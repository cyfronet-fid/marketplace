# frozen_string_literal: true

desc "Migration of parameters"
namespace :parameters do
  task type_to_underscore: :environment do
    Offer.all.each do |offer|
      if offer.parameters.present?
        offer.parameters.each do |p|
          p.type == p.type.underscore
        end
      end
      offer.save!
    end
  end
end
