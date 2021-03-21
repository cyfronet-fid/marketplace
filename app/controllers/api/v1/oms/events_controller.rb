# frozen_string_literal: true

class Api::V1::Oms::EventsController < Api::V1::Oms::ApiController
  def index
    # TODO: implement endpoint functionality
    render json: {
      "events": [
        {
          "timestamp": "<timestamp>",
          "type": "create",
          "resource": "project",
          "project_id": 1
        },
        {
          "timestamp": "<timestamp>",
          "type": "create",
          "resource": "project_item",
          "project_id": 1,
          "project_item_id": 1
        },
        {
          "timestamp": "<timestamp>",
          "type": "update",
          "resource": "message",
          "message_id": 1,
          "project_id": 1,
          "project_item_id": 1,
          "changes": [
            {
              "field": "some.path",
              "before": "value_before",
              "after": "value_after"
            }
          ]
        }
      ]
    }
  end
end
