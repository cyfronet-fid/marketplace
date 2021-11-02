# frozen_string_literal: true

module Recommender
  class SerializeDb
    def initialize; end

    def call
      { services: Service.all.map { |s| Recommender::ServiceSerializer.new(s).as_json },
        users: User.all.map { |s| Recommender::UserSerializer.new(s).as_json },
        categories: Category.all.as_json(only: [:id, :name]),
        providers: Provider.all.as_json(only: [:id, :name]),
        scientific_domains: ScientificDomain.all.as_json(only: [:id, :name]),
        platforms: Platform.all.as_json(only: [:id, :name]),
        target_users: TargetUser.all.as_json(only: [:id, :name, :description]),
        access_modes: Vocabulary.where(type: "Vocabulary::AccessMode").as_json(only: [:id, :name, :description]),
        access_types: Vocabulary.where(type: "Vocabulary::AccessType").as_json(only: [:id, :name, :description]),
        trls: Vocabulary.where(type: "Vocabulary::Trl").as_json(only: [:id, :name, :description]),
        life_cycle_statuses: Vocabulary
                               .where(type: "Vocabulary::LifeCycleStatus").as_json(only: [:id, :name, :description])
      }.as_json
    end
  end
end
