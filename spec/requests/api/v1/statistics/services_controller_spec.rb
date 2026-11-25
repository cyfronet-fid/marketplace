# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::Statistics::ServicesController, swagger_doc: "v1/statistics_swagger.json" do
  # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  before(:all) { Dir.chdir Rails.root.join("swagger/v1") }
  after(:all) { Dir.chdir Rails.root }

  before { allow(Mp::Application.config).to receive(:matomo).and_return(matomo) }

  # A Node that syncs Views.
  let(:matomo) do
    Matomo::Configuration.new(
      "MP_MATOMO_ENABLED" => "true",
      "MP_MATOMO_URL" => "https://matomo.example.org/",
      "MP_MATOMO_SITE_ID" => "12",
      "MP_MATOMO_TOKEN_AUTH" => "secret"
    )
  end
  # Any user: the Statistics API needs no role.
  let(:"X-User-Token") { create(:user).authentication_token }

  path "/api/v1/statistics/services" do
    get "lists the statistics of Services, a page at a time" do
      tags "Service statistics"
      produces "application/json"
      security [authentication_token: []]
      parameter name: :from_id,
                in: :query,
                type: :integer,
                required: false,
                description: "List the Services with an id greater than from_id, 0 by default: next_from_id of the " \
                             "previous page"
      parameter name: :limit,
                in: :query,
                type: :integer,
                required: false,
                description: "Services on a page, 100 by default and 1000 at most"
      parameter name: "pid[]",
                getter: :pids,
                in: :query,
                required: false,
                schema: {
                  type: :array,
                  items: {
                    type: :string
                  },
                  maxItems: 100
                },
                description: "Only the Services with these PIDs, 100 at most. A PID that the Node doesn't publish " \
                             "(no published or errored Service has it) is left out of the page, with no error."

      response 200, "a page of statistics found" do
        schema "$ref" => "statistics/service_statistics_index.json"

        let!(:visible) { [create(:service), create(:datasource), create(:service, status: :errored)] }

        before { create(:service, status: :draft) }

        run_test! do |response|
          expect(response.parsed_body).to match(
            "statistics" => visible.map { |service| a_hash_including("pid" => service.pid) },
            "next_from_id" => nil
          )
        end
      end

      context "with three Services" do
        let!(:services) { create_list(:service, 3) }
        let(:from_id) { services.first.id }

        response 200, "a page with a next page", document: false do
          schema "$ref" => "statistics/service_statistics_index.json"

          let(:limit) { 1 }

          run_test! do |response|
            expect(response.parsed_body).to match(
              "statistics" => [a_hash_including("pid" => services.second.pid)],
              "next_from_id" => services.second.id
            )
          end
        end

        response 200, "a full last page", document: false do
          schema "$ref" => "statistics/service_statistics_index.json"

          let(:limit) { 2 }

          run_test! do |response|
            expect(response.parsed_body).to match(
              "statistics" => services.drop(1).map { |service| a_hash_including("pid" => service.pid) },
              "next_from_id" => nil
            )
          end
        end
      end

      context "with more Services than the default limit" do
        let!(:services) { create_list(:service, 101) }

        response 200, "a page of 100 by default", document: false do
          schema "$ref" => "statistics/service_statistics_index.json"

          run_test! do |response|
            statistics, next_from_id = response.parsed_body.values_at("statistics", "next_from_id")

            expect([statistics.size, next_from_id]).to eq([100, services[99].id])
          end
        end
      end

      response 200, "statistics of the Services with the given PIDs found", document: false do
        schema "$ref" => "statistics/service_statistics_index.json"

        let!(:wanted) { create_list(:service, 2) }
        # Besides the wanted PIDs, an unknown one and a draft Service's.
        let(:pids) { [wanted.first.pid, "21.T15999/unknown", create(:service, status: :draft).pid, wanted.last.pid] }

        # A published Service not asked for.
        before { create(:service) }

        run_test! do |response|
          expect(response.parsed_body).to match(
            "statistics" => wanted.map { |service| a_hash_including("pid" => service.pid) },
            "next_from_id" => nil
          )
        end
      end

      response 400, "more than 100 PIDs", document: false do
        schema "$ref" => "error.json"

        let(:pids) { Array.new(101) { |n| "21.T15999/#{n}" } }

        run_test! { |response| expect(response.parsed_body).to eq("error" => "'pid' must hold at most 100 PIDs") }
      end

      response 200, "a page of the maximum limit", document: false do
        schema "$ref" => "statistics/service_statistics_index.json"

        let(:limit) { 1000 }

        run_test!
      end

      response 400, "from_id, limit or pid[] not valid" do
        schema "$ref" => "error.json"

        let(:limit) { 1001 }

        run_test! do |response|
          expect(response.parsed_body).to eq("error" => "'limit' must be an integer from 1 to 1000")
        end
      end

      response 400, "limit of 0", document: false do
        schema "$ref" => "error.json"

        let(:limit) { 0 }

        run_test! do |response|
          expect(response.parsed_body).to eq("error" => "'limit' must be an integer from 1 to 1000")
        end
      end

      response 400, "negative from_id", document: false do
        schema "$ref" => "error.json"

        let(:from_id) { -1 }

        run_test! do |response|
          expect(response.parsed_body).to eq("error" => "'from_id' must be a non-negative integer")
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"

        let(:"X-User-Token") { "unknown" }

        run_test! do |response|
          expect(response.parsed_body).to eq("error" => "You need to sign in or sign up before continuing.")
        end
      end
    end
  end

  # rswag sends pid only as the list it documents.
  { "a single PID" => "21.T15999/abc", "a hash" => { "a" => "21.T15999/abc" } }.each do |form, pid|
    it "refuses pid given as #{form}, not as pid[]" do
      token = create(:user).authentication_token
      get "/api/v1/statistics/services", params: { pid: }, headers: { "X-User-Token" => token }

      expect(response.parsed_body).to eq("error" => "'pid' must be a list of PIDs: pid[]=…&pid[]=…")
    end
  end

  # rswag sends from_id and limit only as the integers it documents.
  {
    { from_id: "abc" } => "'from_id' must be a non-negative integer",
    { from_id: ["1"] } => "'from_id' must be a non-negative integer",
    { limit: "5abc" } => "'limit' must be an integer from 1 to 1000",
    { limit: ["1"] } => "'limit' must be an integer from 1 to 1000",
    { from_id: "-1", limit: "0" } =>
      "'from_id' must be a non-negative integer; 'limit' must be an integer from 1 to 1000"
  }.each do |query, error|
    it "refuses #{CGI.unescape(query.to_query)} with a 400" do
      token = create(:user).authentication_token
      get "/api/v1/statistics/services", params: query, headers: { "X-User-Token" => token }

      expect(response).to have_http_status(:bad_request).and have_attributes(parsed_body: { "error" => error })
    end
  end

  # Without Accept: application/json too, which rswag always sends.
  it "refuses a request without a token with a 401, not a redirect to the sign-in page" do
    get "/api/v1/statistics/services"

    expect(response).to have_http_status(:unauthorized)
      .and have_attributes(parsed_body: { "error" => "You need to sign in or sign up before continuing." })
  end

  path "/api/v1/statistics/services/{pid}" do
    parameter name: :pid, in: :path, type: :string, description: "PID of the Service, which may contain one /"

    get "retrieves the statistics of a Service" do
      tags "Service statistics"
      produces "application/json"
      security [authentication_token: []]

      response 200, "statistics found" do
        schema "$ref" => "statistics/service_statistics_read.json"

        # Two Offers, two Orders, one open access Project item, which is no
        # Order, an Opinion and 1250 Views.
        let(:pid) do
          create(:service, pid: "21.T15999/abc", usage_counts_views: 1250).tap do |service|
            orders = create_list(:project_item, 2, offer: create(:offer, service:))
            create(:project_item, offer: create(:open_access_offer, service:))
            create(:service_opinion, project_item: orders.first)
          end.pid
        end

        run_test! do |response|
          expect(response.parsed_body).to eq(
            "pid" => "21.T15999/abc", "offers_count" => 2, "service_opinion_count" => 1,
            "project_items_count" => 3, "usage_counts_views" => 1250, "usage_counts_downloads" => 2
          )
        end
      end

      response 200, "statistics of a Datasource found", document: false do
        schema "$ref" => "statistics/service_statistics_read.json"

        let(:pid) { create(:datasource, pid: "21.T15999/data").pid }

        run_test! { |response| expect(response.parsed_body["pid"]).to eq("21.T15999/data") }
      end

      {
        "Matomo is off" => { "MP_MATOMO_ENABLED" => "false", "MP_MATOMO_TOKEN_AUTH" => "secret" },
        "MP_MATOMO_TOKEN_AUTH is not set" => {
          "MP_MATOMO_ENABLED" => "true",
          "MP_MATOMO_URL" => "https://matomo.example.org/",
          "MP_MATOMO_SITE_ID" => "12"
        }
      }.each do |reason, env|
        response 200, "statistics found without Views when #{reason}", document: false do
          schema "$ref" => "statistics/service_statistics_read.json"

          let(:matomo) { Matomo::Configuration.new(env) }
          let(:pid) { create(:service, usage_counts_views: 1250).pid }

          run_test! { |response| expect(response.parsed_body).to include("usage_counts_views" => nil) }
        end
      end

      response 404, "the Node publishes no Service with the PID" do
        schema "$ref" => "error.json"

        let(:pid) { "21.T15999/unknown" }

        run_test! { |response| expect(response.parsed_body).to eq("error" => "Service not found") }
      end

      %i[draft suspended deleted].each do |status|
        response 404, "a #{status} Service not found", document: false do
          schema "$ref" => "error.json"

          let(:pid) { create(:service, status:).pid }

          run_test! { |response| expect(response.parsed_body).to eq("error" => "Service not found") }
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"

        let(:"X-User-Token") { "unknown" }
        let(:pid) { "21.T15999/abc" }

        run_test! do |response|
          expect(response.parsed_body).to eq("error" => "You need to sign in or sign up before continuing.")
        end
      end
    end
  end
end
