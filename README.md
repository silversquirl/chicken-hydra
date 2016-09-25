# Hydra

A stupid-simple database adapter for CHICKEN Scheme.

## What is Hydra?

Imagine your favourite ORM, then strip down almost all of its features
and make it use functional programming. That's basically what Hydra is:
a very minimal, yet very powerful database adapter that does everything
you need and nothing you don't.

Hydra allows you to represent queries as S-expressions, allowing you to
interface with databases without needing to write a single line of SQL.

Here's an example:

```scheme
(use (prefix hydra db:))

;; Open the database
(define db
  (db:open 'sqlite3
           '((dbname . "test.sqlite3")))

;; Define a model (yes, it's just a record type)
(define-record foo bar baz)

;; Save some data to the db
(db:save (make-foo 42 "Hello, world!"))
(db:save (make-foo 1337 "h4x0r"))

;; Perform some queries
(print (foo-baz (db:get db 'foo '(= bar 42))))

(for-each
 (lambda (item)
   (print (foo-baz item)))

 (db:get-all db 'foo '(> bar 20)))
```

## What can Hydra currently do?

Currently, Hydra has a very limited featureset:

  - Get data from a database
  - Save new records into a database

Things that are planned, but not yet implemented:

  - Update existing records
  - Remove records
  - List/vector support
  - Create database schemas

