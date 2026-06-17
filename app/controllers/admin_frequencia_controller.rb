class AdminFrequenciaController < ApplicationController
  layout "dashboard"
  rescue_from ActiveRecord::RecordNotFound, with: :frequencia_nao_encontrada

  def index
    @escola = Escola.find(params[:escola_id])
    @frequencias = Frequencia
                        .da_escola(@escola.id)
                        .includes(:turma, :disciplina, :professor)
                        .order(data_aula: :desc, created_at: :desc)

    aplicar_filtros
    
    @frequencias = @frequencias.page(params[:page]).per(20) if defined?(Kaminari)
  end

  def selecionar_escola
    @escolas = current_admin.escolas
  end

  def show
    @escola = Escola.find(params[:escola_id])
    @frequencia = Frequencia
                        .da_escola(@escola.id)
                        .find(params[:id])
    @frequencia_alunos = @frequencia.frequencia_alunos
                                        .includes(:aluno)
                                        .order('alunos.nome ASC')
  end

  def edit
    @escola = Escola.find(params[:escola_id])
    @frequencia = Frequencia
                        .da_escola(@escola.id)
                        .find(params[:id])
    @turma = @frequencia.turma
    @frequencia_alunos = @frequencia.frequencia_alunos
            .includes(:aluno)
            .order('alunos.nome ASC')
  end

  def update
    @escola = Escola.find(params[:escola_id])
    @frequencia = Frequencia.find(params[:id])
    @turma = @frequencia.turma
    
    if @frequencia.update(frequencia_params)
      redirect_to escola_frequencia_path(@escola, @frequencia), 
                  notice: 'Frequência atualizada com sucesso!'
    else
      @frequencia_alunos = @frequencia.frequencia_alunos.includes(:aluno).order('alunos.nome ASC')
      flash.now[:alert] = "Erro ao atualizar frequência: #{@frequencia.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @escola = Escola.find(params[:escola_id])
    @frequencia = Frequencia.find(params[:id])
    
    if @frequencia.destroy
      redirect_to escola_frequencias_path(@escola), 
                  notice: 'Frequência excluída com sucesso!'
    else
      redirect_to escola_frequencia_path(@escola, @frequencia),
                  alert: 'Erro ao excluir frequência. Tente novamente.'
    end
  end

  private

  def aplicar_filtros
    # Filtro por Turma
    if params[:turma_id].present?
      @frequencias = @frequencias.where(turma_id: params[:turma_id])
    end

    # Filtro por Disciplina
    if params[:disciplina_id].present?
      @frequencias = @frequencias.where(disciplina_id: params[:disciplina_id])
    end

    # Filtro por Professor
    if params[:professor_id].present?
      @frequencias = @frequencias.where(professor_id: params[:professor_id])
    end

    # Filtro por Data
    if params[:data].present?
      begin
        data_filtro = Date.parse(params[:data])
        @frequencias = @frequencias.where(data_aula: data_filtro)
      rescue ArgumentError
        # Data inválida, ignora o filtro
        flash.now[:alert] = "Data inválida fornecida no filtro."
      end
    end

    # Filtro por Período (opcional - se quiser adicionar)
    if params[:data_inicio].present? && params[:data_fim].present?
      begin
        data_inicio = Date.parse(params[:data_inicio])
        data_fim = Date.parse(params[:data_fim])
        @frequencias = @frequencias.where(data_aula: data_inicio..data_fim)
      rescue ArgumentError
        flash.now[:alert] = "Período de datas inválido."
      end
    end

    # Busca por texto (opcional - busca em conteúdo ou observações)
    if params[:busca].present?
      termo_busca = "%#{params[:busca]}%"
      @frequencias = @frequencias.where(
        "conteudo_trabalhado ILIKE ? OR observacoes ILIKE ?", 
        termo_busca, 
        termo_busca
      )
    end
  end

  def frequencia_params
    params.require(:frequencia).permit(
      :professor_id,
      :disciplina_id,
      :data_aula,
      :conteudo_trabalhado,
      :observacoes
    )
  end

  def frequencia_nao_encontrada
    redirect_to escola_frequencias_path(params[:escola_id]),
                alert: "Frequência não encontrada."
  end
end