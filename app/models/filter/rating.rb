# frozen_string_literal: true

class Filter::Rating < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "rating", type: :select,
          title: "Rating")
  end

  private

    def fetch_options
      [["Any", ""],
        ["★+", "1"],
        ["★★+", "2"],
        ["★★★+", "3"],
        ["★★★★+", "4"],
        ["★★★★★", "5"]]
    end

    def do_call(services)
      services.where("rating >= ?", value)
    end
end
