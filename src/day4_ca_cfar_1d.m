%% Day 4 - 1D CA-CFAR on the range profile + Pfa validation
%  (a) Applies a sliding-window Cell-Averaging CFAR to the power range
%      profile of a single chirp.
%  (b) Monte-Carlo validation: runs the detector on noise-only data and
%      compares the measured false-alarm rate with the design Pfa.

clear; clc; close all;
cfg = radar_config();
[targets, noiseStd] = default_scenario();

Nt  = 16;      % training cells per side
Ng  = 3;       % guard cells per side (Hann main-lobe is +/-2 bins)
Pfa = 1e-4;

%% (a) Detection on a single chirp
rng(42);
ifSig = generate_fmcw_if(cfg, targets, noiseStd);
[X, rangeAxis] = range_fft(ifSig, cfg);
profile = abs(X(:, 1)).^2;                         % square-law detector

[detIdx, thr, alpha] = ca_cfar_1d(profile, Nt, Ng, Pfa);
fprintf('1D CA-CFAR: Nt = %d, Ng = %d, Pfa = %.0e, alpha = %.2f (%.1f dB)\n', ...
    Nt, Ng, Pfa, alpha, 10 * log10(alpha));
fprintf('Detections at range bins [m]: %s\n', mat2str(rangeAxis(detIdx).', 4));
fprintf('Note: the weakest target only has ~12 dB SNR in a single chirp; the\n');
fprintf('      Doppler FFT (Day 5) adds ~21 dB of coherent gain.\n\n');

%% (b) Pfa validation on noise-only data
pfaList  = [1e-1 1e-2 1e-3 1e-4];
pfaMeas  = zeros(size(pfaList));
nFrames  = 20;
for p = 1:numel(pfaList)
    nFA = 0; nTested = 0;
    for f = 1:nFrames
        Xn = range_fft(noiseStd * randn(cfg.Nr, cfg.Nd), cfg);
        for ch = 1:cfg.Nd
            [idx, thrN] = ca_cfar_1d(abs(Xn(:, ch)).^2, Nt, Ng, pfaList(p));
            nFA     = nFA + numel(idx);
            nTested = nTested + nnz(~isnan(thrN));
        end
    end
    pfaMeas(p) = nFA / nTested;
    fprintf('Design Pfa = %.0e  ->  measured Pfa = %.2e  (%d cells tested)\n', ...
        pfaList(p), pfaMeas(p), nTested);
end
fprintf(['Measured Pfa is slightly above design because the Hann window\n' ...
         'correlates neighbouring range bins (fewer independent training cells).\n']);

%% Figure
fig = figure('Name', 'Day 4 - 1D CA-CFAR', 'Position', [100 100 1300 480]);

subplot(1, 2, 1);
plot(rangeAxis, 10*log10(profile), 'b', 'LineWidth', 1.0); hold on;
plot(rangeAxis, 10*log10(thr), 'r', 'LineWidth', 1.5);
plot(rangeAxis(detIdx), 10*log10(profile(detIdx)), 'kv', 'MarkerFaceColor', 'g', 'MarkerSize', 8);
for k = 1:numel(targets)
    xline(targets(k).range, 'k:', sprintf('T%d', k));
end
xlabel('Range [m]'); ylabel('Power [dB]'); grid on; xlim([0 cfg.rMaxAdc]);
title(sprintf('1D CA-CFAR on chirp #1 (N_t=%d, N_g=%d, P_{fa}=10^{%d})', Nt, Ng, round(log10(Pfa))));
legend('Range profile', 'CFAR threshold', 'Detections', 'Location', 'northeast');

subplot(1, 2, 2);
loglog(pfaList, pfaMeas, 'bo-', 'LineWidth', 1.5, 'MarkerFaceColor', 'b'); hold on;
loglog(pfaList, pfaList, 'k--', 'LineWidth', 1.0);
xlabel('Design P_{fa}'); ylabel('Measured P_{fa}'); grid on; axis square;
title(sprintf('P_{fa} validation (%d noise-only frames)', nFrames));
legend('Measured', 'Ideal', 'Location', 'northwest');

save_figure(fig, 'day4_1d_cfar.png');
