# frozen_string_literal: true

class Filter::Tag < Filter
  #   TODO finish this filter

  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "tag", type: :select,
          title: "Tags", index: nil)
  end

  def visible?
    false
  end

  private

    def fetch_options
      ActsAsTaggableOn::Tag.all.
        map { |t| { name: t.name, id: t.name } }.
        sort { |x, y| x[:name] <=> y[:name] }
    end

    # def do_call(services)
    #   services.tagged_with(value)
    # end

end
