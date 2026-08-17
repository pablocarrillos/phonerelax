require "application_system_test_case"

# Cómo se ve la tienda en un móvil de verdad (Chrome headless a 390 px):
# estilos cargados, sin scroll horizontal, menú hamburguesa que abre y cierra,
# y las páginas clave usables. Cubre el fallo que dejó la web «sin CSS».
class MobileLayoutTest < ApplicationSystemTestCase
  PAGES = [ "/", "/pages/como-funciona", "/blogs/news", "/presupuesto", "/colegios", "/pages/contact", "/carrito",
            "/sv", "/sv/offert" ].freeze

  setup do
    @product = products(:funda) # con stock: el botón de compra se muestra
  end

  test "las páginas cargan con estilos y sin scroll horizontal en móvil" do
    (PAGES + [ "/products/#{@product.to_param}" ]).each do |path|
      visit path
      # Si el CSS no llegase, la cabecera no tendría fondo azul ni el botón hamburguesa se mostraría.
      assert_selector "header.site-header", visible: :all
      bg = page.evaluate_script("getComputedStyle(document.querySelector('header.site-header')).backgroundColor")
      assert_not_equal "rgba(0, 0, 0, 0)", bg, "#{path}: la cabecera no tiene estilos (¿CSS sin compilar?)"
      assert_selector "button.nav-toggle", visible: true
      assert_no_horizontal_overflow(path)
    end
  end

  test "el menú hamburguesa abre la navegación y navega" do
    visit "/"
    assert_no_selector "nav.site-nav a", visible: true, text: "Blog"
    find("button.nav-toggle").click
    assert_selector "nav.site-nav a", visible: true, text: "Blog"
    click_link "Blog"
    assert_current_path "/blogs/news"
    assert_selector "h1", text: "Blog"
  end

  test "la ficha de producto en móvil muestra el botón de compra y añade al carrito" do
    visit "/products/#{@product.to_param}"
    assert_selector "h1", text: @product.name
    click_button "Añadir al carrito"
    assert_current_path "/carrito"
    assert_text @product.name
    assert_no_horizontal_overflow
  end

  test "en escritorio la barra se ve entera y sin hamburguesa" do
    resize_to DESKTOP
    visit "/"
    assert_selector "nav.site-nav a", visible: true, text: "Blog"
    assert_no_selector "button.nav-toggle", visible: true
    assert_no_horizontal_overflow
  ensure
    resize_to MOBILE
  end
end
