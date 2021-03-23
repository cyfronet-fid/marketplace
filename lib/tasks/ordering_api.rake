# frozen_string_literal: true

require "ordering_api/add_sombo"

namespace :ordering_api do
  desc "Add global SOMBO OMS"
  task add_sombo: :environment do
    OrderingApi::AddSombo.new.call
  end
end
