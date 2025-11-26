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
    },
    "v1/search_swagger.json" => {
      openapi: "3.0.1",
      info: {
        title: "EOSC Marketplace Search API",
        version: "v1",
        description: "API for searching and filtering services with advanced Elasticsearch capabilities"
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
        },
        schemas: {
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
                  target_users: {
                    type: :array,
                    items: {
                      type: :object
                    }
                  },
                  platforms: {
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
    },
    "v1/favourites_swagger.json" => {
      openapi: "3.0.1",
      info: {
        title: "EOSC Marketplace Favourites API",
        version: "v1",
        description: "API for managing a user's favourite resources"
      },
      paths: {
      },
      components: {
        securitySchemes: {
          authentication_token: {
            type: :apiKey,
            name: "X-User-Token",
            in: :header
          },
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT
          }
        },
        schemas: {
          FavouriteBody: {
            type: :object,
            required: %i[pid type],
            properties: {
              pid: {
                type: :string,
                description: "Resource identifier"
              },
              type: {
                type: :string,
                description: "Resource class name (e.g., Service, Offer, ResearchProduct)"
              }
            }
          },
          FavouriteItem: {
            type: :object,
            properties: {
              type: {
                type: :string
              },
              pid: {
                type: :string
              },
              name: {
                type: :string,
                nullable: true
              },
              attributes: {
                type: :object,
                nullable: true,
                properties: {
                  title: {
                    type: :string,
                    nullable: true
                  },
                  authors: {
                    type: :array,
                    items: {
                      type: :string
                    }
                  },
                  links: {
                    type: :object,
                    additionalProperties: true
                  },
                  resource_type: {
                    type: :string,
                    nullable: true
                  },
                  best_access_right: {
                    type: :string,
                    nullable: true
                  }
                }
              }
            }
          },
          FavouritesIndexResponse: {
            type: :object,
            properties: {
              status: {
                type: :string,
                example: "ok"
              },
              favourites: {
                type: :array,
                items: {
                  "$ref" => "#/components/schemas/FavouriteItem"
                }
              }
            }
          },
          ActionResponse: {
            type: :object,
            properties: {
              status: {
                type: :string,
                example: "ok"
              },
              message: {
                type: :string,
                example: "Added to favourites"
              }
            }
          },
          ActionErrorResponse: {
            type: :object,
            properties: {
              status: {
                type: :string,
                example: "error"
              },
              message: {
                type: :string
              }
            }
          },
          ErrorResponse: {
            type: :object,
            properties: {
              error: {
                type: :string
              },
              details: {
                type: :string,
                nullable: true
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
