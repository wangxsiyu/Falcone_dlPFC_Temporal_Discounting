%% Reproduce the ordered-raster and discounted-value correlation figure

data = W.load('../../TempData/data');
cue = data.cue;

%% Figure and analysis settings
cell_specs = [1 52; 2 27]; % [cue animal index, published cell ID]
animal_names = ["Monkey S", "Monkey T"];
panel_letters = ["A", "B"];

win_plot = [-500 1000];
analysis_window = [75 775];
n_conditions = 9;
condition_letters = ["a", "d", "g", "b", "e", "h", "c", "f", "i"];
reward_levels = [2 4 6];
reward_markers = {'o', 's', 'd'};

% Match Figure_Geometry_PCA: use Monkey T's DV ordering and a shared
% low-value red -> middle yellow -> high-value green scale.
reference_data = cue{2};
reference_dv_by_cell = nan(numel(reference_data.cells), n_conditions);
for reference_cell = 1:numel(reference_data.cells)
    reference_game = reference_data.games{ ...
        reference_data.info_cells.gameID(reference_cell)};
    for condition = 1:n_conditions
        reference_dv_by_cell(reference_cell, condition) = mean( ...
            reference_game.DV_overall( ...
            reference_game.condition == condition), 'omitnan');
    end
end
reference_dv = mean(reference_dv_by_cell, 1, 'omitnan');
[~, legend_order] = sort(reference_dv);
color_anchors = [min(reference_dv), ...
    reference_dv(legend_order(ceil(n_conditions/2))), ...
    max(reference_dv)];
condition_colors = nan(n_conditions, 3);
for condition = 1:n_conditions
    condition_colors(condition, :) = plt.interpolatecolors( ...
        {'RSred', 'yellow', 'RSgreen'}, color_anchors, ...
        reference_dv(condition));
end

point_label_dx = { ...
    [0.02 -0.04 0.02 0.02 -0.04 0.02 0.02 -0.02 0.02], ...
    [0.02 0.02 -0.04 0.02 -0.04 -0.04 0.02 0.02 0.02]};
point_label_dy = { ...
    [-0.025 0.025 -0.025 -0.025 -0.025 0.020 -0.025 -0.035 -0.025], ...
    [0.015 -0.025 -0.025 -0.025 0.025 -0.025 -0.025 -0.025 -0.025]};

plt.figure(4, 2, 'is_title', 'all', ...
    'pixel_w', 520, 'pixel_h', 250);

