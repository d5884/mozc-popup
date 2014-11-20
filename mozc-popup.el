;;; mozc-popup.el --- Mozc with popup

;; Copyright (C) 2014  Daisuke Kobayashi

;; Author: Daisuke Kobayashi <d5884jp@gmail.com>
;; Version: 0.1
;; Keywords: i18n, extentions

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package implements popup-style for candidates displaying by
;; `popup.el' for' `mozc'.

;;; Usage: 

;; (require 'mozc-popup)
;; (setq mozc-candidate-style 'popup) ; select popup style.

;; 

;;; Code:

(require 'mozc)
(require 'popup)

(push '(popup
	(clean-up . mozc-cand-popup-clean-up)
	(clear . mozc-cand-popup-clear)
	(update . mozc-cand-popup-update))
      mozc-candidate-dispatch-table)

(defvar-local mozc-cand-popup nil)

(defconst mozc-cand-popup-shortcut-spacer ". ")
(defconst mozc-cand-popup-description-space 3)

(defun mozc-cand-popup-update (candidates)
  (let* ((focused-index (mozc-protobuf-get candidates 'focused-index))
	 (candidates-size (mozc-protobuf-get candidates 'size))
	 (footer-label (or (mozc-protobuf-get candidates 'footer 'label) " "))
	 (index-visible (mozc-protobuf-get candidates 'footer 'index-visible))
	 (max-width (string-width footer-label))
	 (items (mapcar
		 (lambda (candidate)
		   (let ((index (mozc-protobuf-get candidate 'index))
			 (value (mozc-protobuf-get candidate 'value))
			 (description (mozc-protobuf-get candidate 'annotation 'description))
			 (shortcut (mozc-protobuf-get candidate 'annotation 'shortcut)))
		     (setq max-width (max (+ (string-width value)
					     (if shortcut
						 (+ (string-width
						     mozc-cand-popup-shortcut-spacer)
						    (string-width shortcut)) 0)
					     (if description
						 (+ mozc-cand-popup-description-space
						    (string-width description)) 0))
					  max-width))
		     (popup-make-item (if shortcut
					  (concat shortcut
						  mozc-cand-popup-shortcut-spacer
						  value)
					value)
				      :face (if (zerop (logand index 1))
						'mozc-cand-overlay-even-face
					      'mozc-cand-overlay-odd-face)
				      :summary description
				      )))
		 (cdr (assq 'candidate candidates)))))
    (add-to-list
     'items
     (popup-make-item footer-label
		      :face 'mozc-cand-overlay-footer-face
		      :summary (when (and index-visible focused-index candidates-size)
				 (format "%d/%d" (1+ focused-index) candidates-size)))
     t)

    (mozc-cand-popup-clear)
    (setq mozc-cand-popup (popup-create
			   mozc-preedit-point-origin
			   max-width (length items)
			   :around t
			   :margin-left 1
			   :margin-right 1
			   :selection-face (if focused-index
					       'mozc-cand-overlay-focused-face
					     'mozc-cand-overlay-footer-face)
			   :summary-face 'mozc-cand-overlay-footer-face))
    (popup-set-list mozc-cand-popup items)
    (if focused-index
	(popup-select mozc-cand-popup (% focused-index 9))
      ;; when not focused, select footer at once.
      (popup-select mozc-cand-popup (1- (length items))))
    (popup-draw mozc-cand-popup)
    ))

(defun mozc-cand-popup-clear ()
  (popup-delete mozc-cand-popup))

(defun mozc-cand-popup-clean-up ()
  (mozc-cand-popup-clear))


(provide 'mozc-popup)

;;; mozc-popup.el ends here
