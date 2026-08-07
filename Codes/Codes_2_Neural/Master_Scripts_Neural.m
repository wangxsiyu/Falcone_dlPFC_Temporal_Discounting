run('../W_setup.m')
data = W.load('../../TempData/data');
cue = data.cue;
go = data.go;
timeat = cue{1}.time_at;
ntime = length(timeat);
session = data.cue{1}.info_session.info_combinedsessions;
games = data.cue{1}.games;
games = {games(session.animal == "S"), games(session.animal == "T")};
games_all = {vertcat(games{1}{:}), vertcat(games{2}{:})};

plt = SW_plt_from_yml('../fig.yml');
plt.S_colors.RSpurple = [0.55 0.25 0.72];
plt.S_colors.RSyellow = [0.90 0.65 0.05];
plt.overwrite_on;
tlt = plt.custom_vars.name_monkeys;
%% main_ANOVA
main_ANOVA;
%% Figure ANOVA
Figure_ANOVA_CUE;
Figure_ANOVA_GO;
%% decoding analysis
main_decoding_analysis;
Figure_decoding;
%% Revision R1 - decoding (separately for two arrays in Monkey S)
main_decoding_analysis_MonkeyS_twoarray;
Figure_decoding_MonkeyS_twoarray;
%% identify drop/delay coding dimensions
rng(20260806, 'twister');
coding_dimensions_dropdelay(cue, 'coding_dimensions', 0);
% figure coding dimensions
Figure_coding_dimensions(plt, 'coding_dimensions', 5); % plot first 5 bins
%% identify GO-locked drop/delay coding dimensions
rng(20260806, 'twister');
coding_dimensions_dropdelay(go, 'coding_dimensions_GO', 0);
%% figure GO-locked coding dimensions
Figure_coding_dimensions(plt, 'coding_dimensions_GO', 1); % hard coded - GO time
Figure_coding_dimensions(plt, 'coding_dimensions_GO', 2); % plot first 2 bins
%% Geometrical figures
Figure_Geometry_PCA;
%% projection onto Y/P, motor, value, axis
% plot all trials, plot trials matching "motor" for Y/P cues
axes_value = coding_dimension_value(go, 'valueGO', []);
axes_YP = coding_dimension_YP(go, 'YP', []);
% separation_YP = separation_dimension_YP(go, 'sepYP', []);

projections = projection_to_axes(axes_value, go, 'proj_valueGO');
projections1 = projection_to_axes(axes_value, go, 'proj_valueGO1', [], [], {[-250 0]});
projections_YP = projection_to_axes(axes_YP, go, 'proj_YP', {'YP', 'motor'});
% projections_sepYP = projection_to_axes(separation_YP, go, 'proj_sepYP', {'YP', 'motor'});
% plot_projections_conditionaverages(plt, projections, projections_YP);
%% align value/drop, delay 
Figure_align_value_dropdelay;
%% Figure Y/P
Figure_YP;
%% reproduce Rossella rasterplot
rasters_plots_ORDERED;
