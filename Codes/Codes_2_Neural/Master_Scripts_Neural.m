data = W.load('../../TempData/data');
cue = data.cue;
go = data.go;
session = data.cue{1}.info_session.info_combinedsessions;
games = data.cue{1}.games;
games = {games(session.animal == "S"), games(session.animal == "T")};
games_all = {vertcat(games{1}{:}), vertcat(games{2}{:})};
plt = SW_plt_from_yml('../fig.yml');
plt.overwrite_on;
tlt = plt.custom_vars.name_monkeys;
%% main_ANOVA
main_ANOVA;
%% Figure ANOVA
Figure_ANOVA_CUE;
Figure_ANOVA_GO;
%% decoding analysis
main_decoding_analysis;
%% Figure decoding
Figure_decoding;
%% identify drop/delay coding dimensions
coding_dimensions_dropdelay(cue, 'coding_dimensions', 0);
%% figure coding dimensions
Figure_coding_dimensions(plt, 'coding_dimensions', 5); % plot first 5 bins
Figure_coding_dimensions(plt, 'coding_dimensions_GO', 1); % hard coded - GO time
%% identify GO-locked drop/delay coding dimensions
coding_dimensions_dropdelay(go, 'coding_dimensions_GO', 0);
%% figure GO-locked coding dimensions
Figure_coding_dimensions(plt, 'coding_dimensions_GO', 2); % plot first 2 bins
%% Geometrical figures
Figure_Geometry_PCA;
%% value-axis
rng(0, 'twister');
% coding_dimensions_value;
coding_dimensions_valueGO;
%% Yellow/Purple analysis
main_projections_YP;
%% align value/drop, delay 
Figure_align_value_dropdelay;
%% Figure Y/P
Figure_YP;

%% unused
% %% reproduce Y/P axes alignment
% coding_dimensions_YP;
% Figure_align_value_YP;