# frozen_string_literal: true

require "test_bootstrap/omses_with_different_custom_params"

namespace :test_bootstrap do
  task :add_role_to_user, %i[email role] => :environment do |_, args|
    TestBootstrap::AddRoleToUser.new(args.email, args.role).call
  end

  task omses_with_different_custom_params: :environment do
    TestBootstrap::OMSesWithDifferentCustomParams.new.call
  end
end
