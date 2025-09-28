class AnoLetivosController < ApplicationController

  layout 'dashboard'

  before_action :set_escola, only: %i[index new create]
  before_action :set_ano_letivo, only: %i[show edit update destroy]

  # GET /escolas/:escola_id/ano_letivos
  def index
    @ano_letivos = @escola.ano_letivos
  end

  # GET /ano_letivos/:id
  def show
    @escola = @ano_letivo.escola
  end

  # GET /escolas/:escola_id/ano_letivos/new
  def new
    @ano_letivo = @escola.ano_letivos.new
    render layout: false if turbo_frame_request?
  end

  # POST /escolas/:escola_id/ano_letivos
  def create
    @ano_letivo = @escola.ano_letivos.new(ano_letivo_params)

    if @ano_letivo.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("turma_ano_letivo_id", partial: "ano_letivos/option", locals: {ano_letivo: @ano_letivo}),
            turbo_stream.update("modal", "")]
        end

        
      format.html {redirect_to escola_ano_letivos_path(@escola), notice: "Ano letivo criado com sucesso."}
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /ano_letivos/:id/edit
  def edit
    @escola = @ano_letivo.escola
  end

  # PATCH/PUT /ano_letivos/:id
  def update
    if @ano_letivo.update(ano_letivo_params)
      redirect_to escola_ano_letivo_path(@ano_letivo.escola, @ano_letivo), notice: "Ano letivo atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /ano_letivos/:id
  def destroy
    escola = @ano_letivo.escola
    @ano_letivo.destroy
    redirect_to escola_ano_letivos_path(escola), notice: "Ano letivo removido com sucesso."
  end

  private

  def set_escola
    @escola = Escola.find(params[:escola_id])
  end

  def set_ano_letivo
    @ano_letivo = AnoLetivo.find(params[:id])
  end

  def ano_letivo_params
    params.require(:ano_letivo).permit(:ano, :data_inicio, :data_fim, :numero_bimestre)
  end
end
