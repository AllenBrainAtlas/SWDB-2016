# prepare python for R ---------
if(!require(rPython)){
  install.packages('rPython')
}

Sys.setenv(PATH=paste0('/usr/local/var/pyenv/shims:',
                       Sys.getenv('PATH')),
           PYENV_ROOT='/usr/local/var/pyenv',
           PYENV_VERSION='anaconda-4.1.1')

library(R.matlab)
library(rPython)

"
import sys
sys.path.append('/usr/local/var/pyenv/versions/anaconda-4.1.1'+
                '/lib/python2.7/site-packages/')
sys.path.append('/Users/nick/Study/Database_Works/CAM20151012/test/DynamicBrain')

from myfunctions import *

import os
" %>% python.exec(string.code=TRUE)

#### retrieve global data ----
targeted_structures <- python.get(boc.get_all_targeted_structures())
imaging_depths <- python.get(boc.get_all_imaging_depths())
cre_lines <- python.get(boc.get_all_cre_lines())
stimuli <- python.get(boc.get_all_stimuli())

experiment_containers <- python.get(boc.get_experiment_containers())
ophys_experiments <- python.get(boc.get_ophys_experiments())
#nrow(ophys_experiments)/nrow(experiment_containers)==3

cell_specimens <- python.get(boc.get_cell_specimens())
# ophys_experiments %>% sample_n(1) %>% {.$id} -> session_id

"data_set = [ boc.get_ophys_experiment_data(
    ophys_experiment_id = id['id']) for id in boc.get_ophys_experiments()]
" %>% python.exec(string.code = T)

ophys_experiments_meta <- python.get('[ d.get_metadata() for d in data_set]', string.code = T)
ophys_experiments_stimuli <- python.get('[ d.list_stimuli() for d in data_set]', string.code = T)

# save.image('data/ophys_experiments.RData')
load('data/ophys_experiments.RData')

## cells count --------------
cell_specimens %>%
  group_by(experiment_container_id) %>%
  summarise(`# of cells`=n()) %>%
  ggplot(aes(x=`# of cells`))+
  geom_histogram(binwidth = 50)+
  labs(y='# of experiments')

cell_specimens %>%
  mutate(tld1_name_short=gsub('-.*','',cell_specimens$tld1_name),
         appear=
           (is.na(osi_sg)|p_sg>0.05)+
           (is.na(osi_dg)|p_dg>0.05)+
           (is.na(pref_image_ns)|p_ns>0.05)) %>%
  group_by(tld1_name_short, imaging_depth, area, appear) %>%
  summarise(count=length(unique(cell_specimen_id))) %>%
  
  ggplot(aes(tld1_name_short, count, fill=factor(appear)))+
  geom_bar(stat='identity')+
  facet_grid(imaging_depth~area)+
  coord_flip()+
  scale_y_continuous(breaks = seq(0,3e3,5e2),
                     labels = c('0','','1','','2','',''))+
  labs(y='#cell(*10^3)',x='Cre Line',fill='#No Show in Stimuli')+
  theme(legend.position='top')

## experiment-wise data ------------
get_ophys_experiment_data <- function(id, data='stimulus_table', stimuli='drifting_gratings'){
  python.exec(paste0('_r_exp_id = ', id), string.code = TRUE)
  python.exec(paste0('_r_data_set = boc.get_ophys_experiment_data(_r_exp_id)'),string.code = TRUE)
  if(data=='stimulus_table'){
    return(as.data.frame(python.get(paste0('_r_data_set.get_stimulus_table("',stimuli,'")'), string.code = TRUE)))
  }
  else if(data=='cell_specimen_id'){
    return(python.get(paste0('_r_data_set.get_cell_specimen_ids()'), string.code = TRUE))
  }
  else if(data=='running_speed'){
    return(python.get(paste0('_r_data_set.get_running_speed()[1]'), string.code = TRUE))
  }
  else if(data=='timestamps'){
    return(python.get(paste0('_r_data_set.get_running_speed()[0]'), string.code = TRUE))
  }
  else if(data=='corrected_fluorescence_traces'){
    cache_file <- paste0('data/exp-',id,'-corrected_fluorescence_traces.mat')
    if(!file.exists(cache_file)){
"
scipy.io.savemat('data/exp-%d-corrected_fluorescence_traces.mat'%_r_exp_id, 
      {'cfluo':_r_data_set.get_corrected_fluorescence_traces()[1]})
      " %>% python.exec(string.code = TRUE)
    }
    return(readMat(cache_file)$cfluo)
  }
  else if(data=='dff_traces'){
    cache_file <- paste0('data/exp-',id,'-dff_traces.mat')
    if(!file.exists(cache_file)){
"
scipy.io.savemat('data/exp-%d-dff_traces.mat'%_r_exp_id, 
      {'dff':_r_data_set.get_dff_traces()[1]})
      " %>% python.exec(string.code = TRUE)
    }
    return(readMat(cache_file)$dff)
  }
  else if(data=='dff_baseline'){
    return(python.get("np.apply_along_axis(lambda x: seperate_high_low(x)[:-1], 1, _r_data_set.get_dff_traces()[1])", string.code = T))
    }
}

