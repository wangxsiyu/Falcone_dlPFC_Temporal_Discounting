yp = W.load('../../TempData/projections_YP_codex');
projections = yp.projections;
axisNames = string(yp.axisNames);

%% Baseline-corrected Yellow/Purple projections
animalNames = string(plt.custom_vars.name_monkeys(1:2));
yellowColor = [0.90 0.65 0.05];
purpleColor = [0.55 0.25 0.72];
analysisConditions = 1:9;
windowIndex = 1; % Axis trained from -250 to 0 ms before GO
nAxes = numel(axisNames);

plt.figure(nAxes, 2, 'is_title', 'all', ...
    'gapW_custom', [0.7 0 1.2]);
for axisIndex = 1:nAxes
    for animalIndex = 1:numel(animalNames)
        projection = projections{axisIndex, animalIndex};
        timeAt = go{animalIndex}.time_at;
        nTimes = numel(timeAt);
        yellowTrajectory = reshape(projection( ...
            windowIndex, analysisConditions, 1, :), ...
            numel(analysisConditions), nTimes);
        purpleTrajectory = reshape(projection( ...
            windowIndex, analysisConditions, 2, :), ...
            numel(analysisConditions), nTimes);

        plt.ax(axisIndex, animalIndex);
        hold on;
        [yellowMean, yellowSem] = W.avse(yellowTrajectory);
        [purpleMean, purpleSem] = W.avse(purpleTrajectory);
        plt.plot(timeAt, yellowMean, yellowSem, ...
            'shade', 'color', yellowColor);
        plt.plot(timeAt, purpleMean, purpleSem, ...
            'shade', 'color', purpleColor);

        [~, pValue] = ttest(yellowTrajectory - purpleTrajectory);
        isSignificant = pValue < 0.05 & ...
            timeAt >= -250 & timeAt <= 1000;
        upperEnvelope = max([ ...
            yellowMean + yellowSem; purpleMean + purpleSem], [], 1);
        plt.dashX(0);
        plt.dashY(0, [-1 1]);
        plt.sigstar(timeAt(isSignificant), ...
            upperEnvelope(isSignificant) + 0.01, ...
            pValue(isSignificant), 'dx', 0);

        if axisIndex == 1
            panelTitle = animalNames(animalIndex);
        else
            panelTitle = "";
        end
        plt.setfig_ax( ...
            'xlim', [-250 1000], ...
            'xtick', -250:250:1000, ...
            'ylabel', sprintf('%s-axis projection', ...
            axisNames(axisIndex)), ...
            'title', panelTitle);
        if axisIndex == nAxes
            plt.setfig_ax('xlabel', ...
                'Time from GO cue onset (ms)');
        end
        if axisIndex == 1 && animalIndex == 2
            plt.setfig_ax('legend', {'Yellow', 'Purple'}, ...
                'legloc', 'SE');
        end
    end
end
plt.addABCs('ABCDEF');
plt.update('YP population projection GO controlled axes');