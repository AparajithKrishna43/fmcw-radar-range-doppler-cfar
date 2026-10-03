function [ifSig, t] = generate_fmcw_if(cfg, targets, noiseStd)
%GENERATE_FMCW_IF  Synthesise the dechirped (IF / beat) FMCW data cube.
%
%   [ifSig, t] = GENERATE_FMCW_IF(cfg, targets, noiseStd) returns an
%   Nr-by-Nd real matrix (fast-time x slow-time) and the fast-time vector t.
%
%   Model
%   -----
%   Tx chirp :  s_tx(t) = cos(2*pi*(fc*t + S*t^2/2))
%   Rx echo  :  s_rx(t) = A*s_tx(t - tau),  tau = 2*R(t)/c
%   Mixer+LPF:  s_IF(t) = A*cos(2*pi*(fc*tau + S*tau*t - S*tau^2/2))
%
%   The mixer output is computed analytically instead of sampling the
%   77 GHz carrier, which would require a >154 GS/s simulation rate.
%   Target motion is modelled continuously across fast AND slow time:
%       R(t, d) = R0 + v*(d*Tc + t)
%   so Doppler, range-Doppler coupling and range migration are all
%   included.

    t = (0:cfg.Nr-1).' / cfg.fs;        % fast time within a chirp (Nr x 1)
    d = 0:cfg.Nd-1;                     % chirp index              (1 x Nd)

    ifSig = zeros(cfg.Nr, cfg.Nd);
    for k = 1:numel(targets)
        R   = targets(k).range + targets(k).velocity * (d * cfg.Tc + t);  % Nr x Nd
        tau = 2 * R / cfg.c;
        phi = 2 * pi * (cfg.fc * tau + cfg.S * tau .* t - 0.5 * cfg.S * tau.^2);
        ifSig = ifSig + targets(k).amplitude * cos(phi);
    end

    if noiseStd > 0
        ifSig = ifSig + noiseStd * randn(cfg.Nr, cfg.Nd);   % AWGN
    end
end