##
ophys_experiments_meta %>% filter(
  experiment_container_id==511510884,
  session_type=='three_session_A') %>% {.$ophys_experiment_id}

exp_id <- 504637623

stimulus_table <- get_ophys_experiment_data(exp_id, data = 'stimulus_table', stimuli = 'drifting_gratings')
stimulus_table$start <- stimulus_table$start+1
cell_specimen_id <- as.character(get_ophys_experiment_data(exp_id, data = 'cell_specimen_id'))
timestamps <- get_ophys_experiment_data(exp_id, data = 'timestamps')
running_speed <- get_ophys_experiment_data(exp_id, data = 'running_speed')
dff <- get_ophys_experiment_data(exp_id, data = 'dff_traces')
rownames(dff) <- cell_specimen_id
dff_stats <- get_ophys_experiment_data(exp_id, data = 'dff_baseline')
dimnames(dff_stats) <- list(cell=cell_specimen_id, stat=c('low','high','low.std'))

dff_boundary <- dff_stats[,'low']+dff_stats[,'low.std']*3

# stimulus_table %>%
#   maply(function(start, end, ...){
#     rowMeans(dff[,start:end]>dff_boundary)
#   }) -> dff_high_ratio

python.exec(paste0('feature = pickle.load(open("data/features-',exp_id,'-gratings.pkl", "rb"))'), string.code = T)
python.get(feature.keys())


dff_high_ratio <- python.get('feature["metrics"][:, :, feature["metrics_names"]["high_dff_max_ratio"]]', string.code = T)
high_dff_frames_ratio <- python.get('feature["metrics"][:, :, feature["metrics_names"]["high_dff_frames_ratio"]]', string.code = T)
dimnames(high_dff_frames_ratio) <- dimnames(dff_high_ratio) <- 
  list(cell=cell_specimen_id,
       start=python.get(feature['start_end'])[,1]+1)

melt(dff_high_ratio>6&high_dff_frames_ratio>0.15) %>% head
responsive_metrics <- melt(dff_high_ratio, value.name='dff_high_ratio') %>%
  join(melt(high_dff_frames_ratio, value.name='high_dff_frames_ratio'),
       by=c('cell','start')) %>%
  join(stimulus_table, by = 'start') %>%
  mutate(is.responsive=high_dff_frames_ratio>0.15&dff_high_ratio>6)

expand.grid(x=seq(3,10,0.2), y=seq(0,0.25, 0.01)) %>%
  mdply(function(x,y){with(responsive_metrics, 
                           sum(dff_high_ratio>x&high_dff_frames_ratio>y))}) %>%
  mutate(prop=V1/sum(!is.na(responsive_metrics$dff_high_ratio))) -> high_dff_cdf

responsive_metrics %>%
  filter(high_dff_frames_ratio>0) %>%
  ggplot(aes(dff_high_ratio, high_dff_frames_ratio*100)) +
  geom_tile(aes(x,y*100,fill=prop*100), high_dff_cdf)+
  geom_jitter(size=0.1, alpha=0.2, height = 2)+
  geom_contour(aes(x,y*100,z=prop, size=-..level..), high_dff_cdf,bins = 4)+
  geom_segment(aes(x=0,xend=6,y=15,yend=15), color='red', linetype='dashed')+
  geom_segment(aes(x=6,xend=6,y=0,yend=15), color='red', linetype='dashed')+
  coord_cartesian(xlim=c(3,8), ylim=c(0,25),expand = F)+
  scale_fill_distiller(palette = "Spectral",breaks = seq(0,100,25))+
  scale_size_continuous(range = c(1,2), breaks = -seq(0,100,25), guide = F)+
  labs(x='max DF/F ratio', y='High DF/F state time(%)',
       fill='trials(%)',title=paste0('Drifting gratings in Exp.',exp_id))
  

