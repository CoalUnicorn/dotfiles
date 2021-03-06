;;; org-edna-tests.el --- Tests for org-edna

;; Copyright (C) 2017 Free Software Foundation, Inc.

;; Author: Ian Dunn <dunni@gnu.org>
;; Keywords: convenience, text, org
;; Version: 1.0
;; Package-Requires: ((emacs "25.1") (seq "2.19") (org "8.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 3, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'org-edna)
(require 'ert)
(require 'org-id)

(defconst org-edna-test-dir
  (expand-file-name (file-name-directory (or load-file-name buffer-file-name))))

(defconst org-edna-test-file
  (expand-file-name "org-edna-tests.org" org-edna-test-dir))

(defconst org-edna-tests-el
  (expand-file-name "org-edna-tests.el" org-edna-test-dir))

;; Jan 15, 2000; chosen at random
(defconst org-edna-test-time
  (encode-time 0 0 0 15 1 2000))

(defconst org-edna-test-sibling-one-id   "82a4ac3d-9565-4f94-bc84-2bbfd8d7d96c")
(defconst org-edna-test-sibling-two-id   "72534efa-e932-460b-ae2d-f044a0074815")
(defconst org-edna-test-sibling-three-id "06aca55e-ce09-46df-80d7-5b52e55d6505")
(defconst org-edna-test-parent-id        "21b8f1f5-14e8-4677-873d-69e0389fdc9e")
(defconst org-edna-test-id-heading-one   "0d491588-7da3-43c5-b51a-87fbd34f79f7")
(defconst org-edna-test-id-heading-two   "b010cbad-60dc-46ef-a164-eb155e62cbb2")
(defconst org-edna-test-id-heading-three "97e6b0f0-40c4-464f-b760-6e5ca9744eb5")
(defconst org-edna-test-id-heading-four  "7d4d564b-18b2-445c-a0c8-b1b3fb9ad29e")
(defconst org-edna-test-archive-heading  "d7668277-f959-43ba-8e85-8a3c76996862")

(defun org-edna-find-test-heading (id)
  "Find the test heading with id ID."
  (org-id-find-id-in-file id org-edna-test-file t))

(ert-deftest org-edna-parse-form-no-arguments ()
  (let* ((input-string "test-string")
         (parsed       (org-edna-parse-form input-string)))
    (should parsed)
    (should (= (length parsed) 4))
    (pcase-let* ((`(,token ,args ,modifier ,pos) parsed))
      (should (eq token 'test-string))
      (should (not args))
      (should (not modifier))
      (should (= pos 11)))))

(ert-deftest org-edna-parse-form-no-arguments-modifier ()
  (let* ((input-string "!test-string")
         (parsed       (org-edna-parse-form input-string)))
    (should parsed)
    (should (= (length parsed) 4))
    (pcase-let* ((`(,token ,args ,modifier ,pos) parsed))
      (should (eq token 'test-string))
      (should (not args))
      (should (eq modifier '!))
      (should (= pos 12)))))

(ert-deftest org-edna-parse-form-single-argument ()
  (let* ((input-string "test-string(abc)")
         (parsed       (org-edna-parse-form input-string)))
    (should parsed)
    (should (= (length parsed) 4))
    (pcase-let* ((`(,token ,args ,modifier ,pos) parsed))
      (should (eq token 'test-string))
      (should (= (length args) 1))
      (should (symbolp (nth 0 args)))
      (should (eq (nth 0 args) 'abc))
      (should (not modifier))
      (should (= pos (length input-string))))))

(ert-deftest org-edna-parse-form-string-argument ()
  (let* ((input-string "test-string(abc \"def (ghi)\")")
         (parsed       (org-edna-parse-form input-string)))
    (should parsed)
    (should (= (length parsed) 4))
    (pcase-let* ((`(,token ,args ,modifier ,pos) parsed))
      (should (eq token 'test-string))
      (should (= (length args) 2))
      (should (symbolp (nth 0 args)))
      (should (eq (nth 0 args) 'abc))
      (should (stringp (nth 1 args)))
      (should (string-equal (nth 1 args) "def (ghi)"))
      (should (not modifier))
      (should (= pos (length input-string))))))

(ert-deftest org-edna-parse-form-multiple-forms ()
  (let ((input-string "test-string1 test-string2")
        pos)
    (pcase-let* ((`(,token1 ,args1 ,modifier1 ,pos1) (org-edna-parse-form input-string)))
      ;; (should (and token1 args1 modifier1 pos1))
      (should (eq token1 'test-string1))
      (should (not args1))
      (should (not modifier1))
      (should (= pos1 13))
      (setq pos pos1))
    (pcase-let* ((`(,token2 ,args2 ,modifier2 ,pos2) (org-edna-parse-form (substring input-string pos))))
      (should (eq token2 'test-string2))
      (should (not args2))
      (should (not modifier2))
      (should (= pos2 12)))))

(ert-deftest org-edna-parse-form-empty-argument-list ()
  (let ((input-string "test-string1()"))
    (pcase-let* ((`(,token1 ,args1 ,modifier1 ,pos1) (org-edna-parse-form input-string)))
      (should (eq token1 'test-string1))
      (should (not args1))
      (should (not modifier1))
      (should (= pos1 (length input-string))))))

(ert-deftest org-edna-parse-form-condition ()
  (let ((input-string "variable-set?()"))
    (pcase-let* ((`(,token1 ,args1 ,modifier1 ,pos1) (org-edna-parse-form input-string))
                 (`(,type . ,func) (org-edna--function-for-key token1)))
      (should (eq token1 'variable-set?))
      (should (not args1))
      (should (not modifier1))
      (should (= pos1 (length input-string)))
      (should (eq type 'condition))
      (should (eq func 'org-edna-condition/variable-set?)))))


;; Finders

(defsubst org-edna-heading (pom)
  (org-with-point-at pom
    (org-get-heading t t t t)))

(ert-deftest org-edna-finder/match-single-arg ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (targets (org-edna-finder/match "test&1")))
    (should (= (length targets) 2))
    (should (string-equal (org-edna-heading (nth 0 targets)) "Tagged Heading 1"))
    (should (string-equal (org-edna-heading (nth 1 targets)) "Tagged Heading 2"))))

(ert-deftest org-edna-finder/ids-single ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (test-id "caccd0a6-d400-410a-9018-b0635b07a37e")
         (targets (org-edna-finder/ids test-id)))
    (should (= (length targets) 1))
    (should (string-equal (org-edna-heading (nth 0 targets)) "Blocking Test"))
    (should (string-equal (org-entry-get (nth 0 targets) "ID") test-id))))

(ert-deftest org-edna-finder/ids-multiple ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (test-ids '("0d491588-7da3-43c5-b51a-87fbd34f79f7"
                     "b010cbad-60dc-46ef-a164-eb155e62cbb2"))
         (targets (apply 'org-edna-finder/ids test-ids)))
    (should (= (length targets) 2))
    (should (string-equal (org-edna-heading (nth 0 targets)) "ID Heading 1"))
    (should (string-equal (org-entry-get (nth 0 targets) "ID") (nth 0 test-ids)))
    (should (string-equal (org-edna-heading (nth 1 targets)) "ID Heading 2"))
    (should (string-equal (org-entry-get (nth 1 targets) "ID") (nth 1 test-ids)))))

(ert-deftest org-edna-finder/match-blocker ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (heading (org-id-find "caccd0a6-d400-410a-9018-b0635b07a37e" t))
         (blocker (org-entry-get heading "BLOCKER")))
    (should (string-equal "match(\"test&1\")" blocker))
    (org-with-point-at heading
      (org-edna-process-form blocker 'condition))
    (should (string-equal (substring-no-properties org-block-entry-blocking)
                          "TODO Tagged Heading 1 :1:test:"))))

(ert-deftest org-edna-finder/file ()
  (let* ((targets (org-edna-finder/file org-edna-test-file)))
    (should (= (length targets) 1))
    (should (markerp (nth 0 targets)))
    (org-with-point-at (nth 0 targets)
      (should (equal (current-buffer) (find-buffer-visiting org-edna-test-file)))
      (should (equal (point) 1)))))

(ert-deftest org-edna-finder/org-file ()
  (let* ((org-directory (file-name-directory org-edna-test-file))
         (targets (org-edna-finder/org-file (file-name-nondirectory org-edna-test-file))))
    (should (= (length targets) 1))
    (should (markerp (nth 0 targets)))
    (org-with-point-at (nth 0 targets)
      (should (equal (current-buffer) (find-buffer-visiting org-edna-test-file)))
      (should (equal (point) 1)))))

(ert-deftest org-edna-finder/self ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (current (org-id-find "82a4ac3d-9565-4f94-bc84-2bbfd8d7d96c" t))
         (targets (org-with-point-at current (org-edna-finder/self))))
    (should (= (length targets) 1))
    (should (equal current (nth 0 targets)))))

(ert-deftest org-edna-finder/siblings ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (current (org-id-find "82a4ac3d-9565-4f94-bc84-2bbfd8d7d96c" t))
         (siblings (mapcar
                    (lambda (uuid) (org-id-find uuid t))
                    '("72534efa-e932-460b-ae2d-f044a0074815"
                      "06aca55e-ce09-46df-80d7-5b52e55d6505")))
         (targets (org-with-point-at current
                    (org-edna-finder/siblings))))
    (should (= (length targets) 2))
    (should (equal siblings targets))))

(ert-deftest org-edna-finder/siblings-wrap ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (current (org-id-find "72534efa-e932-460b-ae2d-f044a0074815" t))
         (siblings (mapcar
                    (lambda (uuid) (org-id-find uuid t))
                    '("06aca55e-ce09-46df-80d7-5b52e55d6505"
                      "82a4ac3d-9565-4f94-bc84-2bbfd8d7d96c")))
         (targets (org-with-point-at current
                    (org-edna-finder/siblings-wrap))))
    (should (= (length targets) 2))
    (should (equal siblings targets))))

(ert-deftest org-edna-finder/rest-of-siblings ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (current (org-id-find "72534efa-e932-460b-ae2d-f044a0074815" t))
         (siblings (mapcar
                    (lambda (uuid) (org-id-find uuid t))
                    '("06aca55e-ce09-46df-80d7-5b52e55d6505")))
         (targets (org-with-point-at current
                    (org-edna-finder/rest-of-siblings))))
    (should (= (length targets) 1))
    (should (equal siblings targets))))

(ert-deftest org-edna-finder/next-sibling ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (current (org-id-find "72534efa-e932-460b-ae2d-f044a0074815" t))
         (siblings (mapcar
                    (lambda (uuid) (org-id-find uuid t))
                    '("06aca55e-ce09-46df-80d7-5b52e55d6505")))
         (targets (org-with-point-at current
                    (org-edna-finder/next-sibling))))
    (should (= (length targets) 1))
    (should (equal siblings targets))))

(ert-deftest org-edna-finder/previous-sibling ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (current (org-id-find "06aca55e-ce09-46df-80d7-5b52e55d6505" t))
         (siblings (mapcar
                    (lambda (uuid) (org-id-find uuid t))
                    '("72534efa-e932-460b-ae2d-f044a0074815")))
         (targets (org-with-point-at current
                    (org-edna-finder/previous-sibling))))
    (should (= (length targets) 1))
    (should (equal siblings targets))))

(ert-deftest org-edna-finder/first-child ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (current (org-id-find org-edna-test-parent-id t))
         (first-child (list (org-id-find org-edna-test-sibling-one-id t)))
         (targets (org-with-point-at current
                    (org-edna-finder/first-child))))
    (should (= (length targets) 1))
    (should (equal first-child targets))))

(ert-deftest org-edna-finder/children ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (current (org-id-find org-edna-test-parent-id t))
         (children (mapcar
                    (lambda (uuid) (org-id-find uuid t))
                    `(,org-edna-test-sibling-one-id
                      ,org-edna-test-sibling-two-id
                      ,org-edna-test-sibling-three-id)))
         (targets (org-with-point-at current
                    (org-edna-finder/children))))
    (should (= (length targets) 3))
    (should (equal children targets))))

(ert-deftest org-edna-finder/parent ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (current (org-id-find org-edna-test-sibling-one-id t))
         (parent (list (org-id-find org-edna-test-parent-id t)))
         (targets (org-with-point-at current
                    (org-edna-finder/parent))))
    (should (= (length targets) 1))
    (should (equal parent targets))))


;; Actions

(ert-deftest org-edna-action/todo-test ()
  (let* ((org-agenda-files `(,org-edna-test-file))
         (target (org-id-find "0d491588-7da3-43c5-b51a-87fbd34f79f7" t)))
    (org-with-point-at target
      (org-edna-action/todo! nil "DONE")
      (should (string-equal (org-entry-get nil "TODO") "DONE"))
      (org-edna-action/todo! nil "TODO")
      (should (string-equal (org-entry-get nil "TODO") "TODO"))
      (org-edna-action/todo! nil 'DONE)
      (should (string-equal (org-entry-get nil "TODO") "DONE"))
      (org-edna-action/todo! nil 'TODO)
      (should (string-equal (org-entry-get nil "TODO") "TODO")))))

(ert-deftest org-edna-action-scheduled/wkdy ()
  ;; Override `current-time' so we can get a deterministic value
  (cl-letf* (((symbol-function 'current-time) (lambda () org-edna-test-time))
             (org-agenda-files `(,org-edna-test-file))
             (target (org-id-find "0d491588-7da3-43c5-b51a-87fbd34f79f7" t)))
    (org-with-point-at target
      (org-edna-action/scheduled! nil "Mon")
      (should (string-equal (org-entry-get nil "SCHEDULED")
                            "<2000-01-17 Mon>"))
      (org-edna-action/scheduled! nil 'rm)
      (should (not (org-entry-get nil "SCHEDULED")))
      (org-edna-action/scheduled! nil "Mon 9:00")
      (should (string-equal (org-entry-get nil "SCHEDULED")
                            "<2000-01-17 Mon 09:00>"))
      (org-edna-action/scheduled! nil 'rm)
      (should (not (org-entry-get nil "SCHEDULED"))))))

(ert-deftest org-edna-action-scheduled/cp ()
  ;; Override `current-time' so we can get a deterministic value
  (let* ((org-agenda-files `(,org-edna-test-file))
         (target (org-id-find "0d491588-7da3-43c5-b51a-87fbd34f79f7" t))
         (source (org-id-find "97e6b0f0-40c4-464f-b760-6e5ca9744eb5" t))
         (pairs '((cp . rm) (copy . remove) ("cp" . "rm") ("copy" . "remove"))))
    (org-with-point-at target
      (dolist (pair pairs)
        ;; (message "Pair: %s" pair)
        (org-edna-action/scheduled! source (car pair))
        (should (string-equal (org-entry-get nil "SCHEDULED")
                              "<2000-01-15 Sat 00:00>"))
        (org-edna-action/scheduled! source (cdr pair))
        (should (not (org-entry-get nil "SCHEDULED")))))))

(ert-deftest org-edna-action-scheduled/inc ()
  ;; Override `current-time' so we can get a deterministic value
  (cl-letf* (((symbol-function 'current-time) (lambda () org-edna-test-time))
             (org-agenda-files `(,org-edna-test-file))
             (target (org-id-find "97e6b0f0-40c4-464f-b760-6e5ca9744eb5" t)))
    (org-with-point-at target
      ;; Time started at Jan 15, 2000
      ;; Increment 1 minute
      (org-edna-action/scheduled! nil "+1M")
      (should (string-equal (org-entry-get nil "SCHEDULED")
                            "<2000-01-15 Sat 00:01>"))
      (org-edna-action/scheduled! nil "-1M")
      (should (string-equal (org-entry-get nil "SCHEDULED")
                            "<2000-01-15 Sat 00:00>"))
      (org-edna-action/scheduled! nil "+1d")
      (should (string-equal (org-entry-get nil "SCHEDULED")
                            "<2000-01-16 Sun 00:00>"))
      (org-edna-action/scheduled! nil "++1h")
      (should (string-equal (org-entry-get nil "SCHEDULED")
                            "<2000-01-15 Sat 01:00>"))
      (org-edna-action/scheduled! nil "2000-01-15 Sat 00:00")
      (should (string-equal (org-entry-get nil "SCHEDULED")
                            "<2000-01-15 Sat 00:00>")))))

(ert-deftest org-edna-action-tag ()
  (let ((pom (org-edna-find-test-heading org-edna-test-id-heading-one)))
    (org-with-point-at pom
      (org-edna-action/tag! nil "tag")
      (should (equal (org-get-tags) '("tag")))
      (org-edna-action/tag! nil "")
      (should-not (org-get-tags)))))

(ert-deftest org-edna-action-property ()
  (let ((pom (org-edna-find-test-heading org-edna-test-id-heading-one)))
    (org-with-point-at pom
      (org-edna-action/set-property! nil "TEST" "1")
      (should (equal (org-entry-get nil "TEST") "1"))
      (org-edna-action/delete-property! nil "TEST")
      (should-not (org-entry-get nil "TEST")))))

(ert-deftest org-edna-action-clock ()
  (let ((pom (org-edna-find-test-heading org-edna-test-id-heading-one)))
    (org-with-point-at pom
      (org-edna-action/clock-in! nil)
      (should (org-clocking-p))
      (should (equal org-clock-hd-marker pom))
      (org-edna-action/clock-out! nil)
      (should-not (org-clocking-p)))))

(ert-deftest org-edna-action-priority ()
  (let ((pom (org-edna-find-test-heading org-edna-test-id-heading-one))
        (org-lowest-priority  ?C)
        (org-highest-priority ?A)
        (org-default-priority ?B))
    (org-with-point-at pom
      (org-edna-action/set-priority! nil "A")
      (should (equal (org-entry-get nil "PRIORITY") "A"))
      (org-edna-action/set-priority! nil 'down)
      (should (equal (org-entry-get nil "PRIORITY") "B"))
      (org-edna-action/set-priority! nil 'up)
      (should (equal (org-entry-get nil "PRIORITY") "A"))
      (org-edna-action/set-priority! nil ?C)
      (should (equal (org-entry-get nil "PRIORITY") "C"))
      (org-edna-action/set-priority! nil 'remove)
      (should (equal (org-entry-get nil "PRIORITY") "B")))))

(ert-deftest org-edna-action-effort ()
  (let ((pom (org-edna-find-test-heading org-edna-test-id-heading-one)))
    (org-with-point-at pom
      (org-edna-action/set-effort! nil "0:01")
      (should (equal (org-entry-get nil "EFFORT") "0:01"))
      (org-edna-action/set-effort! nil 'increment)
      (should (equal (org-entry-get nil "EFFORT") "0:02"))
      (org-entry-delete nil "EFFORT"))))

(ert-deftest org-edna-action-archive ()
  (let ((org-archive-save-context-info '(todo))
        (pom (org-edna-find-test-heading org-edna-test-archive-heading))
        ;; Archive it to the same location
        (org-archive-location "::** Archive")
        (org-edna-prompt-for-archive nil))
    (org-with-point-at pom
      (org-edna-action/archive! nil)
      (should (equal (org-entry-get nil "ARCHIVE_TODO") "TODO"))
      (org-entry-delete nil "ARCHIVE_TODO"))))

(ert-deftest org-edna-action-chain ()
  (let ((old-pom (org-edna-find-test-heading org-edna-test-id-heading-one))
        (new-pom (org-edna-find-test-heading org-edna-test-id-heading-two)))
    (org-entry-put old-pom "TEST" "1")
    (org-with-point-at new-pom
      (org-edna-action/chain! old-pom "TEST")
      (should (equal (org-entry-get nil "TEST") "1")))
    (org-entry-delete old-pom "TEST")
    (org-entry-delete new-pom "TEST")))


;; Conditions

(defun org-edna-test-condition-form (func-sym pom-true pom-false block-true block-false &rest args)
  (org-with-point-at pom-true
    (should-not (apply func-sym t args))
    (should     (equal (apply func-sym nil args) block-true)))
  (org-with-point-at pom-false
    (should     (equal (apply func-sym t args) block-false))
    (should-not (apply func-sym nil args))))

(ert-deftest org-edna-condition-done ()
  (let* ((pom-done (org-edna-find-test-heading org-edna-test-id-heading-four))
         (pom-todo (org-edna-find-test-heading org-edna-test-id-heading-one))
         (block-done (org-with-point-at pom-done (org-get-heading)))
         (block-todo (org-with-point-at pom-todo (org-get-heading))))
    (org-edna-test-condition-form 'org-edna-condition/done?
                                  pom-done pom-todo
                                  block-done block-todo)))

(ert-deftest org-edna-condition-todo-state-string ()
  (let* ((pom-done (org-edna-find-test-heading org-edna-test-id-heading-four))
         (pom-todo (org-edna-find-test-heading org-edna-test-id-heading-one))
         (block-done (org-with-point-at pom-done (org-get-heading)))
         (block-todo (org-with-point-at pom-todo (org-get-heading))))
    (org-edna-test-condition-form 'org-edna-condition/todo-state?
                                  pom-todo pom-done
                                  block-todo block-done
                                  "TODO")))

(ert-deftest org-edna-condition-todo-state-symbol ()
  (let* ((pom-done (org-edna-find-test-heading org-edna-test-id-heading-four))
         (pom-todo (org-edna-find-test-heading org-edna-test-id-heading-one))
         (block-done (org-with-point-at pom-done (org-get-heading)))
         (block-todo (org-with-point-at pom-todo (org-get-heading))))
    (org-edna-test-condition-form 'org-edna-condition/todo-state?
                                  pom-todo pom-done
                                  block-todo block-done
                                  'TODO)))

(ert-deftest org-edna-condition-headings ()
  (pcase-let* ((`(,pom-headings ,block-headings)
                (with-current-buffer (find-file-noselect org-edna-test-file)
                  (list (point-min-marker) (buffer-name))))
               (`(,pom-no-headings ,block-no-headings)
                (with-current-buffer (find-file-noselect org-edna-tests-el)
                  (list (point-min-marker) (buffer-name)))))
    (org-edna-test-condition-form 'org-edna-condition/headings?
                                  pom-headings pom-no-headings
                                  block-headings block-no-headings)))

(ert-deftest org-edna-condition-variable-set ()
  (let* ((temp-var t))
    (should-not (org-edna-condition/variable-set? t 'temp-var t))
    (should     (equal (org-edna-condition/variable-set? nil 'temp-var t)
                       "temp-var == t"))
    (should     (equal (org-edna-condition/variable-set? t 'temp-var nil)
                       "temp-var != nil"))
    (should-not (org-edna-condition/variable-set? nil 'temp-var nil))))

(ert-deftest org-edna-condition-has-property ()
  (let* ((pom-true (org-edna-find-test-heading org-edna-test-id-heading-four))
         (pom-false (org-edna-find-test-heading org-edna-test-id-heading-one))
         (block-true (org-with-point-at pom-true (org-get-heading)))
         (block-false (org-with-point-at pom-false (org-get-heading))))
    (org-edna-test-condition-form 'org-edna-condition/has-property?
                                  pom-true pom-false
                                  block-true block-false
                                  "ID" org-edna-test-id-heading-four)))

(ert-deftest org-edna-condition-re-search ()
  (pcase-let* ((case-fold-search nil)
               (string "require")
               (`(,pom-true ,block-true)
                (with-current-buffer (find-file-noselect org-edna-tests-el)
                  (list (point-min-marker)
                        (format "Found %s in %s" string (buffer-name)))))
               (`(,pom-false ,block-false)
                (with-current-buffer (find-file-noselect org-edna-test-file)
                  (list (point-min-marker)
                        (format "Did Not Find %s in %s" string (buffer-name))))))
    (org-edna-test-condition-form 'org-edna-condition/re-search?
                                  pom-true pom-false
                                  block-true block-false
                                  string)))


;; Consideration

(ert-deftest org-edna-consideration/all ()
  (let ((blocks-blocking `("a" nil "b"))
        (blocks-no-blocking `(nil nil nil)))
    (should (string-equal (org-edna-handle-consideration 'all blocks-blocking) "a"))
    (should (not (org-edna-handle-consideration 'all blocks-no-blocking)))))

(ert-deftest org-edna-consideration/integer ()
  (let ((blocks-blocking `("a" "c" "b"))
        (blocks-no-blocking `("a" nil "b"))
        (blocks-empty `(nil nil nil)))
    (should (string-equal (org-edna-handle-consideration 1 blocks-blocking) "a"))
    (should (not (org-edna-handle-consideration 1 blocks-no-blocking)))
    (should (not (org-edna-handle-consideration 1 blocks-empty)))))

(ert-deftest org-edna-consideration/float ()
  (let ((blocks-blocking `("a" "c" "b"))
        (blocks-no-blocking `("a" nil "b"))
        (blocks-empty `(nil nil nil)))
    (should (string-equal (org-edna-handle-consideration 0.25 blocks-blocking) "a"))
    (should (not (org-edna-handle-consideration 0.25 blocks-no-blocking)))
    (should (not (org-edna-handle-consideration 0.25 blocks-empty)))))

(provide 'org-edna-tests)

;;; org-edna-tests.el ends here
