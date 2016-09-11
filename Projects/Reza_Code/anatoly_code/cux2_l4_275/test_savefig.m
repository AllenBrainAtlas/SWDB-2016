
hf=fn_figure('test_savefig');
figure(hf)
set(hf,'units','centimeter','pos',[30 5 21 29.7/2])
clf

ha = axes('pos',[0 0 1 1]);
axis([0 21 0 29.7/2])
box on
fn_lines(1:21,1:29,'linestyle','--','color',[1 1 1]*.6)
fn_lines(5:5:20,5:5:25,'color','k')

txtdef = {'verticalalignment','baseline','horizontalalignment','left', ...
    'fontunits','centimeters','fontsize',1};
ht = text(5,5,'Axes units',txtdef{:});

ht = text(0,0,'CM units',txtdef{:});
set(ht,'units','centimeters','position',[5 10])

pt2cm = 0.0352777778;
cm2pt = 1/pt2cm;
line(2,3,'linestyle','none','marker','s','markerSize',2*cm2pt);
line(4,3,'linestyle','none','marker','o','markerSize',2*cm2pt);
line(6,3,'linestyle','none','marker','*','markerSize',2*cm2pt);
line(8,3,'linestyle','none','marker','+','markerSize',2*cm2pt);
line(10,3,'linestyle','none','marker','.','markerSize',2*cm2pt);

