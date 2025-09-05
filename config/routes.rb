Rails.application.routes.draw do
  devise_for :professors
  devise_for :admins
  devise_for :super_admins

  devise_scope :admin do
    get    "/login",  to: "devise/unified_sessions#new",    as: :new_user_session
    post   "/login",  to: "devise/unified_sessions#create", as: :user_session
    delete "/logout", to: "devise/unified_sessions#destroy", as: :destroy_user_session
    get    "/signup", to: "devise/unified_registrations#new", as: :new_user_registration
    post   "/signup", to: "devise/unified_registrations#create", as: :user_registration
  end

  resources :escolas do
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
        patch 'remove_from_turma/:aluno_id', to: 'turmas#remove_from_turma', as: :remove_from_turma
      end
    end
  end

  root to: "home#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
