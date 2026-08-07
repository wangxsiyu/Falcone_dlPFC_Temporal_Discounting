function projections = projection_to_axes(codingaxes, cue_or_go, savename, trialoptions, baselinewindow, windowbins)
    if ~exist('baselinewindow', 'var') || isempty(baselinewindow)
        baselinewindow = [];
    end
    if ~exist('windowbins', 'var') || isempty(windowbins)
        windowbins = [];
    end
    if ~exist('trialoptions', 'var') || isempty(trialoptions)
        trialoptions = { ...
            'YP', 'motor'};
    end
    trialoptions = cellstr(string(trialoptions));
    projections = cell(1, 2);
    axisnames = setdiff(W.fieldnames(codingaxes{1}),{'cue_or_go_name', 'timewindows'});
    naxes = length(axisnames);
    for ai = 1:2
        alld = cue_or_go{ai};
        time_at = alld.time_at;
        if ~isempty(baselinewindow)
            idxbase = time_at > baselinewindow(1) & time_at < baselinewindow(2);
            extractbase = @(spks)mean(spks(:, idxbase), 2);
        else
            extractbase = @(x)0;
        end

        if ~isempty(windowbins)
            idxbins = W.cellfun(@(t) time_at > t(1) & time_at < t(2), windowbins);
            extractwin = @(spks)W.cellfun_horzcat(@(t)mean(spks(:, t), 2), idxbins);
            nTime = length(windowbins);
        else
            extractwin = @(x)x;
            nTime = length(time_at);
        end
        tprojstruct = struct;
        tprojstruct.trialoptions = trialoptions;
        tprojstruct.axes = axisnames;
        tprojstruct.vals = cell(length(trialoptions), naxes);
        tprojstruct.time_at = time_at;
        nCells = numel(alld.cells);

        for toi = 1:length(trialoptions)
            trialIndicesByGame = cell(size(alld.games));
            usedGameIDs = unique(alld.info_cells.gameID);
            for gamei = reshape(usedGameIDs, 1, [])
                trialIndicesByGame{gamei} = get_selected_trials( ...
                    alld.games{gamei}, trialoptions{toi}, ai);
            end
            trajs = cell(1, nCells);
            for celli = 1:nCells
                spikes = alld.cells{celli};
                spkn = extractwin(spikes) - extractbase(spikes);
                gameID = alld.info_cells.gameID(celli);
                trialIndices = trialIndicesByGame{gameID};
                if isempty(trajs)
                    trajs = nan([nCells, size(trialIndices) nTime]);
                end
                
                ttrajs = cell(size(trialIndices));
                for triali = 1:numel(trialIndices)
                    selectedTrials = trialIndices{triali};
                    if isempty(selectedTrials)
                        ttrajs{triali} = nan(1, size(spkn, 2));
                    else
                        ttrajs{triali} = mean(spkn(selectedTrials, :), 1);
                    end
                end
                trajs{celli} = cellarray2array(ttrajs);
            end
            trajs = cellarray2array(trajs);
            for axi = 1:naxes
                axisname = axisnames(axi);
                cax = codingaxes{ai}.(axisname);
                
                outputsize = size(trajs);
                outputsize(1) = size(cax, 2);
                flatTrajs = reshape(trajs, nCells, []);
                flatProjection = nan(size(cax, 2), size(flatTrajs, 2));
                for windowi = 1:size(cax, 2)
                    axisWeights = cax(:, windowi);
                    valid = isfinite(axisWeights) & isfinite(flatTrajs);
                    weightedTrajs = axisWeights .* flatTrajs;
                    weightedTrajs(~valid) = 0;
                    axisWeights(~isfinite(axisWeights)) = 0;
                    availableAxisNorm = sqrt(sum( ...
                        (axisWeights.^2) .* valid, 1));
                    hasData = availableAxisNorm > 0;
                    flatProjection(windowi, hasData) = ...
                        sum(weightedTrajs(:, hasData), 1) ./ ...
                        availableAxisNorm(hasData);
                end
                tprojection = reshape(flatProjection, outputsize);

                tprojstruct.vals{toi, axi} = tprojection;
            end
        end
        projections{ai} = tprojstruct;
    end
    W.save(fullfile('../../TempData', savename), 'projections', projections);
end

   
