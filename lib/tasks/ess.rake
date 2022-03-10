# frozen_string_literal: true

desc "EOSC Search Service tasks"
namespace :ess do
  namespace :reindex do
    task all: :environment do
      Ess::Update.call({ delete: { query: "*:*" }, commit: {} }.to_json)

      Service.all.filter(&:public?).each { |service| Service::Ess::Add.call(service, async: false) }
    end
  end
end
