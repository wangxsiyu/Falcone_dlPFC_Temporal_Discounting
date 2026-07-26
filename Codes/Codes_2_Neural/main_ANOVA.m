%% ANOVA: drop + delay + interaction + choice (baseline)
factornames = {'drop', 'delay', 'choice'};
model = [1,0,0;0,1,0;1,1,0;0,0,1];
anv = {};
for i = 1:2
    d = cue{i};
    anv{i} = W.anovan_slidingwindow_combinedgames(d, factornames, 'model', model);
end
W.save('../../TempData/anv_drop_delay_interaction_choice', 'anv', anv);
%% GO cue
factornames = {'delay', 'drop', 'motor', 'GO cue', 'choice'};
factornames_in_data = {'delay', 'drop', 'release1', 'cue1', 'choice'};
model = [1 0 0 0 0; 0 1 0 0 0; 1 1 0 0 0; 0 0 1 0 0; 0 0 0 0 1; 0 0 0 1 0];
anv = {};
for i = 1:2
    d = go{i};
    anv{i} = W.anovan_slidingwindow_combinedgames(d, factornames, ...
        'factornames_in_data', factornames_in_data, ...
        'model', model);
end
W.save('../../TempData/anvGO_drop_delay', 'anv', anv);


