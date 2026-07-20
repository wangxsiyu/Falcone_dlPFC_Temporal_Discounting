data = W.load('../../TempData/cue');
ani_gm = unique(data.info_cells(:, ["animal", "gameID"]));
games = data.games;
%% train model per session
modelname = '../../TempData/modelfit_session.mat';
if exist(modelname, 'file')
    xfit = W.load(modelname);
else
    xfit = cell(1, length(games));
end
parfor gi = 1:length(games)
    RLopt = S_RL;
    RLopt.setup_optimizer('fmincon', 'repeat', 1, 'bound_inf', 20);
    g = games{gi};
    g.reward = zeros(size(g,1),1);
    g.action = 1 + g.choice; % 2 - accept, 1 - reject
    g.is_yellow_1st = strcmp(g.cue1, 'yellow');
    RLopt.load_data(g);
    models = ["Model1", "Model1t", "Model2", "Model2t", "Model3", "Model3t"];
    for modeli = 1:length(models)
        model = models(modeli);
        if length(xfit) < gi || ~isfield(xfit{gi}, model) || xfit{gi}.(model).LL < -500
            md = eval(model);
            xfit{gi}.(model) = RLopt.train(md);
        end
    end
end
%% check model fits
W.cellfun_vertcat(@(x)[x.model_base.LL, x.model_YP.LL, x.model_YP_time.LL], xfit)
%% save model
W.save(modelname, 'xfit', xfit);
%% train model overall
animals = ["S","S","S","T","T","T"];
models = ["model_base", "model_YP", "model_YP_time","model_base", "model_YP", "model_YP_time"];
xfit = cell(1,6);
W.parpool(6);
reps = [1:6];
parfor repi = 1:6
    if ismember(repi, reps)
        animal = animals(repi);
        md = models(repi);
        xfit{repi}.animal = animal;
        xfit{repi}.modelname = md;
        g = vertcat(games{ani_gm.animal == animal});

        RLopt = S_RL;
        RLopt.setup_optimizer('fmincon', 'repeat', 2, 'bound_inf', 20);
        g.reward = zeros(size(g,1),1);
        g.action = 1 + g.choice; % 2 - accept, 1 - reject
        g.is_yellow_1st = strcmp(g.cue1, 'yellow');
        RLopt.load_data(g);
        switch md
            case "model_base"
                model = model_base;
                xfit{repi}.model_base = RLopt.train(model);
            case 'model_YP'
                model = model_YP;
                xfit{repi}.model_YP = RLopt.train(model);
            case 'model_YP_time'
                model = model_YP_time;
                xfit{repi}.model_YP_time = RLopt.train(model);
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

