;;; magit-topgit.el --- topgit plug-in for Magit

;; Copyright (C) 2008, 2009  Marius Vollmer
;; Copyright (C) 2008  Linh Dang
;; Copyright (C) 2008  Alex Ott
;; Copyright (C) 2008  Marcin Bachry
;; Copyright (C) 2009  Alexey Voinov
;; Copyright (C) 2009  John Wiegley
;; Copyright (C) 2010  Yann Hodique
;;
;; Magit is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; Magit is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Magit.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This plug-in provides topgit functionality as a separate component of Magit

;;; Code:

(require 'magit)

(defcustom magit-topgit-executable "tg"
  "The name of the TopGit executable."
  :group 'magit
  :type 'string)

;;; Topic branches (using topgit)

(defun magit-topgit-create-branch (branch parent)
  (when (zerop (or (string-match "t/" branch) -1))
    (magit-run* (list magit-topgit-executable "create"
                      branch (magit-rev-to-git parent))
                nil nil nil t)
    t))

(defun magit-topgit-pull ()
  (when (file-exists-p ".topdeps")
    (magit-run* (list magit-topgit-executable "update")
                nil nil nil t)
    t))

(defun magit-topgit-wash-topic ()
  (if (search-forward-regexp "^..\\(t/\\S-+\\)\\s-+\\(\\S-+\\)\\s-+\\(\\S-+\\)"
                             (line-end-position) t)
      (let ((topic (match-string 1)))
        (delete-region (match-beginning 2) (match-end 2))
        (goto-char (line-beginning-position))
        (delete-char 4)
        (insert "\t")
        (goto-char (line-beginning-position))
        (magit-with-section topic 'topic
          (magit-set-section-info topic)
          (forward-line)))
    (delete-region (line-beginning-position) (1+ (line-end-position))))
  t)

(defun magit-topgit-wash-topics ()
  (let ((magit-old-top-section nil))
    (magit-wash-sequence #'magit-topgit-wash-topic)))

(magit-define-inserter topics ()
  (magit-git-section 'topics
                     "Topics:" 'magit-topgit-wash-topics
                     "branch" "-v"))

(defvar magit-topgit-extension-inserters
  '((:after stashes magit-insert-topics)))

(defvar magit-topgit-extension-actions
  '(("discard" ((topic)
                (when (yes-or-no-p "Discard topic? ")
                  (magit-run* (list magit-topgit-executable "delete" "-f" info)
                              nil nil nil t))))
    ("visit" ((topic)
              (magit-checkout info)))))

(defvar magit-topgit-extension-commands
  '((create-branch . magit-topgit-create-branch)
    (pull . magit-topgit-pull)))

(defvar magit-topgit-extension
  (make-magit-extension :actions magit-topgit-extension-actions
                        :insert magit-topgit-extension-inserters
                        :commands magit-topgit-extension-commands))

(magit-install-extension magit-topgit-extension)

(provide 'magit-topgit)
;;; magit-topgit.el ends here
