%% Estimate GO-locked value, choice, and motor coding axes
trainingWindows = {[-250 0], [0 250], [250 500], [500 750], [750 1000]};
factorNames = {'DV_overall', 'choice', 'release1'};
axisNames = ["Value", "Choice", "Motor"];
animalNames = ["Monkey S", "Monkey T"];
nPseudoTrialsPerCondition = 100;
rng(1, 'twister');

valueAxis = struct;
valueAxis.settings = W.struct( ...
    'training_lock', 'GO signal', ...
    'training_window_ms', trainingWindows, ...
    'axis_names', axisNames, ...
    'value_definition', 'Model 1 DV_overall', ...
    'coefficient_method', ...
    'W.anovan_slidingwindow on trial-level window-averaged activity', ...
    'model', 'firing rate ~ 1 + DV_overall + choice + release1', ...
    'continuous_factors', 1, ...
    'categorical_contrasts', ...
    'choice: 1 minus 0; motor: release1=1 minus release1=0', ...
    'n_pseudotrials_per_condition', nPseudoTrialsPerCondition, ...
    'is_crossvalidated', false);
valueAxis.animals = repmat(struct, numel(animalNames), 1);

for animalIndex = 1:numel(animalNames)
    d = go{animalIndex};
    d = W.combinedcells_removeNAtrials(d);
    d = W.pseudo_sampletrials_bycond( ...
        d, 'condition', nPseudoTrialsPerCondition);

    timeMasks = makeTimeMasks(d.time_at, trainingWindows);
    d.cells = W.cellfun(@(x) ...
        averageWithinWindows(x, timeMasks), d.cells);
    windowEdges = vertcat(trainingWindows{:});
    d.time_at = mean(windowEdges, 2)';
    d.time_win = diff(windowEdges, 1, 2)';

    anova = W.anovan_slidingwindow( ...
        d, d.games, factorNames, ...
        'continuous', 1, 'is_normalize', true);

    betaValue = extractCoefficient( ...
        anova, 'DV_overall', numel(trainingWindows));
    betaChoice = extractCoefficient( ...
        anova, 'choice', numel(trainingWindows));
    betaMotor = extractCoefficient( ...
        anova, 'release1', numel(trainingWindows));
    assert(all(isfinite([betaValue, betaChoice, betaMotor]), 'all'), ...
        'Every neuron must yield finite value, choice, and motor coefficients.');

    axisValueUnit = normalizeColumns(betaValue);
    axisChoiceUnit = normalizeColumns(betaChoice);
    axisMotorUnit = normalizeColumns(betaMotor);
    betaAxes = cat(3, betaValue, betaChoice, betaMotor);
    axesUnit = cat(3, axisValueUnit, axisChoiceUnit, axisMotorUnit);
    axisCosine = nan(numel(axisNames), numel(axisNames), ...
        numel(trainingWindows));
    for windowIndex = 1:numel(trainingWindows)
        weights = squeeze(axesUnit(:, windowIndex, :));
        axisCosine(:, :, windowIndex) = weights'*weights;
    end

    valueAxis.animals(animalIndex).name = animalNames(animalIndex);
    valueAxis.animals(animalIndex).info_cells = d.info_cells;
    valueAxis.animals(animalIndex).beta = betaValue;
    valueAxis.animals(animalIndex).axis_unit = axisValueUnit;
    valueAxis.animals(animalIndex).beta_value = betaValue;
    valueAxis.animals(animalIndex).beta_choice = betaChoice;
    valueAxis.animals(animalIndex).beta_motor = betaMotor;
    valueAxis.animals(animalIndex).axis_value_unit = axisValueUnit;
    valueAxis.animals(animalIndex).axis_choice_unit = axisChoiceUnit;
    valueAxis.animals(animalIndex).axis_motor_unit = axisMotorUnit;
    valueAxis.animals(animalIndex).beta_axes = betaAxes;
    valueAxis.animals(animalIndex).axes_unit = axesUnit;
    valueAxis.animals(animalIndex).axis_cosine = axisCosine;
end

W.save('../../TempData/value_axisGO_control_for_choicemotor', ...
    'valueAxis', valueAxis);


function timeMasks = makeTimeMasks(timePoints, trainingWindows)
%MAKETIMEMASKS Create one mask for each GO-relative training window.
    nWindows = numel(trainingWindows);
    timeMasks = cell(1, nWindows);
    for windowIndex = 1:nWindows
        window = trainingWindows{windowIndex};
        timeMasks{windowIndex} = ...
            timePoints >= window(1) & timePoints < window(2);
        assert(any(timeMasks{windowIndex}), ...
            'Every training window must contain time samples.');
    end
end


function activity = averageWithinWindows(spikes, timeMasks)
%AVERAGEWITHINWINDOWS Average every trial before fitting the joint model.
    nWindows = numel(timeMasks);
    activity = nan(size(spikes, 1), nWindows);
    for windowIndex = 1:nWindows
        activity(:, windowIndex) = mean( ...
            spikes(:, timeMasks{windowIndex}), 2, 'omitnan');
    end
end


function beta = extractCoefficient(anova, factorName, nWindows)
%EXTRACTCOEFFICIENT Collect a continuous beta or binary level contrast.
    coefficientNames = string(anova.cells{1}.name_factors_terms);
    coefficientRow = find(coefficientNames == string(factorName));
    if isscalar(coefficientRow)
        positiveRow = coefficientRow;
        negativeRow = [];
    else
        negativeRow = find(coefficientNames == ...
            string(factorName) + "=0");
        positiveRow = find(coefficientNames == ...
            string(factorName) + "=1");
        assert(isscalar(negativeRow) && isscalar(positiveRow), ...
            'The requested binary contrast rows must be unique.');
    end

    beta = nan(numel(anova.cells), nWindows);
    for windowIndex = 1:nWindows
        beta(:, windowIndex) = W.cellfun(@(x) ...
            x.coef_factors_terms(positiveRow, windowIndex), ...
            anova.cells)';
        if ~isempty(negativeRow)
            beta(:, windowIndex) = beta(:, windowIndex) - ...
                W.cellfun(@(x)x.coef_factors_terms( ...
                negativeRow, windowIndex), anova.cells)';
        end
    end
end

function axesUnit = normalizeColumns(beta)
%NORMALIZECOLUMNS Normalize every time-specific population axis.
    axisNorms = vecnorm(beta, 2, 1);
    assert(all(isfinite(axisNorms) & axisNorms > 0), ...
        'Every coding axis must have a finite nonzero norm.');
    axesUnit = beta ./ axisNorms;
end