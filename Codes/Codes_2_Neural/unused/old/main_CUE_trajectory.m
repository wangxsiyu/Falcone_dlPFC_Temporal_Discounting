data = W.load('../../TempData/data');
cue = data.cue;
god = data.go;
cue{3} = W.format_combinecells(cue);
plt = SW_plt_from_yml('../fig.yml');
drop = plt.custom_vars.drop;
delay = plt.custom_vars.delay;
timeat = cue{1}.time_at;
ntime = length(timeat);
tlt = {'Monkey 1', 'Monkey 2', 'all data'};
%%
tid = timeat >= 0 & timeat <= 1000;
%% compute population trajectory
pc = {};
pcgo = {};
pcgoY = {};
pcgoP = {};
dvs = {};
for ai = 1:2
    cs = cue{ai}.cells;
    gos = god{ai}.cells;
    gs = W.arrayfun(@(x)cue{ai}.games{x},cue{ai}.info_cells.gameID)';
    nc = length(cs);
    av = cell(1, nc);
    avgo = cell(1, nc);
    avgoY = cell(1, nc);
    avgoP = cell(1, nc);
    dv = cell(1, nc);
    for ci = 1:nc
        c = cs{ci};
        cg = gos{ci};
        g = gs{ci};
        av{ci} = W.cond_average(c, g.condition,1:9);
        avgo{ci} = W.cond_average(cg, g.condition,1:9);
        avgoY{ci} = W.cond_average(cg(g.cue1 == "yellow",:), g.condition(g.cue1 == "yellow"),1:9);
        avgoP{ci} = W.cond_average(cg(g.cue1 == "purple",:), g.condition(g.cue1 == "purple"),1:9);
        dv{ci} = W.cond_average(g.DV, g.condition, 1:9);
    end
    dvs{ai} = mean(vertcat(dv{:}));
    % find population activity per cond
    pp = W.cell_transpose(W.cell_NxMK2KxMN(W.cell_transpose(av)));
    ppgo = W.cell_transpose(W.cell_NxMK2KxMN(W.cell_transpose(avgo)));
    ppgoY = W.cell_transpose(W.cell_NxMK2KxMN(W.cell_transpose(avgoY)));
    ppgoP = W.cell_transpose(W.cell_NxMK2KxMN(W.cell_transpose(avgoP)));
    % find PCA space
    tpp = W.cellfun(@(x)x(:, tid),pp);
    alld = horzcat(tpp{:});
    tppgo = W.cellfun(@(x)x(:, tid),ppgo);
    alldgo = horzcat(tppgo{:});
    pcinfo = W.pca(alld');
    pcinfogo = W.pca(alldgo');
    %% project to pca
    pc{ai} = W.cellfun(@(x)W.pca_project(pcinfo, x', 10), pp);
    pcgo{ai} = W.cellfun(@(x)W.pca_project(pcinfogo, x', 10), ppgo);
    pcgoY{ai} = W.cellfun(@(x)W.pca_project(pcinfogo, x', 10), ppgoY);
    pcgoP{ai} = W.cellfun(@(x)W.pca_project(pcinfogo, x', 10), ppgoP);
end
%%
%% plot first 10 pc
% plt = S_plt;
% plt.figure(3,4);
% for i = 1:10
%     plt.ax(i);
%     te = W.cellfun_vertcat(@(x)x(tid, i)', pc);
%     plt.plot([], te, [], 'line', 'color', cols);
% end
%% plot 3d 3pc
plt.figure(2,2);
for ai = 1:2
    tid1 = timeat >= 0 & timeat <= 1000;
    plt.ax(1,ai);
    cc = W.cond_average_tab(gs{1}, {'condition'}, {'choice','DV','drop', 'delay'});
    dv = dvs{ai};
    [~, od] = sort(dv);
    cols = W.arrayfun(@(x)plt.interpolatecolors({'RSred', 'yellow', 'RSgreen'}, [min(dv), dv(od(5)), max(dv)], x), dv);
    x = {};
    for i = 1:3
        x{i} = W.cellfun_vertcat(@(x)W.smooth1d([],x(tid1, i)',5), pc{ai});
    end
    plt.plot3(x{1},x{2},x{3}, 'color', cols);
    % plt.plot(x{1},x{2},[],'line', 'color', cols);


    tid2 = timeat >= -500 & timeat <= 500;
    plt.ax(2,ai);
    x = {};
    for i = 1:3
        x{i} = W.cellfun_vertcat(@(x)W.smooth1d([],x(tid2, i)',5), pcgo{ai});
    end
    plt.plot3(x{1},x{2},x{3}, 'color', cols);


    % tid2 = timeat >= 0 & timeat <= 500;
    % plt.ax(3,ai);
    % x = {};
    % for i = 1:3
    %     x{i} = W.cellfun_vertcat(@(x)W.smooth1d([],x(tid2, i)',5), pcgoY{ai});
    % end
    % plt.plot3(x{1},x{2},x{3}, 'color', cols);
    % % plt.plot(x{1},x{2},[],'line', 'color', cols);
    % 
    % 
    % tid2 = timeat >= 0 & timeat <= 500;
    % plt.ax(4,ai);
    % x = {};
    % for i = 1:3
    %     x{i} = W.cellfun_vertcat(@(x)W.smooth1d([],x(tid2, i)',5), pcgoP{ai});
    % end
    % plt.plot3(x{1},x{2},x{3}, 'color', cols);
end
plt.unify_lims({[1 1],[2 1]}, {[1 1],[2 1]})
plt.unify_lims({[1 2],[2 2]}, {[1 2],[2 2]})
plt.update;

%%

%% plot 3d 3pc
plt.figure(2,2);
for ai = 1:2
    cols = W.arrayfun(@(x)plt.interpolatecolors({'RSred', 'yellow', 'RSgreen'}, [1 5 9], x), 1:9);
    cols2 = W.cellfun(@(x)(x + [1 1 1])/2, cols);
    [~, tid] = sort(c0.avCHOICE(ai, :));

    tid2 = timeat >= -500 & timeat <= 0;
    plt.ax(1,ai);
    x = {};
    for i = 1:3
        x{i} = W.cellfun_vertcat(@(x)W.smooth1d([],x(tid2, i)',5), pcgoY{ai}(tid));
    end
    plt.plot3(x{1},x{2},x{3}, 'color', cols);
    x = {};
    for i = 1:3
        x{i} = W.cellfun_vertcat(@(x)W.smooth1d([],x(tid2, i)',5), pcgoP{ai}(tid));
    end
    plt.plot3(x{1},x{2},x{3}, 'color', cols2);


    tid2 = timeat >= 0 & timeat <= 500;
    plt.ax(2,ai);
    x = {};
    for i = 1:3
        x{i} = W.cellfun_vertcat(@(x)W.smooth1d([],x(tid2, i)',5), pcgoY{ai}(tid));
    end
    plt.plot3(x{1},x{2},x{3}, 'color', cols);
    x = {};
    for i = 1:3
        x{i} = W.cellfun_vertcat(@(x)W.smooth1d([],x(tid2, i)',5), pcgoP{ai}(tid));
    end
    plt.plot3(x{1},x{2},x{3}, 'color', cols2);
end
plt.update;
%% 
%% compute choice curve, and condition means
session = data.cue{1}.info_session.info_combinedsessions;
gs = data.cue{1}.games;
gs = {gs(session.animal == "S"), gs(session.animal == "T")};
gs_all = {vertcat(gs{1}{:}), vertcat(gs{2}{:})};
c0 = W.cellfun_vertcat(@(g)W.cond_average_tab(g, 'condition', 'choice'), gs_all);
v1 = W.cellfun_vertcat(@(g)W.cond_average_tab(g, 'condition', 'DV'), gs_all);
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
%%
plt.figure(2, 2);
for ai = 1:2    
    dv = dvs{ai};
    [~, od] = sort(dv);
    % cols = W.arrayfun(@(x)plt.interpolatecolors({'RSred', 'yellow', 'RSgreen'}, [min(dv), dv(od(5)), max(dv)], x), dv);
  
    
    cols = W.arrayfun(@(x)plt.interpolatecolors({'RSred', 'yellow', 'RSgreen'}, [1 5 9], x), 1:9);
    cols2 = W.cellfun(@(x)(x + [1 1 1])/2, cols);
    
    plt.ax(1, ai);
    av = [c1.avCHOICE(ai,:); c2.avCHOICE(ai,:)];
    se = [c1.seCHOICE(ai,:); c2.seCHOICE(ai,:)];
    [~, tid] = sort(c0.avCHOICE(ai, :));


    for i = 1:9
        plt.plot(i, av(:, tid(i)), se(:, tid(i)), 'bar', 'color', {cols{i}, cols2{i}});
    end
    plt.sigstar(1:length(tid), mean(av(:, tid)), ps(ai,tid))
    plt.setfig_ax('xlabel', '', 'ylabel', 'Accept Rate (%)', ...
        'xlim', [0 10], 'xtick', 1:9, ...
        'xticklabel', W.arrayfun(@(x)sprintf('%d\\newline%d', drop(x), delay(x)), tid, false));
    if ai == 2
        plt.setfig_ax('legend', {'yellow 1st', 'purple 1st'}, ...
            'legloc', 'SEO');
    end
    
    
    
    
    
    
    
    
    idpre = timeat >= -400 & timeat <= -200;
    idpost = timeat >= 200 & timeat <= 400;
    x = {};
    for i = 1:3
        x{i} = [W.cellfun(@(x)mean(x(idpre, i)'), pcgo{ai}); ...
            W.cellfun(@(x)mean(x(idpre, i)'), pcgoY{ai}); ...
            W.cellfun(@(x)mean(x(idpre, i)'), pcgoP{ai})];
    end



    plt.ax(2, ai);
    plt.plot3(x{1}([1 2],tid)',x{2}([1 2],tid)',x{3}([1 2],tid)', 'color', cols);
    

    plt.plot3(x{1}([1 3],tid)',x{2}([1 3],tid)',x{3}([1 3],tid)', 'color', cols2);
end
plt.update;
