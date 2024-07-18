# frozen_string_literal: true

class Provider::PcDelete < Provider::ApplicationService
  def initialize(provider_id)
    @provider = Provider.friendly.find(provider_id)
    super(@provider)
  end
end
