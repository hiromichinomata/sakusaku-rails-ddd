require "webmock/rspec"

# テストから外部のサービスに本当につながないようにする（localhost は除く）
WebMock.disable_net_connect!(allow_localhost: true)