responsive_metrics %>%
  ggplot(aes(dff_high_ratio, high_dff_frames_ratio))+
  stat_density_2d(geom = "raster", aes(fill = ..density..),
                  contour = FALSE, h = c(0.05,0.05))+
  coord_cartesian(xlim=c(3,6),ylim=c(0,0.1))

facet_labeller <- label_bquote(rows = paste(.(temporal_frequency),'Hz',sep=''))

responsive_metrics %>% 
  group_by(cell) %>%
  summarise(count=sum(is.responsive)) %>%
  filter(count>0) %>%
  ggplot(aes(x=count)) +
  geom_histogram(aes(y=..count..),binwidth = 10,
                 fill=NA,color='black')+
  stat_bin(aes(y=(1-cumsum(..count..)/196)*100),
           binwidth=1,geom='line',color='red')+
  geom_vline(aes(xintercept=5), linetype='dashed',color='blue')+
  labs(x='# of responsive trials', y='# of cells')+
  coord_cartesian(xlim=c(-6,220),ylim=c(0,100), expand = F)

responsive_metrics %>% 
  filter(blank_sweep==0) %>%
  group_by(cell, orientation, temporal_frequency) %>%
  summarise(count=sum(is.responsive)) %>%
  filter(count!=0) %>%
  ggplot(aes(x=count)) +
  geom_histogram(binwidth=1)+
  facet_grid(temporal_frequency~orientation, labeller = facet_labeller)+
  labs(x='# of responsive trials', y='# of cells')+
  scale_x_continuous(breaks = c(1, 5,10))

responsive_metrics %>% 
  group_by(cell) %>%
  summarise(count=sum(is.responsive)) %>%
  left_join(cell_specimens,by=c('cell'='cell_specimen_id')) %>%
  ggplot(aes(log(p_dg), count))+
  geom_jitter(alpha=0.8,shape=1)+
  annotate(geom='rect',xmin=log(0.05),xmax=10,ymin=-5,ymax=1e3,alpha=0.2,fill='red')+
  annotate(geom='rect',xmin=-1e3,xmax=10,ymin=-5,ymax=5,alpha=0.2,fill='red')+
  labs(x='log(p-value)', y='# of responsive trials', 
       title=paste0('Drifting grating cells in Exp. ',exp_id))+
  coord_cartesian(xlim=c(-50,0),ylim=c(0,50))


responsive_metrics %>% 
  group_by(cell) %>%
  summarise(count=sum(is.responsive)) %>%
  filter(count<100,count>80)

cell_specimen_id_example <- "517438505"

stimulus_table %>%
  # filter(blank_sweep==0) %>%
  rowwise() %>%
  do({data.frame(orientation=.$orientation, temporal_frequency=.$temporal_frequency, 
                 start=.$start, 
                 is.responsive=filter(responsive_metrics,
                   start==.$start, 
                   cell==cell_specimen_id_example)$is.responsive,
                t=seq(-1,3,length.out = 120), 
                dff=dff[cell_specimen_id_example,
                        (.$start-30):(.$start+89)])}) -> dff_trace_example

dff_trace_example %>%
  filter(!is.na(orientation)) %>%
  group_by(temporal_frequency, orientation) %>%
  ggplot(aes(x=t,y=dff))+
  geom_rect(aes(xmin=0,xmax=2,ymin=-0.5,ymax=1),fill='grey',alpha=0.2)+
  geom_path(aes(group=start,color=is.responsive,alpha=is.responsive),size=0.2)+
  
  facet_grid(temporal_frequency~orientation, labeller = facet_labeller)+
  scale_alpha_manual(values = c('TRUE'=0.8,'FALSE'=0.4),guide=F)+
  scale_color_manual(values = c('TRUE'='red','FALSE'='black'),guide=F)+
  scale_x_continuous(breaks = c(0,2))+
  scale_y_continuous(breaks = c(0.5,1.0), labels = scales::percent)+
  coord_cartesian(xlim=c(-1,3), ylim=c(-0.05,1.05), expand = F)+
  labs(x='Time(s)', y='DF/F', title=paste0(
    'Drifting grating trials for cell ',cell_specimen_id_example,' Exp. ', exp_id))


