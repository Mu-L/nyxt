;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(in-package :nyxt)
;; Packagers are welcome to customize the `defparameter's to suit the host system.

(export-always '*options*)
(defvar *options* '()
  "The list of command line options.")

(defvar *run-from-repl-p* t
  "If non-nil, don't terminate the Lisp process when quitting the browser.
This is useful when the browser is run from a REPL so that quitting does not
close the connection.")

(export-always '*debug-on-error*)
(defvar *debug-on-error* nil
  "Whether the Nyxt-internal debugger pops up when an error happens.
Allows the user to fix immediate errors in runtime, given enough understanding.")

(defvar *restart-on-error* nil
  "Control variable to enable accurate error reporting during startup.
Implementation detail.
For user-facing controls, see `*run-from-repl-p*' and `*debug-on-error*'.")

(export-always '*open-program*)
(declaim (type (or string null) *open-program*))
(defvar *open-program*
  #+darwin "open"
  #+(and (or linux bsd) (not darwin)) "xdg-open"
  #-(or linux bsd darwin) nil
  "The program to open unsupported files with.")

(export-always '*headless-p*)
(defvar *headless-p* nil
  "If non-nil, don't display anything.
This is convenient for testing purposes or to drive Nyxt programmatically.")

(export-always '*quitting-nyxt-p*)
(defvar *quitting-nyxt-p* nil
  "When non-nil, Nyxt is quitting.")

(export-always '*browser*)
(defvar *browser* nil
  "The entry-point object to a complete instance of Nyxt.
It can be initialized with

  (setf *browser* (make-instance 'browser))

It's possible to run multiple interfaces of Nyxt at the same time.  You can
let-bind *browser* to temporarily switch interface.")

(export-always '*swank-port*)
(defvar *swank-port* 4006
  "The port that Swank will open a new server on (default Emacs SLIME port
is 4005, default set to 4006 in Nyxt to avoid collisions).")

(export-always '*slynk-port*)
(defvar *slynk-port* 4006
  "The port that Slynk will open a new server on (default Emacs Sly port
is 4005, default set to 4006 in Nyxt to avoid collisions).")

(declaim (type (maybe renderer) *renderer*))
(defparameter *renderer* nil
  ;; TODO: Switching renderer does not seem to work anymore.
  ;; Maybe issue at the library level?
  "The renderer used by Nyxt.
It can be changed between two runs of Nyxt when run from a Lisp REPL.
Example:

  (nyxt:quit)
  (setf nyxt::*renderer* (make-instance 'nyxt/renderer/gtk:gtk-renderer))
  (nyxt:start)")

(export-always '+version+)
(alex:define-constant +version+
    (or (uiop:getenv "NYXT_VERSION")
        (let ((version-from-git-tag
                (ignore-errors
                 (uiop:with-current-directory ((asdf:system-source-directory :nyxt))
                   (uiop:run-program (list "git" "describe" "--always" "--tags")
                                     :output '(:string :stripped t)))))
              (version-from-asdf
                (asdf/component:component-version (asdf:find-system :nyxt))))
          (if (uiop:version< (first (str:split "-" version-from-git-tag))
                             version-from-asdf)
              version-from-asdf
              version-from-git-tag)))
  :test #'equal
  :documentation "Nyxt version.
Fetched from ASDF (higher priority) or Git tag.

Can be overridden with NYXT_VERSION environment variable on build systems
relying on neither ASDF nor Git.

`version' and Nyxt-related feature expressions all rely on `+version+'.")

(defun parse-version (version)
  "Helper for `version' to parse any version string, not only `+version+'.

Return 5 values:
- MAJOR version as integer,
- MINOR version as integer,
- PATCH version as integer,
- current COMMIT as string.
- and COMMITS as number of commits from the last release,

Return NIL on error."
  (ignore-errors
   ;; Pre-releases are falling outside the conventional version values.
   (if (search "pre-release" version)
       (parse-integer (first (str:split "-" version)))
       (destructuring-bind (version &optional commits commit)
           (str:split "-" version)
         (let* ((integer-commits-p (and commits (every #'digit-char-p commits)))
                (commits-number (if integer-commits-p
                                    (parse-integer commits)
                                    0))
                (commit (if integer-commits-p
                            commit
                            commits)))
           (destructuring-bind (&optional major minor patch)
               (uiop:parse-version version)
             (values major minor patch commit commits-number)))))))

(defun version ()
  "Get the version of Nyxt parsed as multiple values.
See `parse-version' for details on the returned values."
  (parse-version +version+))

(multiple-value-bind (major minor patch commit commits)
    (version)
  (flet ((push-feature (string)
           (pushnew (intern (uiop:strcat "NYXT-" (string-upcase (princ-to-string string))) "KEYWORD") *features*)))
    (when +version+
      (push-feature +version+))
    (when (search "pre-release" +version+)
      (push-feature (format nil "~a-pre-release" major))
      (push-feature (str:join "-" (subseq (str:split "-" +version+) 0 4))))
    (when major
      (push-feature major))
    (when minor
      (push-feature (format nil "~a.~a" major minor)))
    (when patch
      (push-feature (format nil "~a.~a.~a" major minor patch)))
    (when commit
      (push-feature (string-upcase commit)))
    (when (and commits (not (zerop commits)))
      (push-feature "UNSTABLE"))))

(export-always '*static-data*)
(defvar *static-data* (make-hash-table :test 'equal)
  "Static data for usage in Nyxt.")

(defun load-assets (subdirectory read-function)
  (mapcar (lambda (i)
            (setf (gethash (file-namestring i) *static-data*)
                  (funcall read-function i)))
          (uiop:directory-files (asdf:system-relative-pathname :nyxt (format nil "assets/~a/" subdirectory)))))

(load-assets "fonts" #'alex:read-file-into-byte-vector)
(load-assets "glyphs" #'alex:read-file-into-string)
