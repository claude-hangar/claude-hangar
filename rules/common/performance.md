# Performance

Performance guidelines for all projects.

## General Principles

- Measure before optimizing — no premature optimization
- Set performance budgets early (LCP < 2.5s, CLS < 0.1, INP < 200ms)
- Profile bottlenecks before fixing (CPU, memory, network, I/O)
- Cache aggressively at every layer (CDN, application, database)

## Frontend Performance

- **Bundle size:** Track and set limits (< 200KB initial JS)
- **Images:** Use modern formats (WebP/AVIF), lazy load below fold
- **Fonts:** Preload critical fonts, use font-display: swap
- **CSS:** Purge unused styles, use CSS containment
- **JavaScript:** Code-split by route, defer non-critical scripts
- **Rendering:** Minimize layout shifts, avoid forced reflows

## Backend Performance

- **Database:** Index frequently queried columns, avoid N+1 queries
- **Caching:** Redis/memory cache for hot data, cache invalidation strategy
- **API:** Pagination for list endpoints, field selection for large objects
- **Async:** Use async/await for I/O-bound operations
- **Pooling:** Connection pools for databases and HTTP clients

## Database Performance

- Use `EXPLAIN ANALYZE` before deploying complex queries
- Index foreign keys and frequently filtered columns
- Avoid SELECT * — specify needed columns
- Use batch operations instead of loops
- Monitor slow query logs
