module Admin
  # Todo el panel exige sesión iniciada (concern Authentication del ApplicationController).
  class BaseController < ApplicationController
    layout 'admin'

    helper_method :pending_to_prepare_count

    private

    # Pedidos pagados que siguen en «creado»: pendientes de preparar y enviar.
    def pending_to_prepare_count
      Order.where(payment_status: :pagado, status: :creado).count
    end
  end
end
