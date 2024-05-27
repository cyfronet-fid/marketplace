# frozen_string_literal: true

class RorsController < ApplicationController
  def index
    @rors = Raid::Ror.all
  end
  def autocomplete
    results = Raid::Ror.search(params[:q], fields: %i[name aliases acronyms], match: :word_middle, operator: "or")

    render(template: "raid_projects/ror_autocomplete", locals: { results: results }, layout: false)
  end
end
