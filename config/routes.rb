Rails.application.routes.draw do
  resources :turmas do
    resources :alunos, only: [:index]
  end
  resources :alunos
  get 'escolas/index'
  get 'escolas/show'
  get 'escolas/new'
  get 'escolas/edit'

  devise_for :professors
  devise_for :coordenadors
  devise_for :admins
  devise_for :super_admins

  devise_scope :admin do
    get    "/login",  to: "devise/unified_sessions#new",    as: :new_user_session
    post   "/login",  to: "devise/unified_sessions#create", as: :user_session
    delete "/logout", to: "devise/unified_sessions#destroy", as: :destroy_user_session
    get    "/signup", to: "devise/unified_registrations#new", as: :new_user_registration
    post   "/signup", to: "devise/unified_registrations#create", as: :user_registration
  end

   resources :escolas

  root to: "home#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
