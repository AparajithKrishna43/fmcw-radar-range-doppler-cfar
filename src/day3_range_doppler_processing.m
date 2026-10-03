%% Day 3 - 2D FFT Range-Doppler processing
%  Fast-time FFT -> range, slow-time FFT across chirps -> Doppler / radial
%  velocity. Produces 2D and 3D Range-Doppler map (RDM) visualisations and
%  reports the peak location of every target.

clear; clc; close all;
cfg = radar_config();
[targets, noiseStd] = default_scenario();

rng(42);
ifSig = generate_fmcw_if(cfg, targets, noiseStd);
[rdm, rangeAxis, velAxis] = range_doppler_map(ifSig, cfg);

rdmDb = 10 * log10(rdm);
rdmDb = rdmDb - max(rdmDb(:));                 % normalise to 0 dB peak

%% Peak around each true target (+/- 3 bins search window)
fprintf('%-6s %10s %10s %12s %12s %10s\n', 'Tgt', 'R true', 'v true', 'R est', 'v est', 'SNR [dB]');
noiseFloorDb = 10 * log10(median(rdm(:)));
for k = 1:numel(targets)
    [~, r0] = min(abs(rangeAxis - targets(k).range));
    [~, d0] = min(abs(velAxis  - targets(k).velocity));
    rWin = max(1, r0-3) : min(numel(rangeAxis), r0+3);
    dWin = max(1, d0-3) : min(numel(velAxis),  d0+3);
    sub  = rdm(rWin, dWin);
    [pk, idx] = max(sub(:));
    [ri, di]  = ind2sub(size(sub), idx);
    fprintf('%-6d %10.1f %10.1f %12.1f %12.2f %10.1f\n', k, targets(k).range, ...
        targets(k).velocity, rangeAxis(rWin(ri)), velAxis(dWin(di)), 10*log10(pk) - noiseFloorDb);
end

%% Figure
fig = figure('Name', 'Day 3 - Range-Doppler map', 'Position', [100 100 1300 520]);

subplot(1, 2, 1);
imagesc(velAxis, rangeAxis, rdmDb); axis xy; colormap(gca, 'jet');
cb = colorbar; cb.Label.String = 'Power [dB]'; caxis([-60 0]);
hold on;
plot([targets.velocity], [targets.range], 'wo', 'MarkerSize', 12, 'LineWidth', 1.5);
xlabel('Radial velocity [m/s]  (- approaching / + receding)'); ylabel('Range [m]');
title('Range-Doppler map (2D FFT)'); legend('Ground truth', 'TextColor', 'w', 'Color', 'none');

subplot(1, 2, 2);
surf(velAxis, rangeAxis, rdmDb, 'EdgeColor', 'none'); colormap(gca, 'jet');
xlabel('Velocity [m/s]'); ylabel('Range [m]'); zlabel('Power [dB]');
title('Range-Doppler map (3D)'); zlim([-60 0]); caxis([-60 0]); view(-35, 40);

save_figure(fig, 'day3_rdm_heatmap.png');
