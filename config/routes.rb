Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"
  get "features", to: "pages#features"

  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resource :settings, only: %i[show update]

  get "dashboard", to: "dashboard#show"

  resources :products, except: [ :edit ] do
    member do
      post :refresh
    end
  end

  resources :product_groups, path: "compare", except: [ :edit, :update ] do
    resources :memberships, only: %i[create destroy], controller: "product_group_memberships"
  end

  namespace :admin do
    root to: "dashboard#show"
  end

  namespace :api do
    namespace :v1 do
      resources :products, only: %i[index show create update destroy] do
        member do
          post :refresh
        end
        resources :history, only: :index, controller: "product_history"
      end
    end
  end

  get "health", to: "rails/health#show", as: :health_check
end
