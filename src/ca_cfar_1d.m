function [detIdx, threshold, alpha] = ca_cfar_1d(x, Nt, Ng, Pfa)
%CA_CFAR_1D  Sliding-window Cell-Averaging CFAR detector.
%
%   [detIdx, threshold, alpha] = CA_CFAR_1D(x, Nt, Ng, Pfa)
%
%   x   : linear power vector (output of a square-law detector, |X|^2)
%   Nt  : training cells on EACH side of the cell under test (CUT)
%   Ng  : guard cells on EACH side of the CUT
%   Pfa : desired probability of false alarm
%
%   Noise estimate : Pn = (1/N) * sum(training cells),   N = 2*Nt
%   Threshold      : T  = alpha * Pn
%   Scale factor   : alpha = N * (Pfa^(-1/N) - 1)
%   (exact for exponentially distributed power, i.e. complex Gaussian noise)
%
%   Cells closer than Nt+Ng to either edge are not tested (threshold = NaN).

    x  = x(:);
    N  = 2 * Nt;
    alpha = N * (Pfa^(-1 / N) - 1);

    % Training-cell kernel: [Nt ones | 2*Ng+1 zeros | Nt ones]
    kernel = [ones(Nt, 1); zeros(2 * Ng + 1, 1); ones(Nt, 1)];
    noise  = conv(x, kernel, 'same') / N;

    threshold = alpha * noise;
    edge = Nt + Ng;
    threshold([1:edge, end-edge+1:end]) = NaN;

    detIdx = find(x > threshold);       % comparisons with NaN are false
end
