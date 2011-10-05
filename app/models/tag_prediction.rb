require 'transitions'

class TagPrediction < ActiveRecord::Base
  
  include ActiveRecord::Transitions
  
  belongs_to :tag
  belongs_to :article
  
  validates :tag_id, { 
    :presence => true,
    :uniqueness => { :scope => :article_id }
  }
  
  validates :article_id, { 
    :presence => true
  }

  state_machine do
    state :new
    state :assumed
    state :confirmed
    state :rejected
  end

  after_save do
    if state_changed?
      case state
      when "new"
        if state_was == "assumed"
          ArticleTag.where(:article_id => article.id, :tag_id => tag.id).first.try(:destroy)
        end
      when "assumed"
        ArticleTag.create(:article => article, :tag => tag)
      when "rejected"
        ArticleTag.where(:article_id => article.id, :tag_id => tag.id).first.try(:destroy)
        BayesianTagger.delay.teach(article, tag, false)
      when "confirmed"
        ArticleTag.create(:article => article, :tag => tag)
        BayesianTagger.delay.teach(article, tag, true)
      end
      
      if state == "confirmed" || state == "rejected"
        delay.reevaluate_siblings
      end
    end
  end
  
  after_destroy do
    case state
    when "confirmed"
      BayesianTagger.delay.teach(article, tag, false)
    end
    ArticleTag.where(:article_id => article.id, :tag_id => tag.id).first.try(:destroy)
  end
  
  def reevaluate_siblings
    tag.tag_predictions.where(:state => "new").where("reevaluation_scheduled IS NULL OR reevaluation_scheduled = ?", false).where("id != ?", id).each do |t| 
      t.update_attribute :reevaluation_scheduled, true
      t.delay.reevaluate
    end
  end
  
  def to_s
    "#{article.title}\n#{article.url} (#{article_id}) is #{tag.name} at #{confidence * 100} % confidence"
  end
  
  def confidence
    return 0.9999 if self[:confidence] == 1
    return self[:confidence]
  end
  
  def confidence=(new_confidence)
    super
    if (state == "new" || state == nil) && confidence > 0.9 && tag && tag.articles.count > 10
      self.state = "assumed"
    end
    if state == "assumed" && confidence < 0.9
      self.state = "new"
    end
  end
  
  def reevaluate
    if state == "new"
      self.confidence = BayesianTagger.tokens_probability(BayesianTagger.tokenize_article(article), tag)
      self.reevaluation_scheduled = false
      self.save
    end
  end
  
end
