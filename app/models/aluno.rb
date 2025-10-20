class Aluno < ApplicationRecord
  # === Associações ===
  belongs_to :escola
  belongs_to :turma, optional: true
  belongs_to :cidade, optional: true

  # === Validações ===
  validates :nome, presence: { message: "não pode estar em branco." }, length: { minimum: 3 }
  validates :cpf, uniqueness: { allow_blank: true, message: "já está em uso." }

  # === Active Storage ===
  has_one_attached :foto
  has_one_attached :historico_academico
  has_many_attached :cpf_documento
  has_many_attached :comprovante_residencia

  # === Callbacks ===
  before_create :generate_matricula

  # === Métodos ===
  def generate_matricula
    loop do
      year = Time.zone.now.year
      random_sequence = SecureRandom.hex(4).upcase
      candidate = "ESC-#{escola_id}-#{year}-#{random_sequence}"
      self.matricula = candidate
      break unless Aluno.exists?(matricula: candidate)
    end
  end

  def idade
    return nil unless data_nascimento
    today = Date.current
    age = today.year - data_nascimento.year
    age -= 1 if today < data_nascimento + age.years
    age
  end
end
