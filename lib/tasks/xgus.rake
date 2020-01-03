# frozen_string_literal: true

namespace :xgus do
  desc "Check xGUS configuration"

  task check: :environment do
    Xgus::Checker.new.check
  end
end
