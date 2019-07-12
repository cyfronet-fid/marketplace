class CountrySerializer

  def self.load(json)
    return nil if json.blank?
    if json.is_a? Array
      json.map() { |e| ISO3166::Country.new(JSON.parse(e)) }
    else
      ISO3166::Country.new(JSON.parse(json))
    end
  end

  def self.dump(obj)

    if obj.is_a? Array
      obj.map(&:alpha2).map(&:to_json)
    else
      obj.alpha2.to_json
    end
  end

end