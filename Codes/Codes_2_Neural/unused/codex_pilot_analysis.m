%% Pilot analysis: does choice-axis activity explain the Y/P value projection?
% The value axis is the original -250:0 ms pre-GO DV_overall axis.
% The choice axis is the jointly fitted choice coefficient from the same
% window, controlling for DV_overall and release1.

if ~exist('go', 'var')
    data = W.load('../../TempData/data');
    go = data.go;
end

rng(1, 'twister');
valueAxes = W.load('../../TempData/value_axisGO');
jointAxes = W.load( ...
    '../../TempData/value_axisGO_control_for_choicemotor');

axisWindowIndex = 1;
baselineWindow = [-250 0];
minimumTrials = 10;
analysisWindows = [0 250; 250 500];
animalNames = ["Monkey S", "Monkey T"];
yellowColor = [0.90 0.65 0.05];
purpleColor = [0.55 0.25 0.72];
rejectColor = [0.35 0.35 0.35];
acceptColor = [0.10 0.45 0.75];
choiceComponentColor = [0.10 0.45 0.75];
orthogonalColor = [0.85 0.35 0.10];

pilotResults = repmat(struct, 1, numel(animalNames));
statRows = cell(0, 13);

for animalIndex = 1:numel(animalNames)
    goData = go{animalIndex};
    nNeurons = numel(goData.cells);
    nTimes = numel(goData.time_at);

    assert(isequal(valueAxes.animals(animalIndex).info_cells.cellID, ...
        jointAxes.animals(animalIndex).info_cells.cellID), ...
        'Value- and choice-axis neurons must have identical ordering.');

    valueAxis = valueAxes.animals(animalIndex). ...
        axis_unit(:, axisWindowIndex);
    choiceAxis = jointAxes.animals(animalIndex). ...
        axis_choice_unit(:, axisWindowIndex);
    choiceAxesByWindow = jointAxes.animals(animalIndex). ...
        axis_choice_unit;
    choiceCosineByWindow = valueAxis' * choiceAxesByWindow;

    [allYPTrajectories, matchedYPTrajectories, ...
        choiceTrajectories] = makePilotTrajectories( ...
        goData, baselineWindow, minimumTrials);

    % Use one mask for the choice-axis validation and matched-Y/P plots.
    combinedControlTrajectories = cat(2, ...
        matchedYPTrajectories, choiceTrajectories);
    [combinedControlTrajectories, controlAxes, ...
        validControlNeurons] = prepareProjection( ...
        combinedControlTrajectories, [valueAxis, choiceAxis]);
    matchedYPTrajectories = combinedControlTrajectories(:, 1:2, :);
    choiceTrajectories = combinedControlTrajectories(:, 3:4, :);
    controlChoiceAxis = controlAxes(:, 2);
    projectionMatchedYPChoice = reshape( ...
        controlChoiceAxis' * reshape( ...
        matchedYPTrajectories, nNeurons, []), ...
        2, nTimes);
    projectionChoiceChoice = reshape( ...
        controlChoiceAxis' * reshape( ...
        choiceTrajectories, nNeurons, []), ...
        2, nTimes);

    % Decompose the exact value projection used for the all-cue Y/P panel.
    [allYPTrajectories, decompositionAxes, validAllYPNeurons] = ...
        prepareProjection(allYPTrajectories, [valueAxis, choiceAxis]);
    valueAxisUsed = decompositionAxes(:, 1);
    choiceAxisUsed = decompositionAxes(:, 2);
    axisCosine = valueAxisUsed' * choiceAxisUsed;
    valueChoiceComponent = axisCosine * choiceAxisUsed;
    valueOrthogonalComponent = valueAxisUsed - valueChoiceComponent;

    projectionValue = reshape(valueAxisUsed' * ...
        reshape(allYPTrajectories, nNeurons, []), ...
        9, 2, nTimes);
    projectionChoiceComponent = reshape(valueChoiceComponent' * ...
        reshape(allYPTrajectories, nNeurons, []), ...
        9, 2, nTimes);
    projectionOrthogonal = reshape(valueOrthogonalComponent' * ...
        reshape(allYPTrajectories, nNeurons, []), ...
        9, 2, nTimes);

    meanValue = reshape(mean( ...
        projectionValue, [1 2], 'omitnan'), 1, nTimes);
    meanChoiceComponent = reshape(mean( ...
        projectionChoiceComponent, [1 2], 'omitnan'), 1, nTimes);
    meanOrthogonal = reshape(mean( ...
        projectionOrthogonal, [1 2], 'omitnan'), 1, nTimes);

    colorValue = reshape(mean( ...
        projectionValue, 1, 'omitnan'), 2, nTimes);
    colorChoiceComponent = reshape(mean( ...
        projectionChoiceComponent, 1, 'omitnan'), 2, nTimes);
    colorOrthogonal = reshape(mean( ...
        projectionOrthogonal, 1, 'omitnan'), 2, nTimes);
    deltaValue = colorValue(2, :) - colorValue(1, :);
    deltaChoiceComponent = colorChoiceComponent(2, :) - ...
        colorChoiceComponent(1, :);
    deltaOrthogonal = colorOrthogonal(2, :) - colorOrthogonal(1, :);

    pilotResults(animalIndex).animal = animalNames(animalIndex);
    pilotResults(animalIndex).time_at = goData.time_at;
    pilotResults(animalIndex).axis_cosine = axisCosine;
    pilotResults(animalIndex).choice_cosine_by_window = ...
        choiceCosineByWindow;
    pilotResults(animalIndex).n_valid_allYP = sum(validAllYPNeurons);
    pilotResults(animalIndex).n_valid_control = sum(validControlNeurons);
    pilotResults(animalIndex).projection_choice = ...
        projectionChoiceChoice;
    pilotResults(animalIndex).projection_matchedYP_choice = ...
        projectionMatchedYPChoice;
    pilotResults(animalIndex).mean_value = meanValue;
    pilotResults(animalIndex).mean_choice_component = ...
        meanChoiceComponent;
    pilotResults(animalIndex).mean_orthogonal_component = ...
        meanOrthogonal;
    pilotResults(animalIndex).delta_value = deltaValue;
    pilotResults(animalIndex).delta_choice_component = ...
        deltaChoiceComponent;
    pilotResults(animalIndex).delta_orthogonal_component = ...
        deltaOrthogonal;

    for windowIndex = 1:size(analysisWindows, 1)
        window = analysisWindows(windowIndex, :);
        timeMask = goData.time_at >= window(1) & ...
            goData.time_at < window(2);
        actualCommon = mean(meanValue(timeMask), 'omitnan');
        choiceCommon = mean(meanChoiceComponent(timeMask), 'omitnan');
        orthogonalCommon = mean(meanOrthogonal(timeMask), 'omitnan');
        actualDelta = mean(deltaValue(timeMask), 'omitnan');
        choiceDelta = mean(deltaChoiceComponent(timeMask), 'omitnan');
        orthogonalDelta = mean(deltaOrthogonal(timeMask), 'omitnan');
        acceptMinusReject = mean( ...
            projectionChoiceChoice(2, timeMask) - ...
            projectionChoiceChoice(1, timeMask), 'omitnan');
        purpleMinusYellowChoice = mean( ...
            projectionMatchedYPChoice(2, timeMask) - ...
            projectionMatchedYPChoice(1, timeMask), 'omitnan');
        statRows(end + 1, :) = { ...
            animalNames(animalIndex), window(1), window(2), ...
            axisCosine, choiceCosineByWindow(windowIndex + 1), ...
            acceptMinusReject, purpleMinusYellowChoice, ...
            actualCommon, choiceCommon, orthogonalCommon, ...
            actualDelta, choiceDelta, orthogonalDelta}; %#ok<SAGROW>
    end