dff_trace_example %>% 
  filter(orientation==180,temporal_frequency==8, start == 54324|!is.responsive) %>%
  # group_by(start) %>% slice(1)
  ggplot(aes(x=t,y=dff))+
  geom_rect(aes(xmin=0,xmax=2,ymin=-0.5,ymax=1),fill='grey',alpha=0.2)+
  geom_path(aes(x=ifelse(!is.responsive, t, NA),group=start),alpha=0.5,size=0.4)+
  geom_path(aes(x=ifelse(is.responsive, t, NA)),color='blue')+
  geom_hline(aes(yintercept=dff_stats[cell_specimen_id_example,'low']),linetype='dotted',color='red',size=2)+
  geom_hline(aes(yintercept=dff_boundary[cell_specimen_id_example]),linetype='dotdash',color='red')+
  geom_hline(aes(yintercept=max(dff)),color='red')+
  scale_alpha_manual(values = c('TRUE'=0.8,'FALSE'=0.4),guide=F)+
  scale_color_manual(values = c('TRUE'='red','FALSE'='black'),guide=F)+
  scale_x_continuous(breaks = c(0,2))+
  scale_y_continuous(breaks = c(0.,0.5,1.0), labels = scales::percent)+
  coord_cartesian(xlim=c(-1,3), ylim=c(-0.1,1.05), expand = F)+
  labs(x='Time(s)', y='DF/F')

spikes <- dff_high_ratio>6&high_dff_frames_ratio>0.15
stimulus_table_order <- with(stimulus_table,
                    order(orientation,temporal_frequency,blank_sweep,start))
spikes[, stimulus_table_order] -> spikes

# writeMat('Spikes.mat',Spikes=spikes)
c_idx <- data.frame(cell=rownames(spikes),
                    group=readMat('Spikes.mat')$c,
                    responsive.trail=rowSums(spikes), 
                    stringsAsFactors = F)

c_idx %>% group_by(group) %>% 
  summarise(all.responsive.trail=mean(responsive.trail)) %>%
  mutate(new.group=rank(all.responsive.trail)) %>%
  right_join(c_idx, by = 'group') %>%
  arrange(new.group, responsive.trail) %>%
  mutate(cell_index=seq_along(cell)) %>%
  select(cell, cell_index, new.group) -> c_idx

melt(spikes) %>% join(c_idx, by = 'cell') %>% 
  join (stimulus_table %>%
          arrange(orientation, temporal_frequency, start) %>% 
          mutate(trail_index=seq_along(start)), 
        by='start') %>% 
  filter(value==TRUE) -> spikes_DF
  
spikes_DF %>%
  ggplot(aes(trail_index, cell_index, color=factor(new.group)))+
  geom_point(size=0.5)+
  facet_wrap('orientation',scales = 'free_x', nrow = 1, switch = 'x')+
  coord_cartesian(expand = F)+
  guides(color=F)+
  labs(x='Orientation',y='Ordered Neuron')+
  theme(panel.margin = unit(1, "mm"),
        axis.ticks=element_blank(),
        axis.text=element_blank(),
        panel.grid=element_blank(),
        panel.border=element_blank())

##
pt2vec <- function(pt){
  unlist(apply(pt, 1, function(p){c(length(p$id), p$id, length(p$gid), p$gid)}))
}

exist.cpp.function <- function(func, env=.GlobalEnv){
  func <- as.character(substitute(func))
  
  exists(func, where = env, mode = "function") && attr(
    gregexpr('<pointer: 0x[^>]*>',
             deparse(body(get(func,envir = env)),width.cutoff = 500)[1]
    )[[1]],'match.length') > nchar('<pointer: 0x0>')
}
if(!exist.cpp.function(find_frequent_patterns)){
  sourceCpp('../03baseline/cpp.code/find_pattern.cpp', env = .GlobalEnv)
}

