;;;; dot-egclrc.lisp -> .egclrc - EGCL Initialization File
;;;;
;;;; Read only by an interactive REPL; --eval, --load and --no-init
;;;; runs skip it.

(require :asdf)

;;; ocicl
;;;
;;; Load the runtime if installed, then make ./ocicl/ shadow the
;;; inherited ASDF registry.  Launch from the directory holding
;;; ocicl.csv (code/clide).
#-ocicl
(let ((ocicl-runtime (uiop:xdg-data-home #P"ocicl/ocicl-runtime.lisp")))
  (when (probe-file ocicl-runtime)
    (load ocicl-runtime)))

(asdf:initialize-source-registry
 (list :source-registry
       (list :directory (uiop:getcwd))
       ;; Systems installed by ocicl in ./ocicl/ shadow the inherited
       ;; ASDF registry
       (list :tree (uiop:subpathname (uiop:getcwd) "ocicl/"))
       :inherit-configuration))

;; Show what ocicl is doing, when its runtime is loaded
#+ocicl
(setf ocicl-runtime:*verbose* t)

(setf *print-pretty* t)
