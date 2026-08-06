require "test_helper"

# Herramienta de fotos del admin: subir imágenes con comentario, buscarlas y
# compartirlas por su URL pública (accesible sin sesión).
class AdminPhotosTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "subir una foto con comentario y verla en la lista" do
    assert_difference "Photo.count", 1 do
      post admin_photos_path, params: { images: [ fixture_file_upload("cover.png", "image/png") ],
                                        comment: "Funda personalizada Norfolk" }
    end
    assert_redirected_to admin_photos_path
    photo = Photo.last
    assert_equal "Funda personalizada Norfolk", photo.comment
    assert photo.image.attached?

    get admin_photos_path
    assert_response :success
    assert_includes response.body, "Funda personalizada Norfolk"
    assert_includes response.body, "Copiar URL"
  end

  test "el buscador filtra por comentario o nombre de archivo" do
    Photo.create!(image: fixture_file_upload("cover.png", "image/png"), comment: "Cartel evento Madrid")
    Photo.create!(image: fixture_file_upload("cover.png", "image/png"), comment: "Logo colegio")

    get admin_photos_path(q: "evento")
    assert_includes response.body, "Cartel evento Madrid"
    assert_not_includes response.body, "Logo colegio"

    get admin_photos_path(q: "cover")
    assert_includes response.body, "Cartel evento Madrid" # por nombre de archivo
  end

  test "la URL de la imagen es pública (sin sesión) y borrar la retira" do
    photo = Photo.create!(image: fixture_file_upload("cover.png", "image/png"), comment: "pública")
    blob_path = rails_blob_path(photo.image, disposition: :inline)

    delete session_path # cerrar la sesión del admin
    get blob_path
    assert_response :redirect # redirige al fichero servido por Active Storage

    sign_in_as(users(:one))
    assert_difference "Photo.count", -1 do
      delete admin_photo_path(photo)
    end
  end

  test "la lista incluye las imágenes estáticas del proyecto y el buscador las filtra" do
    get admin_photos_path
    assert_includes response.body, "Imágenes del proyecto"
    assert_includes response.body, "/images/site/paso-1-mete-el-telefono.jpg"
    assert_includes response.body, "800×1067 px" # dimensiones de paso-1

    get admin_photos_path(q: "paso-2")
    assert_includes response.body, "/images/site/paso-2-cierra-la-bolsa.jpg"
    assert_not_includes response.body, "/images/site/paso-1-mete-el-telefono.jpg"
  end

  test "comentar una imagen del proyecto y encontrarla por el comentario" do
    patch project_comment_admin_photos_path,
          params: { path: "/images/site/paso-1-mete-el-telefono.jpg", comment: "meter movil en funda" }
    assert_equal "meter movil en funda",
                 ImageComment.find_by(path: "/images/site/paso-1-mete-el-telefono.jpg").comment

    get admin_photos_path(q: "meter movil")
    assert_includes response.body, "/images/site/paso-1-mete-el-telefono.jpg"
    assert_not_includes response.body, "/images/site/paso-2-cierra-la-bolsa.jpg"

    # una ruta fuera de /images se rechaza
    patch project_comment_admin_photos_path, params: { path: "/etc/passwd", comment: "x" }
    assert_nil ImageComment.find_by(path: "/etc/passwd")
  end

  test "editar el comentario de una foto" do
    photo = Photo.create!(image: fixture_file_upload("cover.png", "image/png"), comment: "antes")
    patch admin_photo_path(photo), params: { photo: { comment: "después" } }
    assert_equal "después", photo.reload.comment
  end
end