#### 
orig_pts <- spikes_DF %>%
  # group_by(cell) %>%
  # mutate(trail_index=sample(nrow(stimulus_table),n())) %>%
  # ungroup() %>%
  
  mutate(id=as.integer(factor(cell_index)), 
         gid=as.integer(factor(trail_index)))

pts <- orig_pts %>% group_by(gid) %>% do(id=sort(.[['id']])) %>% 
  pt2vec %>% find_frequent_patterns() %>% jsonlite::fromJSON()

pts_freq <- data_frame(pt=sapply(pts$id,length),
                       freq=sapply(pts$gid,length))
##
orig_pts <- spikes_DF %>%
  
  group_by(cell, temporal_frequency, orientation) %>% 
  mutate(trail_index=sample(ifelse(is.na(temporal_frequency[1]),30,15),n())) %>%
  ungroup() %>%
  mutate(trail_index=paste0(temporal_frequency,orientation,trail_index)) %>%
  
  mutate(id=as.integer(factor(cell_index)), 
         gid=as.integer(factor(trail_index)))

pts <- orig_pts %>% group_by(gid) %>% do(id=sort(.[['id']])) %>% 
  pt2vec %>% find_frequent_patterns() %>% jsonlite::fromJSON()

pts_freq.surrogate <- data_frame(pt=sapply(pts$id,length),
                       freq=sapply(pts$gid,length))
##

pts_freq %>%
  ggplot()+
  geom_point(aes(pt+runif(n = length(pt),max = 0.9),
                 freq+runif(n = length(pt),max = 0.9)), pts_freq,
              size=0.01,alpha=0.5)+
  geom_point(aes(pt+runif(n = length(pt),max = 0.9),
                 freq+runif(n = length(pt),max = 0.9)), pts_freq.surrogate,
             size=0.01,alpha=0.5,color='red')+
  scale_x_log10(breaks=c(3,5,10,20))+
  scale_y_log10(breaks=c(3,5,10,20,50,100))+
  labs(x='Ensemble size', y='Ensemble frequent')

rbind(cbind(ddply(pts_freq,.(pt,freq),nrow),data='orig'),
cbind(ddply(pts_freq.surrogate,.(pt,freq),nrow),data='surrogate')) %>%
  spread(data, V1, fill = 0) %>%
  mutate(orig.prob=(orig+1)/(sum(orig)+n()),
         surrogate.prob=(surrogate+1)/(sum(surrogate)+n())) %>%
  with(KL.plugin(orig.prob,surrogate.prob)) -> kld
# 0.7753514 for 504637623


## batch #####
calc.kld <- function(exp_id, repeat_times=2){
  # print(paste0('exp_id: ', exp_id))
  file_path <- paste0('data/features-',exp_id,'-gratings.mat')
  stimulus_table <- get_ophys_experiment_data(exp_id, data = 'stimulus_table', stimuli = 'drifting_gratings')
  Sys.sleep(2)
  stimulus_table$trail_index <- seq_along(stimulus_table$start)
  readMat(file_path)$responsive.bool -> spikes
  
  melt(spikes) %>% transmute(cell=Var1, trail_index=Var2, value) %>%
    filter(value==TRUE) %>%
    join(stimulus_table, by='trail_index') -> spikes_DF
  
  spikes_DF %>%
    mutate(id=as.integer(factor(cell)), 
           gid=as.integer(factor(trail_index))) %>% 
    group_by(gid) %>% do(id=sort(.[['id']])) %>% 
    pt2vec %>% find_frequent_patterns() %>% 
    jsonlite::fromJSON() -> pts
  
  pts_freq <- data_frame(pt=sapply(pts$id,length),
                                   freq=sapply(pts$gid,length))
  
  kld_all <- rep(0,repeat_times)
  
  for(j in 1:repeat_times){
    
  spikes_DF %>%
    group_by(cell, temporal_frequency, orientation) %>% 
    mutate(trail_index=sample(ifelse(is.na(temporal_frequency[1]),30,15),n())) %>%
    ungroup() %>%
    mutate(trail_index=paste0(temporal_frequency,orientation,trail_index)) %>%
    
    mutate(id=as.integer(factor(cell)), 
           gid=as.integer(factor(trail_index))) %>%
    group_by(gid) %>% do(id=sort(.[['id']])) %>% 
    pt2vec %>% find_frequent_patterns() %>% 
    jsonlite::fromJSON() -> pts
  
  pts_freq.surrogate <- data_frame(pt=sapply(pts$id,length),
                                   freq=sapply(pts$gid,length))
  
  rbind(cbind(ddply(pts_freq,.(pt,freq),nrow),data='orig'),
        cbind(ddply(pts_freq.surrogate,.(pt,freq),nrow),data='surrogate')) %>%
    spread(data, V1, fill = 0) %>%
    mutate(orig.prob=(orig+1)/(sum(orig)+n()),
           surrogate.prob=(surrogate+1)/(sum(surrogate)+n())) %>%
    with(KL.plugin(orig.prob,surrogate.prob)) -> kld_all[j]
  }
  
  kld_all
}

