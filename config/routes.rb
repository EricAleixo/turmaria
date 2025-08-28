Rails.application.routes.draw do
<<<<<<< HEAD
  root"home#index"
=======
  devise_for :professors
  devise_for :coordenadors
  devise_for :admins
  devise_for :super_admins
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root to: "home#index"
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
>>>>>>> 959cb920778fc49f6e4928a5c9471e8aee30e9b1
end
