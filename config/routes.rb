Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Devise para diferentes tipos de usuários (sem rotas de registro/senha/sessão padrão)
  devise_for :admins, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :professors, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :coordenadors, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :super_admins, skip: [:registrations, :passwords, :sessions], controllers: { confirmations: 'confirmations' }
  devise_for :alunos, skip: [:registrations, :sessions], controllers: { confirmations: 'confirmations' }

  get 'dashboard', to: 'dashboard#index'

  constraints lambda { |request| request.env['warden'].authenticated?(:aluno) } do
  scope :aluno, as: :aluno do
    get 'dashboard', to: 'aluno_dashboard#index', as: :aluno_dashboard
    get 'notas', to: 'dashboard#minhas_notas', as: :minhas_notas
    get 'frequencia', to: 'dashboard#minha_frequencia', as: :minha_frequencia
    get 'professores', to: 'dashboard#professores_da_turma', as: :meus_professores
    get 'atividades', to: 'aluno/contents#atividades', as: :minhas_atividades_e 
    get 'materiais', to: 'aluno/contents#materiais', as: :meus_materiais
    
    resources :conteudos, only: [:show], controller: 'aluno/contents'
    
    resources :boletins, only: [:index], controller: 'aluno/boletins' do
      collection do
        # Show: Exibe o boletim detalhado para o Ano Letivo específico
        # Helper: aluno_por_ano_boletins_path(ano_letivo_id: X)
        # URL: /aluno/boletins/show_por_ano/:id
        get 'show_por_ano/:id', to: 'aluno/boletins#show_por_ano', as: :por_ano
        
        # Enviar Email: Envia o boletim por email
        # Helper: enviar_email_aluno_boletins_path(ano_letivo_id: X)
        # URL: /aluno/boletins/enviar_email/:id
        post 'enviar_email/:id', to: 'aluno/boletins#enviar_email', as: :enviar_email
      end
    end
  end
