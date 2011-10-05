namespace :tagger do
  
  task :slow_tokenize => :environment do
    Article.where("in_neutral_corpus is null").find_each(:batch_size => 100) do |article|
      Token.transaction do
        BayesianTagger.tokenize_article(article).map do |token|
          Token.add(token)
        end
      end
      article.update_attribute :in_neutral_corpus, true
    end
  end
    
  task :recalculate_tokens => :environment do
    Token.all.each(&:destroy)
    tokens = { }
    Article.find_each(:batch_size => 100) do |article|
      p article.id
      BayesianTagger.tokenize_article(article).map do |token|
        tokens[token] ||= 0
        tokens[token] = tokens[token] + 1
      end
    end
    
    puts "Found #{tokens.count} distinct tokens"
    
    tokens.to_a.in_groups_of(100).each do |array| 
      Token.transaction do
        array.each do |t|
          p Token.create(:name => t[0], :count => t[1])
        end 
      end
    end
  end
  
  task :recalculate_tag_tokens => :environment do
    Tag.find_each do |tag|
      
      p tag
      
      TokenFrequency.transaction do
        TokenFrequency.where(:tag_id => tag.id).each(&:destroy)
      end
      
      puts "Tokenizing..."
      
      tokens = { }
      tag.articles.map do |article|
        # p article.id
        BayesianTagger.tokenize_article(article).map do |token|
          tokens[token] ||= 0
          tokens[token] = tokens[token] + 1
        end
      end
      
      puts "Found #{tokens.count} distinct tokens"
      
      
      tokens.to_a.in_groups_of(100).each do |array| 
        TokenFrequency.transaction do
          array.each do |t|            
            if t
              token = Token.find_by_name(t[0])
              unless token
                token = Token.create(:name => t[0], :count => t[1])
              end
              TokenFrequency.create(:token_id => token.id, :count => t[1], :tag_id => tag.id)
            end
          end 
        end
      end
    end
  end
  
  task :predict_all => :environment do     
    BayesianTagger.predict_all
  end
  
end

