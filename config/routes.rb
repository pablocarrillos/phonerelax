Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  root 'shop#home'
  get 'producto/:id', to: 'shop#product', as: :product_page

  get 'carrito', to: 'carts#show', as: :cart
  post 'carrito/anadir/:product_id', to: 'carts#add', as: :cart_add
  patch 'carrito/cantidad/:product_id', to: 'carts#update_quantity', as: :cart_update
  delete 'carrito/quitar/:product_id', to: 'carts#remove', as: :cart_remove

  get 'pedido/nuevo', to: 'orders#new', as: :new_order
  post 'pedido', to: 'orders#create', as: :orders
  get 'pedido/:number/pago-ok', to: 'orders#success', as: :order_success
  get 'pedido/:number/pago-cancelado', to: 'orders#cancel', as: :order_cancel
  get 'pedido/:number', to: 'orders#show', as: :order_status

  post 'stripe/webhook', to: 'stripe_webhooks#create'

  namespace :admin do
    root 'orders#index'
    resources :orders, only: [:index, :show] do
      patch :advance, on: :member # creado → enviado → recibido
    end
    resources :products, except: :show
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
end
