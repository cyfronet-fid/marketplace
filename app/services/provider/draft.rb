# frozen_string_literal: true

class Provider::Draft < Provider::ApplicationService
  def call
    @catalogue.status = :draft
    @catalogue.save(validate: false)
  end
end
