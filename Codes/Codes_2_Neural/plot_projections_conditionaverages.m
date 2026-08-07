function plot_projections_conditionaverages(plt, projections, projections_YP)
%PLOT_PROJECTIONS_YP_RH Plot baseline-matched group-average projections.
% Each condition/group trajectory is centered on its own mean projection
% during -250 to 0 ms before the mean and SE are taken across conditions.

    baseline_window = [-250 0];
    trial_options = projections{1}.trialoptions;
    yellow_color = [0.90 0.65 0.05];
    purple_color = [0.55 0.25 0.72];
    hold_color = [0.65 0.65 0.65];
    release_color = [0.10 0.10 0.10];
    for ai = 1:2
        projections{ai}.axes = [projections{ai}.axes; projections_YP{ai}.axes];
        projections{ai}.vals = [projections{ai}.vals, projections_YP{ai}.vals];
    end

    n_animals = numel(projections);
    n_axes = numel(projections{1}.axes);
    example_values = projections{1}.vals{1, 1};
    n_rows = size(example_values, 1);
    n_groups = size(example_values, 3);
    n_times = size(example_values, 4);

    assert(n_animals == 2, ...
        'The projection figure requires Monkey S and Monkey T.');

    animal_names = string(plt.custom_vars.name_monkeys(1:n_animals));

    for trial_option_index = 1:numel(trial_options)
        trial_option = trial_options{trial_option_index};
        switch trial_option
            case {'YP', 'YP_amb'}
                group_colors = {yellow_color, purple_color};
                group_names = {'Yellow', 'Purple'};
            case {'motor', 'motor_amb'}
                group_colors = {hold_color, release_color};
                group_names = {'Hold', 'Release'};
        end

        plt.figure(n_rows, n_animals*n_axes, 'is_title', 'all', ...
            'pixel_w', 300, 'pixel_h', 220);
        for animal_index = 1:n_animals
            projection = projections{animal_index};
            time_at = double(projection.time_at(:)');
            assert(numel(time_at) == n_times, ...
                'The projection time vector must match dimension four.');
            baseline_mask = time_at >= baseline_window(1) & ...
                time_at < baseline_window(2);
            assert(any(baseline_mask), ...
                'No projection samples fall in the -250 to 0 ms baseline.');

            axis_names = string(projection.axes);
            animal_option_index = find(strcmp( ...
                projection.trialoptions, trial_option), 1);
            assert(~isempty(animal_option_index), ...
                'Animal %d is missing trial option %s.', ...
                animal_index, trial_option);

            for axis_index = 1:n_axes
                column_index = (animal_index - 1)*n_axes + axis_index;
                values = projection.vals{animal_option_index, axis_index};
                n_conditions = size(values, 2);
                assert(isequal(size(values), [n_rows, n_conditions, ...
                    n_groups, n_times]), ...
                    'All projection arrays must have identical dimensions.');

                for row_index = 1:n_rows
                    plt.ax(row_index, column_index);
                    hold on;
                    for group_index = 1:n_groups
                        trajectories = reshape(values(row_index, :, ...
                            group_index, :), n_conditions, n_times);
                        condition_baseline = mean( ...
                            trajectories(:, baseline_mask), 2, 'omitnan');
                        trajectories = trajectories - condition_baseline;
                        [group_mean, group_se] = W.avse(trajectories);
                        plt.plot(time_at, group_mean, group_se, ...
                            'shade', 'color', ...
                            group_colors{group_index});
                    end

                    xline(baseline_window(1), '--', ...
                        'Color', [0.35 0.35 0.35]);
                    xline(baseline_window(2), '--', ...
                        'Color', [0.35 0.35 0.35]);
                    yline(0, '--', 'Color', [0.35 0.35 0.35]);

                    panel_title = sprintf('%s: %s, window %d', ...
                        animal_names(animal_index), ...
                        axis_names(axis_index), row_index);
                    if row_index == n_rows
                        x_label = 'Time from event onset (ms)';
                    else
                        x_label = '';
                    end
                    if column_index == 1 || column_index == n_axes + 1
                        y_label = 'Baseline-matched projection';
                    else
                        y_label = '';
                    end
                    plt.setfig_ax('title', panel_title, ...
                        'xlabel', x_label, 'ylabel', y_label, ...
                        'xlim', time_at([1 end]));
                    if row_index == 1 && axis_index == n_axes
                        plt.setfig_ax('legend', group_names, ...
                            'legloc', 'best');
                    end
                end
            end
        end
        plt.update(['projections_conditionaverages_' trial_option]);
    end
end
