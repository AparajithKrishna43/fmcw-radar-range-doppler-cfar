%% Day 6 - Clutter suppression and CA-CFAR vs OS-CFAR
%  Scenario: 4 moving targets (one weak target right next to a strong one)
%  plus 60 stationary clutter scatterers.
%
%  Compared configurations:
%    1. CA-CFAR, no clutter suppression   -> clutter ridge at v = 0 detected
%    2. MTI + CA-CFAR                     -> clutter removed, weak target masked
%    3. MTI + OS-CFAR                     -> clutter removed, all targets found
%
%  MTI = subtracting the slow-time mean of every range sample, i.e. a
%  zero-Doppler notch that removes stationary returns before the Doppler FFT.

clear; clc; close all;
cfg = radar_config();

rng(7);
[targets, clutter, noiseStd] = clutter_scenario();
ifSig = generate_fmcw_if(cfg, [targets, clutter], noiseStd);

Tr = 10; Td = 6; Gr = 3; Gd = 3; Pfa = 1e-6; kFrac = 0.75;

% Without clutter suppression
[rdmRaw, rangeAxis, velAxis] = range_doppler_map(ifSig, cfg);

% MTI clutter suppression (zero-Doppler notch)
ifMti  = ifSig - mean(ifSig, 2);
rdmMti = range_doppler_map(ifMti, cfg);

detCaRaw = ca_cfar_2d(rdmRaw, Tr, Td, Gr, Gd, Pfa);
detCaMti = ca_cfar_2d(rdmMti, Tr, Td, Gr, Gd, Pfa);
tic;
[detOsMti, ~, alphaOs] = os_cfar_2d(rdmMti, Tr, Td, Gr, Gd, Pfa, kFrac);
tOs = toc;

cases = {'CA-CFAR (no MTI)', detCaRaw, rdmRaw;
         'MTI + CA-CFAR',    detCaMti, rdmMti;
         'MTI + OS-CFAR',    detOsMti, rdmMti};

fprintf('OS-CFAR: k = %.0f%% of N, alpha = %.2f (%.1f dB), runtime %.2f s\n\n', ...
    100*kFrac, alphaOs, 10*log10(alphaOs), tOs);

objs = cell(size(cases, 1), 1);
for c = 1:size(cases, 1)
    objs{c} = cluster_detections(cases{c, 2}, cases{c, 3}, rangeAxis, velAxis);
    found = false(1, numel(targets));
    for k = 1:numel(targets)
        for o = 1:numel(objs{c})
            if abs(objs{c}(o).range - targets(k).range) < 2 && ...
               abs(objs{c}(o).velocity - targets(k).velocity) < 2 * cfg.vRes
                found(k) = true;
            end
        end
    end
    fprintf('%-18s : %3d objects, %d/%d true targets found, %3d false/clutter objects\n', ...
        cases{c, 1}, numel(objs{c}), nnz(found), numel(targets), numel(objs{c}) - nnz(found));
end

%% Figure
fig = figure('Name', 'Day 6 - Clutter & OS-CFAR', 'Position', [50 50 1400 900]);

subplot(2, 2, 1);
imagesc(velAxis, rangeAxis, 10*log10(rdmRaw)); axis xy; colormap(gca, 'jet'); colorbar;
xlabel('Velocity [m/s]'); ylabel('Range [m]');
title('RDM with stationary clutter (ridge at v = 0)');

for c = 1:3
    subplot(2, 2, c + 1);
    imagesc(velAxis, rangeAxis, cases{c, 2}); axis xy; colormap(gca, gray);
    hold on;
    plot([targets.velocity], [targets.range], 'ro', 'MarkerSize', 12, 'LineWidth', 1.5);
    xlabel('Velocity [m/s]'); ylabel('Range [m]');
    title(sprintf('%s - %d objects', cases{c, 1}, numel(objs{c})));
end

save_figure(fig, 'day6_clutter_os_cfar.png');
