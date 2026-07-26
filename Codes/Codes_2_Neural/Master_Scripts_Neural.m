data = W.load('../../TempData/data');
cue = data.cue;
go = data.go;
plt = SW_plt_from_yml('../fig.yml');
plt.overwrite_on;
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
main_coding_dimensions(cue, 'coding_dimensions');
%% figure coding dimensions
Figure_coding_dimensions(plt, 'coding_dimensions', 5); % plot first 5 bins
Figure_coding_dimensions(plt, 'coding_dimensions', 1); % hard coded, plot last bin
%% identify GO-locked drop/delay coding dimensions
main_coding_dimensions(go, 'coding_dimensions_GO');
%% figure GO-locked coding dimensions
Figure_coding_dimensions(plt, 'coding_dimensions_GO', 2); % plot first 2 bins
%% Geometrical figures
Figure_Geometry_PCA;
%% Yellow/Purple analysis
main_YP;