end

pilotStats = cell2table(statRows, 'VariableNames', { ...
    'Animal', 'WindowStart', 'WindowEnd', 'ValueChoiceCosine', ...
    'EpochValueChoiceCosine', 'AcceptMinusRejectOnChoice', ...
    'PurpleMinusYellowOnChoice', ...
    'MeanValue', 'MeanChoiceComponent', 'MeanOrthogonalComponent', ...
    'DeltaPurpleMinusYellow', 'DeltaChoiceComponent', ...
    'DeltaOrthogonalComponent'});
disp(pilotStats);

%% Figure 1: validate and use the choice axis
figure('Color', 'w', 'Name', 'Choice-axis pilot analysis');
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for animalIndex = 1:numel(animalNames)
    result = pilotResults(animalIndex);
    timeAt = result.time_at;

    nexttile(animalIndex);
    hold on;
    plot(timeAt, result.projection_choice(1, :), ...
        'Color', rejectColor, 'LineWidth', 1.8);
    plot(timeAt, result.projection_choice(2, :), ...
        'Color', acceptColor, 'LineWidth', 1.8);
    formatPilotAxis(gca);
    title(sprintf('%s: choice-axis validation', animalNames(animalIndex)));
    ylabel('Choice-axis projection');
    if animalIndex == 2
        legend({'Reject', 'Accept'}, 'Location', 'best', ...
            'Box', 'off');
    end

    nexttile(2 + animalIndex);
    hold on;
    plot(timeAt, result.projection_matchedYP_choice(1, :), ...
        'Color', yellowColor, 'LineWidth', 1.8);
    plot(timeAt, result.projection_matchedYP_choice(2, :), ...
        'Color', purpleColor, 'LineWidth', 1.8);
    formatPilotAxis(gca);
    title(sprintf(['%s: Y/P on choice axis ' ...
        '(choice matched)'], animalNames(animalIndex)));
    xlabel('Time from GO cue onset (ms)');
    ylabel('Choice-axis projection');
    if animalIndex == 2
        legend({'Yellow', 'Purple'}, 'Location', 'best', ...
            'Box', 'off');
    end
