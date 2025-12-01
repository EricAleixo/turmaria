Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Devise para diferentes tipos de usuários (sem rotas de registro/senha/sessão padrão)
  devise_for :admins, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :professors, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :coordenadors, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :super_admins, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :alunos, skip: [:registrations], controllers: { sessions: 'alunos/sessions' }

  # Dashboard principal
  get 'dashboard', to: 'dashboard#index'

  # Rotas explícitas para a Home (Correção para o erro No route matches [GET] "/home")
  get 'home', to: 'home#index' 
  
  # Página inicial (Rota raiz)
  root to: "home#index"

  # Estados e cidades
  resources :estados do
    member do
      get :confirm_delete
    end

    resources :cidades do
      member do
        get :confirm_delete
      end
    end
  end

  # Complete CRUD for administradores
  resources :administradores do
    collection do
      post :generate_presigned_url
      post :confirm_upload
    end
  end

  # Professor-Turma associations
  get '/professors/:professor_id/turmas', to: 'professor_turmas#show', as: 'professor_professor_turmas'
  post '/professors/:professor_id/turmas', to: 'professor_turmas#create'
  delete '/professors/:professor_id/turmas/:id', to: 'professor_turmas#destroy', as: 'professor_professor_turma'

  # Welcome route
  get 'escolas/welcome', to: 'escolas#welcome', as: 'welcome_escola'
  
  # Rotas autenticadas (admin ou super_admin)
  constraints lambda { |request| request.env['warden'].authenticated?(:admin) || request.env['warden'].authenticated?(:super_admin) } do
    
    # ROTAS DE ALUNOS
    resources :alunos do
      collection do
        get :cidades_por_estado
      end
    end

    resources :disciplinas do
      collection do
        get :buscar_escolas
      end
    end
    
    resources :professors do
      resources :alunos
      member do 
        patch :update_disciplinas
      end
    end

    resources :escolas do
      resources :disciplinas
      resources :ano_letivos do
        resources :turmas
      end

      resources :alunos do
        member do
          patch :assign_to_turma
          patch :remove_from_turma
        end
      end

      resources :turmas do
        resources :alunos, except: [:new, :create] do
          member do
            patch :remove_from_turma
          end
        end

        member do
          get :assign_students
          patch :assign_student
          patch 'remove_from_turma/:aluno_id', to: 'turmas#remove_from_turma', as: :remove_from_turma_individual
        end
      end
    end
  end

  # Rotas autenticadas (professor)
  constraints lambda { |request| request.env['warden'].authenticated?(:professor) } do
    get 'minhas_turmas', to: 'professor/turmas#index', as: 'minhas_turmas'
    get 'turmas/:turma_id/historico', to: 'professor/turmas#historico', as: 'historico_turma'

    # Frequências gerais
    resources :frequencias, controller: 'professor/frequencias' do
      member do
        patch :update_presencas
      end
    end

    # Estrutura aninhada de turmas -> disciplinas -> funcionalidades
    namespace :professor do
      # Turmas principais
      resources :turmas, only: [:index] do
        member do
          get :historico # /professor/turmas/:id/historico
        end

        # Disciplinas dentro da turma
        resources :disciplinas, only: [:index] do
          # Visualização de resultados
          resource :resultados, controller: 'notas/resultados', only: [:show] do
              member do
              get :detalhes
             end
          end

          # Frequências aninhadas
          resources :frequencias, controller: 'frequencias', only: [:new, :create, :index] do
            member do
              patch :update_presencas
            end
          end

          # Lançamento de notas
          namespace :notas do
            resources :avaliacoes, controller: 'avaliacoes' do
              collection do
                get :filter_by_bimestre
              end
              resources :registros, controller: 'registros', only: [:new, :create]
            end
          end
        end
      end

      # Outros recursos do namespace professor
      get 'alunos_geral', to: 'alunos#index', as: :alunos_gerais
      resources :alunos
      resources :disciplinas
    end
  end

  # Rota de Perfil
  resource :profile, only: [:show, :edit, :update], controller: 'profiles'

  # Rotas unificadas Devise (Login/Logout/Recuperação de Senha)
  devise_scope :professor do
    get    "/login",   to: "devise/unified_sessions#new",     as: :new_user_session
    post   "/login",   to: "devise/unified_sessions#create",  as: :user_session

    get    "/password/new", to: "devise/unified_passwords#new",    as: :new_user_password
    post   "/password",     to: "devise/unified_passwords#create", as: :user_password

    delete "/logout", to: "devise/unified_sessions#destroy", as: :destroy_user_session
  end
end