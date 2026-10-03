function [X, rangeAxis] = range_fft(ifSig, cfg)
%RANGE_FFT  Stage-1 (fast-time) FFT: beat frequency -> range.
%
%   [X, rangeAxis] = RANGE_FFT(ifSig, cfg) applies a Hann window along
%   fast time, takes the FFT of every chirp (column), and keeps the
%   positive-frequency half (the IF signal is real, so the spectrum is
%   Hermitian-symmetric).
%
%   X         : (Nr/2) x Nd complex range profiles
%   rangeAxis : (Nr/2) x 1 range of each bin [m]

    Nr = size(ifSig, 1);
    w  = hann_window(Nr);                       % range-sidelobe suppression

    X  = fft(ifSig .* w, Nr, 1);
    X  = X(1:Nr/2, :);

    rangeAxis = (0:Nr/2-1).' * cfg.rangeBin;    % f_b = 2*S*R/c
end
