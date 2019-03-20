# frozen_string_literal: true

class Filter::Tag < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "tag", type: :select,
          title: "Tags")
  end

  def visible?
    false
  end

  private

    def fetch_options
      ActsAsTaggableOn::Tag.all.
        map { |t| [t.name, t.name] }.
        sort { |x, y| x[0] <=> y[0] }
    end

    def do_call(services)
      services.tagged_with(value)
    end
end
