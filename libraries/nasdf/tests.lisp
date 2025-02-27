;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(in-package :nasdf)

(export-always 'nasdf-test-system)
(defclass nasdf-test-system (nasdf-system)
  ((test-suite-args
    :initform nil
    :initarg :test-suite-args
    :reader test-suite-args
    :documentation "Arguments passed to `lisp-unit2:run-tests'."))
  (:documentation "Specialized system that runs `lisp-unit2' test suites, whose parameters are
specified by the `test-suite-args' slot."))
(import 'nasdf-test-system  :asdf-user)

(defmethod perform ((op test-op) (c nasdf-test-system))
  (destructuring-bind (&key package tags exclude-tags &allow-other-keys) (test-suite-args c)
    (let ((output (symbol-call
                   :lisp-unit2 :run-tests
                   :package package
                   :tags tags
                   :run-contexts (find-symbol* :with-summary-context :lisp-unit2)))))))

(export-always 'print-benchmark)
(defun print-benchmark (benchmark-results)
  (labels ((rat->float (num)
             (if (integerp num) num (float num)))
           (print-times (entry)
             (let ((title (first entry))
                   (attr (rest entry)))
               (unless (or (member (symbol-name title)
                                   '("RUN-TIME" "SYSTEM-RUN-TIME"))
                           (and (member (symbol-name title)
                                        '("PAGE-FAULTS" "EVAL-CALLS")
                                        :test #'string=)
                                (zerop (getf attr :average))))
                 (format t " ~a: ~,9t~a"
                         (string-downcase title)
                         (rat->float (getf attr :average)))
                 (format t "~32,8t[~a, ~a]"
                         (rat->float (getf attr :minimum))
                         (rat->float (getf attr :maximum)))
                 (format t "~56,8t(median ~a, deviation ~a, total ~a)"
                         (rat->float (getf attr :median))
                         (rat->float (getf attr :deviation))
                         (rat->float (getf attr :total)))
                 (format t "~%")))))
    (dolist (mark benchmark-results)
      (format t "~a (~a sample~:p):~%" (first mark)
              (getf (rest (second mark)) :samples))
      (mapc #'print-times (rest mark)))))
