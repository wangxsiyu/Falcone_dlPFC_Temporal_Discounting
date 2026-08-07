valueAxis = W.load('../../TempData/value_axisGO');
rng(1, 'twister');
baselineWindow = [-250 0];
projections = cell(3,2);
basePs = cell(1,2);
for animalIndex = 1:2
    goData = go{animalIndex};
    gameIDs = unique(goData.info_cells.gameID);
    animalGames = vertcat(goData.games{gameIDs});
    valueResult = valueAxis.animals(animalIndex);
    axesRaw = [valueResult.beta];
    axisNorms = vecnorm(axesRaw, 2, 1);
    axesUnit = axesRaw ./ axisNorms;
    %
    nNeurons = numel(goData.cells);
    nConditions = 9;
    nColors = 2;
    nTimes = numel(goData.time_at);
    trajectories = nan(nNeurons, nConditions, nColors, nTimes);
    trajectories_controlchoice = nan(nNeurons, nColors, nTimes);
    trajectories_choice = nan(nNeurons, 2, nTimes);
    trajectories_motor = nan(nNeurons, 2, nTimes);
    basetrajectories = nan(nNeurons, nConditions, nColors, 5);
    baselineMask = goData.time_at >= baselineWindow(1) & ...
        goData.time_at < baselineWindow(2);
    for neuronIndex = 1:nNeurons
        spikes = goData.cells{neuronIndex};
        game = goData.games{goData.info_cells.gameID(neuronIndex)};
        
        trialMasks_choice = get_balanced_trials(game, 'choice');
        for choicei = 1:2
            trialMask = trialMasks_choice{choicei};
            if numel(trialMask) < 10
                trajectory0 = nan(1, nTimes);
            else
                trajectory0 = mean(spikes(trialMask, :), 1, 'omitnan');
            end
            baseT =  mean(trajectory0(baselineMask), 'omitnan');
            trajectory = trajectory0 - baseT;
            trajectories_choice(neuronIndex, choicei, :) = trajectory;
        end

        trialMasks_motor = get_balanced_trials(game, 'motor');
        for choicei = 1:2
            trialMask = trialMasks_motor{choicei};
            if numel(trialMask) < 10
                trajectory0 = nan(1, nTimes);
            else
                trajectory0 = mean(spikes(trialMask, :), 1, 'omitnan');
            end
            baseT =  mean(trajectory0(baselineMask), 'omitnan');
            trajectory = trajectory0 - baseT;
            trajectories_motor(neuronIndex, choicei, :) = trajectory;
        end

        % trialMasks_motor = get_balanced_trials(game, 'condition_by_motor');
        % conditionMotorTrajectories = nan(nConditions, 2, nTimes);
        % for condition = 1:nConditions
        %     for motori = 1:2
        %         trialMask = trialMasks_motor{condition, motori};
        %         if numel(trialMask) <= 5
        %             trajectory0 = nan(1, nTimes);
        %         else
        %             trajectory0 = mean(spikes(trialMask, :), 1, 'omitnan');
        %         end
        %         baseT =  mean(trajectory0(baselineMask), 'omitnan');
        %         trajectory = trajectory0 - baseT;
        %         conditionMotorTrajectories(condition, motori, :) = trajectory;
        %     end
        % end
        % trajectories_motor(neuronIndex, :, :) = ...
        %     mean(conditionMotorTrajectories, 1, 'omitnan');

        trialMasks_CondYP = get_balanced_trials(game, 'allYP');
        for condition = 1:nConditions
            for colorIndex = 1:nColors
                trialMask = trialMasks_CondYP{condition, colorIndex};
                if numel(trialMask) < 10
                    trajectory0 = nan(1, nTimes);
                else
                    trajectory0 = mean(spikes(trialMask, :), 1, 'omitnan');
                end
                baseT =  mean(trajectory0(baselineMask), 'omitnan');
                trajectory = trajectory0 - baseT;
                trajectories(neuronIndex, condition, ...
                    colorIndex, :) = trajectory;
                basetrajectories(neuronIndex, condition, ...
                    colorIndex, 1) = baseT;
                for wi = 2:5
                    tbaselineMask = goData.time_at >= baselineWindow(1) + 250 * (wi-1) & ...
                        goData.time_at < baselineWindow(2) + 250 * (wi-1);
                    basetrajectories(neuronIndex, condition, ...
                        colorIndex, wi) = mean(trajectory0(tbaselineMask), 'omitnan');
                end
            end
        end

        trialMasks_CondYP = get_balanced_trials(game, 'matching_choice');
        for colorIndex = 1:nColors
            trialMask = trialMasks_CondYP{colorIndex};
            if numel(trialMask) < 10
                trajectory0 = nan(1, nTimes);
            else
                trajectory0 = mean(spikes(trialMask, :), 1, 'omitnan');
            end
            baseT =  mean(trajectory0(baselineMask), 'omitnan');
            trajectory = trajectory0 - baseT;
            trajectories_controlchoice(neuronIndex, ...
                colorIndex, :) = trajectory;
        end
    end
    projection = reshape(axesUnit' * ...
        reshape(trajectories, ...
        nNeurons, []), ...
        [], nConditions, nColors, nTimes);

    % Exclude cells with missing control-choice activity from both colors.
    nanCells = any(reshape(isnan(trajectories_controlchoice), ...
        nNeurons, []), 2);
    trajectories_controlchoice(isnan(trajectories_controlchoice)) = 0;
    axesUnit_controlchoice = axesUnit;
    axesUnit_controlchoice(nanCells, :) = 0;
    % controlAxisNorms = vecnorm(axesUnit_controlchoice, 2, 1);
    % nonzeroAxes = controlAxisNorms > 0;
    % axesUnit_controlchoice(:, nonzeroAxes) = ...
    %     axesUnit_controlchoice(:, nonzeroAxes) ./ ...
    %     controlAxisNorms(nonzeroAxes);
    projection_controlchoice = reshape(axesUnit_controlchoice' * ...
        reshape(trajectories_controlchoice, ...
        nNeurons, []), ...
        [], nColors, nTimes);

    projection_choice = reshape(axesUnit' * ...
        reshape(trajectories_choice, ...
        nNeurons, []), ...
        [], 2, nTimes);
    projection_motor = reshape(axesUnit' * ...
        reshape(trajectories_motor, ...
        nNeurons, []), ...
        [], 2, nTimes);
    baseprojection = reshape(axesUnit' * ...
        reshape(basetrajectories, ...
        nNeurons, []), ...
        [], nConditions, nColors, 5);
    projections{1, animalIndex} = projection;
    projections{2, animalIndex} = projection_choice;
    projections{3, animalIndex} = projection_motor;
    projections{4, animalIndex} = projection_controlchoice;
    basePs{animalIndex} = baseprojection;
end
W.save("../../TempData/projections_YP.m", 'projections', projections, ...
    'basePs', basePs);