require "spec_helper"

# ドメイン層のスペックは Rails を読み込まない。
# Rails がまだ読み込まれていなければ、app/domain のファイルだけを読み込む。
unless defined?(Rails)
  Dir[File.expand_path("../app/domain/**/*.rb", __dir__)].sort.each { |file| require file }
end
