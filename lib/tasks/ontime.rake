# frozen_string_literal: true

# Seguimiento de los envíos de Ontime: consulta el estado de los envíos activos
# (con seguimiento y sin entregar) y apunta los cambios en el historial del
# pedido/presupuesto. Pensada para el cron (deploy/phonerelax-ontime.cron).
namespace :ontime do
  desc "Consulta el estado en Ontime de los envíos activos y registra los cambios"
  task poll_statuses: :environment do
    scope = OntimeShipment.trackable
    total = scope.count
    puts "[#{Time.current.iso8601}] Ontime: consultando #{total} envío(s) activo(s)…"

    checked = 0
    scope.find_each do |shipment|
      shipment.poll!
      checked += 1
    rescue StandardError => e
      warn "[Ontime] error con #{shipment.tracking_number}: #{e.class} #{e.message}"
    end

    puts "[#{Time.current.iso8601}] Ontime: #{checked}/#{total} envío(s) consultados."
  end
end
