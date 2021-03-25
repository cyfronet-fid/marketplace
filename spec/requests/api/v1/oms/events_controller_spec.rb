# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"


RSpec.describe "OMS Events API", swagger_doc: "v1/ordering/swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1", "ordering") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/oms/{oms_id}/events" do
    parameter name: :oms_id, in: :path, type: :string, description: "OMS id"

    get "lists events" do
      tags "Events"
      produces "application/json"
      security [ authentication_token: [] ]
      parameter name: :from_timestamp, in: :query, type: :string, required: true,
                description: "List events after"
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: "number of returned elements"

      response 200, "events found" do
        schema "$ref" => "event/event_index.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:from_timestamp) { "2018-09-15T15:53:00+00:00" }
        run_test!
        # TODO: test functionality
      end
    end
  end
end
