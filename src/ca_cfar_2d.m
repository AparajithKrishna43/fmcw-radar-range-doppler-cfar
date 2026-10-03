function [detMask, threshold, alpha] = ca_cfar_2d(rdm, Tr, Td, Gr, Gd, Pfa)
%CA_CFAR_2D  2D Cell-Averaging CFAR over a Range-Doppler map.
%
%   [detMask, threshold, alpha] = CA_CFAR_2D(rdm, Tr, Td, Gr, Gd, Pfa)
%
%   rdm    : linear power map, rows = range bins, columns = Doppler bins
%   Tr, Td : training cells on each side in range / Doppler
%   Gr, Gd : guard cells on each side in range / Doppler
%   Pfa    : desired probability of false alarm
%
%   The training region is the rectangular ring
%       (2(Tr+Gr)+1) x (2(Td+Gd)+1)  minus  (2Gr+1) x (2Gd+1)
%   around the cell under test. The local noise level is the mean of the
%   training cells; threshold = alpha * noise with
%       alpha = N * (Pfa^(-1/N) - 1),  N = number of training cells.
%
%   Doppler is periodic (it is an FFT axis), so the map is wrapped
%   circularly along Doppler: every Doppler bin is tested. Range is not
%   periodic, so range bins closer than Tr+Gr to either edge are skipped.
%
%   Implemented with conv2 -> O(1) per cell regardless of window size.

    edgeR = Tr + Gr;
    edgeD = Td + Gd;

    kernel = ones(2 * edgeR + 1, 2 * edgeD + 1);
    kernel(Tr+1 : end-Tr, Td+1 : end-Td) = 0;     % remove guard cells + CUT
    N     = sum(kernel(:));
    alpha = N * (Pfa^(-1 / N) - 1);

    % Circular padding along Doppler
    padded   = [rdm(:, end-edgeD+1:end), rdm, rdm(:, 1:edgeD)];
    noiseSum = conv2(padded, kernel, 'same');
    noiseSum = noiseSum(:, edgeD+1 : end-edgeD);

    threshold = alpha * noiseSum / N;
    threshold([1:edgeR, end-edgeR+1:end], :) = NaN;

    detMask = rdm > threshold;
end
