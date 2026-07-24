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
%% check model fits
W.cellfun_vertcat(@(x)x.LL, xfit)
%% train model overall
modelname = '../../TempData/modelfit_overall.mat';
animals = ["S","T"];
nanimal = length(animals);
models = ["Model1", "Model1t", "Model2", "Model2t", "Model3", "Model3t"];
nmodel = length(models);
if exist(modelname, 'file')
    xfit = W.load(modelname);
else
    xfit = cell(nmodel, nanimal);
end
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
        if isempty(xfit{modeli, ai}) || xfit{modeli, ai}.LL < -5000
            md = feval(funcs{modeli});
            xfit{modeli, ai} = RLopt.train(md);
        end
    end
end
W.save('../../TempData/modelfit_overall.mat', 'xfit', xfit);