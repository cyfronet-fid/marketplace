# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  ActiveModel::Type.register(:array, ArrayType)
end
