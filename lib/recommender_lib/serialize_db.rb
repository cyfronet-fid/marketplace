# frozen_string_literal: true

module RecommenderLib
  class SerializeDb
    def call
      {
        services: Service.all.map { |s| Recommender::ServiceSerializer.new(s).as_json },
        users: User.all.map { |s| Recommender::UserSerializer.new(s).as_json },
        projects: Project.all.map { |s| Recommender::ProjectSerializer.new(s).as_json },
        categories: Category.all.map { |s| Recommender::CategorySerializer.new(s).as_json },
        providers: Provider.all.map { |s| Recommender::ProviderSerializer.new(s).as_json },
        scientific_domains: ScientificDomain.all.map { |s| Recommender::ScientificDomainSerializer.new(s).as_json },
        platforms: Platform.all.map { |s| Recommender::PlatformSerializer.new(s).as_json },
        target_users: TargetUser.all.map { |s| Recommender::TargetUserSerializer.new(s).as_json },
        access_modes:
          Vocabulary::AccessMode.all.map { |s| Recommender::Vocabulary::AccessModeSerializer.new(s).as_json },
        access_types:
          Vocabulary::AccessType.all.map { |s| Recommender::Vocabulary::AccessTypeSerializer.new(s).as_json },
        trls: Vocabulary::Trl.all.map { |s| Recommender::Vocabulary::TrlSerializer.new(s).as_json },
        life_cycle_statuses:
          Vocabulary::LifeCycleStatus.all.map { |s| Recommender::Vocabulary::LifeCycleStatusSerializer.new(s).as_json },
        research_activities:
          Vocabulary::ResearchActivity.all.map do |s|
            Recommender::Vocabulary::ResearchActivitySerializer.new(s).as_json
          end
      }.as_json
    end
  end
end
