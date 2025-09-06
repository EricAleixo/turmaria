class Aluno < ApplicationRecord
  belongs_to :escola
  belongs_to :turma, optional: true
  has_one :endereco, dependent: :destroy
  has_one :user, as: :profile, dependent: :destroy

  validates :nome, presence: true
  validate :turma_belongs_to_same_escola, if: :turma_id?
  
  accepts_nested_attributes_for :endereco, allow_destroy: true
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
