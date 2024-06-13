# class Raid::Wizard
#     RAID_FORM_STEPS = {
#     step1: %i[start_date end_date main_title alternative_titles main_description alternative_descriptions],
#     step2: [:contributors],
#     step3: [:raid_organisations],
#     step4: [:raid_access],
#     step5: []
#   }.freeze

#   class Base
#     include ActiveModel::Model
#     attr_accessor :raid_project

#     delegate 
#         :main_title, 
#         :alternative_titles,
#         :main_description, 
#         :alternative_descriptions, 
#         :raid_organisations, 
#         :raid_access,
#         :contributors,
#         to: :raid_project

#     def initialize(raid_project_attributes)
#       @raid_project = ::RaidProject.new(raid_project_attributes)
#     end

   
#   end
