function [paccept] = compute_cond_vs_choice(g)
    offer_conditions = unique(g(:, {'drop', 'delay'}), ...
        'rows', 'stable');
    cue_order = ["yellow", "purple"];
    combination_id = W.combinations( ...
        1:height(offer_conditions), ...
        1:length(cue_order));

    paccept = offer_conditions(combination_id(:, 1), :);
    paccept.cue1 = W.vert(cue_order(combination_id(:, 2)));

    trial_id = W.tab_getcombinedID(g, ...
        {'drop', 'delay', 'cue1'});
    accept_id = W.tab_getcombinedID(g(g.choice == 1, :), ...
        {'drop', 'delay', 'cue1'});
    condition_id = W.tab_getcombinedID(paccept, ...
        {'drop', 'delay', 'cue1'});
    paccept.n_accept = W.vert(W.count_cond(accept_id, condition_id));
    paccept.n_total = W.vert(W.count_cond(trial_id, condition_id));

    paccept.p_accept = paccept.n_accept ./ paccept.n_total;
end
