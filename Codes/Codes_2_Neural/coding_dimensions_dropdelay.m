function coding_dimensions_dropdelay(cue_or_go, savename, isscale, windowEdges, varargin)
    % rng(seed, 'twister');
    if ~exist('isscale', 'var') || isempty(isscale)
        isscale = true;
    end
    %% Compute cross-validated beta coefficients
    if ~exist('windowEdges', 'var') || isempty(windowEdges)
        windowEdges = [-250 0; 0 250; 250 500; 500 750; 750 1000];
    end
    windowLabels = compose('%d to %d ms', ...
        windowEdges(:, 1), windowEdges(:, 2));
    nWindows = size(windowEdges, 1);
    animalNames = ["Monkey S",    "Monkey T"];
    nAnimals = numel(animalNames);
    
    minimumTrialsPerCondition = 10;
    kfold = 2;
    nPseudoTrialsPerCondition = 100;
    factorNames = {'drop', 'delay', 'choice'};
    coding = W.struct( ...
        'window_edges', windowEdges, ...
        'window_labels', windowLabels, ...
        'coefficient_method', ...
        'W.anovan_slidingwindow on window-averaged activity', ...
        'model', 'firing rate ~ 1 + drop + delay + choice', ...
        'is_crossvalidated', true, ...
        'kfold', kfold, ...
        'beta_drop', cell(nAnimals, 1), ...
        'beta_delay', cell(nAnimals, 1), ...
        'fold_results', cell(nAnimals, 1));
    
    for animalIndex = 1:nAnimals
        d = cue_or_go{animalIndex};
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
    
        % Average each trial's activity within each analysis window before
        % estimating the ANOVA coefficients.
        timeMasks = makeTimeMasks(d.time_at, windowEdges);
        tr.cells = W.cellfun(@(x) ...
            averageWithinWindows(x, timeMasks), tr.cells);
        te.cells = W.cellfun(@(x) ...
            averageWithinWindows(x, timeMasks), te.cells);

        % if isscale
        %     tr.cells = W.cellfun(@(x) (x - mean(x))./std(x), tr.cells);
        %     te.cells = W.cellfun(@(x) (x - mean(x))./std(x), te.cells);
        % end
    
        % Keep the time metadata consistent with the five averaged columns.
        windowCenters = mean(windowEdges, 2)';
        windowWidths = diff(windowEdges, 1, 2)';
        tr.time_at = windowCenters;
        tr.time_win = windowWidths;
        te.time_at = windowCenters;
        te.time_win = windowWidths;
    
        anv1 = W.anovan_slidingwindow( ...
            tr, tr.games, factorNames, ...
            'continuous', [1 2], varargin{:}, 'is_normalize', isscale);
        anv2 = W.anovan_slidingwindow( ...
            te, te.games, factorNames, ...
            'continuous', [1 2], varargin{:}, 'is_normalize', isscale);
        W.print_mute_off;
    
        ncell = length(tr.cells);
        vdrop1 = nan(ncell, nWindows);
        vdelay1 = nan(ncell, nWindows);
        vdrop2 = nan(ncell, nWindows);
        vdelay2 = nan(ncell, nWindows);
        for windowIndex = 1:nWindows
            vdrop1(:, windowIndex) = W.cellfun(@(x) ...
                x.coef_factors_terms(2, windowIndex), anv1.cells)';
            vdelay1(:, windowIndex) = W.cellfun(@(x) ...
                x.coef_factors_terms(3, windowIndex), anv1.cells)';
            vdrop2(:, windowIndex) = W.cellfun(@(x) ...
                x.coef_factors_terms(2, windowIndex), anv2.cells)';
            vdelay2(:, windowIndex) = W.cellfun(@(x) ...
                x.coef_factors_terms(3, windowIndex), anv2.cells)';
        end
    
        betaDrop1 = vdrop1;
        betaDelay1 = vdelay1;
        betaDrop2 = vdrop2;
        betaDelay2 = vdelay2;
    
        % Exclude a neuron from a window unless all four fold estimates exist.
        isValid = isfinite(betaDrop1) & isfinite(betaDelay1) & ...
            isfinite(betaDrop2) & isfinite(betaDelay2);
        betaDrop1(~isValid) = nan;
        betaDelay1(~isValid) = nan;
        betaDrop2(~isValid) = nan;
        betaDelay2(~isValid) = nan;
    
        coding.fold_results{animalIndex} = W.struct( ...
            'vdrop1', vdrop1, ...
            'vdrop2', vdrop2, ...
            'vdelay1', vdelay1, ...
            'vdelay2', vdelay2, ...
            'beta_drop1', betaDrop1, ...
            'beta_drop2', betaDrop2, ...
            'beta_delay1', betaDelay1, ...
            'beta_delay2', betaDelay2);
    
        % Compile the two complementary cross-fold comparisons.
        coding.beta_drop{animalIndex} = [betaDrop1; betaDrop2];
        coding.beta_delay{animalIndex} = [betaDelay2; betaDelay1];
    end
    
    %% Compute statistics
    nPermutations = 10000;
    statistics = table('Size', [nAnimals*nWindows, 8], ...
        'VariableTypes', ["string", repmat("double", 1, 7)], ...
        'VariableNames', {'animal', 'window_start_ms', 'window_end_ms', ...
        'n_neurons', 'pearson_r', 'pearson_p', 'cosine', ...
        'cosine_permutation_p'});
    randomStream = RandStream('mt19937ar', 'Seed', 1);
    
    for animalIndex = 1:nAnimals
        foldResults = coding.fold_results{animalIndex};
        for windowIndex = 1:nWindows
            drop1 = foldResults.beta_drop1(:, windowIndex);
            drop2 = foldResults.beta_drop2(:, windowIndex);
            delay1 = foldResults.beta_delay1(:, windowIndex);
            delay2 = foldResults.beta_delay2(:, windowIndex);
            isValid = isfinite(drop1) & isfinite(drop2) & ...
                isfinite(delay1) & isfinite(delay2);
            drop1 = drop1(isValid);
            drop2 = drop2(isValid);
            delay1 = delay1(isValid);
            delay2 = delay2(isValid);
            assert(numel(drop1) >= 4, ...
                'At least four neurons are required per comparison.');
    
            [pearsonR, cosine] = crossFoldSimilarity( ...
                drop1, drop2, delay1, delay2);
            [pearsonP, cosineP] = crossFoldPermutationP( ...
                drop1, drop2, delay1, delay2, ...
                nPermutations, randomStream);
    
            rowIndex = (animalIndex - 1)*nWindows + windowIndex;
            statistics(rowIndex, :) = {animalNames(animalIndex), ...
                windowEdges(windowIndex, 1), ...
                windowEdges(windowIndex, 2), numel(drop1), ...
                pearsonR, pearsonP, cosine, cosineP};
        end
    end
    
    coding.stats = statistics;
    disp(coding.stats);
    W.save(fullfile('../../TempData/', savename), 'coding', coding);
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
    timeResolvedCoefficients, timeMasks)
