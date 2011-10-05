class TokenFrequency < ActiveRecord::Base
  belongs_to :token
  belongs_to :tag
  
  validates :tag_id, { 
    :uniqueness => { :scope => :token_id }
  }

  def self.add(token, tag)
    t = Token.find_by_name(token)
    unless t
      t = Token.create(:name => token, :count => 1)
    end
    
    t.calculate_genericity!
    
    tf = t.token_frequencies.find_or_initialize_by_tag_id(tag.id)
    tf.count ||= 0
    tf.count = tf.count + 1
    tf.save
  end
  
  def self.remove(token, tag)
    t = Token.find_by_name(token)
    unless t
      t = Token.create(:name => token, :count => 1)
    end
    
    tf = t.token_frequencies.find_or_initialize_by_tag_id(tag.id)
    
    return unless tf.id
    
    t.calculate_genericity!
    
    tf.count ||= 0
    tf.count = tf.count - 1
    tf.count = 0 if tf.count < 0
    tf.save
  end

end

