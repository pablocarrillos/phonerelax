require "test_helper"

# Idioma por defecto del visitante: el del navegador si lo tenemos, inglés si
# no; el prefijo de la URL y el selector (?hl=) mandan y quedan en cookie.
class LocaleDetectionTest < ActionDispatch::IntegrationTest
  test "un navegador en francés entra en español y se le lleva a /fr, y se recuerda" do
    get "/", headers: { "Accept-Language" => "fr-FR,fr;q=0.9,en;q=0.5" }
    assert_redirected_to "/fr"
    assert_equal "fr", cookies["locale"]

    # segunda visita: manda la cookie aunque el navegador ya no diga nada
    get "/"
    assert_redirected_to "/fr"
    # y se conserva la página y la query
    get "/pages/como-funciona?x=1"
    assert_redirected_to "/fr/pages/comment-ca-marche?x=1"
  end

  test "un idioma que no tenemos lleva al inglés" do
    get "/", headers: { "Accept-Language" => "ja-JP,ja;q=0.9" }
    assert_redirected_to "/en"
    assert_equal "en", cookies["locale"]
  end

  test "español, sin cabecera o robots: se queda en español y sin cookie" do
    get "/", headers: { "Accept-Language" => "es-ES,es;q=0.9,en;q=0.5" }
    assert_response :success
    assert_equal "es", cookies["locale"]

    reset!
    get "/"
    assert_response :success
    assert_nil cookies["locale"]

    get "/", headers: { "Accept-Language" => "fr-FR", "User-Agent" => "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" }
    assert_response :success
    assert_nil cookies["locale"]
  end

  test "la cabecera elige el primer idioma que tengamos por peso" do
    get "/", headers: { "Accept-Language" => "nl-NL,nl;q=0.9,de;q=0.8,en;q=0.7" }
    assert_redirected_to "/de"
  end

  test "visitar una URL con prefijo fija ese idioma, y el selector permite volver al español" do
    get "/fr/panier"
    assert_response :success
    assert_equal "fr", cookies["locale"]
    get "/"
    assert_redirected_to "/fr"

    # el enlace «Español» del selector lleva ?hl=es: fija la cookie y no vuelve a redirigir
    get "/?hl=es"
    assert_redirected_to "/"
    assert_equal "es", cookies["locale"]
    get "/"
    assert_response :success

    # y desde español, elegir sueco lleva a la página en sueco
    get "/carrito?hl=sv"
    assert_redirected_to "/sv/varukorg"
    assert_equal "sv", cookies["locale"]
  end

  test "las páginas no localizadas y el admin no se tocan" do
    get "/aviso-legal", headers: { "Accept-Language" => "fr-FR" }
    assert_response :success
    get "/session/new", headers: { "Accept-Language" => "fr-FR" }
    assert_response :success
  end

  test "el selector de idioma enlaza con hl y respeta las alternativas hreflang limpias" do
    get "/fr"
    assert_response :success
    assert_select "a.lang-option[href=?]", "/?hl=es"
    assert_select "a.lang-option[href=?]", "/sv?hl=sv"
    assert_select "link[hreflang=es][href=?]", "https://phonerelax.com/"
  end
end
