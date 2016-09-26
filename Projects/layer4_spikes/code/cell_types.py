from common import *

def instantiate_cells_and_cell_types(cells_db):

  #tmp_types = cells_db.groupby('type')['type'].count()
  #print tmp_types.index.values

  i_displ = 0
  for i in cells_db.index:
    tmp_type = cells_db['type'][i]
    if tmp_type not in cell_types:
      cell_types.append(tmp_type)
      cell_displ.append(i+1)
      i_displ += 1
    else:
      cell_displ[i_displ] += 1

  #print cell_types
  #print cell_displ



