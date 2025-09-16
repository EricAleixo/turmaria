class EmailCadastro < ApplicationRecord

    belongs_to :user, polymorphic: true

    validates :email, presence: true, uniqueness: true
end
