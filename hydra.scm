(module hydra
    (condition->sql
     build-select-query
     row->record-type
     get
     get-all
     save)

  (import chicken scheme)
  (use dbi
       lolevel
       matchable
       srfi-1
       srfi-13
       data-structures)
  (reexport dbi)

  (define (condition->sql condition)
    (let* ((params '())
           (sql (map
                 (lambda (part)
                   (cond
                     ((string? part) part)
                     ((list? part)
                      (set! params (append params part))
                      "?")
                     ((symbol? part) (symbol->string part))
                     ((number? part) (number->string part))
                     ((boolean? part) (if part "TRUE" "FALSE"))))

                 (let cond->sql ((condition condition))
                   (match condition
                     (('or . subconditions)
                      `("("
                        ,@(fold
                           (lambda (i seed)
                             (append seed i))
                           '()
                           (intersperse
                            (map cond->sql subconditions)
                            '(" OR ")))
                        ")"))

                     (('and . subconditions)
                      `("("
                        ,@(fold
                           (lambda (i seed)
                             (append seed i))
                           '()
                           (intersperse
                            (map cond->sql subconditions)
                            '(" AND ")))
                        ")"))

                     (('not subcondition)
                      `("(NOT "
                        ,@(cond->sql subcondition)
                        ")"))

                     (('= property param)
                      `(,property " = " (,param)))

                     (('> property param)
                      `(,property " > " (,param)))

                     (('< property param)
                      `(,property " < " (,param)))

                     (('>= property param)
                      `(,property " >= " (,param)))

                     (('<= property param)
                      `(,property " <= " (,param)))

                     (('between property param1 param2)
                      `("("
                        ,property
                        " BETWEEN "
                        (,param1)
                        " AND "
                        (,param2)
                        ")")))))))

    (values (string-concatenate sql)
            params)))

  (define (build-select-query table-name condition)
    ;; Create a SELECT query to get things matching condition
    (if (null? condition)
        (list (string-append "SELECT * FROM "
                             table-name
                             ";"))
        (let-values (((sql params) (condition->sql condition)))
          (list
           (string-append "SELECT * FROM "
                          table-name
                          " WHERE "
                          sql
                          ";")
           params))))

  (define (row->record-type row record-type)
    ;; Convert a row to a record type.
    ;; The row and record type's values _must_ be in the same order.
    (and row
         (apply make-record-instance
                record-type
                (vector->list row))))

  (define (get-table-name record-type)
    ;; Get the name of a record type's database table
    (string-append (symbol->string record-type)
                   "s"))

  (define (get db record-type condition #!optional table-name)
    ;; Return a record type containing data matching condition.
    (row->record-type
     (apply get-one-row
            db
            (build-select-query
             (or table-name
                 (get-table-name record-type))
             condition))
     record-type))

  (define (get-all db record-type condition #!optional table-name)
    ;; Return record types containing data matching condition.
    (map (cut row->record-type <> record-type)
         (apply get-rows
                db
                (build-select-query
                 (or table-name
                     (get-table-name record-type))
                 condition))))

  (define (save db record-instance #!optional table-name)
    (let ((ri-len (record-instance-length record-instance)))
      (apply exec
             db
             (string-append
              "INSERT INTO "
              (or table-name
                  (get-table-name
                   (record-instance-type record-instance)))
              " VALUES ("
              (string-join (make-list ri-len "?")
                           ", ")
              ");")

             (list-tabulate ri-len
                            (cut record-instance-slot
                                 record-instance
                                 <>))))))

