;;; cedille-mode-synthesis.el --- description -*- lexical-binding: t; -*-

;;; Code:

(require 'subr-x)

(defun get-span-type(data)
  "Filter out special attributes from the data in a span"
  (cdr (assoc 'expected-type data)))

(defun get-span-name(data)
  (cdr (assoc 'name data)))

(defun desambiguate-lambdas(term)
  (setq start 0)
  ;; make sure the hashtable will use string equality instead of object equality
  (setq vars-hash (make-hash-table :test 'equal))

  (while (string-match "λ \\([^:]*?\\) :" term start)
    (setq var (match-string 1 term))
    (setq varocc (gethash var vars-hash))
    (if (not varocc)
        (puthash var 1 vars-hash)
      (puthash var (1+ varocc) vars-hash)
      (setq newvar (concatenate 'string var (format "%d" varocc)))
      (setq rep0 (concatenate 'string ".*λ \\(" var))
      (setq rep (concatenate 'string rep0 "\\) :"))
      (setq term (concat (substring term 0 start)
                         (replace-regexp-in-string rep newvar term nil nil 1 start)))
      )
    (setq start (match-end 0)))
  term
  )

(defun synth-hole(type)
  (setq type (replace-regexp-in-string "∀" "Λ" type)) ;; Replace foralls
  (setq type (replace-regexp-in-string "Π" "λ" type)) ;; Replace Pis
  (while (string-match "\\. \\([^\\.➔]*?\\) ➔" type) ;; Create lambdas from arrows
    (setq s (downcase (match-string 1 type)))
    (setq s (concatenate 'string ". λ " s))
    (setq s (concatenate 'string s " : \\1 ."))
    (setq type (replace-match s nil nil type))
    )
  (setq type (replace-regexp-in-string "\\.[^\\.]*$" ". " type)) ;; Delete the final return type
  (desambiguate-lambdas type)
  )

(defun cedille-mode-synth-quantifiers ()
  "This function will synthesize the proper lambdas that match
the quantifiers at the given hole"
  (interactive)
  (when se-mode-selected
    (let* ((term (se-mode-selected))
           (d (se-term-to-json term))
           (name (se-term-name term))
           (type (get-span-type d))
           (synth-type (synth-hole type))
           )
      (when (string= name 'Hole)
        (insert-before-markers synth-type))
      )))

(provide 'cedille-mode-synthesis)
;;; cedille-mode-synthesis.el ends here