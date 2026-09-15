require "test_helper"

# La sección «Accesorios» de la ficha muestra los productos accesorio ligados.
class ProductAccessoriesTest < ActionDispatch::IntegrationTest
  setup do
    @owner = Product.create!(name: "Imán", price: 12.10, vat_percentage: 21, active: true, stock: 5)
    @acc = Product.create!(name: "Caja del imán", price: 58.08, vat_percentage: 21, active: true, stock: 5)
  end

  test "sin accesorios la ficha no muestra la sección" do
    get product_page_path(@owner)
    assert_response :success
    assert_select "section.product-accessories", 0
  end

  test "con un accesorio activo la ficha lo muestra en «Accesorios»" do
    @owner.product_accessories.create!(accessory: @acc, position: 1)

    get product_page_path(@owner)
    assert_response :success
    assert_select "section.product-accessories h2", text: "Accesorios"
    assert_select "section.product-accessories", text: /Caja del imán/
    assert_select "section.product-accessories a[href=?]", product_page_path(@acc)
  end

  test "un accesorio inactivo no se muestra" do
    @acc.update!(active: false)
    @owner.product_accessories.create!(accessory: @acc, position: 1)

    get product_page_path(@owner)
    assert_select "section.product-accessories", 0
  end

  test "no se puede duplicar un accesorio ni ligar el producto consigo mismo" do
    @owner.product_accessories.create!(accessory: @acc)
    assert_not @owner.product_accessories.build(accessory: @acc).valid?, "no debe permitir el mismo accesorio dos veces"
    assert_not @owner.product_accessories.build(accessory: @owner).valid?, "no debe ligarse consigo mismo"
  end
end
