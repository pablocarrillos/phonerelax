Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Comprobación en vivo de un NIF-IVA europeo contra VIES (JSON, desde el checkout).
  get "comprobar-vies", to: "vies#check", as: :vies_check

  # Rutas públicas multilingües CON los segmentos traducidos por idioma
  # (route_translator): el español va sin prefijo (/carrito) y el resto con
  # prefijo y ruta en su idioma (/fr/panier, /en/cart, /pt/carrinho). Las
  # traducciones de cada segmento viven en la clave routes: de cada locale.
  localized do
    root "shop#home"
    # URLs canónicas con la misma estructura que la tienda Shopify anterior
    # (/products, /pages/..., /blogs/news) para no perder SEO al migrar; esos
    # segmentos no se traducen a propósito.
    get "products/:id", to: "shop#product", as: :product_page
    # Precio y desglose de un pack para una cantidad dada (JSON, recálculo en vivo).
    get "products/:id/pack-precio", to: "shop#pack_price", as: :pack_price

    get "pages/como-funciona", to: "pages#como_funciona", as: :como_funciona
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

  # Páginas legales, solo en castellano (los textos de sus enlaces del footer
  # sí se traducen): misma URL para todos los idiomas.
  get "aviso-legal", to: "pages#aviso_legal", as: :aviso_legal
  get "politica-de-cookies", to: "pages#politica_cookies", as: :politica_cookies

  # «Quiénes somos» se fusionó con Contacto; redirección para enlaces antiguos.
  scope "(:locale)", locale: /pt|en|fr|de|sv/ do
    get "pages/quienes-somos", to: redirect { |p, _req| p[:locale] ? "/#{p[:locale]}/pages/contact" : "/pages/contact" }
  end

  # Redirecciones 301 de las URLs de la preview (español) a las canónicas
  # Shopify. OJO: con nombre legacy_* explícito; sin él, Rails les genera
  # helpers (blog_path, contacto_path…) que pisan los helpers multilingües
  # de route_translator y los enlaces de la barra pierden el idioma.
  get "producto/:id",           to: redirect("/products/%{id}"),        as: :legacy_producto
  get "como-funciona",          to: redirect("/pages/como-funciona"),   as: :legacy_como_funciona
  get "quienes-somos",          to: redirect("/pages/contact"),         as: :legacy_quienes_somos
  get "contacto",               to: redirect("/pages/contact"),         as: :legacy_contacto
  get "blog",                   to: redirect("/blogs/news"),            as: :legacy_blog
  get "blog/:slug",             to: redirect("/blogs/news/%{slug}"),    as: :legacy_blog_post
  get "collections/frontpage",  to: redirect("/"),                      as: :legacy_frontpage

  post "stripe/webhook", to: "stripe_webhooks#create"

  namespace :admin do
    root "orders#index"
    resources :accounting, only: [ :index ] do
      collection do
        get :preview
        post :generate
        post :send_email
        post :generate_and_send_all
        post :resubmit_verifactu
      end
    end
    resource :company_setting, only: [ :show, :update ]
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
    resources :clients, except: :show do
      get :search, on: :collection # autocompletado de cliente en presupuestos (JSON)
    end
    resources :samples, except: :show do
      patch :mark_returned, on: :member # recogida/devuelta hoy
      patch :toggle_sold, on: :member   # marca/desmarca que hubo venta
    end
    resources :quotes do
      get :print, on: :member # versión imprimible (PDF con el diálogo del navegador)
      post :duplicate, on: :member # nuevo presupuesto partiendo de este
      patch :set_status, on: :member # marcar aprobado / en pausa / perdido / abierto
      patch :set_payment, on: :member # marcar el cobro (para confirmar / total)
      patch :upload_files, on: :member # subir logo, fichero DTF o presupuesto firmado
      delete :purge_file, on: :member # borrar uno de esos ficheros
      # comentarios del seguimiento, con fecha/hora y usuario
      resources :comments, controller: "quote_comments", only: [ :create, :destroy ], path: "comentarios"
    end
    resources :photos, only: [ :index, :create, :update, :destroy ] do
      patch :project_comment, on: :collection # comentario de una imagen estática
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
