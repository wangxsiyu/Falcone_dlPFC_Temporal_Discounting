run('../W_setup.m')
savedir = W.mkdir('../../Data');
%% get lists
textdir = '../../lPFC_DATA/FOR_DECODING/SEAM_list_channels_and_events_all.txt';
lists = importdata(textdir);
lists = W.cellfun(@(x)string(strsplit(x, ' ')), lists);
lists = W.cellfun(@(x)x(1:2), lists);
lists = vertcat(lists{:});
lists = lists(:,[2 1]);
%% 
eventdir = '../../lPFC_DATA/MONKEY_SEAM/EVENTS_FILES';
files_events = unique(lists(:,1));
events = W.load(fullfile(eventdir, strcat(files_events,'.mat')));
names = arrayfun(@(x)strcat("S", W.str_datetime(W.str_selectbetween2patterns(x, '_', ''), 'ddmmyy', 'yymmdd')), files_events);
%% import events
for i = 1:length(names)
    tev = W.struct_rename(events{i}, {'Data', 'TimeStamp'}, {'eventmarkers','timestamps'});
    tev = struct2table(tev);
    tev.timestamps = tev.timestamps * 1000;
    W.save(fullfile(savedir, names(i), 'events'), 'events', tev);
end
%% import spikes
list_diverse = importdata('../../lPFC_DATA/FOR_DECODING/SEAM_list_cell_diverse.txt');

spikedir = '../../lPFC_DATA/MONKEY_SEAM/CHANNELS';
files_spikes = W.ls(spikedir, 'file');
spikes_all = cell(1, length(files_spikes));
for fi = 1:length(files_spikes)
    W.print('iteration %d', fi)
    te = importdata(files_spikes{fi});
    spikes_all{fi} = te(:,1)' * 1000; % turn s to ms
end
files_spikes = W.basenames(files_spikes);
parfor i = 1:length(names)
    tid = find(files_events(i) == lists(:,1));
    tid = intersect(tid, list_diverse);
    if isempty(tid)
        rmdir(fullfile(savedir, names(i)), 's');
        continue;
    end
    tfilenames = lists(tid,2);
    spks = spikes_all(arrayfun(@(x)find(x == files_spikes), tfilenames));
    tfile = fullfile(savedir, names(i), 'spikes');
    info_spikes = table;
    info_spikes.cellID = tid;
    info_spikes = W.tab_fill(info_spikes, 'animal', extract(names(i),1), 'session', names(i));
    info_session = W.struct('animal', extract(names(i),1), 'session', names(i));
    W.save(tfile, 'cells', spks, 'info_cells', info_spikes, 'info_session', info_session);
end