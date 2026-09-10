require "test_helper"

# Copias de seguridad al Space: qué se sube, con qué nombre, qué se conserva y
# cuándo se considera que una copia está atrasada.
class BackupsTest < ActiveSupport::TestCase
  # Almacén de mentira: se queda con lo subido en memoria, sin tocar la red.
  class FakeStore
    attr_reader :uploads, :pruned

    def initialize(latest: {})
      @uploads = []
      @pruned = []
      @latest = latest
    end

    def upload(key, path)
      @uploads << { key: key, bytes: File.size(path), head: File.binread(path, 4) }
      key
    end

    def prune(prefix, keep:)
      @pruned << { prefix: prefix, keep: keep }
      0
    end

    def latest(prefix) = @latest[prefix]
  end

  # --- copia de los ficheros subidos ---

  test "la copia de archivos empaqueta storage, la sube con fecha en el nombre y poda" do
    store = FakeStore.new
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "storage", "ab"))
      File.write(File.join(root, "storage", "ab", "factura.pdf"), "%PDF-1.4 copia de factura")

      info = Backups::FilesBackup.new(store: store, root: File.join(root, "storage"))
                                 .run(now: Time.zone.local(2026, 9, 10, 3, 20))

      assert_equal "phonerelax/files/phonerelax-files-20260910-0320.tar.gz", info[:key]
      assert_equal 1, info[:files]
      assert_operator info[:size], :>, 0
      assert_equal "\x1F\x8B".b, store.uploads.sole[:head].byteslice(0, 2), "debe ser un .gz de verdad"
      assert_equal({ prefix: "phonerelax/files/", keep: 14 }, store.pruned.sole)
    end
  end

  test "si no existe el directorio de archivos, la copia falla en vez de subir algo vacío" do
    error = assert_raises(RuntimeError) do
      Backups::FilesBackup.new(store: FakeStore.new, root: "/no/existe").run
    end
    assert_match "no existe el directorio de archivos", error.message
  end

  # --- volcado de la base de datos ---

  test "el volcado sale comprimido, con fecha en el nombre, y se conservan 30" do
    store = FakeStore.new
    info = Backups::DatabaseBackup.new(store: store).run(now: Time.zone.local(2026, 9, 10, 3, 20))

    assert_equal "phonerelax/db/phonerelax-db-20260910-0320.sql.gz", info[:key]
    assert_operator info[:size], :>, 0
    assert_equal "\x1F\x8B".b, store.uploads.sole[:head].byteslice(0, 2)
    assert_equal({ prefix: "phonerelax/db/", keep: 30 }, store.pruned.sole)
  end

  # --- estado de las copias ---

  test "las dos copias recientes dan estado correcto" do
    store = FakeStore.new(latest: {
      "phonerelax/db/" => { key: "a", at: 2.hours.ago, size: 100 },
      "phonerelax/files/" => { key: "b", at: 3.hours.ago, size: 200 }
    })

    assert Backups::Status.new(store: store).ok?
  end

  test "una copia atrasada o ausente se detecta y se cuenta en cristiano" do
    store = FakeStore.new(latest: {
      "phonerelax/db/" => { key: "a", at: 4.days.ago, size: 100 },
      "phonerelax/files/" => nil
    })
    status = Backups::Status.new(store: store)

    assert_not status.ok?
    assert_equal 2, status.problems.size
    assert_match(/base de datos: la última es del/, status.problems.first)
    assert_equal "archivos subidos: no hay ninguna copia en el bucket", status.problems.last
  end

  test "sin credenciales el estado lo dice en vez de reventar" do
    status = Backups::Status.new(store: nil)

    assert_not status.configured?
    assert_not status.ok?
    assert(status.problems.all? { |p| p.include?("BACKUP_S3_") })
  end

  test "el aviso por correo cuenta los problemas y a dónde mirar" do
    mail = BackupMailer.failed([ "base de datos: no hay ninguna copia en el bucket" ])

    assert_match "Copias de seguridad de phonerelax", mail.subject
    assert_match "no hay ninguna copia en el bucket", mail.body.to_s
    assert_match "backups:check", mail.body.to_s
  end
end