end
  
  # Página inicial (Rota raiz)
  root to: "home#index"

  # Para criação admin (sem estado na URL)
  get '/admin/cidades/new', to: 'cidades#admin_new', as: 'admin_new_cidade'
  post '/admin/cidades', to: 'cidades#admin_create', as: 'admin_create_cidades'
  get '/admin/cidades/:id', to: 'cidades#admin_show', as: :admin_cidade
  get '/admin/cidades', to: 'cidades#admin_index', as: :admin_cidades


  # Ou se preferir dentro de um namespace admin:
  namespace :admin do
    get 'cidades/new', to: 'cidades#admin_new'
    post 'cidades', to: 'cidades#admin_create'
  end

  resources :cidades do
    collection do
      get :admin_new
    end
  end

  # Welcome route
  get 'escolas/welcome', to: 'escolas#welcome', as: 'welcome_escola'
  
  # Rotas autenticadas (admin ou super_admin)
  constraints lambda { |request| request.env['warden'].authenticated?(:admin) || request.env['warden'].authenticated?(:super_admin) } do
    
    get "/escolas/ano_letivos", to: "ano_letivos#selecionar_escola", as: :selecionar_escola_ano_letivo
    get "/escolas/alunos", to: "alunos#selecionar_escola", as: :selecionar_escola_alunos
    get "/escolas/disciplinas", to: "disciplinas#selecionar_escola", as: :selecionar_escola_disciplinas
    get "/escolas/professores", to: "professors#selecionar_escola", as: :selecionar_escola_professores
    get "/escolas/conteudos", to: "conteudos#selecionar_escola", as: :selecionar_escola_conteudos
    get "/escolas/frequencias", to: "admin_frequencia#selecionar_escola", as: :selecionar_escola_frequencias

    #Rota para minhas escolas(ADMINISTRADOR)
    get "/minhas_escolas", to: "administradores#minhas_escolas", as: :minhas_escolas_admin
    
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
    resources :conteudos, controller: 'admin_conteudos' do
      member do
        delete :remove_material
      end
    end
    resources :professors do
      resources :alunos
      resources :conteudos
      member do 
        patch :update_disciplinas
        patch :update_conteudos
      end
    end

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

    resources :administradores do
    collection do
      post :generate_presigned_url
      post :confirm_upload
    end
  end

    resources :escolas do
      collection do
        get :search
      end

      # FREQUÊNCIAS ANINHADAS EM ESCOLAS
      # URL: /escolas/:escola_id/frequencias
      # Helper: escola_frequencias_path(@escola)
      resources :frequencias, controller: 'admin_frequencia'

      resources :conteudos, controller: 'admin_conteudos'
      resources :disciplinas

      resources :professors do
        resources :alunos
        resources :conteudos

        member do
          patch :update_disciplinas
          patch :update_conteudos
        end

        resources :turmas,
                  controller: 'professor_turmas',
                  only: [:index, :create, :destroy]
      end


      resources :ano_letivos do
        resources :turmas
      end

      resources :alunos do
        member do
          patch :assign_to_turma
          patch :remove_from_turma
          patch :regenerate_matricula 
        end
      end

      resources :turmas do
        resources :disciplinas, controller: 'turma_disciplinas' do
          collection do
            get :associar
            post :associar, action: :processar_associacao
          end
        end

        resources :alunos, except: [:new, :create] do
          member do
            patch :remove_from_turma
          end
        end

        member do
          get :assign_students
          patch :assign_students
          patch :assign_student
          patch :remove_students
          
          patch 'remove_from_turma/:student_id',
                to: 'turmas#remove_from_turma',
                as: :remove_from_turma_individual

          get :assign_professors
          patch :assign_professor
          patch :remove_professor_from_turma
        end
      end
    end

  end

  # Rotas autenticadas (professor)
  constraints lambda { |request| request.env['warden'].authenticated?(:professor) } do
    get 'turmas/:turma_id/historico', to: 'professor/turmas#historico', as: 'historico_turma'

    namespace :professor do
      get "selecionar_turma", to: "conteudos#selecionar_turma"

      namespace :notas do
      get 'selecionar_disciplina',
          to: 'resultados#selecionar_disciplina',
          as: :selecionar_disciplina
    end

      scope :turmas do
        resources :frequencias, only: [:index]
      end

      # Turmas principais
      resources :turmas, only: [:index] do
        member do
          get :historico
        end

        # ============================
        # ✅ ALUNOS ANINHADOS (CORRETO)
        # ============================
        resources :alunos, only: [:index, :show]

        # Frequências
        resources :frequencias, except: [:index] do
          member do
            patch :update_presencas
          end
        end

        # Conteúdos
        resources :conteudos, only: [:index, :show, :new, :create, :edit, :update, :destroy]

        # Disciplinas
        resources :disciplinas, only: [:index] do
          resource :resultados,
                  controller: 'notas/resultados',
                  only: [:show] do
            member do
              get :detalhes
            end
          end

          namespace :notas do
            resources :avaliacoes do
              collection do
                get :filter_by_bimestre
              end
              resources :registros, only: [:new, :create]
            end
          end
        end
      end

      # Outras rotas do professor
      get 'minhas_disciplinas/:disciplina_id/todos_alunos',
          to: 'notas/resultados#todos_alunos',
          as: :disciplina_todos_alunos

      get 'alunos_geral', to: 'alunos#index', as: :alunos_gerais

      # ⚠️ Mantido para INDEX GLOBAL (sidebar)
      resources :alunos, only: [:index]

      resources :disciplinas
      resources :conteudos, as: :painel_conteudos
    end
  end


  # Rota de Perfil
  resource :profile, only: [:show, :edit, :update], controller: 'profiles'

  devise_for :alunos, path: 'aluno'
  # Rotas unificadas Devise
  devise_scope :user do
    get    "/login",  to: "devise/unified_sessions#new",    as: :new_user_session
    post   "/login",  to: "devise/unified_sessions#create", as: :user_session

    get    "/password/new", to: "devise/unified_passwords#new",    as: :new_user_password
    post   "/password",     to: "devise/unified_passwords#create", as: :user_password

    delete "/logout", to: "devise/unified_sessions#destroy", as: :destroy_user_session
  end
end