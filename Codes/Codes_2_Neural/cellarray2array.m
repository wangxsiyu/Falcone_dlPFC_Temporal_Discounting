function outputArray = cellarray2array(cellArray)
    cellDims = size(cellArray);
    itemDims = size(cellArray{1});
    
    assert(all(cellfun(@(x) isequal(size(x), itemDims), ...
        cellArray), 'all'), ...
        'All cells must contain arrays of identical size.');
    
    flattened = cellfun(@(x)reshape(x, 1, []), ...
        cellArray, 'UniformOutput', false);
    
    outputArray = reshape(vertcat(flattened{:}), ...
        [cellDims, itemDims]);
    outputArray = squeeze(outputArray);
end