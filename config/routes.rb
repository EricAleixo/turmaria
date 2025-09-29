Rails.application.routes.draw do
  # Devise para os diferentes tipos de usuários, com skips e controllers customizados
  devise_for :admins, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :professors, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :coordenadors, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :super_admins, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }

  # Dashboard route
  get 'dashboard', to: 'dashboard#index'

  # Estados com CRUD completo e cidades aninhadas com CRUD completo
  resources :estados do
    member do
      get :confirm_delete
    end

    # Aqui habilito TODAS as ações para cidades (index, new, create, edit, update, show, destroy)
    resources :cidades
  end

  # CRUD completo para administradores
  resources :administradores

  # Rota de boas-vindas para escolas (escola onboarding)
  get 'escolas/welcome', to: 'escolas#welcome', as: 'welcome_escola'

  # Rotas autenticadas para diferentes tipos de usuários, controladas pelo Pundit
  constraints lambda { |request| request.env['warden'].authenticated?(:admin) || request.env['warden'].authenticated?(:super_admin) } do
    resources :alunos

    resources :escolas do
      resources :ano_letivos do
        resources :turmas
      end

      # Alunos diretamente em escola (não alocados a turma)
      resources :alunos do
        member do
          patch :assign_to_turma
          patch :remove_from_turma
        end
      end

      resources :turmas do
        # Alunos alocados a turma
        resources :alunos, except: [:new, :create] do
          member do
            patch :remove_from_turma
          end
        end

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

  # Devise scope para professor (rotas de login/logout/password)
  devise_scope :professor do
    get    "/login",  to: "devise/unified_sessions#new",    as: :new_user_session
    post   "/login",  to: "devise/unified_sessions#create", as: :user_session

    get    "/password/new", to: "devise/unified_passwords#new",  as: :new_user_password
    post   "/password",    to: "devise/unified_passwords#create", as: :user_password

    get    "/password/new", to: "devise/unified_passwords#edit",  as: :new_edit_user_password
    post   "/password",    to: "devise/unified_passwords#update", as: :reset_user_password

    delete "/logout", to: "devise/unified_sessions#destroy", as: :destroy_user_session
  end

  # Root da aplicação
  root to: "home#index"

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
end
