function [rdm, rangeAxis, velAxis, rd] = range_doppler_map(ifSig, cfg)
%RANGE_DOPPLER_MAP  2D FFT processing: IF data cube -> Range-Doppler map.
%
%   [rdm, rangeAxis, velAxis, rd] = RANGE_DOPPLER_MAP(ifSig, cfg)
%
%   Stage 1 : Hann-windowed FFT along fast time  (columns) -> range
%   Stage 2 : Hann-windowed FFT along slow time  (rows)    -> Doppler,
%             followed by fftshift so zero velocity sits in the centre.
%
%   rdm       : (Nr/2) x Nd linear power map |rd|^2 (square-law detector)
%   rangeAxis : (Nr/2) x 1 [m]
%   velAxis   : 1 x Nd     [m/s]  (+ receding, - approaching)
%   rd        : complex Range-Doppler matrix

    [X, rangeAxis] = range_fft(ifSig, cfg);

    Nd = size(X, 2);
    wd = hann_window(Nd).';                         % Doppler-sidelobe suppression
    rd = fftshift(fft(X .* wd, Nd, 2), 2);

    rdm = abs(rd).^2;

    fd      = (-Nd/2 : Nd/2-1) / (Nd * cfg.Tc);     % Doppler frequency [Hz]
    velAxis = fd * cfg.lambda / 2;                  % v = f_d * lambda / 2
end
