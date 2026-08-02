require "test_helper"

class SectorPagesTest < ActionDispatch::IntegrationTest
  PATHS = %i[sector_colegios_path sector_eventos_path sector_empresas_path sector_oposiciones_path].freeze

  test "cada landing de sector se renderiza en es/pt/en sin claves sin traducir" do
    PATHS.each do |helper|
      [nil, :pt, :en].each do |locale|
        get send(helper, locale: locale)
        assert_response :success, "#{helper} (#{locale || :es}) no responde 200"
        assert_select "h1"
        assert_no_match(/translation missing/, response.body)
      end
    end
  end
end
