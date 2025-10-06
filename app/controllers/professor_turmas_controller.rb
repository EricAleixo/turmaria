class ProfessorTurmasController < ApplicationController
  layout 'dashboard'
  before_action :authenticate_any_user!
  before_action :set_professor, only: [:show, :create, :destroy]
  before_action :set_professor_turma, only: [:destroy]

  def show
    @turmas_disponiveis = Turma.where.not(id: @professor.turma_ids)
    @turmas_associadas = @professor.turmas.includes(:escola)
  end

  def create
    @turma = Turma.find(params[:turma_id])
    
    if @professor.turmas.include?(@turma)
      redirect_to professor_professor_turmas_path(@professor), alert: 'Professor já está associado a esta turma.'
    else
      @professor.turmas << @turma
      redirect_to professor_professor_turmas_path(@professor), notice: 'Professor associado à turma com sucesso!'
    end
  end

  def destroy
    @professor_turma.destroy
    redirect_to professor_professor_turmas_path(@professor), notice: 'Associação removida com sucesso!'
  end

  private

  def authenticate_any_user!
    unless user_signed_in?
      redirect_to new_user_session_path, alert: 'Você precisa fazer login para continuar.'
    end
  end

  def set_professor
    @professor = Professor.find(params[:professor_id] || params[:id])
  end

  def set_professor_turma
    @professor_turma = ProfessorTurma.find(params[:id])
  end
end
