# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::UsersController, :backend, swagger_doc: "v1/users_swagger.json", type: :request do
  around do |example|
    original_dir = Dir.pwd
    Dir.chdir Rails.root.join("swagger/v1")
    example.run
  ensure
    Dir.chdir original_dir
  end

  path "/api/v1/users/{user_id}" do
    parameter name: "user_id", in: :path, type: :string, required: true, description: "User unique identifier"

    get("Get user roles") do
      tags "Users"
      description "Returns roles for a specific user"
      produces "application/json"
      security [authentication_token: []]

      parameter name: :user_id, in: :path, type: :string, required: true, description: "Unique identifier of the user"

      response(200, "successful") do
        schema "$ref" => "user/user_read.json"

        let(:user_id) { "test-user-uid" }
        let(:user) { create(:user, uid: user_id) }
        let(:"X-User-Token") { user.authentication_token }

        before { user.update(roles: %i[admin coordinator]) }

        run_test! do |response|
          aggregate_failures do
            data = JSON.parse(response.body)
            expect(data["uid"]).to eq(user_id)
            expect(data["roles"]).to include("coordinator", "admin")
          end
        end
      end

      response(200, "successful through a checkin identity on pl", document: false) do
        schema "$ref" => "user/user_read.json"

        let(:user_id) { "test-user-uid" }
        let(:user) { create(:user, roles: %i[admin coordinator]) }
        let(:"X-User-Token") { user.authentication_token }
        let!(:identity) { create(:user_identity, user: user, provider: "checkin", uid: user_id, primary: true) }

        # rubocop:disable RSpec/ScatteredSetup -- each rswag `response` block is its own example group
        before { allow(Mp::Variant).to receive(:pl?).and_return(true) }
        # rubocop:enable RSpec/ScatteredSetup

        run_test! do |response|
          expect(JSON.parse(response.body)["uid"]).to eq(identity.uid)
        end
      end

      response(404, "user not found") do
        schema "$ref" => "error.json"

        let(:user_id) { "nonexistent-uid" }
        let(:"X-User-Token") { create(:user).authentication_token }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref" => "error.json"

        # rubocop:disable RSpec/EmptyExampleGroup -- `run_test!` defines the example; rubocop-rspec doesn't know rswag's DSL
        context "when no token provided" do
          let(:"X-User-Token") { "" }
          let(:user_id) { "test-uid" }

          run_test!
        end

        context "when invalid token provided" do
          let(:"X-User-Token") { "invalid-token" }
          let(:user_id) { "test-uid" }

          run_test!
        end
        # rubocop:enable RSpec/EmptyExampleGroup
      end
    end
  end
end
