# PhoneRelax

Tienda + gestión de pedidos de PhoneRelax (réplica visual de phonerelax.com en Shopify).

- **Tienda pública**: catálogo (importado de Shopify), carrito en sesión y pago con **Stripe Checkout** alojado.
- **Pedidos**: número corto (`PR-XXXXXX`), estado de pago (pendiente/pagado, lo gestiona Stripe) y estado logístico **creado → enviado → recibido** (lo gestionas tú desde el admin). El cliente puede seguir su pedido en `/pedido/PR-XXXXXX`.
- **Panel de gestión** en `/admin` (con login): pedidos con filtros por estado y botón para avanzar el estado, y CRUD de productos.

## Arranque en local

```bash
bin/rails db:create db:migrate db:seed   # importa el catálogo y crea el admin
bin/rails server
```

- Admin: `admin@phonerelax.com` / `phonerelax-admin` (cámbiala desde la consola: `User.first.update!(password: '...')`).
- Base de datos: PostgreSQL local, usuario `development` (igual que el resto de proyectos).

## Claves de Stripe

Copia `config/local_env.yml.sample` a `config/local_env.yml` y pon tus claves (usa las de **test** en desarrollo):

```yaml
STRIPE_SECRET_KEY: sk_test_...
STRIPE_WEBHOOK_SECRET: whsec_...
```

Sin clave, la tienda funciona pero al pagar mostrará un error controlado.

### Webhook en desarrollo

```bash
stripe listen --forward-to localhost:3000/stripe/webhook
```

El evento `checkout.session.completed` marca el pedido como pagado. Además, al volver del
Checkout la app verifica el estado de la sesión contra Stripe, por lo que en desarrollo
funciona incluso sin el webhook.

## Catálogo

`db/seeds.rb` contiene el catálogo importado de phonerelax.com (products.json de Shopify) con
imágenes servidas desde el CDN de Shopify. Es idempotente: puedes reejecutarlo sin duplicar.
# phonerelax
