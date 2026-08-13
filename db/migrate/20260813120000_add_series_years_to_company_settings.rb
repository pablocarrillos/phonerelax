# Las series de facturación llevan el año en curso (WEB26-0001) y reinician su
# numeración al cambiar de año; aquí se guarda el año de cada serie.
class AddSeriesYearsToCompanySettings < ActiveRecord::Migration[8.1]
  def up
    add_column :company_settings, :web_series_year, :integer
    add_column :company_settings, :quote_series_year, :integer
    execute("UPDATE company_settings SET web_series_year = #{Date.current.year}, quote_series_year = #{Date.current.year}")
  end

  def down
    remove_column :company_settings, :web_series_year
    remove_column :company_settings, :quote_series_year
  end
end
