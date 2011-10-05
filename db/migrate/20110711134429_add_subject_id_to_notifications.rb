class AddSubjectIdToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :subject_id, :integer
  end
end
