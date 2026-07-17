class TurmasController < ApplicationController

  layout 'dashboard'

  before_action :set_escola
  before_action :set_turma, only: %i[
  show edit update destroy 
  assign_students assign_student remove_from_turma remove_students 
  assign_professors assign_professor remove_professor_from_turma planos_de_ensino
]

  # GET /escolas/:escola_id/turmas or /escolas/:escola_id/turmas.json
  def index
    @turmas = @escola.turmas

    if params[:busca].present?
      @turmas = @turmas.where('nome ILIKE ?', "%#{params[:busca]}%")
    end

    if params[:filtros].present?
      turnos_filtrados = params[:filtros].reject(&:blank?)
      @turmas = @turmas.where(turno: turnos_filtrados) if turnos_filtrados.any?
    end

    @turmas = @turmas.order(:nome)
  end

  # GET /escolas/:escola_id/turmas/1 or /escolas/:escola_id/turmas/1.json
  def show
  end

  # GET /escolas/:escola_id/turmas/new
  def new
    @turma = @escola.turmas.build
    # 🟢 CORREÇÃO CRÍTICA: Variável padronizada para @anos_letivos
    @anos_letivos = @escola.ano_letivos.order(ano: :desc)
  end

  # GET /escolas/:escola_id/turmas/1/edit
  def edit
    # 🟢 CORREÇÃO CRÍTICA: Variável padronizada para @anos_letivos
    @anos_letivos = @escola.ano_letivos.order(ano: :desc)
  end

  # POST /escolas/:escola_id/turmas or /escolas/:escola_id/turmas.json
  def create
    @turma = @escola.turmas.build(turma_params)

    respond_to do |format|
      if @turma.save
        format.html { redirect_to [@escola, @turma], notice: "Turma foi criada com sucesso." }
        format.json { render :show, status: :created, location: [@escola, @turma] }
      else
        # 🟢 CORREÇÃO CRÍTICA: Variável padronizada para @anos_letivos
        @anos_letivos = @escola.ano_letivos.order(ano: :desc)
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
        # 🟢 CORREÇÃO CRÍTICA: Variável padronizada para @anos_letivos
        @anos_letivos = @escola.ano_letivos.order(ano: :desc)
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @turma.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /escolas/:escola_id/turmas/1 or /escolas/:escola_id/turmas/1.json
  def destroy
    if @turma.destroy
      respond_to do |format|
        format.html { redirect_to escola_path(@escola), status: :see_other, notice: "Turma excluída com sucesso." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to escola_turma_path(@escola, @turma), alert: @turma.errors.full_messages.to_sentence }
        format.json { render json: @turma.errors, status: :unprocessable_entity }
      end
    end
  end

    def planos_de_ensino
    authorize @escola, :show?

    puts "Turma: ",@turma
 
    @ano_letivo = AnoLetivo.find(@turma.ano_letivo_id)
 
    # Todas as disciplinas da turma, mesmo as que ainda não têm nenhum plano —
    # assim dá pra ver de cara o que falta cadastrar.
    @disciplinas = @turma.disciplinas.includes(:area_disciplina).order(:nome)
 
    # Lookup rápido [disciplina_id, bimestre] => plano, pra montar o roadmap sem N+1
    @planos_lookup = @turma.planos_de_ensino
                            .includes(:professor)
                            .each_with_object({}) do |plano, hash|
                              hash[[plano.disciplina_id, plano.bimestre]] = plano
    end
  end


  # ... (O restante das actions assign_students, assign_student, remove_from_turma permanece inalterado)

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
      @aluno = Aluno.find_by(id: params[:student_id], escola_id: @escola.id)
      
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
      @aluno = Aluno.find_by(id: params[:student_id], turma_id: @turma.id)
      puts "Papapapa: ", params[:student_id]
      puts "Parara ",@turma.id
      
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

  def remove_students
    if params[:student_ids].blank?
      redirect_to request.referer || assign_students_escola_turma_path(@escola, @turma),
                  alert: 'Nenhum aluno selecionado para remoção.'
      return
    end

    students = Aluno.where(
      id: params[:student_ids],
      turma_id: @turma.id
    )

    if students.empty?
      respond_to do |format|
        format.html do
          redirect_to request.referer || assign_students_escola_turma_path(@escola, @turma),
                      alert: 'Nenhum aluno válido encontrado nesta turma.'
        end
        format.js { render js: "alert('Nenhum aluno válido encontrado nesta turma.');" }
      end
      return
    end

    removed_count = students.update_all(turma_id: nil)

    respond_to do |format|
      format.html do
        redirect_to request.referer || assign_students_escola_turma_path(@escola, @turma),
                    notice: "#{removed_count} aluno(s) removido(s) da turma #{@turma.nome}."
      end
      format.js { render js: "window.location.reload();" }
    end
  end



  # Adicionar no TurmasController