ophys_experiments_meta %>% 
  filter(session_type=='three_session_A') %>%
  # slice(1:2) %>%
  rowwise() %>%
  do(data_frame(ophys_experiment_id=.$ophys_experiment_id,
                kld=calc.kld(ophys_experiment_id,10))) -> kld_all


# saveRDS(kld_all,'KLD.RData')

kld_all %>% group_by(ophys_experiment_id) %>%
  summarise(kld.min=min(kld),kld.max=max(kld),kld=mean(kld)) %>%
  join(ophys_experiments_meta, by='ophys_experiment_id') %>%
  ungroup() %>%
  mutate(imaging_depth_um=as.integer(as.factor(imaging_depth_um))+
           runif(n())-0.5) %>%
  ggplot(aes(imaging_depth_um, 
             kld, shape=sapply(strsplit(ophys_experiments_meta$cre_line,'-'), .%>%{.[[1]]}),
             color=targeted_structure))+
  geom_errorbar(aes(ymin=kld.min,ymax=kld.max),width=0.05)+
  geom_point(size=2)+
  labs(x='Imaging depth(um)',y='KL divergence', shape='',color='')+
  scale_x_continuous(breaks = seq_along(imaging_depths), labels = imaging_depths)

kld_all %>% group_by(ophys_experiment_id) %>%
  summarise(kld.min=min(kld),kld.max=max(kld),kld=mean(kld)) %>% 
  jsonlite::toJSON() %>% write(file='data/KLD.json')

## 
ophys_experiments_meta
cell_specimen_id_all <- python.get("[(exp['id'], boc.get_ophys_experiment_data(exp['id']).get_cell_specimen_ids()) for exp in boc.get_ophys_experiments(stimuli=['drifting_gratings'])]",string.code = T)

cell_specimen_id_all <- cell_specimen_id_all %>%
  rowwise() %>%
  do(data_frame(ophys_experiment_id=.$`0`,cell_specimen_id=.$`1`))

cell_specimen_id_all <- cell_specimen_id_all %>%
  group_by(ophys_experiment_id) %>%
  mutate(good_cell=cell_specimen_id %in% scan(paste0('data/exp-',ophys_experiment_id[1],'_cell_id_subset.dat'))) %>%
  left_join(cell_specimens, by='cell_specimen_id')

cell_specimen_id_all %>% 
  mutate(significant_cell=p_dg<0.05) %>%
  group_by(ophys_experiment_id, significant_cell, good_cell) %>%
  summarise(cre=tld1_name[1], imaging_depth=imaging_depth[1], area=area[1],
            cell_count=n()) -> tmp

tmp %>%
  mutate(cre=gsub('-.*','',cre),
         appear=c('TRUE TRUE'='  Good',
                  'FALSE FALSE'='Both',
                  'FALSE TRUE'=' Few Response',
                  'TRUE FALSE'='  P>0.05'
                  )[paste(good_cell,significant_cell)]) %>%
  ungroup() %>% group_by(cre, imaging_depth, area) %>%
  mutate(ophys_experiment_id=as.integer(factor(ophys_experiment_id)),
         area_depth_cre=paste(area,imaging_depth,cre,sep = '-')) %>%
  arrange(appear) %>%
  
  ggplot(aes(ophys_experiment_id, cell_count, fill=appear))+
  geom_bar(stat='identity')+
  facet_wrap('area_depth_cre',scales = 'free_x',nrow = 3, switch = 'x')+
  # scale_y_continuous(breaks = seq(0,3e3,5e2),
  #                    labels = c('0','','1','','2','',''))+
  labs(y='# of cell',x='Exp. Container', fill='')+
  theme(legend.position='top', 
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        strip.text=element_text(size=10))

