function trialIndices = get_selected_trials(game, version, animal)
    nConditions = 9;
    nLevels = 2;
    minimumTrials = 20;
    version = char(version);
    switch version
        case 'YP'
            trialIndices = cell(nConditions, nLevels);
            isYellow = game.cue1 == "yellow";
            isPurple = game.cue1 == "purple";
            iderr = game.is_post_error;
            for condition = 1:nConditions
                trialIndices{condition, 1} = find( ...
                    game.condition == condition & isYellow & ~iderr);
                trialIndices{condition, 2} = find( ...
                    game.condition == condition & isPurple & ~iderr);
            end
        case 'YP_amb'
            switch animal 
                case 1 
                    conds = [2, 9];
                case 2
                    conds = [2, 3, 6, 9];
            end
            trialIndices = cell(length(conds), nLevels);
            isYellow = game.cue1 == "yellow";
            isPurple = game.cue1 == "purple";
            iderr = game.is_post_error;
            for condition = 1:length(conds)
                trialIndices{condition, 1} = find( ...
                    game.condition == condition & isYellow & ~iderr);
                trialIndices{condition, 2} = find( ...
                    game.condition == condition & isPurple & ~iderr);
            end
        case 'motor'
            trialIndices = cell(nConditions, nLevels);
            isHold = game.release1 == 0;
            isRelease = game.release1 == 1;
            iderr = game.is_post_error;
            for condition = 1:nConditions
                trialIndices{condition, 1} = find( ...
                    game.condition == condition & isHold & ~iderr);
                trialIndices{condition, 2} = find( ...
                    game.condition == condition & isRelease & ~iderr);
            end
        case 'motor_amb'
            switch animal 
                case 1 
                    conds = [2, 9];
                case 2
                    conds = [2, 3, 6, 9];
            end
            trialIndices = cell(length(conds), nLevels);
            isHold = game.release1 == 0;
            isRelease = game.release1 == 1;
            iderr = game.is_post_error;
            for condition = 1:length(conds)
                trialIndices{condition, 1} = find( ...
                    game.condition == condition & isHold & ~iderr);
                trialIndices{condition, 2} = find( ...
                    game.condition == condition & isRelease & ~iderr);
            end
        % case 'motor_x_YP'
        %     trialIndices = cell(nConditions, 4);
        %     isYellow = game.cue1 == "yellow";
        %     isPurple = game.cue1 == "purple";
        %     isHold = game.release1 == 0;
        %     isRelease = game.release1 == 1;
        %     for condition = 1:nConditions
        %         trialIndices{condition, 1} = find( ...
        %             game.condition == condition & isHold & isYellow);
        %         trialIndices{condition, 2} = find( ...
        %             game.condition == condition & isHold & isPurple);
        %         trialIndices{condition, 3} = find( ...
        %             game.condition == condition & isRelease & isYellow);
        %         trialIndices{condition, 4} = find( ...
        %             game.condition == condition & isRelease & isPurple);
        %     end
        % case 'motor_controlYP'
        %     % Output: condition x [hold, release]. Yellow- and
        %     % purple-first trials are matched within each output group.
        %     trialIndices = cell(nConditions, nLevels);
        %     isYellow = game.cue1 == "yellow";
        %     isPurple = game.cue1 == "purple";
        %     for condition = 1:nConditions
        %         for motorIndex = 1:nLevels
        %             motorLevel = motorIndex - 1;
        %             motorMask = game.release1 == motorLevel;
        %             yellowIndices = find(game.condition == condition & ...
        %                 motorMask & isYellow);
        %             purpleIndices = find(game.condition == condition & ...
        %                 motorMask & isPurple);
        %             trialIndices{condition, motorIndex} = ...
        %                 match_and_combine(yellowIndices, purpleIndices, ...
        %                 minimumTrials);
        %         end
        %     end
        % case 'YP_controlMotor'
        %     % Output: condition x [yellow, purple]. Hold and release
        %     % trials are matched within each output group.
        %     trialIndices = cell(nConditions, nLevels);
        %     cueMasks = {game.cue1 == "yellow", game.cue1 == "purple"};
        %     for condition = 1:nConditions
        %         for colorIndex = 1:nLevels
        %             conditionColorMask = game.condition == condition & ...
        %                 cueMasks{colorIndex};
        %             holdIndices = find(conditionColorMask & ...
        %                 game.release1 == 0);
        %             releaseIndices = find(conditionColorMask & ...
        %                 game.release1 == 1);
        %             trialIndices{condition, colorIndex} = ...
        %                 match_and_combine(holdIndices, releaseIndices, ...
        %                 minimumTrials);
        %         end
        %     end
        otherwise
            error('get_selected_trials:UnknownVersion', ...
                'Unknown trial-selection option: %s.', version);
    end
end

function selectedIndices = match_and_combine(firstIndices, secondIndices, ...
        minimumTrials)
    nKeep = min(numel(firstIndices), numel(secondIndices));
    if 2*nKeep < minimumTrials
        selectedIndices = zeros(0, 1);
        return;
    end

    firstIndices = firstIndices(randperm(numel(firstIndices), nKeep));
    secondIndices = secondIndices(randperm(numel(secondIndices), nKeep));
    selectedIndices = [firstIndices(:); secondIndices(:)];
