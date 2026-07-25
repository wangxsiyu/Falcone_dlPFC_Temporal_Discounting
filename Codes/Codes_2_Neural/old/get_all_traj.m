function alltraj = get_all_traj(d)
    ncell = length(d.cells);
    traj = cell(1, ncell);
    for i = 1:ncell
        tcell = d.cells{i};
        tg = d.games{d.info_cells.gameID(i)};
        traj{i} = W.arrayfun_vertcat(@(x)W.avse(tcell(tg.condition == x, :)), 1:9);
    end
    alltraj = W.cell_transpose(W.cell_NxMK2KxMN(W.cellfun(@(x)x',traj)));
end