# frozen_string_literal: true

# Copias de seguridad al Space servipau-backups: el volcado de PostgreSQL y el
# archivo de todo lo subido (incluidas las copias en PDF de las facturas).
# Aquí no hay plugin de dokku que respalde la base de datos, así que las hace
# la propia aplicación. Si algo falla, avisa por correo.
namespace :backups do
  desc "Volcado de la base de datos al bucket"
  task db: :environment do
    info = Backups::DatabaseBackup.new.run
    puts "Volcado subido: #{info[:key]} (#{info[:size]} bytes)"
  end

  desc "Empaqueta y sube al bucket todo lo subido a la aplicación"
  task files: :environment do
    info = Backups::FilesBackup.new.run
    puts "Copia de archivos subida: #{info[:key]} (#{info[:files]} ficheros, #{info[:size]} bytes)"
  end

  desc "Las dos copias, de una vez (lo que corre el cron cada noche)"
  task run: :environment do
    problems = []
    %w[db files].each do |part|
      Rake::Task["backups:#{part}"].invoke
    rescue StandardError => e
      # que falle una no puede impedir la otra
      warn "Falló la copia de #{part}: #{e.class}: #{e.message}"
      problems << "#{part}: #{e.class}: #{e.message}"
    end

    if problems.any?
      BackupMailer.failed(problems, context: "Una copia de seguridad ha fallado al ejecutarse.").deliver_now
      exit 1
    end
  end

  desc "Comprueba que las copias (base de datos y archivos) están al día"
  task check: :environment do
    status = Backups::Status.new
    if status.ok?
      puts "Copias al día: #{status.parts.map { |p| "#{p.name} #{p.at}" }.join(' · ')}"
    else
      warn "Copias con problemas: #{status.problems.join(' | ')}"
      BackupMailer.failed(status.problems).deliver_now
      exit 1
    end
  end
end
