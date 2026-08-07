require "test_helper"

# Los enlaces de la barra deben conservar el idioma de la página: las
# redirecciones antiguas (/blog, /contacto…) no pueden pisar los helpers
# multilingües de route_translator (por eso llevan nombre legacy_*).
class LocalizedNavTest < ActionDispatch::IntegrationTest
  test "la barra enlaza cada sección en el idioma de la página" do
    get "/pt"
    assert_select "nav a[href=?]", "/pt/blogs/news"
    assert_select "nav a[href=?]", "/pt/pages/como-funciona"
    assert_select "nav a[href=?]", "/pt/pages/contact"

    get "/de"
    assert_select "nav a[href=?]", "/de/blogs/news"
    assert_select "nav a[href=?]", "/de/pages/wie-es-funktioniert"

    get "/"
    assert_select "nav a[href=?]", "/blogs/news"
    assert_select "nav a[href=?]", "/pages/como-funciona"
  end

  test "las redirecciones antiguas del preview siguen funcionando" do
    get "/blog"
    assert_redirected_to "/blogs/news"
    get "/contacto"
    assert_redirected_to "/pages/contact"
    get "/como-funciona"
    assert_redirected_to "/pages/como-funciona"
  end
end
