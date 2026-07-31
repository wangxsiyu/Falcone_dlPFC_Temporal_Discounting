data = W.load('../../TempData/cue');
ani_gm = unique(data.info_cells(:, ["animal", "gameID"]));
behs = W.cellfun(@(x)compute_cond_vs_choice(x), data.games, false);
nsession = length(behs);
%% train model per session
modelname = '../../TempData/modelfit_session.mat';
models = ["Model1", "Model1t", "Model2", "Model2t", "Model3", "Model3t"];
nmodel = length(models);
if exist(modelname, 'file')
    xfit = W.load(modelname);
    % xfit = xfit(1:length(models),:);
else
    xfit = cell(nmodel, nsession);
end
funcs = W.arrayfun(@(x)str2func(x), models);
rng(0, 'twister');
for gi = 1:nsession
    g = behs{gi};
    R = g.drop;
    D = g.delay;
    Y = g.cue1 == "yellow";
    nT = g.n_total;
    nA = g.n_accept;
    for modeli = 1:nmodel
        md = feval(funcs{modeli});
        required_fields = [md.name_parameters, {'LL', 'AIC'}];
        needs_fit = size(xfit, 1) < modeli || isempty(xfit{modeli, gi}) || ...
            ~isstruct(xfit{modeli, gi}) || ...
            ~all(isfield(xfit{modeli, gi}, required_fields)) || isoverwrite;
        if needs_fit
            W.print('fitting model %d: session %d', modeli, gi);
            xfit{modeli, gi} = fit_model(md, R, D, Y, nA, nT);
        end
    end
end
W.save(modelname, 'xfit', xfit);
% %% check model fits
% W.cellfun_vertcat(@(x)x.LL, xfit)
%% train model overall
modelname = '../../TempData/modelfit_overall.mat';
animals = ["S","T"];
nanimal = length(animals);
if exist(modelname, 'file')
    xfit = W.load(modelname);
    % xfit = xfit(1:length(models),:);
else
    xfit = cell(nmodel, nanimal);
end
rng(0, 'twister');

for ai = 1:nanimal
    animal = animals(ai);
    animal_games = data.games(ani_gm.animal == animal);
    pooled_trials = vertcat(animal_games{:});
    g = compute_cond_vs_choice(pooled_trials);
    R = g.drop;
    D = g.delay;
    Y = g.cue1 == "yellow";
    nT = g.n_total;
    nA = g.n_accept;

    for modeli = 1:nmodel
        md = feval(funcs{modeli});
        required_fields = [md.name_parameters, {'LL', 'AIC'}];
        needs_fit = size(xfit, 1) < modeli || isempty(xfit{modeli, ai}) || ...
            ~isstruct(xfit{modeli, ai}) || ...
            ~all(isfield(xfit{modeli, ai}, required_fields)) || isoverwrite;
        if needs_fit
            W.print('fitting model %d: animal %s', modeli, animal);
            xfit{modeli, ai} = fit_model(md, R, D, Y, nA, nT);
        end
    end
end
W.save(modelname, 'xfit', xfit);
