module Admin
  # Ver en PDF la etiqueta de un envío de Ontime, por su nº de seguimiento y el
  # código postal de destino. De momento solo consulta la etiqueta; el alta de
  # envíos desde el pedido vendrá después.
  class OntimeLabelsController < BaseController
    def index; end

    def pdf
      tracking = params[:tracking].to_s.strip
      postal_code = params[:cp].to_s.strip
      if tracking.blank? || postal_code.blank?
        return redirect_to admin_ontime_labels_path,
                           alert: "Indica el nº de seguimiento y el código postal de destino."
      end

      label = Ontime::LabelPdf.render(tracking: tracking, postal_code: postal_code)
      send_data label, type: "application/pdf", disposition: "inline",
                       filename: "etiqueta-ontime-#{tracking}.pdf"
    rescue Ontime::Client::Error, Ontime::LabelPdf::Error => e
      redirect_to admin_ontime_labels_path, alert: "No se pudo obtener la etiqueta: #{e.message}"
    end
  end
end
