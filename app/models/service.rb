# frozen_string_literal: true

require "elasticsearch/model"

class Service < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
end
