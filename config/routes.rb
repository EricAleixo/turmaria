Rails.application.routes.draw do

  devise_for :admins, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :professors, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :coordenadors, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :super_admins, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }

  # Dashboard route (will use DashboardController with Pundit authorization)
  get 'dashboard', to: 'dashboard#index'

  # Complete CRUD for administradores
  resources :administradores

  # Welcome route for escola onboarding
  get 'escolas/welcome', to: 'escolas#welcome', as: 'welcome_escola'

  # Authenticated routes for all user types (authorization handled by Pundit)
  constraints lambda { |request| request.env['warden'].authenticated?(:admin) || request.env['warden'].authenticated?(:super_admin) } do
    resources :alunos
    resources :escolas do
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

  devise_scope :professor do
    get    "/login",  to: "devise/unified_sessions#new",    as: :new_user_session
    post   "/login",  to: "devise/unified_sessions#create", as: :user_session
    
    get    "/password/new", to: "devise/unified_passwords#new",  as: :new_user_password
    post   "/password",    to: "devise/unified_passwords#create", as: :user_password

    get    "/password/new", to: "devise/unified_passwords#edit",  as: :new_edit_user_password
    post   "/password",    to: "devise/unified_passwords#update", as: :reset_user_password


     delete "/logout", to: "devise/unified_sessions#destroy", as: :destroy_user_session

  end

  root to: "home#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