for animal_index = 1:2
    %% Match the requested cell ID to the preprocessed cue data
    cue_index = cell_specs(animal_index, 1);
    requested_cell_id = cell_specs(animal_index, 2);
    animal_data = cue{cue_index};
    cell_index = find(animal_data.info_cells.cellID == ...
        requested_cell_id);
    assert(isscalar(cell_index), ...
        'Expected one match for animal %d cell ID %d; found %d.', ...
        cue_index, requested_cell_id, numel(cell_index));

    spike_table = animal_data.ST{cell_index};
    cell_activity = double(animal_data.cells{cell_index});
    cue_time_at = double(animal_data.time_at(:)');
    rate_scale = 1000/double(animal_data.time_win);
    game_id = animal_data.info_cells.gameID(cell_index);
    game = animal_data.games{game_id};
    assert(size(cell_activity, 1) == height(game), ...
        'The firing-rate matrix and game table have different trial counts.');

    %% Condition means, raw count errors, and ordered rasters
    in_count_window = spike_table.spiketimes >= analysis_window(1) & ...
        spike_table.spiketimes <= analysis_window(2);
    trial_spike_count = accumarray( ...
        spike_table.trialID(in_count_window), 1, [height(game), 1]);

    mean_sdf = nan(n_conditions, numel(cue_time_at));
    mean_count = nan(n_conditions, 1);
    se_count = nan(n_conditions, 1);
    discounted_value = nan(n_conditions, 1);
    condition_drop = nan(n_conditions, 1);
    condition_delay = nan(n_conditions, 1);
    raster_spikes = cell(n_conditions, 1);
    raster_trial_ids = cell(n_conditions, 1);

    for condition = 1:n_conditions
        trial_ids = find(game.condition == condition & ...
            isfinite(game.rt_cueon_to_cue1));
        marker_times = game.rt_cueon_to_cue1(trial_ids);
        [~, trial_order] = sort(marker_times, 'descend');
        trial_ids = trial_ids(trial_order);
        raster_trial_ids{condition} = trial_ids;

        condition_spikes = cell(numel(trial_ids), 1);
        for trial_index = 1:numel(trial_ids)
            trial_id = trial_ids(trial_index);
            spikes = double(spike_table.spiketimes( ...
                spike_table.trialID == trial_id));
            condition_spikes{trial_index} = spikes( ...
                spikes >= win_plot(1) & spikes <= win_plot(2));
        end
        raster_spikes{condition} = condition_spikes;

        mean_sdf(condition, :) = mean( ...
            cell_activity(trial_ids, :), 1, 'omitnan') * rate_scale;
        counts = trial_spike_count(trial_ids);
        mean_count(condition) = mean(counts, 'omitnan');
        se_count(condition) = std(counts, 0, 'omitnan') / ...
            sqrt(sum(isfinite(counts)));
        discounted_value(condition) = mean( ...
            game.DV_overall(trial_ids), 'omitnan');
        condition_drop(condition) = mean(game.drop(trial_ids), 'omitnan');
        condition_delay(condition) = mean(game.delay(trial_ids), 'omitnan');
    end

    [~, condition_order] = sort(mean_count, 'ascend', ...
        'MissingPlacement', 'last');

    %% Registered layout: density/raster at left, spanning correlation right
    first_grid_row = 2*animal_index - 1;
    plt.ax(first_grid_row, 1);
    ax_sdf = gca;
    plt.ax(first_grid_row + 1, 1);
    ax_raster = gca;
    plt.ax(first_grid_row, 2);
    ax_corr = gca;
    plt.ax(first_grid_row + 1, 2);
    unused_corr_axis = gca;

    upper_position = ax_corr.Position;
    lower_position = unused_corr_axis.Position;
    ax_corr.Position = [upper_position(1), lower_position(2), ...
        upper_position(3), ...
        upper_position(2) + upper_position(4) - lower_position(2)];
    set(unused_corr_axis, 'Visible', 'off');

    % Tighten the left stack and give more height to the square raster.
    sdf_units = ax_sdf.Units;
    raster_units = ax_raster.Units;
    ax_sdf.Units = 'normalized';
    ax_raster.Units = 'normalized';
    left_top = ax_sdf.Position(2) + ax_sdf.Position(4);
    left_bottom = ax_raster.Position(2);
    left_height = left_top - left_bottom;
    sdf_height = 0.28*left_height;
    raster_height = 0.58*left_height;
    panel_gap = 0.025*left_height;
    raster_bottom = left_bottom + 0.06*left_height;
    ax_raster.Position(2) = raster_bottom;
    ax_raster.Position(4) = raster_height;
    ax_sdf.Position(2) = raster_bottom + raster_height + panel_gap;
    ax_sdf.Position(4) = sdf_height;

    % Give the short PSTH and square raster the same physical width.
    figure_handle = gcf;
    figure_units = figure_handle.Units;
    figure_handle.Units = 'pixels';
    figure_position = figure_handle.Position;
    figure_handle.Units = figure_units;
    matched_width = raster_height * ...
        figure_position(4)/figure_position(3);
    original_center = ax_raster.Position(1) + ...
        ax_raster.Position(3)/2;
    matched_left = original_center - matched_width/2;
    ax_raster.Position([1 3]) = [matched_left matched_width];
    ax_sdf.Position([1 3]) = [matched_left matched_width];

    % Pull the correlation panel toward the left stack while leaving room
    % for its external legend.
    corr_units = ax_corr.Units;
    ax_corr.Units = 'normalized';
    correlation_gap = 0.105;
    ax_corr.Position(1) = matched_left + matched_width + correlation_gap;
    ax_corr.Units = corr_units;
    ax_sdf.Units = sdf_units;
    ax_raster.Units = raster_units;
    hold(ax_sdf, 'on');
    hold(ax_raster, 'on');

    %% Spike-density panel
    density_mask = cue_time_at >= win_plot(1) & cue_time_at <= win_plot(2);
    for condition = 1:n_conditions
        plot(ax_sdf, cue_time_at(density_mask), ...
            mean_sdf(condition, density_mask), ...
            'Color', condition_colors(condition, :), 'LineWidth', 1.2);
    end
    xlim(ax_sdf, win_plot);
    ylim(ax_sdf, [0 20]);
    set(ax_sdf, 'XTick', [], 'FontSize', 9, 'TickDir', 'out', ...
        'Box', 'off');
    ylabel(ax_sdf, 'Spikes/sec');
    title(ax_sdf, sprintf('%s Cell #%d', ...
        animal_names(animal_index), requested_cell_id), ...
        'FontWeight', 'normal');
    original_axis_units = ax_sdf.Units;
    ax_sdf.Units = 'normalized';
    normalized_sdf_position = ax_sdf.Position;
    ax_sdf.Units = original_axis_units;
    panel_label_x = min(0.95, max(0.005, ...
        normalized_sdf_position(1) - 0.055));
    panel_label_y = min(0.95, max(0.005, ...
        normalized_sdf_position(2) + normalized_sdf_position(4) - 0.01));
    annotation(gcf, 'textbox', ...
        [panel_label_x, panel_label_y, 0.04, 0.04], ...
        'String', panel_letters(animal_index), ...
        'FontSize', 18, 'EdgeColor', 'none', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');

    %% Ordered raster panel
    total_trials = sum(cellfun(@numel, raster_trial_ids));
    patch(ax_raster, analysis_window([1 2 2 1]), ...
        [0.5 0.5 total_trials + 0.5 total_trials + 0.5], ...
        [0.90 0.90 0.90], 'EdgeColor', 'none', ...
        'FaceAlpha', 0.65);

    first_raster_row = 1;
    block_centers = nan(n_conditions, 1);
    block_labels = strings(n_conditions, 1);
    for order_index = 1:n_conditions
        condition = condition_order(order_index);
        condition_spikes = raster_spikes{condition};
        n_trials = numel(condition_spikes);
        block_centers(order_index) = first_raster_row + (n_trials - 1)/2;
        block_labels(order_index) = condition_letters(condition);

        spike_x = [];
        spike_y = [];
        for trial_index = 1:n_trials
            spikes = condition_spikes{trial_index};
            spike_x = [spike_x; spikes(:)]; %#ok<AGROW>
            spike_y = [spike_y; repmat( ...
                first_raster_row + trial_index - 1, ...
                numel(spikes), 1)]; %#ok<AGROW>
        end
        plot(ax_raster, spike_x, spike_y, '.', ...
            'Color', condition_colors(condition, :), ...
            'MarkerSize', 3);
        first_raster_row = first_raster_row + n_trials;
    end
    xline(ax_raster, 0, ':k', 'LineWidth', 2);
    xlim(ax_raster, win_plot);
    ylim(ax_raster, [0.5 total_trials + 0.5]);
    set(ax_raster, 'YTick', block_centers, ...
        'YTickLabel', cellstr(block_labels), ...
        'FontSize', 9, 'TickDir', 'out', 'Box', 'off');
    axis(ax_raster, 'square');
    add_offer_onset_label(ax_raster);

    %% Discounted-value correlation panel
    hold(ax_corr, 'on');

    correlation_model = fitlm(discounted_value, mean_count);
    regression_x = linspace(min(discounted_value), ...
        max(discounted_value), 100)';
    regression_y = predict(correlation_model, regression_x);
    plot(ax_corr, regression_x, regression_y, '-', ...
        'Color', [0.25 0.25 0.25], 'LineWidth', 1.3);

    x_max = ceil(max(discounted_value)*2)/2;
    y_min = floor(min(mean_count));
    y_max = ceil(max(mean_count + se_count));
    y_limits = [y_min y_max];

    for condition = 1:n_conditions
        reward_index = find(reward_levels == condition_drop(condition), 1);
        errorbar(ax_corr, discounted_value(condition), ...
            mean_count(condition), se_count(condition), ...
            'LineStyle', 'none', ...
            'Color', condition_colors(condition, :), ...
            'Marker', reward_markers{reward_index}, ...
            'MarkerFaceColor', 'white', ...
            'MarkerEdgeColor', condition_colors(condition, :), ...
            'MarkerSize', 6, 'CapSize', 4, 'LineWidth', 1.2);
        text(ax_corr, discounted_value(condition) + ...
            point_label_dx{animal_index}(condition)*x_max, ...
            mean_count(condition) + ...
            point_label_dy{animal_index}(condition)*diff(y_limits), ...
            condition_letters(condition), 'FontSize', 10, ...
            'Color', [0.2 0.2 0.2], ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle');
    end

    signed_r_squared = sign(correlation_model.Coefficients.Estimate(2)) * ...
        correlation_model.Rsquared.Ordinary;
    slope_p = correlation_model.Coefficients.pValue(2);
    statistics_x = [0.28 0.10];
    text(ax_corr, statistics_x(animal_index), 0.88, sprintf( ...
        'R^2 = %.3f\np = %.4f', signed_r_squared, slope_p), ...
        'Units', 'normalized', 'FontSize', 11, ...
        'VerticalAlignment', 'top');

    condition_legend_handles = gobjects(n_conditions, 1);
    condition_legend_labels = strings(n_conditions, 1);
    for legend_index = 1:n_conditions
        condition = legend_order(legend_index);
        reward_index = find(reward_levels == condition_drop(condition), 1);
        condition_legend_handles(legend_index) = plot(ax_corr, nan, nan, ...
            reward_markers{reward_index}, 'LineStyle', '-', ...
            'Color', condition_colors(condition, :), ...
            'MarkerFaceColor', 'white', 'MarkerSize', 5, ...
            'LineWidth', 1.3);
        condition_legend_labels(legend_index) = sprintf( ...
            '%g drops, %gs delay', condition_drop(condition), ...
            condition_delay(condition));
    end
    legend(ax_corr, condition_legend_handles, ...
        cellstr(condition_legend_labels), 'Location', 'eastoutside', ...
        'FontSize', 8, 'Box', 'off');

    xlim(ax_corr, [0 x_max]);
    ylim(ax_corr, y_limits);
    xlabel(ax_corr, 'Discounted Value');
    ylabel(ax_corr, 'Spike Count');
    set(ax_corr, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off');
    ax_corr.XLabel.FontSize = 12;
    ax_corr.YLabel.FontSize = 12;
    axis(ax_corr, 'square');
end

plt.update('SEAM_rasters');

function add_offer_onset_label(ax)
%ADD_OFFER_ONSET_LABEL Mark time zero below an axis, as in Figure_decoding.
    x_limits = xlim(ax);
    y_limits = ylim(ax);
    label_y = y_limits(1) - 0.02*diff(y_limits);
    triangle_half_width = 0.012*diff(x_limits);
    triangle_height = 0.025*diff(y_limits);
    patch(ax, [-triangle_half_width triangle_half_width 0], ...
        [y_limits(1) - triangle_height, ...
        y_limits(1) - triangle_height, y_limits(1)], ...
        'black', 'EdgeColor', 'black', 'Clipping', 'off');

    x_ticks = xticks(ax);
    x_tick_labels = string(xticklabels(ax));
    zero_tick = abs(x_ticks) < eps(max(abs(x_limits)));
    if numel(x_tick_labels) == numel(x_ticks)
        x_tick_labels(zero_tick) = "";
        xticklabels(ax, x_tick_labels);
    end

    text(ax, 0, label_y, sprintf('Offer\nOnset'), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'top', ...
        'FontSize', max(ax.FontSize - 2, 8), ...
        'Clipping', 'off');
end
