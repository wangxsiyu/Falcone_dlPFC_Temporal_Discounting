data = W.load('../../TempData/data');
go = data.go;
plt = SW_plt_from_yml('../fig.yml');
%% go period
%% ANOVA: drop + delay + interaction + yellow/purple + motor + choice
factornames = {'drop', 'delay', 'choice', 'motor', 'GO cue'};
factornames_in_data = {'drop', 'delay', 'choice', 'release1', 'cue1'};
model = [1,0,0,0,0; ...
         0,1,0,0,0; ...
         1,1,0,0,0; ...
         0,0,1,0,0; ...
         0,0,0,1,0; ...
         0,0,0,0,1];
anv = {};
for i = 1:2
    d = go{i};
    anv{i} = W.anovan_slidingwindow_combinedgames(d, factornames, ...
        'factornames_in_data', factornames_in_data, ...
        'model', model);
    % merge factors
    anv{i} = W.anovan_mergefactors(anv{i}, {'delay', 'drop', 'drop*delay'}, {'drop|delay'});
end
W.save('../../TempData/result/anvGO_all_factors', 'anv', anv);
%% Figure - ANOVA
anv = W.load('../../TempData/result/anvGO_all_factors');
SW_fig(plt, anv{1}, anv{2}, 'axes', 'ax_slidingwindow_ANOVA','ax_slidingwindow_ANOVA', ...
    'ax_slidingwindow_ANOVA_omega','ax_slidingwindow_ANOVA_omega', ...
     'data_axes', 1, 2, 1, 2, ...
     'varargin_axes', {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 1'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 2'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     'ABC_axes', 'ABCD', 'nx', 2, 'ny', 2, ...
     'varargin_fig', 'is_title', 'all', 'savename', 'anvGO_all_factors');
%%
SW_fig(plt, anv{1}, anv{2}, 'axes', 'ax_slidingwindow_ANOVA','ax_slidingwindow_ANOVA', ...
    'ax_slidingwindow_ANOVA_omega','ax_slidingwindow_ANOVA_omega', ...
     'data_axes', 1, 2, 1, 2, ...
     'varargin_axes', {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 1'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 2'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     'ABC_axes', 'ABCD', 'nx', 2, 'ny', 2, ...
     'varargin_fig', 'is_title', 'all', 'savename', 'anvGO_all_factors_merged');
%% ANOVA: condition + yellow/purple + motor + choice
factornames = {'condition', 'motor', 'GO cue'};
factornames_in_data = {'condition', 'release1', 'cue1'};
model = [1,0,0; ...
         0,1,0; ...
         0,0,1];
anv = {};
for i = 1:2
    d = go{i};
    anv{i} = W.anovan_slidingwindow_combinedgames(d, factornames, ...
        'factornames_in_data', factornames_in_data, ...
        'model', model);
end
W.save('../../TempData/result/anvGO_condition', 'anv', anv);
%%
SW_fig(plt, anv{1}, anv{2}, 'axes', 'ax_slidingwindow_ANOVA','ax_slidingwindow_ANOVA', ...
    'ax_slidingwindow_ANOVA_omega','ax_slidingwindow_ANOVA_omega', ...
     'data_axes', 1, 2, 1, 2, ...
     'varargin_axes', {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 1'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NW', 'xlim', [-500, 1000], 'ylim', [-0.02 0.7], 'ytick', -1:.2:1, 'title', 'Monkey 2'}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     {'plottype', 'shade', ...
     'legloc', 'NE', 'xlim', [-500, 1000], 'ylim', [-0.001 0.035], 'ytick', [-0.05:0.01:0.05]}, ...
     'ABC_axes', 'ABCD', 'nx', 2, 'ny', 2, ...
     'varargin_fig', 'is_title', 'all');
% 
% %% Figure - correlation between dV and yellow/purple 
% cuecoef = W.load('../../TempData/result/cue_coefs');
% anv = W.load('../../TempData/result/anvGO_DV_choice_motor_gocue');
% id = W.cellfun(@(x)find(strcmp(anv{1}.cells{1}.name_factors_terms, x)), {'DV', 'choice', 'motor', 'GO cue', 'Constant'});
% ntime = length(timeat);
% coef = cell(2, ntime);
% invcoef = cell(2, ntime);
% wd = [300 800];
% idwd = find(timeat > wd(1) & timeat < wd(2));
% % idwd = 171;
% avcoef = cell(1,2);
% avinvcoef = cell(1,2);
% avc0 = cell(1,2);
% for i = 1:2
%     tcoefs = W.cellfun(@(x)x.coef_factors_terms(id,:), anv{i}.cells);
%     tcoefs = W.cell_transpose(W.cell_NxMK2KxMN(W.cell_transpose(tcoefs)));
%     ttcoef = W.cellfun_horzcat(@(x)mean(x(:, idwd), 2), tcoefs);
%     avcoef{i} = ttcoef;
%     avinvcoef{i} = (inv(ttcoef(:, 1:4)' * ttcoef(:, 1:4)) * ttcoef(:, 1:4)')';
%     avc0{i} = ttcoef(:, 5);
% %     figure, imagesc(tcoefs{1})
% %     tcoefs = W.cell_NxMK2KxMN(tcoefs);
%     for ti = 1:ntime
%         ttcoef = W.arrayfun_horzcat(@(x)tcoefs{x}(:, ti), 1:4);
%         coef{i, ti} = ttcoef;
%         invcoef{i, ti} = (inv(ttcoef' * ttcoef) * ttcoef')';
%     end
% end
% W.save('../../TempData/result/go_coefs', 'coef', coef, 'invcoef', invcoef, ...
%     'avcoef', avcoef, 'avinvcoef', avinvcoef, 'avc0', avc0);
% %% get mean firing rate per condition per neuron
% trajs = cell(1,2);
% for i = 1:2
%     trajs{i} = get_all_traj(go{i});
% end
% %% projections onto the three dimensions bin by bin
% projs = cell(2, 4);
% for i = 1:2
%     tprojs = cell(1, 9);
%     for ci = 1:9
%         tprojs{ci} = W.arrayfun_horzcat(@(x)avinvcoef{i}' * (trajs{i}{ci}(:, x) - avc0{i}), 1:ntime);
%     end
%     projs(i,:) = W.cell_transpose(W.cell_NxMK2KxMN(W.cell_transpose(tprojs)));
% end
% %% Figure - linear decoding
% plt.figure(2,4, 'gapW_custom', [0 0 0 0 7], 'is_title', 'all');
% tlts = {'DV', 'choice', 'motor', 'GO cue'};
% for ai = 1:2
%     for i = 1:4
%         plt.ax(ai,i);
%         cols = plt.custom_vars.color_condition;
%         plt.plot(timeat, projs{ai, i}, [], 'line', 'color', cols);
%         plt.setfig_ax('xlim', [-500 1000], 'title', tlts{i}, 'xlabel', 'time (ms)');
%         if i == 1
%             plt.setfig_ax('ylabel', sprintf('Monkey %d', ai));
%         end
%         if i == 4 && ai == 2
%             legs = arrayfun(@(x)sprintf("drop = %d, delay = %d", drop(x), delay(x)), 1:9);
%             plt.setfig_ax('legend', legs, 'legloc', 'EO');
%         end
%     end
% end
% plt.update('linear decoding GO');
% %% Figure - scatter plots
% plt.figure(6,2, 'gapW_custom', [0.5 0 0.5], 'is_title', 1);
% names = string({'DV', 'choice', 'motor', 'GO cue'});
% iii = {[1 2], [1 3], [1 4], [2 3], [2 4], [3 4]};
% for ai = 1:2
%     for i = 1:6
%         ii = iii{i};
%         plt.ax(i, ai);
%         if i == 1
%             plt.setfig_ax('title', sprintf('Monkey %d', ai));
%         end
%         plt.scatter(avinvcoef{ai}(:,ii(1)), avinvcoef{ai}(:,ii(2)), 'corr');
%         plt.setfig_ax('ylabel', ['Coding dimension for ' char(names(ii(2)))], ...
%             'xlabel', ['Coding dimension for ' char(names(ii(1)))]);
%     end
% end
% plt.update('corr DV GOcue');
% %% correlations between dimensions over time
% rr = W.cellfun(@(x)W.func('corr', 1, x, x), invcoef);
% pp = W.cellfun(@(x)W.func('corr', 2, x, x), invcoef);
% rrr = cell(2, 3);
% ppp = cell(2, 3);
% 
% for i = 1:4
%     for j = 1:4
%         rrr{i,j} = W.cellfun(@(x)x(i,j), rr);
%         ppp{i,j} = W.cellfun(@(x)x(i,j), pp);
%     end
% end
% %% Figure - correlation between drop/delay/dV/choice over time
% plt.figure(6,2, 'gapW_custom', [0.5 0 0.5], 'is_title', 1);
% names = string({'DV', 'choice', 'motor', 'GO cue'});
% iii = {[1 2], [1 3], [1 4], [2 3], [2 4], [3 4]};
% for ai = 1:2
%     for i = 1:6
%         ii = iii{i};
%         plt.ax(i, ai);
%         if i == 1
%             plt.setfig_ax('title', sprintf('Monkey %d', ai));
%         end
%         plt.plot(timeat, rrr{ii(1), ii(2)}(ai,:), [], 'line');
% %         plt.sigstar(timeat, rrr{ii(1), ii(2)}(ai,:), ppp{ii(1), ii(2)}(ai,:));
%         plt.setfig_ax('ylabel', ['Coding dimension for ' char(names(ii(1)))], ...
%             'xlabel', ['Coding dimension for ' char(names(ii(2)))], ...
%             'ylim', [-1 1], 'xlim', [-500 1000]);
%     end
% end
% plt.update('corr DV GOcue over time');
% %% correlations between dimensions over time
% rr = {}; pp = {};
% for i = 1:2
%     rr{i} = W.cellfun_horzcat(@(x)W.func('corr', 1, x, cuecoef.avinvcoef{i}(:,3)), invcoef(i,:));
%     pp{i} = W.cellfun_horzcat(@(x)W.func('corr', 2, x, cuecoef.avinvcoef{i}(:,3)), invcoef(i,:));
% end
% %% Figure - correlation between drop/delay/dV/choice over time
% plt.figure(1,2, 'gapW_custom', [0.5 0 0.5], 'is_title', 1);
% names = string({'DV', 'choice', 'motor', 'GO cue'});
% for ai = 1:2
%     plt.ax(1, ai);
%     plt.setfig_ax('title', sprintf('Monkey %d', ai));
%     plt.plot(timeat, rr{ai}, [], 'line');
%     %         plt.sigstar(timeat, rrr{ii(1), ii(2)}(ai,:), ppp{ii(1), ii(2)}(ai,:));
%     plt.setfig_ax('ylabel', ['Coding dimension for ' char(names(ii(1)))], ...
%         'xlabel', ['Coding dimension for ' char(names(ii(2)))], ...
%         'ylim', [-1 1], 'xlim', [-500 1000], 'legend', names);
% end
% plt.update('corr DV GOcue over time');
