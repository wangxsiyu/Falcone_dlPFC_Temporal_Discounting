function plot_projections(plt, projections, games)
%PLOT_PROJECTIONS Plot each trial-grouping option in a separate figure.
% Rows are the five axis-training windows. Columns 1-2 show Monkey S and
% columns 3-4 show Monkey T. Offer color is ordered by mean DV_overall;
% dashed and solid lines distinguish the two groups for each trial option.

    n_animals = numel(projections);
    n_axes = numel(projections{1}.axes);
    trial_options = { ...
        'YP', 'motor', 'motor_controlYP', 'YP_controlMotor'};
    group_names = { ...
        {'Yellow', 'Purple'}, ...
        {'Hold', 'Release'}, ...
        {'Hold (Y/P matched)', 'Release (Y/P matched)'}, ...
        {'Yellow (motor matched)', 'Purple (motor matched)'}};
    group_styles = {'--', '-'};

    first_option_index = find(strcmp( ...
        projections{1}.trialoptions, trial_options{1}), 1);
    assert(~isempty(first_option_index), ...
        'The projections must include all four trial options.');
    example_values = projections{1}.vals{first_option_index, 1};
    n_rows = size(example_values, 1);
    n_conditions = size(example_values, 2);
    n_groups = size(example_values, 3);
    n_times = size(example_values, 4);

    assert(n_animals == 2, ...
        'The projection figure requires Monkey S and Monkey T.');
    assert(n_axes == 2, ...
        'Each animal must contain exactly two projection axes.');
    assert(n_rows == 5 && n_conditions == 9 && n_groups == 2, ...
        'Projection arrays must have size 5 x 9 x 2 x time.');
    assert(numel(games) == n_animals, ...
        'Provide one behavioral table for each animal.');

    offer_colors = turbo(n_conditions);
    animal_names = string(plt.custom_vars.name_monkeys(1:n_animals));

    for trial_option_index = 1:numel(trial_options)
        trial_option = trial_options{trial_option_index};
        option_group_names = group_names{trial_option_index};
        plt.figure(n_rows, n_animals*n_axes, 'is_title', 'all', ...
            'pixel_w', 300, 'pixel_h', 220);

        for animal_index = 1:n_animals
            projection = projections{animal_index};
            animal_game = games{animal_index};
            if iscell(animal_game)
                animal_game = vertcat(animal_game{:});
            end
            condition_dv = nan(n_conditions, 1);
            for condition = 1:n_conditions
                condition_dv(condition) = mean(double( ...
                    animal_game.DV_overall( ...
                    animal_game.condition == condition)), 'omitnan');
            end
            assert(all(isfinite(condition_dv)), ...
                'Every offer must have a finite mean DV_overall.');
            [sorted_dv, condition_order] = sort(condition_dv);
            color_rank = nan(n_conditions, 1);
            color_rank(condition_order) = 1:n_conditions;

            time_at = double(projection.time_at(:)');
            assert(numel(time_at) == n_times, ...
                'The projection time vector must match dimension four.');
            axis_names = string(projection.axes);
            animal_option_index = find(strcmp( ...
                projection.trialoptions, trial_option), 1);
            assert(~isempty(animal_option_index), ...
                'Animal %d is missing trial option %s.', ...
                animal_index, trial_option);

            for axis_index = 1:n_axes
                column_index = (animal_index - 1)*n_axes + axis_index;
                values = projection.vals{animal_option_index, axis_index};
                assert(isequal(size(values), [n_rows, n_conditions, ...
                    n_groups, n_times]), ...
                    'All projection arrays must have identical dimensions.');

                for row_index = 1:n_rows
                    plt.ax(row_index, column_index);
                    hold on;
                    for group_index = 1:n_groups
                        for rank_index = 1:n_conditions
                            condition = condition_order(rank_index);
                            trajectory = reshape(values(row_index, ...
                                condition, group_index, :), 1, n_times);
                            if any(~isfinite(trajectory))
                                continue;
                            end
                            plot(time_at, trajectory, ...
                                'Color', offer_colors( ...
                                color_rank(condition), :), ...
                                'LineStyle', group_styles{group_index}, ...
                                'LineWidth', 1.1);
                        end
                    end
                    plt.dashX(0);
                    plt.dashY(0);

                    panel_title = sprintf('%s: %s, window %d', ...
                        animal_names(animal_index), ...
                        axis_names(axis_index), row_index);
                    if row_index == n_rows
                        x_label = 'Time from event onset (ms)';
                    else
                        x_label = '';
                    end
                    if column_index == 1 || column_index == n_axes + 1
                        y_label = 'Projection';
                    else
                        y_label = '';
                    end
                    plt.setfig_ax('title', panel_title, ...
                        'xlabel', x_label, 'ylabel', y_label, ...
                        'xlim', time_at([1 end]));
                    if row_index == 1 && axis_index == 1
                        group_handles = gobjects(1, n_groups);
                        for group_index = 1:n_groups
                            group_handles(group_index) = plot(nan, nan, ...
                                'k', 'LineStyle', ...
                                group_styles{group_index}, ...
                                'LineWidth', 1.4);
                        end
                        legend(group_handles, option_group_names, ...
                            'Location', 'best');
                    elseif row_index == 1 && axis_index == n_axes
                        colormap(gca, offer_colors);
                        clim(gca, [1, n_conditions]);
                        color_bar = colorbar;
                        color_bar.Ticks = 1:n_conditions;
                        color_bar.TickLabels = compose('%.2g', sorted_dv);
                        color_bar.Label.String = 'Mean DV_overall';
                    end
                end
            end
        end
        plt.update(['projections_' trial_option]);
    end
end
