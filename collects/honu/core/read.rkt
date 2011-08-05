#lang racket/base

(require rackunit)
(require parser-tools/lex
         (prefix-in : parser-tools/lex-sre))
(require racket/match
         (for-syntax racket/base
                     syntax/parse))

(define-tokens honu-tokens (number identifier string))

(define-empty-tokens honu-empty-tokens
                     [eof fail whitespace
                      left-parens right-parens
                      parse-error
                      left-bracket right-bracket
                      left-brace right-brace
                      block-comment
                      end-of-line-comment])

(define-lex-abbrev digit (:/ #\0 #\9))
(define-lex-abbrev identifier-first-character (:or (:/ #\a #\z)
                                                   (:/ #\A #\Z)))
(define-lex-abbrev identifier-character (:or identifier-first-character
                                             digit))
(define-lex-abbrev identifier (:: identifier-first-character
                                  (:* identifier-character)))
(define-lex-abbrev number (:+ digit))
(define-lex-abbrev string-character (:or (:: #\\ any-char)
                                         (:~ #\")))
(define-lex-abbrev string (:: #\" (:* string-character) #\"))
(define-lex-abbrev block-comment (:: "/*"
                                     (complement (:: any-string "*/" any-string))
                                     "*/"))

(define-lex-abbrev line-comment (:: (:or "#" "//")
                                    (:* (:~ "\n"))
                                    ;; we might hit eof before a \n
                                    (:? "\n")))

(define (replace-escapes string)
  (define replacements '([#px"\\\\n" "\n"]
                         [#px"\\\\t" "\t"]))
  (for/fold ([string string])
            ([replace replacements])
    (define pattern (car replace))
    (define with (cadr replace))
    (regexp-replace* pattern string with)))

(provide honu-lexer)
(define honu-lexer
  (lexer-src-pos
    [(eof) (token-eof)]
    #;
    [line-comment (token-whitespace)]
    [(:or "#" "//") (token-end-of-line-comment)]
    ["\n" (token-whitespace)]
    [number (token-number (string->number lexeme))]
    #;
    [block-comment (token-whitespace)]
    ["/*" (token-block-comment)]
    ["." (token-identifier '|.|)]
    ["," (token-identifier '|,|)]
    ["!" (token-identifier '!)]
    ["=" (token-identifier '=)]
    ["*" (token-identifier '*)]
    ["/" (token-identifier '/)]
    ["+" (token-identifier '+)]
    [";" (token-identifier '|;|)]
    ;; strip the quotes from the resulting string
    ;; TODO: find a more optimal way
    [string (let ()
              (define raw (substring (substring lexeme 1)
                                     0 (- (string-length lexeme) 2)))
              (token-string (replace-escapes raw)))]
    ["(" (token-left-parens)]  [")" (token-right-parens)]
    ["[" (token-left-bracket)] ["]" (token-right-bracket)]
    ["{" (token-left-brace)]   ["}" (token-right-brace)]
    [identifier (token-identifier (string->symbol lexeme))]
    [(union " " "\t") (token-whitespace)]
    [any-char (token-parse-error)]))

(define-syntax (define-token? stx)
  (syntax-parse stx
    [(_ name)
     (define name? (datum->syntax #'name (string->symbol
                                           (format "token-~a?"
                                                 (symbol->string
                                                   (syntax->datum #'name))))
                                  #'name))
     (with-syntax ([name? name?])
       #'(begin
           (provide name?)
           (define (name? token)
             (equal? 'name (token-name token)))))]))

(define-syntax-rule (define-tokens? name ...)
                    (begin
                      (define-token? name) ...))

(define-tokens? eof whitespace end-of-line-comment number string
                block-comment parse-error
                identifier left-parens right-parens
                left-bracket right-bracket
                left-brace right-brace)

;; returns #t if an entire comment was read (with an ending newline)
(define (read-until-end-of-line input)
  (define (finish? what)
    (or (eof-object? what)
        (= (char->integer #\newline) what)))
  ;; #t if read a #\newline, otherwise #f
  (define (clean-end? what)
    (if (eof-object? what)
      #f
      (= (char->integer #\newline) what)))
  (let loop ()
    (define what (read-byte input))
    (if (not (finish? what))
      (loop)
      (clean-end? what))))

;; returns #t if an entire block comment was read
(define (read-block-comment port)
  (define comment-lexer
    (lexer
      ["/*" 'nest]
      ["*/" 'done]
      [(eof) eof]
      [any-char 'continue]))

  (define (finish? what)
    (or (eq? 'done what)
        (eof-object? what)))

  (let loop ([nesting 1])
    (define what (comment-lexer port))
    (cond
      [(eq? what 'nest) (loop (add1 nesting))]
      [(eq? what 'done) (if (> nesting 1)
                          (loop (sub1 nesting))
                          #t)]
      [(eof-object? what) #f]
      [else (loop nesting)])))

;; read characters from a port and return a stream of tokens
(define (read-tokens port)
  (let loop ([tokens '()])
    (define next (honu-lexer port))
    ;; (printf "next ~a\n" next)
    (match next
      [(struct* position-token ([token (? token-eof?)] [start-pos start] [end-pos end]))
       ;; (printf "done lexing\n")
       (reverse tokens)]
      [(struct* position-token ([token (? token-end-of-line-comment?)]
                                 [start-pos start]
                                 [end-pos end]))
       (read-until-end-of-line port)
       (loop tokens)]
       [(struct* position-token ([token (? token-block-comment?)]
                                 [start-pos start]
                                 [end-pos end]))
        (read-block-comment port)
        (loop tokens)]
       [(struct* position-token ([token (? token-whitespace?)] [start-pos start] [end-pos end]))
        (loop tokens)]
       [else (loop (cons next tokens))]
       #;
       [(position-token token start end)
        ;; (printf "next is ~a eof? ~a\n" token (token-eof? token))
        (loop (cons token tokens))])))

;; symbols that can be used for colors
;;   symbol
;;   keyword
;;   comment
;;   string
;;   constant
;;   parenthesis
;;   error
;;   other
(define (honu-name->color token-name)
  ;; (printf "Get honu color for ~a\n" token-name)
  (case token-name
    [(number) 'constant]
    [(string) 'string]
    [(parens) 'parenthesis]
    [(identifier) 'symbol]
    [else 'other]))

;; implements a lexer that the colorer in drracket expects
;; FIXME: color comments
(provide color-lexer)
(define (color-lexer port offset mode)
  ;; (printf "Parse at token ~a mode is ~a\n" offset mode)
  (define lexeme (honu-lexer port))
  (define need-backup (if mode mode 0))
  (match lexeme
    [(position-token token start end)
     ;; (printf "Lexed ~a\n" token)
     (define (encloser kind)
       (values token 'parens kind
               (position-offset start)
               (position-offset end)
               need-backup mode))

     ;; (printf "Get token for at ~a\n" (position-offset start))
     (cond
       [(token-eof? token)
        (values token 'eof #f
                (position-offset start)
                (position-offset end)
                need-backup mode)]
       [(token-parse-error? token)
        (define backup (if mode (add1 mode) 1))
        (values token 
                'error
                #f
                (position-offset start)
                (position-offset end)
                backup backup)]
       [(token-end-of-line-comment? token)
        (read-until-end-of-line port)
        (define-values (line column position) (port-next-location port))
        (values #f 'comment #f
                (position-offset start)
                position
                need-backup need-backup)]
       [(token-block-comment? token)
        (read-block-comment port)
        (define-values (line column position) (port-next-location port))
        (values #f 'comment #f
                (position-offset start)
                position
                need-backup need-backup)]
       [(token-left-parens? token)  (encloser '|(|)]
       [(token-right-parens? token) (encloser '|)|)]
       [(token-left-bracket? token) (encloser '|[|)]
       [(token-right-bracket? token)(encloser '|]|)]
       [(token-left-brace? token)   (encloser '|{|)]
       [(token-right-brace? token)  (encloser '|}|)]
       [else (values (format "~a" (token-value token))
                     (honu-name->color (token-name token))
                     #f
                     (position-offset start)
                     (position-offset end)
                     need-backup mode)])]))

;; convert a string to a stream of tokens
(define (lex-string input)
  (read-tokens (open-input-string input)))

;; make a syntax object out of some symbol and a position-token
(define (make-syntax datum token source)
  (match token
    [(position-token token start end)
     (datum->syntax #f datum
                    (list source (position-line start)
                          (position-col start)
                          (position-offset start)
                          (- (position-offset end)
                             (position-offset start))))]))

(define (make-syntax-from-token token source)
  (match token
    [(position-token datum start end)
     (make-syntax (token-value datum) token source)])) 

;; converts a stream of tokens to a tree
(define (parse source tokens)
  (define (is-first-token what? tokens)
    (match tokens
      [(list (position-token token start end) rest ...)
       (what? token)]
      [else #f]))

  (define (do-atom current tokens table)
    (do-parse (cons (make-syntax-from-token (car tokens) source) current)
              (cdr tokens)
              table))
  (define (atom? tokens)
    (is-first-token (lambda (token)
                      (or (token-identifier? token)
                          (token-string? token)
                          (token-number? token)))
                    tokens))

  (define (do-empty current tokens table)
    (reverse current))
  
  (define (left-parens? tokens)
    (is-first-token token-left-parens? tokens))
  (define (right-parens? tokens)
    (is-first-token token-right-parens? tokens))
  (define (left-bracket? tokens)
    (is-first-token token-left-bracket? tokens))
  (define (right-bracket? tokens)
    (is-first-token token-right-bracket? tokens))
  (define (left-brace? tokens)
    (is-first-token token-left-brace? tokens))
  (define (right-brace? tokens)
    (is-first-token token-right-brace? tokens))

  (define (do-end-encloser current tokens table)
    (values (reverse current) (cdr tokens)))

  (define (add-dispatch-rule table rule)
    (cons rule table))
  (define ((do-fail kind) current tokens table)
    (define line (syntax-line (car current)))
    (define column (add1 (+ (syntax-span (car current))
                            (syntax-column (car current)))))
    (error 'parse "expected a ~a character at line ~a column ~a" kind line column))
  ;; add a rule to the dispatch table to expect an ending token then
  ;; parse the sub-tree and continue
  (define (make-encloser head failure-name next)
    (lambda (current tokens table)
      (define added (add-dispatch-rule
                      (add-dispatch-rule dispatch-table [list next do-end-encloser])
                    [list null? (do-fail failure-name)]))
      (define-values (sub-tree unparsed)
                     (do-parse (list (make-syntax head (car tokens) source))
                               (cdr tokens) added))
      (do-parse (cons sub-tree current) unparsed table)))

  (define do-left-parens (make-encloser '#%parens ")" right-parens?))
  (define do-left-bracket (make-encloser '#%bracket "}" right-bracket?))
  (define do-left-brace (make-encloser '#%braces "]" right-brace?))
  
  (define dispatch-table (list [list atom? do-atom]
                               [list left-parens? do-left-parens]
                               [list left-bracket? do-left-bracket]
                               [list left-brace? do-left-brace]
                               [list null? do-empty]))

  (define (do-parse current tokens table)
    (define (fail tokens)
      (if (null? tokens)
        (error 'parse "error while parsing")
        (let ([first (car tokens)])
          ;; hack to get the current failure behavior
          (do-parse current '() table)
          (define line (position-line (position-token-start-pos first)))
          (define column (position-col (position-token-start-pos first)))
          (error 'parse "error while parsing on line ~a column ~a" line column))))
    ;; (printf "do parse ~a [tokens] ~a table ~a\n" (strip current) (strip tokens) table)
    (let loop ([use table])
      (cond
        [(null? use) (fail tokens)]
        [(let ([dispatcher (caar use)])
           (dispatcher tokens))
         (define action (cadar use))
         (action current tokens table)]
        [else (loop (cdr use))])))

  (if (null? tokens)
    eof
    (datum->syntax #f (do-parse '() tokens dispatch-table)
                   #f)))

;; strip the source location from the position tokens
(define (strip tokens)
  (for/list ([token tokens])
    (match token
      [(position-token token start end) token]
      [else token])))

(provide honu-read-syntax)
(define (honu-read-syntax [name #f] [port (current-input-port)])
  (parse name (read-tokens port)))

(provide honu-read)
(define (honu-read [port (current-input-port)])
  (syntax->datum (honu-read-syntax #f port)))

(define (count-lines port)
  (port-count-lines! port)
  port)

(test-case
  "Basic tests"
  (check-equal? (strip (lex-string "5"))
                (list (token-number 5)))
  (check-equal? (strip (lex-string "5 8"))
                (list (token-number 5) (token-number 8)))
  (check-equal? (strip (lex-string "hello"))
                (list (token-identifier 'hello)))
  (check-equal? (strip (lex-string "()"))
                (list (token-left-parens)
                      (token-right-parens)))
  (check-equal? (strip (lex-string "()[]{}"))
                (list (token-left-parens)
                      (token-right-parens)
                      (token-left-bracket)
                      (token-right-bracket)
                      (token-left-brace)
                      (token-right-brace)))
  (check-equal? (strip (lex-string "foo // 5"))
                (list (token-identifier 'foo)))
  (check-equal? (strip (lex-string "foo // 5
                            bar"))
                (list (token-identifier 'foo)
                      (token-identifier 'bar)))
  (check-equal? (strip (lex-string "f(2)"))
                (list (token-identifier 'f)
                      (token-left-parens)
                      (token-number 2)
                      (token-right-parens)))
  (check-equal? (strip (lex-string "8 /* aosidfjasdf329023 */ 5"))
                (list (token-number 8)
                      (token-number 5)))
  (check-equal? (strip (lex-string "\"hello\""))
                (list (token-string "hello")))
  ;; FIXME: how can we write a string with an escaped character in it?
  #;
  (check-equal? (strip (lex-string "\"hel\\\\\"lo\""))
                (list (token-string "hel\"lo")))
  (check-equal? (honu-read (open-input-string "f(5)"))
                '(f (#%parens 5)))
  (check-exn exn:fail? (lambda ()
                         (honu-read (count-lines (open-input-string "({)}")))))
  )