data = W.load('../../TempData/data');
session = data.cue{1}.info_session.info_combinedsessions;
gs = data.cue{1}.games;
gs = {gs(session.animal == "S"), gs(session.animal == "T")};
%% compute choice curve, and condition means
gs_all = {vertcat(gs{1}{:}), vertcat(gs{2}{:})};
c0 = W.cellfun_vertcat(@(g)W.cond_average_tab(g, 'condition', 'choice'), gs_all);
v1 = W.cellfun_vertcat(@(g)W.cond_average_tab(g, 'condition', 'DV'), gs_all);
%% Figure 2 - behavior
xfit = W.load('../../TempData/modelfit_overall');
params = {xfit{1,1}.params_table, xfit{1,2}.params_table};

xlms = {[0 2.5], [0 4]};
point_labels = 'adgbehcfi';
label_dx = { ...
    [0.02 -0.04 0.02 0.02 -0.04 0.02 0.02 0.02 0.02], ...
    [0.02 0.02 -0.04 0.02 -0.04 -0.04 0.02 0.02 0.02]};
label_dy = { ...
    [-0.025 0.025 -0.025 -0.025 -0.025 0.020 -0.025 -0.035 -0.025], ...
    [0.015 -0.025 -0.025 -0.025 0.025 -0.025 -0.025 -0.025 -0.025]};
plt.figure(1,2, 'is_title', 'all');
for i = 1:2
    plt.ax(1, i);
    xs = 0:0.01:5;
    x = params{i};
    f = @(V)W.col_select(W_RL.softmax_binary(x.thres, V, x.beta),2);
    cp = arrayfun(@(x)f(x), xs);
    plt.plot(xs, cp, [], 'line', 'color', 'black', 'LineWidth', 2);
    sp = 'ooosssddd';
    col = 'brgbrgbrg';
