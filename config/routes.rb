# frozen_string_literal: true

Rails.application.routes.draw do
  # The mobile app does NOT use Doorkeeper's standard OAuth endpoints.
  # Tokens are issued by our custom controllers under /api/mobile/v1/auth/*
  # (see Api::Mobile::V1::AuthController + MobileAuth::TokenIssuer).
  # We intentionally do NOT mount /oauth/authorize, /oauth/applications, etc.
  # If we adopt Authorization Code + PKCE in the future, mount only `:authorizations`
  # and `:tokens` here.
  use_doorkeeper do
    skip_controllers :all
  end

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
    namespace :public do
      namespace :v1 do
        get "bill_rooms/:share_token", to: "bill_rooms#show"
        post "bill_rooms/:share_token/join", to: "bill_rooms#join"
        patch "bill_rooms/:share_token/guest", to: "guest_sessions#update"
        delete "bill_rooms/:share_token/guest", to: "guest_sessions#destroy"
        post "bill_rooms/:share_token/items/:receipt_item_id/claim", to: "item_claims#create"
        delete "bill_rooms/:share_token/items/:receipt_item_id/claim", to: "item_claims#destroy"
      end
    end

    namespace :mobile do
      namespace :v1 do
        get "health", to: "health#show"
        scope :auth, controller: "auth" do
          post "login", action: :login
          post "logout", action: :logout
          get "me", action: :me
          post "refresh", action: :refresh
        end
        resources :bills, only: %i[index show create] do
          member do
            get :summary
            get :room
            post :confirm
            post :finalize
            post :split_all_equally, to: "bill_assignments#split_all_equally"
            post :split_unassigned_equally, to: "bill_assignments#split_unassigned_equally"
            delete :assignments, to: "bill_assignments#clear"
          end
          resources :participants, only: %i[create], controller: "bill_participants"
          resources :receipts, only: %i[create], controller: "receipts"
          resources :receipt_items, only: %i[create], controller: "receipt_items"
          resources :receipt_images, only: %i[create], controller: "receipt_images"
        end
        resources :bill_participants, only: %i[update destroy], controller: "bill_participants"
        resources :receipt_items, only: %i[update destroy], controller: "receipt_items" do
          resource :assignments, only: %i[update destroy], controller: "item_assignments"
        end
        resources :receipts, only: %i[show] do
          member do
            post :confirm
          end
          resources :adjustments, only: %i[create], controller: "receipt_adjustments"
        end
        resources :receipt_adjustments, only: %i[update destroy], controller: "receipt_adjustments"
      end
    end
  end
end
