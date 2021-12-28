# frozen_string_literal: true

namespace :whitelabel do
  task migrate_category_logos: :environment do
    attach_logos(Category.all)
  end

  task migrate_scientific_domain_logos: :environment do
    attach_logos(ScientificDomain.all)
  end

  task migrate_learn_more: :environment do
    learn_more =
      LeadSection.find_or_create_by(
        slug: I18n.t("lead.learn_more.slug"),
        title: I18n.t("lead.learn_more.title"),
        template: "learn_more"
      )

    lead1 = build_new_lead("lead.learn_more.initiative", learn_more, 1)
    lead2 = build_new_lead("lead.learn_more.project", learn_more, 2)
    lead3 = build_new_lead("lead.learn_more.providers", learn_more, 3)

    lead1.picture.attach(io: File.open(file_path(lead1.header.split.last)), filename: "eosc-initiative.png")
    lead2.picture.attach(io: File.open(file_path(lead2.header.split.last)), filename: "projects.png")
    lead3.picture.attach(io: File.open(file_path(lead3.header.split.last)), filename: "for-providers.png")
    lead1.save!
    lead2.save!
    lead3.save!
  end

  task migrate_use_cases: :environment do
    use_cases =
      LeadSection.find_or_create_by(
        slug: I18n.t("lead.use_cases.slug"),
        title: I18n.t("lead.use_cases.title"),
        template: "use_case"
      )

    lead1 = build_new_lead("lead.use_cases.clarin", use_cases, 1)
    lead2 = build_new_lead("lead.use_cases.earth_observation", use_cases, 2)

    lead1.save!
    lead2.save!
  end

  def attach_logos(collection)
    collection.each do |record|
      record.logo.attach(io: File.open(logo_path(record.name.split.first)), filename: "logo.png") if logo?(record)
    end
  end

  def build_new_lead(name, section, position)
    Lead.new(
      header: I18n.t("#{name}.header"),
      body: I18n.t("#{name}.body"),
      url: I18n.t("#{name}.url"),
      position: position,
      lead_section: section
    )
  end

  def file_path(name)
    "app/assets/images/ico_#{name}.png".underscore
  end

  def logo?(record)
    File.exist?(logo_path(record))
  end
end
