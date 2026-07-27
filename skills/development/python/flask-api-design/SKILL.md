---
name: flask-api-design
description: Flask API design for senior-engineer decisions in large-company services. Use when designing or reviewing Flask HTTP endpoints, resource models, URI shape, HTTP semantics, error contracts, pagination, filtering, versioning, and API evolution discipline.
---

# Flask API Design

Use this skill when the task is primarily about designing or reviewing an HTTP
API implemented in Flask.

This skill is not about teaching Python basics. It is about thinking like a
senior engineer in a large organization that happens to use Flask as the web
framework.

## Authoritative references

Treat these as the primary source of truth:

1. Zalando RESTful API and Event Guidelines
2. Microsoft Azure API design best practices
3. Google AIP-121 Resource-oriented design
4. Google Python Style Guide

## Core stance

Flask is an implementation detail.

The API contract is the product.

Design decisions must optimize for:

1. stable resource-oriented contracts
2. clear semantics at the HTTP boundary
3. client usability and low surprise
4. loose coupling between clients and server internals
5. long-term evolvability without breaking callers

Do not let Flask convenience drive the external API shape.

## Senior mindset

Think like an API owner, not only an endpoint implementer.

- Treat the API as a product.
- Prefer API-first thinking over route-first coding.
- Design the resource model before the handler details.
- Avoid exposing database structure or framework internals.
- Prefer consistency across endpoints over local convenience.

## Resource-first design

Design around resources and their relationships.

- Use nouns for resources.
- Prefer collections and items as the basic shape.
- Use plural collection names.
- Keep URIs resource-oriented and mostly verb-free.
- Model hierarchy conservatively; do not over-nest.
- Avoid turning every use case into a custom route.

Good pressure tests:

- Is this route describing a business resource or just an operation?
- Would a new client understand the model without reading server code?
- Is the URI stable even if internal storage changes?

## Methods over ad-hoc actions

Prefer standard HTTP methods whenever they fit.

- `GET` for retrieval
- `POST` for creation or server-side processing that does not fit standard CRUD
- `PUT` for full replacement when the contract supports it
- `PATCH` for partial update when the patch format is explicit
- `DELETE` for removal

Prefer standard methods over custom action endpoints.

If a custom action is unavoidable, make sure it is justified by domain behavior
 that does not map cleanly to standard CRUD.

## URI and route design

Review whether:

- collection routes and item routes are clearly separated
- URIs use nouns, not verbs like `/create-order`
- related resources are discoverable without deeply nested paths
- paths do not become more complex than necessary
- the route shape reflects business entities, not database tables

Avoid chatty APIs that force many tiny requests to assemble one business view.

## Request and response semantics

Use HTTP semantics deliberately.

- `GET` must be safe for reads.
- `PUT` must be idempotent.
- `PATCH` is for partial changes, not vague mutation.
- `POST` should not be overloaded casually for everything.
- Return the most specific relevant status code.

For long-running work, prefer asynchronous processing with `202 Accepted` and a
 status endpoint rather than blocking indefinitely.

## Error contract

Errors are part of the API contract.

- Use official HTTP status codes.
- Return structured error payloads consistently.
- Do not expose stack traces or internal exception details.
- Make client-fixable errors distinguishable from server failures.
- Keep error shapes predictable across endpoints.

When reviewing Flask handlers, ensure framework exceptions do not leak raw
debug-oriented responses into the public contract.

## Filtering, pagination, and partial responses

Design list endpoints for scale from the start.

- Support pagination for collections that can grow.
- Prefer cursor-oriented thinking when offset pagination becomes unstable or
  expensive.
- Keep query parameters conventional and clearly documented.
- Support filtering deliberately, not by exposing arbitrary internal fields.
- Consider field selection or partial responses when payload size is a real
  concern.

Do not make collection endpoints return unbounded datasets by default.

## Naming and payload discipline

Prefer consistent, durable naming.

- Keep path and payload naming consistent within one API.
- Do not mirror framework object names or ORM names in the public contract.
- Keep representations stable across methods for the same resource where
  practical.
- Avoid top-level payload ambiguity.

If the API already has an established casing convention, preserve it. If the
contract is still being designed, choose one convention and apply it uniformly.

## Versioning and compatibility

Compatibility discipline matters more than adding features quickly.

- Prefer additive evolution over breaking change.
- Design conservatively so common growth does not require a version bump.
- Do not break clients for internal cleanup.
- Treat every public field, status code, and route shape as part of the
  compatibility story.

If versioning is necessary, treat it as a product decision with explicit trade-
offs, not a convenience switch.

## Consistency and steady state

Method completion should mean the caller can reliably proceed.

- After successful create, the resource should be retrievable.
- After successful update, the caller should be able to read the updated state.
- After successful delete, the caller should observe the documented deleted
  behavior.
- Avoid APIs that say success before the user-visible state is coherent unless
  the endpoint is explicitly asynchronous.

## Observability and operational contract

For enterprise services, the API boundary should support operations and
troubleshooting.

- Propagate trace or correlation identifiers consistently.
- Keep request/response handling observable without leaking internals.
- Design headers and status responses so support teams can reason about
  failures.

## Flask-specific application of these rules

When working in Flask:

- Treat route functions as HTTP boundary code, not as the place to invent the
  domain model.
- Do not let Flask routing convenience justify poor resource design.
- Keep request parsing, response shaping, and status-code decisions aligned with
  the API contract.
- Keep framework error handling from defining the public API accidentally.
- Prefer explicit, contract-driven responses over whatever the framework would
  serialize by default.

## Review checklist

When using this skill, review whether:

- the API is resource-oriented rather than RPC-shaped by default
- standard HTTP methods are used correctly
- URI design is stable, readable, and not over-nested
- list endpoints have sensible pagination and filtering semantics
- status codes are specific and consistent
- error payloads are structured and safe
- the contract avoids coupling to Flask internals, ORM schema, or database
  tables
- changes are backward-compatible or explicitly managed as breaking changes
- the API shape would still make sense if the Flask implementation were replaced

## Output expectations

When using this skill, report findings and recommendations in terms of:

1. resource-model problems
2. HTTP semantic problems
3. compatibility or versioning risks
4. pagination, filtering, or payload-shape risks
5. error-contract or observability risks
6. the smallest contract-safe improvement
