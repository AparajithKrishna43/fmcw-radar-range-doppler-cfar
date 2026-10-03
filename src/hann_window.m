function w = hann_window(N)
%HANN_WINDOW  Periodic Hann window (column vector).
%
%   Uses hann() from the Signal Processing Toolbox when available and
%   falls back to the closed-form expression so the project also runs on
%   base MATLAB.

    if exist('hann', 'file')
        w = hann(N, 'periodic');
    else
        n = (0:N-1).';
        w = 0.5 - 0.5 * cos(2 * pi * n / N);
    end
end
