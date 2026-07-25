classdef Model1 < handle
    properties
        name_parameters
    end
    methods
        function obj = Model1()
            obj.name_parameters = {'beta', 'k', 'thres'};
        end
        function [v_accept, v_reject] = compVal(obj, params, R, D, Y)
            k = params(2);
            thres = params(3);
            v_accept = compute_DV(R, D, k);
            v_reject = thres;
        end
        function cp = policy(obj, params, varargin)
            [v_accept, v_reject] = obj.compVal(params, varargin{:});
            beta = params(1);
            cp = W_RL.softmax_binary(v_accept, v_reject, beta);
            cp = cp(:, 1);
        end
    end
end