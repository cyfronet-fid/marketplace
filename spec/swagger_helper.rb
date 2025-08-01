# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("swagger")

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.openapi_specs = {
    "v1/offering_swagger.json" => {
      openapi: "3.0.1",
      info: {
        title: "EOSC Marketplace Offering API",
        version: "v1",
        # TODO: Change description
        description: "Documentation of the EOSC Marketplace REST API for integration of other software systems"
      },
      paths: {
      },
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
    "v1/ordering_swagger.json" => {
      openapi: "3.0.1",
      info: {
        title: "EOSC Marketplace Ordering API",
        version: "v1",
        description: "API for Order Management Systems to integrate with EOSC Marketplace ordering process"
      },
      paths: {
      },
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
    "v1/ess_swagger.json" => {
      openapi: "3.0.1",
      info: {
        title: "EOSC Marketplace search API",
        version: "v1",
        description: "API for Search Service to integrate with EOSC Marketplace collections"
      },
      paths: {
      },
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
    "v1/users_swagger.json" => {
      openapi: "3.0.1",
      info: {
        title: "EOSC User API",
        version: "v1",
        description: "API for external clients loading user configuration"
      },
      paths: {
      },
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

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.\
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :json
end
