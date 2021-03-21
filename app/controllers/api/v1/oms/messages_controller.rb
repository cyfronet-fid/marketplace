# frozen_string_literal: true

class Api::V1::Oms::MessagesController < Api::V1::Oms::ApiController
  def index
    # TODO: implement endpoint functionality
    render json: {
      "messages": [
        {
          "id": 1,
          "author": {
            "email": "<email>",
            "name": "<name>",
            "role": "user"
          },
          "content": "<content>",
          "scope": "public",
          "created_at": "<created_at>",
          "updated_at": "<updated_at>"
        },
        {
          "id": 2,
          "author": {
            "email": "<email>",
            "name": "<name>",
            "role": "provider"
          },
          "content": "<content>",
          "scope": "internal",
          "created_at": "<created_at>",
          "updated_at": "<updated_at>"
        },
        {
          "id": 2,
          "author": {
            "email": "<email>",
            "name": "<name>",
            "role": "provider"
          },
          "content": "<OBFUSCATED>",
          "scope": "user_direct",
          "created_at": "<created_at>",
          "updated_at": "<updated_at>"
        }
      ]
    }
  end

  def create
    # TODO: implement endpoint functionality
    render json: {
      "id": 1,
      "author": {
        "email": "<email>",
        "name": "<name>",
        "role": "provider"
      },
      "content": "VISIBLE!",
      "scope": "user_direct",
      "created_at": "<created_at>",
      "updated_at": "<updated_at>"
    }, status: 201
  end

  def update
    # TODO: implement endpoint functionality
    render json: {
      "id": 1,
      "author": {
        "email": "<email>",
        "name": "<name>",
        "role": "provider"
      },
      "content": "VISIBLE!",
      "scope": "user_direct",
      "created_at": "<created_at>",
      "updated_at": "<updated_at>"
    }
  end
end
