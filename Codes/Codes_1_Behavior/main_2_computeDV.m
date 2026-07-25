%% Calculate Model 1 discounted values
data = W.load('../../TempData/cue');
games = data.games;
ani_gm = unique(data.info_cells(:, ["animal", "gameID"]));
fit_session = W.load('../../TempData/modelfit_session');
fit_overall = W.load('../../TempData/modelfit_overall');
animals = ["S", "T"];

assert(numel(games) == height(ani_gm), ...
    'The number of games does not match the animal/game lookup table.');
assert(size(fit_session, 2) == numel(games), ...
    'The number of session fits does not match the number of games.');

DVgames = cell(size(games));
parfor xi = 1:numel(games)
    g = games{xi};
    animal_index = find(animals == ani_gm.animal(xi), 1);
    assert(~isempty(animal_index), ...
        'No overall-fit column is defined for animal %s.', ani_gm.animal(xi));
    if animal_index == 1
        bmd = 6;
    else
        bmd = 4;
    end
    session_fit = fit_session{1, xi}; % Model 1, session-specific fit
    session_best = fit_session{bmd, xi}; % Model 1, session-specific fit
    overall_fit = fit_overall{1, animal_index}; % Model 1, pooled animal fit
    overall_best = fit_overall{bmd, animal_index};
    g.DV = compute_DV(g.drop, g.delay, session_fit.k);
    g.DVbest = compute_DV(g.drop, g.delay, session_best.k);
    g.DV_overall = compute_DV(g.drop, g.delay, overall_fit.k);
    g.DVbest_overall = compute_DV(g.drop, g.delay, overall_best.k);

    % % Preserve the Model 1 choice predictions used by downstream scripts.
    % model = Model1();
    % params = [overall_fit.beta, overall_fit.k, overall_fit.thres];
    % g.is_yellow_1st = g.cue1 == "yellow";
    % g.pred_accept = model.policy( ...
    %     params, g.drop, g.delay, g.is_yellow_1st);
    % g.action_likelihood = g.choice .* g.pred_accept + ...
    %     (1 - g.choice) .* (1 - g.pred_accept);
    % g.pred_release = (~g.is_yellow_1st) .* g.pred_accept + ...
    %     g.is_yellow_1st .* (1 - g.pred_accept);
    DVgames{xi} = g;
end
% save game with DV
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

