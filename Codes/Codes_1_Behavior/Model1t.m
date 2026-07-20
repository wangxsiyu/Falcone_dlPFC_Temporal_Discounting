classdef Model1t < S_RL_model
    methods
        function obj = Model1t()
            obj.name_parameters = {'beta', 'k', 'thres'};
            obj.X0 = [NaN, NaN, 0];
            NMAX = inf;
            obj.LB = [0, 0, -NMAX];
            obj.UB = [NMAX, NMAX, NMAX];
        end
        function [cp, LV] = policy(obj, params, LV, data)
            D = data.delay;
            R = data.drop;
            k = params.k;
            VF = params.thres;
            func = @(R, D) R/(1 + k * D);
            DV = func(R, D);
            V2 = VF;
            V1 = DV + func(VF, D);
            cp = W_RL.softmax_binary(V2, V1, params.beta);
            LV.DV = DV;
        end
    end
end