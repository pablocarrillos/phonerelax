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

  test "editar el comentario de una foto" do
    photo = Photo.create!(image: fixture_file_upload("cover.png", "image/png"), comment: "antes")
    patch admin_photo_path(photo), params: { photo: { comment: "después" } }
    assert_equal "después", photo.reload.comment
  end
end
