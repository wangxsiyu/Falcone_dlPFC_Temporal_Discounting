function codingaxes = coding_dimension_value_motor(cue_or_go, savename, timewindows, varargin)
    if exist(fullfile('../../TempData', savename), 'file')
        codingaxes = W.load(fullfile('../../TempData', savename));
        codingaxes = codingaxes.codingaxes;
        return;
    end
    if ~exist("timewindows", 'var') || isempty(timewindows)
        timewindows = {[-250 0],[0 250],[250 500],[500 750],[750 1000]};
    end
    ntimewindow = length(timewindows);
    nAnimal = length(cue_or_go);
    nFactor = 2;
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
                spikes = mean(spikes(:, windowMask), 2);
                factors = W.cellfun_horzcat(@(x)game.(x), factor_names);
                % compute motor for equal trials in ambiguous conditions
                combID = W.tab_getcombinedID(game, {'condition', 'release1'});
                [tc, tid] = W.count_cond(combID);

                % compute value-axis on all trials, after removing the
                % motor effect
                tanv = W.anovan_slidingwindow_singlecell(spikes, factors, 'continuous', 1:nFactor, ...
                    varargin{:});
                betas(celli, windowi, :) = tanv.coef_factors_terms(2:end);
            end
            for fi = 1:nFactor
                betas(:, windowi, fi) = betas(:, windowi, fi)./norm(betas(:, windowi, fi));
            end
        end
        vars = W.arrayfun(@(x)squeeze(betas(:,:, x)), 1:nFactor, false);
        codingaxes{ai} = W.varargin2struct_namesfirst(varnames, vars{:});
    end
    W.save(fullfile('../../TempData', savename), 'codingaxes', codingaxes);
end