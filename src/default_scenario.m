function [targets, noiseStd] = default_scenario()
%DEFAULT_SCENARIO  Three moving point targets in AWGN.
%
%   [targets, noiseStd] = DEFAULT_SCENARIO() returns a struct array with
%   fields .range [m], .velocity [m/s] and .amplitude (linear, relative),
%   plus the standard deviation of the real-valued AWGN added to the IF
%   signal.
%
%   Sign convention: positive velocity = receding (range increasing),
%                    negative velocity = approaching.

    targets = struct( ...
        'range',     {45.3,  110.0, 165.7}, ...
        'velocity',  {-18.0,  12.0, -35.0}, ...
        'amplitude', {1.0,    0.6,   0.4});

    % Per-ADC-sample SNR of the strongest target. The 2D FFT adds roughly
    % 10*log10(Nr*Nd) ~ 48 dB of coherent gain (minus window losses), so
    % targets well below the noise in the raw IF data become clearly
    % visible in the Range-Doppler map.
    snrPerSampleDb = -5;
    signalPower    = targets(1).amplitude^2 / 2;          % power of A*cos()
    noiseStd       = sqrt(signalPower / 10^(snrPerSampleDb / 10));
end
