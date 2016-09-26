from common import *
#from cell_types import cells

h.load_file("parlib.hoc")

stim_list = []
stim = None





def mkstim_IClamp(stim_id, amp_i, delay, duration):

  #exit if the cell with id = stim_id does not exist on this host
  if not pc.gid_exists(stim_id):
    return

  #printf("stim cell: gid = %d\n", stim_id)
  s = pc.gid2cell(stim_id).soma[0]
  stim = h.IClamp(s(0.5))
  stim.delay = delay
  stim.dur = duration
  stim.amp = amp_i
  #print stim.hname()

  stim_list.append(stim)





def mkstim_VClamp(stim_id, v_hold, duration):

  #exit if the cell with id = stim_id does not exist on this host
  if not pc.gid_exists(stim_id):
    return

  s = pc.gid2cell(stim_id).soma[0]
  stim = h.VClamp(s(0.5))
  stim.dur[0] = duration
  stim.amp[0] = v_hold

  stim_list.append(stim)


