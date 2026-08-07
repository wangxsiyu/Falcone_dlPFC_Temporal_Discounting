function codingaxes = coding_dimension_YP(cue_or_go, cue_or_go_name, timewindows, varargin)
    savename = W.file_prefix(cue_or_go_name, 'axes');
    if exist(fullfile('../../TempData', savename), 'file')
        codingaxes = W.load(fullfile('../../TempData', savename));
        codingaxes = codingaxes.codingaxes;
        return;
    end
    if ~exist("timewindows", 'var') || isempty(timewindows)
        timewindows = {[0 250]};
    end
    varnames = {'YP', 'motor', 'choice'};
    factor_names = {'DV_overall', 'YP', 'release1', 'choice'};
    ntimewindow = length(timewindows);
    nAnimal = length(cue_or_go);
    nFactor = length(varnames);
    codingaxes = cell(1, nAnimal);
    for ai = 1:nAnimal
        alld = cue_or_go{ai};
        time_at = alld.time_at;
        nCells = numel(alld.cells);
        betas = nan(nCells, ntimewindow, nFactor);
        for windowi = 1:ntimewindow
            timewindow = timewindows{windowi};
            windowMask = time_at >= timewindow(1) & ...
                time_at < timewindow(2);
            for celli = 1:nCells
                spikes = alld.cells{celli};
                game = alld.games{alld.info_cells.gameID(celli)};
                game.YP = game.cue1 == "purple";

                % try
                    pa = W.cond_average_tab(game, {'condition','cue1'}, 'choice');
                    pa = pa(ismember(pa.cue1, ["yellow", "purple"]),:);
                    pa = reshape(pa.avCHOICE, 2, []);
                % catch
                %     cuenames = ["yellow", "purple"];
                %     for tcondi = 1:9
                %         for tcuei = 1:2
                %             ttid = game.condition == tcondi & game.cue1 == cuenames(tcuei);
                %             pa(tcondi, tcuei) = mean(ttid);
                %         end
                %     end
                % end

                conds = find(any(pa > 0.2 & pa < 0.8));
                switch ai
                    case 1
                        conds0 = [2 9];
                    case 2
                        conds0 = [2 3 6 9];
                end
                if ~isequal(conds, conds0)
                    W.print('animal %d, cell %d: actual conds', ai, celli);
                    disp(conds);
                end

                if ~isempty(conds)
                    tid = ismember(game.condition, conds);
                    spikes = spikes(tid,:);
                    game = game(tid,:);

                    spikes = mean(spikes(:, windowMask), 2);
                    factors = W.cellfun_horzcat(@(x)game.(x), factor_names);
                    tanv = W.anovan_slidingwindow_singlecell(spikes, factors, 'continuous', 1:4, ...
                        varargin{:});
                    betas(celli, windowi, :) = tanv.coef_factors_terms(end-2:end);
                end
            end
            for fi = 1:nFactor
                te = betas(:, windowi, fi);
                betas(:, windowi, fi) = te./norm(te(~isnan(te)));
            end
        end
        vars = W.arrayfun(@(x)squeeze(betas(:,:, x)), 1:nFactor, false);
        codingaxes{ai} = W.varargin2struct_namesfirst(varnames, vars{:});
        codingaxes{ai}.timewindows = timewindows;
        codingaxes{ai}.cue_or_go_name = cue_or_go_name;
    end
    W.save(fullfile('../../TempData', savename), 'codingaxes', codingaxes);
end