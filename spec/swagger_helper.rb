# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.join("swagger")

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.swagger_docs = {
    "v1/offering/swagger.json" => {
      openapi: "3.0.1",
      info: {
        title: "EOSC Marketplace Offering API",
        version: "v1",
        # TODO: Change description
        description: "Documentation of the EOSC Marketplace REST API for integration of other software systems"
      },
      paths: {},
      components: {
        securitySchemes: {
          authentication_token: {
            type: :apiKey,
            name: "X-User-Token",
            in: :header
          }
        }
      }
    },
    "v1/ordering/swagger.json" => {
      openapi: "3.0.1",
      info: {
        title: "EOSC Marketplace Ordering API",
        version: "v1",
        # TODO: Change description
        description: "Ordering API"
      },
      paths: {},
      components: {
        securitySchemes: {
          authentication_token: {
            type: :apiKey,
            name: "X-User-Token",
            in: :header
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.swagger_format = :json
end
