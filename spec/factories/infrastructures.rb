# frozen_string_literal: true

FactoryBot.define do
  factory :infrastructure do
    association :project_item
    im_base_url { "https://deploy.sandbox.eosc-beyond.eu" }
    cloud_site { "IISAS-FedCloud" }
    state { "pending" }
    outputs { {} }
    retry_count { 0 }

    trait :creating do
      state { "creating" }
      im_infrastructure_id { SecureRandom.uuid }
      last_state_check_at { Time.current }
    end

    trait :configured do
      state { "configured" }
      im_infrastructure_id { SecureRandom.uuid }
      last_state_check_at { Time.current }
    end

    trait :running do
      state { "running" }
      im_infrastructure_id { SecureRandom.uuid }
      last_state_check_at { Time.current }
      outputs { { "jupyterhub_url" => "https://#{SecureRandom.uuid}.vm.fedcloud.eu/jupyterhub/" } }
    end

    trait :failed do
      state { "failed" }
      im_infrastructure_id { SecureRandom.uuid }
      last_error { "Deployment failed: timeout" }
      retry_count { 1 }
      last_state_check_at { Time.current }
    end

    trait :destroyed do
      state { "destroyed" }
      im_infrastructure_id { SecureRandom.uuid }
      last_state_check_at { Time.current }
    end
  end
end
