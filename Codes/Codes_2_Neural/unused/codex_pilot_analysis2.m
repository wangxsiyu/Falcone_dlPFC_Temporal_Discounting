%% Pilot analysis 2: sensory color or a persistent choice-action state?
% With effect coding, cue color is exactly the choice-by-release1
% interaction:
%   Purple: choice and release1 have the same sign.
%   Yellow: choice and release1 have opposite signs.
% This script estimates condition-controlled choice, motor, and interaction
% coefficients at every GO-locked time point and projects them onto the
% original pre-GO value axis.

if ~exist('go', 'var')
    data = W.load('../../TempData/data');
    go = data.go;
end

valueAxes = W.load('../../TempData/value_axisGO');
yp = W.load('../../TempData/projections_YP');
axisWindowIndex = 1;
baselineWindow = [-250 0];
analysisWindows = [0 250; 250 500; 500 750; 750 1000];
animalNames = ["Monkey S", "Monkey T"];
colorNames = ["Yellow", "Purple"];
yellowColor = [0.90 0.65 0.05];
purpleColor = [0.55 0.25 0.72];
choiceColor = [0.10 0.45 0.75];
motorColor = [0.80 0.25 0.20];
interactionColor = [0.45 0.15 0.65];

pilot2Results = repmat(struct, 1, numel(animalNames));
behaviorRows = cell(0, 7);
timeCourseRows = cell(0, 14);

