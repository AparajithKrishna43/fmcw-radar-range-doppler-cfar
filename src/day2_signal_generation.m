%% Day 2 - FMCW chirp synthesis, multi-target echoes and beat signal
%  Generates the dechirped IF data cube for three moving targets in AWGN
%  and visualises the chirp timing, the raw beat signal and the
%  single-chirp spectrum (beat frequency -> range).

clear; clc; close all;
cfg = radar_config();
[targets, noiseStd] = default_scenario();

rng(42);                                              % reproducible noise
ifClean       = generate_fmcw_if(cfg, targets, 0);
[ifSig, t]    = generate_fmcw_if(cfg, targets, noiseStd);

fprintf('Generated IF data cube: %d fast-time x %d slow-time samples\n', size(ifSig));
fprintf('Noise std = %.3f  (per-sample SNR of strongest target = -5 dB)\n\n', noiseStd);
fprintf('%-8s %10s %10s %14s\n', 'Target', 'R0 [m]', 'v [m/s]', 'f_beat [MHz]');
for k = 1:numel(targets)
    fb = 2 * cfg.S * targets(k).range / cfg.c;
    fprintf('%-8d %10.1f %10.1f %14.3f\n', k, targets(k).range, targets(k).velocity, fb / 1e6);
end

%% Figure
fig = figure('Name', 'Day 2 - Beat signal', 'Position', [100 100 1200 800]);

% (a) Tx / Rx instantaneous frequency for 3 chirps (farthest target)
subplot(3, 1, 1);
tt   = (0:3*cfg.Nr-1) / cfg.fs;
fTx  = cfg.S * mod(tt, cfg.Tc);
tau  = 2 * targets(end).range / cfg.c;
fRx  = cfg.S * mod(tt - tau, cfg.Tc);
plot(tt * 1e6, fTx / 1e6, 'b', tt * 1e6, fRx / 1e6, 'r--', 'LineWidth', 1.2);
xlabel('Time [\mus]'); ylabel('f - f_c [MHz]'); grid on;
title(sprintf('Tx vs Rx chirp (target at %.1f m, \\tau = %.2f \\mus)', targets(end).range, tau * 1e6));
legend('Tx', 'Rx (delayed)', 'Location', 'northwest');

% (b) Time-domain beat signal of the first chirp
subplot(3, 1, 2);
plot(t * 1e6, ifSig(:, 1), 'Color', [0.7 0.7 0.7]); hold on;
plot(t * 1e6, ifClean(:, 1), 'k', 'LineWidth', 1.0);
xlabel('Fast time [\mus]'); ylabel('Amplitude'); grid on;
title('IF beat signal - chirp #1'); legend('With AWGN', 'Noise-free');
xlim([0 cfg.Tc * 1e6]);

% (c) Single-chirp spectrum -> range
subplot(3, 1, 3);
[X, rangeAxis] = range_fft(ifSig, cfg);
P = 20 * log10(abs(X(:, 1)));
plot(rangeAxis, P - max(P), 'b', 'LineWidth', 1.0); hold on;
for k = 1:numel(targets)
    xline(targets(k).range, 'r--', sprintf('T%d', k), 'LineWidth', 1.0);
end
xlabel('Range [m]  (f_b = 2SR/c)'); ylabel('Normalised power [dB]'); grid on;
title('Range FFT of chirp #1 (Hann window)'); xlim([0 cfg.rMaxAdc]); ylim([-60 5]);

save_figure(fig, 'day2_beat_signal.png');
