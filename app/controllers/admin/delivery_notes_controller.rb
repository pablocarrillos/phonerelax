module Admin
  # Albaranes numerados (serie ALBARAN-PHONERELAX): se generan desde un pedido
  # o un presupuesto, consumen número de la serie al emitirse y después se
  # pueden editar libremente manteniendo el número.
  class DeliveryNotesController < BaseController
    # Genera el albarán del pedido o presupuesto indicado. Si ya existe, no se
    # crea otro (ni se consume número): se va al que hay.
    def create
      note = if params[:order_id].present?
        DeliveryNote.issue_for_order!(Order.find(params[:order_id]))
      else
        DeliveryNote.issue_for_quote!(Quote.find(params[:quote_id]))
      end
      redirect_to edit_admin_delivery_note_path(note),
                  notice: "Albarán #{note.number} de #{note.source_label}."
    end

    def edit
      @delivery_note = DeliveryNote.includes(:lines).find(params[:id])
    end

    # El número no se puede cambiar (no está en los params permitidos); el resto
    # de datos sí, aunque el albarán ya esté emitido.
    def update
      @delivery_note = DeliveryNote.find(params[:id])
      if @delivery_note.update(delivery_note_params)
        redirect_to edit_admin_delivery_note_path(@delivery_note), notice: "Albarán #{@delivery_note.number} guardado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def pdf
      note = DeliveryNote.find(params[:id])
      send_data DeliveryNotePdf.render(note.pdf_data),
                filename: "#{note.number}.pdf", type: "application/pdf", disposition: "inline"
    end

    private

    def delivery_note_params
      params.require(:delivery_note).permit(
        :issued_on, :client_name, :client_tax_id, :client_email, :client_address, :delivery_address, :comments,
        lines_attributes: [ :id, :description, :quantity, :position, :_destroy ]
      )
    end
  end
end
