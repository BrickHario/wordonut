class AddShareTokenToLikedWords < ActiveRecord::Migration[7.2]
  def change
    add_column :liked_words, :share_token, :string
    add_index :liked_words, :share_token
  end
end
