# app/controllers/aluno/contents_controller.rb
class Aluno::ContentsController < ApplicationController
  include DisciplinaHelper
  layout 'dashboard'
  before_action :authenticate_aluno!
  before_action :load_aluno_context, only: [:atividades, :materiais, :show]
  before_action :set_content_config, only: [:show] # <-- NOVO before_action

  # GET /aluno/atividades
  def atividades
    # Filtra pelo ENUM: tipo: atividade (1)
    @contents = fetch_contents_by_type(:atividade)
    @titulo_pagina = "Minhas Atividades"
    @type_label = "Atividades"
    render :index # Usará a nova view index para listagem
  end

  # GET /aluno/materiais
  def materiais
    # Filtra pelo ENUM: tipo: material (0)
    @contents = fetch_contents_by_type(:material)
    @titulo_pagina = "Meus Materiais de Estudo"
    @type_label = "Materiais de Estudo"
    render :index # Usará a nova view index para listagem
  end

  # GET /aluno/conteudos/:id
  def show
    @content = fetch_contents_base_scope.find(params[:id])
    @titulo_pagina = @content.titulo

    disciplina = @content.disciplina
    @cor_disciplina = disciplina.try(:cor_nome) || disciplina.try(:cor) || '#10B981'
    
  rescue ActiveRecord::RecordNotFound
    redirect_to aluno_minhas_atividades_e_path, alert: "Conteúdo não encontrado ou indisponível."
  end

  private

  # Garante que o aluno tenha uma turma para buscar conteúdos
  def load_aluno_context
    @aluno = current_aluno
    @turma_atual = @aluno.turma
    unless @turma_atual
      redirect_to dashboard_path, alert: "Você não está associado a uma turma, não é possível visualizar conteúdos."
    end
  end

  # Escopo base: Conteúdos da turma do aluno, ordenados (usado por todas as actions)
  def fetch_contents_base_scope
    disciplina_ids = @turma_atual.disciplinas.pluck(:id)
    
    Conteudo.includes(:disciplina)
            .where(disciplina_id: disciplina_ids, escola_id: @aluno.escola_id)
            # Ordena pelo BIMESTRE (do mais alto para o mais baixo)
            .order(bimestre: :desc, created_at: :desc)
  end

  # Adiciona o filtro de tipo ao escopo base
  def fetch_contents_by_type(content_type)
    fetch_contents_base_scope.where(tipo: Conteudo.tipos[content_type])
  end

  def set_content_config
    # Carrega o conteúdo se ainda não estiver carregado (para garantir o acesso à disciplina)
    if @content.nil?
      @content = fetch_contents_base_scope.find(params[:id]) rescue nil
    end
    
    # Define @area_cfg que contém :cor, :bg, e :text
    if @content && @content.disciplina&.area_disciplina.present?
      @area_cfg = area_cfg(@content.disciplina.area_disciplina.to_s)
    else
      # Fallback para o cinza definido em area_cfg
      @area_cfg = area_cfg(nil) 
    end
  end

end