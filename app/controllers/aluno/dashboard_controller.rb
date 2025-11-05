# app/controllers/aluno/dashboard_controller.rb
class Aluno::DashboardController < ApplicationController
  # Esta linha garante que só alunos logados possam acessar este dashboard
  # Certifique-se de que o Devise está configurado para o modelo Aluno.
  before_action :authenticate_aluno! 
  
  # Layout: Se você usa um layout específico para o portal, defina-o aqui.
  # layout 'aluno_layout' # Exemplo
  
  def index
    # current_aluno é o helper do Devise que retorna o objeto Aluno logado
    @aluno = current_aluno
    
    # Exemplo simples de dados para exibir na tela
    @turma = @aluno.turmas.last # Assume que o aluno pertence a pelo menos uma turma.
                                # Ajuste conforme a sua modelagem (ex: current_turma).

    @titulo_pagina = "Dashboard | #{@aluno.nome}"
  end
end