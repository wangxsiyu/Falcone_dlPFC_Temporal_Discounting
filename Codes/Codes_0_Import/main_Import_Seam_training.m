run('../W_setup.m')
savedir = W.mkdir('../../TempData/Seam_training');
%% 
eventdir = '../../lPFC_DATA/SEAM_trainingdata/SEAM_SESSIONS';
[events, files] = W.load(fullfile(eventdir, '*E.mat'));
names = arrayfun(@(x)strcat("S", W.str_datetime(W.str_selectbetween2patterns(x, '_', 'E'), 'ddmmyy', 'yymmdd')), W.basenames(files));
%% import events
for i = 1:length(names)
    tev = W.struct_rename(events{i}, {'Data', 'TimeStamp'}, {'eventmarkers','timestamps'});
    tev = struct2table(tev);
    tev.timestamps = tev.timestamps * 1000;
    W.save(fullfile(savedir, names(i), 'events'), 'events', tev);
end