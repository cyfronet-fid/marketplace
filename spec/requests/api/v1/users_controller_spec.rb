# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::UsersController, swagger_doc: "v1/users_swagger.json", backend: true do
  around do |example|
    original_dir = Dir.pwd
    Dir.chdir Rails.root.join("swagger", "v1")
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
          data = JSON.parse(response.body)
          expect(data["uid"]).to eq(user_id)
          expect(data["roles"]).to include("coordinator", "admin")
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
      end
    end
  end
end
