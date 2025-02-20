class User < ApplicationRecord
    has_secure_password

    validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 15 }

    validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

    has_many :liked_words, dependent: :destroy
end
