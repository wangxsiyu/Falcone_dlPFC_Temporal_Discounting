function trialIndices = get_balanced_trials(game, version)
%GET_BALANCED_TRIALS Sample equal group sizes separately within each cue.
    nConditions = 9;
    nLevels = 2;
    version = string(version);

    switch version
        case {"choice", "motor"}
            trialIndices = cell(1, nLevels);
            trialIndices(:) = {zeros(0, 1)};
            if version == "choice"
                groupingVariable = game.choice;
            else
                groupingVariable = game.release1;
            end
            isYellow = game.cue1 == "yellow";
            isPurple = game.cue1 == "purple";

            for condition = 1:nConditions
                for levelIndex = 1:nLevels
                    level = levelIndex - 1;
                    colorIndices = { ...
                        find(game.condition == condition & ...
                        groupingVariable == level & isYellow), ...
                        find(game.condition == condition & ...
                        groupingVariable == level & isPurple)};
                    nKeep = min(cellfun(@numel, colorIndices));
                    if nKeep == 0
                        continue;
                    end
                    for colorIndex = 1:nLevels
                        available = colorIndices{colorIndex};
                        selected = available( ...
                            randperm(numel(available), nKeep));
                        trialIndices{levelIndex} = [ ...
                            trialIndices{levelIndex}; selected(:)];
                    end
                end
            end
            assert(all(cellfun(@(x)~isempty(x), trialIndices)), ...
                'No color-balanced trials remain for one of the requested levels.');

        case "condition_by_motor"
            trialIndices = cell(nConditions, nLevels);
            isYellow = game.cue1 == "yellow";
            isPurple = game.cue1 == "purple";
            for condition = 1:nConditions
                for motorIndex = 1:nLevels
                    motorLevel = motorIndex - 1;
                    colorIndices = { ...
                        find(game.condition == condition & ...
                        game.release1 == motorLevel & isYellow), ...
                        find(game.condition == condition & ...
                        game.release1 == motorLevel & isPurple)};
                    nKeep = min(cellfun(@numel, colorIndices));
                    if nKeep == 0
                        trialIndices{condition, motorIndex} = zeros(0, 1);
                        continue;
                    end
                    selected = cell(1, nLevels);
                    for colorIndex = 1:nLevels
                        available = colorIndices{colorIndex};
                        selected{colorIndex} = available( ...
                            randperm(numel(available), nKeep));
                    end
                    trialIndices{condition, motorIndex} = ...
                        vertcat(selected{:});
                end
            end

        case "allYP"
            trialIndices = cell(nConditions, nLevels);
            isYellow = game.cue1 == "yellow";
            isPurple = game.cue1 == "purple";
            for condition = 1:nConditions
                trialIndices{condition, 1} = find( ...
                    game.condition == condition & isYellow);
                trialIndices{condition, 2} = find( ...
                    game.condition == condition & isPurple);
            end

        case "matching_choice"
            trialIndices = cell(1, nLevels);
            trialIndices(:) = {zeros(0, 1)};
            isColor = {game.cue1 == "yellow", game.cue1 == "purple"};
            for condition = 1:nConditions
                for colorIndex = 1:nLevels
                    choiceIndices = { ...
                        find(game.condition == condition & ...
                        isColor{colorIndex} & game.choice == 0), ...
                        find(game.condition == condition & ...
                        isColor{colorIndex} & game.choice == 1)};
                    nKeep = min(cellfun(@numel, choiceIndices));
                    if nKeep == 0
                        continue;
                    end
                    for choiceIndex = 1:nLevels
                        available = choiceIndices{choiceIndex};
                        selected = available( ...
                            randperm(numel(available), nKeep));
                        trialIndices{colorIndex} = [ ...
                            trialIndices{colorIndex}; selected(:)];
                    end
                end
            end
            assert(all(cellfun(@(x)~isempty(x), trialIndices)), ...
                'No choice-matched trials remain for one of the colors.');

        case {"condition_by_YP", "YP"}
            trialIndices = cell(nConditions, nLevels);
            isYellow = game.cue1 == "yellow";
            isPurple = game.cue1 == "purple";
            for condition = 1:nConditions
                colorIndices = { ...
                    find(game.condition == condition & isYellow), ...
                    find(game.condition == condition & isPurple)};
                nKeep = min(cellfun(@numel, colorIndices));
                if nKeep == 0
                    trialIndices(condition, :) = {zeros(0, 1)};
                    continue;
                end
                for colorIndex = 1:nLevels
                    available = colorIndices{colorIndex};
                    selected = available(randperm(numel(available), nKeep));
                    trialIndices{condition, colorIndex} = selected(:);
                end
            end

        otherwise
            error('get_balanced_trials:UnknownVersion', ...
                'Unknown balancing version: %s.', version);
    end
end