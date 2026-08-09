# Configuración de Pagy (v43). Los valores por defecto de la app van en
# Pagy::OPTIONS (Pagy::DEFAULT es de solo lectura).
Pagy::OPTIONS[:limit] = 20

# Nota: en Pagy 43 desapareció el extra "overflow". Una página fuera de rango
# devuelve una página vacía por defecto (no lanza error salvo :raise_range_error).
