class Aluno < ApplicationRecord
  belongs_to :escola, counter_cache: :alunos_count
  belongs_to :turma, optional: true
  has_one :user, as: :profile, dependent: :destroy
 
  # Apenas o campo 'nome' é obrigatório agora
  validates :nome, presence: true
  
  # As outras validações de formato continuam, mas não exigem o preenchimento
  # Se o campo for preenchido, a validação de formato será aplicada.
  validates :cpf, format: { with: /\A\d{3}\.\d{3}\.\d{3}-\d{2}\z/, message: "formato incorreto (ex: 000.000.000-00)" }, allow_blank: true
  validates :telefone, format: { with: /\A\(\d{2}\)\s?\d{4,5}-\d{4}\z/, message: "formato incorreto (ex: (00) 00000-0000)" }, allow_blank: true
  
  # Adicionei allow_blank: true para as outras validações. Isso faz com que
  # o campo possa estar em branco, mas se for preenchido, o formato deve ser
  # o correto.
  validates :data_nascimento, :cpf, :rg, :telefone, :email, :responsavel_1, :telefone_responsavel_1, presence: false
  
  validate :turma_belongs_to_same_escola, if: :turma_id?
  
  # accepts_nested_attributes_for :endereco, allow_destroy: true
  accepts_nested_attributes_for :user, allow_destroy: true

  scope :allocated, -> { where.not(turma_id: nil) }
  scope :unallocated, -> { where(turma_id: nil) }
  scope :by_escola, ->(escola_id) { where(escola_id: escola_id) }

  def display_name
    nome
  end

  def allocated?
    turma_id.present?
  end

  def unallocated?
    !allocated?
  end

  def status
    allocated? ? "Alocado - #{turma.nome}" : "Não alocado"
  end

  def idade
    return nil unless data_nascimento
    
    hoje = Date.current
    idade_calculada = hoje.year - data_nascimento.year
    
    # Ajusta se ainda não fez aniversário este ano
    if hoje.month < data_nascimento.month || 
      (hoje.month == data_nascimento.month && hoje.day < data_nascimento.day)
      idade_calculada -= 1
    end
    
    idade_calculada
  end

  before_create :set_idade_on_create

  private

  def turma_belongs_to_same_escola
    return unless turma_id && escola_id
    
    unless turma.escola_id == escola_id
      errors.add(:turma, "deve pertencer à mesma escola do aluno")
    end
  end

  def set_idade_on_create
    if data_nascimento.present?
      hoje = Date.current
      idade_calculada = hoje.year - data_nascimento.year
      
      # Ajusta se ainda não fez aniversário este ano
      if hoje.month < data_nascimento.month || 
        (hoje.month == data_nascimento.month && hoje.day < data_nascimento.day)
        idade_calculada -= 1
      end
      
      self.idade = idade_calculada
    end
  end
end
