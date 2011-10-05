class Token < ActiveRecord::Base
  belongs_to :tag
  
  validates :name, { 
    :uniqueness => true
  }
  
  has_many :token_frequencies
  
  def self.add(token)
    t = Token.find_by_name(token)
    unless t
      create(:name => token, :count => 1)
    else 
      t.count = t.count + 1
      t.save
    end
  end
  
  def genericity
    self[:genericity] || self.calculate_genericity!
  end
  
  def calculate_genericity!
    probabilities = self.token_frequencies.includes(:tag).reject{|tf| tf.count < 1 }.map do |t|
      [ t.tag.name, BayesianTagger.token_probability(self.name, t.tag, false) ]
    end.sort_by{|x| (0.5 - x[1]).abs}
    
    return 0.05 unless probabilities.count > 0
    
    tokens = probabilities.map do |p| 
      if p[1] > 0.5
        (1 - p[1]) * 2
      else
        p[1] * 2
      end
    end
    
    product = tokens.inject(1){ |p, t| p * t }
    denominator = tokens.inject(1){ |p, t| p * (1 - t) }    

    self.genericity = [ 0.05, product / (product + denominator) ].max
    self.save
    self.genericity
  end
      
end
