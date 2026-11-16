# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("swagger")

  # The 'rswag:specs:swaggerize' rake task writes the complete document
  # to the relative path below, under openapi_root.
  # All spec files add their operations to this document.
  config.openapi_specs = {
    "v1/spec.json" => {
      openapi: "3.0.1",
      info: {
        title: "EOSC Marketplace API",
        version: "v1",
        description: <<~DESCRIPTION
          REST API of the EOSC Marketplace. The API has these parts:

          - Offering (`/api/v1/resources`): the offers of the resources that a user administers.
          - Ordering (`/api/v1/oms`): the integration of an Order Management System with the ordering process.
          - ESS (`/api/v1/ess`): the collections that the Search Service reads.
          - Users (`/api/v1/users`): the user configuration for external clients.
          - Search (`/api/v1/search`): the search and the filters of the services.
          - Catalogue (`/api/v1/catalogue`): the public catalogue of the services. Only the pl variant has this part.
        DESCRIPTION
      },
      paths: {},
      components: {
        securitySchemes: {
          authentication_token: {
            type: :apiKey,
            name: "X-User-Token",
            in: :header
          }
        },
        schemas: {
          **Api::V1::ComponentSchema.all,
          CatalogueService: {
            type: :object,
            description: "Subset of the Service entity as published in Catalogue API",
            properties: {
              id: {
                type: :string,
                description: "PID"
              },
              webpage: {
                type: :string,
                nullable: true
              },
              tags: {
                type: :array,
                items: {
                  type: :string
                }
              },
              languageAvailabilities: {
                type: :array,
                items: {
                  type: :string
                }
              },
              trl: {
                type: :string,
                nullable: true,
                example: "trl-9"
              },
              userManual: {
                type: :string,
                nullable: true
              },
              termsOfUse: {
                type: :string,
                nullable: true
              },
              privacyPolicy: {
                type: :string,
                nullable: true
              },
              accessPolicy: {
                type: :string,
                nullable: true
              },
              orderType: {
                type: :string,
                example: "order_type-open_access"
              },
              logo: {
                type: :string,
                format: :uri
              },
              alternativeIdentifiers: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    type: {
                      type: :string
                    },
                    value: {
                      type: :string
                    }
                  },
                  required: %w[type value]
                }
              },
              abbreviation: {
                type: :string,
                nullable: true
              },
              name: {
                type: :string
              },
              description: {
                type: :string,
                nullable: true
              },
              tagline: {
                type: :string,
                nullable: true
              },
              targetUsers: {
                type: :array,
                items: {
                  type: :string
                }
              },
              accessModes: {
                type: :array,
                items: {
                  type: :string
                }
              },
              helpdeskEmail: {
                type: :string,
                nullable: true
              },
              securityContactEmail: {
                type: :string,
                nullable: true
              },
              scientificDomains: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    scientificDomain: {
                      type: :string,
                      example: "scientific_domain-natural_sciences"
                    },
                    scientificSubdomain: {
                      type: :string,
                      example: "scientific_subdomain-natural_sciences-biological_sciences"
                    }
                  },
                  required: ["scientificDomain"]
                }
              },
              categories: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    category: {
                      type: :string,
                      example: "category-access_physical_and_einfrastructures-compute"
                    },
                    subcategory: {
                      type: :string,
                      example: "subcategory-access_physical_and_einfrastructures-compute-orchestration"
                    }
                  },
                  required: ["category"]
                }
              }
            },
            required: %w[id name logo orderType]
          },
          SearchResponse: {
            type: :object,
            properties: {
              results: {
                type: :array,
                items: {
                  type: :object
                }
              },
              offers: {
                type: :object,
                additionalProperties: {
                  type: :array,
                  items: {
                    type: :object
                  }
                }
              },
              pagination: {
                type: :object,
                properties: {
                  current_page: {
                    type: :integer
                  },
                  total_pages: {
                    type: :integer
                  },
                  total_count: {
                    type: :integer
                  },
                  per_page: {
                    type: :integer
                  }
                }
              },
              highlights: {
                type: :object,
                additionalProperties: {
                  type: :array,
                  items: {
                    type: :string
                  }
                }
              },
              facets: {
                type: :object,
                properties: {
                  categories: {
                    type: :array,
                    items: {
                      type: :object
                    }
                  },
                  scientific_domains: {
                    type: :array,
                    items: {
                      type: :object
                    }
                  },
                  providers: {
                    type: :array,
                    items: {
                      type: :object
                    }
                  },
                  research_activities: {
                    type: :array,
                    items: {
                      type: :object
                    }
                  },
                  rating: {
                    type: :array,
                    items: {
                      type: :object
                    }
                  },
                  order_type: {
                    type: :array,
                    items: {
                      type: :object
                    }
                  }
                }
              }
            }
          },
          ErrorResponse: {
            type: :object,
            properties: {
              error: {
                type: :string
              }
            }
          },
          ValidationErrorResponse: {
            type: :object,
            properties: {
              errors: {
                type: :array,
                items: {
                  type: :string
                }
              }
            }
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
