class ApplicationJob < ActiveJob::Base
  # 業務のイベントのログに、どのジョブで起きたかを残す
  before_perform { |job| Rails.event.set_context(job_id: job.job_id, job_class: job.class.name) }

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
