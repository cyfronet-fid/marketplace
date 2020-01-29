# frozen_string_literal: true

class HelpItem < ApplicationRecord
  has_rich_text :content

  belongs_to :help_section

  validates :title, presence: true
  validates :content, presence: true
end
