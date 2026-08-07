run('../W_setup.m')
savedir = W.mkdir('../../Data');
%% get lists
textdir = '../../lPFC_DATA/FOR_DECODING/TOBIAS_list_channels_and_events_all.txt';
lists = importdata(textdir);
lists = W.cellfun(@(x)string(strsplit(x, ' ')), lists);
lists = W.cellfun(@(x)x(1:2), lists);
lists = vertcat(lists{:});
%% event dir
eventdir = '../../lPFC_DATA/MONKEY_TOBIAS/EVENTS_FILES';
files_events = unique(lists(:,1));
events = W.load(fullfile(eventdir, strcat(files_events,'.mat')));
names = arrayfun(@(x)strcat("T",W.str_selectbetween2patterns(x, 'tob.', '-blk')), files_events);
%% import events
for i = 1:length(names)
    tev = W.struct_rename(events{i}, {'Data', 'TimeStamp'}, {'eventmarkers','timestamps'});
    tev = struct2table(tev);
    W.save(fullfile(savedir, names(i), 'events'), 'events', tev);
end
%% import spikes
spikedir = '../../lPFC_DATA/MONKEY_TOBIAS/CHANNELS';
files_spikes = W.ls(spikedir, 'file');
spikes_all = W.load(files_spikes);
files_spikes = W.basenames(files_spikes);
for i = 1:length(names)
    tid = find(files_events(i) == lists(:,1));
    tfilenames = lists(tid,2);
    tspikes = spikes_all(arrayfun(@(x)find(x == files_spikes), tfilenames));
    spks = W.cellfun(@(x)x(:,3)', tspikes);
    info_spikes = table;
    info_spikes.cellID = tid;
    info_spikes = W.tab_fill(info_spikes, 'animal', extract(names(i),1), 'session', names(i));
    info_session = W.struct('animal', extract(names(i),1), 'session', names(i));
    W.save(fullfile(savedir, names(i), 'spikes'), ...
        'cells', spks, 'info_cells', info_spikes, 'info_session', info_session);
end