# frozen_string_literal: true

desc "Add an extension to the images that has lack of them"
task add_providers_default_logo: :environment do
  include ImageHelper

  providers_without_logo =
    Provider.all.select { |provider| provider.logo.blank? || !provider.logo.attached? || !provider.logo.variable? }
  providers_without_logo.each do |provider_without_logo|
    providers_without_logo.set_default_logo
    provider_without_logo.save!
  end
end
