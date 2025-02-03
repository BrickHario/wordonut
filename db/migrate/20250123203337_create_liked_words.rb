class CreateLikedWords < ActiveRecord::Migration[7.2]
  def change
    create_table :liked_words do |t|
      t.references :user, null: false, foreign_key: true
      t.string :word
      t.string :source_lang

      t.timestamps
    end
  end
end
