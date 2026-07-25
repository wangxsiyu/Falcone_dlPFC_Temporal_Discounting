classdef Model3t < S_RL_model
    methods
        function obj = Model3t()
            obj.name_parameters = {'beta', 'k', 'value_future', 'timeYP'};
            obj.X0 = [NaN, NaN, 1e-5, 1e-5];
            NMAX = inf;
            obj.LB = [0, 0, 0, 0];
            obj.UB = [NMAX, NMAX, NMAX, NMAX];
        end
        function [cp, LV] = policy(obj, params, LV, data)
            VF = params.value_future;
            k = params.k;
            func = @(R, D) R/(1 + k * D);
            D = data.delay;
            R = data.drop;
            tYP = params.timeYP;
            if data.is_yellow_1st
                V2 = func(VF, 0); % reject in yellow
                V1_future = func(VF, D + tYP); % accept in purple
                V1_now = func(R, D + tYP); % accept in purple
            else
                V2 = func(VF, tYP); % reject in yellow
                V1_future = func(VF, D); % accept in purple
                V1_now = func(R, D); 
            end
            V1 = V1_now + V1_future;
            cp = W_RL.softmax_binary(V2, V1, params.beta);
        end
    end
end