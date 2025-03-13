# frozen_string_literal: true

desc "EOSC Search Service tasks"
COLLECTIONS = {
  services: "Service",
  datasources: "Datasource",
  providers: "Provider",
  offers: "Offer",
  bundles: "Bundle"
}.freeze
namespace :ess do
  namespace :reindex do
    task all: :environment do
      Ess::Update.call({ delete: { query: "*:*" }, commit: {} }.to_json)

      Service.all.filter(&:public?).each { |service| Service::Ess::Add.call(service, async: false) }
    end
  end

  task :dump, [:collections] => [:environment] do |_t, options|
    keys = options[:collections]
    if keys == "all"
      dump(COLLECTIONS)
    else
      keys = options[:collections].split.map(&:to_sym)

      dump(COLLECTIONS.slice(*keys))
    end
  end

  def load_dataset(value)
    case value.to_s
    when "Service", "Datasource"
      value.where(type: value.to_s).filter(&:public?)
    when "Offer", "Bundle"
      value.where(status: :published)
    when "Provider"
      value.active
    end
  end

  def dump(collections)
    collections.each do |key, value|
      puts "Dump #{key} to \"#{key}.json\""

      value = value.constantize
      dataset = load_dataset(value)
      output = dataset.each.map { |object| "Ess::#{object.class}Serializer".constantize.new(object).as_json }
      File.write("#{key}.json", JSON.pretty_generate(output))
      puts "#{key.to_s.camelize} dump complete"
    end
  end
end
