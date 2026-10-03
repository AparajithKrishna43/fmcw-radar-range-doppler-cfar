%% Day 1 - FMCW waveform design from system requirements
%  Derives bandwidth, chirp time, slope, ADC rate and frame size from the
%  range / velocity requirements and checks that every requirement is met.

clear; clc;
cfg = radar_config();

fprintf('===== 77 GHz FMCW Radar - Waveform Design =====\n\n');
fprintf('Requirements\n');
fprintf('  Range resolution        : %6.2f m\n',   cfg.req.rangeRes);
fprintf('  Max range               : %6.1f m\n',   cfg.req.maxRange);
fprintf('  Max |radial velocity|   : %6.1f m/s\n', cfg.req.maxVelocity);
fprintf('  Velocity resolution     : %6.2f m/s\n\n', cfg.req.velRes);

fprintf('Waveform\n');
fprintf('  Carrier frequency  fc   : %6.1f GHz\n',     cfg.fc / 1e9);
fprintf('  Wavelength         lam  : %6.3f mm\n',      cfg.lambda * 1e3);
fprintf('  Bandwidth          B    : %6.1f MHz\n',     cfg.B / 1e6);
fprintf('  Chirp duration     Tc   : %6.1f us\n',      cfg.Tc * 1e6);
fprintf('  Chirp slope        S    : %6.1f MHz/us\n',  cfg.S / 1e12);
fprintf('  ADC sample rate    fs   : %6.1f MHz\n',     cfg.fs / 1e6);
fprintf('  Samples / chirp    Nr   : %6d\n',           cfg.Nr);
fprintf('  Chirps / frame     Nd   : %6d\n',           cfg.Nd);
fprintf('  Frame time              : %6.2f ms\n\n',    cfg.Tframe * 1e3);

fprintf('Achieved performance\n');
fprintf('  Range bin size          : %6.2f m\n',   cfg.rangeBin);
fprintf('  Max beat freq @ Rmax    : %6.1f MHz (Nyquist %0.1f MHz)\n', cfg.fbMax/1e6, cfg.fs/2e6);
fprintf('  Max range (real ADC)    : %6.1f m\n',   cfg.rMaxAdc);
fprintf('  Max |velocity|          : %6.1f m/s (%0.0f km/h)\n', cfg.vMax, cfg.vMax * 3.6);
fprintf('  Velocity resolution     : %6.2f m/s\n', cfg.vRes);
fprintf('  Tc / round-trip @ Rmax  : %6.1f x\n\n', cfg.Tc / cfg.tauMax);

%% Requirement checks
checks = {
    'Range resolution',      cfg.rangeBin <= cfg.req.rangeRes + 1e-9
    'Beat freq < Nyquist',   cfg.fbMax    <  cfg.fs / 2
    'Max range covered',     cfg.rMaxAdc  >= cfg.req.maxRange
    'Max velocity covered',  cfg.vMax     >= cfg.req.maxVelocity
    'Velocity resolution',   cfg.vRes     <= cfg.req.velRes
    'Tc >> round-trip delay',cfg.Tc       >= 5 * cfg.tauMax
};
for k = 1:size(checks, 1)
    status = 'FAIL';
    if checks{k, 2}, status = 'PASS'; end
    fprintf('  [%s] %s\n', status, checks{k, 1});
end
assert(all([checks{:, 2}]), 'One or more waveform requirements are not met.');
