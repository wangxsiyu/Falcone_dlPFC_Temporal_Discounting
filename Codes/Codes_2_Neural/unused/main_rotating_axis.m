%% Compute cross-validated rotating coding dimensions
windowEdges = [-250 0; 0 250; 250 500; 500 750; 750 1000];
offerWindowLabels = compose('O %d:%d', windowEdges(:, 1), windowEdges(:, 2));
goWindowLabels = compose('G %d:%d', windowEdges(:, 1), windowEdges(:, 2));
windowLabels = [offerWindowLabels; goWindowLabels];
nEventWindows = size(windowEdges, 1);
nWindows = numel(windowLabels);

animalNames = ["Monkey S", "Monkey T"];
axisNames = ["Value", "Drop", "Delay"];
nAnimals = numel(animalNames);
nAxes = numel(axisNames);

kfold = 2;
minimumTrialsPerCondition = 10;
nPseudoTrialsPerCondition = 100;
factorNames = {'drop', 'delay', 'choice'};
valueFactorNames = {'DV_overall'};
randomSeed = 7;
rng(randomSeed, 'twister');

rotatingAxes = W.struct( ...
    'window_edges', windowEdges, ...
    'window_labels', windowLabels, ...
    'axis_names', axisNames, ...
    'coefficient_method', ...
    'W.anovan_slidingwindow on window-averaged activity', ...
    'value_model', 'firing rate ~ 1 + DV_overall', ...
    'drop_delay_model', ...
    'firing rate ~ 1 + drop + delay + choice', ...
    'is_crossvalidated', true, ...
    'kfold', kfold, ...
    'n_pseudotrials_per_condition', nPseudoTrialsPerCondition, ...
    'random_seed', randomSeed, ...
    'animals', repmat(struct, nAnimals, 1));

