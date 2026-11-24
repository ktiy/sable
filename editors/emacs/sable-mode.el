;; -*- lexical-binding: t; -*-
(require 'rx)
(require 'cl-lib)

(defgroup sable nil
  "Major mode for the sable programming language."
  :group 'languages
  :prefix "sable-")

(defcustom sable-indent-offset 2
  "Indentation level"
  :type 'integer
  :safe #'integerp)


(defcustom sable-keymap
  (cl-mapcar #'cons
             "noO+-mM=><pdtSejislrR12 3 ;["
             "∅⫦⊪×÷↧↥≠≥≤□↓↑Ρ⊂⨝ιρ⧻△▽ˊ¨:ˋ‿⋄←")
  "Sable keymap"
  :type '(alist :key-type character :value-type character))

(defface sable-stack-prim-face
  '((t (:inherit font-lock-comment-face)))
  "face for stack primitives"
  :group 'sable)

(defface sable-monad-face
  '((t (:inherit font-lock-variable-use-face)))
  "face for monad primitives"
  :group 'sable)

(defface sable-dyad-face
  '((t (:inherit font-lock-keyword-face)))
  "face for dyad primitives"
  :group 'sable)

(defface sable-modifier-face
  '((t (:inherit font-lock-function-name-face)))
  "face for modifiers"
  :group 'sable)

(defface sable-builtin-face
  '((t (:inherit font-lock-builtin-face)))
  "face for builtins"
  :group 'sable)

(defface sable-number-face
  '((t (:inherit font-lock-number-face)))
  "face for numbers"
  :group 'sable)

(defface sable-lambda-face
  '((t (:inherit font-lock-keyword-face :weight bold)))
  "face for lambda"
  :group 'sable)

(defface sable-punctuation-face
  '((t (:inherit font-lock-misc-punctuation-face)))
  "face for punctuation"
  :group 'sable)

(defconst sable--stack-prims
  (list ?. ?, ?~ ?⫦ ?⊪))

(defconst sable--monadic-prims
  (list ?ι ?ρ ?⧻ ?△ ?▽ ?↧ ?↥))

(defconst sable--dyadic-prims
  (list ?□ ?Ρ ?↓ ?↑ ?⊂ ?⨝ ?+ ?- ?× ?÷ ?* ?| ?≠ ?≤ ?≥))

(defconst sable--modifier-prims
  (list ?ˊ ?¨ ?: ?ˋ))

(defconst sable--punctuation
  (list ?\; ?⋄ ?‿ ?← ?λ ?#))

(defvar sable--syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?% "<" st)
    (modify-syntax-entry ?\n ">" st)
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?\\ "\\" st)
    (modify-syntax-entry ?' "." st)
    (modify-syntax-entry ?\[ "(]" st)
    (modify-syntax-entry ?\] ")[" st)
    (modify-syntax-entry ?\{ "(}" st)
    (modify-syntax-entry ?\} "){" st)
    (modify-syntax-entry ?_ "_" st)
    (dolist (c (append sable--stack-prims
                       sable--monadic-prims
                       sable--dyadic-prims
                       sable--modifier-prims
                       sable--punctuation))
      (modify-syntax-entry c "." st))
    st))

(defconst sable--font-lock-keywords
  `((,(rx "'" nonl) . 'font-lock-string-face)
    (,(rx "#" (* (any "0-9a-fA-F"))) . 'sable-number-face)
    (,(rx "@" (* (any "0-9a-zA-Z_"))) . 'sable-builtin-face)

    (,(rx (group symbol-start (any "A-Za-z_") (* (any "A-Za-z0-9_")))
          (* (any " \t")) "←")
     1 font-lock-variable-name-face)

    (,(rx symbol-start (any "0-9") (* (any "0-9_"))
          (opt "." (* (any "0-9_")))
          (opt (any "eE") (opt (any "+-")) (* (any "0-9_"))))
     . 'sable-number-face)

    ("λ" . 'sable-lambda-face)
    (,(rx (any "←‿;⋄")) . 'sable-punctuation-face)

    (,(regexp-opt-charset sable--stack-prims)   . 'sable-stack-prim-face)
    (,(regexp-opt-charset sable--monadic-prims) . 'sable-monad-face)
    (,(regexp-opt-charset sable--dyadic-prims)  . 'sable-dyad-face)
    (,(regexp-opt-charset sable--modifier-prims) . 'sable-modifier-face)))

(defun sable--indent-line ()
  "indent the current line"
  (interactive)
  (let* ((target
          (save-excursion
            (back-to-indentation)
            (let ((ppss (syntax-ppss)))
              (unless (nth 8 ppss)
                (* sable-indent-offset
                   (max 0 (- (car ppss)
                             (if (looking-at "[]}]") 1 0))))))))
         (before-indent (<= (current-column) (current-indentation))))
    (when target
      (if before-indent
          (indent-line-to target)
        (save-excursion (indent-line-to target))))))

(defun sable-backslash ()
  (interactive)
  (let* ((ev (read-event "\\"))
         (hit (and (characterp ev) (assq ev sable-keymap))))
    (cond
     (hit (insert (cdr hit)))
     ((eq ev ?\\) (insert "\\\\"))
     (t (insert ?\\)
        (push ev unread-command-events)))))

(defconst sable--imenu-generic-expression
  `(("Definitions"
     ,(rx bol (* (any " \t"))
          (group symbol-start (any "A-Za-z_") (* (any "A-Za-z0-9_")))
          (* (any " \t")) "←")
     1)))

(defvar sable-mode-map (make-sparse-keymap))
(define-key sable-mode-map "\\" #'sable-backslash)

;;###autoload
(define-derived-mode sable-mode prog-mode "sable"
  "Major mode for editing sable source code"
  (setq-local font-lock-defaults '(sable--font-lock-keywords))
  (setq-local comment-start "%")
  (setq-local comment-start-skip "%+[ \t]*")
  (setq-local comment-end "")
  (setq-local indent-line-function #'sable--indent-line)
  (setq-local indent-tabs-mode nil)
  (setq-local imenu-generic-expression sable--imenu-generic-expression)
  (setq-local electric-indent-chars '(?\n ?\] ?\}))
  (set-syntax-table sable--syntax-table))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sbl\\'" . sable-mode))

(provide 'sable-mode)
