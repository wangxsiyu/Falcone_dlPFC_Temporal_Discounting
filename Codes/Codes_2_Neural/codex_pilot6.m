%% Explain the Figure_YP purple-minus-yellow difference
% Figure_YP panels A-B pair purple and yellow activity across nine task
% conditions. This script uses the same nine pairs and fits
%
%   PurpleMinusYellowProjection =
%       intercept + bChoice*PurpleMinusYellowChoiceRate + ...
%       bMotor*PurpleMinusYellowRelease1Rate.
%
% Choice and motor enter as main effects only. Relative importance is
% assessed with both drop-one (unique) R-squared and two-predictor
% Shapley/LMG R-squared. The latter shares correlated explanatory variance
% equally across the two possible predictor orderings.

if ~exist("go", "var")
    data = load("../../TempData/data.mat", "go");
    go = data.go;
end

ypData = load("../../TempData/projections_YP.mat", "projections");
projections = ypData.projections;

axisWindowIndex = 1;
analysisWindow = [0 250];
animalNames = ["Monkey S", "Monkey T"];
yellowColor = [0.90 0.65 0.05];
purpleColor = [0.55 0.25 0.72];
choiceColor = [0.15 0.45 0.80];
motorColor = [0.85 0.30 0.20];
unexplainedColor = [0.35 0.35 0.35];

pilot6Results = repmat(struct, 1, numel(animalNames));
summaryRows = cell(0, 26);

figure("Color", "w", ...
    "Name", "Choice and motor explanation of Figure_YP A-B", ...
    "Position", [100 80 1200 780]);
plotLayout = tiledlayout(2, 2, ...
    "TileSpacing", "compact", "Padding", "compact");

