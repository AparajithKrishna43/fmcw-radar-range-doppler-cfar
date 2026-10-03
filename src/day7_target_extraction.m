%% Day 7 - Target extraction: clustering, centroiding and accuracy report
%  Full pipeline on the clutter scenario:
%    IF cube -> MTI -> 2D FFT -> OS-CFAR -> clustering -> target list
%  and evaluates range / velocity estimation error against ground truth.

clear; clc; close all;
cfg = radar_config();

rng(7);
[targets, clutter, noiseStd] = clutter_scenario();
ifSig = generate_fmcw_if(cfg, [targets, clutter], noiseStd);

ifMti = ifSig - mean(ifSig, 2);
[rdm, rangeAxis, velAxis] = range_doppler_map(ifMti, cfg);
detMask = os_cfar_2d(rdm, 10, 6, 3, 3, 1e-6, 0.75);
[objects, labels] = cluster_detections(detMask, rdm, rangeAxis, velAxis);

%% Associate each object with nearest ground-truth target
fprintf('===== Target list =====\n');
fprintf('%-4s %9s %10s %9s %8s | %9s %10s | %8s %9s\n', 'ID', 'R [m]', 'v [m/s]', ...
    'Peak[dB]', 'Cells', 'R true', 'v true', 'dR [m]', 'dv [m/s]');
errR = []; errV = [];
for o = 1:numel(objects)
    dist = hypot(([targets.range] - objects(o).range) / cfg.rangeBin, ...
                 ([targets.velocity] - objects(o).velocity) / cfg.vRes);
    [dmin, k] = min(dist);
    if dmin < 3
        dR = objects(o).range - targets(k).range;
        dV = objects(o).velocity - targets(k).velocity;
        errR(end+1) = dR; errV(end+1) = dV; %#ok<AGROW>
        fprintf('%-4d %9.2f %10.2f %9.1f %8d | %9.1f %10.1f | %8.2f %9.2f\n', o, ...
            objects(o).range, objects(o).velocity, objects(o).peakDb, objects(o).numCells, ...
            targets(k).range, targets(k).velocity, dR, dV);
    else
        fprintf('%-4d %9.2f %10.2f %9.1f %8d | %9s %10s |  (false alarm)\n', o, ...
            objects(o).range, objects(o).velocity, objects(o).peakDb, objects(o).numCells, '-', '-');
    end
end
fprintf('\nRMS range error    : %.3f m   (bin = %.2f m)\n',   sqrt(mean(errR.^2)), cfg.rangeBin);
fprintf('RMS velocity error : %.3f m/s (bin = %.2f m/s)\n', sqrt(mean(errV.^2)), cfg.vRes);

%% Figure
fig = figure('Name', 'Day 7 - Target extraction', 'Position', [100 100 1300 520]);

subplot(1, 2, 1);
imagesc(velAxis, rangeAxis, labels); axis xy;
colormap(gca, [0 0 0; lines(max(1, numel(objects)))]);
xlabel('Velocity [m/s]'); ylabel('Range [m]');
title('Clustered CFAR detections (colour = object ID)');

subplot(1, 2, 2);
plot([targets.velocity], [targets.range], 'ko', 'MarkerSize', 14, 'LineWidth', 1.5); hold on;
if ~isempty(objects)
    scatter([objects.velocity], [objects.range], 60, [objects.peakDb], 'filled');
    cb = colorbar; cb.Label.String = 'Peak power [dB]';
    for o = 1:numel(objects)
        text(objects(o).velocity + 2, objects(o).range, sprintf('#%d', o));
    end
end
grid on; xlim([-cfg.vMax cfg.vMax]); ylim([0 cfg.rMaxAdc]);
xlabel('Velocity [m/s]'); ylabel('Range [m]');
title('Extracted point cloud vs ground truth');
legend('Ground truth', 'Detected objects', 'Location', 'southeast');

save_figure(fig, 'day7_target_list.png');
