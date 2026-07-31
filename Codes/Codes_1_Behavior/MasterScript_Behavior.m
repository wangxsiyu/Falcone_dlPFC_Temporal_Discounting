%%
isoverwrite = false;
main_1_fitRL;
%%
main_2_computeDV;
%%
plt = SW_plt_from_yml('../fig.yml');
data = W.load('../../TempData/data');
session = data.cue{1}.info_session.info_combinedsessions;
games = data.cue{1}.games;
games = {games(session.animal == "S"), games(session.animal == "T")};
games_all = {vertcat(games{1}{:}), vertcat(games{2}{:})};
%%
xfit = W.load('../../TempData/modelfit_session');
xfit_all = W.load('../../TempData/modelfit_overall');
%% Figure 2
Figure_behavior_base(plt, games_all, xfit_all);
%% Figure 3
Figure_behavior_purpleyellow(plt, games_all);
%% Figure 4
Figure_model_comparison(plt, xfit, session);
%% Figure model parameters
Figure_model_parameters(plt, xfit, session);
%% Figure model posterior checks
Figure_model_posteriorchecks(plt, games_all, xfit_all);