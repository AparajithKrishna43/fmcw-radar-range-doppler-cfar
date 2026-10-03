function [detMask, threshold, alpha] = os_cfar_2d(rdm, Tr, Td, Gr, Gd, Pfa, kFrac)
%OS_CFAR_2D  2D Ordered-Statistic CFAR over a Range-Doppler map.
%
%   [detMask, threshold, alpha] = OS_CFAR_2D(rdm, Tr, Td, Gr, Gd, Pfa, kFrac)
%
%   Same window geometry as CA_CFAR_2D, but the noise level is the k-th
%   smallest training cell instead of the mean (k = round(kFrac * N),
%   default kFrac = 0.75). A few strong interferers inside the training
%   window (neighbouring targets, clutter edges) therefore do not raise
%   the threshold, which avoids target masking.
%
%   The scale factor alpha is found numerically from the OS-CFAR false
%   alarm equation for exponentially distributed noise:
%       Pfa = prod_{i=0}^{k-1} (N - i) / (N - i + alpha)

    if nargin < 7 || isempty(kFrac)
        kFrac = 0.75;
    end

    edgeR = Tr + Gr;
    edgeD = Td + Gd;

    mask = true(2 * edgeR + 1, 2 * edgeD + 1);
    mask(Tr+1 : end-Tr, Td+1 : end-Td) = false;     % remove guard cells + CUT
    N = nnz(mask);
    k = max(1, min(N, round(kFrac * N)));

    % Solve for alpha (log form for numerical stability)
    i = 0:k-1;
    pfaFun = @(a) sum(log(N - i) - log(N - i + a)) - log(Pfa);
    alpha  = fzero(pfaFun, [0, 1e6]);

    [nR, nD] = size(rdm);
    padded   = [rdm(:, end-edgeD+1:end), rdm, rdm(:, 1:edgeD)];   % Doppler wrap
    threshold = NaN(nR, nD);

    for r = edgeR+1 : nR-edgeR
        for d = 1:nD
            win    = padded(r-edgeR : r+edgeR, d : d+2*edgeD);
            sorted = sort(win(mask));
            threshold(r, d) = alpha * sorted(k);
        end
    end

    detMask = rdm > threshold;
end
