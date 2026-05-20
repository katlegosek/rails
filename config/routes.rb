# frozen_string_literal: true

Rails.application.routes.draw do
  use_doorkeeper
  devise_for :users, controllers: { registrations: "registrations" }
  devise_scope :user do
    get "users/confirm", to: "registrations#confirm", as: :confirm_registration
  end


  if Rails.env.development?
    mount Lookbook::Engine, at: "/lookbook"
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  get "up" => "rails/health#show", as: :rails_health_check
  root "dashboards#index"

  resources :users do
    member do
      patch :lock
      patch :unlock
    end
    collection do
      get :turbo_modal
    end
  end

  resources :inbox_messages
  resources :notifications

  concern :deletable do
    member do
      patch :archive
      patch :restore
    end
  end

  namespace :api do
    namespace :mobile do
      namespace :v1 do
        get "health", to: "health#show"
        resources :bills, only: %i[index show]
      end
    end
  end
end