end

%% Figure 2: decompose the value-axis signal into choice and residual parts
figure('Color', 'w', 'Name', 'Value-choice axis decomposition');
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for animalIndex = 1:numel(animalNames)
    result = pilotResults(animalIndex);
    timeAt = result.time_at;

    nexttile(animalIndex);
    hold on;
    plot(timeAt, result.mean_value, 'k', 'LineWidth', 2);
    plot(timeAt, result.mean_choice_component, ...
        'Color', choiceComponentColor, 'LineWidth', 1.8);
    plot(timeAt, result.mean_orthogonal_component, ...
        'Color', orthogonalColor, 'LineWidth', 1.8);
    formatPilotAxis(gca);
    title(sprintf('%s: common Y/P activity, cos = %.2f', ...
        animalNames(animalIndex), result.axis_cosine));
    ylabel('Value-axis projection');
    if animalIndex == 2
        legend({'Observed value projection', ...
            'Choice-aligned component', 'Choice-orthogonal component'}, ...
            'Location', 'best', 'Box', 'off');
    end

    nexttile(2 + animalIndex);
    hold on;
    plot(timeAt, result.delta_value, 'k', 'LineWidth', 2);
    plot(timeAt, result.delta_choice_component, ...
        'Color', choiceComponentColor, 'LineWidth', 1.8);
    plot(timeAt, result.delta_orthogonal_component, ...
        'Color', orthogonalColor, 'LineWidth', 1.8);
    formatPilotAxis(gca);
    title(sprintf('%s: Purple minus Yellow', animalNames(animalIndex)));
    xlabel('Time from GO cue onset (ms)');
    ylabel('\Delta value-axis projection');
    if animalIndex == 2
        legend({'Observed difference', 'Choice-aligned component', ...
            'Choice-orthogonal component'}, ...
            'Location', 'best', 'Box', 'off');
    end
end

%% Figure 3: test whether the choice axis rotates toward the value axis
choiceWindowLabels = ["-250:0", "0:250", "250:500", ...
    "500:750", "750:1000"];
figure('Color', 'w', 'Name', 'Value-choice alignment by time');
hold on;
for animalIndex = 1:numel(animalNames)
    plot(1:numel(choiceWindowLabels), ...
        pilotResults(animalIndex).choice_cosine_by_window, ...
        '-o', 'LineWidth', 1.8, ...
        'DisplayName', animalNames(animalIndex));
