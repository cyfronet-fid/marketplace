# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::FavouritesController, swagger_doc: "v1/favourites_swagger.json", backend: true do
  before(:all) do
    # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
    Dir.chdir Rails.root.join("swagger", "v1")
  end

  after(:all) do
    # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
    Dir.chdir Rails.root
  end

  let(:user) { create(:user_with_token) }
  let(:"X-User-Token") { user.authentication_token }

  path "/api/v1/favourites" do
    get "lists current user's favourites" do
      tags "Favourites"
      produces "application/json"
      security [authentication_token: []]

      response 200, "ok" do
        schema "$ref" => "#/components/schemas/FavouritesIndexResponse"

        let!(:service1) { create(:service) }
        let!(:service2) { create(:service) }
        let!(:fav1) { UserFavourite.create!(user: user, favoritable: service1) }
        let!(:fav2) { UserFavourite.create!(user: user, favoritable: service2) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["favourites"]).to be_a(Array)
          expect(data["favourites"].size).to eq(2)
          types = data["favourites"].map { |h| h["type"] }.uniq
          expect(types).to eq(["Service"]) # both favourites are services
        end
      end

      response 401, "unauthorized without token" do
        schema "$ref" => "#/components/schemas/ErrorResponse"

        let(:"X-User-Token") { "invalid-token" }

        run_test!
      end
    end

    post "adds a resource to favourites" do
      tags "Favourites"
      consumes "application/json"
      produces "application/json"
      security [authentication_token: []]

      parameter name: :body, in: :body, schema: { "$ref" => "#/components/schemas/FavouriteBody" }

      response 200, "added known Service" do
        schema "$ref" => "#/components/schemas/ActionResponse"

        let(:service) { create(:service) }
        let(:body) { { pid: service.slug, type: "Service" } }

        run_test! { |_response| expect(UserFavourite.where(user: user, favoritable: service)).to exist }
      end

      response 200, "creates ResearchProduct for unknown type" do
        schema "$ref" => "#/components/schemas/ActionResponse"

        let(:pid_value) { "10.5281/zenodo.12345" }
        let(:type_value) { "ZenodoDataset" }
        let(:body) { { pid: pid_value, type: type_value } }

        run_test! do |_response|
          rp = ResearchProduct.find_by(resource_id: pid_value, resource_type: type_value)
          expect(rp).to be_present
          expect(UserFavourite.where(user: user, favoritable: rp)).to exist
        end
      end

      response 400, "missing params" do
        schema "$ref" => "#/components/schemas/ActionErrorResponse"

        let(:body) { { pid: "something" } }

        run_test!
      end

      response 404, "known class but resource not found" do
        schema "$ref" => "#/components/schemas/ActionErrorResponse"

        let(:body) { { pid: "definitely-does-not-exist", type: "Service" } }

        run_test!
      end
    end

    delete "removes a resource from favourites" do
      tags "Favourites"
      consumes "application/json"
      produces "application/json"
      security [authentication_token: []]

      parameter name: :body, in: :body, schema: { "$ref" => "#/components/schemas/FavouriteBody" }

      response 200, "removed existing favourite (Service)" do
        schema "$ref" => "#/components/schemas/ActionResponse"

        let(:service) { create(:service) }
        let!(:fav) { UserFavourite.create!(user: user, favoritable: service) }
        let(:body) { { pid: service.slug, type: "Service" } }

        run_test! { |_response| expect(UserFavourite.where(id: fav.id)).not_to exist }
      end

      response 404, "unknown type without existing ResearchProduct" do
        schema "$ref" => "#/components/schemas/ActionErrorResponse"

        let(:body) { { pid: "10.9999/none", type: "CompletelyUnknown" } }

        run_test!
      end

      response 400, "missing params" do
        schema "$ref" => "#/components/schemas/ActionErrorResponse"

        let(:body) { { type: "Service" } }

        run_test!
      end
    end
  end
end
