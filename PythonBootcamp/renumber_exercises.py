import sys, re

try:
    fname = sys.argv[1]
    n = int(fname[:fname.index('_')])
except:
    print "Usage: renumber_exercises.py NN_inputfile.ipynb"
    sys.exit()
    
i = 1
for line in open(fname, 'r'):
    m = re.search(r'Exercise (###|\d+(\.\d+)?):', line)
    if m is not None:
        repl = 'Exercise %d.%d:' % (n, i)
        line = re.sub(r'Exercise (###|\d+(\.\d+)?):', repl, line)
        i += 1
    
    print line,

