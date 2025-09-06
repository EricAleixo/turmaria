class TurmasController < ApplicationController
  before_action :set_escola
  before_action :set_turma, only: %i[show edit update destroy assign_students assign_student remove_from_turma]

  # GET /escolas/:escola_id/turmas or /escolas/:escola_id/turmas.json
  def index
    @turmas = @escola.turmas
  end

  # GET /escolas/:escola_id/turmas/1 or /escolas/:escola_id/turmas/1.json
  def show
  end

  # GET /escolas/:escola_id/turmas/new
  def new
    @turma = @escola.turmas.build
  end

  # GET /escolas/:escola_id/turmas/1/edit
  def edit
  end

  # POST /escolas/:escola_id/turmas or /escolas/:escola_id/turmas.json
  def create
    @turma = @escola.turmas.build(turma_params)

    respond_to do |format|
      if @turma.save
        format.html { redirect_to [@escola, @turma], notice: "Turma foi criada com sucesso." }
        format.json { render :show, status: :created, location: [@escola, @turma] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @turma.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /escolas/:escola_id/turmas/1 or /escolas/:escola_id/turmas/1.json
  def update
    respond_to do |format|
      if @turma.update(turma_params)
        format.html { redirect_to [@escola, @turma], notice: "Turma foi atualizada com sucesso." }
        format.json { render :show, status: :ok, location: [@escola, @turma] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @turma.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /escolas/:escola_id/turmas/1 or /escolas/:escola_id/turmas/1.json
  def destroy
    @turma.destroy!

    respond_to do |format|
      format.html { redirect_to escola_turmas_path(@escola), status: :see_other, notice: "Turma foi excluída com sucesso." }
      format.json { head :no_content }
    end
  end

  def assign_students
    # Filtros separados para cada tabela
    allocated_age_filter = params[:allocated_age_filter]
    allocated_order_filter = params[:allocated_order_filter] || 'recent'
    allocated_search_query = params[:allocated_search]

    available_age_filter = params[:available_age_filter]
    available_order_filter = params[:available_order_filter] || 'recent'
    available_search_query = params[:available_search]

    # Base queries
    @allocated_alunos = @turma.alunos.includes(:escola)
    @unallocated_alunos = Aluno.where(escola_id: @escola.id, turma_id: nil).includes(:escola)

    # Aplicar filtros para alunos alocados
    if allocated_age_filter.present?
      case allocated_age_filter
      when 'child'
        @allocated_alunos = @allocated_alunos.where('idade BETWEEN ? AND ? OR idade IS NULL', 0, 12)
      when 'teen'
        @allocated_alunos = @allocated_alunos.where('idade BETWEEN ? AND ?', 13, 17)
      when 'adult'
        @allocated_alunos = @allocated_alunos.where('idade >= ?', 18)
      end
    end

    if allocated_search_query.present?
      @allocated_alunos = @allocated_alunos.where('nome ILIKE ?', "%#{allocated_search_query}%")
    end

    case allocated_order_filter
    when 'recent'
      @allocated_alunos = @allocated_alunos.order(created_at: :desc)
    when 'oldest'
      @allocated_alunos = @allocated_alunos.order(created_at: :asc)
    when 'name_asc'
      @allocated_alunos = @allocated_alunos.order(:nome)
    when 'name_desc'
      @allocated_alunos = @allocated_alunos.order(nome: :desc)
    when 'age_asc'
      @allocated_alunos = @allocated_alunos.order('idade ASC NULLS LAST')
    when 'age_desc'
      @allocated_alunos = @allocated_alunos.order('idade DESC NULLS LAST')
    end

    # Aplicar filtros para alunos disponíveis
    if available_age_filter.present?
      case available_age_filter
      when 'child'
        @unallocated_alunos = @unallocated_alunos.where('idade BETWEEN ? AND ? OR idade IS NULL', 0, 12)
      when 'teen'
        @unallocated_alunos = @unallocated_alunos.where('idade BETWEEN ? AND ?', 13, 17)
      when 'adult'
        @unallocated_alunos = @unallocated_alunos.where('idade >= ?', 18)
      end
    end

    if available_search_query.present?
      @unallocated_alunos = @unallocated_alunos.where('nome ILIKE ?', "%#{available_search_query}%")
    end

    case available_order_filter
    when 'recent'
      @unallocated_alunos = @unallocated_alunos.order(created_at: :desc)
    when 'oldest'
      @unallocated_alunos = @unallocated_alunos.order(created_at: :asc)
    when 'name_asc'
      @unallocated_alunos = @unallocated_alunos.order(:nome)
    when 'name_desc'
      @unallocated_alunos = @unallocated_alunos.order(nome: :desc)
    when 'age_asc'
      @unallocated_alunos = @unallocated_alunos.order('idade ASC NULLS LAST')
    when 'age_desc'
      @unallocated_alunos = @unallocated_alunos.order('idade DESC NULLS LAST')
    end
    
    if request.patch?
      if params[:student_ids].present?
        student_ids = params[:student_ids]
        students = Aluno.where(id: student_ids, escola_id: @escola.id, turma_id: nil)
        
        success_count = 0
        students.each do |aluno|
          if aluno.update(turma: @turma)
            success_count += 1
          end
        end
        
        if success_count > 0
          redirect_to assign_students_escola_turma_path(@escola, @turma), 
                      notice: "#{success_count} aluno(s) foram alocados para a turma #{@turma.nome}."
        else
          redirect_to assign_students_escola_turma_path(@escola, @turma), 
                      alert: 'Erro ao alocar alunos para a turma.'
        end
        return
      end
    end
  end

  def assign_student

    if params[:student_ids].present?
      student_ids = params[:student_ids]
      action = params[:action]

      if action == 'remove'
        students = Aluno.where(id: student_ids, turma_id: @turma.id)
        
        if students.any?
          updated_count = students.update_all(turma_id: nil)
          redirect_to assign_students_escola_turma_path(@escola, @turma), 
                      notice: "#{updated_count} aluno(s) removido(s) da turma #{@turma.nome}."
        else
          redirect_to assign_students_escola_turma_path(@escola, @turma), 
                      alert: 'Nenhum aluno válido encontrado para remoção.'
        end
      else
        students = Aluno.where(id: student_ids, escola_id: @escola.id, turma_id: nil)
        
        success_count = 0
        students.each do |aluno|
          if aluno.update(turma: @turma)
            success_count += 1
          end
        end
        
        if success_count > 0
          redirect_to assign_students_escola_turma_path(@escola, @turma), 
                      notice: "#{success_count} aluno(s) foram alocados para a turma #{@turma.nome}."
        else
          redirect_to assign_students_escola_turma_path(@escola, @turma), 
                      alert: 'Erro ao alocar alunos para a turma.'
        end
      end
    else
      @aluno = Aluno.find_by(id: params[:aluno_id], escola_id: @escola.id)
      
      if @aluno.nil?
        redirect_to assign_students_escola_turma_path(@escola, @turma), 
                    alert: 'Aluno não encontrado.'
        return
      end
      
      if @aluno.update(turma: @turma)
        redirect_to assign_students_escola_turma_path(@escola, @turma), 
                    notice: "#{@aluno.nome} foi alocado para a turma #{@turma.nome}."
      else
        redirect_to assign_students_escola_turma_path(@escola, @turma), 
                    alert: 'Erro ao alocar aluno para a turma.'
      end
    end
  end

  def remove_from_turma
    if params[:student_ids].present?
      student_ids = params[:student_ids]
      students = Aluno.where(id: student_ids, turma_id: @turma.id)
      
      if students.any?
        updated_count = students.update_all(turma_id: nil)
        redirect_to request.referer || assign_students_escola_turma_path(@escola, @turma), 
                    notice: "#{updated_count} aluno(s) removido(s) da turma #{@turma.nome}."
      else
        redirect_to request.referer || assign_students_escola_turma_path(@escola, @turma), 
                    alert: 'Nenhum aluno válido encontrado para remoção.'
      end
    else
      @aluno = Aluno.find_by(id: params[:aluno_id], turma_id: @turma.id)
      
      if @aluno.nil?
        respond_to do |format|
          format.html { redirect_to request.referer || assign_students_escola_turma_path(@escola, @turma), alert: 'Aluno não encontrado nesta turma.' }
          format.js { render js: "alert('Aluno não encontrado nesta turma.');" }
        end
        return
      end
      
      if @aluno.update(turma: nil)
        respond_to do |format|
          format.html { redirect_to request.referer || assign_students_escola_turma_path(@escola, @turma), notice: "#{@aluno.nome} foi removido da turma #{@turma.nome}." }
          format.js { render js: "window.location.reload();" }
        end
      else
        respond_to do |format|
          format.html { redirect_to request.referer || assign_students_escola_turma_path(@escola, @turma), alert: 'Erro ao remover aluno da turma.' }
          format.js { render js: "alert('Erro ao remover aluno da turma.');" }
        end
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_escola
      @escola = Escola.find(params[:escola_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_turma
      @turma = @escola.turmas.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def turma_params
      params.require(:turma).permit(:nome, :serie, :turno)
    end
end
