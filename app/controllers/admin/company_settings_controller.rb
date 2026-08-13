# "Datos de empresa": la emisora de las facturas (Drop Point Systems), sus dos
# series de facturación y la configuración de VeriFactu.
module Admin
  class CompanySettingsController < BaseController
    def show
      @setting = CompanySetting.current
    end

    def update
      @setting = CompanySetting.current
      if @setting.update(setting_params)
        redirect_to admin_company_setting_path, notice: "Datos de empresa guardados."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def setting_params
      params.require(:company_setting).permit(
        :legal_name, :tax_id, :address, :city, :postal_code, :province, :country,
        :phone, :email,
        :web_series, :web_next_number, :quote_series, :quote_next_number,
        :verifactu_enabled, :verifactu_environment, :verifactu_token
      )
    end
  end
end
