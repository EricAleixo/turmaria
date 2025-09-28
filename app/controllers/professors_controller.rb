class ProfessorsController < ApplicationController
  layout 'dashboard'
  before_action :set_professor, only: [:show, :edit, :update, :destroy]
  
  def index
    @professores = Professor.all
  end

  def show
    
  end

  def new
    @professor = Professor.new
  end

  def create
    @professor = Professor.new(professor_params)
    if @professor.save
      redirect_to @professor, notice: "Professor criado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end


def edit

end

def update
  if @professor.update(professor_params)
    redirect_to @professor, notice: "Professor atualizado com sucesso!"
  else
    render :edit, status: :unprocessable_entity
  end
end

def destroy
  @professor.destroy
  redirect_to professors_path, notice: "Professor excluído com sucesso!"
end

private

def set_professor
  @professor = Professor.find(params[:id])
end

def professor_params
  params.require(:professor).permit(:nome, :email, :password, :cpf, :telefone, :escola_id, :tipo_professor, :formacao)
end
end