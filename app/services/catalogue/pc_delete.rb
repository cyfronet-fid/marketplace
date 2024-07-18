# frozen_string_literal: true

class Catalogue::PcDelete < Catalogue::Delete
  def initialize(catalogue_id)
    @catalogue = Catalogue.includes(:providers, :services).friendly.find(catalogue_id)
    super(@catalogue)
  end
end
