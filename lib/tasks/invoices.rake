# frozen_string_literal: true

namespace :invoices do
  desc "Archiva la copia en PDF de las facturas emitidas que aún no la tienen"
  task archive_pdfs: :environment do
    pending = Invoice.pending_pdf_archive.count
    archived = 0
    failed = []

    Invoice.pending_pdf_archive.find_each do |invoice|
      archived += 1 if invoice.archive_pdf!
    rescue StandardError => e
      # una factura que falla no puede dejar sin copia a las demás
      failed << "#{invoice.number} (#{e.class}: #{e.message})"
    end

    puts "Facturas sin copia: #{pending}. Copias archivadas ahora: #{archived}."
    puts "Han fallado: #{failed.join(' | ')}" if failed.any?
    puts "Siguen sin copia: #{Invoice.pending_pdf_archive.count} (las pendientes de VeriFactu se archivan al enviarse)."
  end
end
