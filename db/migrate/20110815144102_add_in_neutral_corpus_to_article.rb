class AddInNeutralCorpusToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :in_neutral_corpus, :boolean
  end
end
