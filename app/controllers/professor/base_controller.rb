# app/controllers/professor/base_controller.rb
class Professor::BaseController < ApplicationController
  # Seus controllers de professor herdarão daqui.
  
  # Adicione a autenticação do Devise aqui, se ainda não estiver no ApplicationController
  before_action :authenticate_professor!
  
  # Opcional: Layout específico para o professor
  # layout 'professor_layout' 
end