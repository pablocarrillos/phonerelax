require "test_helper"

class CompanySettingTest < ActiveSupport::TestCase
  test "el token de VeriFactu se guarda cifrado y se lee transparente" do
    setting = CompanySetting.current
    setting.update!(verifactu_token: "a" * 64)

    raw = CompanySetting.connection.select_value(
      "SELECT verifactu_token FROM company_settings WHERE id = #{setting.id}"
    )

    assert_not_equal "a" * 64, raw, "la columna no debe guardar el token en claro"
    assert_equal "a" * 64, setting.reload.verifactu_token
  end
end
