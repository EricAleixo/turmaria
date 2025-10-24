class Professor < ApplicationRecord

  # === Active Storage ===
  has_one_attached :foto

  include EmailCadastroUser
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable
 
  belongs_to :escola, optional: true
  belongs_to :coordenador, optional: true
  has_many :professor_turmas
  has_many :turmas, through: :professor_turmas
  has_one :endereco, dependent: :destroy
  has_many :alunos, through: :turmas
  has_many :professor_disciplinas
  has_many :disciplinas, through: :professor_disciplinas
  has_many :frequencias, dependent: :destroy

  accepts_nested_attributes_for :endereco

  enum tipo_professor: { concursado: "concursado", contratado: "contratado" }
  enum formacao: { mestrado: "mestrado", doutorado: "doutorado", pos_graduado:"pos_graduado", graduado:"graduado" }

  validates :nome, :cpf, presence: true
  validates :cpf, uniqueness: true

  # Busca por nome
  scope :por_nome, ->(busca) { where("nome ILIKE ?", "%#{busca}%") if busca.present? }

  # Filtro por formação
  scope :por_formacao, ->(formacao) { where(formacao: formacao) if formacao.present? }

  # Filtro por tipo (concursado, contratado etc)
  scope :por_tipo, ->(tipo) { where(tipo_professor: tipo) if tipo.present? }



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

  # 1. Total de Turmas Ativas
  def total_turmas_ativas
    # Assumindo que o enum de Turma tenha um status 'ativa' ou 'ativo'
    # Como seu modelo Turma não mostrou um campo status, vou simular o que seria lógico:
    turmas.count # Contamos todas as turmas que o professor está associado.
    # Se houvesse um campo "status" na Turma, seria:
    # turmas.where(status: 'ativo').count 
  end

  # 2. Total de Disciplinas Únicas
  def total_disciplinas_unicas
    disciplinas.distinct.count
  end

  # 3. Total de Alunos Únicos
  # A associação 'has_many :alunos, through: :turmas' funciona para isso.
  def total_alunos_unicos
    alunos.distinct.count
  end

  # 4. Média Geral de Notas
  def media_geral_notas
    # 1. Identifica todas as IDs de disciplinas lecionadas
    disciplina_ids = self.disciplina_ids

    # 2. Encontra todas as configurações de avaliação (provas/trabalhos) ligadas a essas disciplinas
    # (Inclui avaliações de recuperação, a menos que você decida excluí-las aqui)
    avaliacao_config_ids = AvaliacaoConfiguracao
                           .where(disciplina_id: disciplina_ids)
                           .pluck(:id)
                           
    # 3. Calcula a média dos RegistrosDeNotas
    media = RegistroDeNota.where(avaliacao_configuracao_id: avaliacao_config_ids).average(:valor)

    # Retorna a média ou 0.0 se for nil, formatado para duas casas (antes de ser usado na view)
    media.present? ? media.round(2) : 0.0
  end

  # 5. Média de Presença
  def media_presenca
    # MANTER MOCK (Pendente de Frequencia)
    rand(85.0..99.0).round(1)
  end

  # 6. Média Pior Turma (Simulação)
  def pior_turma_media
    # Lógica real: Agrupar `RegistroDeNota` por `Turma`, calcular a média
    # de cada grupo e encontrar o valor mínimo.
    
    # Por enquanto, retorna um valor simples com o nome da pior turma
    {
      media: rand(5.0..7.0).round(1),
      nome: "9º Ano A - Matemática" # Valor fixo/mock, pois o cálculo é pesado
    }
  end

  # 7. Notas Lançadas no Mês
  def notas_lancadas_mes
    # Usa as mesmas IDs de Avaliação para contar apenas as criadas neste mês
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
    # Retorna uma lista de hashes única para cada par Disciplina/Turma
    
    # O método `turmas` já inclui todas as turmas do professor.
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

  # 9. Dados para Gráfico: Desempenho por Disciplina
  def grafico_desempenho_disciplinas
    # Mapeia a média de notas para cada disciplina lecionada pelo professor
    
    # Simulação por complexidade:
    disciplinas_ativas = disciplinas.distinct.limit(4).pluck(:nome)
    
    {
      labels: disciplinas_ativas,
      data: disciplinas_ativas.map { |d| rand(7.0..9.0).round(1) }
    }
  end

  # 10. Dados para Gráfico: Evolução de Notas (Semestral)
  def grafico_evolucao_notas
    # MANTER MOCK (Dados de tempo complexos e pesados)
    {
      labels: ["Fev", "Mar", "Abr", "Mai", "Jun", "Jul"],
      data: [rand(7.0..8.0).round(1), rand(7.2..8.2).round(1), rand(7.5..8.5).round(1), rand(7.7..8.7).round(1), rand(8.0..9.0).round(1), rand(7.9..8.9).round(1)]
    }
  end

  # 11. Dados para Gráfico: Presença por Turma
  def grafico_presenca_turmas
    # MANTER MOCK (Pendente de Frequencia)
    turmas_ativas = turmas.limit(4).pluck(:nome)
    {
      labels: turmas_ativas,
      data: turmas_ativas.map { |t| rand(85.0..98.0).round(1) }
    }
  end

  def total_notas_cadastradas
    # Este método busca a contagem total de registros de nota
    disciplina_ids = self.disciplina_ids
    
    # Busca todas as configurações de avaliação ligadas às suas disciplinas
    avaliacao_config_ids = AvaliacaoConfiguracao
                           .where(disciplina_id: disciplina_ids)
                           .pluck(:id)

    # Conta todos os RegistrosDeNota para essas avaliações
    RegistroDeNota.where(
      avaliacao_configuracao_id: avaliacao_config_ids
    ).count
    # NOTA: Se o model for diferente (ex: Nota), ajuste o nome
  end
  
  # 2. Escola que participa (Método já existe pela associação `belongs_to :escola`)
  # (Não precisa de código extra, o @user.escola.nome já funciona)

  # 3. Total de Frequências Cadastradas (do professor, em todas as suas turmas)
  def total_frequencias_cadastradas
    # Simulação: Conta todos os registros de frequência que o professor criou/lançou.
    # Assumindo que o model Frequencia tenha uma associação com o professor.
    
    # Se você tiver has_many :frequencias (como estava no Aluno):
    # frequencias.count 
    
    # Se não tiver a associação, use um valor MOCK por enquanto:
    rand(50..300) 
  end

end
