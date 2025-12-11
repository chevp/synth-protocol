# VFP-REST: E-Commerce

Online Shop mit Warenkorb, Bestellungen und Echtzeit-Lagerbestand.

## Architektur

```
┌─────────────────┐                    ┌─────────────────┐
│  Shop Frontend  │   VFP-REST/WS      │  Shop Server    │
│  (Next.js)      │ ◄───────────────► │  (PHP/Node)     │
└─────────────────┘                    │                 │
                                       │  - Preise       │
┌─────────────────┐                    │  - Lager        │
│  Admin Panel    │   VFP-REST         │  - Checkout     │
│  (React)        │ ◄───────────────► │  - Payment      │
└─────────────────┘                    └─────────────────┘
```

## URL Schema

```
/vfp/shops/{shopId}/
    meta.json               Shop Konfiguration
    products/
        {sku}.json          Produkte
    categories/
        {slug}.json         Kategorien
    inventory/
        {sku}.json          Lagerbestand
    carts/
        {cartId}.json       Warenkoerbe
    orders/
        {orderId}.json      Bestellungen
    customers/
        {customerId}.json   Kunden
    promotions/
        {promoId}.json      Rabattaktionen
```

## Produkt anlegen

```http
PUT /vfp/shops/myshop/products/SKU-001.json HTTP/1.1
Content-Type: application/json
X-Vfp-Message: Add new product

{
  "sku": "SKU-001",
  "name": "Premium Headphones",
  "slug": "premium-headphones",
  "description": "High-quality wireless headphones",
  "price": {
    "amount": 19999,
    "currency": "EUR"
  },
  "comparePrice": {
    "amount": 24999,
    "currency": "EUR"
  },
  "images": [
    { "id": "img_001", "url": "/media/products/headphones-1.jpg", "alt": "Front view" },
    { "id": "img_002", "url": "/media/products/headphones-2.jpg", "alt": "Side view" }
  ],
  "categories": ["electronics", "audio"],
  "tags": ["wireless", "bluetooth", "premium"],
  "variants": [
    { "id": "var_black", "name": "Black", "sku": "SKU-001-BLK", "price": null },
    { "id": "var_white", "name": "White", "sku": "SKU-001-WHT", "price": null }
  ],
  "status": "active",
  "createdAt": 1733400000000
}
```

## Lagerbestand

```http
PUT /vfp/shops/myshop/inventory/SKU-001-BLK.json HTTP/1.1
Content-Type: application/json

{
  "sku": "SKU-001-BLK",
  "quantity": 150,
  "reserved": 5,
  "available": 145,
  "lowStockThreshold": 20,
  "trackInventory": true,
  "allowBackorder": false,
  "warehouse": "WH-EU-01"
}
```

## Realtime Lagerbestand (WebSocket)

Shop zeigt Echtzeit-Verfuegbarkeit:

```json
{
  "id": "req-001",
  "op": "WATCH",
  "payload": {
    "patterns": ["/shops/myshop/inventory/*"],
    "initial": false
  }
}
```

**Server sendet bei Bestellung:**
```json
{
  "op": "DELTA",
  "payload": {
    "tick": 5001,
    "nodes": [
      {
        "path": "/inventory/SKU-001-BLK.json",
        "op": "update",
        "fields": [
          { "field": "quantity", "value": 148 },
          { "field": "available", "value": 143 }
        ]
      }
    ]
  }
}
```

## Warenkorb erstellen

```http
PUT /vfp/shops/myshop/carts/cart_abc123.json HTTP/1.1
Content-Type: application/json

{
  "id": "cart_abc123",
  "customerId": null,
  "sessionId": "sess_xyz789",
  "items": [],
  "subtotal": { "amount": 0, "currency": "EUR" },
  "createdAt": 1733400000000,
  "expiresAt": 1733486400000
}
```

## Artikel zum Warenkorb hinzufuegen

```http
PUT /vfp/shops/myshop/carts/cart_abc123.json HTTP/1.1
Content-Type: application/json
If-Match: "cart_v1"

{
  "id": "cart_abc123",
  "items": [
    {
      "sku": "SKU-001-BLK",
      "name": "Premium Headphones - Black",
      "quantity": 2,
      "unitPrice": { "amount": 19999, "currency": "EUR" },
      "lineTotal": { "amount": 39998, "currency": "EUR" }
    }
  ],
  "subtotal": { "amount": 39998, "currency": "EUR" }
}
```

**Server validiert:**
- Produkt existiert und ist aktiv
- Lagerbestand verfuegbar
- Preis ist aktuell

**Bei Fehler:**
```http
HTTP/1.1 409 Conflict

{
  "code": "INSUFFICIENT_STOCK",
  "message": "Only 1 item available",
  "sku": "SKU-001-BLK",
  "available": 1,
  "requested": 2
}
```

## Rabattcode anwenden

```http
PUT /vfp/shops/myshop/carts/cart_abc123.json HTTP/1.1
Content-Type: application/json

{
  "id": "cart_abc123",
  "items": [...],
  "promoCode": "SAVE20",
  "subtotal": { "amount": 39998, "currency": "EUR" }
}
```

