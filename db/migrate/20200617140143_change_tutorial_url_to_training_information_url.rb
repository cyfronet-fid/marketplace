# frozen_string_literal: true

class ChangeTutorialUrlToTrainingInformationUrl < ActiveRecord::Migration[6.0]
  def change
    rename_column :services, :tutorial_url, :training_information_url
  end
end
