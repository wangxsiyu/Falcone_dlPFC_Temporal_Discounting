seaminfo = xlsread('../../lPFC_DATA/MONKEY_S_ARRAY.xlsx');
%% decoding analysis for the two arrays for Seam
kfold = 5;
results = cell(1,2);
d0 = cue{1};
cellIDs = d0.info_cells.cellID;
cells = W.arrayfun(@(x) seaminfo(seaminfo(:, 1) == x, 2), cellIDs);
for ai = 1:2
    d = d0;
    tid = cells <= ai;
    d.cells = d.cells(tid);
    d.info_cells = d.info_cells(tid,:);
    d = W.combinedcells_removeNAtrials(d);
    nmin = W.cellfun(@(x)min(W.count_cond(x.condition,1:9)), d.games);
    idx = find(nmin >= 10);
    idcell = ismember(d.info_cells.gameID, idx);
    d.info_cells = d.info_cells(idcell,:);
    d.cells = d.cells(idcell);

    out = cell(1,kfold);
    parfor i = 1:kfold
        W.print('animal %d, fold %d', ai, i);
        W.print_mute_on;
        [tr0, te0] = W.combinedcells_kfoldtrials_bycond(d, kfold, 'condition');
        tr = W.pseudo_sampletrials_bycond(tr0{i}, 'condition', 80);
        te = W.pseudo_sampletrials_bycond(te0{i}, 'condition', 80);

        m1 = W.neuro_decode_slidingwindow(tr, 'cells', tr.games.delay, 'SVM', 'train', 'SVMfunc', 'discrete');
        r1 = W.neuro_decode_slidingwindow(te, 'cells', te.games.delay, m1.models, 'test', 'SVMfunc', 'discrete');

        m2 = W.neuro_decode_slidingwindow(tr, 'cells', tr.games.drop, 'SVM', 'train', 'SVMfunc', 'discrete');
        r2 = W.neuro_decode_slidingwindow(te, 'cells', te.games.drop, m2.models, 'test', 'SVMfunc', 'discrete');

        m3 = W.neuro_decode_slidingwindow(tr, 'cells', tr.games.condition, 'SVM', 'train', 'SVMfunc', 'discrete');
        r3 = W.neuro_decode_slidingwindow(te, 'cells', te.games.condition, m3.models, 'test', 'SVMfunc', 'discrete');

        out{i} = W.struct('r_delay', r1, 'r_drop', r2, 'r_interaction', r3);
        W.print_mute_off;
    end
    results{ai} = out;
end
W.save('../../TempData/decoding_Seam_twoarray', 'result', results);