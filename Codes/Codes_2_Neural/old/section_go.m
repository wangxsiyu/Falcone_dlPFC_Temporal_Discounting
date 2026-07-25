%%
anv = W.load('../../TempData/drop_delay.mat');
anv1 = W.load('../../TempData/condition.mat');
anv2 = W.load('../../TempData/result/anvGO_condition.mat');
ps = W.load('../../TempData/behavior_pYP');
%% drop vs delay
plt.figure(3,4)
vs_drop = cell(1,3);
vs_delay = cell(1,3);
vs_DV = cell(1,3);
vs_YP = cell(1,3);
for ai = 1:3
    if ai <= 2
        p = find(ps(ai,:) < 0.05);
    else
        p = find(any(ps < 0.05));
    end
    gID = anv1{ai}.info_cells.gameID;
    gs = cue{ai}.games;
    tdv = W.arrayfun(@(x)unique(gs{x}(:, ["condition", "DV"])).DV, gID);
    ncell = length(anv{ai}.cells);
    vdrop = NaN(ncell, ntime);
    vdelay = NaN(ncell, ntime);
    vDV = NaN(ncell, ntime);
    vYP = NaN(ncell, ntime);
    for ti = 1:ntime
        vdrop(:, ti) = W.cellfun(@(x)x.coef_factors_terms(2,ti), anv{ai}.cells)';
        vdelay(:, ti) = W.cellfun(@(x)x.coef_factors_terms(3,ti), anv{ai}.cells)';
        te = W.cellfun(@(x)x.coef_factors_terms(2:end,ti), anv1{ai}.cells)';
        vDV(:, ti) = W.arrayfun(@(x)corr(te{x}, tdv{x}), 1:ncell)';
%         vYP(:, ti) = W.cellfun(@(x)mean([x.coef_factors_terms([13:2:30],ti)- x.coef_factors_terms(1+[13:2:30],ti)]), anv2{ai}.cells)';
        vYP(:, ti) = W.cellfun(@(x)mean([x.coef_factors_terms(p * 2 + 9,ti)- x.coef_factors_terms(p * 2 + 10,ti)]), anv2{ai}.cells)';
    end

    plt.ax(ai,1);
    [r, p] = corr(vYP, vYP);
    plt.imagesc(timeat, timeat, r, 'AlphaData', p < 0.05);
    plt.setfig_ax('xlabel', 'YP', 'ylabel', {tlt{ai},'YP'});
    plt.ax(ai,2);
    [r, p] = corr(vdrop, vYP);
    plt.imagesc(timeat, timeat, r, 'AlphaData', p < 0.05);
    plt.setfig_ax('xlabel', 'YP', 'ylabel', 'drop');
    plt.ax(ai,3);
    [r, p] = corr(vdelay, vYP);
    plt.imagesc(timeat, timeat, r, 'AlphaData', p < 0.05);
    plt.setfig_ax('xlabel', 'YP', 'ylabel', 'delay')
    plt.ax(ai,4);
    [r, p] = corr(vDV, vYP, 'rows', 'pairwise');
    plt.imagesc(timeat, timeat, r, 'AlphaData', p < 0.05);
    plt.setfig_ax('xlabel', 'YP', 'ylabel', 'DV')
    vs_drop{ai} = vdrop;
    vs_delay{ai} = vdelay;
    vs_DV{ai} = vDV;
    vs_YP{ai} = vYP;
end
plt.update('heatGO');
%% scatter plot - drop vs delay
tm = [100 500];
id = timeat >= tm(1) & timeat <= tm(2);
plt.figure(3,3, 'is_title', 'all');
for ai = 1:3
    plt.ax(1,ai);
    plt.scatter(mean(vs_YP{ai}(:, id), 2), mean(vs_DV{ai}(:, id), 2), 'corr');
    plt.setfig_ax('xlabel', 'YP', 'ylabel', 'DV', 'title', tlt{ai});

    plt.ax(2,ai);
    plt.scatter(mean(vs_YP{ai}(:, id), 2), mean(vs_drop{ai}(:, id), 2), 'corr');
    plt.setfig_ax('xlabel', 'YP', 'ylabel', 'drop', 'title', tlt{ai});

    plt.ax(3,ai);
    plt.scatter(mean(vs_YP{ai}(:, id), 2), mean(vs_delay{ai}(:, id), 2), 'corr');
    plt.setfig_ax('xlabel', 'YP', 'ylabel', 'delay', 'title', tlt{ai});
end
plt.update('corrGO');