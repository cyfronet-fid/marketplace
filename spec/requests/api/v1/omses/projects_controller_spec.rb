# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::OMSes::ProjectsController, swagger_doc: "v1/ordering_swagger.json", backend: true do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/oms/{oms_id}/projects" do
    parameter name: :oms_id, in: :path, type: :integer, description: "OMS id"

    get "lists projects" do
      tags "Projects"
      produces "application/json"
      security [authentication_token: []]
      parameter name: :from_id,
                in: :query,
                type: :integer,
                required: false,
                description: "List projects with id greater than from_id"
      parameter name: :limit, in: :query, type: :integer, required: false, description: "Limit of projects listed"

      response 200, "projects found" do
        schema "$ref" => "project/project_index.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:other_oms) { create(:oms, administrators: [oms_admin]) }
        let!(:projects) do
          [
            create(:project, project_items: [build(:project_item, offer: build(:offer, primary_oms: oms))], id: 1),
            create(:project, project_items: [build(:project_item, offer: build(:offer, primary_oms: oms))], id: 2),
            create(
              :project,
              project_items: [build(:project_item, offer: build(:offer, primary_oms: other_oms))],
              id: 3
            ),
            create(:project, project_items: [build(:project_item, offer: build(:offer, primary_oms: oms))], id: 4),
            create(:project, project_items: [build(:project_item, offer: build(:offer, primary_oms: oms))], id: 5)
          ]
        end
        let(:from_id) { 1 }
        let(:limit) { 2 }
        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(
            {
              projects: projects.values_at(1, 3).map { |p| Api::V1::ProjectSerializer.new(p).as_json }
            }.deep_stringify_keys
          )
        end
      end

      response 200, "projects found but were empty", document: false do
        schema "$ref" => "project/project_index.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ projects: [] }.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:oms_id) { 1 }
        let(:"X-User-Token") { "asdasdasd" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized to access this OMS" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:user) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 404, "OMS not found" do
        schema "$ref" => "error.json"
        let(:user) { create(:user) }

        let(:oms_id) { 9999 }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "OMS not found" }.deep_stringify_keys)
        end
      end
    end
  end

  path "/api/v1/oms/{oms_id}/projects/{p_id}" do
    parameter name: :oms_id, in: :path, type: :string, description: "OMS id"
    parameter name: :p_id, in: :path, type: :string, description: "Project id"

    get "retrieves a project" do
      tags "Projects"
      produces "application/json"
      security [authentication_token: []]

      response 200, "project found" do
        schema "$ref" => "project/project_read.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) do
          create(:project, project_items: [build(:project_item, offer: build(:offer, primary_oms: oms))])
        end

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(Api::V1::ProjectSerializer.new(project).as_json.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:oms_id) { 1 }
        let(:p_id) { 1 }
        let(:"X-User-Token") { "asdasdasd" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized" do
        schema "$ref" => "error.json"
        let(:oms1_admin) { create(:user) }
        let(:oms2_admin) { create(:user) }
        let(:oms1) { create(:oms, administrators: [oms1_admin]) }
        let(:oms2) { create(:oms, administrators: [oms2_admin]) }
        let(:project) do
          create(:project, project_items: [build(:project_item, offer: build(:offer, primary_oms: oms1))])
        end

        let(:oms_id) { oms1.id }
        let(:p_id) { project.id }
        let(:"X-User-Token") { oms2_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized to access this OMS" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:user) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:p_id) { 1 }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 404, "OMS not found" do
        schema "$ref" => "error.json"
        let(:user) { create(:user) }

        let(:oms_id) { 9999 }
        let(:p_id) { 9999 }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "OMS not found" }.deep_stringify_keys)
        end
      end

      response 404, "project not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:other_oms) { create(:oms) }
        let(:project) do
          create(:project, project_items: [build(:project_item, offer: build(:offer, primary_oms: other_oms))])
        end

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Project not found" }.deep_stringify_keys)
        end
      end
    end
  end
end
