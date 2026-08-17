require "test_helper"

# Lo que no puede volver a pasar en móvil: que un navegador quede bloqueado
# con un 406 y que la página salga sin hoja de estilos.
class MobileBrowsersTest < ActionDispatch::IntegrationTest
  MOBILE_UAS = {
    "iPhone iOS 16 Safari" => "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1",
    "iPhone iOS 17.0" => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
    "Instagram in-app (iOS)" => "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 290.0.0.13.76",
    "Android Chrome 110" => "Mozilla/5.0 (Linux; Android 11; SM-A515F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.5481.154 Mobile Safari/537.36",
    "Samsung Internet" => "Mozilla/5.0 (Linux; Android 13; SAMSUNG SM-S911B) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/21.0 Chrome/110.0.5481.154 Mobile Safari/537.36",
    "Facebook in-app (Android)" => "Mozilla/5.0 (Linux; Android 12; SM-G991B Build/SP1A.210812.016; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/108.0.5359.128 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/400.0.0.30.109;]"
  }.freeze

  test "ningún navegador móvil recibe un 406 (allow_browser fuera)" do
    MOBILE_UAS.each do |name, ua|
      reset! # sesión nueva: que la cookie de idioma de la vuelta anterior no redirija
      get "/", headers: { "User-Agent" => ua, "Accept-Language" => "es-ES" }
      assert_response :success, "#{name} no puede ver la portada (#{response.status})"
      get "/sv", headers: { "User-Agent" => ua }
      assert_response :success, "#{name} no puede ver /sv (#{response.status})"
    end
  end

  test "la página enlaza su hoja de estilos y esta existe, y declara el viewport móvil" do
    get "/"
    assert_response :success
    assert_select "meta[name=viewport][content*='width=device-width']"
    # el menú móvil (hamburguesa) está en el HTML
    assert_select "button.nav-toggle[aria-controls=site-nav]"
    assert_select "nav#site-nav"
    css = css_select("link[rel=stylesheet]").map { |l| l["href"] }.grep(%r{^/assets/application-})
    assert css.any?, "la portada no enlaza /assets/application-*.css"
    get css.first
    assert_response :success, "la hoja de estilos #{css.first} no se sirve"
    assert_match(/site-header/, response.body, "el CSS servido no es el de la tienda")
  end
end