for animalIndex = 1:numel(animalNames)
    goData = go{animalIndex};
    nNeurons = numel(goData.cells);
    nTimes = numel(goData.time_at);
    baselineMask = goData.time_at >= baselineWindow(1) & ...
        goData.time_at < baselineWindow(2);

    valueAxis = valueAxes.animals(animalIndex). ...
        axis_unit(:, axisWindowIndex);
    betaTime = nan(nNeurons, 3, nTimes);
    mappingMismatch = 0;

    for neuronIndex = 1:nNeurons
        spikes = goData.cells{neuronIndex};
        game = goData.games{goData.info_cells.gameID(neuronIndex)};

        choiceCode = 2 * game.choice - 1;
        motorCode = 2 * game.release1 - 1;
        interactionCode = choiceCode .* motorCode;
        isPurple = game.cue1 == "purple";
        validMapping = (interactionCode == 1) == isPurple;
        mappingMismatch = mappingMismatch + sum( ...
            ~validMapping);

        conditionTerms = zeros(height(game), 8);
        for condition = 2:9
            conditionTerms(:, condition - 1) = ...
                game.condition == condition;
        end
        design = [ones(height(game), 1), conditionTerms, ...
            choiceCode, motorCode, interactionCode];
        validBehavior = all(isfinite(design), 2) & validMapping;

        for timeIndex = 1:nTimes
            validTrials = validBehavior & ...
                isfinite(spikes(:, timeIndex));
            designNow = design(validTrials, :);
            assert(rank(designNow) == size(designNow, 2), ...
                'The condition/choice/motor design matrix is rank deficient.');
            coefficients = designNow \ spikes(validTrials, timeIndex);
            betaTime(neuronIndex, :, timeIndex) = ...
                coefficients(end - 2:end);
        end
    end

    if mappingMismatch > 0
        warning('Excluded %d neuron-trial records with inconsistent mapping.', ...
            mappingMismatch);
    end

    betaTime = betaTime - mean( ...
        betaTime(:, :, baselineMask), 3, 'omitnan');
    validNeurons = all(reshape(isfinite(betaTime), ...
        nNeurons, []), 2) & isfinite(valueAxis);
    betaTime(~validNeurons, :, :) = 0;
    valueAxis(~validNeurons) = 0;
    valueAxis = valueAxis / norm(valueAxis);

    % Multiplication by two converts an effect-coded coefficient into the
    % full level contrast. The interaction is Purple minus Yellow.
    factorProjection = 2 * reshape(valueAxis' * ...
        reshape(betaTime, nNeurons, []), 3, nTimes);

    allYPProjection = yp.projections{1, animalIndex};
    allYPProjection = reshape( ...
        allYPProjection(axisWindowIndex, :, :, :), 9, 2, nTimes);
    commonValueProjection = reshape(mean( ...
        allYPProjection, [1 2], 'omitnan'), 1, nTimes);
    colorValueProjection = reshape(mean( ...
        allYPProjection, 1, 'omitnan'), 2, nTimes);
    rawPurpleMinusYellow = colorValueProjection(2, :) - ...
        colorValueProjection(1, :);

    matchedProjection = yp.projections{4, animalIndex};
    matchedProjection = reshape( ...
        matchedProjection(axisWindowIndex, :, :), 2, nTimes);
    matchedPurpleMinusYellow = matchedProjection(2, :) - ...
        matchedProjection(1, :);

    gameIDs = unique(goData.info_cells.gameID);
    animalGame = vertcat(goData.games{gameIDs});
    choiceRates = nan(9, 2);
    motorRates = nan(9, 2);
    for condition = 1:9
        for colorIndex = 1:2
            colorMask = animalGame.cue1 == lower(colorNames(colorIndex));
            conditionColorMask = animalGame.condition == condition & ...
                colorMask;
            choiceRates(condition, colorIndex) = mean( ...
                animalGame.choice(conditionColorMask), 'omitnan');
            motorRates(condition, colorIndex) = mean( ...
                animalGame.release1(conditionColorMask), 'omitnan');
        end
    end
    deltaChoiceRate = mean( ...
        choiceRates(:, 2) - choiceRates(:, 1), 'omitnan');
    deltaMotorRate = mean( ...
        motorRates(:, 2) - motorRates(:, 1), 'omitnan');
    choiceMixtureContribution = ...
        deltaChoiceRate * factorProjection(1, :);
    motorMixtureContribution = ...
        deltaMotorRate * factorProjection(2, :);
    predictedPurpleMinusYellow = choiceMixtureContribution + ...
        motorMixtureContribution + factorProjection(3, :);
    residualPurpleMinusYellow = rawPurpleMinusYellow - ...
        predictedPurpleMinusYellow;

    medianRelease1 = median( ...
        animalGame.rt_release1, 'omitnan');
    medianCue2Onset = median( ...
        animalGame.rt_cue1_to_cue2, 'omitnan');

    for colorIndex = 1:2
        colorMask = animalGame.cue1 == lower(colorNames(colorIndex));
        behaviorRows(end + 1, :) = { ...
            animalNames(animalIndex), colorNames(colorIndex), ...
            sum(colorMask), ...
            mean(animalGame.choice(colorMask), 'omitnan'), ...
            mean(animalGame.release1(colorMask), 'omitnan'), ...
            median(animalGame.rt_release1(colorMask), 'omitnan'), ...
            median(animalGame.rt_cue1_to_cue2(colorMask), ...
            'omitnan')}; %#ok<SAGROW>
    end

    for windowIndex = 1:size(analysisWindows, 1)
        window = analysisWindows(windowIndex, :);
        timeMask = goData.time_at >= window(1) & ...
            goData.time_at < window(2);
        timeCourseRows(end + 1, :) = { ...
            animalNames(animalIndex), window(1), window(2), ...
            mean(commonValueProjection(timeMask), 'omitnan'), ...
            mean(factorProjection(1, timeMask), 'omitnan'), ...
            mean(factorProjection(2, timeMask), 'omitnan'), ...
            mean(factorProjection(3, timeMask), 'omitnan'), ...
            mean(rawPurpleMinusYellow(timeMask), 'omitnan'), ...
            mean(matchedPurpleMinusYellow(timeMask), 'omitnan'), ...
            mean(choiceMixtureContribution(timeMask), 'omitnan'), ...
            mean(motorMixtureContribution(timeMask), 'omitnan'), ...
            mean(predictedPurpleMinusYellow(timeMask), 'omitnan'), ...
            mean(residualPurpleMinusYellow(timeMask), 'omitnan'), ...
            sum(validNeurons)}; %#ok<SAGROW>
    end

    pilot2Results(animalIndex).animal = animalNames(animalIndex);
    pilot2Results(animalIndex).time_at = goData.time_at;
    pilot2Results(animalIndex).common_value_projection = ...
        commonValueProjection;
    pilot2Results(animalIndex).choice_projection = ...
        factorProjection(1, :);
    pilot2Results(animalIndex).motor_projection = ...
        factorProjection(2, :);
    pilot2Results(animalIndex).interaction_projection = ...
        factorProjection(3, :);
    pilot2Results(animalIndex).raw_purple_minus_yellow = ...
        rawPurpleMinusYellow;
    pilot2Results(animalIndex).matched_purple_minus_yellow = ...
        matchedPurpleMinusYellow;
    pilot2Results(animalIndex).choice_mixture_contribution = ...
        choiceMixtureContribution;
    pilot2Results(animalIndex).motor_mixture_contribution = ...
        motorMixtureContribution;
    pilot2Results(animalIndex).predicted_purple_minus_yellow = ...
        predictedPurpleMinusYellow;
    pilot2Results(animalIndex).residual_purple_minus_yellow = ...
        residualPurpleMinusYellow;
    pilot2Results(animalIndex).delta_choice_rate = deltaChoiceRate;
    pilot2Results(animalIndex).delta_motor_rate = deltaMotorRate;
    pilot2Results(animalIndex).median_release1 = medianRelease1;
    pilot2Results(animalIndex).median_cue2_onset = medianCue2Onset;
    pilot2Results(animalIndex).n_valid_neurons = sum(validNeurons);
