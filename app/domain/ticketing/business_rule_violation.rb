module Ticketing
  # 業務のルールに反する操作をしたときのエラーの親クラス
  class BusinessRuleViolation < StandardError; end
end
