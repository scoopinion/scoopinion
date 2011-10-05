class DeleteInvalidSites < ActiveRecord::Migration
  def up
    Site.all.each do |s|
      unless s.valid?
        p "Deleting #{s.title} #{s.url}"
        p s.errors.full_messages
        s.destroy
      end
    end
  end

  def down
  end
end
