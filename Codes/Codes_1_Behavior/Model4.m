classdef Model4 < handle
    properties
        name_parameters
    end
    methods
        function obj = Model4()
            obj.name_parameters = {'beta', 'kD', 'thres', 'biasYP'};
        end
        function [v_accept, v_reject] = compVal(obj, params, R, D, Y)
            kD = params(2);
            thres = params(3);
            bias = sign(Y - 0.5) * params(4);
            v_accept = R + kD * D + bias;
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