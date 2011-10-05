class DeleteInvalidArticles < ActiveRecord::Migration
  def up
    Article.all.each do |a|
      unless a.valid?
        p "Deleting #{a.title} #{a.url}"
        p a.errors.full_messages
        a.destroy
      end
    end
  end

  def down
  end
end
