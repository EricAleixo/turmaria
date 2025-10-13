# config/routes.rb
Rails.application.routes.draw do

  devise_for :admins, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :professors, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :coordenadors, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :super_admins, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :alunos, skip:[:registrations] , controllers: { sessions: 'alunos/sessions' }

  # Dashboard route (will use DashboardController with Pundit authorization)
  get 'dashboard', to: 'dashboard#index'

  resources :estados

  # Complete CRUD for administradores
  resources :administradores

  # Professor-Turma associations - MANUAL ROUTES
  get '/professors/:professor_id/turmas', to: 'professor_turmas#show', as: 'professor_professor_turmas'
  post '/professors/:professor_id/turmas', to: 'professor_turmas#create'
  delete '/professors/:professor_id/turmas/:id', to: 'professor_turmas#destroy', as: 'professor_professor_turma'

  # Welcome route for escola onboarding
  get 'escolas/welcome', to: 'escolas#welcome', as: 'welcome_escola'
  
  # Authenticated routes for all user types (authorization handled by Pundit)
  constraints lambda { |request| request.env['warden'].authenticated?(:admin) || request.env['warden'].authenticated?(:super_admin) } do
    resources :alunos
    resources :disciplinas
    resources :professors do
      resources :alunos
    end
    resources :escolas do
      resources :disciplinas
      resources :ano_letivos do
        resources :turmas
      end
      # Alunos directly under escola (not allocated to any turma)
      resources :alunos do
        member do
          patch :assign_to_turma
          patch :remove_from_turma
        end
      end
      
      resources :turmas do
        # Alunos allocated to specific turma
        resources :alunos, except: [:new, :create] do
          member do
            patch :remove_from_turma
          end
        end
        
        # Action to assign existing students to this turma
        member do
          get :assign_students
          patch :assign_student
          patch :assign_students
          patch :remove_from_turma
          patch 'remove_from_turma/:aluno_id', to: 'turmas#remove_from_turma', as: :remove_from_turma_individual
        end
      end
    end
  end

  # =========================================================================
  # BLOCO DE ROTAS DO PROFESSOR (Implementação do novo fluxo Turma -> Disciplina -> Notas)
  # =========================================================================
  constraints lambda { |request| request.env['warden'].authenticated?(:professor) } do
    
    get 'minhas_turmas', to: 'professor/turmas#index', as: 'minhas_turmas'
    
    namespace :professor do
      
      # ROTAS PRINCIPAIS ANINHADAS: Turmas -> Disciplinas -> Funcionalidades
      resources :turmas, only: [:index] do
        
        member do
          get :historico # Rota 'historico_turma'
        end
        
        # O professor vê as disciplinas que leciona nessa turma (Passo 2)
        resources :disciplinas, only: [:index] do 
            
          # 1. Visualização da Média Final/Resultados (Passo 3)
          # resource singular para resultados, usa :turma_id e :disciplina_id
          resource :resultados, controller: 'notas/resultados', only: [:show] # Usamos :show pois é uma visualização única
          
          # 2. Rotas de Frequência (Aninhadas corretamente)
          resources :frequencias, controller: 'frequencias', only: [:new, :create, :index] do
            member do
              patch :update_presencas
            end
          end
          
          # 3. Aninhamento para Configuração/Lançamento de Notas (Dentro da Disciplina)
          namespace :notas do
            resources :avaliacoes, controller: 'avaliacoes' do
              resources :registros, controller: 'registros', only: [:new, :create] 
            end
          end
        end
      end
      
      # Rotas de Alunos
      get 'alunos_geral', to: 'alunos#index', as: :alunos_gerais 
      resources :alunos 
    end
  end
  # =========================================================================

  devise_scope :professor do
    # ROTAS DE AUTENTICAÇÃO (MANTIDAS)
    get "/login", to: "devise/unified_sessions#new", as: :new_user_session
    post "/login", to: "devise/unified_sessions#create", as: :user_session
    
    get "/password/new", to: "devise/unified_passwords#new", as: :new_user_password
    post "/password", to: "devise/unified_passwords#create", as: :user_password

    get "/password/new", to: "devise/unified_passwords#edit", as: :new_edit_user_password
    post "/password", to: "devise/unified_passwords#update", as: :reset_user_password

    delete "/logout", to: "devise/unified_sessions#destroy", as: :destroy_user_session
  end

  root to: "home#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
