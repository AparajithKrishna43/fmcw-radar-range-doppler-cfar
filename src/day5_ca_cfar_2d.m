%% Day 5 - 2D CA-CFAR across the full Range-Doppler map
%  Applies a 2D Cell-Averaging CFAR with a rectangular training ring and
%  guard band to every cell of the RDM, then verifies the false-alarm rate
%  on noise-only frames.

clear; clc; close all;
cfg = radar_config();
[targets, noiseStd] = default_scenario();

% CFAR window (cells on each side of the CUT)
Tr = 10;  Td = 6;      % training: range / Doppler
Gr = 3;   Gd = 3;      % guard:    range / Doppler
Pfa = 1e-6;            % ~0.03 false alarms per 32k-cell frame

rng(42);
ifSig = generate_fmcw_if(cfg, targets, noiseStd);
[rdm, rangeAxis, velAxis] = range_doppler_map(ifSig, cfg);

tic;
[detMask, thr, alpha] = ca_cfar_2d(rdm, Tr, Td, Gr, Gd, Pfa);
tCfar = toc;
nTrain = (2*(Tr+Gr)+1) * (2*(Td+Gd)+1) - (2*Gr+1) * (2*Gd+1);

fprintf('2D CA-CFAR: Tr=%d Td=%d Gr=%d Gd=%d, N_train=%d, Pfa=%.0e\n', Tr, Td, Gr, Gd, nTrain, Pfa);
fprintf('alpha = %.2f (%.1f dB), runtime = %.1f ms\n', alpha, 10*log10(alpha), tCfar * 1e3);
fprintf('Detected cells: %d\n\n', nnz(detMask));

objects = cluster_detections(detMask, rdm, rangeAxis, velAxis);
fprintf('%-5s %10s %12s %10s %8s\n', 'Obj', 'R [m]', 'v [m/s]', 'Peak[dB]', 'Cells');
for k = 1:numel(objects)
    fprintf('%-5d %10.2f %12.2f %10.1f %8d\n', k, objects(k).range, ...
        objects(k).velocity, objects(k).peakDb, objects(k).numCells);
end

%% False-alarm check on noise-only frames (higher Pfa so it is measurable)
pfaTest = 1e-3; nFA = 0; nTested = 0;
for f = 1:5
    rdmN = range_doppler_map(noiseStd * randn(cfg.Nr, cfg.Nd), cfg);
    [mN, tN] = ca_cfar_2d(rdmN, Tr, Td, Gr, Gd, pfaTest);
    nFA = nFA + nnz(mN);  nTested = nTested + nnz(~isnan(tN));
end
fprintf('\nNoise-only check: design Pfa = %.0e, measured Pfa = %.2e\n', pfaTest, nFA / nTested);

%% Figure
fig = figure('Name', 'Day 5 - 2D CA-CFAR', 'Position', [100 100 1400 480]);
rdmDb = 10*log10(rdm);

subplot(1, 3, 1);
imagesc(velAxis, rangeAxis, rdmDb); axis xy; colormap(gca, 'jet'); colorbar;
xlabel('Velocity [m/s]'); ylabel('Range [m]'); title('Range-Doppler map [dB]');

subplot(1, 3, 2);
cutR = round(targets(1).range / cfg.rangeBin) + 1;
plot(velAxis, rdmDb(cutR, :), 'b', velAxis, 10*log10(thr(cutR, :)), 'r', 'LineWidth', 1.2);
grid on; xlabel('Velocity [m/s]'); ylabel('Power [dB]');
title(sprintf('Doppler cut at R = %.0f m', rangeAxis(cutR)));
legend('RDM', 'CA-CFAR threshold', 'Location', 'southwest');

subplot(1, 3, 3);
imagesc(velAxis, rangeAxis, detMask); axis xy; colormap(gca, gray);
hold on;
plot([targets.velocity], [targets.range], 'ro', 'MarkerSize', 14, 'LineWidth', 1.5);
xlabel('Velocity [m/s]'); ylabel('Range [m]');
title(sprintf('CA-CFAR detections (%d objects)', numel(objects)));
legend('Ground truth', 'TextColor', 'w', 'Color', 'none');

save_figure(fig, 'day5_2d_ca_cfar.png');