end

        % case 'YP_amb'
        %     % pa = W.cond_average_tab(game, 'condition', 'choice');
        %     % pa = pa.avCHOICE;
        %     switch animal 
        %         case 1
        %             id = [2, 10];
        %         case 2
        %             id = [2, 6]
        %     end
    % 
    % switch version
    %     case {"choice", "motor"}
    %         trialIndices = cell(1, nLevels);
    %         trialIndices(:) = {zeros(0, 1)};
    %         if version == "choice"
    %             groupingVariable = game.choice;
    %         else
    %             groupingVariable = game.release1;
    %         end
    %         isYellow = game.cue1 == "yellow";
    %         isPurple = game.cue1 == "purple";
    % 
    %         for condition = 1:nConditions
    %             for levelIndex = 1:nLevels
    %                 level = levelIndex - 1;
    %                 colorIndices = { ...
    %                     find(game.condition == condition & ...
    %                     groupingVariable == level & isYellow), ...
    %                     find(game.condition == condition & ...
    %                     groupingVariable == level & isPurple)};
    %                 nKeep = min(cellfun(@numel, colorIndices));
    %                 if nKeep == 0
    %                     continue;
    %                 end
    %                 for colorIndex = 1:nLevels
    %                     available = colorIndices{colorIndex};
    %                     selected = available( ...
    %                         randperm(numel(available), nKeep));
    %                     trialIndices{levelIndex} = [ ...
    %                         trialIndices{levelIndex}; selected(:)];
    %                 end
    %             end
    %         end
    %         assert(all(cellfun(@(x)~isempty(x), trialIndices)), ...
    %             'No color-balanced trials remain for one of the requested levels.');
    % 
    %     case "condition_by_motor"
    %         trialIndices = cell(nConditions, nLevels);
    %         isYellow = game.cue1 == "yellow";
    %         isPurple = game.cue1 == "purple";
    %         for condition = 1:nConditions
    %             for motorIndex = 1:nLevels
    %                 motorLevel = motorIndex - 1;
    %                 colorIndices = { ...
    %                     find(game.condition == condition & ...
    %                     game.release1 == motorLevel & isYellow), ...
    %                     find(game.condition == condition & ...
    %                     game.release1 == motorLevel & isPurple)};
    %                 nKeep = min(cellfun(@numel, colorIndices));
    %                 if nKeep == 0
    %                     trialIndices{condition, motorIndex} = zeros(0, 1);
    %                     continue;
    %                 end
    %                 selected = cell(1, nLevels);
    %                 for colorIndex = 1:nLevels
    %                     available = colorIndices{colorIndex};
    %                     selected{colorIndex} = available( ...
    %                         randperm(numel(available), nKeep));
    %                 end
    %                 trialIndices{condition, motorIndex} = ...
    %                     vertcat(selected{:});
    %             end
    %         end
    % 
    % 
    %     case "matching_choice"
    %         trialIndices = cell(1, nLevels);
    %         trialIndices(:) = {zeros(0, 1)};
    %         isColor = {game.cue1 == "yellow", game.cue1 == "purple"};
    %         for condition = 1:nConditions
    %             for colorIndex = 1:nLevels
    %                 choiceIndices = { ...
    %                     find(game.condition == condition & ...
    %                     isColor{colorIndex} & game.choice == 0), ...
    %                     find(game.condition == condition & ...
    %                     isColor{colorIndex} & game.choice == 1)};
    %                 nKeep = min(cellfun(@numel, choiceIndices));
    %                 if nKeep == 0
    %                     continue;
    %                 end
    %                 for choiceIndex = 1:nLevels
    %                     available = choiceIndices{choiceIndex};
    %                     selected = available( ...
    %                         randperm(numel(available), nKeep));
    %                     trialIndices{colorIndex} = [ ...
    %                         trialIndices{colorIndex}; selected(:)];
    %                 end
    %             end
    %         end
    %         assert(all(cellfun(@(x)~isempty(x), trialIndices)), ...
    %             'No choice-matched trials remain for one of the colors.');
    % 
    %     case {"condition_by_YP", "YP"}
    %         trialIndices = cell(nConditions, nLevels);
    %         isYellow = game.cue1 == "yellow";
    %         isPurple = game.cue1 == "purple";
    %         for condition = 1:nConditions
    %             colorIndices = { ...
    %                 find(game.condition == condition & isYellow), ...
    %                 find(game.condition == condition & isPurple)};
    %             nKeep = min(cellfun(@numel, colorIndices));
    %             if nKeep == 0
    %                 trialIndices(condition, :) = {zeros(0, 1)};
    %                 continue;
    %             end
    %             for colorIndex = 1:nLevels
    %                 available = colorIndices{colorIndex};
    %                 selected = available(randperm(numel(available), nKeep));
    %                 trialIndices{condition, colorIndex} = selected(:);
    %             end
    %         end
    % 
    %     otherwise
    %         error('get_balanced_trials:UnknownVersion', ...
    %             'Unknown balancing version: %s.', version);
    % end
