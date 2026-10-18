RSpec.configure do |config|
  config.include ActiveJob::TestHelper
  config.before { ActionMailer::Base.deliveries.clear }
end

# 届いたメールの件名の一覧
def delivered_subjects
  ActionMailer::Base.deliveries.map(&:subject)
end
