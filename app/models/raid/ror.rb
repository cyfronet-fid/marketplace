class Raid::Ror < ApplicationRecord
    searchkick word_middle: [:name, :acronyms, :aliases]

end
