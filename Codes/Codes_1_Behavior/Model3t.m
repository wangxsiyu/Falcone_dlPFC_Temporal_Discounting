classdef Model3t < handle
    properties
        name_parameters
    end
    methods
        function obj = Model3t()
            obj.name_parameters = {'beta', 'k', 'thres', 'timeYP'};
        end
        function [v_accept, v_reject] = compVal(~, params, R, D, Y)
            k = params(2);
            thres = params(3);
            tYP = params(4);
            is_yellow = logical(Y);
            v_accept = compute_DV(R, D, k) + ...
                compute_DV(thres, D, k);
            v_reject = repmat(compute_DV(thres, tYP, k), size(R));
            v_accept(is_yellow) = compute_DV( ...
                R(is_yellow), D(is_yellow) + tYP, k) + ...
                compute_DV(thres, D(is_yellow) + tYP, k);
            v_reject(is_yellow) = thres;
        end
        function cp = policy(obj, params, varargin)
            [v_accept, v_reject] = obj.compVal(params, varargin{:});
            beta = params(1);
            cp = W_RL.softmax_binary(v_accept, v_reject, beta);
            cp = cp(:, 1);
        end
    end
end
