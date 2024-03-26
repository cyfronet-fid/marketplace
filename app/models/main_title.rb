class MainTitle < Title
    after_initialize :set_type 

    def set_type
        self.title_type = 'primary'
    end
end
  