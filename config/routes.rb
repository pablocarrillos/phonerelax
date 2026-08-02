Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Rutas públicas bilingües: español sin prefijo, portugués bajo /pt
  # (el idioma por defecto no lleva prefijo; ver default_url_options).
  scope '(:locale)', locale: /pt|en/ do
    root 'shop#home'
    get 'producto/:id', to: 'shop#product', as: :product_page

    get 'como-funciona', to: 'pages#como_funciona', as: :como_funciona
    get 'quienes-somos', to: 'pages#quienes_somos', as: :quienes_somos
    get 'politica-privacidad', to: 'pages#privacidad', as: :privacidad
    get 'contacto', to: 'contacts#new', as: :contacto
    post 'contacto', to: 'contacts#create', as: :contact_messages

    get 'blog', to: 'blog#index', as: :blog
    get 'blog/:slug', to: 'blog#show', as: :blog_post

    get 'carrito', to: 'carts#show', as: :cart
    post 'carrito/anadir/:product_id', to: 'carts#add', as: :cart_add
    patch 'carrito/cantidad/:product_id', to: 'carts#update_quantity', as: :cart_update
    delete 'carrito/quitar/:product_id', to: 'carts#remove', as: :cart_remove

    get 'pedido/nuevo', to: 'orders#new', as: :new_order
    post 'pedido', to: 'orders#create', as: :orders
    get 'pedido/:number/pagar', to: 'orders#pay_page', as: :order_pay
    post 'pedido/:number/pagar', to: 'orders#pay', as: :order_payments
    get 'pedido/:number/pago-ok', to: 'orders#success', as: :order_success
    get 'pedido/:number/pago-cancelado', to: 'orders#cancel', as: :order_cancel
    get 'pedido/:number', to: 'orders#show', as: :order_status
  end

  post 'stripe/webhook', to: 'stripe_webhooks#create'

  namespace :admin do
    root 'orders#index'
    resources :orders, only: [:index, :show, :update] do
      patch :advance, on: :member # creado → enviado → recibido
      patch :revert, on: :member  # deshace un avance de estado
      post :mark_paid, on: :member # cobro manual (fuera de Stripe)
      post :payment_reminder, on: :member
      get :packing_slip, on: :member # albarán imprimible
    end
    resources :products, except: :show do
      resources :product_images, only: [:create, :destroy] do
        patch :move, on: :member
      end
    end
    resources :posts, except: :show
    resources :contact_messages, only: [:index, :destroy]
    resources :users, except: [:show]
  end

  get 'up' => 'rails/health#show', as: :rails_health_check

  # SEO: robots.txt y sitemap.xml dinámicos
  get '/robots.txt',  to: 'seo#robots'
  get '/sitemap.xml', to: 'seo#sitemap'
  get '/llms.txt',    to: 'seo#llms'
end
