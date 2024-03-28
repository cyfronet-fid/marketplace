require 'languages'

class Language
    class << self
        def living
        Languages.living.sort_by(&:name)
        end
    end
end
