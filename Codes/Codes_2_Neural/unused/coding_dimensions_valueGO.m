%% Estimate the post-offer Model 1 value-coding axis
trainingWindows = {[-250 0],[0 250],[250 500],[500 750],[750 1000], [850 1100]};
factorNames = {'DV_overall'};
animalNames = ["Monkey S", "Monkey T"];

valueAxis = struct;
valueAxis.settings = W.struct( ...
    'training_lock', 'go signal', ...
    'training_window_ms', trainingWindows, ...
    'value_definition', 'Model 1 DV_overall', ...
    'coefficient_method', ...
    'W.anovan_slidingwindow on condition-averaged activity', ...
    'analysis_level', 'nine condition means per neuron', ...
    'is_crossvalidated', false);
valueAxis.animals = repmat(struct, numel(animalNames), 1);

for animalIndex = 1:numel(animalNames)
    d = go{animalIndex};
    for windowi = 1:length(trainingWindows)
        trainingWindow = trainingWindows{windowi};
        trainingMask = d.time_at >= trainingWindow(1) & ...
            d.time_at < trainingWindow(2);
        assert(any(trainingMask), ...
            'The value-axis training window contains no samples.');

        nCells = numel(d.cells);
        % normalization.mean = nan(nCells, 1);
        % normalization.std = nan(nCells, 1);
        conditionResponses = cell(1, nCells);
        commonConditionInfo = table;

        for cellIndex = 1:nCells
            spikes = d.cells{cellIndex};
            game = d.games{d.info_cells.gameID(cellIndex)};
            assert(size(spikes, 1) == height(game), ...
                'Spike trials and behavioral trials must match.');

            % center = mean(spikes(:, trainingMask), 'all', 'omitnan');
            % scale = std(spikes(:, trainingMask), 0, 'all', 'omitnan');
            % if ~isfinite(scale) || scale <= eps
            %     scale = 1;
            % end
            % normalization.mean(cellIndex) = center;
            % normalization.std(cellIndex) = scale;

            % trialResponse = mean( ...
            %     (spikes(:, trainingMask) - center)/scale, ...
            %     2, 'omitnan');
            trialResponse = spikes(:, trainingMask);
            conditionInfo = unique(game(:, ...
                {'condition', 'DV_overall'}), 'rows');
            conditionInfo = sortrows(conditionInfo, 'condition');
            conditionResponse = arrayfun(@(condition)mean( ...
                trialResponse(game.condition == condition), 'omitnan'), ...
                conditionInfo.condition);

            if cellIndex == 1
                commonConditionInfo = conditionInfo;
            else
                assert(isequal(conditionInfo, commonConditionInfo), ...
                    'All cells from one animal must share condition values.');
            end

            % This archived W wrapper fails during summary-table construction
            % for a one-factor, one-column input. Duplicating the response column
            % runs the identical regression twice; only the first is retained.
            conditionResponses{cellIndex} = ...
                repmat(conditionResponse(:), 1, 2);
        end

        anova = W.anovan_slidingwindow( ...
            conditionResponses, commonConditionInfo, factorNames, ...
            'continuous', 1, 'is_normalize', true);

        coefficientNames = string(anova.cells{1}.name_factors_terms);
        valueRow = find(coefficientNames == "DV_overall");
        assert(isscalar(valueRow), ...
            'The DV_overall coefficient row must be unique.');
        betaValue = W.cellfun(@(x) ...
            x.coef_factors_terms(valueRow, 1), anova.cells)';
        assert(all(isfinite(betaValue)), ...
            'Every cell must yield a finite value coefficient.');

        axisNorm = norm(betaValue);
        assert(isfinite(axisNorm) && axisNorm > 0, ...
            'The value-coding axis must have a finite nonzero norm.');
        % valueAxis.animals(animalIndex).normalization = normalization;
        valueAxis.animals(animalIndex).beta(:, windowi) = betaValue;
        valueAxis.animals(animalIndex).axis_unit(:, windowi) = betaValue/axisNorm;
    end
    valueAxis.animals(animalIndex).name = animalNames(animalIndex);
    valueAxis.animals(animalIndex).info_cells = d.info_cells;
end

W.save('../../TempData/value_axisGO', 'valueAxis', valueAxis);
