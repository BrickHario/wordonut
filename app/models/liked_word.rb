class LikedWord < ApplicationRecord
  belongs_to :user

  validates :word, presence: true, uniqueness: { scope: [:user_id, :source_lang], message: "This word has already been saved." }
  validates :source_lang, presence: true

  validates :source_lang, presence: true
  validates :share_token, uniqueness: true, allow_nil: true

  before_create :generate_share_token

  private

  def generate_share_token
    self.share_token ||= SecureRandom.urlsafe_base64(8)
  end
end


