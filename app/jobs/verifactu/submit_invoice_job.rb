# frozen_string_literal: true

module Verifactu
  # Envía una factura a VeriFactu (TICKETBAIWS) y guarda huella/QR/URL.
  # Reintenta ante errores temporales (red/5xx). Sin cola persistente en phonerelax:
  # si un envío se pierde por un reinicio queda en «pending» y se reenvía con el
  # botón «Reenviar» del listado.
  class SubmitInvoiceJob < ApplicationJob
    queue_as :default

    retry_on Verifactu::TemporaryError, wait: :polynomially_longer, attempts: 8

    def perform(invoice)
      setting = CompanySetting.current
      return unless setting.verifactu_configured?
      return if invoice.verifactu_status == "sent"

      invoice.increment!(:verifactu_attempts)
      result = Verifactu::Client.new(setting).submit(Verifactu::InvoicePayload.build(invoice))

      if result.ok?
        invoice.update!(
          verifactu_status: "sent",
          verifactu_huella: result.huella,
          verifactu_qr: result.qr,
          verifactu_url: result.url,
          verifactu_error: nil,
          verifactu_sent_at: Time.current
        )
      else
        invoice.update!(verifactu_status: "error", verifactu_error: result.message)
      end
    end
  end
end
