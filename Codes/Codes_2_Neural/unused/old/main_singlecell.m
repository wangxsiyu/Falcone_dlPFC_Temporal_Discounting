plt = S_plt('savedir', './figures', 'issave',1);
cellID = 86;
animal = "T";
g = cue{2}.games{cue{2}.info_cells.gameID(cellID)};

ep = cue{2}.cells{cellID};
st = cue{2}.ST{cellID};
%%
plt.figure(2,3, 'gapW_custom', [0 0 0 5]);

cc = W.cond_average_tab(g, {'condition'}, {'choice','DV','drop', 'delay'});
dv = cc.avDV;
[~, od] = sort(dv);




plt.ax(1,1);
cols = {'RSred', 'yellow', 'RSgreen'};

trials = W.arrayfun(@(x)find(g.drop == x), unique(g.drop));
for i = 1:3
    [av, se] = W.avse(ep(trials{i},:));
    plt.plot(timeat, av, [], 'line', 'color', cols{i});
end
legs = W.iif(fi == 2,W.arrayfun(@(x)sprintf('dv = %.2f', x), dv(od)), []);
plt.setfig_ax('xlabel', 'Time (ms)', 'ylabel', 'firing rate', ...
    'xlim', [-500 1000], 'legend', legs, 'legloc', 'NEO');
plt.ax(2,1);
width = 0.4;
x0 = 0;
for i = 3:-1:1
    tst = st(ismember(st.trialID, trials{i}),:);
    x = W.horz(tst.spiketimes);
    tnt = length(unique(tst.trialID));
    tst.trialID = W.num2rank(tst.trialID);
    y = W.horz(tst.trialID) + x0;
    x0 = x0 + tnt;

    err = width*ones(size(x));
    plt.plot(x, y, err, 'line', 'LineStyle', '.', 'color', cols{i}, ...
        'CapSize', 0, 'MarkerSize', 1);
end

plt.setfig_ax('xlabel', 'Time (ms)', 'ylabel', 'Trial No.', 'ylim', [0 x0+1], ...
    'xlim', [-500 1000]);


plt.ax(1,2);
cols = {'RSred', 'yellow', 'RSgreen'};

trials = W.arrayfun(@(x)find(g.delay == x), unique(g.delay));
for i = 1:3
    [av, se] = W.avse(ep(trials{i},:));
    plt.plot(timeat, av, [], 'line', 'color', cols{i});
end
legs = W.iif(fi == 2,W.arrayfun(@(x)sprintf('dv = %.2f', x), dv(od)), []);
plt.setfig_ax('xlabel', 'Time (ms)', 'ylabel', 'firing rate', ...
    'xlim', [-500 1000], 'legend', legs, 'legloc', 'NEO');
plt.ax(2,2);
width = 0.4;
x0 = 0;
for i = 3:-1:1
    tst = st(ismember(st.trialID, trials{i}),:);
    x = W.horz(tst.spiketimes);
    tnt = length(unique(tst.trialID));
    tst.trialID = W.num2rank(tst.trialID);
    y = W.horz(tst.trialID) + x0;
    x0 = x0 + tnt;

    err = width*ones(size(x));
    plt.plot(x, y, err, 'line', 'LineStyle', '.', 'color', cols{i}, ...
        'CapSize', 0, 'MarkerSize', 1);
end

plt.setfig_ax('xlabel', 'Time (ms)', 'ylabel', 'Trial No.', 'ylim', [0 x0+1], ...
    'xlim', [-500 1000]);




plt.ax(1,3);
cols = W.arrayfun(@(x)plt.interpolatecolors({'RSred', 'yellow', 'RSgreen'}, [min(dv), dv(od(5)), max(dv)], x), dv(od));
trials = W.arrayfun(@(x)find(g.condition == x), od);

for i = 1:9
    [av, se] = W.avse(ep(trials{i},:));
    plt.plot(timeat, av, [], 'line', 'color', cols{i});
end
legs = W.iif(fi == 2,W.arrayfun(@(x)sprintf('dv = %.2f', x), dv(od)), []);
plt.setfig_ax('xlabel', 'Time (ms)', 'ylabel', 'firing rate', ...
    'xlim', [-500 1000], 'legend', legs, 'legloc', 'NEO');
plt.ax(2,3);
width = 0.4;
x0 = 0;
for i = 9:-1:1
    tst = st(ismember(st.trialID, trials{i}),:);
    x = W.horz(tst.spiketimes);
    tnt = length(unique(tst.trialID));
    tst.trialID = W.num2rank(tst.trialID);
    y = W.horz(tst.trialID) + x0;
    x0 = x0 + tnt;

    err = width*ones(size(x));
    plt.plot(x, y, err, 'line', 'LineStyle', '.', 'color', cols{i}, ...
        'CapSize', 0, 'MarkerSize', 1);
end

plt.setfig_ax('xlabel', 'Time (ms)', 'ylabel', 'Trial No.', 'ylim', [0 x0+1], ...
    'xlim', [-500 1000]);

plt.update;
