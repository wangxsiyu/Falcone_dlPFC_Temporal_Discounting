function Figure_behavior_purpleyellow(plt, games_all)
    %% compute p(accept) separated by yellow/purple    
    c0 = W.cellfun_vertcat(@(g)W.cond_average_tab(g, 'condition', 'choice'), games_all);
    c1 = W.cellfun_vertcat(@(g)W.cond_average_tab(g(g.cue1 == "yellow",:), 'condition', 'choice'), games_all);
    c2 = W.cellfun_vertcat(@(g)W.cond_average_tab(g(g.cue1 ~= "yellow",:), 'condition', 'choice'), games_all);
    %% t-test 
    ps = [];
    for i = 1:2
        g = games_all{i};
        for c = 1:9
            tc = g.choice(g.condition == c);
            typ = g.cue1(g.condition == c) == "yellow";
            [ps(i, c)] = W.chi2ind_xy(tc, typ);
        end
    end
    ps = ps * 18;
    % W.save('../../TempData/behavior_pYP', 'ps', ps);
    %% plot
    drop = plt.custom_vars.drop;
    delay = plt.custom_vars.delay;
    plt.figure(1,2, 'is_title', 'all', 'gapW_custom', [0 0 3]);
    for i = 1:2
        plt.ax(1, i);
        av = [c1.avCHOICE(i,:); c2.avCHOICE(i,:)];
        se = [c1.seCHOICE(i,:); c2.seCHOICE(i,:)];
        [~, tid] = sort(c0.avCHOICE(i, :));
        plt.plot(1:length(tid), av(:, tid), se(:, tid), 'bar', 'color', {'yellow','magenta'});
        plt.sigstar(1:length(tid), mean(av(:, tid)), ps(i,tid))
        plt.setfig_ax('xlabel', '', 'ylabel', 'Acceptance Rate (%)', ...
            'xlim', [0 10], 'xtick', 1:9, ...
            'xticklabel', W.arrayfun(@(x)sprintf('%d\\newline%d', drop(x), delay(x)), tid, false), ...
            'title', plt.custom_vars.name_monkeys(i), ...
            'ytick', [0:.1:1], 'yticklabel', [0:10:100]);
        plt.matlabax(@(~)text(0.03, -0.070, 'Drop', ...
            'Units', 'normalized', 'FontSize', get(gca, 'FontSize'), ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
            'Clipping', 'off'));
        plt.matlabax(@(~)text(0.03, -0.135, 'Delay', ...
            'Units', 'normalized', 'FontSize', get(gca, 'FontSize'), ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
            'Clipping', 'off'));
        if i == 2
            plt.setfig_ax('legend', {'yellow 1st', 'purple 1st'}, ...
            'legloc', 'SEO');
        end
    end
    plt.addABCs('AB');
    plt.update('behavior_YP');
end
