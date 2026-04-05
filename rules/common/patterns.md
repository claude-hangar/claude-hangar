# Positive Design Patterns

Patterns to follow when building software. Complement the anti-patterns
documented in the project's CLAUDE.md.

## Architectural Patterns

### Repository Pattern
Separate data access from business logic:
```
// Interface defines the contract
interface UserRepository {
  findById(id: string): Promise<User | null>
  save(user: User): Promise<void>
}

// Implementation handles the details
class PostgresUserRepository implements UserRepository {
  // ...database-specific code
}
```
**When:** Any project with database access.

### Service Layer
Business logic lives in service classes, not in route handlers:
```
// GOOD: Logic in service
router.post('/users', async (req, res) => {
  const user = await userService.createUser(req.body)
  res.json(user)
})

// BAD: Logic in handler
router.post('/users', async (req, res) => {
  const hashedPw = await bcrypt.hash(req.body.password, 10)
  const user = await db.insert(users).values({ ...req.body, password: hashedPw })
  await sendWelcomeEmail(user.email)
  res.json(user)
})
```

### Event-Driven Architecture
Use events for cross-cutting concerns:
```
// Emit events for side effects
eventBus.emit('user.created', user)

// Listeners handle side effects independently
eventBus.on('user.created', sendWelcomeEmail)
eventBus.on('user.created', initializeUserSettings)
eventBus.on('user.created', trackAnalytics)
```
**When:** Multiple actions triggered by one event.

## API Patterns

### Consistent Response Format
```json
{
  "success": true,
  "data": { ... },
  "meta": { "page": 1, "total": 42 }
}

{
  "success": false,
  "error": { "code": "VALIDATION_ERROR", "message": "Email is required" }
}
```

### Pagination
Always paginate list endpoints:
```
GET /api/users?page=1&limit=20
GET /api/users?cursor=abc123&limit=20
```

### Idempotency
For mutation endpoints, use idempotency keys:
```
POST /api/payments
Idempotency-Key: unique-request-id-123
```

## Code Patterns

### Early Returns
```
// GOOD: Return early, reduce nesting
function process(input) {
  if (!input) return null
  if (!input.valid) return { error: 'invalid' }
  return doWork(input)
}

// BAD: Deep nesting
function process(input) {
  if (input) {
    if (input.valid) {
      return doWork(input)
    } else {
      return { error: 'invalid' }
    }
  }
  return null
}
```

### Composition Over Inheritance
```
// GOOD: Compose behaviors
const withAuth = (handler) => (req, res) => {
  if (!req.user) return res.status(401).send()
  return handler(req, res)
}

// BAD: Deep inheritance
class AuthenticatedHandler extends BaseHandler { ... }
class AdminHandler extends AuthenticatedHandler { ... }
```

### Fail Fast
Validate at the boundary, trust internally:
```
// Validate once at the edge
function createUser(input: unknown) {
  const validated = userSchema.parse(input)  // throws if invalid
  return userService.create(validated)        // trusted from here
}
```
