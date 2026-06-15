(define-module (files gubar blocks date-time-2)
  #:use-module (gubar gublock)
  #:use-module (gubar swaybar-protocol)
  #:use-module (fibers)
  #:use-module ((fibers timers) #:select ((sleep . fsleep)))
  #:export (date-time-2))

(define* (date-time-2 #:key (format "%c") (signal 6))
  "Display the current date and time, updating on precise second boundaries.
Unlike interval-based polling, a fiber sleeps to the next whole second
using gettimeofday, eliminating clock drift.
Optional #:format sets the strftime format string (default: \"%c\").
Optional #:signal N sets the SIGRTMIN offset (default: 6)."
  (let ((pid (getpid)))
    (spawn-fiber
     (lambda ()
       (let loop ()
         ;; Sleep until next second boundary
         (let* ((now (gettimeofday))
                (remaining (- 1.0 (/ (cdr now) 1000000.0))))
           (fsleep remaining)
           (kill pid (+ signal SIGRTMIN))
           (loop))))
     #:parallel? #t)
    (gublock
     #:interval 'persistent
     #:signal signal
     #:procedure
     (lambda (block)
       (set-block-full-text!
        block
        (strftime format (localtime (current-time))))
       block))))
