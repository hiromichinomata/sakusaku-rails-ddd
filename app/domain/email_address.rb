require "uri"

# メールアドレス。前後の空白を取り、小文字にそろえて持つ値オブジェクト
class EmailAddress < Data.define(:value)
  def initialize(value:)
    normalized = value.to_s.strip.downcase
    unless normalized.match?(URI::MailTo::EMAIL_REGEXP)
      raise ArgumentError, "メールアドレスの形が正しくありません: #{value.inspect}"
    end

    super(value: normalized)
  end

  def to_s
    value
  end
end
