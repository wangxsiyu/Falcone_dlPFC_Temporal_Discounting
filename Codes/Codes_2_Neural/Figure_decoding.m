results = W.load('../../TempData/decoding');
plt.figure(3,2, 'is_title', 'all')
for ai = 1:2
    r0 = results{ai};
    r = cell(1,3);
    r{1} = W.cellfun_vertcat(@(x)x.r_delay.ac_decode, r0);
    r{2} = W.cellfun_vertcat(@(x)x.r_drop.ac_decode, r0);
    r{3} = W.cellfun_vertcat(@(x)x.r_interaction.ac_decode, r0);
    chance = [1/3, 1/3, 1/9];
%     tlt = {'drop', 'delay', 'Drop x Delay'};
    for i = 1:3
        plt.ax(i, ai);
        [av, se] = W.avse(r{i});
        plt.plot(timeat, av, se, 'shade', 'color', plt.custom_vars.color_anova{i});
        plt.dashX(chance(i));
        plt.dashY(0, [0 1]);
        plt.setfig_ax('xlabel', 'time (ms)', 'ylabel', 'decoding accuracy', 'title', tlt{ai}, ...
            'xlim', [-500 1000]);
        if i == 3
            [av1, se1] = W.avse(r{1}.*r{2});
            [p] = W.stat_ttest(r{1}.*r{2}, r{3});
            tid = find(timeat > -500 & timeat < 1000);
            plt.plot(timeat, av1, se1, 'shade', 'color', 'black');
            plt.sigstar(timeat(tid), av(tid) + se(tid) + 0.01, p(tid), 'dx', 25)
            plt.setfig_ax('legend', {'data','independence'}, 'ylim', [0 1]);
        else
            plt.setfig_ax('ylim', [0 1]);
        end
    end
end

for axi = 1:6
    plt.ax(axi);
    plt.matlabax(@(~)add_offer_onset_label());
end
plt.update('decode');

function add_offer_onset_label()
%ADD_OFFER_ONSET_LABEL Mark time zero below the current x-axis.
    ax = gca;
    x_limits = xlim(ax);
    y_limits = ylim(ax);
    label_y = y_limits(1) - 0.02*diff(y_limits);
    triangle_half_width = 0.012*diff(x_limits);
    triangle_height = 0.025*diff(y_limits);
    patch(ax, [-triangle_half_width triangle_half_width 0], ...
        [y_limits(1) - triangle_height, ...
        y_limits(1) - triangle_height, y_limits(1)], ...
        'black', 'EdgeColor', 'black', ...
        'Clipping', 'off');

    x_ticks = xticks(ax);
    x_tick_labels = string(xticklabels(ax));
    zero_tick = abs(x_ticks) < eps(max(abs(x_limits)));
    if numel(x_tick_labels) == numel(x_ticks)
        x_tick_labels(zero_tick) = "";
        xticklabels(ax, x_tick_labels);
    end

    text(ax, 0, label_y, sprintf('Offer\nOnset'), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'top', ...
        'FontSize', max(ax.FontSize - 2, 8), ...
        'Clipping', 'off');

    x_label = ax.XLabel;
    x_label.Units = 'normalized';
    x_label_position = x_label.Position;
    x_label_position(1) = 1;
    x_label.Position = x_label_position;
    x_label.HorizontalAlignment = 'right';
end
