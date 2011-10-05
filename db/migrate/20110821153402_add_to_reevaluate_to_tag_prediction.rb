class AddToReevaluateToTagPrediction < ActiveRecord::Migration
  def change
    add_column :tag_predictions, :reevaluation_scheduled, :boolean
  end
end
