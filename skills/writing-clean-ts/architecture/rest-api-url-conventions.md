# REST API URL Conventions

REST API URL path conventions for creating consistent and predictable endpoints.

## URL Path Naming

### Case Convention

**Use dashed-case (kebab-case) for URL paths.**

```
✅ /user-profiles
✅ /api/v1/order-items
✅ /appointments/1/time-slots

❌ /userProfiles (camelCase)
❌ /user_profiles (snake_case)
❌ /UserProfiles (PascalCase)
```

### Plural vs Singular

**Use plural names for collections, singular names for specific entities or actions.**

```
✅ /books              (collection - plural)
✅ /books/1            (specific book - ID after plural)
✅ /books/2/checkout   (action on specific book)

❌ /book               (collection should be plural)
❌ /book/1             (should use plural even for single item)
```

### Path Structure

**General REST path structure:**

```
http(s)://<base-url>/<plural-collection>/<entity-id>/<optional-action-or-nested-resource>
```

**Examples:**

```
GET    https://app.com/books
GET    https://app.com/books/1
POST   https://app.com/books
PUT    https://app.com/books/1
DELETE https://app.com/books/1
POST   https://app.com/books/2/checkout
GET    https://app.com/books/2/reviews
```

### Unique Identifiers in Path

**Singular names can be used for path segments representing unique identifiers, but they must follow the plural collection name:**

```
Pattern: /<collection>/<identifier>
```

**Examples:**

```
✅ /appointments/1                    (appointment ID)
✅ /integrations/ab-inbev             (integration for client "ab-inbev")
✅ /users/john-doe/profile            (user identifier + nested resource)
✅ /projects/acme-corp/settings       (project identifier + nested resource)

❌ /appointment/1                     (collection should be plural)
❌ /integration/ab-inbev              (collection should be plural)
```

**Note:** In `/integrations/ab-inbev`, "ab-inbev" represents a unique identifier for the integration with that specific client, not a sub-collection.

## Examples by HTTP Method

### GET (Read)

```
GET /users                    # List all users
GET /users/123                # Get specific user
GET /users/123/orders         # Get orders for user 123
GET /users/123/orders/456     # Get specific order for user 123
```

### POST (Create)

```
POST /users                   # Create new user
POST /users/123/activate      # Action: activate user 123
POST /books/2/checkout        # Action: checkout book 2
```

### PUT/PATCH (Update)

```
PUT   /users/123              # Full update of user 123
PATCH /users/123              # Partial update of user 123
```

### DELETE (Remove)

```
DELETE /users/123             # Delete user 123
DELETE /users/123/avatar      # Delete avatar for user 123
```

## Common Patterns

### Nested Resources

```
✅ /users/123/orders          # Orders belonging to user 123
✅ /posts/456/comments        # Comments on post 456
✅ /projects/789/tasks        # Tasks in project 789

# Avoid deep nesting (max 2-3 levels)
❌ /users/123/orders/456/items/789/reviews
```

### Actions on Resources

```
✅ /orders/123/cancel         # Cancel order 123
✅ /users/456/activate        # Activate user 456
✅ /documents/789/publish     # Publish document 789
```

### Unique Resource Identifiers

```
✅ /integrations/stripe       # Stripe integration (unique)
✅ /integrations/paypal       # PayPal integration (unique)
✅ /settings/notification     # Notification settings (unique)
✅ /users/current             # Current authenticated user
```

## Query Parameters vs Path Parameters

### Path Parameters (Resource Identification)

Use path parameters to identify specific resources:

```
✅ /users/123                 # User ID in path
✅ /books/isbn-12345          # Book ISBN in path
✅ /projects/acme-corp        # Project identifier in path
```

### Query Parameters (Filtering, Sorting, Pagination)

Use query parameters for filtering, sorting, and pagination:

```
✅ /users?role=admin&status=active
✅ /books?author=tolkien&sort=title
✅ /orders?page=2&limit=20
✅ /products?category=electronics&price_min=100
```

## Complete Examples

### E-commerce API

```
GET    /products                          # List products
GET    /products/123                      # Get product details
POST   /products                          # Create product
PUT    /products/123                      # Update product
DELETE /products/123                      # Delete product

GET    /orders                            # List orders
GET    /orders/456                        # Get order details
POST   /orders                            # Create order
POST   /orders/456/cancel                 # Cancel order
GET    /orders/456/items                  # Get order items

GET    /users/789/orders                  # Orders for user 789
GET    /users/789/cart                    # Cart for user 789
POST   /users/789/cart/checkout           # Checkout cart
```

### Integration API

```
GET    /integrations                      # List all integrations
GET    /integrations/stripe               # Stripe integration (unique identifier)
POST   /integrations/stripe/connect       # Connect Stripe integration
DELETE /integrations/stripe/disconnect    # Disconnect Stripe

GET    /integrations/ab-inbev             # AB InBev client integration
PUT    /integrations/ab-inbev             # Update AB InBev integration config
```

### Appointment System

```
GET    /appointments                      # List appointments
GET    /appointments/1                    # Get appointment 1
POST   /appointments                      # Create appointment
PUT    /appointments/1                    # Update appointment
DELETE /appointments/1                    # Cancel appointment
GET    /appointments/1/time-slots         # Available time slots
POST   /appointments/1/reschedule         # Reschedule appointment
```

## Key Rules Summary

1. **Use dashed-case (kebab-case)** for all URL paths
2. **Use plural names** for collections (`/books`, `/users`, `/orders`)
3. **Use singular identifiers** after the plural collection (`/books/1`, `/integrations/stripe`)
4. **Follow the pattern**: `/<collection>/<identifier>/<optional-nested-resource-or-action>`
5. **Path parameters**: For resource identification
6. **Query parameters**: For filtering, sorting, pagination
7. **Keep nesting shallow**: Max 2-3 levels deep
8. **Actions are verbs**: `/orders/123/cancel`, `/users/456/activate`

## Integration with File Naming

**REST URL paths map to Express controller files:**

```
URL Path                    →  Controller File
---------------------------------------------------------------------------
GET  /books                 →  src/controller/express/get-books.ts
GET  /books/:id             →  src/controller/express/get-book.ts
POST /books                 →  src/controller/express/post-book.ts
PUT  /books/:id             →  src/controller/express/put-book.ts
POST /books/:id/checkout    →  src/controller/express/post-book-checkout.ts
```

**See [express-handler-pattern.md](express-handler-pattern.md) for controller implementation details.**
