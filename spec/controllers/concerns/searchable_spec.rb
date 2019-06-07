# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    attr_accessor :params
    include Service::Searchable
  end

  context "#search" do
    before { Searchkick.enable_callbacks }
    after { Searchkick.disable_callbacks }

    it "don't duplicate results when service belongs to many providers" do
      Searchkick.enable_callbacks
      provider1, provider2 = create_list(:provider, 2)
      create(:service, providers: [provider1, provider2])

      # scope.count == 2 => results are duplicated
      scope = Service.joins(:service_providers).
        where(service_providers: { provider_id: [provider1.id, provider2.id] })

      expect(controller.search(scope, []).count).to eq(1)
    end
  end
end
