# frozen_string_literal: true

require "rails_helper"
require "recommender_lib/serialize_db"

describe RecommenderLib::SerializeDb, backend: true do
  it "properly serializes the database" do
    create_list(:service, 2)
    create_list(:user, 2)
    create_list(:category, 2)
    create_list(:provider, 2)
    create_list(:scientific_domain, 2)
    create_list(:platform, 2)
    create_list(:target_user, 2)
    create_list(:access_type, 2)
    create_list(:access_mode, 2)
    create_list(:trl, 2)
    create_list(:life_cycle_status, 2)
    create_list(:project, 2)

    serialized = described_class.new.call

    expected_services = Service.all
    expect(serialized["services"].map { |x| x["id"] }).to match_array(expected_services.pluck(:id))
    expect(serialized["services"].map { |x| x["name"] }).to match_array(expected_services.pluck(:name))
    expect(serialized["services"].map { |x| x["description"] }).to match_array(expected_services.pluck(:description))

    expect(serialized["users"].map { |x| x["id"] }).to match_array(User.all.pluck(:id))
    expect(serialized["users"].map { |x| x["aai_uid"] }).to match_array(User.all.pluck(:uid))

    expect(serialized["projects"].map { |x| x["id"] }).to match_array(Project.all.pluck(:id))

    expect(serialized["categories"].map { |x| x["id"] }).to match_array(Category.all.pluck(:id))
    expect(serialized["categories"].map { |x| x["name"] }).to match_array(Category.all.pluck(:name))

    expect(serialized["providers"].map { |x| x["id"] }).to match_array(Provider.all.pluck(:id))
    expect(serialized["providers"].map { |x| x["name"] }).to match_array(Provider.all.pluck(:name))

    expect(serialized["scientific_domains"].map { |x| x["id"] }).to match_array(ScientificDomain.all.pluck(:id))
    expect(serialized["scientific_domains"].map { |x| x["name"] }).to match_array(ScientificDomain.all.pluck(:name))

    expect(serialized["platforms"].map { |x| x["id"] }).to match_array(Platform.all.pluck(:id))
    expect(serialized["platforms"].map { |x| x["name"] }).to match_array(Platform.all.pluck(:name))

    expect(serialized["target_users"].map { |x| x["id"] }).to match_array(TargetUser.all.pluck(:id))
    expect(serialized["target_users"].map { |x| x["name"] }).to match_array(TargetUser.all.pluck(:name))
    expect(serialized["target_users"].map { |x| x["description"] }).to match_array(TargetUser.all.pluck(:description))

    expect(serialized["access_types"].map { |x| x["id"] }).to match_array(
      Vocabulary.where(type: "Vocabulary::AccessType").pluck(:id)
    )
    expect(serialized["access_types"].map { |x| x["name"] }).to match_array(
      Vocabulary.where(type: "Vocabulary::AccessType").pluck(:name)
    )
    expect(serialized["access_types"].map { |x| x["description"] }).to match_array(
      Vocabulary.where(type: "Vocabulary::AccessType").pluck(:description)
    )

    expect(serialized["access_modes"].map { |x| x["id"] }).to match_array(
      Vocabulary.where(type: "Vocabulary::AccessMode").pluck(:id)
    )
    expect(serialized["access_modes"].map { |x| x["name"] }).to match_array(
      Vocabulary.where(type: "Vocabulary::AccessMode").pluck(:name)
    )
    expect(serialized["access_modes"].map { |x| x["description"] }).to match_array(
      Vocabulary.where(type: "Vocabulary::AccessMode").pluck(:description)
    )

    expect(serialized["trls"].map { |x| x["id"] }).to match_array(Vocabulary.where(type: "Vocabulary::Trl").pluck(:id))
    expect(serialized["trls"].map { |x| x["name"] }).to match_array(
      Vocabulary.where(type: "Vocabulary::Trl").pluck(:name)
    )
    expect(serialized["trls"].map { |x| x["description"] }).to match_array(
      Vocabulary.where(type: "Vocabulary::Trl").pluck(:description)
    )

    expect(serialized["life_cycle_statuses"].map { |x| x["id"] }).to match_array(
      Vocabulary.where(type: "Vocabulary::LifeCycleStatus").pluck(:id)
    )
    expect(serialized["life_cycle_statuses"].map { |x| x["name"] }).to match_array(
      Vocabulary.where(type: "Vocabulary::LifeCycleStatus").pluck(:name)
    )
    expect(serialized["life_cycle_statuses"].map { |x| x["description"] }).to match_array(
      Vocabulary.where(type: "Vocabulary::LifeCycleStatus").pluck(:description)
    )
  end
end
