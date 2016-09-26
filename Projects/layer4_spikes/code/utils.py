from allensdk.model.biophys_sim.neuron.hoc_utils import HocUtils
from allensdk.config.model.formats.hdf5_util import Hdf5Util
import logging
import pandas as pd
import json

'''
Created on Aug 3, 2015

@author: Sergey Gratiy, Nathan Gouwens 
'''


class Utils(HocUtils):
    _log = logging.getLogger(__name__)
    
    def __init__(self, description):
        super(Utils, self).__init__(description)
        self.stim = None
        self.stim_curr = None
        self.sampling_rate = None
    

    def load_cell_db(self):
        ''' 
        load cell data base as a data frame
        '''
        cell_db_path = self.description.manifest.get_path('CELL_DB')
        db = pd.read_csv(cell_db_path, sep=' ')
        
        return db


    def load_connectivity(self):
        '''
        load the connectivity matrix from the hdf5 file in the CSR format - efficient for large networks
        '''

        h5u = Hdf5Util()
        
        con_path = self.description.manifest.get_path('CONNECTIONS')
        con = h5u.read(con_path)
        
        return con


    def set_run_params(self):
        
        run = self.description.data["run"]
        
        h =self.h
        
        h.dt = run["dt"]
        h.tstop = run["tstop"]
        h.runStopAt = h.tstop
        h.steps_per_ms = 1/h.dt
        

    def generate_cells(self,db):
        '''
        instantiate cells based on the type provided in the cell database
        '''

        fit_ids = self.description.data['fit_ids'][0]

        cells = {}

        for gid in db.index:
            cell = self.h.cell()
            cells[gid]=cell
            morphology_path = self.description.manifest.get_path('MORPHOLOGY_%s' % (db.ix[gid]['type']))
            self.generate_morphology(cell, morphology_path)
            #print fit_ids[db.ix[gid]['type']]
            self.load_cell_parameters(cell, fit_ids[db.ix[gid]['type']])

            print 'gid:',gid, ' ', db.ix[gid]['type']

        return cells
    


    def generate_morphology(self, cell, morph_filename):

        '''
        load morphology and simplify axon by replacing the reconstructed axon 
        with an axon initial segment made out of two sections
        '''        
        h = self.h
        
        swc = self.h.Import3d_SWC_read()
        swc.input(morph_filename)
        imprt = self.h.Import3d_GUI(swc, 0)
        imprt.instantiate(cell)
        
        for seg in cell.soma[0]:
            seg.area()

        for sec in cell.all:
            sec.nseg = 1 + 2 * int(sec.L / 40)
        
        cell.simplify_axon()
        for sec in cell.axonal:
            sec.L = 30
            sec.diam = 1
            sec.nseg = 1 + 2 * int(sec.L / 40)
        cell.axon[0].connect(cell.soma[0], 0.5, 0)
        cell.axon[1].connect(cell.axon[0], 1, 0)
        h.define_shape()


    
    def load_cell_parameters(self, cell, cell_par_fname):

        with open(cell_par_fname) as cell_par_file:    
          cell_par_data = json.load(cell_par_file)

        passive = cell_par_data['passive'][0]
        conditions = cell_par_data['conditions'][0]
        genome = cell_par_data['genome']

        # Set passive properties
        cm_dict = dict([(c['section'], c['cm']) for c in passive['cm']])
        for sec in cell.all:
            sec.Ra = passive['ra']
            sec.cm = cm_dict[sec.name().split(".")[1][:4]]
            sec.insert('pas')
            for seg in sec:
                seg.pas.e = passive["e_pas"]

        # Insert channels and set parameters
        for p in genome:
            sections = [s for s in cell.all if s.name().split(".")[1][:4] == p["section"]]
            for sec in sections:
                if p["mechanism"] != "":
                    sec.insert(p["mechanism"])
                setattr(sec, p["name"], p["value"])
        
        # Set reversal potentials
        for erev in conditions['erev']:
            sections = [s for s in cell.all if s.name().split(".")[1][:4] == erev["section"]]
            for sec in sections:
                sec.ena = erev["ena"]
                sec.ek = erev["ek"]


    def load_syn_data(self):
        f = open(self.description.data['syn_data_file'], 'r')
        self.description.data['syn_data_types'] = json.load(f)
        f.close()


    def connect_cell(self,cells,db,con):

        '''
        connect cells with specific synapses and specific locations based on connectome
        Limitation: target section is always dend[0]
        '''

        h = self.h

        synaptic = self.description.data["synaptic"]

        
        indices = con.indices
        indptr = con.indptr
        data = con.data
        netcons = []; syns =[]
        for tar_gid in cells:
            
            src_gids = indices[indptr[tar_gid]:indptr[tar_gid+1]]
            nsyns = data[indptr[tar_gid]:indptr[tar_gid+1]] # read from hdf5 nsyns and src_gids for a tar_gid

            print 'tar_gid:',tar_gid,' src_gids:', src_gids, 'nsyn:',nsyns
            tar_type = db.ix[tar_gid]['type']
             
            for src_gid,nsyn in zip(src_gids,nsyns):
   
                src_type = db.ix[src_gid]['type']
                src_cell = cells[src_gid]
                
                for isyn in xrange(nsyn):
                    tar_sec = cells[tar_gid].dend[0]
                    syn = h.Exp2Syn(0.5, sec=tar_sec)
                    src_sec = src_cell.soma[0]
                    nc = h.NetCon(src_sec(0.5)._ref_v, syn, sec=src_sec)
  
                    syn.e = synaptic[src_type]['syn_Ve']
                    nc.delay = synaptic[tar_type]['src'][src_type]['D']  
                    nc.weight[0] = synaptic[tar_type]['src'][src_type]['W']      # mean synaptic conductance in uS (for Exp2Syn).
                    nc.threshold = -20
  
                    netcons.append(nc)
                    syns.append(syn)


        return [netcons,syns]






    def record_values(self, cells):

        h=self.h

        vec = { "v": [],
                "t": h.Vector() }
    
        for gid in cells:
            cell=cells[gid]
            vec["v"].append(h.Vector())
            vec["v"][gid].record(cell.soma[0](0.5)._ref_v)
        vec["t"].record(h._ref_t)

        return vec




    def setIClamps(self,cells):
        '''
        set the current clamp stimuli
        '''
        
        h = self.h

        stim_path = self.description.manifest.get_path('STIMULUS')
        
        stim_json = open(stim_path,'r')
        stim_params = json.load(stim_json) 
        
        delay = stim_params["delay"]
        dur = stim_params["dur"]
        amps = stim_params["amps"]
        print stim_params


        stims = {}
        for gid in cells:
            
            cell = cells[gid]
            stim = h.IClamp(cell.soma[0](0.5))
            stim.amp = amps[str(gid)]
            stim.delay = delay
            stim.dur = dur
            
            stims[gid] = stim
        return stims






        
