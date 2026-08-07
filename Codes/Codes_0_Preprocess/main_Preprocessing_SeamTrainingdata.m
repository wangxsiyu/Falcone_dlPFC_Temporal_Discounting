run('../W_setup.m')
looper = S_looper_folder('../../TempData/Seam_training/');
jobs = S_jobs();
jobs.set_loopers({'folder'}, {looper});
jobs.add_jobs_with_looper_folder([], 'event2trials', ...
    {'events'}, {'inputname1'}, 'trials');
jobs.add_jobs_with_looper_folder([], 'preprocess_trials', ...
    {'trials'}, {}, 'games');
jobs.parfor_off;
jobs.overwrite_off;
jobs.run()