for animalIndex = 1:numel(animalNames)
    goData = go{animalIndex};
    timeAt = goData.time_at;
    nTimes = numel(timeAt);

    % The first projection set is the quantity plotted in Figure_YP A-B.
    projection = projections{1, animalIndex};
    projection = reshape( ...
        projection(axisWindowIndex, 1:9, 1:2, :), ...
        9, 2, nTimes);
    purpleMinusYellow = reshape( ...
        projection(:, 2, :) - projection(:, 1, :), 9, nTimes);

    % Pool each animal's unique behavioral sessions, matching the approach
    % used in the related pilot analysis.
    gameIDs = unique(goData.info_cells.gameID);
    animalGame = vertcat(goData.games{gameIDs});
    choiceRates = nan(9, 2);
    motorRates = nan(9, 2);
    for condition = 1:9
        for colorIndex = 1:2
            if colorIndex == 1
                colorMask = animalGame.cue1 == "yellow";
            else
                colorMask = animalGame.cue1 == "purple";
            end
            trialMask = animalGame.condition == condition & colorMask;
            choiceRates(condition, colorIndex) = mean( ...
                animalGame.choice(trialMask), "omitnan");
            motorRates(condition, colorIndex) = mean( ...
                animalGame.release1(trialMask), "omitnan");
        end
    end

    deltaChoice = choiceRates(:, 2) - choiceRates(:, 1);
    deltaMotor = motorRates(:, 2) - motorRates(:, 1);
    validConditions = all(isfinite(purpleMinusYellow), 2) & ...
        isfinite(deltaChoice) & isfinite(deltaMotor);
    nValidConditions = sum(validConditions);
    analysisDifference = purpleMinusYellow(validConditions, :);
    analysisDeltaChoice = deltaChoice(validConditions);
    analysisDeltaMotor = deltaMotor(validConditions);
    design = [ones(nValidConditions, 1), ...
        analysisDeltaChoice, analysisDeltaMotor];
    assert(rank(design) == 3, ...
        "Choice and motor difference design is rank deficient.");

    % Regress all time points together; each column is one OLS outcome.
    coefficients = design \ analysisDifference;
    fitted = design * coefficients;
    residual = analysisDifference - fitted;
    totalSS = sum((analysisDifference - ...
        mean(analysisDifference, 1)).^2, 1);
    residualSS = sum(residual.^2, 1);
    fullR2 = 1 - residualSS ./ totalSS;

    % Single-predictor models provide drop-one and Shapley/LMG R-squared.
    choiceDesign = design(:, 1:2);
    motorDesign = design(:, [1 3]);
    choiceResidual = analysisDifference - ...
        choiceDesign * (choiceDesign \ analysisDifference);
    motorResidual = analysisDifference - ...
        motorDesign * (motorDesign \ analysisDifference);
    choiceOnlyR2 = 1 - sum(choiceResidual.^2, 1) ./ totalSS;
    motorOnlyR2 = 1 - sum(motorResidual.^2, 1) ./ totalSS;
    uniqueChoiceR2 = fullR2 - motorOnlyR2;
    uniqueMotorR2 = fullR2 - choiceOnlyR2;
    shapleyChoiceR2 = 0.5 * ( ...
        choiceOnlyR2 + fullR2 - motorOnlyR2);
    shapleyMotorR2 = 0.5 * ( ...
        motorOnlyR2 + fullR2 - choiceOnlyR2);
    shapleyChoicePercent = 100 * shapleyChoiceR2 ./ fullR2;
    shapleyMotorPercent = 100 * shapleyMotorR2 ./ fullR2;
    invalidR2 = ~isfinite(fullR2) | fullR2 <= eps;
    shapleyChoicePercent(invalidR2) = nan;
    shapleyMotorPercent(invalidR2) = nan;

    % Signed decomposition of the mean purple-minus-yellow gap.
    interceptContribution = coefficients(1, :);
    choiceContribution = coefficients(2, :) * ...
        mean(analysisDeltaChoice);
    motorContribution = coefficients(3, :) * ...
        mean(analysisDeltaMotor);
    meanGap = mean(analysisDifference, 1);
    assert(max(abs(meanGap - interceptContribution - ...
        choiceContribution - motorContribution)) < 1e-10, ...
        "Mean-gap decomposition failed.");

    % The primary numeric result matches Figure_YP panel B: 0-250 ms.
    analysisMask = timeAt > analysisWindow(1) & ...
        timeAt < analysisWindow(2);
    windowDifference = mean( ...
        analysisDifference(:, analysisMask), 2, "omitnan");
    regressionTable = table( ...
        windowDifference(:), analysisDeltaChoice(:), ...
        analysisDeltaMotor(:), ...
        'VariableNames', { ...
        'PurpleMinusYellow', 'ChoiceDifference', 'MotorDifference'});
    fullModel = fitlm(regressionTable, ...
        "PurpleMinusYellow ~ ChoiceDifference + MotorDifference");
    choiceModel = fitlm(regressionTable, ...
        "PurpleMinusYellow ~ ChoiceDifference");
    motorModel = fitlm(regressionTable, ...
        "PurpleMinusYellow ~ MotorDifference");

    windowFullR2 = fullModel.Rsquared.Ordinary;
    windowChoiceOnlyR2 = choiceModel.Rsquared.Ordinary;
    windowMotorOnlyR2 = motorModel.Rsquared.Ordinary;
    windowUniqueChoiceR2 = windowFullR2 - windowMotorOnlyR2;
    windowUniqueMotorR2 = windowFullR2 - windowChoiceOnlyR2;
    windowShapleyChoiceR2 = 0.5 * ( ...
        windowChoiceOnlyR2 + windowUniqueChoiceR2);
    windowShapleyMotorR2 = 0.5 * ( ...
        windowMotorOnlyR2 + windowUniqueMotorR2);

    if windowFullR2 > eps
        windowShapleyChoicePercent = ...
            100 * windowShapleyChoiceR2 / windowFullR2;
        windowShapleyMotorPercent = ...
            100 * windowShapleyMotorR2 / windowFullR2;
    else
        windowShapleyChoicePercent = nan;
        windowShapleyMotorPercent = nan;
    end

    predictorCorrelation = corr(analysisDeltaChoice, analysisDeltaMotor);
    predictorVIF = 1 / (1 - predictorCorrelation^2);
    standardModel = fitlm( ...
        [zscore(analysisDeltaChoice), zscore(analysisDeltaMotor)], ...
        zscore(windowDifference));
    standardBetas = standardModel.Coefficients.Estimate(2:3);
    coefficientCI = coefCI(fullModel);
    modelPValue = coefTest(fullModel);
    windowCoefficients = fullModel.Coefficients.Estimate;
    windowPValues = fullModel.Coefficients.pValue;
    windowChoiceContribution = ...
        windowCoefficients(2) * mean(analysisDeltaChoice);
    windowMotorContribution = ...
        windowCoefficients(3) * mean(analysisDeltaMotor);

    summaryRows(end + 1, :) = { ...
        animalNames(animalIndex), nValidConditions, ...
        predictorCorrelation, predictorVIF, ...
        mean(windowDifference), windowCoefficients(1), ...
        windowCoefficients(2), coefficientCI(2, 1), ...
        coefficientCI(2, 2), windowPValues(2), standardBetas(1), ...
        windowCoefficients(3), coefficientCI(3, 1), ...
        coefficientCI(3, 2), windowPValues(3), standardBetas(2), ...
        windowChoiceContribution, windowMotorContribution, ...
        windowFullR2, fullModel.Rsquared.Adjusted, modelPValue, ...
        windowUniqueChoiceR2, windowUniqueMotorR2, ...
        windowShapleyChoiceR2, windowShapleyChoicePercent, ...
        windowShapleyMotorPercent}; %#ok<SAGROW>

    pilot6Results(animalIndex).animal = animalNames(animalIndex);
    pilot6Results(animalIndex).time_at = timeAt;
    pilot6Results(animalIndex).purple_minus_yellow = ...
        purpleMinusYellow;
    pilot6Results(animalIndex).delta_choice_rate = deltaChoice;
    pilot6Results(animalIndex).delta_motor_rate = deltaMotor;
    pilot6Results(animalIndex).valid_conditions = find(validConditions);
    pilot6Results(animalIndex).coefficients = coefficients;
    pilot6Results(animalIndex).full_R2 = fullR2;
    pilot6Results(animalIndex).unique_choice_R2 = uniqueChoiceR2;
    pilot6Results(animalIndex).unique_motor_R2 = uniqueMotorR2;
    pilot6Results(animalIndex).shapley_choice_R2 = shapleyChoiceR2;
    pilot6Results(animalIndex).shapley_motor_R2 = shapleyMotorR2;
    pilot6Results(animalIndex).shapley_choice_percent = ...
        shapleyChoicePercent;
    pilot6Results(animalIndex).shapley_motor_percent = ...
        shapleyMotorPercent;
    pilot6Results(animalIndex).mean_gap = meanGap;
    pilot6Results(animalIndex).intercept_contribution = ...
        interceptContribution;
    pilot6Results(animalIndex).choice_contribution = ...
        choiceContribution;
    pilot6Results(animalIndex).motor_contribution = ...
        motorContribution;
    pilot6Results(animalIndex).window_model = fullModel;

    % Top row: signed decomposition of the observed mean color gap.
    nexttile(animalIndex);
    hold on;
    plot(timeAt, meanGap, "Color", purpleColor, "LineWidth", 2.2);
    plot(timeAt, interceptContribution, ...
        "Color", unexplainedColor, "LineWidth", 1.6);
    plot(timeAt, choiceContribution, ...
        "Color", choiceColor, "LineWidth", 1.6);
    plot(timeAt, motorContribution, ...
        "Color", motorColor, "LineWidth", 1.6);
    xline(0, "--k");
    yline(0, ":k");
    xlim([-250 1000]);
    title(animalNames(animalIndex));
    xlabel("Time from GO cue onset (ms)");
    ylabel("Purple minus yellow projection");
    box off;
    if animalIndex == 2
        legend({"Observed gap", "Unexplained/intercept", ...
            "Choice contribution", "Motor contribution"}, ...
            "Location", "best", "Box", "off");
    end

    % Bottom row: Shapley division of explained variance.
    nexttile(2 + animalIndex);
    hold on;
    areaHandles = area(timeAt, ...
        [shapleyChoiceR2; shapleyMotorR2]', ...
        "LineStyle", "none");
    areaHandles(1).FaceColor = choiceColor;
    areaHandles(2).FaceColor = motorColor;
    areaHandles(1).FaceAlpha = 0.80;
    areaHandles(2).FaceAlpha = 0.80;
    plot(timeAt, fullR2, "k", "LineWidth", 1.5);
    xline(0, "--k");
    xlim([-250 1000]);
    ylim([0 1]);
    title(sprintf("%s (predictor r = %.2f, VIF = %.1f)", ...
        animalNames(animalIndex), predictorCorrelation, predictorVIF));
    xlabel("Time from GO cue onset (ms)");
    ylabel("Explained variance (R^2)");
    box off;
    if animalIndex == 2
        legend({"Choice Shapley R^2", "Motor Shapley R^2", ...
            "Full model R^2"}, "Location", "best", "Box", "off");
    end
