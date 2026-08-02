require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "display_name usa la traducción PT solo en portugués y cuando existe" do
    product = Product.new(name: "Funda", name_pt: "Bolsa")
    assert_equal "Funda", I18n.with_locale(:es) { product.display_name }
    assert_equal "Bolsa", I18n.with_locale(:pt) { product.display_name }
  end

  test "display_name cae al español cuando la traducción PT está vacía" do
    product = Product.new(name: "Funda", name_pt: nil)
    assert_equal "Funda", I18n.with_locale(:pt) { product.display_name }
    assert_equal "Funda", I18n.with_locale(:es) { product.display_name }
  end
end
