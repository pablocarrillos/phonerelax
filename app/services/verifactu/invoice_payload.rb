# frozen_string_literal: true

module Verifactu
  # Cuerpo JSON de alta en TICKETBAIWS para una factura de phonerelax (venta web
  # o presupuesto aprobado). Las líneas van AGREGADAS por tipo de IVA con la base
  # sin IVA (bases resumidas, como exige VeriFactu); sin NIF del cliente se envía
  # como simplificada.
  class InvoicePayload
    DESCRIPTIONS = {
      Invoice::WEB => "Venta tienda online PhoneRelax",
      Invoice::QUOTE => "Pedido PhoneRelax"
    }.freeze

    def self.build(invoice) = new(invoice).build

    def initialize(invoice)
      @invoice = invoice
    end

    def build
      serie, numero = split_number(@invoice.number)
      payload = {
        fecha: date(@invoice.issued_on),
        hora: @invoice.created_at.in_time_zone.strftime("%H:%M:%S"),
        serie: serie,
        numero: numero,
        simplificada: simplificada?,
        tipo_operacion: "bienes",
        total_factura: @invoice.total.to_f,
        lineas: lineas
      }
      payload.merge!(cliente) unless simplificada?
      payload
    end

    private

    def simplificada?
      @invoice.client_tax_id.blank?
    end

    def lineas
      @invoice.iva_breakdown.map do |b|
        {
          descripcion: "#{DESCRIPTIONS[@invoice.kind]} (IVA #{b[:rate].to_i}%)",
          cantidad: 1,
          importe_unitario: b[:base].to_f,
          tipo_iva: b[:rate].to_f,
          tipo_req: 0
        }
      end
    end

    def cliente
      {
        nif: @invoice.client_tax_id.to_s,
        nombre: @invoice.client_name.to_s,
        direccion: @invoice.client_address.to_s,
        pais_cliente: "ES"
      }
    end

    # "WEB-0001" -> ["WEB", "0001"]: el número es el último tramo.
    def split_number(number)
      before, _sep, last = number.to_s.rpartition("-")
      before.present? ? [ before, last ] : [ "", last ]
    end

    def date(d) = d&.strftime("%d/%m/%Y")
  end
end
