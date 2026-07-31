data = W.load('../../TempData/data');
cue = data.cue;
cue{3} = W.format_combinecells(cue);
plt = SW_plt_from_yml('../fig.yml');
drop = plt.custom_vars.drop;
delay = plt.custom_vars.delay;
timeat = cue{1}.time_at;
%% cue period
%% ANOVA: drop + delay + interaction + choice (baseline)
factornames = {'drop', 'delay', 'choice'};
model = [1,0,0;0,1,0;1,1,0;0,0,1];
anv = {};
for i = 1:2
    d = cue{i};
    anv{i} = W.anovan_slidingwindow_combinedgames(d, factornames, 'model', model);
end
W.save('../../TempData/result/anv_drop_delay_interaction_choice', 'anv', anv);
%% Figure - baseline
anv = W.load('../../TempData/result/anv_drop_delay_interaction_choice');
SW_fig(plt, anv{1}, anv{2}, W.format_combinecells(anv), ...
    'axes', 'ax_slidingwindow_ANOVA','ax_slidingwindow_ANOVA','ax_slidingwindow_ANOVA', ...
    'ax_slidingwindow_ANOVA_omega','ax_slidingwindow_ANOVA_omega','ax_slidingwindow_ANOVA_omega', ...
     'data_axes', 1, 2, 3, 1, 2, 3,  ...
     'varargin_axes', {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 1'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 2'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', ''}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     'ABC_axes', 'ABACDB', 'nx', 2, 'ny', 3, ...
     'varargin_fig', 'is_title', 'all', 'savename', 'ANOVA_drop_delay_interaction_choice');
%% ANOVA: drop + delay + dV (continuous) 
factornames = {'drop', 'delay', 'DV'};
anv = {};
for i = 1:2
    d = cue{i};
    anv{i} = W.anovan_slidingwindow_combinedgames(d, factornames, 'continuous', [1 2 3], 'is_normalize', true);
end
W.save('../../TempData/result/anv_dropC_delayC_DV', 'anv', anv);
%%
factornames = {'drop', 'delay'};
anv = {};
for i = 1:2
    d = cue{i};
    anv{i} = W.anovan_slidingwindow_combinedgames(d, factornames, 'continuous', [1 2], 'is_normalize', true);
end
W.save('../../TempData/result/anv_dropC_delayC', 'anv', anv);
%% test
dsf = d;
for i = 1:length(dsf.cells)
    idnew = randperm(size(dsf.cells{i},1));
    dsf.cells{i} = dsf.cells{i}(idnew,:);
end

tanv = W.anovan_slidingwindow_combinedgames(dsf, factornames, 'continuous', [1 2 3], 'is_normalize', true);

SW_fig(plt, tanv, tanv, W.format_combinecells(anv), ...
    'axes', 'ax_slidingwindow_ANOVA','ax_slidingwindow_ANOVA','ax_slidingwindow_ANOVA', ...
    'ax_slidingwindow_ANOVA_omega','ax_slidingwindow_ANOVA_omega','ax_slidingwindow_ANOVA_omega', ...
     'data_axes', 1, 2, 3, 1, 2, 3, ...
     'varargin_axes', {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 1'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 2'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', ''}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     'ABC_axes', 'ABACDB', 'nx', 2, 'ny', 3, ...
     'varargin_fig', 'is_title', 'all');
    tcoefs = W.cellfun(@(x)x.coef_factors_terms([2 3 4],:), tanv.cells);
    tcoefs = W.cell_transpose(W.cell_NxMK2KxMN(W.cell_transpose(tcoefs)));
    for ti = 1:ntime
        tecoef{ti} = W.arrayfun_horzcat(@(x)tcoefs{x}(:, ti), 1:3);
    end
rr = W.cellfun(@(x)W.func('corr', 1, x, x), tecoef);
rrr = cell(3, 3);
ppp = cell(3, 3);

for i = 1:3
    for j = 1:3
        rrr{i,j} = W.cellfun(@(x)x(i,j), rr);
%         ppp{i,j} = W.cellfun(@(x)x(i,j), pp);
    end
end
%% Figure ANOVA DV
anv = W.load('../../TempData/result/anv_dropC_delayC_DV');
SW_fig(plt, anv{1}, anv{2}, W.format_combinecells(anv), ...
    'axes', 'ax_slidingwindow_ANOVA','ax_slidingwindow_ANOVA','ax_slidingwindow_ANOVA', ...
    'ax_slidingwindow_ANOVA_omega','ax_slidingwindow_ANOVA_omega','ax_slidingwindow_ANOVA_omega', ...
     'data_axes', 1, 2, 3, 1, 2, 3, ...
     'varargin_axes', {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 1'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 2'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', ''}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     'ABC_axes', 'ABACDB', 'nx', 2, 'ny', 3, ...
     'varargin_fig', 'is_title', 'all', 'savename', 'ANOVA_dropC_delayC_DV');
%% Figure ANOVA DV
anv = W.load('../../TempData/result/anv_dropC_delayC');
SW_fig(plt, anv{1}, anv{2}, W.format_combinecells(anv), ...
    'axes', 'ax_slidingwindow_ANOVA','ax_slidingwindow_ANOVA','ax_slidingwindow_ANOVA', ...
    'ax_slidingwindow_ANOVA_omega','ax_slidingwindow_ANOVA_omega','ax_slidingwindow_ANOVA_omega', ...
     'data_axes', 1, 2, 3, 1, 2, 3, ...
     'varargin_axes', {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 1'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 2'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', ''}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     'ABC_axes', 'ABACDB', 'nx', 2, 'ny', 3, ...
     'varargin_fig', 'is_title', 'all', 'savename', 'ANOVA_dropC_delayC');
%% analysis - linear decoding coefs
anv = W.load('../../TempData/result/anv_dropC_delayC');
id = W.cellfun(@(x)find(strcmp(anv{1}.cells{1}.name_factors_terms, x)), {'drop', 'delay', 'Constant'});
ntime = length(timeat);
coef = cell(2, ntime);
invcoef = cell(2, ntime);
wd = [75 750];
idwd = find(timeat > wd(1) & timeat < wd(2));
avcoef = cell(1,2);
avinvcoef = cell(1,2);
avc0 = cell(1,2);
for i = 1:2
    tcoefs = W.cellfun(@(x)x.coef_factors_terms(id,:), anv{i}.cells);
    tcoefs = W.cell_transpose(W.cell_NxMK2KxMN(W.cell_transpose(tcoefs)));
    ddd{i}  =tcoefs;
    ttcoef = W.cellfun_horzcat(@(x)mean(x(:, idwd), 2), tcoefs);
    avcoef{i} = ttcoef;
    avinvcoef{i} = (inv(ttcoef(:, 1:2)' * ttcoef(:, 1:2)) * ttcoef(:, 1:2)')';
    avc0{i} = ttcoef(:, 3);
    % figure, imagesc(tcoefs{1})
    % tcoefs = W.cell_NxMK2KxMN(tcoefs);
    for ti = 1:ntime
        ttcoef = W.arrayfun_horzcat(@(x)tcoefs{x}(:, ti), 1:3);
        coef{i, ti} = ttcoef;
        invcoef{i, ti} = (inv(ttcoef' * ttcoef) * ttcoef')';
    end
end
avinvcoef{3} = vertcat(avinvcoef{1}, avinvcoef{2});
avc0{3} = vertcat(avc0{1}, avc0{2});
W.save('../../TempData/result/cue_coefs', 'coef', coef, 'invcoef', invcoef, ...
    'avcoef', avcoef, 'avinvcoef', avinvcoef);
%% get mean firing rate per condition per neuron
trajs = cell(1,2);
for i = 1:3
    trajs{i} = get_all_traj(cue{i});
end
%% projections onto the three dimensions bin by bin
projs = cell(3, 3);
for i = 1:3
    tprojs = cell(1, 9);
    for ci = 1:9
        tprojs{ci} = W.arrayfun_horzcat(@(x)avinvcoef{i}' * (trajs{i}{ci}(:, x) - avc0{i}), 1:ntime);
    end
    projs(i,:) = W.cell_transpose(W.cell_NxMK2KxMN(W.cell_transpose(tprojs)));
end
%% Figure - linear decoding
plt.figure(3,3, 'gapW_custom', [0 0 0 7], 'is_title', 'all');
tlts = {'drop', 'delay', 'DV'};
for ai = 1:3
    for i = 1:3
        plt.ax(ai,i);
        cols = plt.custom_vars.color_condition;
        plt.plot(timeat, projs{ai, i}, [], 'line', 'color', cols);
        plt.setfig_ax('xlim', [-500 1000], 'title', tlts{i}, 'xlabel', 'time (ms)');
        if i == 1
            plt.setfig_ax('ylabel', sprintf('Monkey %d', ai));
        end
        if i == 3 && ai == 2
            legs = arrayfun(@(x)sprintf("drop = %d, delay = %d", drop(x), delay(x)), 1:9);
            plt.setfig_ax('legend', legs, 'legloc', 'EO');
        end
    end
end
plt.update('linear decoding');
%% Figure - scatter plots
plt.figure(3,3, 'gapW_custom', [0.5 0 0 0.5], 'is_title', 1);
names = ["drop", "delay", "DV"];
iii = {[1 3], [2 3], [1 2]};
for ai = 1:3
    for i = 1:3
        ii = iii{i};
        plt.ax(i, ai);
        if i == 1 && ai ~= 3
            plt.setfig_ax('title', sprintf('Monkey %d', ai));
        end
        plt.scatter(avinvcoef{ai}(:,ii(1)), avinvcoef{ai}(:,ii(2)), 'corr');
        plt.setfig_ax('ylabel', ['Coding dimension for ' char(names(ii(1)))], ...
            'xlabel', ['Coding dimension for ' char(names(ii(2)))]);
    end
end
plt.update('corr DV vs drop delay');
%% Figure - scatter plots v2
plt.figure(3,3, 'gapW_custom', [0.5 0 0 0.5], 'is_title', 1);
names = ["drop", "delay", "DV"];
iii = {[1 3], [2 3], [1 2]};
avcoef{3} = vertcat(avcoef{1}, avcoef{2});
for ai = 1:3
    for i = 1:3
        ii = iii{i};
        plt.ax(i, ai);
        if i == 1 && ai ~= 3
            plt.setfig_ax('title', sprintf('Monkey %d', ai));
        end
        plt.scatter(avcoef{ai}(:,ii(1)), avcoef{ai}(:,ii(2)), 'corr');
        plt.setfig_ax('ylabel', ['Coding dimension for ' char(names(ii(1)))], ...
            'xlabel', ['Coding dimension for ' char(names(ii(2)))]);
    end
end
plt.update('corr DV vs drop delay v2');
%% correlations between dimensions over time
rr = W.cellfun(@(x)W.func('corr', 1, x, x), coef);
pp = W.cellfun(@(x)W.func('corr', 2, x, x), coef);
rrr = cell(3, 3);
ppp = cell(3, 3);

for i = 1:3
    for j = 1:3
        rrr{i,j} = W.cellfun(@(x)x(i,j), rr);
        ppp{i,j} = W.cellfun(@(x)x(i,j), pp);
    end
end
%% Figure - correlation between drop/delay/dV/choice over time
plt.figure(3,2, 'gapW_custom', [0.5 0 0.5], 'is_title', 1);
names = ["drop", "delay", "DV"];
iii = {[1 3], [2 3], [1 2]};
for ai = 1:2
    for i = 1:3
        ii = iii{i};
        plt.ax(i, ai);
        if i == 1
            plt.setfig_ax('title', sprintf('Monkey %d', ai));
        end
        plt.plot(timeat, rrr{ii(1), ii(2)}(ai,:), [], 'line');
        plt.sigstar(timeat, rrr{ii(1), ii(2)}(ai,:), ppp{ii(1), ii(2)}(ai,:));
        plt.setfig_ax('ylabel', ['Coding dimension for ' char(names(ii(1)))], ...
            'xlabel', ['Coding dimension for ' char(names(ii(2)))], ...
            'ylim', [-1 1], 'xlim', [-500 1000]);
    end
end
plt.update('corr DV vs drop delay over time');
%%
plt.figure(2,3, 'gapW_custom', [0 0 0 3]);
names = ["drop", "delay", "C"];
iiii = {[2 3], [1 3], [1 2]};
for ai = 1:2
    dd = ddd{ai};
    for i = 1:3
        ii = iiii{i};
        tlt = sprintf('%s vs %s', names(ii(1)), names(ii(2)));
        plt.ax(i);
        [tcor, pcor] = corr(dd{ii(1)}, dd{ii(2)}, 'Rows', 'pairwise');
        tcor(pcor > 0.05) = NaN;
        colormap jet
        h = imagesc(timeat, timeat, tcor);
        set(gca, 'YDir', 'normal', 'CLim', [-1 1]);
        set(h, 'AlphaData', ~isnan(tcor))
        plt.setfig_ax('ylabel', names(ii(1)), 'xlabel', 'Discounted value', ...
            'title', tlt);
        h = colorbar('manual');
        h.Position = [0.93 0.2 0.02 0.6];
    end
end
plt.update('supplementary - DV vs drop delay');
