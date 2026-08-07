%% Monkey S behavior and model fits across training
% Combines the early behavioral sessions in TempData/Seam_training with the
% later recording sessions in Data. Only Monkey S folders (S*) are loaded.

script_file = mfilename('fullpath');
behavior_dir = fileparts(script_file);
codes_dir = fileparts(behavior_dir);
project_dir = fileparts(codes_dir);

if ~exist('plt', 'var')
    run(fullfile(codes_dir, 'W_setup.m'));
    plt = SW_plt_from_yml(fullfile(codes_dir, 'fig.yml'));
end
if ~exist('isoverwrite', 'var')
    isoverwrite = false;
end

early_dir = fullfile(project_dir, 'TempData', 'Seam_training');
late_dir = fullfile(project_dir, 'Data');
[training_games, training_sessions, training_phase] = ...
    load_seam_training_games(early_dir, late_dir);
n_sessions = numel(training_games);
n_early = sum(training_phase == "Early training");
assert(n_early > 0 && n_early < n_sessions, ...
    'Both early-training and late-recording sessions are required.');

% %% Behavior: yellow-first and purple-first acceptance across sessions
% condition_drop = double(plt.custom_vars.drop(:)');
% condition_delay = double(plt.custom_vars.delay(:)');
% n_conditions = numel(condition_drop);
% cue_order = ["yellow", "purple"];
% p_accept = nan(n_sessions, n_conditions, numel(cue_order));
% n_trials = zeros(size(p_accept));
% 
% for sessioni = 1:n_sessions
%     game = training_games{sessioni};
%     for conditioni = 1:n_conditions
%         offer_id = game.drop == condition_drop(conditioni) & ...
%             game.delay == condition_delay(conditioni);
%         for cuei = 1:numel(cue_order)
%             trial_id = offer_id & string(game.cue1) == cue_order(cuei);
%             n_trials(sessioni, conditioni, cuei) = sum(trial_id);
%             if any(trial_id)
%                 p_accept(sessioni, conditioni, cuei) = ...
%                     mean(game.choice(trial_id));
%             end
%         end
%     end
% end
% assert(all(sum(n_trials, 1) > 0, 'all'), ...
%     'An offer-by-cue combination is absent from the combined dataset.');
% 
session_x = 1:n_sessions;
[tick_id, tick_labels] = training_ticks(training_sessions);
yellow_color = plt.custom_vars.color_yellowpurple{1};
purple_color = plt.custom_vars.color_yellowpurple{2};
% 
% plt.figure(3, 3, 'is_title', 'all', ...
%     'pixel_w', 340, 'pixel_h', 280);
% for conditioni = 1:n_conditions
%     rowi = ceil(conditioni/3);
%     coli = mod(conditioni - 1, 3) + 1;
%     plt.ax(rowi, coli);
%     plot_condition_training(gca, session_x, ...
%         p_accept(:, conditioni, :), n_early, tick_id, tick_labels, ...
%         condition_drop(conditioni), condition_delay(conditioni), ...
%         yellow_color, purple_color, conditioni == 1, ...
%         conditioni == n_conditions);
% end
% plt.addABCs('ABCDEFGHI');
% plt.update('Seam training behavior');

%% Models: fit the same six models used by main_1_fitRL
model_classes = ["Model1", "Model1t", "Model2", ...
    "Model2t", "Model3", "Model3t"];
model_labels = ["Model 1", "Model 1v", "Model 2", ...
    "Model 2v", "Model 3", "Model 3v"];
model_functions = arrayfun(@str2func, model_classes, ...
    'UniformOutput', false);
n_models = numel(model_classes);
cache_file = fullfile(project_dir, 'TempData', ...
    'modelfit_Seam_training.mat');
xfit_training = cell(n_models, n_sessions);

if exist(cache_file, 'file') && ~isoverwrite
    cached = load(cache_file);
    cache_matches = isfield(cached, 'xfit_training') && ...
        isfield(cached, 'training_sessions') && ...
        isfield(cached, 'model_classes') && ...
        isequal(string(cached.training_sessions), training_sessions) && ...
        isequal(string(cached.model_classes), model_classes) && ...
        isequal(size(cached.xfit_training), [n_models n_sessions]);
    if cache_matches
        xfit_training = cached.xfit_training;
    end
end

condition_behavior = cellfun(@compute_cond_vs_choice, ...
    training_games, 'UniformOutput', false);
for sessioni = 1:n_sessions
    behavior = condition_behavior{sessioni};
    R = behavior.drop;
    D = behavior.delay;
    Y = behavior.cue1 == "yellow";
    nA = behavior.n_accept;
    nT = behavior.n_total;
    session_was_refit = false;
    for modeli = 1:n_models
        model = feval(model_functions{modeli});
        required_fields = [model.name_parameters, {'LL', 'AIC', 'BIC'}];
        fit_is_valid = isstruct(xfit_training{modeli, sessioni}) && ...
            all(isfield(xfit_training{modeli, sessioni}, required_fields));
        if isoverwrite || ~fit_is_valid
            fprintf('Seam training: fitting %s, session %s\n', ...
                model_classes(modeli), training_sessions(sessioni));
            rng(1000*sessioni + modeli, 'twister');
            xfit_training{modeli, sessioni} = fit_model( ...
                model, R, D, Y, nA, nT);
            session_was_refit = true;
        end
    end
    if session_was_refit
        save(cache_file, 'xfit_training', 'training_sessions', ...
            'training_phase', 'model_classes');
    end
end

AIC = cellfun(@(fit)fit.AIC, xfit_training);
assert(all(isfinite(AIC), 'all'), ...
    'Every training-session model fit must have finite AIC.');
delta_AIC = AIC - min(AIC, [], 1);
[~, best_model] = min(AIC, [], 1);
is_early = training_phase == "Early training";
p_best = nan(2, n_models);
p_best(1, :) = arrayfun(@(modeli)mean(best_model(is_early) == modeli), ...
    1:n_models);
p_best(2, :) = arrayfun(@(modeli)mean(best_model(~is_early) == modeli), ...
    1:n_models);

plt.figure(1, 1, 'is_title', 'all', ...
    'pixel_w', 400, 'pixel_h', 400, 'gapW_custom', [1 0], 'gapH_custom', [1 1]);
plt.ax(1, 1);
% plot_delta_aic(gca, session_x, delta_AIC, n_early, tick_id, ...
%     tick_labels, model_labels);
% plt.ax(1, 2);
plot_best_model_timeline(gca, session_x, best_model, n_early, ...
    tick_id, tick_labels, model_labels);
% plt.ax(1, 3);
% plot_best_model_proportions(gca, p_best, model_labels);
plt.addABCs('ABC');
plt.update('Seam training models');

%% Local functions
function [games, session_names, phase] = ...
        load_seam_training_games(early_dir, late_dir)
    early_files = dir(fullfile(early_dir, 'S*', 'games.mat'));
    late_files = dir(fullfile(late_dir, 'S*', 'games.mat'));
    assert(~isempty(early_files), ...
        'No Monkey S games.mat files found in %s.', early_dir);
    assert(~isempty(late_files), ...
        'No Monkey S games.mat files found in %s.', late_dir);

    files = [early_files; late_files];
    phase = [repmat("Early training", numel(early_files), 1); ...
        repmat("Late recording", numel(late_files), 1)];
    session_names = strings(numel(files), 1);
    for filei = 1:numel(files)
        [~, session_names(filei)] = fileparts(files(filei).folder);
    end
    assert(numel(unique(session_names)) == numel(session_names), ...
        'Duplicate Monkey S session folders were found.');
    [session_names, order] = sort(session_names);
    files = files(order);
    phase = phase(order);

    required_variables = {'is_complete', 'is_post_error', 'cue1', ...
        'choice', 'drop', 'delay'};
    games = cell(numel(files), 1);
    for filei = 1:numel(files)
        loaded = load(fullfile(files(filei).folder, files(filei).name));
        assert(isfield(loaded, 'data') && istable(loaded.data), ...
            '%s must contain a table named data.', ...
            fullfile(files(filei).folder, files(filei).name));
        game = loaded.data;
        assert(all(ismember(required_variables, ...
            game.Properties.VariableNames)), ...
            'Session %s is missing required game variables.', ...
            session_names(filei));
        valid = logical(game.is_complete) & ...
            ~logical(game.is_post_error) & ...
            isfinite(game.choice) & isfinite(game.drop) & ...
            isfinite(game.delay) & strlength(string(game.cue1)) > 0;
        game = game(valid, :);
        assert(~isempty(game), 'Session %s has no valid trials.', ...
            session_names(filei));
        assert(all(ismember(unique(game.drop), [2 4 6])) && ...
            all(ismember(unique(game.delay), [1 5 10])) && ...
            all(ismember(unique(string(game.cue1)), ...
            ["yellow", "purple"])), ...
            'Session %s contains an unexpected task condition.', ...
            session_names(filei));
        games{filei} = game;
    end
end

function [tick_id, tick_labels] = training_ticks(session_names)
    tick_id = unique(round(linspace(1, numel(session_names), 7)));
    dates = datetime(extractAfter(session_names(tick_id), 1), ...
        'InputFormat', 'yyMMdd');
    tick_labels = string(dates, 'MM/dd/yy');
end

function mark_training_boundary(ax, n_early, show_label)
    if nargin < 3
        show_label = false;
    end
    if show_label
        boundary_label = 'Late recording begins';
    else
        boundary_label = '';
    end
    xline(ax, n_early + 0.5, '--', boundary_label, ...
        'Color', [0.25 0.25 0.25], 'LineWidth', 1.2, ...
        'LabelOrientation', 'aligned', ...
        'LabelVerticalAlignment', 'middle', ...
        'HandleVisibility', 'off');
end

function format_training_xaxis(ax, n_sessions, tick_id, tick_labels)
    xlim(ax, [0.5 n_sessions + 0.5]);
    xticks(ax, tick_id);
    xticklabels(ax, tick_labels);
    xtickangle(ax, 35);
    xlabel(ax, 'Session date');
end

function plot_condition_training(ax, session_x, condition_accept, ...
        n_early, tick_id, tick_labels, drop, delay, ...
        yellow_color, purple_color, label_boundary, show_legend)
    condition_accept = squeeze(condition_accept);
    hold(ax, 'on');
    plot(ax, session_x, condition_accept(:, 2), '-o', ...
        'Color', purple_color, 'MarkerFaceColor', purple_color, ...
        'MarkerSize', 3, 'LineWidth', 1.1);
    plot(ax, session_x, condition_accept(:, 1), '-o', ...
        'Color', yellow_color, 'MarkerFaceColor', yellow_color, ...
        'MarkerSize', 3, 'LineWidth', 1.1);
    mark_training_boundary(ax, n_early, label_boundary);
    format_training_xaxis(ax, numel(session_x), tick_id, tick_labels);
    ylim(ax, [0 1]);
    yticks(ax, 0:0.2:1);
    yticklabels(ax, 0:20:100);
    ylabel(ax, 'p(accept) (%)');
    title(ax, sprintf('%d drops, %d s delay', drop, delay));
    if show_legend
        legend(ax, {'Purple first', 'Yellow first'}, ...
            'Location', 'best', 'Box', 'off');
    end
end

function plot_delta_aic(ax, session_x, delta_AIC, n_early, ...
        tick_id, tick_labels, model_labels)
    display_limit = 50;
    imagesc(ax, session_x, 1:numel(model_labels), ...
        min(delta_AIC, display_limit), [0 display_limit]);
    colormap(ax, flipud(gray(256)));
    colorbar(ax);
    mark_training_boundary(ax, n_early);
    format_training_xaxis(ax, numel(session_x), tick_id, tick_labels);
    yticks(ax, 1:numel(model_labels));
    yticklabels(ax, model_labels);
    ylabel(ax, 'Choice model');
    title(ax, 'Relative model evidence');
end

function plot_best_model_timeline(ax, session_x, best_model, n_early, ...
        tick_id, tick_labels, model_labels)
    hold(ax, 'on');
    plot(ax, session_x, best_model, '-', 'Color', [0.7 0.7 0.7], ...
        'LineWidth', 0.8, 'HandleVisibility', 'off');
    scatter(ax, session_x, best_model, 26, best_model, 'filled');
    colormap(ax, lines(numel(model_labels)));
    mark_training_boundary(ax, n_early);
    format_training_xaxis(ax, numel(session_x), tick_id, tick_labels);
    ylim(ax, [0.5 numel(model_labels) + 0.5]);
    yticks(ax, 1:numel(model_labels));
    yticklabels(ax, model_labels);
    ylabel(ax, 'Lowest-AIC model');
    title(ax, 'Best-fitting model by session');
end

function plot_best_model_proportions(ax, p_best, model_labels)
    b = bar(ax, 1:numel(model_labels), p_best', 'grouped');
    b(1).FaceColor = [0.72 0.72 0.72];
    b(2).FaceColor = [0.20 0.20 0.20];
    xticks(ax, 1:numel(model_labels));
    xticklabels(ax, model_labels);
    xtickangle(ax, 35);
    ylim(ax, [0 1]);
    yticks(ax, 0:0.2:1);
    ylabel(ax, 'Proportion best fit');
    title(ax, 'Early versus late sessions');
    legend(ax, {'Early training', 'Late recording'}, ...
        'Location', 'best', 'Box', 'off');
end
