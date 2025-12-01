class Professor < ApplicationRecord

  # === Active Storage ===
  has_one_attached :foto

  # === Includes ===
  include EmailCadastroUser
  
  # === Devise ===
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable
  
  # === Associações ===
  belongs_to :escola, optional: true
  belongs_to :coordenador, class_name: 'Professor', foreign_key: 'coordenador_id', optional: true
  has_many :professor_turmas
  has_many :turmas, through: :professor_turmas
  has_one :endereco, dependent: :destroy
  has_many :alunos, through: :turmas
  has_many :professor_disciplinas
  has_many :disciplinas, through: :professor_disciplinas
  has_many :frequencias, dependent: :destroy
  # Nota: Se coordenador_id for uma chave para professor, a associação está correta acima.
  # Se for para outra tabela (ex: Coordenador), o belongs_to deve ser ajustado.
  # Assumi que Professor pode ser coordenador de outro professor/equipe (uso do coordenador_id).

  accepts_nested_attributes_for :endereco

  # === Enums ===
  enum tipo_professor: { concursado: "concursado", contratado: "contratado" }
  enum formacao: { mestrado: "mestrado", doutorado: "doutorado", pos_graduado: "pos_graduado", graduado: "graduado" }

  # === Validações ===
  validates :nome, :cpf, presence: true
  validates :cpf, uniqueness: true

  # === Scopes de Filtros (Ajustados para o Modal) ===
  
  # Busca por nome (usando ILIKE para case-insensitivity)
  scope :por_nome, ->(busca) { 
    where("nome ILIKE ?", "%#{busca}%") if busca.present? 
  }

  # Filtro por formação (Ajustado para receber Array - compatível com o modal)
  # Ex: Professor.por_formacao(["mestrado", "doutorado"]) -> WHERE (formacao IN ('mestrado', 'doutorado'))
  scope :por_formacao, ->(formacoes) { 
    where(formacao: formacoes) if formacoes.present? 
  }

  # Filtro por tipo (CORRIGIDO para usar 'tipo_professor' e Ajustado para receber Array)
  scope :por_tipo, ->(tipos) { 
    where(tipo_professor: tipos) if tipos.present? 
  }

  # === Métodos de Negócio e Dashboard ===

  def endereco_completo
    return "Endereço não cadastrado" unless endereco.present?
    
    parts = []
    parts << "#{endereco.logradouro}, #{endereco.numero}" if endereco.logradouro.present? && endereco.numero.present?
    parts << endereco.complemento if endereco.complemento.present?
    parts << endereco.bairro if endereco.bairro.present?
    if endereco.cidade.present?
      parts << "#{endereco.cidade.nome} - #{endereco.cidade.estado.nome}"
    end
    parts << "CEP: #{endereco.cep}" if endereco.cep.present?
    
    parts.join(', ')
  end

  ## Métricas do Dashboard

  # 1. Total de Turmas Ativas
  def total_turmas_ativas
    # Assumindo que o Turma.count é suficiente
    turmas.count 
  end

  # 2. Total de Disciplinas Únicas
  def total_disciplinas_unicas
    disciplinas.distinct.count
  end

  # 3. Total de Alunos Únicos
  def total_alunos_unicos
    alunos.distinct.count
  end

  # 4. Média Geral de Notas
  def media_geral_notas
    disciplina_ids = self.disciplina_ids
    
    avaliacao_config_ids = AvaliacaoConfiguracao
                            .where(disciplina_id: disciplina_ids)
                            .pluck(:id)
                            
    # Nota: Assumi a existência do model RegistroDeNota
    media = RegistroDeNota.where(avaliacao_configuracao_id: avaliacao_config_ids).average(:valor)

    media.present? ? media.round(2) : 0.0
  end

  # 5. Média de Presença (MOCK)
  def media_presenca
    rand(85.0..99.0).round(1)
  end

  # 6. Média Pior Turma (MOCK)
  def pior_turma_media
    {
      media: rand(5.0..7.0).round(1),
      nome: "9º Ano A - Matemática"
    }
  end

  # 7. Notas Lançadas no Mês
  def notas_lancadas_mes
    disciplina_ids = self.disciplina_ids
    
    avaliacao_config_ids = AvaliacaoConfiguracao
                            .where(disciplina_id: disciplina_ids)
                            .pluck(:id)

    RegistroDeNota.where(
      avaliacao_configuracao_id: avaliacao_config_ids,
      created_at: Time.current.all_month
    ).count
  end

  # 8. Lista de Disciplinas e Turmas
  def disciplinas_e_turmas_atribuidas
    turmas.includes(:turma_disciplinas, :disciplinas).flat_map do |turma|
      turma.disciplinas.map do |disciplina|
        {
          disciplina: disciplina.nome,
          turma: turma.nome_completo, 
          id: turma.id 
        }
      end
    end.uniq { |item| [item[:disciplina], item[:turma]] }
  end

  # 9. Dados para Gráfico: Desempenho por Disciplina (MOCK)
  def grafico_desempenho_disciplinas
    disciplinas_ativas = disciplinas.distinct.limit(4).pluck(:nome)
    
    {
      labels: disciplinas_ativas,
      data: disciplinas_ativas.map { |d| rand(7.0..9.0).round(1) }
    }
  end

  # 10. Dados para Gráfico: Evolução de Notas (Semestral) (MOCK)
  def grafico_evolucao_notas
    {
      labels: ["Fev", "Mar", "Abr", "Mai", "Jun", "Jul"],
      data: [rand(7.0..8.0).round(1), rand(7.2..8.2).round(1), rand(7.5..8.5).round(1), rand(7.7..8.7).round(1), rand(8.0..9.0).round(1), rand(7.9..8.9).round(1)]
    }
  end

  # 11. Dados para Gráfico: Presença por Turma (MOCK)
  def grafico_presenca_turmas
    turmas_ativas = turmas.limit(4).pluck(:nome)
    {
      labels: turmas_ativas,
      data: turmas_ativas.map { |t| rand(85.0..98.0).round(1) }
    }
  end

  def total_notas_cadastradas
    disciplina_ids = self.disciplina_ids
    
    avaliacao_config_ids = AvaliacaoConfiguracao
                            .where(disciplina_id: disciplina_ids)
                            .pluck(:id)

    RegistroDeNota.where(
      avaliacao_configuracao_id: avaliacao_config_ids
    ).count
  end
  
  # 3. Total de Frequências Cadastradas (MOCK)
  def total_frequencias_cadastradas
    # Simulação: Conta todos os registros de frequência que o professor criou/lançou.
    rand(50..300) 
  end
end