class AvaliacaoConfiguracao < ApplicationRecord
  self.table_name = 'avaliacoes_configuracoes'

  # Associações
  belongs_to :turma
  belongs_to :disciplina
  has_many :registros_de_notas, class_name: 'RegistroDeNota', dependent: :destroy
  
  # Nova Associação para Recuperação (esta avaliação é uma recuperação de qual prova?)
  belongs_to :avaliacao_original, class_name: 'AvaliacaoConfiguracao', 
                                  foreign_key: 'avaliacao_original_id', 
                                  optional: true

  # Associações Inversas: Uma avaliação padrão pode ter várias recuperações
  has_many :avaliacoes_recuperacao, class_name: 'AvaliacaoConfiguracao', 
                                    foreign_key: 'avaliacao_original_id',
                                    # 🚨 ALTERAÇÃO CRÍTICA: Apaga a recuperação se a original for apagada
                                    dependent: :destroy
  
  # Validações
  validates :bimestre, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :nome, presence: true, uniqueness: { scope: [:turma_id, :disciplina_id, :bimestre] }
  
  # REGRA DE NEGÓCIO: Se for recuperação, DEVE ter uma avaliação original associada.
  validates :avaliacao_original_id, presence: true, if: :recuperacao?
  # REGRA DE NEGÓCIO: Se NÃO for recuperação, NÃO PODE ter uma avaliação original associada.
  validates :avaliacao_original_id, absence: true, unless: :recuperacao?

  # Scopes úteis (A ordem agora é implícita pelo created_at)
  scope :do_bimestre, ->(bimestre) { where(bimestre: bimestre) }
  scope :padrao, -> { where(is_recuperacao: false) }
  scope :recuperacao, -> { where(is_recuperacao: true) }

  # Alias para clareza
  alias_attribute :recuperacao?, :is_recuperacao
end