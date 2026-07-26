% Test whether the GO-cue Yellow/Purple population shift aligns with value.
%
% The coding axes are estimated from color-collapsed, offer-locked activity
% and are then applied to independently GO-locked activity. Thus, the
% Yellow/Purple contrast being tested does not define the axes. All axes
% are oriented toward increasing drop, delay, or Model-1 discounted value.

animalNames = string(plt.custom_vars.name_monkeys(1:2));
axisNames = ["Drop", "Delay", "Value"];
colorNames = ["Yellow", "Purple"];
axisTrainingWindow = [0 750];       % ms relative to offer onset
baselineWindow = [-250 0];          % ms relative to GO onset
summaryWindow = [0 500];            % ms relative to GO onset
statisticsWindows = [-250 0; 0 250; 250 500; ...
    500 750; 750 1000];
nPermutations = 10000;
familywiseAlpha = 0.05;
yellowColor = [0.90 0.65 0.05];
purpleColor = [0.55 0.25 0.72];
axisColors = [0.25 0.55 0.80; 0.30 0.65 0.40; 0.35 0.35 0.35];

assert(numel(cue) >= 2 && numel(go) >= 2, ...
    'Both offer- and GO-locked data must contain two animals.');
rng(1, 'twister');

YP = struct;
YP.settings = struct( ...
    'axis_training_lock', 'offer onset', ...
    'axis_training_window_ms', axisTrainingWindow, ...
    'projection_lock', 'GO cue onset', ...
    'baseline_window_ms', baselineWindow, ...
    'summary_window_ms', summaryWindow, ...
    'statistics_windows_ms', statisticsWindows, ...
    'value_definition', 'Model 1 DV_overall', ...
    'behavior_multiple_comparison', 'Bonferroni across 18 cues', ...
    'n_permutations', nPermutations);
YP.animals = repmat(struct, numel(animalNames), 1);

