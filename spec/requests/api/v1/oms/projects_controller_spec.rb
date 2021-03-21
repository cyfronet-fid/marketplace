# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"


RSpec.describe "OMS Projects API", swagger_doc: "v1/ordering/swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1", "ordering") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/oms/{oms_id}/projects" do
    parameter name: :oms_id, in: :path, type: :integer, description: "OMS id"

    get "lists projects" do
      tags "Projects"
      produces "application/json"
      parameter name: :from_id, in: :query, type: :integer, required: false,
                description: "List projects with id greater than from_id"
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: "Limit of projects listed"

      response 200, "projects found" do
        schema "$ref" => "project/project_index.json"
        let(:oms_id) { 1 }
        run_test!
        # TODO: test functionality
      end
    end
  end

  path "/api/v1/oms/{oms_id}/projects/{p_id}" do
    parameter name: :oms_id, in: :path, type: :string, description: "OMS id"
    parameter name: :p_id, in: :path, type: :string, description: "Project id"

    get "retrieves a project" do
      tags "Projects"
      produces "application/json"

      response 200, "project found" do
        schema "$ref" => "project/project_read.json"
        let(:oms_id) { 1 }
        let(:p_id) { 1 }
        run_test!
        # TODO: test functionality
      end
    end
  end
end
