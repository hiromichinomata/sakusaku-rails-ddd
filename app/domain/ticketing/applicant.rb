module Ticketing
  # 申込者。予約を申し込み、支払う人
  class Applicant < Data.define(:name, :email)
    def initialize(name:, email:)
      raise ArgumentError, "申込者の名前を指定してください" if name.to_s.strip.empty?

      email = EmailAddress.new(email) unless email.is_a?(EmailAddress)
      super(name: name.strip, email: email)
    end
  end
end
