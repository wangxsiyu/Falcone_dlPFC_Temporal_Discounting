%% calculate value
xfit = W.load('../../TempData/modelfit_overall');
xx = {xfit{1,1}, xfit{1,2}};
DVgames = {};
parfor xi = 1:length(games)
    g = games{xi};
    RLopt = S_RL;
    g.reward = zeros(size(g,1),1);
    g.action = 1 + g.choice; % 2 - accept, 1 - reject
    g.is_yellow_1st = strcmp(g.cue1, 'yellow');
    RLopt.load_data(g);
    xxx = xx{(ani_gm.animal(xi) == "T") + 1};
    % calculate value
    [info] = RLopt.test(xxx.params, xxx.model);
    g.DV = info.DV;
    g.action_likelihood = info.action_likelihood;
    g.pred_accept = info.action_dist(:,2);
    g.pred_release = (~g.is_yellow_1st) .* g.pred_accept + g.is_yellow_1st .* (1 - g.pred_accept);
    DVgames{xi} = g;
end
%% save game with DV
W.save('../../TempData/games_DV', 'DVgames', DVgames);
%% update cue.mat and go.mat
DVgames = W.load('../../TempData/games_DV');
cue = W.load('../../TempData/cue');
cue.games = DVgames;
go = W.load('../../TempData/go');
go.games = DVgames;
W.save('../../TempData/cue_DV', 'cue', cue);
W.save('../../TempData/go_DV', 'go', go);
%% separate the two monkeys
cueS = W.select_cells(cue, cue.info_cells.animal == "S", {'ST', 'cells'}, {'info_cells'});
cueT = W.select_cells(cue, cue.info_cells.animal == "T", {'ST', 'cells'}, {'info_cells'});
goS = W.select_cells(go, go.info_cells.animal == "S", {'ST', 'cells'}, {'info_cells'});
goT = W.select_cells(go, go.info_cells.animal == "T", {'ST', 'cells'}, {'info_cells'});
W.save('../../TempData/data', 'cue', {cueS, cueT}, 'go', {goS, goT});