for animalIndex = 1:nAnimals
    [d, timeMasks] = combineOfferAndGo( ...
        cue{animalIndex}, go{animalIndex}, windowEdges);
    d = W.combinedcells_removeNAtrials(d);

    nmin = W.cellfun(@(x) ...
        min(W.count_cond(x.condition, 1:9)), d.games);
    idx = find(nmin >= minimumTrialsPerCondition);
    idcell = ismember(d.info_cells.gameID, idx);
    d.info_cells = d.info_cells(idcell, :);
    d.cells = d.cells(idcell);
    assert(~isempty(d.cells), ...
        'No cells have enough trials in every condition.');

    [tr0, te0] = W.combinedcells_kfoldtrials_bycond( ...
        d, kfold, 'condition');
    W.print('loop %d', animalIndex);
    W.print_mute_on;

    % With two folds, tr0{1} and te0{1} are complementary halves.
    tr = W.pseudo_sampletrials_bycond( ...
        tr0{1}, 'condition', nPseudoTrialsPerCondition);
    te = W.pseudo_sampletrials_bycond( ...
        te0{1}, 'condition', nPseudoTrialsPerCondition);

    % Average activity within windows before estimating coefficients.
    tr.cells = W.cellfun(@(x) ...
        averageWithinWindows(x, timeMasks), tr.cells);
    te.cells = W.cellfun(@(x) ...
        averageWithinWindows(x, timeMasks), te.cells);

    tr.time_at = 1:nWindows;
    tr.time_win = repmat(diff(windowEdges, 1, 2)', 1, 2);
    te.time_at = tr.time_at;
    te.time_win = tr.time_win;

    anvDropDelay1 = W.anovan_slidingwindow( ...
        tr, tr.games, factorNames, ...
        'continuous', [1 2], 'is_normalize', false);
    anvDropDelay2 = W.anovan_slidingwindow( ...
        te, te.games, factorNames, ...
        'continuous', [1 2], 'is_normalize', false);
    anvValue1 = W.anovan_slidingwindow( ...
        tr, tr.games, valueFactorNames, ...
        'continuous', 1, 'is_normalize', false);
    anvValue2 = W.anovan_slidingwindow( ...
        te, te.games, valueFactorNames, ...
        'continuous', 1, 'is_normalize', false);
    W.print_mute_off;

    betaValue1 = extractCoefficient(anvValue1, 'DV_overall', nWindows);
    betaValue2 = extractCoefficient(anvValue2, 'DV_overall', nWindows);
    betaDrop1 = extractCoefficient(anvDropDelay1, 'drop', nWindows);
    betaDrop2 = extractCoefficient(anvDropDelay2, 'drop', nWindows);
    betaDelay1 = extractCoefficient(anvDropDelay1, 'delay', nWindows);
    betaDelay2 = extractCoefficient(anvDropDelay2, 'delay', nWindows);

    betaFold1 = permute(cat(3, ...
        betaValue1, betaDrop1, betaDelay1), [1 3 2]);
    betaFold2 = permute(cat(3, ...
        betaValue2, betaDrop2, betaDelay2), [1 3 2]);
    isValid = isfinite(betaFold1) & isfinite(betaFold2);
    betaFold1(~isValid) = nan;
    betaFold2(~isValid) = nan;

    crossValidatedCosine = nan(nAxes, nWindows, nWindows);
    for axisIndex = 1:nAxes
        axisFold1 = squeeze(betaFold1(:, axisIndex, :));
        axisFold2 = squeeze(betaFold2(:, axisIndex, :));
        crossValidatedCosine(axisIndex, :, :) = ...
            crossFoldTemporalCosine(axisFold1, axisFold2);
    end

    reliability = nan(nAxes, nWindows);
    offerAdjacent = nan(nAxes, nEventWindows - 1);
    goAdjacent = nan(size(offerAdjacent));
    goIndices = nEventWindows + (1:nEventWindows);
    for axisIndex = 1:nAxes
        cosine = squeeze(crossValidatedCosine(axisIndex, :, :));
        reliability(axisIndex, :) = diag(cosine)';
        offerAdjacent(axisIndex, :) = ...
            diag(cosine(1:nEventWindows-1, 2:nEventWindows))';
        goAdjacent(axisIndex, :) = diag(cosine( ...
            goIndices(1:end-1), goIndices(2:end)))';
    end

    rotatingAxes.animals(animalIndex).name = animalNames(animalIndex);
    rotatingAxes.animals(animalIndex).info_cells = tr.info_cells;
    rotatingAxes.animals(animalIndex).beta_fold1 = betaFold1;
    rotatingAxes.animals(animalIndex).beta_fold2 = betaFold2;
    rotatingAxes.animals(animalIndex).cosine_cv_mean = crossValidatedCosine;
    rotatingAxes.animals(animalIndex).cosine_cv_sem = [];
    rotatingAxes.animals(animalIndex).split_half_reliability = reliability;
    rotatingAxes.animals(animalIndex).offer_adjacent_cosine = offerAdjacent;
    rotatingAxes.animals(animalIndex).go_adjacent_cosine = goAdjacent;

    fprintf('\n%s\n', animalNames(animalIndex));
    for axisIndex = 1:nAxes
        fprintf(['%s axis reliability\n  Offer: %s\n  GO:    %s\n' ...
            '  Adjacent Offer: %s\n  Adjacent GO:    %s\n'], ...
            axisNames(axisIndex), ...
            mat2str(reliability(axisIndex, 1:nEventWindows), 3), ...
            mat2str(reliability(axisIndex, goIndices), 3), ...
            mat2str(offerAdjacent(axisIndex, :), 3), ...
            mat2str(goAdjacent(axisIndex, :), 3));
    end
end

W.save('../../TempData/rotating_axes', ...
    'rotatingAxes', rotatingAxes);

%% Figure: split-half cross-validated axis similarity
figureHandle = figure( ...
    'Color', 'w', ...
    'Units', 'pixels', ...
    'Position', [100 50 1350 1300]);
layout = tiledlayout(3, 2, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

nColorLevels = 128;
blue = [0.15 0.32 0.65];
white = [1 1 1];
red = [0.75 0.18 0.18];
colorMap = [ ...
    linspace(blue(1), white(1), nColorLevels)', ...
    linspace(blue(2), white(2), nColorLevels)', ...
    linspace(blue(3), white(3), nColorLevels)'; ...
    linspace(white(1), red(1), nColorLevels)', ...
    linspace(white(2), red(2), nColorLevels)', ...
    linspace(white(3), red(3), nColorLevels)'];

for axisIndex = 1:numel(axisNames)
    for animalIndex = 1:numel(animalNames)
        axesHandle = nexttile;
        cosine = squeeze(rotatingAxes.animals( ...
            animalIndex).cosine_cv_mean(axisIndex, :, :));
        imagesc(axesHandle, cosine, [-1 1]);
        axis(axesHandle, 'square');
        hold(axesHandle, 'on');
        xline(axesHandle, 5.5, 'k-', 'LineWidth', 1.25);
        yline(axesHandle, 5.5, 'k-', 'LineWidth', 1.25);
        xticks(axesHandle, 1:numel(windowLabels));
        yticks(axesHandle, 1:numel(windowLabels));
        xticklabels(axesHandle, windowLabels);
        yticklabels(axesHandle, windowLabels);
        xtickangle(axesHandle, 45);
        axesHandle.FontSize = 9;
        title(axesHandle, sprintf('%s: %s axis', ...
            animalNames(animalIndex), axisNames(axisIndex)));
        xlabel(axesHandle, 'Coding axis at time window');
        ylabel(axesHandle, 'Coding axis at time window');
    end
end

colormap(figureHandle, colorMap);
colorBar = colorbar;
colorBar.Layout.Tile = 'east';
colorBar.Label.String = 'Cross-validated cosine similarity';
title(layout, 'Temporal stability of population coding axes', ...
    'FontWeight', 'bold');

figureFolder = fullfile('..', '..', 'Figures');
if ~isfolder(figureFolder)
    mkdir(figureFolder);
end
figureBaseName = fullfile(figureFolder, 'Rotating coding axes');
exportgraphics(figureHandle, figureBaseName + ".jpg", ...
    'Resolution', 180);
print(figureHandle, figureBaseName + ".svg", '-dsvg');
savefig(figureHandle, figureBaseName + ".fig");



function [d, timeMasks] = combineOfferAndGo( ...
        cueData, goData, windowEdges)
%COMBINEOFFERANDGO Join aligned trials before condition-stratified CV.
    assert(isequal(cueData.info_cells(:, {'animal', 'gameID'}), ...
        goData.info_cells(:, {'animal', 'gameID'})), ...
        'Offer- and GO-locked neurons must have identical ordering.');
    assert(numel(cueData.cells) == numel(goData.cells), ...
        'Offer- and GO-locked data must contain the same neurons.');

    d = cueData;
    nCueTimes = numel(cueData.time_at);
    nGoTimes = numel(goData.time_at);
    d.cells = cellfun(@(offer, goSignal)[offer, goSignal], ...
        cueData.cells, goData.cells, 'UniformOutput', false);
    d.time_at = 1:(nCueTimes + nGoTimes);
    d.time_win = ones(size(d.time_at));

    cueMasks = makeTimeMasks(cueData.time_at, windowEdges);
    goMasks = makeTimeMasks(goData.time_at, windowEdges);
    timeMasks = cell(1, numel(cueMasks) + numel(goMasks));
    for windowIndex = 1:numel(cueMasks)
        timeMasks{windowIndex} = [ ...
            cueMasks{windowIndex}, false(1, nGoTimes)];
        timeMasks{numel(cueMasks) + windowIndex} = [ ...
            false(1, nCueTimes), goMasks{windowIndex}];
    end
end


function timeMasks = makeTimeMasks(timePoints, windowEdges)
%MAKETIMEMASKS Create nonoverlapping time-window masks.
    nWindows = size(windowEdges, 1);
    timeMasks = cell(1, nWindows);
    for windowIndex = 1:nWindows
        timeMasks{windowIndex} = ...
            timePoints > windowEdges(windowIndex, 1) & ...
            timePoints < windowEdges(windowIndex, 2);
        assert(any(timeMasks{windowIndex}), ...
            'Every coding window must contain time samples.');
    end
end


function coefficients = averageWithinWindows( ...
        timeResolvedActivity, timeMasks)
%AVERAGEWITHINWINDOWS Average population activity within each window.
    nWindows = numel(timeMasks);
    coefficients = nan(size(timeResolvedActivity, 1), nWindows);
    for windowIndex = 1:nWindows
        coefficients(:, windowIndex) = mean( ...
            timeResolvedActivity(:, timeMasks{windowIndex}), ...
            2, 'omitnan');
    end
end


function beta = extractCoefficient(anova, factorName, nWindows)
%EXTRACTCOEFFICIENT Collect one coefficient across cells and windows.
    coefficientNames = string(anova.cells{1}.name_factors_terms);
    coefficientRow = find(coefficientNames == string(factorName));
    assert(isscalar(coefficientRow), ...
        'The requested coefficient row must be unique.');
    nCells = numel(anova.cells);
    beta = nan(nCells, nWindows);
    for windowIndex = 1:nWindows
        beta(:, windowIndex) = W.cellfun(@(x) ...
            x.coef_factors_terms(coefficientRow, windowIndex), ...
            anova.cells)';
    end
end


function cosine = crossFoldTemporalCosine(beta1, beta2)
%CROSSFOLDTEMPORALCOSINE Average the two cross-fold comparisons.
    nWindows = size(beta1, 2);
    cosine = nan(nWindows, nWindows);
    for firstWindow = 1:nWindows
        for secondWindow = 1:nWindows
            isValid = isfinite(beta1(:, firstWindow)) & ...
                isfinite(beta2(:, firstWindow)) & ...
                isfinite(beta1(:, secondWindow)) & ...
                isfinite(beta2(:, secondWindow));
            cosine12 = cosineSimilarity( ...
                beta1(isValid, firstWindow), ...
                beta2(isValid, secondWindow));
            cosine21 = cosineSimilarity( ...
                beta2(isValid, firstWindow), ...
                beta1(isValid, secondWindow));
            cosine(firstWindow, secondWindow) = ...
                mean([cosine12, cosine21]);
        end
    end
end


function similarity = cosineSimilarity(x, y)
%COSINESIMILARITY Compute the raw cosine between two vectors.
    denominator = norm(x)*norm(y);
    if denominator == 0
        similarity = nan;
    else
        similarity = dot(x, y)/denominator;
    end
end
