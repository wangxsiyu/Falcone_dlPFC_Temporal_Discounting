if ~exist('windowEdges', 'var') || isempty(windowEdges)
    windowEdges = [-250 0; 0 250; 250 500; 500 750; 750 1000];
end
windowLabels = compose('%d to %d ms', ...
    windowEdges(:, 1), windowEdges(:, 2));
nWindows = size(windowEdges, 1);
animalNames = ["Monkey S",    "Monkey T"];
nAnimals = numel(animalNames);

minimumTrialsPerCondition = 10;
kfold = 1;
nPseudoTrialsPerCondition = 100;
factorNames = {'condition', 'release1', 'choice', 'cue1'};
coding = W.struct( ...
    'window_edges', windowEdges, ...
    'window_labels', windowLabels, ...
    'coefficient_method', ...
    'W.anovan_slidingwindow on window-averaged activity', ...
    'is_crossvalidated', false, ...
    'kfold', kfold, ...
    'fold_results', cell(nAnimals, 1));

anv = W.load('../../TempData/anvGO_old_YP');
for ai = 1:2
    ntime = length(anv{ai}.time_at);
    vYP = NaN(length(anv{ai}.cells), ntime);
    for ti = 1:ntime
        vYP(:, ti) = W.cellfun(@(x)x.coef_factors_terms(16,ti), anv{ai}.cells)';
    end
    tid = anv{ai}.time_at > 0 & anv{ai}.time_at < 500;
    betaYP = mean(vYP(:, tid), 2);
    coding.fold_results{ai} = W.struct( ...
        'betaYP', betaYP);
end
% for animalIndex = 1:nAnimals
%     d = go{animalIndex};
%     d = W.combinedcells_removeNAtrials(d);
% 
%     nmin = W.cellfun(@(x) ...
%         min(W.count_cond(x.condition, 1:9)), d.games);
%     idx = find(nmin >= minimumTrialsPerCondition);
%     idcell = ismember(d.info_cells.gameID, idx);
%     d.info_cells = d.info_cells(idcell, :);
%     d.cells = d.cells(idcell);
%     assert(~isempty(d.cells), ...
%         'No cells have enough trials in every condition.');
% 
%     % [tr0, te0] = W.combinedcells_kfoldtrials_bycond( ...
%     %     d, kfold, 'condition');
%     tr0 = {d};
%     te0 = {d};
%     W.print('loop %d', animalIndex);
%     W.print_mute_on;
% 
%     % With two folds, tr0{1} and te0{1} are complementary halves.
%     tr = W.pseudo_sampletrials_bycond( ...
%         tr0{1}, 'condition', nPseudoTrialsPerCondition);
%     te = W.pseudo_sampletrials_bycond( ...
%         te0{1}, 'condition', nPseudoTrialsPerCondition);
% 
%     % Average each trial's activity within each analysis window before
%     % estimating the ANOVA coefficients.
%     timeMasks = makeTimeMasks(d.time_at, windowEdges);
%     tr.cells = W.cellfun(@(x) ...
%         averageWithinWindows(x, timeMasks), tr.cells);
%     te.cells = W.cellfun(@(x) ...
%         averageWithinWindows(x, timeMasks), te.cells);
% 
%     % if isscale
%     %     tr.cells = W.cellfun(@(x) (x - mean(x))./std(x), tr.cells);
%     %     te.cells = W.cellfun(@(x) (x - mean(x))./std(x), te.cells);
%     % end
% 
%     % Keep the time metadata consistent with the five averaged columns.
%     windowCenters = mean(windowEdges, 2)';
%     windowWidths = diff(windowEdges, 1, 2)';
%     tr.time_at = windowCenters;
%     tr.time_win = windowWidths;
%     te.time_at = windowCenters;
%     te.time_win = windowWidths;
%     tg = tr.games;
%     tg.YP = (tg.cue1 == "yellow") + 0;
%     anv1 = W.anovan_slidingwindow( ...
%         tr, tg, factorNames, 'is_normalize', false);
%     % anv2 = W.anovan_slidingwindow( ...
%     %     te, tg, factorNames, ...
%     %     'continuous', [1 2], varargin{:}, 'is_normalize', isscale);
%     W.print_mute_off;
% 
%     ncell = length(tr.cells);
%     % betaValue = nan(ncell, nWindows);
%     betaYP = nan(ncell, nWindows);
%     for windowIndex = 1:nWindows
%         % betaValue(:, windowIndex) = W.cellfun(@(x) ...
%         %     x.coef_factors_terms(2, windowIndex), anv1.cells)';
%         betaYP(:, windowIndex) = W.cellfun(@(x) ...
%             x.coef_factors_terms(14, windowIndex), anv1.cells)';
%     end
% 
%     % Exclude a neuron from a window unless all four fold estimates exist.
%     isValid = isfinite(betaYP);
%     % betaValue(~isValid) = nan;
%     betaYP(~isValid) = nan;
% 
%     coding.fold_results{animalIndex} = W.struct( ...
%         'betaYP', betaYP);
% end
W.save(fullfile('../../TempData/', 'coding_dimensions_YP'), 'coding', coding);

% function timeMasks = makeTimeMasks(timePoints, windowEdges)
% %MAKETIMEMASKS Create nonoverlapping time-window masks.
%     nWindows = size(windowEdges, 1);
%     timeMasks = cell(1, nWindows);
%     for windowIndex = 1:nWindows
%         timeMasks{windowIndex} = ...
%             timePoints > windowEdges(windowIndex, 1) & ...
%             timePoints < windowEdges(windowIndex, 2);
%         assert(any(timeMasks{windowIndex}), ...
%             'Every coding window must contain time samples.');
%     end
% end
% 
% 
% function coefficients = averageWithinWindows( ...
%     timeResolvedCoefficients, timeMasks)
% %AVERAGEWITHINWINDOWS Average time-resolved coefficients in each window.
%     nWindows = numel(timeMasks);
%     coefficients = nan(size(timeResolvedCoefficients, 1), nWindows);
%     for windowIndex = 1:nWindows
%         coefficients(:, windowIndex) = mean( ...
%             timeResolvedCoefficients(:, timeMasks{windowIndex}), ...
%             2, 'omitnan');
%     end
% end
% 
% 