**Server berechnet Rabatt und antwortet:**
```json
{
  "id": "cart_abc123",
  "items": [...],
  "promoCode": "SAVE20",
  "subtotal": { "amount": 39998, "currency": "EUR" },
  "discount": {
    "code": "SAVE20",
    "type": "percentage",
    "value": 20,
    "amount": { "amount": 7999, "currency": "EUR" }
  },
  "total": { "amount": 31999, "currency": "EUR" }
}
```

## Checkout - Bestellung erstellen

```http
PUT /vfp/shops/myshop/orders/order_001.json HTTP/1.1
Content-Type: application/json
X-Vfp-Message: Create order from cart

{
  "id": "order_001",
  "cartId": "cart_abc123",
  "customer": {
    "email": "kunde@example.com",
    "firstName": "Max",
    "lastName": "Mustermann"
  },
  "shippingAddress": {
    "street": "Musterstrasse 123",
    "city": "Berlin",
    "postalCode": "10115",
    "country": "DE"
  },
  "billingAddress": {
    "sameAsShipping": true
  },
  "paymentMethod": "stripe",
  "status": "pending_payment"
}
```

**Server:**
1. Validiert Warenkorb
2. Reserviert Lagerbestand
3. Erstellt Payment Intent
4. Gibt Payment Client Secret zurueck

```json
{
  "id": "order_001",
  "status": "pending_payment",
  "payment": {
    "provider": "stripe",
    "clientSecret": "pi_xxx_secret_yyy",
    "amount": { "amount": 31999, "currency": "EUR" }
  },
  "items": [...],
  "totals": {
    "subtotal": { "amount": 39998, "currency": "EUR" },
    "discount": { "amount": 7999, "currency": "EUR" },
    "shipping": { "amount": 0, "currency": "EUR" },
    "tax": { "amount": 5109, "currency": "EUR" },
    "total": { "amount": 37108, "currency": "EUR" }
  }
}
```

## Payment Webhook (Server-to-Server)

Stripe sendet Webhook, Server aktualisiert:

```http
PUT /vfp/shops/myshop/orders/order_001.json HTTP/1.1
Content-Type: application/json

{
  "status": "paid",
  "payment": {
    "status": "succeeded",
    "paidAt": 1733401000000,
    "transactionId": "pi_xxx"
  }
}
```

## Order Status Updates (Realtime)

Kunde sieht Echtzeit-Status:

```json
{
  "op": "DELTA",
  "payload": {
    "tick": 6000,
    "nodes": [
      {
        "path": "/orders/order_001.json",
        "op": "update",
        "fields": [
          { "field": "status", "value": "shipped" },
          { "field": "tracking", "value": {
            "carrier": "DHL",
            "trackingNumber": "123456789",
            "url": "https://dhl.de/track/123456789"
          }}
        ]
      }
    ]
  }
}
```

## Produktsuche

```http
GET /vfp/shops/myshop/products/_select?search=headphones&filter=status%3Dactive&sort=price:asc&limit=20 HTTP/1.1
```

```json
{
  "results": [
    {
      "path": "/products/SKU-001.json",
      "data": {
        "sku": "SKU-001",
        "name": "Premium Headphones",
        "price": { "amount": 19999, "currency": "EUR" }
      },
      "score": 0.95
    },
    {
      "path": "/products/SKU-002.json",
      "data": {
        "sku": "SKU-002",
        "name": "Budget Headphones",
        "price": { "amount": 4999, "currency": "EUR" }
      },
      "score": 0.82
    }
  ],
  "total": 2,
  "has_more": false
}
```

## React Shop Component

```tsx
function ProductPage({ sku }: Props) {
    const vfp = useVfpClient();
    const [product, setProduct] = useState<Product | null>(null);
    const [inventory, setInventory] = useState<Inventory | null>(null);

    useEffect(() => {
        // Load product
        vfp.read(`/shops/myshop/products/${sku}.json`).then(setProduct);

        // Realtime inventory
        const unwatch = vfp.watch(`/shops/myshop/inventory/${sku}*`, (delta) => {
            setInventory(prev => ({
                ...prev,
                ...delta.fields.reduce((acc, f) => ({ ...acc, [f.field]: f.value }), {})
            }));
        });

        return unwatch;
    }, [sku]);

    async function addToCart() {
        const cartId = getOrCreateCartId();
        const cart = await vfp.read(`/shops/myshop/carts/${cartId}.json`);

        const updatedCart = {
            ...cart,
            items: [...cart.items, {
                sku: product.sku,
                name: product.name,
                quantity: 1,
                unitPrice: product.price
            }]
        };

        await vfp.write(`/shops/myshop/carts/${cartId}.json`, updatedCart);
    }

    return (
        <div>
            <h1>{product?.name}</h1>
            <Price amount={product?.price} />
            <StockIndicator available={inventory?.available} />
            <button onClick={addToCart} disabled={!inventory?.available}>
                Add to Cart
            </button>
        </div>
    );
}
```