end

behaviorStats = cell2table(behaviorRows, 'VariableNames', { ...
    'Animal', 'Color', 'NTrials', 'AcceptRate', 'Release1Rate', ...
    'MedianRelease1RT', 'MedianCue2Onset'});
timeCourseStats = cell2table(timeCourseRows, 'VariableNames', { ...
    'Animal', 'WindowStart', 'WindowEnd', 'CommonValueProjection', ...
    'ChoiceMainEffect', 'MotorMainEffect', ...
    'ChoiceByMotorInteraction', 'RawPurpleMinusYellow', ...
    'ChoiceMatchedPurpleMinusYellow', 'ChoiceMixtureContribution', ...
    'MotorMixtureContribution', 'PredictedPurpleMinusYellow', ...
    'ResidualPurpleMinusYellow', 'NValidNeurons'});
disp(behaviorStats);
disp(timeCourseStats);

%% Figure 1: temporal decomposition on the plotted value axis
figure('Color', 'w', ...
    'Name', 'Choice-motor explanation of the Y/P response');
tiledlayout(4, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for animalIndex = 1:numel(animalNames)
    result = pilot2Results(animalIndex);
    timeAt = result.time_at;

    nexttile(animalIndex);
    hold on;
    plot(timeAt, result.common_value_projection, ...
        'k', 'LineWidth', 2);
    addTaskTiming(result);
    formatPilot2Axis(gca);
    title(sprintf(['%s: common GO-locked component\n' ...
        'release1 RT = %.0f ms, cue2 = %.0f ms'], ...
        animalNames(animalIndex), result.median_release1, ...
        result.median_cue2_onset));
    ylabel('Value-axis projection');

    nexttile(2 + animalIndex);
    hold on;
    plot(timeAt, result.choice_projection, ...
        'Color', choiceColor, 'LineWidth', 1.8);
    plot(timeAt, result.motor_projection, ...
        'Color', motorColor, 'LineWidth', 1.8);
    formatPilot2Axis(gca);
    title(sprintf('%s: additive behavioral effects', ...
        animalNames(animalIndex)));
    ylabel('Value-axis contrast');
    if animalIndex == 2
        legend({'Choice: accept - reject', ...
            'Motor: release1 = 1 - 0'}, ...
            'Location', 'best', 'Box', 'off');
    end

    nexttile(4 + animalIndex);
    hold on;
    plot(timeAt, result.raw_purple_minus_yellow, ...
        'k', 'LineWidth', 2);
    plot(timeAt, result.choice_mixture_contribution, ...
        'Color', choiceColor, 'LineWidth', 1.5);
    plot(timeAt, result.motor_mixture_contribution, ...
        'Color', motorColor, 'LineWidth', 1.5);
    plot(timeAt, result.interaction_projection, ...
        'Color', interactionColor, 'LineWidth', 1.8);
    plot(timeAt, result.residual_purple_minus_yellow, ...
        '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.4);
    formatPilot2Axis(gca);
    title(sprintf(['%s: observed color contrast decomposition\n' ...
        '\\Delta choice rate = %.2f, \\Delta motor rate = %.2f'], ...
        animalNames(animalIndex), result.delta_choice_rate, ...
        result.delta_motor_rate));
    ylabel('Purple - Yellow projection');
    if animalIndex == 2
        legend({'Observed P - Y', 'Choice-mixture contribution', ...
            'Motor-mixture contribution', ...
            'Choice \times motor interaction', 'Residual'}, ...
            'Location', 'best', 'Box', 'off');
    end

    nexttile(6 + animalIndex);
    hold on;
    plot(timeAt, result.matched_purple_minus_yellow, ...
        'Color', purpleColor, 'LineWidth', 1.8);
    plot(timeAt, result.interaction_projection, '--', ...
        'Color', interactionColor, 'LineWidth', 1.8);
    formatPilot2Axis(gca);
    title(sprintf('%s: after matching marginal choice/action', ...
        animalNames(animalIndex)));
    xlabel('Time from GO cue onset (ms)');
    ylabel('Purple - Yellow projection');
    if animalIndex == 2
        legend({'Matched P - Y', ...
            'Condition-controlled choice \times motor'}, ...
            'Location', 'best', 'Box', 'off');
    end
end

%% Figure 2: behavioral coupling between cue color, choice, and action
figure('Color', 'w', 'Name', 'Behavioral color-choice-motor coupling');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for animalIndex = 1:numel(animalNames)
    nexttile;
    animalRows = behaviorStats.Animal == animalNames(animalIndex);
    values = [behaviorStats.AcceptRate(animalRows), ...
        behaviorStats.Release1Rate(animalRows)];
    bars = bar(values, 'grouped');
    bars(1).FaceColor = [0.25 0.55 0.80];
    bars(2).FaceColor = [0.80 0.35 0.20];
    xticklabels(colorNames);
    ylim([0 1]);
    ylabel('Trial proportion');
    title(animalNames(animalIndex));
    box off;
    set(gca, 'FontSize', 11);
    if animalIndex == 2
        legend({'Accept', 'Release1 = 1'}, ...
            'Location', 'best', 'Box', 'off');
    end
end


function addTaskTiming(result)
%ADDTASKTIMING Mark typical response and second-cue times.
    xline(result.median_release1, ':', 'Color', [0.2 0.2 0.2]);
    xline(result.median_cue2_onset, ':', 'Color', [0.5 0.5 0.5]);
end


function formatPilot2Axis(axisHandle)
%FORMATPILOT2AXIS Apply common formatting to GO-locked panels.
    xline(axisHandle, 0, '--', 'Color', [0.4 0.4 0.4]);
    yline(axisHandle, 0, ':', 'Color', [0.65 0.65 0.65]);
    xlim(axisHandle, [-250 1250]);
    xticks(axisHandle, -250:250:1250);
    box(axisHandle, 'off');
    axisHandle.FontSize = 11;
end