%AVERAGEWITHINWINDOWS Average time-resolved coefficients in each window.
    nWindows = numel(timeMasks);
    coefficients = nan(size(timeResolvedCoefficients, 1), nWindows);
    for windowIndex = 1:nWindows
        coefficients(:, windowIndex) = mean( ...
            timeResolvedCoefficients(:, timeMasks{windowIndex}), ...
            2, 'omitnan');
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


function [pearsonR, cosine] = crossFoldSimilarity( ...
    drop1, drop2, delay1, delay2)
%CROSSFOLDSIMILARITY Average the two cross-fold comparisons.
    pearson21 = corr(delay1, drop2);
    pearson12 = corr(delay2, drop1);
    pearsonR = mean([pearson21, pearson12]);

    cosine21 = cosineSimilarity(delay1, drop2);
    cosine12 = cosineSimilarity(delay2, drop1);
    cosine = mean([cosine21, cosine12]);
end


function [pearsonP, cosineP] = crossFoldPermutationP( ...
    drop1, drop2, delay1, delay2, nPermutations, randomStream)
%CROSSFOLDPERMUTATIONP Permute delay neuron labels across both folds.
    [observedPearson, observedCosine] = crossFoldSimilarity( ...
        drop1, drop2, delay1, delay2);

    [~, permutationOrder] = sort(rand( ...
        randomStream, numel(drop1), nPermutations), 1);
    permutedDelay1 = delay1(permutationOrder);
    permutedDelay2 = delay2(permutationOrder);

    pearson21 = columnwiseCorrelation(drop2, permutedDelay1);
    pearson12 = columnwiseCorrelation(drop1, permutedDelay2);
    permutationPearson = mean([pearson21; pearson12], 1);

    cosine21 = (drop2'*permutedDelay1)/ ...
        (norm(drop2)*norm(delay1));
    cosine12 = (drop1'*permutedDelay2)/ ...
        (norm(drop1)*norm(delay2));
    permutationCosine = mean([cosine21; cosine12], 1);

    pearsonP = (1 + sum(abs(permutationPearson) >= ...
        abs(observedPearson)))/(nPermutations + 1);
    cosineP = (1 + sum(abs(permutationCosine) >= ...
        abs(observedCosine)))/(nPermutations + 1);
end

function correlations = columnwiseCorrelation(x, y)
%COLUMNWISECORRELATION Correlate one vector with each column of a matrix.
    centeredX = x - mean(x);
    centeredY = y - mean(y, 1);
    denominator = norm(centeredX)*sqrt(sum(centeredY.^2, 1));
    correlations = (centeredX'*centeredY)./denominator;
end
