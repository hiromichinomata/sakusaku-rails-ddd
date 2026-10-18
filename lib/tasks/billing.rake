namespace :billing do
  desc "返金に失敗した決済を一覧にする"
  task failed_refunds: :environment do
    payments = Payment.refund_failed.order(:id)
    puts "返金に失敗した決済: #{payments.size}件"
    payments.each { |p| puts "  予約 #{p.reservation_id}: #{Money.new(p.amount)}（支払いID #{p.charge_id}）" }
  end

  desc "返金に失敗した決済を、返金のジョブに積み直す"
  task retry_failed_refunds: :environment do
    ids = Billing::RetryFailedRefunds.new.call
    puts "返金のジョブを積み直した予約: #{ids.inspect}"
  end
end
