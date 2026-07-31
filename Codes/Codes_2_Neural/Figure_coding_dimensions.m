function Figure_coding_dimensions(plt, codingname, nplot)
    coding = W.load(fullfile('../../TempData', codingname));
    % Plot the saved drop and delay population coding dimensions.
    assert(isstruct(coding) && all(isfield(coding, ...
        {'fold_results', 'stats', 'window_labels'})), ...
        'Run main_coding_dimensions before plotting this figure.');
    
    window_labels = string(coding.window_labels);
    n_animals = numel(coding.beta_drop);
    n_windows = numel(window_labels);
    animal_names = string(plt.custom_vars.name_monkeys(1:n_animals));
    assert(n_windows == 5, ...
        'The coding-dimension figure expects five time windows.');
    
    gap_w = [1.5, zeros(1, nplot - 1), 0];
    gap_h = [1.5, 0, 0];
    if nplot == 1
        plt.figure(nplot, 2, 'is_title', 'all', ...
            'pixel_w', 250, 'pixel_h', 250);
    else
        plt.figure(2, nplot, 'is_title', 'all', ...
            'pixel_w', 250, 'pixel_h', 250, ...
            'gapW_custom', gap_w, 'gapH_custom', gap_h);
    end
    for animali = 1:n_animals
        for windowi = 1:nplot
            if nplot == 1
                windowi = 1;
                plt.ax(animali);
            else
                plt.ax(animali, windowi);
            end
            fold_results = coding.fold_results{animali};
            drop_axis = mean([ ...
                fold_results.beta_drop1(:, windowi), ...
                fold_results.beta_drop2(:, windowi)], 2);
            delay_axis = mean([ ...
                fold_results.beta_delay1(:, windowi), ...
                fold_results.beta_delay2(:, windowi)], 2);
            valid_neuron = isfinite(drop_axis) & isfinite(delay_axis);
            drop_axis = drop_axis(valid_neuron);
            delay_axis = delay_axis(valid_neuron);
            rowi = (animali - 1)*n_windows + windowi;
    
            plt.scatter(drop_axis, delay_axis, 'corr', ...
                'autotitle', false, 'color', 'black');
            statistics_text = sprintf( ...
                '\\fontsize{12}cos = %.2f, p\\_perm = %.3f', ...
                coding.stats.cosine(rowi), ...
                coding.stats.cosine_permutation_p(rowi));
            if animali == 1 && nplot ~= 1
                title_text = sprintf('\\fontsize{18}%s\n%s', ...
                    window_labels(windowi), statistics_text);
                x_label = '';
            elseif nplot == 1
                title_text = sprintf('\\fontsize{18}%s\n%s', ...
                    animal_names(animali), statistics_text);
                x_label = 'Drop coefficient (\beta)';
            else
                title_text = statistics_text;
                x_label = 'Drop coefficient (\beta)';
            end
            if windowi == 1 && nplot ~= 1
                y_label = {animal_names(animali), 'Delay coefficient (\beta)'};
            else
                y_label = 'Delay coefficient (\beta)';
            end
            plt.setfig_ax( ...
                'xlabel', x_label, ...
                'ylabel', y_label, ...
                'title', title_text);
        end
    end
    plt.addABCs('ABCDEFGHIJ');
    % for animali = 1:n_animals
    %     row_axes = {repmat(animali, 1, nplot), 1:nplot};
    %     plt.unify_lims(row_axes, row_axes);
    % end
    if nplot == 1
        plt.update(W.file_suffix(codingname, 'Monkey'));
    else
        plt.update(codingname);
    end
end
