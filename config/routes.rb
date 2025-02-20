Rails.application.routes.draw do
  root "translations#new"
  resources :translations, only: [ :new, :create ]
  get "translations", to: "translations#new"

  get "login", to: "sessions#login", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  get "signup", to: "users#signin", as: :signup
  post "signup", to: "users#create"

get "profile", to: "users#edit", as: :profile
patch "profile", to: "users#update"
  delete "profile", to: "users#destroy", as: :delete_account

  patch "profile/update_username", to: "users#update_username", as: :update_username_profile
  patch "profile/update_password", to: "users#update_password", as: :update_password_profile

  post "save_word", to: "words#save", as: :save_word
  get "saved_words", to: "words#wordlist", as: :saved_words
delete "saved_words/:id", to: "words#destroy", as: :delete_saved_word

  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "s/:token", to: "words#shared", as: :shared_word
end
