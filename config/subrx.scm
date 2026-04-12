;;;
;;; Commentary:
;;;
;;; Scheme language extensions and syntactic sugar for GuixOS config system.
;;;
(define-module (config subrx)
  #:export (define-parameter))


;;;
;;; Convenient Dynamic Scope
;;;
;;; Usage:
;;;   (define-parameter %my-param default-value)
;;;
;;;   ;; Access the current value:
;;;   (%my-param)
;;;
;;;   ;; Override temporarily with parameterize:
;;;   (parameterize ((%my-param new-value))
;;;     ...)
;;;
(define-syntax define-parameter
  (syntax-rules ()
    ((define-parameter name value)
     (define name (make-parameter value)))))
