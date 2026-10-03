function save_figure(fig, fileName)
%SAVE_FIGURE  Save a figure as PNG into the repository's docs/ folder.

    docsDir = fullfile(fileparts(mfilename('fullpath')), '..', 'docs');
    if ~exist(docsDir, 'dir')
        mkdir(docsDir);
    end
    outFile = fullfile(docsDir, fileName);

    try
        exportgraphics(fig, outFile, 'Resolution', 150);   % R2020a+
    catch
        print(fig, outFile, '-dpng', '-r150');
    end
    fprintf('Saved figure: %s\n', outFile);
end
