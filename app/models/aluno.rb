# app/models/aluno.rb

class Aluno < ApplicationRecord
  # === Associações (Relacionamentos) ===
  # Relacionamentos essenciais
  belongs_to :escola
  belongs_to :cidade, optional: true # Tornando cidade_id opcional
  belongs_to :turma, optional: true # Aluno pode estar sem turma alocada

  # === Validações ===
  # ESSENCIAL: Garante que os campos obrigatórios sejam preenchidos
  # APENAS NOME É OBRIGATÓRIO
  validates :nome, presence: { message: "não pode estar em branco." }, length: { minimum: 3 }
  
  # CPF continua com validação de unicidade, mas o campo pode ficar vazio
  validates :cpf, uniqueness: { allow_blank: true, message: "já está em uso." }

  # data_nascimento não tem mais validação de presence: true

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
  
  # =========================================================================
  # O MÉTODO QUE ESTAVA FALTANDO PARA RESOLVER O NoMethodError
  # =========================================================================
  # Este método é chamado na view (aluno.status_aluno) e no controller (para filtros).
  def status_aluno
    # A lógica mais simples é baseada na alocação de turma.
    # O controller usa implicitamente esta lógica para o filtro "alocado" / "pendente de alocacao".
    if turma_id.present?
      "Alocado"
    else
      "Pendente de Alocação"
    end
  end
  # =========================================================================
end