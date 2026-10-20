# frozen_string_literal: true

ApplicationDeploymentManager::Deployment = Data.define(:id, :status, :details, :outputs)
