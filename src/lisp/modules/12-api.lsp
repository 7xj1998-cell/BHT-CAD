;;; ----------------------------------------------------------------------
;;; 0.4.3: API cho plugin .NET (BHT.Bridge / BHT.Palette)
;;;  - Lisp la noi DUY NHAT chua thuat toan nhan / ky hieu / ky hieu anh /
;;;    kiem tra / thu tu hien thi; plugin goi cac ham duoi day, KHONG viet lai.
;;;  - Moi ham tra ve DANH SACH CHUOI: ("OK" ...) hoac ("LOI" "ly do").
;;;  - Khong hoi nguoi dung, khong phu thuoc palette.
;;;  - Duoc dang ky bang vl-acad-defun de .NET goi qua Application.Invoke
;;;    (acedInvoke) trong ngu canh lenh; cung goi duoc tu dong lenh:
;;;    (bht:api-version)
;;; ----------------------------------------------------------------------

(setq *bht-api-level* "1")

(defun bht:api-alist (r)
  (mapcar '(lambda (p) (strcat (strcase (bht:str (car p)) T) "=" (bht:str (cdr p)))) r)
)

(defun bht:api-ids (s)
  (vl-remove "" (bht:split (bht:replace (bht:replace (bht:str s) "," " ") ";" " ") " "))
)

;; Chay fn an toan; ket qua (danh sach) -> ("OK" chuoi...).
(defun bht:api-run (fn args / r)
  (setq r (vl-catch-all-apply fn args))
  (bht:log-flush)
  (cond
    ((vl-catch-all-error-p r) (list "LOI" (vl-catch-all-error-message r)))
    ((and (listp r) (= (car r) 'LOI)) (list "LOI" (bht:str (cadr r))))
    (T (cons "OK" (mapcar 'bht:str (if (listp r) r (list r))))))
)

(defun bht:api-version ()
  (list "OK" *bht-version* *bht-api-level* *bht-build*)
)

;; Lay cac thong bao cua lenh tuong tac de hien ngay trong Palette.
;; DRAIN/CLEAR: tra ve theo dung thu tu roi xoa bo dem; PEEK: chi doc.
(defun bht:api-messages (mode / out)
  (setq out (reverse *bht-screen-messages*))
  (if (member (strcase (bht:str mode)) '("DRAIN" "CLEAR"))
    (setq *bht-screen-messages* nil *bht-screen-problems* nil))
  (cons "OK" out)
)

;; 0.4.6-fix3: loi / canh bao (bht:err / bht:warn) cua lenh vua chay, dang "ERROR|noi dung" / "WARN|noi dung".
;; Palette goi TRUOC bht:api-messages de to trang thai that bai. DRAIN/CLEAR: doc roi xoa; PEEK: chi doc.
(defun bht:api-problems (mode / out)
  (setq out (reverse *bht-screen-problems*))
  (if (member (strcase (bht:str mode)) '("DRAIN" "CLEAR"))
    (setq *bht-screen-problems* nil))
  (cons "OK" out)
)

;; Thong tin giong BHTINFO (theo handle thuc the / ID diem / ID ho so / ma anh).
(defun bht:api-info-handle (h)
  (bht:api-run '(lambda (h / e)
                  (if (and (setq e (handent (bht:str h))) (entget e))
                    (bht:info-lines e)
                    (list 'LOI (strcat "không có thực thể handle " (bht:str h)))))
               (list h))
)

(defun bht:api-info-point (pid)
  (bht:api-run '(lambda (pid / p)
                  (if (setq p (bht:pt-find (bht:str pid) (bht:pt-all)))
                    (bht:point-info-lines p)
                    (list 'LOI (strcat "không có điểm " (bht:str pid)))))
               (list pid))
)

(defun bht:api-info-object (oid)
  (bht:api-run '(lambda (oid) (bht:obj-info-lines (strcase (bht:str oid)))) (list oid))
)

(defun bht:api-info-photo (pid)
  (bht:api-run '(lambda (pid) (bht:photo-info-lines (bht:str pid))) (list pid))
)

;; Duong dan JPG ma Lisp tim thay ("" = khong thay) - dung doi chieu voi C#.
(defun bht:api-photo-path (pid)
  (bht:api-run '(lambda (pid / rec p)
                  (setq rec (bht:photo-read (strcase (bht:str pid))))
                  (if (null rec) (list 'LOI (strcat "không có ảnh " (bht:str pid)))
                    (list (if (setq p (bht:photo-path rec)) p ""))))
               (list pid))
)

;; Ky hieu theo object_id: ids "" = moi ho so; "OBJ-1,OBJ-2" = chi cac ho so do.
(defun bht:api-sign-free (oid)
  (bht:api-run '(lambda (oid / r)
    (bht:ensure-model)
    (setq r (bht:kh-place-free oid))
    (cond ((eq (car r) 'LOI) r) ((eq (car r) 'HUY) (list "Đã hủy, hồ sơ không đổi."))
          (T (bht:api-alist r)))) (list oid)))

(defun bht:api-sign-fill (value)
  (bht:api-run '(lambda (value / ids)
    (if (not (member value '("0" "1"))) (list 'LOI "Giá trị tô màu không hợp lệ.")
      (progn (bht:meta-set "sign_fill_all" value)
        (setq ids (vl-remove-if-not '(lambda (oid) (= (bht:get (bht:obj-read oid) "nhom") "BIEN_BAO")) (bht:obj-ids)))
        (if ids (bht:api-alist (bht:symbol-sync-ex ids nil)) (list "Không có hồ sơ biển báo BHT."))))) (list value)))

(defun bht:api-sign-place (oid mode direction degrees)
  (bht:api-run '(lambda (oid mode direction degrees / r)
    (bht:ensure-model)
    (setq r (bht:kh-place-options oid mode direction degrees))
    (cond ((eq (car r) 'LOI) r) ((eq (car r) 'HUY) (list "Đã hủy, hồ sơ không đổi."))
          (T (bht:api-alist r)))) (list oid mode direction degrees)))

(defun bht:api-symbol-sync (ids)
  (bht:api-run '(lambda (ids / sc)
                  (setq sc (bht:api-ids ids))
                  (bht:ensure-model)
                  (bht:api-alist (bht:symbol-sync (if sc sc nil))))
               (list ids))
)

;; Nhan diem: "" = chi diem moi / doi noi dung; "ALL" = bo tri lai tat ca;
;; danh sach ID = bo tri lai cac diem do (nhan doi tay van giu).
(defun bht:api-label-sync (ids)
  (bht:api-run '(lambda (ids / sc r ov)
                  (setq sc (cond ((= (strcase (bht:str ids)) "ALL") 'ALL)
                                 ((bht:api-ids ids) (mapcar 'strcase (bht:api-ids ids)))
                                 (T nil)))
                  (setq r (bht:lbl-sync-scope sc)
                        ov (bht:lbl-overlaps (if (listp sc) sc nil)))
                  (append (bht:api-alist r) (list (strcat "overlap=" (bht:lbl-overlap-text ov)))))
               (list ids))
)

;; Dinh dang POINT thanh dau X dung tam va sap lai nhan toan ban ve.
(defun bht:api-point-style (size)
  (bht:api-run '(lambda (size / s)
                  (setq s (bht:num (bht:str size)))
                  (if (not (and s (> s 0.0)))
                    (list 'LOI "kích thước dấu X phải lớn hơn 0")
                    (bht:api-alist (bht:point-style-apply s T))))
               (list size))
)

(defun bht:api-photo-sync ()
  (bht:api-run '(lambda () (bht:api-alist (bht:photo-sync))) nil)
)

(defun bht:api-photo-stats ()
  (bht:api-run '(lambda () (bht:api-alist (bht:photo-stats))) nil)
)

;; Kiem tra toan ven (giong BHTKT): ("OK" "loi=n" "canh_bao=n" dong...)
(defun bht:api-check ()
  (bht:api-run '(lambda (/ r)
                  (setq r (bht:check))
                  (append (list (strcat "loi=" (itoa (car r))) (strcat "canh_bao=" (itoa (cadr r)))) (caddr r)))
               nil)
)

(defun bht:api-route-diag (id)
  (bht:api-run
    '(lambda (id / ids out)
       (setq id (strcase (bht:str id)) ids (if (= id "") (bht:route-ids) (list id)) out nil)
       (if (null ids) (list 'LOI "chưa có tuyến tham chiếu")
         (progn
           (foreach rid ids
             (if out (setq out (append out (list "" "----------------------------------------"))))
             (setq out (append out (bht:route-diag-lines rid))))
           out)))
    (list id))
)

;; Thu tu hien thi (dung lenh DRAWORDER). Chi chay duoc khi goi tu dong lenh / Lisp o cap cao nhat.
;; Goi qua Application.Invoke (acedInvoke), AutoCAD TU CHOI lenh (kiem chung Core Console 0.4.0):
;; tra ve LOI ro rang - plugin dung duong lenh BHTTHUTUVE (SendStringToExecute) thay the.
(defun bht:api-draworder (/ r)
  (setq r (bht:api-run '(lambda () (bht:api-alist (bht:draworder-sync))) nil))
  (if (= (car r) "LOI") (bht:sv-restore))
  (if (and (= (car r) "LOI") (vl-string-search "COMMAND" (strcase (bht:str (cadr r)))))
    (list "LOI" (strcat "DRAWORDER không chạy được trong ngữ cảnh gọi API (" (bht:str (cadr r))
                        ") - dùng lệnh BHTTHUTUVE"))
    r)
)

(setq *bht-api-functions*
  '(bht:api-version bht:api-messages bht:api-problems bht:api-info-handle bht:api-info-point bht:api-info-object bht:api-info-photo
    bht:api-photo-path bht:api-sign-fill bht:api-sign-place bht:api-sign-free bht:api-symbol-sync bht:api-label-sync bht:api-point-style bht:api-photo-sync bht:api-photo-stats
    bht:api-check bht:api-route-diag bht:api-draworder))

(defun bht:api-register (/ n)
  (setq n 0)
  (if vl-acad-defun
    (foreach f *bht-api-functions*
      (if (not (vl-catch-all-error-p (vl-catch-all-apply 'vl-acad-defun (list f)))) (setq n (1+ n)))))
  n
)
(setq *bht-api-registered* (bht:api-register))

;; Tu nap Palette theo cung co che APPLOAD cua GKIN. BTH va BHT la command
;; .NET, nen Lisp khong dinh nghia c:BTH / c:BHT de tranh hai lenh trung ten.
(defun bht:command-available-p (name / value)
  (setq value (vl-catch-all-apply 'getcname (list name)))
  (and (not (vl-catch-all-error-p value)) value)
)

(defun bht:palette-load (/ result)
  (cond
    ((bht:command-available-p "BTH") T)
    ((or (null *bht-palette-dll*) (not (findfile *bht-palette-dll*))) nil)
    (T
      (setq result (vl-catch-all-apply 'vl-cmdf (list "_.NETLOAD" *bht-palette-dll*)))
      (and (not (vl-catch-all-error-p result)) (bht:command-available-p "BTH"))))
)

(defun c:BHTLOAD ()
  (if (bht:palette-load)
    (bht:msg "BHT: Palette đã sẵn sàng. Gõ BTH hoặc BHT để mở bảng.")
    (progn
      (bht:warn "BHT: không nạp được Palette.")
      (bht:msg (strcat "  Kiểm tra BHT.Palette.dll, BHT.Bridge.dll và BHT.Core.dll nằm cạnh BHT-" *bht-version* ".lsp."))))
  (princ)
)

;;; ----------------------------------------------------------------------
(if (and (getvar "LISPSYS") (= (getvar "LISPSYS") 0))
  (princ "\nBHT CANH BAO: LISPSYS=0 - tieng Viet co dau co the hien sai. Dat LISPSYS=1, khoi dong lai AutoCAD roi nap lai."))
(bht:point-style-apply nil nil)
(setq *bht-palette-loaded* (bht:command-available-p "BTH"))
(defun bht:load-message () (strcat "BHT " *bht-version* " đã nạp thành công."))
(princ (strcat "\n" (bht:load-message)))
(if *bht-palette-loaded*
  (princ "\nGõ BTH hoặc BHT để mở Palette bên trái; BHTHELP để xem danh sách lệnh.")
  (princ "\nPalette chỉ nạp khi gọi lệnh. Gõ BHTLOAD rồi BTH để mở bảng."))
(princ)

