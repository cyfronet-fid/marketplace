# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::Catalogue::ServicesController, swagger_doc: "v1/catalogue_swagger.json" do
  include RequestSpecHelper

  before(:all) do
    # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
    Dir.chdir Rails.root.join("swagger/v1")
  end

  after(:all) { Dir.chdir Rails.root }

  # The catalogue API is routed only under the pl variant.
  before do
    allow(Mp::Variant).to receive(:pl?).and_return(true)
    Rails.application.reload_routes!
  end

  after do
    allow(Mp::Variant).to receive(:pl?).and_call_original
    Rails.application.reload_routes!
  end

  path "/api/v1/catalogue/services" do
    get "List catalogue services" do
      tags "services"
      produces "application/json"

      parameter name: :keyword, in: :query, type: :string, required: false, description: "Full-text search keyword"
      parameter name: :from,
                in: :query,
                schema: {
                  type: :integer,
                  minimum: 0,
                  default: 0
                },
                required: false,
                description: "Offset of the first record"
      parameter name: :quantity,
                in: :query,
                schema: {
                  type: :integer,
                  minimum: 1,
                  default: 10
                },
                required: false,
                description: "Number of records to return"
      parameter name: :order,
                in: :query,
                schema: {
                  type: :string,
                  enum: %w[asc desc],
                  default: "asc"
                },
                required: false,
                description: "Sort order for name/sort_name"

      response 200, "returns a paginated list" do
        schema type: :object,
               properties: {
                 total: {
                   type: :integer
                 },
                 from: {
                   type: :integer
                 },
                 to: {
                   type: :integer
                 },
                 results: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: {
                         type: :string
                       },
                       service: {
                         "$ref" => "#/components/schemas/CatalogueService"
                       }
                     },
                     required: %w[id service]
                   }
                 }
               },
               required: %w[total from to results]

        let!(:visible_services) do
          [
            create(:service, name: "AAA Service", status: :published),
            create(:service, name: "BBB Service", status: :suspended),
            create(:service, name: "CCC Service", status: :published)
          ]
        end
        let!(:hidden_draft) { create(:service, status: :draft, name: "ZZZ Draft") }
        let!(:hidden_deleted) { create(:service, status: :deleted, name: "YYY Deleted") }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["total"]).to eq(visible_services.count)
          expect(body["from"]).to eq(0)
          expect(body["to"]).to eq(10)

          ids = body["results"].map { |r| r["id"] }
          expect(ids).to match_array(visible_services.map(&:pid))
          expect(ids).not_to include(hidden_draft.pid, hidden_deleted.pid)

          names = body["results"].map { |r| r["service"]["name"] }
          expect(names).to eq(["AAA Service", "BBB Service", "CCC Service"])
        end
      end

      response(200, "supports pagination and ordering", document: false) do
        let!(:services) do
          %w[Alpha Beta Gamma Delta Epsilon Zeta Eta Theta Iota Kappa Lambda].map do |n|
            create(:service, name: n, status: :published)
          end
        end

        let(:from) { 3 }
        let(:quantity) { 5 }
        let(:order) { "desc" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["total"]).to eq(services.size)
          expect(data["from"]).to eq(3)
          expect(data["to"]).to eq(8)

          expected_slice = services.sort_by(&:name).reverse.map(&:pid).slice(3, 5)
          expect(data["results"].map { |r| r["id"] }).to eq(expected_slice)
        end
      end

      response(200, "coerces invalid params", document: false) do
        let!(:services) { create_list(:service, 12, status: :published) }

        let(:from) { -10 }
        let(:quantity) { 0 }
        let(:order) { "sideways" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["from"]).to eq(0)
          expect(data["to"]).to eq(10)
          expect(data["results"].size).to eq(10)

          expected_ids = services.sort_by(&:name).map(&:pid).first(10)
          expect(data["results"].map { |r| r["id"] }).to eq(expected_ids)
        end
      end
    end
  end
end