%     plt.plot(v1.avDV(i,:), c0.avCHOICE(i, :), c0.seCHOICE(i, :), 'line', 'color', 'black', 'LineStyle', 'o');
    for j = 1:9
        plt.scatter(v1.avDV(i,j), c0.avCHOICE(i, j), [], 'shape', sp(j), ...
            'dotsize', 7, 'color', col(j));
        plt.matlabax(@(~)text( ...
            v1.avDV(i,j) + label_dx{i}(j) .* diff(xlms{i}), ...
            c0.avCHOICE(i,j) + label_dy{i}(j), point_labels(j), ...
            'FontSize', 8, 'Color', [0.25 0.25 0.25], ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle'));
    end
    plt.matlabax(@(~)set(findobj(gca, 'Type', 'line', ...
        '-not', 'Marker', 'none'), 'LineWidth', 2));
    if i == 2
        plt.matlabax(@(ax)legend(ax, [ ...
            line(ax, nan, nan, 'LineStyle', 'none', 'Marker', 'o', ...
                'MarkerSize', 7, 'MarkerEdgeColor', 'black', 'LineWidth', 2); ...
            line(ax, nan, nan, 'LineStyle', 'none', 'Marker', 's', ...
                'MarkerSize', 7, 'MarkerEdgeColor', 'black', 'LineWidth', 2); ...
            line(ax, nan, nan, 'LineStyle', 'none', 'Marker', 'd', ...
                'MarkerSize', 7, 'MarkerEdgeColor', 'black', 'LineWidth', 2); ...
            line(ax, nan, nan, 'Color', 'b', 'LineWidth', 2); ...
            line(ax, nan, nan, 'Color', 'r', 'LineWidth', 2); ...
            line(ax, nan, nan, 'Color', 'g', 'LineWidth', 2)], ...
            {'Reward 2 drops', 'Reward 4 drops', 'Reward 6 drops', ...
            'Delay Short (1s)', 'Delay Medium (5s)', 'Delay Long (10s)'}, ...
            'Location', 'southeast', 'Box', 'off'));
    end
    plt.setfig_ax('ylabel', 'Accept Rate (%)', 'xlabel', 'Discounted Value', 'ylim', [0 1], ...
        'ytick', [0:.1:1], 'title', plt.custom_vars.name_monkeys(i), 'xlim', xlms{i});   
end
plt.addABCs('AB');
plt.update('behavior');
%% compute p(accept) separated by yellow/purple
c1 = W.cellfun_vertcat(@(g)W.cond_average_tab(g(g.cue1 == "yellow",:), 'condition', 'choice'), gs_all);
c2 = W.cellfun_vertcat(@(g)W.cond_average_tab(g(g.cue1 ~= "yellow",:), 'condition', 'choice'), gs_all);
%% t-test 
ps = [];
for i = 1:2
    g = gs_all{i};
    for c = 1:9
        tc = g.choice(g.condition == c);
        typ = g.cue1(g.condition == c) == "yellow";
        [ps(i, c)] = W.chi2ind_xy(tc, typ);
    end
end
ps = ps * 18;
W.save('../../TempData/behavior_pYP', 'ps', ps);
%% plot
drop = plt.custom_vars.drop;
delay = plt.custom_vars.delay;
plt.figure(1,2, 'is_title', 'all', 'gapW_custom', [0 0 4]);
for i = 1:2
    plt.ax(1, i);
    av = [c1.avCHOICE(i,:); c2.avCHOICE(i,:)];
    se = [c1.seCHOICE(i,:); c2.seCHOICE(i,:)];
    [~, tid] = sort(c0.avCHOICE(i, :));
    plt.plot(1:length(tid), av(:, tid), se(:, tid), 'bar', 'color', {'yellow','magenta'});
    plt.sigstar(1:length(tid), mean(av(:, tid)), ps(i,tid))
    plt.setfig_ax('xlabel', '', 'ylabel', 'Accept Rate (%)', ...
        'xlim', [0 10], 'xtick', 1:9, ...
        'xticklabel', W.arrayfun(@(x)sprintf('%d\\newline%d', drop(x), delay(x)), tid, false), ...
        'title', plt.custom_vars.name_monkeys(i));
    if i == 2
        plt.setfig_ax('legend', {'yellow 1st', 'purple 1st'}, ...
        'legloc', 'SEO');
    end
end
plt.addABCs('AB');
plt.update('behavior_YP');
%% model comparison
d = W.load('../../TempData/modelfit_session');
aic = W.cellfun(@(x)x.aic, d);
ll = W.cellfun(@(x)x.LL, d);
% bic = W.cellfun_horzcat(@(x)[x.model_base.bic;x.model_YP_time.bic;x.model_YP.bic], d);
%%
plt.figure(2,2);
xname = ["Model1", "Model1t", "Model2", "Model2t", "Model3", "Model3t"];
animals = ["S", "T"];
for ai = 1:2
    id = session.animal == animals(ai);
    daic = aic(:, id)';
    nmd = size(daic, 2);

    plt.ax(ai);
    [av, se] = W.avse(daic);
    plt.plot(1:nmd, av, se, 'bar', 'color', 'black');
    plt.setfig_ax('xtick', 1:nmd, 'xticklabel', xname, 'ylabel', 'AIC');

    plt.ax(ai+2);
    [~, best_model] = min(daic, [], 2);
    p_best = W.count_cond(best_model, 1:nmd);
    p_best = p_best ./ sum(p_best);
    plt.plot(1:nmd, p_best, [], 'bar', 'color', 'black');
    plt.setfig_ax('xtick', 1:nmd, 'xticklabel', xname, ...
        'ylabel', 'p(best fit)', 'ylim', [0 1]);
end
plt.setfig([1 2], 'title', W.str2cell(plt.custom_vars.name_monkeys));
plt.addABCs('ABCD');
plt.update('model comparison');

%% posterior checks
% drop = plt.custom_vars.drop;
% delay = plt.custom_vars.delay;
% model_rows = [2 4 6];
% is_yellow_first = [true false];
% plt.figure(3,2, 'is_title', 'all', 'gapW_custom', [1 0 4]);
% for i = 1:2
%     session_ids = find(session.animal == animals(i));
%     for j = 1:3
%         plt.ax(j, i);
%         av = [c1.avCHOICE(i,:); c2.avCHOICE(i,:)];
%         se = [c1.seCHOICE(i,:); c2.seCHOICE(i,:)];
%         [~, tid] = sort(c0.avCHOICE(i, :));
%         plt.plot(1:length(tid), av(:, tid), se(:, tid), 'bar', 'color', {'yellow','magenta'});
% 
%         session_pred_accept = nan(2, length(drop), length(session_ids));
%         for sessioni = 1:length(session_ids)
%             model_fit = d{model_rows(j), session_ids(sessioni)};
%             for orderi = 1:2
%                 for condi = 1:length(drop)
%                     model_data = struct('drop', drop(condi), ...
%                         'delay', delay(condi), ...
%                         'is_yellow_1st', is_yellow_first(orderi));
%                     cp = model_fit.model.policy( ...
%                         model_fit.model.params, struct, model_data);
%                     session_pred_accept(orderi, condi, sessioni) = cp(2);
%                 end
%             end
%         end
%         pred_accept = mean(session_pred_accept, 3);
%         plt.plot(1:length(tid), pred_accept(:, tid), [], 'line', ...
%             'color', {'red', [1 0.5 0]}, 'LineWidth', 2);
% 
%         plt.setfig_ax('xlabel', '', ...
%             'xlim', [0 10], 'xtick', 1:9, ...
%             'xticklabel', W.arrayfun(@(x)sprintf('%d\\newline%d', drop(x), delay(x)), tid, false));
%         if j == 1
%             plt.setfig_ax('title', plt.custom_vars.name_monkeys(i));
%         end
%         if i == 1
%             plt.setfig_ax('ylabel', {sprintf('Model %d', j), 'Accept Rate (%)'});
%         end
%         if i == 2 && j == 3
%             plt.setfig_ax('legend', {'yellow 1st', 'purple 1st', "yellow 1st (model)", "purple 1st (model)"}, ...
%                 'legloc', 'SEO');
%         end
%     end
% end
% plt.update('behavior_YP_posteriorchecks');

%% posterior checks, with inferred value
drop = plt.custom_vars.drop;
delay = plt.custom_vars.delay;
model_rows = [1 2; 3 4; 5 6];
is_yellow_first = [true false];
observed_accept = nan(2, length(drop), 2);
for animali = 1:2
    animal_sessions = gs{animali};
    for orderi = 1:2
        for condi = 1:length(drop)
            session_accept = nan(length(animal_sessions), 1);
            session_n = zeros(length(animal_sessions), 1);
            for sessioni = 1:length(animal_sessions)
                g_session = animal_sessions{sessioni};
                trial_id = g_session.condition == condi & ...
                    g_session.is_yellow_1st == is_yellow_first(orderi) & ...
                    ~isnan(g_session.choice);
                session_n(sessioni) = sum(trial_id);
                if session_n(sessioni) > 0
                    session_accept(sessioni) = ...
                        mean(g_session.choice(trial_id));
                end
            end
            valid_sessions = session_n > 0;
            observed_accept(animali, condi, orderi) = ...
                sum(session_accept(valid_sessions) .* ...
                session_n(valid_sessions)) ./ ...
                sum(session_n(valid_sessions));
        end
    end
end
group_title_fontsize = plt.param_plt.fontsize_title;

plt.figure(3, 4, 'is_title', 'all', ...
    'gapH_custom', [2 0 0 0], ...
    'gapW_custom', [0 0 2 0 0]);
for modeli = 1:3
    for variant = 1:2
        for animali = 1:2
            axi = (animali - 1)*2 + variant;
            plt.ax(modeli, axi);
            model_row = model_rows(modeli, variant);
            model_fit = xfit{model_row, animali};
            p = model_fit.params_table;
            value_diff = nan(2, length(drop));

            for orderi = 1:2
                for condi = 1:length(drop)
                    R = drop(condi);
                    D = delay(condi);
                    discount = @(value, time)value ./ (1 + p.k .* time);

                    switch model_row
                        case 1  % Model1
                            value_reject = p.thres;
                            value_accept = discount(R, D);
                        case 2  % Model1t
                            value_reject = p.thres;
                            value_accept = discount(R, D) + ...
                                discount(p.thres, D);
                        case 3  % Model2
                            bias = p.biasYP;
                            if ~is_yellow_first(orderi)
                                bias = -bias;
                            end
                            value_reject = p.thres;
                            value_accept = discount(R, D) + bias;
                        case 4  % Model2t
                            bias = p.biasYP;
                            if ~is_yellow_first(orderi)
                                bias = -bias;
                            end
                            value_reject = p.thres;
                            value_accept = discount(R, D) + ...
                                discount(p.thres, D) + bias;
                        case 5  % Model3
                            if is_yellow_first(orderi)
                                value_reject = p.value_future;
                                value_accept = discount(R, D + p.timeYP);
                            else
                                value_reject = discount( ...
                                    p.value_future, p.timeYP);
                                value_accept = discount(R, D);
                            end
                        case 6  % Model3t
                            if is_yellow_first(orderi)
                                value_reject = p.value_future;
                                value_accept = discount(R, D + p.timeYP) + ...
                                    discount(p.value_future, D + p.timeYP);
                            else
                                value_reject = discount( ...
                                    p.value_future, p.timeYP);
                                value_accept = discount(R, D) + ...
                                    discount(p.value_future, D);
                            end
                    end
                    value_diff(orderi, condi) = ...
                        value_accept - value_reject;
                end
            end

            x_min = min([value_diff(:); 0]);
            x_max = max([value_diff(:); 0]);
            x_span = x_max - x_min;
            if x_span == 0
                x_span = 1;
            end
            xlims = [x_min - 0.05*x_span, x_max + 0.05*x_span];
            xs = linspace(xlims(1), xlims(2), 501);
            pred_accept = arrayfun(@(x)W.col_select( ...
                W_RL.softmax_binary(0, x, p.beta), 2), xs);

            plt.plot(xs, pred_accept, [], 'line', ...
                'color', 'black', 'LineWidth', 2);
            observed_panel = [observed_accept(animali,:,1); ...
                observed_accept(animali,:,2)];
            plt.plot(value_diff', observed_panel', [], 'line', ...
                'color', 'gray', 'LineStyle', '--', ...
                'LineWidth', 1, 'addtolegend', 0);
            plt.plot(value_diff(1,:), observed_panel(1,:), [], 'line', ...
                'color', 'yellow', 'LineStyle', 's', ...
                'MarkerSize', 7, 'LineWidth', 1.5, ...
                'is_hollow_dot', true);
            plt.plot(value_diff(2,:), observed_panel(2,:), [], 'line', ...
                'color', [0.5 0 0.5], 'LineStyle', 'o', ...
                'MarkerSize', 7, 'LineWidth', 1.5, ...
                'is_hollow_dot', true);

            model_name = sprintf('Model %d', modeli);
            if variant == 2
                model_name = sprintf('Model %dt', modeli);
            end
            model_title = sprintf( ...
                '%s, LL = %.3f', model_name, model_fit.LL);
            xlabel_text = '';
            if modeli == 3
                xlabel_text = 'V_{accept} - V_{reject}';
            end
            ylabel_text = '';
            if ismember(axi, [1 3])
                ylabel_text = 'p(accept)';
            end
            plt.setfig_ax('xlabel', xlabel_text, ...
                'ylabel', ylabel_text, 'xlim', xlims, 'ylim', [0 1], ...
                'ytick', 0:0.2:1, 'title', model_title);
            if modeli == 3 && variant == 2 && animali == 2
                plt.setfig_ax('legend', ...
                    {'Model softmax', 'Yellow offer', 'Purple offer'}, ...
                    'legloc', 'SE');
            end
        end
    end
end
plt.matlab(@()annotation(gcf, 'textbox', [0.05 0.965 0.40 0.025], ...
    'String', 'Monkey S', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontSize', group_title_fontsize, 'FontWeight', 'normal'));
plt.matlab(@()annotation(gcf, 'textbox', [0.55 0.965 0.40 0.025], ...
    'String', 'Monkey T', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontSize', group_title_fontsize, 'FontWeight', 'normal'));
plt.update('behavior_inferred_value');
