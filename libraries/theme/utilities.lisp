;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(in-package :theme)

(serapeum:-> relative-luminance ((or string integer cl-colors-ng:rgb cl-colors-ng:hsv))
             real)
(defun relative-luminance (color)
  "Compute relative luminance of COLOR."
  ;; See https://www.w3.org/WAI/GL/wiki/Relative_luminance
  (loop for const in '(0.2126 0.7152 0.0722)
        for rgb-component in (list (cl-colors-ng:rgb-red (cl-colors-ng:as-rgb color))
                                   (cl-colors-ng:rgb-green (cl-colors-ng:as-rgb color))
                                   (cl-colors-ng:rgb-blue (cl-colors-ng:as-rgb color)))
        sum (* const (if (<= rgb-component 0.04045)
                         (/ rgb-component 12.92)
                         (expt (/ (+ rgb-component 0.055) 1.055) 2.4)))))

(serapeum:-> contrast-ratio ((or string integer cl-colors-ng:rgb cl-colors-ng:hsv)
                             (or string integer cl-colors-ng:rgb cl-colors-ng:hsv))
             (real 0 21)) ; Ratio between black and white.
(export-always 'contrast-ratio)
(defun contrast-ratio (color1 color2)
  "Compute contrast ratio between COLOR1 and COLOR2."
  ;; See https://www.w3.org/WAI/GL/wiki/Contrast_ratio
  (let ((ratio (/ (+ (relative-luminance color1) 0.05)
                  (+ (relative-luminance color2) 0.05))))
    (max ratio (/ ratio))))

(serapeum:-> contrasting-color ((or string integer cl-colors-ng:rgb cl-colors-ng:hsv)) string)
(export-always 'contrasting-color)
(defun contrasting-color (color)
  "Determine whether black or white best contrasts with COLOR."
  (if (>= (contrast-ratio color "white")
          (contrast-ratio color "black"))
      "white"
      "black"))
