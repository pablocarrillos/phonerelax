require "test_helper"

# Ajustes de empresa: el nº de la serie simplificada se muestra con sus ceros
# (000002) en el formulario, pero se guarda como número entero.
class CompanySettingAdminTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "el nº simplificada se muestra con ceros y se guarda como número" do
    CompanySetting.current.update!(simplified_series: "4", simplified_next_number: 2)

    get admin_company_setting_path
    assert_response :success
    assert_select "input[name=?][value=?]", "company_setting[simplified_next_number]", "000002"

    patch admin_company_setting_path, params: { company_setting: { simplified_next_number: "000009" } }
    assert_equal 9, CompanySetting.current.reload.simplified_next_number
  end
end
