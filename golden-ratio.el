;;; golden-ratio.el --- Automatic resizing of Emacs windows to the golden ratio

;; Copyright (C) 2012 Roman Gonzalez

;; Author: Roman Gonzalez <romanandreg@gmail.com>
;; Mantainer: Roman Gonzalez <romanandreg@gmail.com>
;; Created: 13 Oct 2012
;; Keywords: Window Resizing
;; Version: 0.0.4

;; Code inspired by ideas from Tatsuhiro Ujihisa

;; This file is not part of GNU Emacs.

;; This file is free software (MIT License)

;;; Code:
(eval-when-compile (require 'cl))

(defconst golden-ratio--value 1.618
  "The golden ratio value itself.")

(defgroup golden-ratio nil
  "Resize windows to golden ratio."
  :group 'windows)

;; Major modes that are exempt from being resized. An example of this
;; for users of Org-mode might be:
;;  ("calendar-mode") or (calendar-mode)
(defcustom golden-ratio-exclude-modes nil
  "A list of symbols or strings naming major modes.
Switching to a buffer whose major mode is a member of this list
will not cause the window to be resized to the golden ratio."
  :type '(repeat (choice symbol string))
  :group 'golden-ratio)

;; Buffer names that are exempt from being resized. An example of this
;; for users of Org-mode might be (note the leading spaces):
;;  (" *Org tags*" " *Org todo*")
(defcustom golden-ratio-exclude-buffer-names nil
  "An array of strings containing buffer names.
Switching to a buffer whose name is a member of this list
will not cause the window to be resized to the golden ratio."
  :type '(repeat string)
  :group 'golden-ratio)

(defcustom golden-ratio-inhibit-functions nil
  "List of functions to call with no arguments.
Switching to a buffer, if any of these functions returns non-nil
will not cause the window to be resized to the golden ratio."
  :group 'golden-ratio
  :type '(repeat symbol))

(defcustom golden-ratio-extra-commands
  '(windmove-left windmove-right windmove-down windmove-up)
  "List of extra commands used to jump to other window."
  :group 'golden-ratio
  :type '(repeat symbol))

(defcustom golden-ratio-recenter nil
  "Recenter window vertically and scroll right when non--nil."
  :group 'golden-ratio
  :type 'boolean)

(defcustom golden-ratio-adjust-factor 1.0
  "Adjust the width sizing by some factor. 1 is no adjustment.
   For very wide screens/frames, ie. 3400px, .4 may work well."
  :group 'golden-ratio
  :type 'integer)

(defcustom golden-ratio-wide-adjust-factor 0.8
  "Width adjustment factor for widescreens. Used when
   toggling between widescreen and regular modes."
  :group 'golden-ratio
  :type 'float)

(defcustom golden-ratio-auto-scale nil
  "Automatic width adjustment factoring. Scales the width
   of the screens to be smaller as the frame gets bigger."
  :group 'golden-ratio
  :type 'boolean)


;;; Compatibility
;;
(unless (fboundp 'window-resizable-p)
  (defalias 'window-resizable-p 'window--resizable-p))

(defun golden-ratio-toggle-widescreen ()
  (interactive)
  (if (= golden-ratio-adjust-factor 1)
      (setq golden-ratio-adjust-factor golden-ratio-wide-adjust-factor)
    (setq golden-ratio-adjust-factor 1))
  (golden-ratio))

(defun golden-ratio-adjust (a)
  "set the adjustment of window widths."
  (interactive
   (list
    (read-number "Screeen width adjustment factor: " golden-ratio-adjust-factor)))
  (setq golden-ratio-adjust-factor a)
  (golden-ratio))

(defun golden-ratio--scale-factor ()
  (if golden-ratio-auto-scale
      (- 1.0 (* (/ (- (frame-width) 100.0) 1000.0) 1.8))
    golden-ratio-adjust-factor))

(defun golden-ratio--dimensions ()
  (list (floor (/ (frame-height) golden-ratio--value))
        (floor  (* (/ (frame-width)  golden-ratio--value)
                   (golden-ratio--scale-factor)))))

(defun golden-ratio--resize-window (dimensions &optional window)
  (with-selected-window (or window (selected-window))
    (let ((nrow  (floor (- (first  dimensions) (window-height))))
          (ncol  (floor (- (second dimensions) (window-width)))))
      (when (and
             (window-resizable-p (selected-window) nrow)
             ;; don't enlarge ignored windows
             (> nrow 0))
        (enlarge-window nrow))
      (when (and (window-resizable-p (selected-window) ncol t)
                 ;; don't enlarge ignored windows
                 (> ncol 0))
        (enlarge-window ncol t)))))

(defun golden-ratio-exclude-major-mode-p ()
  "Returns non-nil if `major-mode' should not use golden-ratio."
  (or (memq major-mode golden-ratio-exclude-modes)
      (member (symbol-name major-mode)
              golden-ratio-exclude-modes)))

(defvar golden-ratio-in-progress nil
  "Avoid recursive adjustment.")

;;;###autoload
(defun golden-ratio ()
  "Resizes current window to the golden-ratio's size specs."
  (interactive)
  (when (and golden-ratio-mode
             (not golden-ratio-in-progress))
    (let ((golden-ratio-in-progress t))
      (unless (or (window-minibuffer-p)
                  (one-window-p)
                  (golden-ratio-exclude-major-mode-p)
                  (member (buffer-name)
                          golden-ratio-exclude-buffer-names)
                  (and golden-ratio-inhibit-functions
                       (loop for fun in golden-ratio-inhibit-functions
                          thereis (funcall fun))))
        (balance-windows)
        (golden-ratio--resize-window (golden-ratio--dimensions))
        (when golden-ratio-recenter
          (scroll-right) (recenter))))))

(defadvice select-window (after golden-ratio-select-window activate)
  (when golden-ratio-mode
    (golden-ratio)))

(defadvice split-window (after golden-ratio-select-window activate)
  (when golden-ratio-mode
    (golden-ratio)))

;;;###autoload
(define-minor-mode golden-ratio-mode
    "Enable automatic window resizing with golden ratio."
  :lighter " Golden"
  :global t)


(provide 'golden-ratio)

;;; golden-ratio.el ends here