end

title(plotLayout, { ...
    "Figure_YP purple-minus-yellow difference: choice and motor", ...
    "Main-effects-only regression across nine paired conditions"});

pilot6Summary = cell2table(summaryRows, 'VariableNames', { ...
    'Animal', 'NConditions', 'PredictorCorrelation', 'PredictorVIF', ...
    'MeanPurpleMinusYellow', 'Intercept', ...
    'ChoiceBeta', 'ChoiceCI95Low', 'ChoiceCI95High', ...
    'ChoiceP', 'ChoiceStandardizedBeta', ...
    'MotorBeta', 'MotorCI95Low', 'MotorCI95High', ...
    'MotorP', 'MotorStandardizedBeta', ...
    'ChoiceMeanGapContribution', 'MotorMeanGapContribution', ...
    'FullR2', 'AdjustedR2', 'ModelP', ...
    'UniqueChoiceR2', 'UniqueMotorR2', ...
    'ShapleyChoiceR2', 'ShapleyChoicePercent', ...
    'ShapleyMotorPercent'});

disp(pilot6Summary);
writetable(pilot6Summary, "codex_pilot6_summary.csv");
save("codex_pilot6_results.mat", ...
    "pilot6Results", "pilot6Summary", "analysisWindow");

%% Behavioral predictors entered into the regression
% Show all nine behavioral condition pairs, including Monkey S condition 1.
% That condition had a missing neural projection and was therefore absent
% only from the neural regression, not from this behavioral plot.
behaviorFigure = figure("Color", "w", ...
    "Name", "Yellow-purple behavioral predictor differences", ...
    "Position", [150 150 940 430]);
