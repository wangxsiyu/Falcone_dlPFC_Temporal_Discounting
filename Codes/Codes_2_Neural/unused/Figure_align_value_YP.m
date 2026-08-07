axis_YP = W.load('../../TempData/coding_dimensions_YP');
axis_GO = W.load('../../TempData/coding_dimensions_GO');
%%
n_animals = numel(axis_value.animals);
animal_names = string(plt.custom_vars.name_monkeys(1:n_animals));
nplot = 1;
gap_w = [1.5, zeros(1, 2 - 1), 0];
gap_h = [1.5, 0, 0];
plt.figure(2, 2, 'is_title', 'all', ...
    'pixel_w', 250, 'pixel_h', 250, ...
    'gapW_custom', gap_w, 'gapH_custom', gap_h);
for animali = 1:n_animals
    for windowi = 1:nplot
        fold_results = axis_GO.fold_results{animali};
        drop_axis = mean([ ...
            fold_results.beta_drop1(:, windowi), ...
            fold_results.beta_drop2(:, windowi)], 2);
        delay_axis = mean([ ...
            fold_results.beta_delay1(:, windowi), ...
            fold_results.beta_delay2(:, windowi)], 2);
        value_axis = axis_YP.fold_results{animali}.betaYP;
        value_axis = value_axis / norm(value_axis);
        valid_neuron = isfinite(drop_axis) & isfinite(delay_axis);
        drop_axis = drop_axis(valid_neuron);
        delay_axis = delay_axis(valid_neuron);
        value_axis = value_axis(valid_neuron);


        y_label = 'YP coefficient (\beta)';
        nPermutations = 10000;
        plt.ax(1, animali);
        plt.scatter(drop_axis, value_axis, 'corr', ...
            'autotitle', false, 'color', 'black');
        
        [p, c] = PermutationP(drop_axis, value_axis, nPermutations);
        statistics_text = sprintf( ...
            '\\fontsize{12}cos = %.2f, p\\_perm = %.3f', ...
            c, ...
            p);
        title_text = sprintf('\\fontsize{18}%s\n%s', ...
            animal_names(animali), statistics_text);
        x_label = 'Drop coefficient (\beta)';
        plt.setfig_ax( ...
            'xlabel', x_label, ...
            'ylabel', y_label, ...
            'title', title_text);

        plt.ax(2, animali);
        plt.scatter(delay_axis, value_axis, 'corr', ...
            'autotitle', false, 'color', 'black');
        [p, c] = PermutationP(delay_axis, value_axis, nPermutations);
        statistics_text = sprintf( ...
            '\\fontsize{12}cos = %.2f, p\\_perm = %.3f', ...
            c, ...
            p);
        title_text = sprintf('%s', ...
            statistics_text);
        x_label = 'Delay coefficient (\beta)';
        plt.setfig_ax( ...
            'xlabel', x_label, ...
            'ylabel', y_label, ...
            'title', title_text);
    end
end
plt.addABCs('ABCD');
plt.update('YP_vs_dropdelay');

function similarity = cosineSimilarity(x, y)
%COSINESIMILARITY Compute the raw cosine between two vectors.
    denominator = norm(x)*norm(y);
    if denominator == 0
        similarity = nan;
    else
        similarity = dot(x, y)/denominator;
    end
end

function [cosineP, observedCosine] = PermutationP( ...
    v1, v2, nPermutations)
    randomStream = 1;
%CROSSFOLDPERMUTATIONP Permute delay neuron labels across both folds.
    observedCosine = cosineSimilarity( ...
        v1, v2);

    [~, permutationOrder] = sort(rand( ...
        randomStream, numel(v1), nPermutations), 1);
    permutedv2 = squeeze(v2(permutationOrder));

    permutationCosine = (v1'*permutedv2)/ ...
        (norm(v1)*norm(v2));

    cosineP = (1 + sum(abs(permutationCosine) >= ...
        abs(observedCosine)))/(nPermutations + 1);
end