%% Non-cross-validated value and residual-motor coding dimensions
% For each neuron, the value coefficient is estimated from the nine
% condition-mean responses. The fitted DV contribution is then removed
% from every trial, and release1 is regressed onto the residual response.

run('../W_setup.m');
data = W.load('../../TempData/data');
go = data.go;
cue = data.cue;
plt = SW_plt_from_yml('../fig.yml');
plt.overwrite_on;

training_window = [0 250];
baseline_window = [-250 0];
minimum_cells = 10;
n_bootstrap = 1000;
yellow_color = [0.90 0.65 0.05];
purple_color = [0.55 0.25 0.72];
motor_colors = {[0.65 0.65 0.65], [0.10 0.10 0.10]};
cue_labels = ["Yellow first", "Purple first"];
motor_labels = ["Release second", "Release first"];
animal_names = string(plt.custom_vars.name_monkeys(1:numel(go)));

coding = struct;
coding.settings = W.struct( ...
    'lock_event', 'GO signal', ...
    'training_window_ms', training_window, ...
    'baseline_window_ms', baseline_window, ...
    'value_definition', 'Model 1 DV_overall', ...
    'value_model', ...
    'nine condition means: z(FR) ~ 1 + z(DV_overall)', ...
    'motor_model', ...
    'trial level: z(DV-residual FR) ~ 1 + release1', ...
    'is_crossvalidated', false, ...
    'matched_trajectory', ...
    'condition x cue1 x release1 counts equalized', ...
    'unmatched_trajectory', ...
    'cue1 counts equalized within condition; release1 left natural', ...
    'n_bootstrap', n_bootstrap);
animal_results = cell(numel(go), 1);

