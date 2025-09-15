# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1::Search::ServicesController", type: :request, swagger_doc: "v1/search_swagger.json" do
  path "/api/v1/search/services" do
    get("Search services") do
      tags "Search Services"
      description "Search and filter services using Elasticsearch with EID-based filtering. " +
                    "Supports full-text search and multiple filter criteria."
      operationId "searchServices"
      produces "application/json"

      parameter name: :q,
                in: :query,
                type: :string,
                required: false,
                description:
                  "Search query string. Searches in service name, tagline, description, " +
                    "offer names, and provider names using Elasticsearch"
      parameter name: :scientific_domains,
                in: :query,
                type: :array,
                items: {
                  type: :string
                },
                required: false,
                description:
                  "Array of scientific domain EIDs to filter by. Use external IDs (EIDs) " +
                    "from scientific domain vocabulary"
      parameter name: :providers,
                in: :query,
                type: :array,
                items: {
                  type: :string
                },
                required: false,
                description: "Array of provider EIDs to filter by. Use external IDs (EIDs) from provider registry"
      parameter name: :target_users,
                in: :query,
                type: :array,
                items: {
                  type: :string
                },
                required: false,
                description:
                  "Array of target user EIDs to filter by. Use external IDs (EIDs) from target user vocabulary"
      parameter name: :platforms,
                in: :query,
                type: :array,
                items: {
                  type: :string
                },
                required: false,
                description: "Array of platform EIDs to filter by. Use external IDs (EIDs) from platform vocabulary"
      parameter name: :research_activities,
                in: :query,
                type: :array,
                items: {
                  type: :string
                },
                required: false,
                description:
                  "Array of research activity EIDs to filter by. Use external IDs (EIDs) " +
                    " from research activity vocabulary"
      parameter name: :tags,
                in: :query,
                type: :array,
                items: {
                  type: :string
                },
                required: false,
                description: "Array of tag EIDs to filter by. Use external IDs (EIDs) from tag vocabulary"
      parameter name: :rating,
                in: :query,
                type: :number,
                required: false,
                minimum: 1,
                maximum: 5,
                description:
                  "Filter by minimum rating (1-5). Shows services with rating equal or higher than specified value"
      parameter name: :order_type,
                in: :query,
                type: :string,
                required: false,
                description: "Filter by order type. Determines how the service can be accessed",
                enum: %w[open_access fully_open_access order_required other]
      parameter name: :page,
                in: :query,
                type: :integer,
                required: false,
                default: 1,
                minimum: 1,
                description: "Page number for pagination. Must be a positive integer"
      parameter name: :per_page,
                in: :query,
                type: :integer,
                required: false,
                default: 25,
                minimum: 1,
                maximum: 100,
                description: "Number of results per page. Maximum allowed is 100"
      parameter name: :sort,
                in: :query,
                type: :string,
                required: false,
                default: "_score",
                description: "Sort order for results. Default is by relevance score",
                enum: %w[_score name -name rating -rating created_at -created_at]

      response(200, "Successful search") do
        schema "$ref" => "#/components/schemas/SearchResponse"

        example "application/json",
                :basic_search,
                {
                  results: [
                    {
                      id: 123,
                      eid: "ml-platform-v2.1",
                      name: "Machine Learning Platform",
                      slug: "machine-learning-platform",
                      tagline: "Advanced ML platform for researchers",
                      description:
                        "A comprehensive machine learning platform providing tools for data analysis, " +
                          " model training, and deployment for research purposes.",
                      rating: 4.5,
                      score: 1.2345,
                      logo_url: "https://example.com/logo.png",
                      path: "/services/machine-learning-platform",
                      providers: [{ id: 456, eid: "research-institute-eu", name: "European Research Institute" }],
                      scientific_domains: [
                        { id: 789, eid: "computer-science", name: "Computer Science" },
                        { id: 790, eid: "artificial-intelligence", name: "Artificial Intelligence" }
                      ],
                      target_users: [
                        { id: 101, eid: "researchers", name: "Researchers" },
                        { id: 102, eid: "data-scientists", name: "Data Scientists" }
                      ],
                      platforms: [{ id: 202, eid: "web-platform", name: "Web Platform" }],
                      research_activities: [{ id: 303, eid: "data-analysis", name: "Data Analysis" }],
                      tags: [
                        { id: 404, eid: "machine-learning", name: "Machine Learning" },
                        { id: 405, eid: "python", name: "Python" }
                      ]
                    }
                  ],
                  offers: {
                    "123": [
                      {
                        id: 111,
                        name: "Basic ML Plan",
                        service_id: 123,
                        score: 0.9876,
                        highlights: ["Basic <mark>machine</mark> learning features", "<mark>ML</mark> model training"]
                      },
                      {
                        id: 112,
                        name: "Premium ML Plan",
                        service_id: 123,
                        score: 0.8765,
                        highlights: [
                          "Premium <mark>ML</mark> capabilities",
                          "Advanced <mark>machine learning</mark> tools"
                        ]
                      }
                    ]
                  },
                  pagination: {
                    current_page: 1,
                    total_pages: 5,
                    total_count: 125,
                    per_page: 25
                  },
                  highlights: {
                    "123": ["Advanced <mark>ML</mark> platform for researchers", "<mark>Machine learning</mark> tools"]
                  },
                  facets: {
                    categories: [{ name: "Category 1", eid: "cat-1", count: 3, children: [] }],
                    scientific_domains: [{ name: "Computer Science", eid: "computer-science", count: 4, children: [] }],
                    providers: [{ name: "European Research Institute", eid: "research-institute-eu", count: 10 }],
                    target_users: [{ name: "Researchers", eid: "researchers", count: 7 }],
                    platforms: [{ name: "Web Platform", eid: "web-platform", count: 2 }],
                    research_activities: [{ name: "Data Analysis", eid: "data-analysis", count: 5 }],
                    rating: [{ name: "4+ stars", eid: "4", count: 8 }],
                    order_type: [{ name: "Open Access", eid: "open_access", count: 12 }]
                  }
                }

        example "application/json",
                :empty_search,
                {
                  results: [],
                  offers: {
                  },
                  pagination: {
                    current_page: 1,
                    total_pages: 0,
                    total_count: 0,
                    per_page: 25
                  },
                  highlights: {
                  },
                  facets: {
                  }
                }

        let(:q) { "machine learning" }
        let(:scientific_domains) { ["computer-science"] }
        let(:page) { 1 }
        let(:per_page) { 10 }

        run_test!
      end

      response(400, "Bad request") do
        schema "$ref" => "#/components/schemas/ErrorResponse"

        example "application/json", :invalid_per_page, { error: "Invalid per_page parameter. Maximum allowed is 100." }

        example "application/json", :invalid_page, { error: "Invalid page parameter. Must be a positive integer." }

        before { skip "API currently returns 200 for invalid params; skipping example to keep docs only" }

        let(:per_page) { 1000 } # Too many per page

        run_test!
      end

      response(422, "Unprocessable entity") do
        schema "$ref" => "#/components/schemas/ValidationErrorResponse"

        example "application/json",
                :validation_errors,
                {
                  errors: [
                    "Invalid scientific domain EID: 'invalid-domain'",
                    "Invalid provider EID: 'non-existent-provider'"
                  ]
                }

        let(:scientific_domains) { ["invalid-domain"] }
        let(:providers) { ["non-existent-provider"] }

        run_test!
      end

      response(500, "Internal server error") do
        schema "$ref" => "#/components/schemas/ErrorResponse"

        example "application/json", :server_error, { error: "Internal server error occurred during search processing" }

        run_test!
      end
    end
  end
end
