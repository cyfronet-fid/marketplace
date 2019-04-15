# frozen_string_literal: true

module Service::Autocomplete
  extend ActiveSupport::Concern

  def autocomplete
    query = Service.search(params[:q],
      fields: ["title"],
      operator: "or",
      match: :word_middle,
      limit: 5,
      load: false,
      highlight: { tag: "<b>" }
    )

    if request.xhr?
      generate_html(query)
    end
  end

  private

    def generate_html(query)
      html_results = query.highlights.map.with_index { |s, i| "<li class=\"dropdown-item\" role=\"option\" data-autocomplete-value=\"#{i}\">#{s[:title]}</li>" }.join

      respond_to do |format|
        format.html do
          render status: :ok, html: html_results.html_safe
        end
      end
    end
end
