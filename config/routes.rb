Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Comprobación en vivo de un NIF-IVA europeo contra VIES (JSON, desde el checkout).
  get "comprobar-vies", to: "vies#check", as: :vies_check

  # Rutas públicas bilingües: español sin prefijo, portugués bajo /pt
  # (el idioma por defecto no lleva prefijo; ver default_url_options).
  scope "(:locale)", locale: /pt|en|fr/ do
    root "shop#home"
    # URLs canónicas con la misma estructura que la tienda Shopify anterior
    # (/products, /pages/..., /blogs/news) para no perder SEO al migrar.
    get "products/:id", to: "shop#product", as: :product_page
    # Precio y desglose de un pack para una cantidad dada (JSON, recálculo en vivo).
    get "products/:id/pack-precio", to: "shop#pack_price", as: :pack_price

    get "pages/como-funciona", to: "pages#como_funciona", as: :como_funciona
    # «Quiénes somos» se fusionó con Contacto; redirección para enlaces antiguos
    get "pages/quienes-somos", to: redirect { |p, _req| p[:locale] ? "/#{p[:locale]}/pages/contact" : "/pages/contact" }
    get "politica-privacidad", to: "pages#privacidad", as: :privacidad
    get "pages/contact", to: "contacts#new", as: :contacto
    post "pages/contact", to: "contacts#create", as: :contact_messages

    # Presupuesto para pedidos grandes (colegios, empresas, eventos)
    get "presupuesto", to: "quotes#new", as: :quote
    post "presupuesto", to: "quotes#create", as: :quotes

    # Landings por sector
    get "colegios",    to: "sectors#show", defaults: { sector: "colegios" },    as: :sector_colegios
    get "eventos",     to: "sectors#show", defaults: { sector: "eventos" },     as: :sector_eventos
    get "empresas",    to: "sectors#show", defaults: { sector: "empresas" },    as: :sector_empresas
    get "oposiciones", to: "sectors#show", defaults: { sector: "oposiciones" }, as: :sector_oposiciones

    get "blogs/news", to: "blog#index", as: :blog
    get "blogs/news/:slug", to: "blog#show", as: :blog_post

    get "carrito", to: "carts#show", as: :cart
    post "carrito/anadir/:product_id", to: "carts#add", as: :cart_add
    patch "carrito/cantidad/:product_id", to: "carts#update_quantity", as: :cart_update
    delete "carrito/quitar/:product_id", to: "carts#remove", as: :cart_remove

    get "pedido/nuevo", to: "orders#new", as: :new_order
    post "pedido", to: "orders#create", as: :orders
    get "pedido/:number/pagar", to: "orders#pay_page", as: :order_pay
    post "pedido/:number/pagar", to: "orders#pay", as: :order_payments
    get "pedido/:number/pago-ok", to: "orders#success", as: :order_success
    get "pedido/:number/pago-cancelado", to: "orders#cancel", as: :order_cancel
    get "pedido/:number", to: "orders#show", as: :order_status
  end

  # Redirecciones 301 de las URLs de la preview (español) a las canónicas Shopify.
  get "producto/:id",           to: redirect("/products/%{id}")
  get "como-funciona",          to: redirect("/pages/como-funciona")
  get "quienes-somos",          to: redirect("/pages/contact")
  get "contacto",               to: redirect("/pages/contact")
  get "blog",                   to: redirect("/blogs/news")
  get "blog/:slug",             to: redirect("/blogs/news/%{slug}")
  get "collections/frontpage",  to: redirect("/")

  post "stripe/webhook", to: "stripe_webhooks#create"

  namespace :admin do
    root "orders#index"
    resources :orders, only: [ :index, :show, :update, :destroy ] do
      patch :advance, on: :member # creado → enviado → recibido
      patch :revert, on: :member  # deshace un avance de estado
      post :mark_paid, on: :member # cobro manual (fuera de Stripe)
      post :refund, on: :member # reembolso total o parcial
      post :payment_reminder, on: :member
      get :packing_slip, on: :member # albarán imprimible
    end
    resources :products, except: :show do
      patch :reorder, on: :collection # nuevo orden de ids tras arrastrar en la lista
      resources :product_images, only: [ :create, :destroy ] do
        patch :move, on: :member
      end
    end
    resources :posts, except: :show
    resources :users, except: [ :show ]
    get "estadisticas", to: "stats#show", as: :stats
    get "transporte", to: "shipping#show", as: :shipping
    patch "transporte", to: "shipping#update"
    resources :clients, except: :show
    resources :samples, except: :show do
      patch :mark_returned, on: :member # recogida/devuelta hoy
    end
    resources :quotes do
      get :print, on: :member # versión imprimible (PDF con el diálogo del navegador)
      post :duplicate, on: :member # nuevo presupuesto partiendo de este
    end
    resources :suppliers, except: :show
    resources :purchases do
      patch :receive, on: :member   # marca recibida y suma stock
      patch :unreceive, on: :member # deshace la recepción
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # SEO: robots.txt y sitemap.xml dinámicos
  get "/robots.txt",  to: "seo#robots"
  get "/sitemap.xml", to: "seo#sitemap"
  get "/llms.txt",    to: "seo#llms"
end
