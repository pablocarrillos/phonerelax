# Ejemplos de personalización

Fotos reales de bolsas PhoneRelax con la marca del cliente. Se muestran en la
galería de /presupuesto (sección "Personalización con tu marca").

La galería lee esta carpeta a través de `ApplicationHelper::CUSTOMIZATION_EXAMPLES`
y solo muestra la foto si el archivo existe con ESTE nombre exacto:

- kensington-school.jpg    → Kensington School
- colegio-norfolk.jpg      → Colegio Norfolk
- colegio-san-fernando.jpg → Colegio San Fernando
- montcau-la-mola.jpg      → Escola Montcau-La Mola
- phonerelax-basica.jpg    → PhoneRelax (modelo estándar)

Recomendado: JPG, orientación vertical, ~1000 px de ancho, < 300 KB.
Para añadir más ejemplos, sube la foto aquí y añade su {file, name} a la
constante CUSTOMIZATION_EXAMPLES del helper.
