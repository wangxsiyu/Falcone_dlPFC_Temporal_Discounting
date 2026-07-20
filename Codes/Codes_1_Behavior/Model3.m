classdef Model3 < S_RL_model
    methods
        function obj = Model3()
            obj.name_parameters = {'beta', 'k', 'value_future', 'timeYP'};
            obj.X0 = [NaN, NaN, 0, 0];
            NMAX = inf;
            obj.LB = [0, 0, -NMAX, -NMAX];
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
                V2 = VF; % reject in yellow
                V1 = func(R, D + tYP); % accept in purple
            else
                V2 = func(VF, tYP); % reject in yellow
                V1 = func(R, D); 
            end
            cp = W_RL.softmax_binary(V2, V1, params.beta);
        end
    end
end