data = W.load('../../TempData/cue');
ani_gm = unique(data.info_cells(:, ["animal", "gameID"]));
games = data.games;
%% train model per session
modelname = '../../TempData/modelfit_session.mat';
if exist(modelname, 'file')
    xfit = W.load(modelname);
else
    xfit = cell(length(models), length(games));
end
models = ["Model1", "Model1t", "Model2", "Model2t", "Model3", "Model3t"];
nmodel = length(models);
funcs = W.arrayfun(@(x)str2func(x), models);
parfor gi = 1:length(games)
    RLopt = S_RL;
    RLopt.setup_optimizer('fmincon', 'repeat', 1, 'bound_inf', 20);
    g = games{gi};
    g.reward = zeros(size(g,1),1);
    g.action = 1 + g.choice; % 2 - accept, 1 - reject
    g.is_yellow_1st = strcmp(g.cue1, 'yellow');
    RLopt.load_data(g);
    for modeli = 1:nmodel
        if isempty(xfit{modeli, gi}) || xfit{modeli, gi}.LL < -500
            md = feval(funcs{modeli});
            xfit{modeli, gi} = RLopt.train(md);
        end
    end
end
W.save(modelname, 'xfit', xfit);
% %% check model fits
% W.cellfun_vertcat(@(x)[x.model_base.LL, x.model_YP.LL, x.model_YP_time.LL], xfit)
%% train model overall
animals = ["S","T"];
nanimal = length(animals);
models = ["Model1", "Model1t", "Model2", "Model2t", "Model3", "Model3t"];
nmodel = length(models);
xfit = cell(nmodel, nanimal);
for ai = 1:nanimal
    animal = animals(ai);
    g = vertcat(games{ani_gm.animal == animal});
    RLopt = S_RL;
    RLopt.setup_optimizer('fmincon', 'repeat', 2, 'bound_inf', 20);
    g.reward = zeros(size(g,1),1);
    g.action = 1 + g.choice; % 2 - accept, 1 - reject
    g.is_yellow_1st = strcmp(g.cue1, 'yellow');
    RLopt.load_data(g);
    parfor modeli = 1:nmodel
        if isempty(xfit{modeli, ai}) || xfit{modeli, ai}.LL < -500
            md = feval(funcs{modeli});
            xfit{modeli, ai} = RLopt.train(md);
        end
    end
end
W.save('../../TempData/modelfit_overall.mat', 'xfit', xfit);
%% calculate value
xfit = W.load('../../TempData/modelfit_overall');
xx = {xfit{1}.model_base, xfit{4}.model_base};
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

