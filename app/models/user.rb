class User < ApplicationRecord
    has_secure_password

    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

    validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

    has_many :liked_words, dependent: :destroy
end
