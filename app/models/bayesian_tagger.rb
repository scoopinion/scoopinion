class BayesianTagger
  
  @@frequencies = { }
  
  def self.predict(article, tag = nil)
    
    tags = all_tags
    
    if tag
      tags = [ tag ]
    end
    
#    puts "#{article.id} #{article.title}"
    
    tokens = self.tokenize_article(article)
    self.cache_tokens(tokens)
    
    predictions = []
    
    tags.each do |t|
      unless article.tags.include?(t) || article.tag_predictions.any?{ |tp| tp.tag_id == t.id && (tp.state == "confirmed" || tp.state == "rejected") }
        prob = self.tokens_probability(tokens, t)
        tp = article.tag_predictions.detect{ |x| x.tag_id == t.id}

        if prob > 0.1
          unless tp
            predictions << TagPrediction.create(:tag => t, :article => article, :confidence => prob)
          else
            predictions << tp
            tp.confidence = prob
            tp.save
          end
        else 
          if tp
            tp.destroy
          end
        end
      end
    end
    
    predictions
  end
  
  def self.teach(article, tag, result)
    tokens = self.tokenize(self.tokenize_article(article))
    
    unless article.in_neutral_corpus?
      tokens.each{ |token| Token.add(token) }
      article.update_attribute :in_neutral_corpus, true
    end
    
    if result
      tokens.each{ |token| TokenFrequency.add(token, tag) }
    else
      tokens.each{ |token| TokenFrequency.remove(token, tag) }
    end
    
    tag.new_data_since_recalculated += 1
    tag.save
    
    if time_to_repredict(tag)
      self.delay.predict_tag(tag)
    end
  end
  
  def self.time_to_repredict(tag)
    tag.new_data_since_recalculated > tag.articles.count / 20.0 || Time.now - tag.recalculated_at > 12.hours
  end  
  
  def self.token_probability(token, tag, generic=true)
    
    @@probabilities ||= { }
    @@probabilities[tag] ||= { }
    
    if @@probabilities[tag][token]
      return @@probabilities[tag][token]
    end
    
    @@frequencies ||= { }
    all = self.get_token(token)

    @@all_count ||= Token.sum(:count).to_f
    
    @@article_count ||= Article.count.to_f
    @@tag_counts ||= { }
    @@tag_counts[tag] ||= tag.articles.count.to_f
    
    return [0.10, ((@@tag_counts[tag]) / (@@article_count))].max unless all > 5
    
    tokens = self.get_tag_token(tag, token)
    
    unless tokens > 0
      if generic
        return self.get_token_object(token).genericity / 2.0
      else
        return 0.05
      end
    end
    
    

    yes = tokens.to_f
    no = (all.to_f - yes) * (1 - ((@@tag_counts[tag]) / (@@article_count)))
        
    @@positive_count ||= { }
    @@positive_count[tag] ||= TokenFrequency.where(:tag_id => tag.id).sum(:count).to_f
    negative_count = @@all_count - @@positive_count[tag]
    
    probability = [ 0.01, [ 0.9999999, (yes / @@positive_count[tag]) / ((yes / @@positive_count[tag]) + (no / negative_count)) ].min ].max
    
    # puts "#{token} #{yes} #{no} #{probability}"
    
    @@probabilities[tag][token] = probability
  end
  
  def self.get_tag_token(tag, token)
    @@frequencies[tag.id] ||= { }
    @@frequencies[tag.id][token] ||= Token.find_by_name(token).token_frequencies.where(:tag_id => tag.id).first.try(:count) || 0
  end

  
  def self.get_token(token)
    @@frequencies[:master] ||= { }
    @@frequencies[:master][token] ||= Token.find_by_name(token).try(:count) || 0
  end
  
  def self.get_token_object(token_name)
    @@tokens ||= { }
    @@tokens[token_name] ||= Token.find_by_name(token_name)
  end

  
  def self.cache_tokens(tokens)
    @@frequencies[:master] ||= { }
    @@genericities ||= { }
    @@tokens ||= { }
    tokens = tokens.reject{ |t| @@frequencies[:master][t] }.uniq
    
    return if tokens.count == 0
    
    token_objects = Token.where("name in (?)", tokens).includes(:token_frequencies)
    token_objects.each do |t| 
      @@tokens[t.name] = t
      @@frequencies[:master][t.name] = t.count 
      t.token_frequencies.each do |tf|
        @@frequencies[tf.tag_id] ||= { }
        @@frequencies[tf.tag_id][t.name] = tf.count
      end
      all_tags.reject{ |tag| t.token_frequencies.any?{ |tf| tf.tag_id == tag.id } }.each do |tag|
        @@frequencies[tag.id] ||= { }
        @@frequencies[tag.id][t.name] = 0        
      end 
    end
  end
  
  def self.all_tags
    @@all_tags ||= Tag.where("supertag_id IS NULL")
  end

  
  def self.article_probability(article, tag)
    self.text_probability(self.tokenize_article(article), tag)
  end
  
  def self.tokens_probability(tokens, tag)
    
    return 0.01 unless tokens.uniq.count > 10
    
    tokens = tokens.uniq.map{ |t| [ self.token_probability(t, tag), t] }.sort_by{ |t| ( 0.5 - t[0]).abs }.reverse.take(15)
        
    #p tokens
    
    tokens.map!{ |t| t[0]}
    product = tokens.inject(1){ |p, t| p * t }
    
    denominator = tokens.inject(1){ |p, t| p * (1 - t) }
    
    return 0.01 unless product + denominator > 0
    
    probability = [ 0.0001, product / (product + denominator)].max
    
    # puts "#{product} / (#{product} + #{denominator}) = #{probability}"
    
    if probability > 0.1
      p "#{tag.name} #{(probability * 100).to_s[0..3]}%"
    end
        
    probability
  end
  
  def self.positive_corpus(tag)
    corpus = self.join(tag.articles)
    @@npositive = tokenize(corpus).size
    corpus
  end
  
  def self.negative_corpus(tag)
    corpus = Article.includes(:site)
    blocked_taggings = ArticleTag.where("article_id IN (?)", corpus).where(:tag_id => tag.id).includes(:article).map{ |at| at.article }
    corpus.reject! { |a| blocked_taggings.include? a }
    corpus = self.join(corpus)
    @@nnegative = tokenize(corpus).size
    corpus
  end
  
  def self.join(articles)
    articles.map{ |a| self.tokenize_article(article) }
  end
  
  def self.tokenize_article(a)
    self.tokenize([ CGI::unescape(a.url), a.pretty_title, a.description ].compact)
  end
  
  def self.tokenize(corpus)
    corpus = [ corpus ] unless Array.try_convert(corpus)
    corpus.flatten.map{ |t| t.downcase.gsub(/[\]\[!"\#$%&'()*+,.\/:;<=>?@\^_`{|}~-]/, " ").split }.flatten.reject{ |t| t.match /^[0-9]*$/ }
  end
  
  def self.group(tokens)
    puts "Grouping..."
    hash = { }
    tokens.each do |t| 
      hash[t] ||= 0
      hash[t] = hash[t] + 1
    end
    hash
  end
  
  def self.predict_tag(tag, force=false)
    
    unless force || time_to_repredict(tag)
      return
    end
    
    new_data = tag.new_data_since_recalculated
    
    Article.includes(:site, :tag_predictions, :article_tags).newer_than(3.days).find_in_batches(:batch_size => 10) do |articles|
      articles.map{ |article|  BayesianTagger.predict(article, tag) }
    end  
    
    tag.recalculated_at = Time.now
    tag.new_data_since_recalculated -= new_data
    tag.new_data_since_recalculated = 0 if tag.new_data_since_recalculated < 0
    tag.save
  end

  def self.predict_all(period)
    Article.includes(:site, :tag_predictions, :article_tags).order("created_at DESC").where("created_at > ?", Time.now - period).find_each(:batch_size => 10) do |article|
      TagPrediction.transaction do
        BayesianTagger.predict(article, Tag.find_by_id(ENV["TAG"]))
      end
    end
  end
  
end
