# frozen_string_literal: true

class Api::V1::Oms::ProjectsController < Api::V1::Oms::ApiController
  def index
    # TODO: implement endpoint functionality
    render json: {
      "projects": [
        {
          "id": 1,
          "owner": {
            "email": "<contact email>",
            "name": "<displayable name>"
          },
          "project_items": [ 1, 2 ],
          "attributes": {
            "reason_for_access": "",
            "country_of_origin": "",
            "customer_typology": "",
            "etc": ""
          }
      },
        {
          "id": 2,
          "owner": {
            "email": "<contact email>",
            "name": "<displayable name>"
          },
          "project_items": [ 2, 3 ],
          "attributes": {
            "etc1": "",
            "etc2": ""
          }
        }
      ]
    }
  end

  def show
    # TODO: implement endpoint functionality
    render json: {
      "id": 1,
      "owner": {
        "email": "<contact email>",
        "name": "<displayable name>"
      },
      "project_items": [ 1, 2 ],
      "attributes": {
        "reason_for_access": "",
        "country_of_origin": "",
        "customer_typology": "",
        "etc": ""
      }
    }
  end
end
