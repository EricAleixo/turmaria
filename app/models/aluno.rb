class Aluno < ApplicationRecord
  # === Associações (Relacionamentos) ===
  # Relacionamentos essenciais
  belongs_to :escola
  belongs_to :cidade
  belongs_to :turma, optional: true # Aluno pode estar sem turma alocada

  # === Validações ===
  # ESSENCIAL: Garante que os campos obrigatórios sejam preenchidos
  validates :cidade_id, presence: { message: "deve ser preenchida." }
  validates :nome, presence: { message: "não pode estar em branco." }, length: { minimum: 3 }
  validates :cpf, uniqueness: { allow_blank: true, message: "já está em uso." }

  # Validação de data de nascimento para garantir que o aluno seja maior que X ou menor que Y
  # Exemplo: Alunos com no máximo 100 anos e no mínimo 3 anos.
  validates :data_nascimento, presence: true
  validate :data_nascimento_valida

  # === Active Storage Anexos ===
  # Arquivos de upload conforme listado nos strong parameters do Controller
  has_one_attached :foto # Foto de perfil
  has_one_attached :historico_academico # Histórico (um arquivo)
  has_many_attached :cpf_documento # Documentos de CPF (pode ser frente e verso)
  has_many_attached :comprovante_residencia # Comprovantes (pode ser mais de um)

  # === Callbacks e Lógica Personalizada ===
  before_create :generate_matricula

  # Lógica de geração de matrícula única
  def generate_matricula
    loop do
      # Formato: ESC-ID_ESCOLA-ANO-SEQUENCIAL_UNICO
      year = Time.zone.now.year
      # Gera um número aleatório único (ou use uma sequência incremental do banco)
      random_sequence = SecureRandom.hex(4).upcase 
      candidate_matricula = "ESC-#{escola_id}-#{year}-#{random_sequence}"
      self.matricula = candidate_matricula
      # Garante que a matrícula gerada é realmente única antes de sair do loop
      break unless Aluno.exists?(matricula: candidate_matricula)
    end
  end

  # Calcula a idade do aluno
  def idade
    return nil unless data_nascimento
    today = Date.current
    age = today.year - data_nascimento.year
    age -= 1 if today < data_nascimento + age.years
    age
  end

  private

  # Método de validação customizado para data de nascimento
  def data_nascimento_valida
    if data_nascimento.present?
      if data_nascimento > Date.current
        errors.add(:data_nascimento, "não pode ser no futuro.")
      elsif data_nascimento < 100.years.ago.to_date
        errors.add(:data_nascimento, "parece muito antiga, verifique o ano.")
      end
    end
  end
end