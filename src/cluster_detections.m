function [objects, labels] = cluster_detections(detMask, rdm, rangeAxis, velAxis)
%CLUSTER_DETECTIONS  Group CFAR hits into objects and estimate centroids.
%
%   [objects, labels] = CLUSTER_DETECTIONS(detMask, rdm, rangeAxis, velAxis)
%
%   A single target spreads over several Range-Doppler cells (window
%   main-lobe), so CFAR returns a blob of detections per target. This
%   function labels 8-connected blobs (Doppler wraps around) with a
%   flood fill - no Image Processing Toolbox required - and returns one
%   object per blob:
%
%     objects(i).range      power-weighted range centroid    [m]
%     objects(i).velocity   power-weighted velocity centroid [m/s]
%     objects(i).peakDb     peak power in the blob           [dB]
%     objects(i).numCells   number of CFAR cells in the blob
%
%   labels is a matrix the size of detMask with the blob ID of each cell.

    [nR, nD] = size(detMask);
    labels   = zeros(nR, nD);
    nLabels  = 0;
    nbr      = [-1 -1; -1 0; -1 1; 0 -1; 0 1; 1 -1; 1 0; 1 1];

    [rIdx, dIdx] = find(detMask);
    for n = 1:numel(rIdx)
        if labels(rIdx(n), dIdx(n)) ~= 0
            continue;
        end
        nLabels = nLabels + 1;
        labels(rIdx(n), dIdx(n)) = nLabels;
        stack = [rIdx(n), dIdx(n)];
        while ~isempty(stack)
            cur = stack(end, :);
            stack(end, :) = [];
            for m = 1:size(nbr, 1)
                r = cur(1) + nbr(m, 1);
                d = mod(cur(2) + nbr(m, 2) - 1, nD) + 1;      % Doppler wrap
                if r >= 1 && r <= nR && detMask(r, d) && labels(r, d) == 0
                    labels(r, d) = nLabels;
                    stack(end+1, :) = [r, d]; %#ok<AGROW>
                end
            end
        end
    end

    objects = struct('range', {}, 'velocity', {}, 'peakDb', {}, 'numCells', {});
    for L = 1:nLabels
        [r, d] = find(labels == L);
        p      = rdm(sub2ind([nR, nD], r, d));
        w      = p / sum(p);
        objects(L).range    = sum(w .* rangeAxis(r));
        objects(L).velocity = sum(w .* velAxis(d).');
        objects(L).peakDb   = 10 * log10(max(p));
        objects(L).numCells = numel(p);
    end

    % Strongest object first
    if ~isempty(objects)
        [~, order] = sort([objects.peakDb], 'descend');
        objects    = objects(order);
    end
end
