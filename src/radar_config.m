function cfg = radar_config()
%RADAR_CONFIG  Central parameter set for the 77 GHz FMCW automotive radar.
%
%   cfg = RADAR_CONFIG() derives the FMCW waveform (bandwidth, chirp time,
%   slope, sampling rate, frame size) from high-level system requirements
%   and returns every quantity used by the processing chain in one struct.
%
%   All scripts in this repository call RADAR_CONFIG so that the waveform
%   is defined in exactly one place.

    %% Physical constants
    cfg.c      = 3e8;               % speed of light [m/s]
    cfg.fc     = 77e9;              % carrier frequency [Hz]
    cfg.lambda = cfg.c / cfg.fc;    % wavelength [m] (~3.9 mm)

    %% System requirements
    cfg.req.rangeRes    = 1;        % range resolution        [m]
    cfg.req.maxRange    = 200;      % max detection range     [m]
    cfg.req.maxVelocity = 90;       % max |radial velocity|   [m/s]
    cfg.req.velRes      = 2;        % velocity resolution     [m/s]

    %% Waveform design
    % Bandwidth sets range resolution: dR = c / (2B)
    cfg.B  = cfg.c / (2 * cfg.req.rangeRes);            % 150 MHz

    % Chirp time sets max velocity: v_max = lambda / (4 Tc)
    %   -> Tc <= lambda / (4 v_max_req) = 10.8 us. Choose 10 us.
    cfg.Tc = 10e-6;                                     % chirp duration [s]
    cfg.S  = cfg.B / cfg.Tc;                            % slope [Hz/s] (15 MHz/us)

    % Frame size
    cfg.Nr = 512;                                       % fast-time samples / chirp
    cfg.Nd = 128;                                       % slow-time chirps / frame
    cfg.fs = cfg.Nr / cfg.Tc;                           % ADC rate [Hz] (51.2 MHz)

    %% Derived performance figures
    cfg.fbMax     = 2 * cfg.S * cfg.req.maxRange / cfg.c;   % max beat freq [Hz]
    cfg.rangeBin  = cfg.c * cfg.fs / (2 * cfg.S * cfg.Nr);  % range bin size [m]
    cfg.rMaxAdc   = cfg.rangeBin * cfg.Nr / 2;              % real-ADC max range [m]
    cfg.vMax      = cfg.lambda / (4 * cfg.Tc);              % max unambiguous |v| [m/s]
    cfg.vRes      = cfg.lambda / (2 * cfg.Nd * cfg.Tc);     % velocity resolution [m/s]
    cfg.Tframe    = cfg.Nd * cfg.Tc;                        % frame duration [s]
    cfg.tauMax    = 2 * cfg.req.maxRange / cfg.c;           % max round-trip delay [s]
end
