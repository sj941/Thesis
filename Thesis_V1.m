clear;
clc;

basef = fileparts(which('Thesis_V1.mod'));
% Step 1: Load Demand Data
input_file = 'Data_thesis.xlsx';



    PD = readmatrix(input_file, 'Range', 'B2:B49');  
    WP = readmatrix(input_file, 'Range', 'D52:D99');
    PV = readmatrix(input_file, 'Range', 'C2:C49');
% catch
%     PD = xlsread(input_file, 'Sheet1', 'B2:B49');  % You may need to adjust the sheet name
%     WP = xlsread(input_file, 'Sheet1', 'D52:D99');  % You may need to adjust the sheet name

N = length(PD);


% Step 2: Create AMPL data file
datFile = fullfile(basef, 'Thesis_V1.dat');
fid = fopen(datFile, 'w');

% Write set D
fprintf(fid, 'set D := ');
fprintf(fid, '%d ', 1:N);
fprintf(fid, ';\n');

% Write parameter Pd
fprintf(fid, 'param Pd :=\n');
for i = 1:N
    fprintf(fid, '%d %f\n', i, PD(i));
end
fprintf(fid, ';\n');

% Write parameter price
fprintf(fid, 'param price :=\n');
for i = 1:N
    fprintf(fid, '%d %f\n', i, WP(i));
end
fprintf(fid, ';\n');


% Write parameter PV
fprintf(fid, 'param PV :=\n');
for i = 1:N
    fprintf(fid, '%d %f\n', i, PV(i));
end
fprintf(fid, ';\n');
fclose(fid);

% Step 3: Call AMPL from MATLAB
ampl = AMPL(); % Create an AMPL instance
ampl.reset();
ampl.setOption('solver', 'gurobi');   % Set solver gurobi
ampl.eval('option version;');        % Show AMPL version


ampl.read(fullfile(basef, 'Thesis_V1.mod'));  % Read model

ampl.readData(fullfile(basef, 'Thesis_V1.dat'));  % Read data

ampl.solve();

% Step 4: Extract and plot grid_power

values = ampl.getVariable('grid_power').getValues();

indices_raw = cell2mat(values.getColumn('i1'));
grid_vals_raw = cell2mat(values.getColumn('val'));


price_data = ampl.getParameter('price').getValues();
price_data = cell2mat(price_data.getColumn('val'));

Bat_p = ampl.getVariable('discharge_rate').getValues();
Bat_p = cell2mat(Bat_p.getColumn('val'));

% WH_on = ampl.getVariable('hwh_on').getValues();
% WH_on = cell2mat(WH_on.getColumn('val'));

% AC_P = ampl.getVariable('ac_power').getValues();
% AC_P = cell2mat(AC_P.getColumn('val'));

% Plot
figure;
plot(indices_raw, [grid_vals_raw, PD, price_data/100,Bat_p],'LineWidth', 2);
xlabel('Time Period (half-hours)');
ylabel('Grid Power Usage (kW)');
title('Optimal Grid Power Usage Over 24 Hours');
legend("Grid usage", "Power Demand", "Electricity Price", "Battery Power", "Water Heater On", "PV", "AC_p")
grid on;
