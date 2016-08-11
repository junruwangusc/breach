%% Analysis of a simple Neural-Network based controller. 

%% Model and inputs
u_ts = 0.001;
mdl = 'narmamaglev_v1';
B = BreachSimulinkSystem(mdl); 
B.SetTime(0:.01:20);

%% One simulation
B.SetInputGen('UniStep4');
B.SetParam({'Ref_u0','Ref_u1','Ref_u2','Ref_u3'}, [1 2 0.8 1.7]);
B.Sim();B.PlotSignals();
figure; hold on; grid on;
B.PlotExpr({'Ref[t]','Pos[t]', 'abs(Ref[t]-Pos[t])'}); legend({'Ref[t]','Pos[t]', 'abs(Ref[t]-Pos[t])'});

%% Checking specifications
STL_ReadFile('NNspecs.stl');
B.PlotRobustSat(reach_ref_in_tau);

%% Changing specification
B.SetParam('tau', 0.5)
B.PlotRobustSat(reach_ref_in_tau);

%% Learning tau
pb_tau = ParamSynthProblem(B, alw_reach_ref_in_tau, 'tau', [0.5 2]);
pb_tau.solve();

%% Simple family of signals: constant, systematic simulations
B.SetInputGen('UniStep1');
B.SetParamRanges('Ref_u0', [-1 4]);
B.GridSample(20);
B.Sim();
figure; hold on; grid on;
B.PlotExpr({'abs(Ref[t]-Pos[t])'}); 
title('abs(Ref[t]-Pos[t])');

%% Guess valid input range
B.SetParam('tau', 2)
B.CheckSpec(alw_reach_ref_in_tau);
B.PlotParams()

%% Larger class of signals 
u_min = 1;
u_max = 3; 
B.SetInputGen('UniStep3');
B.SetParamRanges({'Ref_u0','Ref_u1','Ref_u2'}, [u_min u_max; u_min u_max; u_min u_max]);
B.QuasiRandomSample(10); B.Sim(); B.PlotSignals({'Ref', 'Pos'}); 
figure; hold on; grid on;
B.PlotExpr('abs(Ref[t]-Pos[t])'); title('abs(Ref[t]-Pos[t])');

%% Checks for all 
B.CheckSpec(alw_reach_ref_in_tau);
B.PrintAll()


%% Design decision
B.SetInputGen('UniStep2');B.SetParam({'Ref_u0','Ref_u1'}, [3 1]);
B.SetParamRanges({'u_ts'}, [0.001 0.1]);
B.GridSample(20); B.Sim();
B.CheckSpec(alw_reach_ref_in_tau); B.PlotParams();