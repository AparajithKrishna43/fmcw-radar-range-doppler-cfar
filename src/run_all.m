function run_all()
%RUN_ALL  Execute the complete FMCW radar pipeline (Days 1-7).
%  Every script saves its figure to ../docs/. Run from any folder.

    srcDir = fileparts(mfilename('fullpath'));
    addpath(srcDir);

    scripts = {'day1_radar_parameters', 'day2_signal_generation', ...
               'day3_range_doppler_processing', 'day4_ca_cfar_1d', ...
               'day5_ca_cfar_2d', 'day6_clutter_os_cfar', 'day7_target_extraction'};

    for s = 1:numel(scripts)
        fprintf('\n\n################  %s  ################\n', scripts{s});
        run_one(fullfile(srcDir, [scripts{s} '.m']));
        drawnow;
    end
end

function run_one(scriptPath)
% Each day-script starts with "clear", so run it in its own workspace.
    run(scriptPath);
end