# old stuff ----------------

# max_projection <- python.get('[ d.get_max_projection() for d in data_set]', string.code = T)
max_projection <- python.get('data_set[0].get_max_projection()', string.code = T)
# roi_mask_array <- python.get('data_set[0].get_roi_mask()[0].get_mask_plane()',string.code = T)
# imshow(max_projection)

"
from allensdk.brain_observatory.drifting_gratings import DriftingGratings

dg = DriftingGratings(data_set[2])
" %>% python.exec(string.code=T)

acquisition_rate <- python.get(dg.acquisition_rate)
sweep_response <- python.get(dg.sweep_response)
sweep_response$dx %>% {as.data.frame(cbind(t=seq_len(ncol(.)),t(.)))} %>%
  gather(trail,dx, -t) %>%
  mutate(t=t/acquisition_rate-1.,
    trail=as.integer(factor(trail)), 
         ori=stimulus_table$orientation[trail], 
         tf=stimulus_table$temporal_frequency[trail]) -> running_speed
  
running_speed %>% filter(!is.na(ori)) %>%
ggplot(aes(t,dx,group=trail))+
  geom_path()+
  facet_grid(ori~tf)

timestamps_and_traces <- python.get('data_set[0].get_corrected_fluorescence_traces()',string.code = T)
timestamps <- timestamps_and_traces[[1]]
corrected_fluorescence_traces <- timestamps_and_traces[[2]]

"
def get_stimulus_table(id):
    data_set = boc.get_ophys_experiment_data(id)
    def stimulus_table(stim):
        stimulus_table = data_set.get_stimulus_table(stimulus_name=stim)
        stimulus_table['stimulus_name'] = stim
        return stimulus_table
    
    stimulus_table = pd.concat([ stimulus_table(stim) for stim in data_set.list_stimuli()]).sort_values('start')
    
    stimulus_table['id'] = id
    return stimulus_table
" %>% python.exec(string.code = T)

p <- python.get(get_stimulus_table(501794235))

as.data.frame(p) %>% 
  ggplot(aes(x=stimulus_name, y=start, ymin=start, ymax=end,
             color=stimulus_name))+
  geom_crossbar()+
  guides(color=F)+
  # scale_y_continuous(labels = function(x){round(x/30/60)})+
  labs(x='',y='Time (min)')+
  coord_flip(ylim = c(750,800))

#### from python #################
cell_id <- scan('data/exp-502115959_cell_id.dat')
stimulus_table <- read.csv('data/exp-502115959_stimulus_table.dat')
response_bool <- fread('data/exp-502115959_responsive_bool.dat',header = F) %>% as.matrix()

stimulus_table %>% 
  # mutate(metrics_index = seq_along(start)) %>%
  group_by(orientation, temporal_frequency) %>%
  do(data.frame(orientation=.$orientation[1], 
                temporal_frequency=.$temporal_frequency[1],
                cell_id=cell_id,
                response_trail_count=rowSums(response_bool[, .$metrics_index])
                )) %>%
  mutate(p_dg=cell_specimens$p_dg[
    match(cell_id,cell_specimens$cell_specimen_id)]) -> response_trail

response_trail %>%
  filter(!is.na(orientation)) %>%
  ggplot(aes(factor(cell_id), factor(orientation), fill=response_trail_count))+
  geom_tile()+
  facet_wrap('temporal_frequency')+
  labs(x='Cell',y='Ori.',fill='#Trail')

response_trail %>%
  filter(!is.na(orientation)) %>%
  group_by(cell_id) %>%
  summarise(p_dg=p_dg[1], 
            all_response_trail_count=sum(response_trail_count),
            max_response_trail_count=max(response_trail_count)) %>%
  ggplot()+
  geom_jitter(aes(log10(p_dg),all_response_trail_count/15), size=0.5, color='red',alpha=0.5)+
  geom_jitter(aes(log10(p_dg),max_response_trail_count), size=0.5, alpha=0.5)+
  labs(x='log p-value',y='# responsive trails')


ophys_experiments %>% 
  filter(targeted_structure=='VISp',imaging_depth==175)

imshow(response_bool)
