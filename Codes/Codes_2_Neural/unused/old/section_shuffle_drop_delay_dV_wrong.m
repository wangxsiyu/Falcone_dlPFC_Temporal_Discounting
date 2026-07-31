%%
factornames = {'drop', 'delay', 'DV'};
anv = {};
for i = 1:2
    d = cue{i};
    ncell = length(d.cells);
    for ci = 1:ncell
        idnew = randperm(size(d.cells{ci},1));
        d.cells{ci} = d.cells{ci}(idnew,:);
    end
    anv{i} = W.anovan_slidingwindow_combinedgames(d, factornames, 'continuous', [1 2 3], 'is_normalize', false);
end
anv{3} = W.format_combinecells(anv);
W.save('../../TempData/shuffle_drop_delay_dV.mat', 'anv', anv);
%% drop vs delay
plt.figure(6,3)
vs_drop = cell(1,3);
vs_delay = cell(1,3);
vs_DV = cell(1,3);
for ai = 1:3
    ncell = length(anv{ai}.cells);
    vdrop = NaN(ncell, ntime);
    vdelay = NaN(ncell, ntime);
    vDV = NaN(ncell, ntime);
    for ti = 1:ntime
        vdrop(:, ti) = W.cellfun(@(x)x.coef_factors_terms(2,ti), anv{ai}.cells)';
        vdelay(:, ti) = W.cellfun(@(x)x.coef_factors_terms(3,ti), anv{ai}.cells)';
        vDV(:, ti) = W.cellfun(@(x)x.coef_factors_terms(4,ti), anv{ai}.cells)';
    end

    plt.ax(1,ai);
    [r, p] = corr(vdrop, vdrop);
    plt.imagesc(timeat, timeat, r, 'AlphaData', p < 0.05);
    plt.setfig_ax('xlabel', 'drop', 'ylabel', 'drop', 'title', tlt{ai});
    plt.ax(2,ai);
    [r, p] = corr(vdelay, vdelay);
    plt.imagesc(timeat, timeat, r, 'AlphaData', p < 0.05);
    plt.setfig_ax('xlabel', 'delay', 'ylabel', 'delay')
    plt.ax(3,ai);
    [r, p] = corr(vDV, vDV);
    plt.imagesc(timeat, timeat, r, 'AlphaData', p < 0.05);
    plt.setfig_ax('xlabel', 'DV', 'ylabel', 'DV')

    plt.ax(4,ai);
    [r, p] = corr(vdrop, vDV);
    plt.imagesc(timeat, timeat, r, 'AlphaData', p < 0.05);
    plt.setfig_ax('xlabel', 'DV', 'ylabel', 'drop', 'title', tlt{ai});
    plt.ax(5,ai);
    [r, p] = corr(vdelay, vDV);
    plt.imagesc(timeat, timeat, r, 'AlphaData', p < 0.05);
    plt.setfig_ax('xlabel', 'DV', 'ylabel', 'delay')
    plt.ax(6,ai);
    [r, p] = corr(vdelay, vdrop);
    plt.imagesc(timeat, timeat, r, 'AlphaData', p < 0.05);
    plt.setfig_ax('xlabel', 'drop', 'ylabel', 'delay')

%             opt_params = W.struct('colormap', [], 'saveobject', 1, ...
%                 'iscolorbar', false, 'colorbarPosition', [], ...
%                 'LineWidth', obj.param_plt.linewidth, 'is_hollow_dot', false, ...
%                 'Clim', [], 'AlphaData', []);
    vs_drop{ai} = vdrop;
    vs_delay{ai} = vdelay;
    vs_DV{ai} = vDV;
end
plt.update;
%% scatter plot - drop vs delay
tm = [750 1000];
id = timeat >= tm(1) & timeat <= tm(2);
plt.figure(3,3);
for ai = 1:3
    plt.ax(1,ai);
    plt.scatter(mean(vs_drop{ai}(:, id), 2), mean(vs_delay{ai}(:, id), 2), 'corr');
    plt.setfig_ax('xlabel', 'drop', 'ylabel', 'delay', 'title', tlt{ai});

    plt.ax(2,ai);
    plt.scatter(mean(vs_DV{ai}(:, id), 2), mean(vs_drop{ai}(:, id), 2), 'corr');
    plt.setfig_ax('xlabel', 'DV', 'ylabel', 'drop', 'title', tlt{ai});

    plt.ax(3,ai);
    plt.scatter(mean(vs_DV{ai}(:, id), 2), mean(vs_delay{ai}(:, id), 2), 'corr');
    plt.setfig_ax('xlabel', 'DV', 'ylabel', 'delay', 'title', tlt{ai});
end
plt.update;