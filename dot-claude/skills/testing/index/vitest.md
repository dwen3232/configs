# Vitest Patterns

## Setup: inline vs. extracted function

Inline setup when each test differs meaningfully — visibility beats brevity:

```ts
test('removes a todo by id', () => {
  const list = createTodoList()
  const todo = list.add('buy milk')
  list.remove(todo.id)
  expect(list.getAll()).toHaveLength(0)
})
```

Extract a `setup()` function when setup is genuinely identical across many
tests. Return values explicitly so each test declares what it uses:

```ts
function setup() {
  const list = createTodoList()
  const todo = list.add('buy milk')
  return { list, todo }
}

test('removes a todo by id', () => {
  const { list, todo } = setup()
  list.remove(todo.id)
  expect(list.getAll()).toHaveLength(0)
})

test('keeps other todos when removing one', () => {
  const { list, todo } = setup()
  list.add('walk dog')
  list.remove(todo.id)
  expect(list.getAll()).toHaveLength(1)
})
```

Use `beforeEach` only for cleanup that must run even when a test fails:

```ts
afterEach(() => {
  vi.useRealTimers()
})
```

## Grouping with describe

Group by function or method. Keep nesting at one level — avoid nested
`describe` blocks with their own `beforeEach` hooks:

```ts
describe('add', () => {
  test('returns the new todo', () => { /* ... */ })
  test('throws when text is empty', () => { /* ... */ })
})

describe('remove', () => {
  test('removes the todo by id', () => { /* ... */ })
  test('throws when id does not exist', () => { /* ... */ })
})
```

## One behavior per test

```ts
// bad — two behaviors, one name
test('adds a todo and increments the count', () => {
  list.add('buy milk')
  expect(list.getAll()).toHaveLength(1)
  expect(list.count()).toBe(1)
})

// good
test('adds the todo to the list', () => {
  list.add('buy milk')
  expect(list.getAll()).toHaveLength(1)
})

test('increments the count when a todo is added', () => {
  list.add('buy milk')
  expect(list.count()).toBe(1)
})
```

## Behavioral testing

Assert on outputs, not on internal mechanics:

```ts
// bad — coupled to internal call
test('formats price correctly', () => {
  const spy = vi.spyOn(Intl, 'NumberFormat')
  formatPrice(10, 'USD')
  expect(spy).toHaveBeenCalledWith('en-US', { style: 'currency', currency: 'USD' })
})

// good — asserts observable output
test('formats price correctly', () => {
  expect(formatPrice(10, 'USD')).toBe('$10.00')
})
```

## Mocking external dependencies

Mock at the boundary — network, third-party SDKs, filesystem. Do not mock
modules internal to your own codebase:

```ts
// mocking an external HTTP client
vi.mock('../lib/httpClient', () => ({
  post: vi.fn(),
}))

import { post } from '../lib/httpClient'
import { createUser } from './userService'

test('sends a POST request when creating a user', async () => {
  vi.mocked(post).mockResolvedValue({ id: '123' })

  await createUser({ name: 'Alice', email: 'alice@example.com' })

  expect(post).toHaveBeenCalledWith('/users', {
    name: 'Alice',
    email: 'alice@example.com',
  })
})
```

Test through your own internal classes rather than mocking them. If you find
yourself wanting to mock an internal dependency, consider whether the boundary
is in the right place.

## Assert the full call signature

Always assert the complete argument list on external mock calls — never just
`.toHaveBeenCalled()`. The call to an external system *is* the behavior under
test; an incomplete assertion lets the wrong data silently pass through.

If you only care about specific arguments, use `expect.any()` for the rest
rather than omitting the assertion:

```ts
// bad — proves the call happened, nothing about what was sent
expect(post).toHaveBeenCalled()

// bad — ignores the second argument entirely
expect(post).toHaveBeenCalledWith('/users', expect.anything())

// good — full signature; expect.any() for fields you don't control
expect(post).toHaveBeenCalledWith('/users', {
  name: 'Alice',
  email: 'alice@example.com',
  createdAt: expect.any(String),
  requestId: expect.any(String),
})
```

This applies equally to injected dependencies:

```ts
// bad
expect(sendEmail).toHaveBeenCalled()

// good — even if only the address matters, still assert the full shape
expect(sendEmail).toHaveBeenCalledWith(
  'alice@example.com',
  expect.stringContaining('Welcome'),
)
```

## Injected dependencies

When a dependency is injected rather than imported, use `vi.fn()` directly:

```ts
test('calls the mailer with the right address and subject', async () => {
  const sendEmail = vi.fn().mockResolvedValue(undefined)
  const service = new NotificationService({ sendEmail })

  await service.notifyUser('alice@example.com', 'Welcome')

  expect(sendEmail).toHaveBeenCalledWith(
    'alice@example.com',
    expect.stringContaining('Welcome'),
  )
})
```

## Controlling time

```ts
beforeEach(() => {
  vi.useFakeTimers()
})

afterEach(() => {
  vi.useRealTimers()
})

test('expires a session after 30 minutes', () => {
  const session = createSession()
  vi.setSystemTime(Date.now() + 31 * 60 * 1000)
  expect(session.isExpired()).toBe(true)
})
```

## Parameterized tests

Use `test.each` for edge cases that share the same logic but differ only in
input/output:

```ts
test.each([
  { input: '25',   expected: 25 },
  { input: '25.9', expected: 25 },
  { input: '0',    expected: 0  },
  { input: '150',  expected: 150 },
])('parseAge("$input") returns $expected', ({ input, expected }) => {
  expect(parseAge(input)).toBe(expected)
})

test.each(['-1', '151', 'abc', ''])(
  'parseAge("%s") throws for invalid input',
  (input) => {
    expect(() => parseAge(input)).toThrow('Invalid age')
  },
)
```

## Error paths

```ts
test('throws when text is empty', () => {
  const list = createTodoList()
  expect(() => list.add('')).toThrow('Todo text cannot be empty')
})

test('throws when text is only whitespace', () => {
  const list = createTodoList()
  expect(() => list.add('   ')).toThrow('Todo text cannot be empty')
})
```

## Partial matching

Use `expect.objectContaining` and `expect.arrayContaining` when only some
fields matter:

```ts
test('includes the user id in the response', async () => {
  const result = await createUser({ name: 'Alice' })
  expect(result).toEqual(expect.objectContaining({ id: expect.any(String) }))
})
```