# GET /escolas/:escola_id/turmas/:id/assign_professors
  def assign_professors
    # Filtros separados para cada tabela
    allocated_type_filter = params[:allocated_type_filter]
    allocated_order_filter = params[:allocated_order_filter] || 'recent'
    allocated_search_query = params[:allocated_search]

    available_type_filter = params[:available_type_filter]
    available_order_filter = params[:available_order_filter] || 'recent'
    available_search_query = params[:available_search]

    # Base queries - professores já alocados nesta turma
    @allocated_professores = @turma.professores.includes(:escola)
    
    # Professores disponíveis - que pertencem à escola mas NÃO estão nesta turma
    @unallocated_professores = Professor.where(escola_id: @escola.id)
                                        .where.not(id: @turma.professores.pluck(:id))
                                        .includes(:escola)

    # Aplicar filtros para professores alocados
    if allocated_type_filter.present?
      @allocated_professores = @allocated_professores.where(tipo_professor: allocated_type_filter)
    end

    if allocated_search_query.present?
      @allocated_professores = @allocated_professores.where(
        'nome ILIKE ? OR email ILIKE ?', 
        "%#{allocated_search_query}%", 
        "%#{allocated_search_query}%"
      )
    end

    case allocated_order_filter
    when 'recent'
      @allocated_professores = @allocated_professores.order(created_at: :desc)
    when 'oldest'
      @allocated_professores = @allocated_professores.order(created_at: :asc)
    when 'name_asc'
      @allocated_professores = @allocated_professores.order(:nome)
    when 'name_desc'
      @allocated_professores = @allocated_professores.order(nome: :desc)
    end

    # Aplicar filtros para professores disponíveis
    if available_type_filter.present?
      @unallocated_professores = @unallocated_professores.where(tipo_professor: available_type_filter)
    end

    if available_search_query.present?
      @unallocated_professores = @unallocated_professores.where(
        'nome ILIKE ? OR email ILIKE ?', 
        "%#{available_search_query}%", 
        "%#{available_search_query}%"
      )
    end

    case available_order_filter
    when 'recent'
      @unallocated_professores = @unallocated_professores.order(created_at: :desc)
    when 'oldest'
      @unallocated_professores = @unallocated_professores.order(created_at: :asc)
    when 'name_asc'
      @unallocated_professores = @unallocated_professores.order(:nome)
    when 'name_desc'
      @unallocated_professores = @unallocated_professores.order(nome: :desc)
    end
    
    if request.patch?
      if params[:professor_ids].present?
        professor_ids = params[:professor_ids]
        professores = Professor.where(id: professor_ids, escola_id: @escola.id)
        
        success_count = 0
        professores.each do |professor|
          unless @turma.professores.include?(professor)
            @turma.professores << professor
            success_count += 1
          end
        end
        
        if success_count > 0
          redirect_to assign_professors_escola_turma_path(@escola, @turma), 
                      notice: "#{success_count} professor(es) foram alocados para a turma #{@turma.nome}."
        else
          redirect_to assign_professors_escola_turma_path(@escola, @turma), 
                      alert: 'Erro ao alocar professores para a turma.'
        end
        return
      end
    end
  end