for animal_index = 1:numel(go)
    d = go{animal_index};
    time_at = double(d.time_at(:)');
    training_mask = time_at >= training_window(1) & ...
        time_at < training_window(2);
    baseline_mask = time_at >= baseline_window(1) & ...
        time_at < baseline_window(2);
    assert(any(training_mask) && any(baseline_mask), ...
        'Training and baseline windows must contain GO-aligned samples.');

    n_cells = numel(d.cells);
    n_times = numel(time_at);
    beta_dv = nan(n_cells, 1);
    beta_motor = nan(n_cells, 1);
    cue_matched = nan(n_cells, 2, n_times);
    cue_unmatched = nan(n_cells, 2, n_times);
    motor_trajectory = nan(n_cells, 2, n_times);
    n_matched = zeros(n_cells, 2);
    n_unmatched = zeros(n_cells, 2);

    for cell_index = 1:n_cells
        spikes = double(d.cells{cell_index});
        game_id = d.info_cells.gameID(cell_index);
        game = d.games{game_id};
        assert(size(spikes, 1) == height(game), ...
            'Spike trials and behavioral trials must match for every cell.');
        assert(ismember('DV_overall', game.Properties.VariableNames), ...
            'Every game table must contain Model 1 DV_overall.');

        trial_response = mean(spikes(:, training_mask), 2, 'omitnan');
        valid_trial = isfinite(trial_response) & ...
            isfinite(double(game.DV_overall)) & ...
            isfinite(double(game.release1)) & ...
            isfinite(double(game.condition)) & ...
            ismember(string(game.cue1), ["yellow", "purple"]);
        response_scale = std(trial_response(valid_trial), 0);
        if ~isfinite(response_scale) || response_scale <= eps
            continue;
        end

        % Fit DV to the nine equally weighted condition means.
        condition_response = nan(9, 1);
        condition_dv = nan(9, 1);
        for condition_index = 1:9
            condition_trial = valid_trial & ...
                game.condition == condition_index;
            if ~any(condition_trial)
                continue;
            end
            condition_response(condition_index) = mean( ...
                trial_response(condition_trial), 'omitnan');
            condition_dv(condition_index) = mean( ...
                double(game.DV_overall(condition_trial)), 'omitnan');
        end
        if any(~isfinite(condition_response)) || ...
                any(~isfinite(condition_dv))
            continue;
        end
        dv_center = mean(condition_dv);
        dv_scale = std(condition_dv, 0);
        if ~isfinite(dv_scale) || dv_scale <= eps
            continue;
        end
        condition_dv_z = (condition_dv - dv_center)/dv_scale;
        value_design = [ones(9, 1), condition_dv_z];
        value_coefficients_raw = value_design\condition_response;
        beta_dv(cell_index) = ...
            value_coefficients_raw(2)/response_scale;

        % Remove the condition-mean DV fit from every trial, then regress
        % the residual response on release1 at the individual-trial level.
        trial_dv_z = (double(game.DV_overall(valid_trial)) - ...
            dv_center)/dv_scale;
        predicted_value_response = [ ...
            ones(sum(valid_trial), 1), trial_dv_z] * ...
            value_coefficients_raw;
        residual_response = trial_response(valid_trial) - ...
            predicted_value_response;
        residual_scale = std(residual_response, 0);
        if ~isfinite(residual_scale) || residual_scale <= eps
            continue;
        end
        residual_z = (residual_response - ...
            mean(residual_response))/residual_scale;
        motor_predictor = double(game.release1(valid_trial));
        motor_design = [ones(numel(residual_z), 1), motor_predictor];
        if rank(motor_design) < size(motor_design, 2)
            continue;
        end
        motor_coefficients = motor_design\residual_z;
        beta_motor(cell_index) = motor_coefficients(2);

        groups = make_trajectory_groups( ...
            game, valid_trial, 10000*animal_index + cell_index);
        if ~groups.is_valid
            continue;
        end
        for cue_index = 1:2
            cue_matched(cell_index, cue_index, :) = ...
                standardized_trajectory(spikes, ...
                groups.cue_matched{cue_index}, baseline_mask, ...
                response_scale);
            cue_unmatched(cell_index, cue_index, :) = ...
                standardized_trajectory(spikes, ...
                groups.cue_unmatched{cue_index}, baseline_mask, ...
                response_scale);
            n_matched(cell_index, cue_index) = ...
                numel(groups.cue_matched{cue_index});
            n_unmatched(cell_index, cue_index) = ...
                numel(groups.cue_unmatched{cue_index});
        end
        for motor_index = 1:2
            motor_trajectory(cell_index, motor_index, :) = ...
                standardized_trajectory(spikes, ...
                groups.motor{motor_index}, baseline_mask, response_scale);
        end
    end

    finite_matched = all(isfinite(reshape( ...
        cue_matched, n_cells, [])), 2);
    finite_unmatched = all(isfinite(reshape( ...
        cue_unmatched, n_cells, [])), 2);
    finite_motor = all(isfinite(reshape( ...
        motor_trajectory, n_cells, [])), 2);
    valid_value_cell = isfinite(beta_dv) & ...
        finite_matched & finite_unmatched;
    valid_motor_cell = isfinite(beta_motor) & ...
        finite_matched & finite_motor;
    assert(sum(valid_value_cell) >= minimum_cells, ...
        'Only %d valid value-axis cells remain for %s.', ...
        sum(valid_value_cell), animal_names(animal_index));
    assert(sum(valid_motor_cell) >= minimum_cells, ...
        'Only %d valid motor-axis cells remain for %s.', ...
        sum(valid_motor_cell), animal_names(animal_index));

    value_beta = beta_dv(valid_value_cell);
    value_axis_unit = value_beta/norm(value_beta);
    [value_matched_projection, value_matched_ci] = ...
        bootstrap_projection(value_beta, value_axis_unit, ...
        cue_matched(valid_value_cell, :, :), n_bootstrap);
    [value_unmatched_projection, value_unmatched_ci] = ...
        bootstrap_projection(value_beta, value_axis_unit, ...
        cue_unmatched(valid_value_cell, :, :), n_bootstrap);

    motor_beta = beta_motor(valid_motor_cell);
    motor_axis_unit = motor_beta/norm(motor_beta);
    [motor_cue_projection, motor_cue_ci] = ...
        bootstrap_projection(motor_beta, motor_axis_unit, ...
        cue_matched(valid_motor_cell, :, :), n_bootstrap);
    [motor_validation_projection, motor_validation_ci] = ...
        bootstrap_projection(motor_beta, motor_axis_unit, ...
        motor_trajectory(valid_motor_cell, :, :), n_bootstrap);

    result = struct;
    result.name = animal_names(animal_index);
    result.time_at = time_at;
    result.info_cells_value = d.info_cells(valid_value_cell, :);
    result.info_cells_motor = d.info_cells(valid_motor_cell, :);
    result.beta_dv = value_beta;
    result.beta_motor = motor_beta;
    result.value_axis_unit = value_axis_unit;
    result.motor_axis_unit = motor_axis_unit;
    result.value_matched_projection = value_matched_projection;
    result.value_matched_ci95 = value_matched_ci;
    result.value_unmatched_projection = value_unmatched_projection;
    result.value_unmatched_ci95 = value_unmatched_ci;
    result.motor_cue_projection = motor_cue_projection;
    result.motor_cue_ci95 = motor_cue_ci;
    result.motor_validation_projection = motor_validation_projection;
    result.motor_validation_ci95 = motor_validation_ci;
    result.n_matched = n_matched(valid_value_cell, :);
    result.n_unmatched = n_unmatched(valid_value_cell, :);
    animal_results{animal_index} = result;
end
coding.animals = vertcat(animal_results{:});

%% Define a cue-locked YP dimension and align it with the value axis
yp_window = [0 250];
coding.settings.yp_training_window_ms = yp_window;
coding.settings.yp_model = ...
    'trial level: z(FR) ~ 1 + z(DV_overall) + I(yellow first)';
coding.settings.yp_positive_direction = 'yellow first minus purple first';
coding.settings.cosine_permutations = 10000;
for animal_index = 1:numel(cue)
    yp_result = fit_yp_dimension(cue{animal_index}, yp_window);
    value_info = coding.animals(animal_index).info_cells_value;
    [is_shared, cue_row] = ismember(value_info, ...
        yp_result.info_cells, 'rows');
    beta_value = coding.animals(animal_index).beta_dv;
    beta_yp = nan(size(beta_value));
    beta_yp(is_shared) = yp_result.beta_yp(cue_row(is_shared));
    valid_axis = is_shared & isfinite(beta_value) & isfinite(beta_yp);
    assert(sum(valid_axis) >= minimum_cells, ...
        'Too few shared finite neurons for the YP/value cosine.');
    beta_value = beta_value(valid_axis);
    beta_yp = beta_yp(valid_axis);
    [cosine_value_yp, cosine_p] = permutation_cosine( ...
        beta_value, beta_yp, coding.settings.cosine_permutations, ...
        20000 + animal_index);
    coding.animals(animal_index).info_cells_yp_value = ...
        value_info(valid_axis, :);
    coding.animals(animal_index).beta_value_for_cosine = beta_value;
    coding.animals(animal_index).beta_yp = beta_yp;
    coding.animals(animal_index).yp_value_cosine = cosine_value_yp;
    coding.animals(animal_index).yp_value_cosine_p = cosine_p;
end

W.save('../../TempData/codex_pilot_motor', 'coding', coding);

%% Plot cue-order trajectories on the condition-mean value axis
x_limits = [-250 1000];
x_ticks = -250:250:1000;
plot_two_animal_figure(plt, coding.animals, ...
    'value_matched_projection', 'value_matched_ci95', ...
    {yellow_color, purple_color}, cue_labels, ...
    'Value-axis projection', animal_names, x_limits, x_ticks, ...
    'pilot value dimension');

unmatched_titles = animal_names + " (motor unmatched)";
plot_two_animal_figure(plt, coding.animals, ...
    'value_unmatched_projection', 'value_unmatched_ci95', ...
    {yellow_color, purple_color}, cue_labels, ...
    'Value-axis projection', unmatched_titles, x_limits, x_ticks, ...
    'pilot value dimension unmatched');

%% Plot YP/value-axis cosine similarity
cosine_values = [coding.animals.yp_value_cosine];
cosine_p = [coding.animals.yp_value_cosine_p];
plt.figure(1, 1, 'is_title', 'all', ...
    'pixel_w', 430, 'pixel_h', 350);
plt.ax(1, 1);
ax = gca;
hold(ax, 'on');
bar(ax, 1:numel(cosine_values), cosine_values, 0.65, ...
    'FaceColor', [0.25 0.25 0.25], 'EdgeColor', 'none');
yline(ax, 0, '-', 'Color', [0.55 0.55 0.55], ...
    'HandleVisibility', 'off');
for animal_index = 1:numel(cosine_values)
    text(ax, animal_index, cosine_values(animal_index), ...
        sprintf('  cos = %.2f\np_{perm} = %.3f', ...
        cosine_values(animal_index), cosine_p(animal_index)), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', vertical_alignment(cosine_values(animal_index)));
end
xlim(ax, [0.4 numel(cosine_values) + 0.6]);
ylim(ax, [-1 1]);
xticks(ax, 1:numel(cosine_values));
xticklabels(ax, animal_names);
ylabel(ax, 'Cosine similarity');
title(ax, 'Cue-locked YP axis vs. GO-locked value axis');
plt.addABCs('A');
plt.update('pilot YP value cosine');

%% Plot the residual-motor dimension and its response contrast
plt.figure(2, numel(go), 'is_title', 'all', ...
    'pixel_w', 420, 'pixel_h', 310);
for animal_index = 1:numel(go)
    result = coding.animals(animal_index);
    plt.ax(1, animal_index);
    plot_projection(gca, result.time_at, result.motor_cue_projection, ...
        result.motor_cue_ci95, {yellow_color, purple_color}, cue_labels, ...
        x_limits, x_ticks, 'Residual-motor-axis projection', ...
        animal_names(animal_index), animal_index == numel(go));
    plt.ax(2, animal_index);
    plot_projection(gca, result.time_at, ...
        result.motor_validation_projection, ...
        result.motor_validation_ci95, motor_colors, motor_labels, ...
        x_limits, x_ticks, 'Residual-motor-axis projection', ...
        'Motor-response contrast', animal_index == numel(go));
end
plt.addABCs('ABCD');
plt.update('pilot motor dimension');


function result = fit_yp_dimension(d, training_window)
%FIT_YP_DIMENSION Fit DV and cue-order coefficients on cue-locked trials.
    time_at = double(d.time_at(:)');
    training_mask = time_at >= training_window(1) & ...
        time_at < training_window(2);
    assert(any(training_mask), ...
        'The YP training window must contain cue-aligned samples.');
    n_cells = numel(d.cells);
    beta_yp = nan(n_cells, 1);
    for cell_index = 1:n_cells
        spikes = double(d.cells{cell_index});
        game = d.games{d.info_cells.gameID(cell_index)};
        assert(size(spikes, 1) == height(game), ...
            'Cue-aligned spike trials and behavior must match.');
        trial_response = mean(spikes(:, training_mask), 2, 'omitnan');
        dv = double(game.DV_overall);
        is_yellow = double(string(game.cue1) == "yellow");
        valid_trial = isfinite(trial_response) & isfinite(dv) & ...
            ismember(string(game.cue1), ["yellow", "purple"]);
        response = trial_response(valid_trial);
        dv = dv(valid_trial);
        is_yellow = is_yellow(valid_trial);
        response_scale = std(response, 0);
        dv_scale = std(dv, 0);
        if numel(response) < 4 || ...
                ~isfinite(response_scale) || response_scale <= eps || ...
                ~isfinite(dv_scale) || dv_scale <= eps
            continue;
        end
        response_z = (response - mean(response))/response_scale;
        dv_z = (dv - mean(dv))/dv_scale;
        design = [ones(numel(response), 1), dv_z, is_yellow];
        if rank(design) < size(design, 2)
            continue;
        end
        coefficients = design\response_z;
        beta_yp(cell_index) = coefficients(3);
    end
    valid_cell = isfinite(beta_yp);
    result.info_cells = d.info_cells(valid_cell, :);
    result.beta_yp = beta_yp(valid_cell);
end


function [observed_cosine, p_value] = permutation_cosine( ...
        axis_1, axis_2, n_permutations, random_seed)
%PERMUTATION_COSINE Test an axis cosine by permuting neuron identities.
    axis_1 = axis_1(:);
    axis_2 = axis_2(:);
    denominator = norm(axis_1)*norm(axis_2);
    assert(isfinite(denominator) && denominator > 0, ...
        'Both axes must have finite nonzero norms.');
    observed_cosine = dot(axis_1, axis_2)/denominator;
    random_stream = RandStream('mt19937ar', 'Seed', random_seed);
    null_cosine = nan(n_permutations, 1);
    for permutation_index = 1:n_permutations
        shuffled = axis_2(randperm(random_stream, numel(axis_2)));
        null_cosine(permutation_index) = ...
            dot(axis_1, shuffled)/denominator;
    end
    p_value = (1 + sum(abs(null_cosine) >= ...
        abs(observed_cosine)))/(n_permutations + 1);
end


function alignment = vertical_alignment(value)
%VERTICAL_ALIGNMENT Place a bar label outside the bar endpoint.
    if value >= 0
        alignment = 'bottom';
    else
        alignment = 'top';
    end
end


function groups = make_trajectory_groups(game, valid_trial, random_seed)
%MAKE_TRAJECTORY_GROUPS Construct matched and motor-unmatched trial sets.
    n_conditions = 9;
    cue_values = ["yellow", "purple"];
    motor_values = [0 1];
    random_stream = RandStream('mt19937ar', 'Seed', random_seed);
    groups.cue_matched = {zeros(0, 1), zeros(0, 1)};
    groups.cue_unmatched = {zeros(0, 1), zeros(0, 1)};
    groups.motor = {zeros(0, 1), zeros(0, 1)};

    for condition_index = 1:n_conditions
        four_groups = cell(2, 2);
        for cue_index = 1:2
            for motor_index = 1:2
                four_groups{cue_index, motor_index} = find( ...
                    valid_trial & game.condition == condition_index & ...
                    string(game.cue1) == cue_values(cue_index) & ...
                    game.release1 == motor_values(motor_index));
            end
        end
        n_four_way = min(cellfun(@numel, four_groups), [], 'all');
        if n_four_way > 0
            for cue_index = 1:2
                for motor_index = 1:2
                    available = four_groups{cue_index, motor_index};
                    selected = available(randperm(random_stream, ...
                        numel(available), n_four_way));
                    groups.cue_matched{cue_index} = [ ...
                        groups.cue_matched{cue_index}; selected(:)];
                    groups.motor{motor_index} = [ ...
                        groups.motor{motor_index}; selected(:)];
                end
            end
        end

        cue_groups = cell(1, 2);
        for cue_index = 1:2
            cue_groups{cue_index} = find( ...
                valid_trial & game.condition == condition_index & ...
                string(game.cue1) == cue_values(cue_index));
        end
        n_cue_matched = min(cellfun(@numel, cue_groups));
        if n_cue_matched > 0
            for cue_index = 1:2
                available = cue_groups{cue_index};
                selected = available(randperm(random_stream, ...
                    numel(available), n_cue_matched));
                groups.cue_unmatched{cue_index} = [ ...
                    groups.cue_unmatched{cue_index}; selected(:)];
            end
        end
    end
    groups.is_valid = ...
        all(cellfun(@numel, groups.cue_matched) >= 2) && ...
        all(cellfun(@numel, groups.cue_unmatched) >= 2) && ...
        all(cellfun(@numel, groups.motor) >= 2);
end


function trajectory = standardized_trajectory( ...
        spikes, trial_id, baseline_mask, response_scale)
%STANDARDIZED_TRAJECTORY Return baseline-corrected standardized activity.
    trajectory = mean(spikes(trial_id, :), 1, 'omitnan');
    baseline = mean(trajectory(baseline_mask), 'omitnan');
    trajectory = (trajectory - baseline)/response_scale;
end


function [projection, ci95] = bootstrap_projection( ...
        beta, axis_unit, trajectories, n_bootstrap)
%BOOTSTRAP_PROJECTION Project activity and bootstrap neurons for a 95% CI.
    n_cells = numel(beta);
    n_groups = size(trajectories, 2);
    n_times = size(trajectories, 3);
    projection = reshape(axis_unit' * ...
        reshape(trajectories, n_cells, []), n_groups, n_times);
    bootstrap_values = nan(n_bootstrap, n_groups, n_times);
    for bootstrap_index = 1:n_bootstrap
        sampled_cell = randi(n_cells, n_cells, 1);
        sampled_beta = beta(sampled_cell);
        sampled_axis = sampled_beta/norm(sampled_beta);
        sampled_trajectory = trajectories(sampled_cell, :, :);
        bootstrap_values(bootstrap_index, :, :) = reshape( ...
            sampled_axis' * reshape(sampled_trajectory, n_cells, []), ...
            1, n_groups, n_times);
    end
    ci95 = permute(prctile(bootstrap_values, [2.5 97.5], 1), ...
        [2 3 1]);
end


function plot_two_animal_figure(plt, animals, projection_field, ...
        ci_field, colors, group_labels, y_label, panel_titles, ...
        x_limits, x_ticks, figure_name)
%PLOT_TWO_ANIMAL_FIGURE Plot one projection panel for each animal.
    n_animals = numel(animals);
    plt.figure(1, n_animals, 'is_title', 'all', ...
        'pixel_w', 420, 'pixel_h', 310);
    for animal_index = 1:n_animals
        result = animals(animal_index);
        plt.ax(1, animal_index);
        plot_projection(gca, result.time_at, ...
            result.(projection_field), result.(ci_field), ...
            colors, group_labels, x_limits, x_ticks, y_label, ...
            panel_titles(animal_index), animal_index == n_animals);
    end
    plt.addABCs('AB');
    plt.update(figure_name);
end


function plot_projection(ax, time_at, projection, ci95, colors, ...
        group_labels, x_limits, x_ticks, y_label, panel_title, show_legend)
%PLOT_PROJECTION Plot two trajectories and neuron-bootstrap intervals.
    hold(ax, 'on');
    for group_index = 1:2
        lower = reshape(ci95(group_index, :, 1), 1, []);
        upper = reshape(ci95(group_index, :, 2), 1, []);
        fill(ax, [time_at fliplr(time_at)], ...
            [lower fliplr(upper)], colors{group_index}, ...
            'FaceAlpha', 0.18, 'EdgeColor', 'none', ...
            'HandleVisibility', 'off');
        plot(ax, time_at, projection(group_index, :), ...
            'Color', colors{group_index}, 'LineWidth', 1.8);
    end
    xline(ax, 0, '--', 'Color', [0.35 0.35 0.35], ...
        'HandleVisibility', 'off');
    yline(ax, 0, '-', 'Color', [0.65 0.65 0.65], ...
        'HandleVisibility', 'off');
    xlim(ax, x_limits);
    xticks(ax, x_ticks);
    xlabel(ax, 'Time from GO signal (ms)');
    ylabel(ax, y_label);
    title(ax, panel_title);
    if show_legend
        legend(ax, cellstr(group_labels), 'Location', 'best', 'Box', 'off');
    end
end
