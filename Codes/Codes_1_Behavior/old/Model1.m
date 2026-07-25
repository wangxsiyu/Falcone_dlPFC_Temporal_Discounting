classdef Model1 < S_RL_model
    methods
        function obj = Model1()
            obj.name_parameters = {'beta', 'k', 'thres'};
            obj.X0 = [NaN, NaN, 0];
            NMAX = inf;
            obj.LB = [0, 0, -NMAX];
            obj.UB = [NMAX, NMAX, NMAX];
        end
        function [cp, LV] = policy(obj, params, LV, data)
            D = data.delay;
            R = data.drop;
            DV = R/(1 + params.k * D);
            cp = W_RL.softmax_binary(params.thres, DV, params.beta);
            LV.DV = DV;
        end
    end
end