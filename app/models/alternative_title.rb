class AlternativeTitle < Title
  after_initialize :set_type 

  def set_type
      self.title_type = 'alternative'
  end
 
  end
  