# frozen_string_literal: true

class Raid::Ror < ApplicationRecord
  searchkick word_middle: %i[name acronyms aliases]
end
