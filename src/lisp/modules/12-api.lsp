;;; ----------------------------------------------------------------------
;;; 0.4.3: API cho plugin .NET (BHT.Bridge / BHT.Palette)
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
        (setq ids (vl-remove-if-not '(lambda (oid) (bht:kh-fillable-p (bht:obj-read oid))) (bht:obj-ids)))
        (if ids (bht:api-alist (bht:symbol-sync-ex ids nil)) (list "Không có hồ sơ biển báo BHT."))))) (list value)))

(defun bht:api-object-delete (oid)
  (bht:api-run '(lambda (oid)
    (if (or (= (bht:trim oid) "") (not (bht:obj-read oid))) (list 'LOI "Hồ sơ không tồn tại.")
      (if (bht:obj-delete oid) (list (strcase oid) "Đã xóa hồ sơ và ký hiệu; điểm RTK và ảnh gốc giữ nguyên.")
        (list 'LOI "Không xóa được hồ sơ.")))) (list oid)))

(defun bht:api-symbol-upgrade ()
  (bht:api-run '(lambda (/ *bht-preserve-symbol-placement* ids r pair)
    (cond
      ((= (bht:meta "symbol_build" "") *bht-version*) (list "Ký hiệu đã ở phiên bản hiện tại."))
      ((= (getvar "WRITESTAT") 0) (list 'LOI "Bản vẽ chỉ đọc; chưa cập nhật ký hiệu."))
      ((not (bht:fn-defined-p 'BHTSIGNBOUNDS)) (list 'LOI "Lõi Bridge chưa sẵn sàng."))
      (T
        (foreach pair (bht:tagged-pairs "INSERT" "BHT_KH" 1) (setq ids (bht:unique-add ids (car pair))))
        (setq ids (vl-remove-if-not '(lambda (id / rec) (setq rec (bht:obj-read id)) (or (bht:kh-fillable-p rec) (member (bht:get rec "nhom") '("DEN" "DEN_CS" "DEN_TH")))) ids))
        (if ids
          (progn
            (setq *bht-preserve-symbol-placement* T r (bht:symbol-sync-ex ids nil))
            (bht:meta-set "symbol_build" *bht-version*)
            (cons (strcat "Đã cập nhật ký hiệu BHT " *bht-version* "; lưu bản vẽ để giữ thay đổi.") (bht:api-alist r)))
          (list "Không có ký hiệu biển BHT cần cập nhật."))))) nil))

(defun bht:api-sign-place (oid mode direction degrees)
  (bht:api-run '(lambda (oid mode direction degrees / r)
    (bht:ensure-model)
    (setq r (bht:kh-place-options oid mode direction degrees))
    (cond ((eq (car r) 'LOI) r) ((eq (car r) 'HUY) (list "Đã hủy, hồ sơ không đổi."))
          (T (bht:api-alist r)))) (list oid mode direction degrees)))

(defun bht:api-sign-scale (symbol label)
  (bht:api-run '(lambda (symbol label / s h ids rec e d st nx sc pr index *bht-preserve-symbol-placement*)
    (setq s (bht:num (bht:replace (bht:str symbol) "," "."))
          h (bht:num (bht:replace (bht:str label) "," ".")))
    (if (not (and s h (>= s 0.01) (<= s 100.0) (>= h 0.01) (<= h 100.0)
                  (equal s (bht:num (bht:fnum s 3)) 1e-10) (equal h (bht:num (bht:fnum h 3)) 1e-10)))
      (list 'LOI "Tỷ lệ từ 0,01 đến 100, tối đa 3 chữ số thập phân.")
      (progn
        (bht:ensure-model)
        (bht:meta-set "sign_scale" (bht:fnum s 3))
        (bht:meta-set "sign_label_scale" (bht:fnum h 3))
        (setq ids (vl-remove-if-not '(lambda (oid) (bht:kh-sign-scale-p (bht:obj-read oid))) (bht:obj-ids))
              index (bht:pt-all))
        (foreach pr (bht:tagged-pairs "INSERT" "BHT_KH" 1)
          (if (member (car pr) ids)
            (progn
              (setq e (cdr pr) d (entget e) rec (bht:obj-read (car pr))
                    st (bht:kh-ins-state e (car (bht:kh-auto-transform rec (bht:obj-position rec index) (bht:kh-scale-for rec))))
                    sc (bht:kh-scale-for rec)
                    nx (bht:kh-xdata-ins (car pr) (if (eq st 'AUTO) "TU_DONG" "TAY") (cdr (assoc 10 d)) (cdr (assoc 50 d)) sc))
              (entmod (append (bht:dxf-put (bht:dxf-put (bht:dxf-put d 41 sc) 42 sc) 43 sc) (list nx))) (entupd e))))
        (setq *bht-preserve-symbol-placement* T)
        (if ids (bht:api-alist (bht:symbol-sync-ex ids nil)) (list "Đã lưu tỷ lệ; áp dụng khi chèn biển và bảng."))))) (list symbol label)))

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

;; Scale only existing RTK labels; creating/arranging labels is a separate action.
(defun bht:api-rtk-scale (symbol label)
  (bht:api-run '(lambda (symbol label / s factor h r count pair e d)
    (setq s (bht:num (bht:replace (bht:str symbol) "," "."))
          factor (bht:num (bht:replace (bht:str label) "," ".")))
    (if (not (and s factor (>= s 0.01) (<= s 100.0) (>= factor 0.01) (<= factor 100.0)
                  (equal s (bht:num (bht:fnum s 3)) 1e-10) (equal factor (bht:num (bht:fnum factor 3)) 1e-10)))
      (list 'LOI "Tỷ lệ từ 0,01 đến 100, tối đa 3 chữ số thập phân.")
      (progn
        (setq h (* 0.5 factor) count 0)
        (bht:meta-set "nhan_h" (bht:fnum h 6))
        (setq r (bht:point-style-apply s nil))
        (foreach pair (bht:tagged-pairs "TEXT" "BHT_NHAN" 2)
          (setq e (cdr pair) d (entget e))
          (if (not (equal (cdr (assoc 40 d)) h 1e-9))
            (progn (entmod (bht:dxf-put d 40 h)) (entupd e) (setq count (1+ count)))))
        (append (bht:api-alist r) (list (strcat "label_height=" (bht:fnum h 6)) (strcat "updated=" (itoa count))))))) (list symbol label)))

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

(defun bht:api-object-station (id) (bht:api-run 'bht:station-one (list id)))

(defun bht:api-route-select (id)
  (bht:api-run '(lambda (id)
    (if (bht:route-read id) (progn (setq *bht-route-selected* id) (list id))
      (list 'LOI "Tuyến đã bị xóa hoặc không tồn tại."))) (list id)))

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
    bht:api-photo-path bht:api-object-delete bht:api-symbol-upgrade bht:api-sign-fill bht:api-sign-scale bht:api-sign-place bht:api-sign-free bht:api-symbol-sync bht:api-label-sync bht:api-point-style bht:api-rtk-scale bht:api-photo-sync bht:api-photo-stats
    bht:api-check bht:api-object-station bht:api-route-select bht:api-route-diag bht:api-draworder))

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
;; Symbol updates are explicit; do not modify a drawing while it is opening.
(setq *bht-palette-loaded* (bht:command-available-p "BTH"))
(defun bht:load-message () (strcat "BHT " *bht-version* " đã nạp thành công."))
(princ (strcat "\n" (bht:load-message)))
(if *bht-palette-loaded*
  (princ "\nGõ BTH hoặc BHT để mở Palette bên trái; BHTHELP để xem danh sách lệnh.")
  (princ "\nPalette chỉ nạp khi gọi lệnh. Gõ BHTLOAD rồi BTH để mở bảng."))
(princ)