# PATCH /escolas/:escola_id/turmas/:id/assign_professor
  def assign_professor
    if params[:professor_ids].present?
      professor_ids = params[:professor_ids]
      action_type = params[:action_type] # Para diferenciar de 'action' do Rails

      if action_type == 'remove'
        # Busca professores que estão nesta turma
        professores = @turma.professores.where(id: professor_ids)
        
        if professores.any?
          professores.each do |professor|
            @turma.professores.delete(professor)
          end
          
          redirect_to assign_professors_escola_turma_path(@escola, @turma), 
                      notice: "#{professores.count} professor(es) removido(s) da turma #{@turma.nome}."
        else
          redirect_to assign_professors_escola_turma_path(@escola, @turma), 
                      alert: 'Nenhum professor válido encontrado para remoção.'
        end
      else
        professores = Professor.where(id: professor_ids, escola_id: @escola.id)
        
        success_count = 0
        professores.each do |professor|
          unless @turma.professores.include?(professor)
            @turma.professores << professor
            success_count += 1
          end
        end
        
        if success_count > 0
          redirect_to assign_professors_escola_turma_path(@escola, @turma), 
                      notice: "#{success_count} professor(es) foram alocados para a turma #{@turma.nome}."
        else
          redirect_to assign_professors_escola_turma_path(@escola, @turma), 
                      alert: 'Erro ao alocar professores para a turma.'
        end
      end
    else
      # Busca apenas por ID, sem turma_id
      @professor = Professor.find_by(id: params[:professor_id], escola_id: @escola.id)
      
      if @professor.nil?
        redirect_to assign_professors_escola_turma_path(@escola, @turma), 
                    alert: 'Professor não encontrado.'
        return
      end
      
      unless @turma.professores.include?(@professor)
        @turma.professores << @professor
        redirect_to assign_professors_escola_turma_path(@escola, @turma), 
                    notice: "#{@professor.nome} foi alocado para a turma #{@turma.nome}."
      else
        redirect_to assign_professors_escola_turma_path(@escola, @turma), 
                    alert: 'Professor já está alocado nesta turma.'
      end
    end
  end

# PATCH /escolas/:escola_id/turmas/:id/remove_professor_from_turma
  def remove_professor_from_turma
    if params[:professor_ids].present?
      professor_ids = params[:professor_ids]
      # Busca professores que estão nesta turma
      professores = @turma.professores.where(id: professor_ids)
      
      if professores.any?
        professores.each do |professor|
          @turma.professores.delete(professor)
        end
        
        redirect_to request.referer || assign_professors_escola_turma_path(@escola, @turma), 
                    notice: "#{professores.count} professor(es) removido(s) da turma #{@turma.nome}."
      else
        redirect_to request.referer || assign_professors_escola_turma_path(@escola, @turma), 
                    alert: 'Nenhum professor válido encontrado para remoção.'
      end
    else
      @professor = Professor.find_by(id: params[:professor_id])
      
      if @professor.nil? || !@turma.professores.include?(@professor)
        respond_to do |format|
          format.html { redirect_to request.referer || assign_professors_escola_turma_path(@escola, @turma), alert: 'Professor não encontrado nesta turma.' }
          format.js { render js: "alert('Professor não encontrado nesta turma.');" }
        end
        return
      end
      
      @turma.professores.delete(@professor)
      respond_to do |format|
        format.html { redirect_to request.referer || assign_professors_escola_turma_path(@escola, @turma), notice: "#{@professor.nome} foi removido da turma #{@turma.nome}." }
        format.js { render js: "window.location.reload();" }
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
      # Nota: A busca está corretamente scoped para garantir que a turma pertence à escola atual.
      @turma = @escola.turmas.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def turma_params
      params.require(:turma).permit(:nome, :serie, :turno, :ano_letivo_id, :tipo_avaliacao)
    end
end
 