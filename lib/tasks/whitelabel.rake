# frozen_string_literal: true

namespace :whitelabel do
  task migrate_category_logos: :environment do
    Category.all.each do |category|
      if has_logo?(category)
        category.logo.attach(io: File.open(logo_path(category)), filename: "logo.png")
      end
    end
  end

  def logo_path(category)
    "app/assets/images/ico_#{category.name.split.first}.png".underscore
  end

  def has_logo?(category)
    File.exist?(logo_path(category))
  end
end
