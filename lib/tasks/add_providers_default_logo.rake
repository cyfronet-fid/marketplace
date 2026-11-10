# frozen_string_literal: true

desc "Add an extension to the images that has lack of them"
task add_providers_default_logo: :environment do
  include ImageHelper

  Provider.find_each do |provider|
    next if provider.logo.attached? && provider.logo.variable?

    provider.set_default_logo
    provider.save!
  end
end
