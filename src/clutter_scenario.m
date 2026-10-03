function [targets, clutter, noiseStd] = clutter_scenario()
%CLUTTER_SCENARIO  Moving targets plus stationary ground clutter.
%
%   [targets, clutter, noiseStd] = CLUTTER_SCENARIO() returns:
%     targets  - moving targets, including a weak target placed right next
%                to a strong one (a CA-CFAR "masking" test case)
%     clutter  - many stationary (v = 0) scatterers: road surface,
%                guard-rails, signs, parked cars
%     noiseStd - AWGN standard deviation (same as DEFAULT_SCENARIO)
%
%   Call rng(seed) before this function for a reproducible clutter field.

    targets = struct( ...
        'range',     {45.3,  110.0, 114.0, 165.7}, ...
        'velocity',  {-18.0,  12.0,  13.5, -35.0}, ...
        'amplitude', {1.0,    0.6,   0.15,  0.4});

    nClutter  = 60;
    clutRange = 3 + (200 - 3) * rand(1, nClutter);
    clutAmp   = 0.25 * abs(randn(1, nClutter) + 1j * randn(1, nClutter)) / sqrt(2);

    clutter = struct( ...
        'range',     num2cell(clutRange), ...
        'velocity',  num2cell(zeros(1, nClutter)), ...
        'amplitude', num2cell(clutAmp));

    [~, noiseStd] = default_scenario();
end