behaviorLayout = tiledlayout(1, 2, ...
    "TileSpacing", "compact", "Padding", "compact");
behaviorPredictors = { ...
    [pilot6Results(1).delta_choice_rate, ...
    pilot6Results(2).delta_choice_rate], ...
    [pilot6Results(1).delta_motor_rate, ...
    pilot6Results(2).delta_motor_rate]};
behaviorTitles = { ...
    "Choice-rate difference", "Release1-rate difference"};
animalPlotColors = [0.15 0.45 0.75; 0.75 0.25 0.20];

for predictorIndex = 1:2
    nexttile;
    hold on;
    predictorValues = behaviorPredictors{predictorIndex};
    for condition = 1:9
        plot(1:2, predictorValues(condition, :), "-", ...
            "Color", [0.72 0.72 0.72], "LineWidth", 0.8);
    end
    scatter(ones(9, 1), predictorValues(:, 1), 42, ...
        animalPlotColors(1, :), "filled", ...
        "MarkerFaceAlpha", 0.75);
    scatter(2 * ones(9, 1), predictorValues(:, 2), 42, ...
        animalPlotColors(2, :), "filled", ...
        "MarkerFaceAlpha", 0.75);
    predictorMeans = mean(predictorValues, 1, "omitnan");
    plot(1:2, predictorMeans, "kd-", ...
        "MarkerFaceColor", "k", "MarkerSize", 8, ...
        "LineWidth", 1.8);
    text(1, predictorMeans(1), sprintf("  mean = %.3f", ...
        predictorMeans(1)), "VerticalAlignment", "bottom");
    text(2, predictorMeans(2), sprintf("mean = %.3f  ", ...
        predictorMeans(2)), "HorizontalAlignment", "right", ...
        "VerticalAlignment", "bottom");
    yline(0, ":k");
    xlim([0.65 2.35]);
    ylim([-1.05 1.12]);
    set(gca, "XTick", 1:2, ...
        "XTickLabel", cellstr(animalNames));
    ylabel("Purple rate minus yellow rate");
    title(behaviorTitles{predictorIndex});
    box off;
end

title(behaviorLayout, { ...
    "Behavioral predictors used for the Y/P regression", ...
    "Lines connect the same task condition; diamonds show 9-condition means"});
exportgraphics(behaviorFigure, ...
    "codex_pilot6_behavioral_deltas.png", "Resolution", 200);
savefig(behaviorFigure, "codex_pilot6_behavioral_deltas.fig");
