# frozen_string_literal: true

class Project::Destroy
  def initialize(project)
    @project = project
  end

  def call
    @project.destroy
  end
end
