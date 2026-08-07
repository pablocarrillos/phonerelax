require "test_helper"

# Páginas legales (aviso legal y cookies, solo en castellano) y footer.
class LegalPagesTest < ActionDispatch::IntegrationTest
  test "aviso legal con los datos de Drop Point Systems" do
    get aviso_legal_path
    assert_response :success
    assert_includes response.body, "DROP POINT SYSTEMS S.L.U."
    assert_includes response.body, "B02631976"
    assert_includes response.body, "C/ Carrasqueta, 14"
  end

  test "política de cookies: solo técnicas y referencia a Stripe" do
    get politica_cookies_path
    assert_response :success
    assert_includes response.body, "_phonerelax_session"
    assert_includes response.body, "Stripe"
    assert_includes response.body, "22.2 LSSI-CE"
  end

  test "el footer enlaza los tres legales y lleva el copyright con el año en curso" do
    get root_path
    assert_select "footer a[href=?]", "/aviso-legal", text: "Aviso legal"
    assert_select "footer a[href=?]", "/politica-privacidad"
    assert_select "footer a[href=?]", "/politica-de-cookies", text: "Política de cookies"
    assert_includes response.body, "© #{Date.current.year} Drop Point Systems S.L. — Todos los derechos reservados."

    # En otros idiomas los textos de los enlaces van traducidos, con el mismo
    # contenido en castellano como destino.
    get "/de"
    assert_select "footer a[href=?]", "/aviso-legal", text: "Impressum"
    assert_select "footer a[href=?]", "/politica-de-cookies", text: "Cookie-Richtlinie"
    get "/fr"
    assert_select "footer a[href=?]", "/aviso-legal", text: "Mentions légales"
  end
end
