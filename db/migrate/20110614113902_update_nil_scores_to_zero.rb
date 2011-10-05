class UpdateNilScoresToZero < ActiveRecord::Migration
  def up
    Article.where(:score => nil).each do |a|
      p a.title
      a[:score] = 0
      a.save
    end
  end

  def down
  end
end