for animalIndex = 1:numel(animalNames)
    cueData = cue{animalIndex};
    goData = go{animalIndex};
    assert(isequal(cueData.info_cells(:, {'animal', 'gameID'}), ...
        goData.info_cells(:, {'animal', 'gameID'})), ...
        'Offer- and GO-locked neurons must have identical ordering.');
    assert(numel(cueData.cells) == numel(goData.cells), ...
        'Offer- and GO-locked data must contain the same neurons.');

    gameIDs = unique(goData.info_cells.gameID);
    animalGames = vertcat(goData.games{gameIDs});
    behavior = computeBehavioralShift(animalGames);
    behavior.p_bonferroni = min( ...
        behavior.p_uncorrected*18, 1);
    behavior.is_shifted = ...
        behavior.p_bonferroni < familywiseAlpha & ...
        behavior.delta_accept_purple_minus_yellow > 0;
    shiftedConditions = behavior.condition(behavior.is_shifted);
    assert(~isempty(shiftedConditions), ...
        'No behaviorally shifted cues were found for %s.', ...
        animalNames(animalIndex));

    [axesRaw, normalization] = estimateOfferAxes( ...
        cueData, axisTrainingWindow);
    axisNorms = vecnorm(axesRaw, 2, 1);
    assert(all(isfinite(axisNorms) & axisNorms > 0), ...
        'All population coding axes must have a finite nonzero norm.');
    axesUnit = axesRaw ./ axisNorms;

    normalizedTrajectories = computeGoColorTrajectories( ...
        goData, normalization, baselineWindow);
    nConditions = height(behavior);
    nTimes = numel(goData.time_at);
    projection = reshape(axesUnit' * ...
        reshape(normalizedTrajectories, ...
        numel(goData.cells), []), ...
        numel(axisNames), nConditions, numel(colorNames), nTimes);

    statistics = computeProjectionStatistics( ...
        normalizedTrajectories, axesUnit, shiftedConditions, ...
        goData.time_at, statisticsWindows, axisNames, ...
        nPermutations);

    summaryMask = goData.time_at >= summaryWindow(1) & ...
        goData.time_at < summaryWindow(2);
    valueShiftByCondition = reshape(mean( ...
        projection(3, :, 2, summaryMask) - ...
        projection(3, :, 1, summaryMask), 4, 'omitnan'), ...
        nConditions, 1);
    [behaviorNeuralR, behaviorNeuralP] = corr( ...
        behavior.delta_accept_purple_minus_yellow, ...
        valueShiftByCondition, 'Type', 'Spearman', ...
        'Rows', 'complete');
    behavior.neural_value_shift_0_to_500_ms = ...
        valueShiftByCondition;

    YP.animals(animalIndex).name = animalNames(animalIndex);
    YP.animals(animalIndex).behavior = behavior;
    YP.animals(animalIndex).shifted_conditions = shiftedConditions;
    YP.animals(animalIndex).axes_raw = axesRaw;
    YP.animals(animalIndex).axes_unit = axesUnit;
    YP.animals(animalIndex).axis_names = axisNames;
    YP.animals(animalIndex).axis_cosine = axesUnit' * axesUnit;
    YP.animals(animalIndex).normalization = normalization;
    YP.animals(animalIndex).go_color_trajectories = ...
        normalizedTrajectories;
    YP.animals(animalIndex).projection = projection;
    YP.animals(animalIndex).projection_statistics = statistics;
    YP.animals(animalIndex).behavior_neural_spearman_r = ...
        behaviorNeuralR;
    YP.animals(animalIndex).behavior_neural_spearman_p = ...
        behaviorNeuralP;
    YP.animals(animalIndex).time_at = goData.time_at;

    fprintf('\n%s: behaviorally shifted conditions = %s\n', ...
        animalNames(animalIndex), ...
        strjoin(string(shiftedConditions'), ', '));
    disp(statistics);
    fprintf(['Behavioral versus neural value shift across nine cues: ' ...
        'Spearman r = %.3f, p = %.4g\n'], ...
        behaviorNeuralR, behaviorNeuralP);
    fprintf('Cosines among [drop, delay, value] axes:\n');
    disp(YP.animals(animalIndex).axis_cosine);
end

W.save('../../TempData/YP_population_projection_GO', 'YP', YP);

%% Figure 1: primary population-projection results
plt.figure(3, 2, 'is_title', 'all', ...
    'pixel_w', 440, 'pixel_h', 300, ...
    'gapW_custom', [0.7 0 1.2]);
for animalIndex = 1:numel(animalNames)
    result = YP.animals(animalIndex);
    timeAt = result.time_at;
    selected = result.shifted_conditions;
    projection = result.projection;

    % Absolute, baseline-corrected Yellow and Purple value projections.
    plt.ax(1, animalIndex);
    hold on;
    yellowValue = reshape(projection(3, selected, 1, :), ...
        numel(selected), numel(timeAt));
    purpleValue = reshape(projection(3, selected, 2, :), ...
        numel(selected), numel(timeAt));
    plotMeanSem(timeAt, yellowValue, yellowColor);
    plotMeanSem(timeAt, purpleValue, purpleColor);
    addReferenceLines;
    xlim([-250 1000]);
    ylabel('Value-axis projection');
    title(sprintf('%s: shifted cues %s', ...
        animalNames(animalIndex), ...
        strjoin(string(selected'), ', ')));
    if animalIndex == 2
        legend({'Yellow SEM', 'Yellow', 'Purple SEM', 'Purple'}, ...
            'Location', 'northeast', 'Box', 'off');
    end

    % Purple-minus-Yellow shift along all three coding axes.
    plt.ax(2, animalIndex);
    hold on;
    for axisIndex = 1:numel(axisNames)
        axisDifference = reshape(mean( ...
            projection(axisIndex, selected, 2, :) - ...
            projection(axisIndex, selected, 1, :), ...
            2, 'omitnan'), 1, []);
        plot(timeAt, axisDifference, ...
            'Color', axisColors(axisIndex, :), ...
            'LineWidth', 2);
    end
    addReferenceLines;
    xlim([-250 1000]);
    ylabel('Purple - Yellow projection');
    if animalIndex == 2
        legend(axisNames, 'Location', 'northeast', 'Box', 'off');
    end

    % Across-cue correspondence between behavioral and neural shifts.
    plt.ax(3, animalIndex);
    hold on;
    behavior = result.behavior;
    x = behavior.delta_accept_purple_minus_yellow;
    y = behavior.neural_value_shift_0_to_500_ms;
    scatter(x(~behavior.is_shifted), y(~behavior.is_shifted), ...
        42, [0.65 0.65 0.65], 'o', 'filled');
    scatter(x(behavior.is_shifted), y(behavior.is_shifted), ...
        58, purpleColor, 'o', 'filled');
    for conditionIndex = 1:height(behavior)
        text(x(conditionIndex), y(conditionIndex), ...
            sprintf('  %d', behavior.condition(conditionIndex)), ...
            'FontSize', max(gca().FontSize - 2, 8));
    end
    xline(0, ':', 'Color', [0.5 0.5 0.5]);
    yline(0, ':', 'Color', [0.5 0.5 0.5]);
    xlabel('\Delta acceptance (Purple - Yellow)');
    ylabel('\Delta value projection (0-500 ms)');
    title(sprintf('Across cues: r_s = %.2f, p = %.3g', ...
        result.behavior_neural_spearman_r, ...
        result.behavior_neural_spearman_p));
end
plt.addABCs('ABCDEF');
plt.update('YP population projection GO');

%% Figure 2: cue-specific Purple-minus-Yellow value shifts
plt.figure(1, 2, 'is_title', 'all', ...
    'pixel_w', 440, 'pixel_h', 330, ...
    'gapW_custom', [0.7 0 1.2]);
heatmapLimits = zeros(numel(animalNames), 1);
for animalIndex = 1:numel(animalNames)
    valueDifference = reshape( ...
        YP.animals(animalIndex).projection(3, :, 2, :) - ...
        YP.animals(animalIndex).projection(3, :, 1, :), ...
        9, []);
    heatmapLimits(animalIndex) = max(abs(valueDifference), [], 'all');
end
commonLimit = max(heatmapLimits);
for animalIndex = 1:numel(animalNames)
    plt.ax(1, animalIndex);
    result = YP.animals(animalIndex);
    valueDifference = reshape( ...
        result.projection(3, :, 2, :) - ...
        result.projection(3, :, 1, :), 9, []);
    imagesc(result.time_at, 1:9, valueDifference);
    set(gca, 'YDir', 'normal');
    colormap(gca, blueWhiteRed(257));
    clim([-commonLimit commonLimit]);
    hold on;
    xline(0, 'k--', 'LineWidth', 1);
    behavior = result.behavior;
    labels = string(compose('%d', behavior.condition));
    labels(behavior.is_shifted) = labels(behavior.is_shifted) + " *";
    yticks(1:9);
    yticklabels(labels);
    xlim([-250 1000]);
    xlabel('Time from GO cue onset (ms)');
    ylabel('Condition (* behavioral shift)');
    title(animalNames(animalIndex));
    colorbar;
end
plt.addABCs('AB');
plt.update('YP value shift heatmap GO');


function behavior = computeBehavioralShift(games)
%COMPUTEBEHAVIORALSHIFT Compare acceptance for Purple- and Yellow-first.
    conditionInfo = unique(games(:, ...
        {'condition', 'drop', 'delay', 'DV_overall'}), 'rows');
    conditionInfo = sortrows(conditionInfo, 'condition');
    nConditions = height(conditionInfo);
    pYellow = nan(nConditions, 1);
    pPurple = nan(nConditions, 1);
    pUncorrected = nan(nConditions, 1);
    nYellow = zeros(nConditions, 1);
    nPurple = zeros(nConditions, 1);
    for conditionIndex = 1:nConditions
        condition = conditionInfo.condition(conditionIndex);
        isCondition = games.condition == condition;
        isYellow = games.cue1 == "yellow";
        isPurple = games.cue1 == "purple";
        nYellow(conditionIndex) = sum(isCondition & isYellow);
        nPurple(conditionIndex) = sum(isCondition & isPurple);
        pYellow(conditionIndex) = mean( ...
            games.choice(isCondition & isYellow), 'omitnan');
        pPurple(conditionIndex) = mean( ...
            games.choice(isCondition & isPurple), 'omitnan');
        pUncorrected(conditionIndex) = W.chi2ind_xy( ...
            games.choice(isCondition), isPurple(isCondition));
    end
    behavior = conditionInfo;
    behavior.n_yellow = nYellow;
    behavior.n_purple = nPurple;
    behavior.p_accept_yellow = pYellow;
    behavior.p_accept_purple = pPurple;
    behavior.delta_accept_purple_minus_yellow = pPurple - pYellow;
    behavior.p_uncorrected = pUncorrected;
end

function [axesRaw, normalization] = estimateOfferAxes( ...
        cueData, trainingWindow)
%ESTIMATEOFFERAXES Learn color-collapsed coding axes from offer activity.
    trainingMask = cueData.time_at >= trainingWindow(1) & ...
        cueData.time_at < trainingWindow(2);
    assert(any(trainingMask), ...
        'The offer-axis training window contains no samples.');
    nNeurons = numel(cueData.cells);
    axesRaw = nan(nNeurons, 3);
    normalization.mean = nan(nNeurons, 1);
    normalization.std = nan(nNeurons, 1);

    for neuronIndex = 1:nNeurons
        spikes = cueData.cells{neuronIndex};
        game = cueData.games{cueData.info_cells.gameID(neuronIndex)};
        assert(size(spikes, 1) == height(game), ...
            'Spike trials and behavioral trials must match.');
        center = mean(spikes(:, trainingMask), 'all', 'omitnan');
        scale = std(spikes(:, trainingMask), 0, 'all', 'omitnan');
        if ~isfinite(scale) || scale <= eps
            scale = 1;
        end
        normalization.mean(neuronIndex) = center;
        normalization.std(neuronIndex) = scale;

        trialResponse = mean( ...
            (spikes(:, trainingMask) - center)/scale, ...
            2, 'omitnan');
        conditionInfo = unique(game(:, ...
            {'condition', 'drop', 'delay', 'DV_overall'}), 'rows');
        conditionInfo = sortrows(conditionInfo, 'condition');
        conditionResponse = arrayfun(@(condition)mean( ...
            trialResponse(game.condition == condition), 'omitnan'), ...
            conditionInfo.condition);

        drop = standardize(conditionInfo.drop);
        delay = standardize(conditionInfo.delay);
        value = standardize(conditionInfo.DV_overall);
        dropDelayFit = [ones(height(conditionInfo), 1), ...
            drop, delay] \ conditionResponse;
        valueFit = [ones(height(conditionInfo), 1), ...
            value] \ conditionResponse;
        axesRaw(neuronIndex, :) = ...
            [dropDelayFit(2), dropDelayFit(3), valueFit(2)];
    end
end

function trajectories = computeGoColorTrajectories( ...
        goData, normalization, baselineWindow)
%COMPUTEGOCOLORTRAJECTORIES Average normalized responses by cue and color.
    nNeurons = numel(goData.cells);
    nConditions = 9;
    nColors = 2;
    nTimes = numel(goData.time_at);
    trajectories = nan(nNeurons, nConditions, nColors, nTimes);
    baselineMask = goData.time_at >= baselineWindow(1) & ...
        goData.time_at < baselineWindow(2);
    assert(any(baselineMask), ...
        'The GO baseline window contains no samples.');

    for neuronIndex = 1:nNeurons
        spikes = (goData.cells{neuronIndex} - ...
            normalization.mean(neuronIndex)) / ...
            normalization.std(neuronIndex);
        game = goData.games{goData.info_cells.gameID(neuronIndex)};
        assert(size(spikes, 1) == height(game), ...
            'Spike trials and behavioral trials must match.');
        for condition = 1:nConditions
            for colorIndex = 1:nColors
                if colorIndex == 1
                    isColor = game.cue1 == "yellow";
                else
                    isColor = game.cue1 == "purple";
                end
                trialMask = game.condition == condition & isColor;
                assert(any(trialMask), ...
                    'Every session must contain each condition/color pair.');
                trajectory = mean(spikes(trialMask, :), 1, 'omitnan');
                trajectory = trajectory - mean( ...
                    trajectory(baselineMask), 'omitnan');
                trajectories(neuronIndex, condition, ...
                    colorIndex, :) = trajectory;
            end
        end
    end
end

function statistics = computeProjectionStatistics( ...
        trajectories, axesUnit, selectedConditions, timeAt, ...
        windows, axisNames, nPermutations)
%COMPUTEPROJECTIONSTATISTICS Test neuron-wise alignment by sign flips.
    nAxes = numel(axisNames);
    nWindows = size(windows, 1);
    nRows = nAxes*nWindows;
    statistics = table('Size', [nRows 10], ...
        'VariableTypes', ["string", repmat("double", 1, 9)], ...
        'VariableNames', {'axis', 'window_start_ms', ...
        'window_end_ms', 'n_neurons', 'projection_shift', ...
        'cosine_alignment', 'p_positive', 'p_two_sided', ...
        'q_positive', 'q_two_sided'});
    rowIndex = 0;
    for axisIndex = 1:nAxes
        for windowIndex = 1:nWindows
            rowIndex = rowIndex + 1;
            isLast = windowIndex == nWindows;
            timeMask = timeAt >= windows(windowIndex, 1) & ...
                (timeAt < windows(windowIndex, 2) | ...
                (isLast & timeAt <= windows(windowIndex, 2)));
            delta = trajectories(:, selectedConditions, 2, timeMask) - ...
                trajectories(:, selectedConditions, 1, timeMask);
            neuronDelta = reshape(mean(mean(delta, 2, 'omitnan'), ...
                4, 'omitnan'), [], 1);
            axisWeights = axesUnit(:, axisIndex);
            contributions = axisWeights .* neuronDelta;
            isValid = isfinite(contributions) & ...
                isfinite(axisWeights) & isfinite(neuronDelta);
            contributions = contributions(isValid);
            cosineDenominator = norm(axisWeights(isValid)) * ...
                norm(neuronDelta(isValid));
            if cosineDenominator <= eps
                cosineAlignment = NaN;
            else
                cosineAlignment = dot(axisWeights(isValid), ...
                    neuronDelta(isValid)) / cosineDenominator;
            end
            [pPositive, pTwoSided, observed] = ...
                signFlipTest(contributions, nPermutations);
            statistics(rowIndex, 1:8) = {axisNames(axisIndex), ...
                windows(windowIndex, 1), windows(windowIndex, 2), ...
                numel(contributions), observed, cosineAlignment, ...
                pPositive, pTwoSided};
        end
    end
    statistics.q_positive = ...
        benjaminiHochberg(statistics.p_positive);
    statistics.q_two_sided = ...
        benjaminiHochberg(statistics.p_two_sided);
end

function [pPositive, pTwoSided, observed] = ...
        signFlipTest(contributions, nPermutations)
%SIGNFLIPTEST Test whether aligned neuron contributions sum above zero.
    observed = sum(contributions);
    signs = 2*(rand(numel(contributions), nPermutations) > 0.5) - 1;
    nullDistribution = contributions' * signs;
    pPositive = (1 + sum(nullDistribution >= observed)) / ...
        (nPermutations + 1);
    pTwoSided = (1 + sum(abs(nullDistribution) >= ...
        abs(observed))) / (nPermutations + 1);
end

function qValues = benjaminiHochberg(pValues)
%BENJAMINIHOCHBERG Control false discovery rate within one animal.
    [sortedP, order] = sort(pValues);
    nTests = numel(pValues);
    sortedQ = sortedP .* nTests ./ (1:nTests)';
    sortedQ = flipud(cummin(flipud(sortedQ)));
    sortedQ = min(sortedQ, 1);
    qValues = nan(size(pValues));
    qValues(order) = sortedQ;
end

function z = standardize(x)
%STANDARDIZE Convert a predictor to zero mean and unit sample SD.
    z = (x - mean(x, 'omitnan')) / std(x, 0, 'omitnan');
end

function plotMeanSem(x, observations, color)
%PLOTMEANSEM Plot a mean trajectory with condition-level SEM.
    average = mean(observations, 1, 'omitnan');
    n = sum(isfinite(observations), 1);
    sem = std(observations, 0, 1, 'omitnan') ./ sqrt(max(n, 1));
    fill([x(:); flipud(x(:))], ...
        [average(:) - sem(:); flipud(average(:) + sem(:))], ...
        color, 'FaceAlpha', 0.18, 'EdgeColor', 'none');
    plot(x, average, 'Color', color, 'LineWidth', 2);
end

function addReferenceLines
%ADDREFERENCELINES Mark GO onset and zero projection.
    xline(0, 'k--', 'LineWidth', 1);
    yline(0, ':', 'Color', [0.5 0.5 0.5]);
    xlabel('Time from GO cue onset (ms)');
end

function colors = blueWhiteRed(nColors)
%BLUEWHITERED Create a diverging blue-white-red colormap.
    if nargin < 1
        nColors = 257;
    end
    half = ceil(nColors/2);
    blueToWhite = [linspace(0.15, 1, half)', ...
        linspace(0.35, 1, half)', ones(half, 1)];
    whiteToRed = [ones(half, 1), ...
        linspace(1, 0.20, half)', ...
        linspace(1, 0.20, half)'];
    colors = [blueToWhite; whiteToRed(2:end, :)];
    colors = colors(round(linspace(1, size(colors, 1), nColors)), :);
end
