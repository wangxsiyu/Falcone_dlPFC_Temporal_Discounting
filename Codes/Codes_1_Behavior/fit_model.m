function xfit = fit_model(md, R, D, Y, nA, nT)
%FIT_MODEL Fit one choice model using multi-start maximum likelihood.
    parameter_names = md.name_parameters;
    nparams = length(parameter_names);
    nstarts = 10;
    bound_inf = 10;

    assert(isequal(size(R), size(D), size(Y), size(nA), size(nT)), ...
        'R, D, Y, nA, and nT must have identical sizes.');
    assert(all(nA >= 0 & nA <= nT), ...
        'nA must be between zero and nT for every condition.');
    n_observations = sum(nT, 'all');
    assert(isfinite(n_observations) && n_observations > 0, ...
        'The total number of observations must be positive and finite.');

    loss = @(params)LL(params, md, R, D, Y, nA, nT);
    lower_bounds = zeros(1, nparams);
    upper_bounds = bound_inf*ones(1, nparams);

    is_bias = strcmp(parameter_names, 'biasYP');
    lower_bounds(is_bias) = -bound_inf;
    
    start_points = lower_bounds + ...
        rand(nstarts, nparams).*(upper_bounds - lower_bounds);
    start_points(1, :) = ones(1, nparams);
    start_points(1, is_bias) = 0;
    start_points(1, strcmp(parameter_names, 'timeYP')) = 0.5;
    start_points(1, :) = min(max(start_points(1, :), ...
        lower_bounds), upper_bounds);
    assert(isfinite(loss(start_points(1, :))), ...
        'Initial loss is not finite for %s.', class(md));

    fit_options = optimoptions('fmincon', ...
        'Algorithm', 'interior-point', ...
        'Display', 'off', ...
        'MaxIterations', 1000, ...
        'MaxFunctionEvaluations', 1e4);
    best_loss = inf;
    best_params = nan(1, nparams);
    best_exitflag = NaN;
    best_output = struct;
    for starti = 1:nstarts
        [params, fitted_loss, exitflag, output] = fmincon( ...
            loss, start_points(starti, :), [], [], [], [], ...
            lower_bounds, upper_bounds, [], fit_options);
        if isfinite(fitted_loss) && fitted_loss < best_loss
            best_loss = fitted_loss;
            best_params = params;
            best_exitflag = exitflag;
            best_output = output;
        end
    end

    assert(isfinite(best_loss), ...
        'No finite fit was found for %s.', class(md));
    if best_exitflag <= 0
        warning('Model %s did not converge: %s', ...
            class(md), best_output.message);
    end

    xfit = cell2struct(num2cell(best_params), parameter_names, 2);
    xfit.LL = -best_loss;
    xfit.AIC = 2*nparams - 2*xfit.LL;
    xfit.BIC = nparams*log(n_observations) - 2*xfit.LL;
end
