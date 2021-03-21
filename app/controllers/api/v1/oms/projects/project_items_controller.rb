# frozen_string_literal: true

class Api::V1::Oms::Projects::ProjectItemsController < Api::V1::Oms::ApiController
  def index
    # TODO: implement endpoint functionality
    render json: {
      "project_items": [
        {
          "id": 1,
          "project_id": 1,
          "status": {
            "value": "<status>",
            "type": "rejected"
          },
          "attributes": {
            "reason_for_access": "",
            "country_of_origin": "",
            "customer_typology": "",
          },
          "oms_params": {
              "order_target": "target@mail.eu"
          }
        },
        {
          "id": 2,
          "project_id": 2,
          "status": {
            "value": "<status>",
            "type": "ready"
          },
          "attributes": {
            "etc1": "",
            "etc3": "",
          },
          "user_secrets": {
            "secret1": "<OBFUSCATED>"
          },
          "oms_params": {
            "some_detail": "asdqwe"
          }
        }
      ]
    }
  end

  def show
    # TODO: implement endpoint functionality
    render json: {
      "id": 1,
      "project_id": 1,
      "status": {
        "value": "<status>",
        "type": "rejected"
      },
      "attributes": {
        "reason_for_access": "",
        "country_of_origin": "",
        "customer_typology": "",
      },
      "user_secrets": {
        "secret1": "<OBFUSCATED>"
      },
      "oms_params": {
        "order_target": "target@mail.eu"
      }
    }
  end

  def update
    # TODO: implement endpoint functionality
    render json: {
      "id": 1,
      "project_id": 1,
      "status": {
        "value": "<status>",
        "type": "ready"
      },
      "attributes": {
        "reason_for_access": "",
        "country_of_origin": "",
        "customer_typology": "",
      },
      "user_secrets": {
        "secret1": "VISIBLE!"
      },
      "oms_params": {
        "order_target": "target@mail.eu"
      }
    }
  end
end
