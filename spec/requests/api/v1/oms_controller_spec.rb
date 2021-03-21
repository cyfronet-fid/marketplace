# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe "OMS API", swagger_doc: "v1/ordering/swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1", "ordering") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/oms/{id}" do
    parameter name: :id, in: :path, type: :string, description: "OMS id"

    get "retrieves an OMS" do
      tags "OMS"
      produces "application/json"

      response 200, "OMS found" do
        # TODO: Define OMS schema
        let(:id) { 1 }
        run_test!
        # TODO: test functionality
      end
    end

    patch "updates an OMS" do
      tags "OMS"
      produces "application/json"
      consumes "application/json"

      response "200", "OMS updated" do
        # TODO: Define OMS schema
        let(:id) { 1 }
        run_test!
        # TODO: test functionality
      end
    end
  end
end
