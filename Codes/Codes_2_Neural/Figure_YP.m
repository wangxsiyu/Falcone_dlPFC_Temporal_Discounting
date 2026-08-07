projections = W.load('../../TempData/proj_valueGO');
projections_YP = W.load('../../TempData/proj_YP');
% projections_sepYP = W.load('../../TempData/proj_sepYP');
axes_YP = W.load('../../TempData/axes_YP');
axes_sYP = W.load('../../TempData/axes_sepYP');
axes_value = W.load('../../TempData/axes_valueGO');
%% Figure 1: primary population-projection results
animalNames = string(plt.custom_vars.name_monkeys(1:2));
colorNames = ["Yellow", "Purple"];
yellowColor = [0.90 0.65 0.05];
purpleColor = [0.55 0.25 0.72];
xticks = [-250:250:1000];
xlm = [-250, 500];
animal_names = plt.custom_vars.name_monkeys;
windowi = 1;
plt.figure(3, 2, 'is_title', 'all', ...
    'gapW_custom', [0.7 0 1.2]);
for animalIndex = 1:numel(animalNames)

    projection = projections{animalIndex};
    timeAt = double(projection.time_at(:)');
    baseline_window = [-250 0];
    baseline_mask = timeAt >= baseline_window(1) & ...
        timeAt < baseline_window(2);
    analysisConditions = 1:9;
    nTimes = length(timeAt);

    % Absolute, baseline-corrected value projections across all nine cues.
    plt.ax(1, animalIndex);
    hold on;
    yellowValue = reshape(projection.vals{1}(windowi, analysisConditions, 1, :), ...
        numel(analysisConditions), nTimes);
    purpleValue = reshape(projection.vals{1}(windowi, analysisConditions, 2, :), ...
        numel(analysisConditions), nTimes);

    yellowValue = yellowValue - mean(yellowValue(:, baseline_mask), 2);
    purpleValue = purpleValue - mean(purpleValue(:, baseline_mask), 2);

    [av, se] = W.avse(yellowValue);
    max1 = av + se;
    plt.plot(timeAt, av, se, 'shade', 'color', yellowColor);
    [av, se] = W.avse(purpleValue);
    max2 = av + se;
    plt.plot(timeAt, av, se, 'shade', 'color', purpleColor);
    maxt = max([max1; max2]);
    [~, pval] = ttest(yellowValue - purpleValue);
    tid = pval < 0.05 & timeAt <= xlm(2) & timeAt >= xlm(1);
    plt.sigstar(timeAt(tid), maxt(tid) + 0.01, pval(tid), 'dx', 0)

    plt.dashX(0);
    plt.dashY(0);
    plt.setfig_ax('xlabel', 'Time from GO cue onset (ms)', ...
        'xlim', xlm, 'xtick', xticks, 'ylabel', 'Value-axis projection', ...
        'title', sprintf('%s', animalNames(animalIndex)));
    if animalIndex == 2
        plt.setfig_ax('legend', {'Yellow', 'Purple'}, ...
            'legloc', 'SE');
    end

    plt.ax(2, animalIndex);
    tid = timeAt < 250 & timeAt > 0;
    avY = mean(yellowValue(:, tid), 2)';
    avP = mean(purpleValue(:, tid), 2)';
    [tav, tse] = W.avse([avY', avP']);
    [~, pp] = ttest(avP' - avY');
    plt.plot([], tav, tse, 'bar', 'color', {yellowColor, purpleColor}, 'individualcolor', true);
    plt.setfig_ax('ylim', [-0.4, 0.5], 'xtick', 1:2, 'xticklabel', {'Yellow', 'Purple'}, ...
        'ylabel', {'\Delta activity on value-axis', '250ms after - before go signal'})
    plt.sigstar(1.5, 0.4, pp);


    % plt.ax(2, animalIndex);
    % % projection = projections_sepYP{animalIndex};
    % % % Absolute, baseline-corrected value projections across all nine cues.
    % % hold on;
    % % twins = -250:10:500;
    % % tvals = projection.vals{1};
    % % tsz = size(tvals);
    % % ttvals = nan(tsz(2:end));
    % % for ttti = 1:2
    % %     for tttwi = 1:size(tvals, 1)
    % %         tttvi = find(timeAt == twins(tttwi));
    % %         ttvals(:, ttti, tttvi) = tvals(tttwi, :, ttti, tttvi);
    % %     end
    % % end
    % % yellowValue = reshape(ttvals(analysisConditions, 1, :), ...
    % %     numel(analysisConditions), nTimes);
    % % purpleValue = reshape(ttvals(analysisConditions, 2, :), ...
    % %     numel(analysisConditions), nTimes);
    % projection = projections_YP{animalIndex};
    % ttvals = squeeze(projection.vals{1}(windowi, :, :, :));
    % yellowValue = squeeze(ttvals(:, 1, :));
    % purpleValue = squeeze(ttvals(:, 2, :));
    % yellowValue = yellowValue - mean(yellowValue(:, baseline_mask), 2);
    % purpleValue = purpleValue - mean(purpleValue(:, baseline_mask), 2);
    % 
    % % basett = (yellowValue + purpleValue)./2;
    % % yellowValue = yellowValue - basett;
    % % purpleValue = purpleValue - basett;
    % 
    % [av, se] = W.avse(yellowValue);
    % max1 = av + se;
    % plt.plot(timeAt, av, se, 'shade', 'color', yellowColor);
    % [av, se] = W.avse(purpleValue);
    % max2 = av + se;
    % plt.plot(timeAt, av, se, 'shade', 'color', purpleColor);
    % maxt = max([max1; max2]);
    % [~, pval] = ttest(yellowValue - purpleValue);
    % tid = pval < 0.05 & timeAt <= xlm(2) & timeAt >= xlm(1);
    % plt.sigstar(timeAt(tid), maxt(tid) + 0.01, pval(tid), 'dx', 0)
    % 
    % plt.dashX(0);
    % plt.dashY(0);
    % plt.setfig_ax('xlabel', 'Time from GO cue onset (ms)', ...
    %     'xlim', xlm, 'xtick', xticks, 'ylabel', 'Value-axis projection', ...
    %     'title', sprintf('%s', animalNames(animalIndex)));
    % if animalIndex == 2
    %     plt.setfig_ax('legend', {'Yellow', 'Purple'}, ...
    %         'legloc', 'SE');
    % end

    plt.ax(3, animalIndex);
    YP_axis = axes_YP{animalIndex}.YP;
    % YP_axis = YP_axis(:, find(timeAt == 120));
    value_axis = axes_value{animalIndex}.value;
    tid = isnan(YP_axis) | isnan(value_axis);
    YP_axis = YP_axis(~tid);
    value_axis = value_axis(~tid);

    y_label = 'Value coefficient (\beta)';
    nPermutations = 10000;
    plt.scatter(YP_axis, value_axis, 'corr', ...
        'autotitle', false, 'color', 'black');

    [p, c] = PermutationP(YP_axis, value_axis, nPermutations);
    % [c, p] = corr(YP_axis, value_axis);
    statistics_text = sprintf( ...
        '\\fontsize{12}cos = %.2f, p\\_perm = %.3f', ...
        c, ...
        p);
    title_text = statistics_text;
    x_label = 'Y/P coefficient (\beta)';
    plt.setfig_ax( ...
        'xlabel', x_label, ...
        'ylabel', y_label, ...
        'title', title_text);

end
plt.addABCs('ABCDEF');
plt.update('YP population projection GO');


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
    randomStream = RandStream('mt19937ar', 'Seed', 1);
    % v2 = v2 - mean(v2);
    % v1 = v1 - mean(v1);
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