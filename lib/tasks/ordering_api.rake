# frozen_string_literal: true

require "ordering_api/add_sombo"

namespace :ordering_api do
  task add_sombo: :environment do
    OrderingApi::AddSombo.new.call
  end

  task add_provider_oms: :environment do
    OrderingApi::AddProviderOMS.new(
      ENV.fetch("ARG_OMS_NAME", nil),
      ENV.fetch("ARG_PROVIDER_PID", nil),
      ENV.fetch("ARG_AUTHENTICATION_TOKEN", nil)
    ).call
  end

  task authorization_test_setup: :environment do
    OrderingApi::AuthorizationTestSetup.new.call
  end

  task triggers_test_setup: :environment do
    OrderingApi::TriggersTestSetup.new.call
  end
end
