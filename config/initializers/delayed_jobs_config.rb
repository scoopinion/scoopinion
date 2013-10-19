# config/initializers/delayed_job_config.rb

require "delayed_job_patch"

Delayed::Worker.destroy_failed_jobs = true
#Delayed::Worker.sleep_delay = 60
#Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 10.minutes

