%%
factornames = {'drop', 'delay'};
anv = {};
for i = 1:3
    d = cue{i};
    anv{i} = W.anovan_slidingwindow_combinedgames(d, factornames, 'continuous', [1 2], 'is_normalize', false);
end
W.save('../../TempData/drop_delay.mat', 'anv', anv);
%% drop vs delay
anv = W.load('../../TempData/drop_delay.mat')

plt.figure(3,3)
vs_drop = cell(1,3);
vs_delay = cell(1,3);
for ai = 1:3
    ncell = length(anv{ai}.cells);
    vdrop = NaN(ncell, ntime);
    vdelay = NaN(ncell, ntime);
    for ti = 1:ntime
        vdrop(:, ti) = W.cellfun(@(x)x.coef_factors_terms(2,ti), anv{ai}.cells)';
        vdelay(:, ti) = W.cellfun(@(x)x.coef_factors_terms(3,ti), anv{ai}.cells)';
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
    [r, p] = corr(vdelay, vdrop);
    rr{ai} = diag(r);
    plt.imagesc(timeat, timeat, r, 'AlphaData', p < 0.05);
    plt.setfig_ax('xlabel', 'drop', 'ylabel', 'delay')

%             opt_params = W.struct('colormap', [], 'saveobject', 1, ...
%                 'iscolorbar', false, 'colorbarPosition', [], ...
%                 'LineWidth', obj.param_plt.linewidth, 'is_hollow_dot', false, ...
%                 'Clim', [], 'AlphaData', []);
    vs_drop{ai} = vdrop;
    vs_delay{ai} = vdelay;
end
plt.update;
%% scatter plot - drop vs delay
tm = [750 1000];
id = timeat >= tm(1) & timeat <= tm(2);
plt.figure(1,3);
for ai = 1:3
    plt.ax(1,ai);
    plt.scatter(mean(vs_drop{ai}(:, id), 2), mean(vs_delay{ai}(:, id), 2), 'corr');
    plt.setfig_ax('xlabel', 'drop', 'ylabel', 'delay', 'title', tlt{ai});
end
plt.update;
%% drop/delay vs time
plt.figure(1,2);
for ai = 1:2
    plt.ax(1,ai);


    plt.plot(timeat, rr{ai}', [], 'line');
    plt.setfig_ax('xlabel', 'time', 'ylabel', 'cor(delay, drop)', 'title', tlt{ai});
end
plt.update;
