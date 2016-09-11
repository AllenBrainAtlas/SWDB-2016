function locate(fun)

f = which(fun);
cmd = ['!explorer /select,"' f '"'];
disp(cmd)
eval(cmd)