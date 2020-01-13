# frozen_string_literal: true

namespace :whitelabel do
  task migrate_category_logos: :environment do
    attach_logos(Category.all)
  end

  task migrate_research_area_logos: :environment do
    attach_logos(ResearchArea.all)
  end

  def attach_logos(collection)
    collection.each do |record|
      if has_logo?(record)
        record.logo.attach(io: File.open(logo_path(record)), filename: "logo.png")
      end
    end
  end

  def logo_path(record)
    "app/assets/images/ico_#{record.name.split.first}.png".underscore
  end

  def has_logo?(record)
    File.exist?(logo_path(record))
  end
end
