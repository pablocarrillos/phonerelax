require "test_helper"

# Tests de sistema con Chrome headless. Por defecto en tamaño de MÓVIL
# (390×844, un iPhone normal): el sitio se usa sobre todo desde el teléfono y
# ahí es donde se han colado los problemas (assets sin compilar, 406…).
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  MOBILE = [ 390, 844 ].freeze
  DESKTOP = [ 1280, 900 ].freeze

  driven_by :selenium, using: :headless_chrome, screen_size: MOBILE do |options|
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--hide-scrollbars")
  end

  def resize_to(size)
    page.driver.browser.manage.window.resize_to(*size)
  end

  # Ancho real del documento frente al del viewport: si el primero es mayor,
  # algo se sale por la derecha y aparece scroll horizontal (el clásico
  # «se ve mal en el móvil»).
  def assert_no_horizontal_overflow(label = current_path)
    doc, view = page.evaluate_script("[document.documentElement.scrollWidth, document.documentElement.clientWidth]")
    assert doc <= view, "#{label}: el contenido (#{doc}px) es más ancho que la pantalla (#{view}px): scroll horizontal"
  end
end
