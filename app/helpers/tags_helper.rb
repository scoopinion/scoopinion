module TagsHelper
  
  def article_counts(tag)
    counts = [
              [ 1.day, "today"],
              [ 7.days, "this week"],
              [ 30.days, "this month"],
              [ 100.years, "in total"]
             ]
    counts = counts.map do |a|
      count = tag.articles.newer_than(a[0]).count
      [ count, *a ] if count > 0
    end.compact
    
    return "" unless counts.size > 0
    
    noun = "article"
    noun = noun.pluralize if counts[0][0] > 1
    
    counts[0][2] = noun + " " + counts[0][2]
    
    counts.map{ |a| "#{a[0]} #{a[2]}"}.join(", ")
  end
  
end