end
yline(0, ':', 'Color', [0.5 0.5 0.5]);
xlim([0.75 numel(choiceWindowLabels) + 0.25]);
xticks(1:numel(choiceWindowLabels));
xticklabels(choiceWindowLabels);
xlabel('Choice-axis training window relative to GO (ms)');
ylabel('Cosine with pre-GO value axis');
title('Does the choice axis rotate toward the plotted value axis?');
legend('Location', 'best', 'Box', 'off');
box off;
set(gca, 'FontSize', 11);


function [allYP, matchedYP, choice] = makePilotTrajectories( ...
    goData, baselineWindow, minimumTrials)
%MAKEPILOTTRAJECTORIES Construct baseline-corrected population activity.
    nNeurons = numel(goData.cells);
    nConditions = 9;
    nColors = 2;
    nTimes = numel(goData.time_at);
    allYP = nan(nNeurons, nConditions, nColors, nTimes);
    matchedYP = nan(nNeurons, nColors, nTimes);
    choice = nan(nNeurons, 2, nTimes);
    baselineMask = goData.time_at >= baselineWindow(1) & ...
        goData.time_at < baselineWindow(2);

    for neuronIndex = 1:nNeurons
        spikes = goData.cells{neuronIndex};
        game = goData.games{goData.info_cells.gameID(neuronIndex)};

        masks = get_balanced_trials(game, 'allYP');
        for condition = 1:nConditions
            for colorIndex = 1:nColors
                allYP(neuronIndex, condition, colorIndex, :) = ...
                    baselineCorrectedMean(spikes, ...
                    masks{condition, colorIndex}, baselineMask, ...
                    nTimes, minimumTrials);
            end
        end

        masks = get_balanced_trials(game, 'matching_choice');
        for colorIndex = 1:nColors
            matchedYP(neuronIndex, colorIndex, :) = ...
                baselineCorrectedMean(spikes, masks{colorIndex}, ...
                baselineMask, nTimes, minimumTrials);
        end

        masks = get_balanced_trials(game, 'choice');
        for choiceIndex = 1:2
            choice(neuronIndex, choiceIndex, :) = ...
                baselineCorrectedMean(spikes, masks{choiceIndex}, ...
                baselineMask, nTimes, minimumTrials);
        end
    end
end


function trajectory = baselineCorrectedMean( ...
    spikes, trialMask, baselineMask, nTimes, minimumTrials)
%BASELINECORRECTEDMEAN Average selected trials and subtract pre-GO activity.
    if numel(trialMask) < minimumTrials
        trajectory = nan(1, nTimes);
        return;
    end
    trajectory = mean(spikes(trialMask, :), 1, 'omitnan');
    baseline = mean(trajectory(baselineMask), 'omitnan');
    trajectory = trajectory - baseline;
end


function [trajectories, axesUnit, validNeurons] = ...
    prepareProjection(trajectories, axesRaw)
%PREPAREPROJECTION Apply one common neuron mask and renormalize each axis.
    nNeurons = size(trajectories, 1);
    invalidActivity = any(reshape( ...
        ~isfinite(trajectories), nNeurons, []), 2);
    invalidAxes = any(~isfinite(axesRaw), 2);
    validNeurons = ~(invalidActivity | invalidAxes);
    trajectories(~isfinite(trajectories)) = 0;
    trajectories(~validNeurons, :) = 0;
    axesUnit = axesRaw;
    axesUnit(~validNeurons, :) = 0;
    axisNorms = vecnorm(axesUnit, 2, 1);
    assert(all(axisNorms > 0 & isfinite(axisNorms)), ...
        'At least one projection axis has no valid neurons.');
    axesUnit = axesUnit ./ axisNorms;
end


function formatPilotAxis(axisHandle)
%FORMATPILOTAXIS Apply common GO-locked plotting limits.
    xline(axisHandle, 0, '--', 'Color', [0.4 0.4 0.4]);
    yline(axisHandle, 0, ':', 'Color', [0.6 0.6 0.6]);
    xlim(axisHandle, [-250 500]);
    xticks(axisHandle, -250:250:500);
    box(axisHandle, 'off');
    axisHandle.FontSize = 11;
end
