# app/models/disciplina.rb
class Disciplina < ApplicationRecord
  # Associações
  has_many :turma_disciplinas
  has_many :turmas, through: :turma_disciplinas

  has_many :avaliacoes_configuracoes, 
           class_name: 'AvaliacaoConfiguracao', 
           foreign_key: 'disciplina_id'
  has_many :avaliacoes_bimestrais

  has_many :professor_disciplinas
  has_many :professores, through: :professor_disciplinas, source: :professor
  
  belongs_to :escola
  belongs_to :area_disciplina, optional: true
  has_many :conteudos, dependent: :destroy

  # Validações
  validates :nome, presence: true
  validates :area, presence: true
  validates :escola_id, presence: true

  # Callbacks
  before_validation :associar_ou_criar_area, if: -> { area.present? }

  private

  def associar_ou_criar_area
    # Busca área existente (case-insensitive)
    area_existente = AreaDisciplina.find_by('LOWER(nome) = ?', area.downcase)
    
    if area_existente
      # Se existe, apenas associa
      self.area_disciplina = area_existente
      # Atualiza a cor se foi fornecida uma nova
      area_existente.update(cor: cor) if cor.present? && area_existente.cor != cor
    else
      # Se não existe, cria nova área
      nova_area = AreaDisciplina.create(
        nome: area,
        cor: cor || '#FFFFFF'
      )
      
      if nova_area.persisted?
        self.area_disciplina = nova_area
      else
        errors.add(:area, "não pôde ser criada: #{nova_area.errors.full_messages.join(', ')}")
      end
    end
  end
end
