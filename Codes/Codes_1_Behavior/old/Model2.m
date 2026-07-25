classdef Model2 < S_RL_model
    methods
        function obj = Model2()
            obj.name = "YP";
            obj.name_parameters = {'beta', 'k', 'thres', 'biasYP'};
            obj.X0 = [NaN, NaN, 0, 0];
            NMAX = inf;
            obj.LB = [0, 0, -NMAX, -NMAX];
            obj.UB = [NMAX, NMAX, NMAX, NMAX];
        end
        function [cp, LV] = policy(obj, params, LV, data)
            D = data.delay;
            R = data.drop;
            DV = R/(1 + params.k * D);
            if data.is_yellow_1st
                bias = params.biasYP;
            else
                bias = -params.biasYP;
            end
            cp = W_RL.softmax_binary_bias(params.thres, DV, params.beta, bias);
            LV.DV = DV;
        end
    end
end