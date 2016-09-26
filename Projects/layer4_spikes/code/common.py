from neuron import h

h.load_file("stdgui.hoc")
h.load_file('parlib.hoc')
h.load_file("import3d.hoc")

h.load_file("cell.hoc")

h.load_file("LIF_pyramid_1.hoc")
h.load_file("LIF_interneuron_1.hoc")

pc = h.ParallelContext()
rank = int(pc.id())
nhost = int(pc.nhost())


#from cell_types import *

cells = {}
cell_types = []
cell_displ = [0]

common_nc_list = []
common_syn_list = []
common_rand_stream_dict = {}

cell_sec = {}

def type_index(gid):
  for i, displ in enumerate(cell_displ):
    if gid < displ:
      return i-1
  return -1 # If nothing found.



