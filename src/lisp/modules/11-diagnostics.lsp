;;; ----------------------------------------------------------------------
;;; Kiem tra toan ven (BHTKT)
;;; ----------------------------------------------------------------------

;; Tra ve (so_loi so_canh_bao danh_sach_dong)
;; Ghi 1 dong ket qua kiem tra. Dung bien errs/warns/lines cua bht:check (pham vi dong).
(defun bht:ck-add (lvl s)
  (if (= lvl 2) (setq errs (1+ errs)) (if (= lvl 1) (setq warns (1+ warns))))
  (setq lines (cons (strcat (cond ((= lvl 2) "LỖI: ") ((= lvl 1) "CẢNH BÁO: ") (T "")) s) lines))
)

(defun bht:check (/ ss n i ent x ids dup legacy moved index loc errs warns lines objs owners rec pids
                    missing multi pc v0 v1 pend rid rrec ent2 marks segs nsym orph
                    lg ldup lorph lbad p mk mdup morig minv morph mpos mmiss jmiss one)
  (setq errs 0 warns 0 lines nil)
  ;; diem
  (setq ss (ssget "_X" (list '(0 . "POINT") '(-3 ("BHT_PT")))) n (if ss (sslength ss) 0) i 0 ids nil dup nil moved 0)
  (while (< i n)
    (setq ent (ssname ss i) x (bht:xget ent "BHT_PT") loc (cdr (assoc 10 (entget ent))))
    (if (member (strcase (car x)) ids) (setq dup (cons (car x) dup)) (setq ids (cons (strcase (car x)) ids)))
    (if (or (> (abs (- (car loc) (bht:num (nth 5 x)))) 1e-6) (> (abs (- (cadr loc) (bht:num (nth 4 x)))) 1e-6)
            (> (abs (- (caddr loc) (bht:num (nth 6 x)))) 1e-6))
      (progn (setq moved (1+ moved)) (bht:ck-add 2 (strcat "điểm " (car x) " bị dịch khỏi tọa độ gốc (X=E, Y=N, Z)"))))
    (setq i (1+ i)))
  (bht:ck-add 0 (strcat "Điểm RTK v0.2: " (itoa n) " | ID duy nhất: " (itoa (length ids)) " | trùng ID: " (itoa (length dup))
                        " | bị dịch: " (itoa moved)))
  (foreach d dup (bht:ck-add 2 (strcat "trùng survey_point_id " d)))
  (setq ss (ssget "_X" (list '(0 . "POINT") (cons 8 *bht-pt-layer*))) legacy 0 i 0)
  (if ss (while (< i (sslength ss))
           (if (and (bht:xget (ssname ss i) "BHT_RTK") (not (bht:xget (ssname ss i) "BHT_PT"))) (setq legacy (1+ legacy)))
           (setq i (1+ i))))
  (bht:ck-add 0 (strcat "Dataset: " (bht:join (bht:rec-keys "DATASET") ", ")))
  ;; doi tuong
  (setq objs (bht:rec-all "OBJ") owners (bht:pt-owner-map) missing 0 multi 0 pend 0)
  (foreach o objs
    (setq rec (cdr o) pids (bht:get-all rec "pt"))
    (if (null pids) (bht:ck-add 1 (strcat "đối tượng " (car o) " không có điểm RTK")))
    (foreach p pids (if (not (member (strcase p) ids))
                      (progn (setq missing (1+ missing)) (bht:ck-add 2 (strcat (car o) " tham chiếu điểm không tồn tại " p)))))
    (foreach a (bht:get-all rec "anh")
      (setq pc (bht:photo-read (car (bht:split a "|"))))
      (if (or (null pc) (not (member (strcase (car o)) (mapcar 'strcase (bht:get-all pc "doi_tuong")))))
        (bht:ck-add 2 (strcat "liên kết ảnh không đồng bộ: " (car o) " - " (car (bht:split a "|")))))))
  (foreach w owners (if (> (length (cdr w)) 1)
                      (progn (setq multi (1+ multi))
                             (bht:ck-add 1 (strcat "điểm " (car w) " thuộc nhiều đối tượng: " (bht:join (cdr w) ", "))))))
  (bht:ck-add 0 (strcat "Đối tượng: " (itoa (length objs)) " | điểm dùng chung: " (itoa multi)
                        " | điểm thiếu: " (itoa missing)))
  ;; anh
  (setq v0 0 v1 0 pc 0)
  (foreach pid (bht:rec-keys "PHOTO")
    (setq rec (bht:photo-read pid))
    (if (= (bht:get rec "gps_hop_le") "1") (setq v1 (1+ v1)) (setq v0 (1+ v0)))
    (if (member (bht:get rec "trang_thai") '("DE_XUAT" "MO_HO")) (setq pend (1+ pend)))
    (if (= (bht:get rec "trang_thai") "DA_XAC_NHAN") (setq pc (1+ pc)))
    (foreach o (bht:get-all rec "doi_tuong")
      (cond
        ((not (bht:obj-read o)) (bht:ck-add 2 (strcat "ảnh " pid " trỏ tới đối tượng không tồn tại " o)))
        ((not (member (strcase pid) (mapcar '(lambda (a) (strcase (car (bht:split a "|")))) (bht:get-all (bht:obj-read o) "anh"))))
         (bht:ck-add 2 (strcat "liên kết ảnh một chiều: ảnh " pid " ghi đối tượng " o " nhưng hồ sơ " o " không có ảnh này"))))))
  (bht:ck-add 0 (strcat "Ảnh: " (itoa (+ v0 v1)) " | GPS hợp lệ: " (itoa v1) " | GPS 0,0/không có: " (itoa v0)
                        " | đã xác nhận: " (itoa pc) " | chờ duyệt: " (itoa pend)))
  (if (> pend 0) (bht:ck-add 1 (strcat (itoa pend) " ảnh có đề xuất chưa duyệt (BHTXACNHANANH)")))
  ;; tuyen
  (foreach rid (bht:route-ids)
    (setq rrec (bht:route-read rid) ent2 (bht:route-ent rrec) marks (bht:route-marks rrec))
    (cond ((null ent2) (bht:ck-add 2 (strcat "tuyến " rid ": không còn Polyline (handle " (bht:get rrec "handle") ")")))
          ((not (car (bht:route-check-ent ent2))) (bht:ck-add 2 (strcat "tuyến " rid ": " (cadr (bht:route-check-ent ent2))))))
    (if (null marks) (bht:ck-add 1 (strcat "tuyến " rid " chưa có mốc Km -> lý trình chưa xác định")))
    (setq i 0)
    (while (< i (1- (length marks)))
      (setq v0 (/ (- (nth 1 (nth (1+ i) marks)) (nth 2 (nth i marks))) (- (nth 0 (nth (1+ i) marks)) (nth 0 (nth i marks)))))
      (if (> (abs (- (abs v0) 1.0)) *bht-ratio-tol*)
        (bht:ck-add 1 (strcat "tuyến " rid ": hệ số đoạn mốc " (itoa i) "-" (itoa (1+ i)) " = " (bht:fnum v0 4) " (kiểm tra mốc/tuyến)")))
      (if (and (> i 0) (/= (minusp v0) (minusp v1)))
        (bht:ck-add 2 (strcat "tuyến " rid ": chiều tăng Km đổi dấu giữa các mốc - kiểm tra lại mốc")))
      (setq v1 v0 i (1+ i)))
    (bht:ck-add 0 (strcat "Tuyến " rid " (" (bht:get rrec "loai") "): " (itoa (length marks)) " mốc")))
  ;; goi thau
  (setq segs (bht:rec-keys "SEG"))
  (bht:ck-add 0 (strcat "Đoạn tuyến đã nạp: " (itoa (length segs))))
  (setq i 0)
  (foreach o objs (if (= (bht:get (cdr o) "gan_doan_pp") "NHIEU_DOAN") (setq i (1+ i))))
  (if (> i 0) (bht:ck-add 1 (strcat (itoa i) " đối tượng thuộc nhiều đoạn chồng lấn - cần BHTGANDOAN")))
  ;; ky hieu
  (setq ss (ssget "_X" (list '(0 . "INSERT") '(-3 ("BHT_KH")))) nsym (if ss (sslength ss) 0) orph 0 i 0)
  (while (< i nsym)
    (if (not (bht:obj-read (car (bht:xget (ssname ss i) "BHT_KH")))) (setq orph (1+ orph)))
    (setq i (1+ i)))
  (bht:ck-add 0 (strcat "Ký hiệu: " (itoa nsym) " | mồ côi: " (itoa orph)))
  (if (> orph 0) (bht:ck-add 1 "có ký hiệu không còn hồ sơ - chạy BHTKYHIEU để cập nhật (chỉ xóa ký hiệu của hồ sơ đã xóa)"))
  ;; 0.3.3: ky hieu / nhan dat tay
  (setq i 0)
  (foreach pr (bht:tagged-pairs "INSERT" "BHT_KH" 1)
    (if (and (>= (length (bht:xget (cdr pr) "BHT_KH")) 6) (= (nth 1 (bht:xget (cdr pr) "BHT_KH")) "TAY")) (setq i (1+ i))))
  (setq n 0)
  (foreach pr (bht:tagged-pairs "TEXT" "BHT_NHAN" 2) (if (= (bht:lbl-state (cdr pr)) 'TAY) (setq n (1+ n))))
  (bht:ck-add 0 (strcat "Ký hiệu đặt tay (giữ khi cập nhật): " (itoa i) " | nhãn điểm dời tay: " (itoa n)))
  (setq i 0)
  (foreach o objs (if (null (bht:symbol-exists (car o))) (setq i (1+ i))))
  (if (and (> i 0) (> nsym 0)) (bht:ck-add 1 (strcat (itoa i) " hồ sơ chưa có ký hiệu - chạy BHTKYHIEU")))
  ;; 0.3.3: thuc the BHT nam ngoai Model
  (setq i (length (bht:ents-outside-model)))
  (if (> i 0) (bht:ck-add 1 (strcat (itoa i) " thực thể BHT nằm trong Layout (paper space) - kiểm tra vị trí thực thể trong Layout")))
  ;; nhan diem RTK (0.3.2)
  (setq lg (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_NHAN" 2)) ldup 0 lorph 0 lbad 0 index (bht:pt-all))
  (foreach g lg
    (if (> (length (cdr g)) 1) (setq ldup (1+ ldup)))
    (setq p (bht:pt-find (car (bht:split (car g) "|")) index))
    (cond ((null p) (setq lorph (1+ lorph)))
          ((/= (cdr (assoc 1 (entget (cadr g)))) (bht:lbl-text p (cadr (bht:split (car g) "|")))) (setq lbad (1+ lbad)))))
  (bht:ck-add 0 (strcat "Nhãn điểm RTK: " (itoa (length lg)) " | trùng: " (itoa ldup) " | mồ côi: " (itoa lorph)
                        " | lệch nội dung: " (itoa lbad)))
  (if (> ldup 0) (bht:ck-add 2 (strcat (itoa ldup) " nhãn điểm bị nhân đôi - chạy BHTNHANDIEM để dọn")))
  (if (> lorph 0) (bht:ck-add 1 (strcat (itoa lorph) " nhãn không còn điểm RTK - chạy BHTNHANDIEM để dọn")))
  (if (> lbad 0) (bht:ck-add 1 (strcat (itoa lbad) " nhãn khác dữ liệu gốc (bị sửa tay?) - chạy BHTNHANDIEM để cập nhật")))
  ;; ky hieu anh (0.3.2)
  (setq mk (bht:group-pairs (bht:tagged-pairs "INSERT" "BHT_ANHPT" 1)) mdup 0 morig 0 minv 0 morph 0 mpos 0 mmiss 0 jmiss 0)
  (foreach g mk
    (setq rec (bht:photo-read (car g)))
    (if (> (length (cdr g)) 1) (setq mdup (1+ mdup)))
    (foreach e (cdr g)
      (setq loc (cdr (assoc 10 (entget e))))
      (if (and (< (abs (car loc)) 0.001) (< (abs (cadr loc)) 0.001)) (setq morig (1+ morig))))
    (setq loc (cdr (assoc 10 (entget (cadr g)))))
    (cond ((null rec) (setq morph (1+ morph)))
          ((/= (bht:get rec "gps_hop_le") "1") (setq minv (1+ minv)))
          ((or (null (bht:num (bht:get rec "e"))) (null (bht:num (bht:get rec "n")))
               (> (abs (- (car loc) (bht:num (bht:get rec "e")))) 0.01)
               (> (abs (- (cadr loc) (bht:num (bht:get rec "n")))) 0.01))
           (setq mpos (1+ mpos)))))
  (foreach pid (bht:rec-keys "PHOTO")
    (setq rec (bht:photo-read pid))
    (if (and (= (bht:get rec "gps_hop_le") "1") (not (assoc pid mk))) (setq mmiss (1+ mmiss)))
    (if (null (bht:photo-path rec)) (setq jmiss (1+ jmiss))))
  (bht:ck-add 0 (strcat "Ký hiệu ảnh: " (itoa (length mk)) " ảnh có ký hiệu | trùng: " (itoa mdup)
                        " | ở gốc 0,0: " (itoa morig) " | ảnh không GPS có ký hiệu: " (itoa minv)
                        " | mồ côi: " (itoa morph) " | lệch vị trí: " (itoa mpos) " | ảnh GPS thiếu ký hiệu: " (itoa mmiss)
                        " | thiếu JPG: " (itoa jmiss)))
  (if (> mdup 0) (bht:ck-add 2 (strcat (itoa mdup) " ảnh có ký hiệu bị nhân đôi - chạy BHTDONGBOANH")))
  (if (> morig 0) (bht:ck-add 2 (strcat (itoa morig) " ký hiệu ảnh nằm ở gốc 0,0 - chạy BHTDONGBOANH")))
  (if (> minv 0) (bht:ck-add 2 (strcat (itoa minv) " ảnh GPS 0,0 lại có ký hiệu - chạy BHTDONGBOANH")))
  (if (> morph 0) (bht:ck-add 1 (strcat (itoa morph) " ký hiệu ảnh không còn bản ghi - chạy BHTDONGBOANH")))
  (if (> mpos 0) (bht:ck-add 1 (strcat (itoa mpos) " ký hiệu ảnh lệch vị trí (đổi hệ tọa độ?) - chạy BHTDONGBOANH")))
  (if (> mmiss 0) (bht:ck-add 1 (strcat (itoa mmiss) " ảnh GPS hợp lệ chưa có ký hiệu - chạy BHTDONGBOANH")))
  (if (> jmiss 0) (bht:ck-add 1 (strcat (itoa jmiss) " ảnh không tìm thấy file JPG - BHTTHUMUCANH")))
  (list errs warns (reverse lines))
)

(defun c:BHTKT (/ *error* r)
  (setq *error* bht:on-error)
  (setq r (bht:check))
  (foreach l (caddr r) (bht:msg (strcat "  " l)) (bht:log l))
  (bht:msg (strcat "BHTKT: " (itoa (car r)) " lỗi, " (itoa (cadr r)) " cảnh báo."))
  (bht:log-flush)
  (princ)
)
(defun c:BHTCHECK () (c:BHTKT))

;;; ----------------------------------------------------------------------
;;; Thong tin / chan doan
;;; ----------------------------------------------------------------------

(defun bht:obj-info-lines (oid / rec out)
  (setq rec (bht:obj-read oid) out (list (strcat "=== Đối tượng " (bht:str oid) " ===")))
  (if (null rec) (setq out (append out (list "  (không có hồ sơ)"))))
  (foreach p rec (setq out (append out (list (strcat "  " (car p) " = " (cdr p))))))
  out
)

(defun bht:obj-info (oid)
  (foreach l (bht:obj-info-lines oid) (bht:msg l))
)

;; Thong tin 1 diem RTK: du lieu goc, nhan, doi tuong, anh lien quan.
(defun bht:point-info-lines (p / id owners out lg kinds ph xyz)
  (setq id (strcase (bht:pv p 'id)) xyz (bht:pv p 'xyz)
        out (list (strcat "=== Điểm " (bht:pv p 'id) " ===")
                  (strcat "  dataset " (bht:pv p 'ds) ", dòng " (bht:pv p 'row))
                  (strcat "  tên: " (bht:pv p 'name))
                  (strcat "  N (Bắc) gốc: " (bht:pv p 'n) "  E (Đông) gốc: " (bht:pv p 'e) "  Z gốc: " (bht:pv p 'z))
                  (strcat "  mô tả gốc: [" (bht:pv p 'desc) "]")
                  (strcat "  phân loại gợi ý: " (bht:pv p 'cls) " | file nguồn: " (bht:pv p 'src))
                  (strcat "  CAD X,Y,Z: " (bht:fnum (car xyz) 3) ", " (bht:fnum (cadr xyz) 3) ", " (bht:fnum (caddr xyz) 3))))
  (setq lg (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_NHAN" 2)) kinds nil)
  (foreach k *bht-lbl-kinds*
    (if (assoc (strcat id "|" (car k)) lg)
      (setq kinds (append kinds (list (strcat (car k) (if (eq (bht:lbl-state (cadr (assoc (strcat id "|" (car k)) lg))) 'TAY)
                                                       " (dời tay)" " (tự động)")))))))
  (setq out (append out (list (strcat "  nhãn trên bản vẽ: " (if kinds (bht:join kinds ", ") "(chưa có - BHTNHANDIEM)")))))
  (setq owners (cdr (assoc id (bht:pt-owner-map))))
  (setq out (append out (list (strcat "  thuộc đối tượng: " (if owners (bht:join owners ", ") "(chưa)")))))
  (setq ph (bht:photos-for-point id))
  (setq out (append out (list (strcat "  ảnh đã xác nhận: " (if (car ph) (bht:join (car ph) ", ") "(không)"))
                              (strcat "  ảnh đề xuất (chưa xác nhận): " (if (cadr ph) (bht:join (cadr ph) ", ") "(không)"))
                              (strcat "  ảnh chụp gần (chỉ gợi ý): " (if (caddr ph) (bht:join (caddr ph) ", ") "(không)")))))
  (foreach o owners (setq out (append out (bht:obj-info-lines o))))
  out
)

;; Thong tin cua 1 thuc the bat ky (ham khong tuong tac, dung cho BHTINFO va kiem thu).
(defun bht:info-lines (ent / p x)
  (cond
    ((or (null ent) (null (entget ent))) (list "Không có đối tượng."))
    ((setq p (bht:pt-from-ent ent)) (bht:point-info-lines p))
    ((setq x (bht:xget ent "BHT_NHAN"))
     (cons (strcat "Nhãn " (bht:str (cadr x)) " của điểm " (car x))
           (if (setq p (bht:pt-find (car x) (bht:pt-all)))
             (bht:point-info-lines p)
             (list "  (điểm RTK không còn - nhãn mồ côi; chạy BHTNHANDIEM để dọn)"))))
    ((setq x (bht:xget ent "BHT_KH")) (bht:obj-info-lines (car x)))
    ((or (setq x (bht:xget ent "BHT_ANHPT")) (setq x (bht:xget ent "BHT_ANHTEN")) (setq x (bht:xget ent "BHT_ANHRS")))
     (bht:photo-info-lines (car x)))
    ((setq x (bht:xget ent "BHT_RTK")) (list (strcat "Điểm v0.1: " (bht:join x " | ") " (chưa có ID v0.2)")))
    (T (list "Không có dữ liệu BHT trên đối tượng này.")))
)

(defun c:BHTINFO (/ *error* sel ent x)
  (setq *error* bht:on-error)
  (if (setq sel (entsel "\nChọn điểm RTK / nhãn / ký hiệu BHT / ký hiệu ảnh: "))
    (progn
      (setq ent (car sel))
      (foreach l (bht:info-lines ent) (bht:msg l))
      (if (or (setq x (bht:xget ent "BHT_ANHPT")) (setq x (bht:xget ent "BHT_ANHTEN")) (setq x (bht:xget ent "BHT_ANHRS")))
        (if (= (strcase (bht:ask-string "Mở ảnh này? [C/K]" "C")) "C") (bht:photo-browse (car x))))))
  (princ)
)

;; Thong ke proxy theo layer (khong goi vlax-curve tren proxy).
(defun bht:proxy-stats (/ ss i ent lay out it)
  (setq out nil i 0 ss (ssget "_X" '((0 . "ACAD_PROXY_ENTITY"))))
  (if ss
    (while (< i (sslength ss))
      (setq lay (cdr (assoc 8 (entget (ssname ss i)))))
      (if (setq it (assoc lay out))
        (setq out (subst (cons lay (1+ (cdr it))) it out))
        (setq out (cons (cons lay 1) out)))
      (setq i (1+ i))))
  out
)

(defun c:BHTDIAG (/ *error* sel ent data obj on chk st)
  (setq *error* bht:on-error)
  (initget "Tatca")
  (setq sel (entsel "\nChọn đối tượng cần chẩn đoán hoặc [Tatca = thống kê proxy]: "))
  (cond
    ((= sel "Tatca")
     (setq st (bht:proxy-stats))
     (bht:msg (strcat "ACAD_PROXY_ENTITY trong bản vẽ: " (itoa (apply '+ (cons 0 (mapcar 'cdr st))))))
     (foreach s st (princ (strcat "\n  layer " (car s) ": " (itoa (cdr s)))))
     (bht:msg (strcat "Layer Tuyen: " (itoa (if (ssget "_X" '((8 . "Tuyen"))) (sslength (ssget "_X" '((8 . "Tuyen")))) 0)) " đối tượng.")))
    (sel
     (setq ent (car sel) data (entget ent)
           obj (vl-catch-all-apply 'vlax-ename->vla-object (list ent))
           on (if (vl-catch-all-error-p obj) "không lấy được" (vl-catch-all-apply 'vla-get-ObjectName (list obj))))
     (if (vl-catch-all-error-p on) (setq on "không lấy được"))
     (setq chk (bht:route-check-ent ent))
     (bht:msg (strcat "DXF: " (cdr (assoc 0 data)) " | Layer: " (cdr (assoc 8 data)) " | Handle: " (cdr (assoc 5 data))
                      " | ObjectName: " on))
     (bht:msg (strcat "Dùng làm tuyến tham chiếu: " (if (car chk) "ĐƯỢC" (strcat "KHÔNG - " (cadr chk)))))))
  (princ)
)

;;; ----------------------------------------------------------------------
;;; ----------------------------------------------------------------------

;;; ----------------------------------------------------------------------
;;; Tu kiem tra ham thuan (khong sua ban ve) - BHTTEST
;;; ----------------------------------------------------------------------

;; Ghi 1 ket qua tu kiem tra (dung bien pass/fail cua bht:selftest, pham vi dong).
(defun bht:st-chk (name ok)
  (if ok (setq pass (1+ pass))
    (progn (setq fail (1+ fail)) (bht:msg (strcat "  FAIL " name))))
)

(defun bht:selftest (/ pass fail marks r en segs fp rec)
  (setq pass 0 fail 0)
  (bht:st-chk "csv ngoặc kép" (equal (bht:csv-fields "P1,1,2,3,\"207,e\"") '("P1" "1" "2" "3" "207,e")))
  (bht:st-chk "csv escape" (= (bht:csv-cell "a\"b,c") "\"a\"\"b,c\""))
  (bht:st-chk "csv tiếng Việt" (equal (bht:csv-fields "Đ1,1,2,3,biển cấm") '("Đ1" "1" "2" "3" "biển cấm")))
  (bht:st-chk "số hợp lệ" (equal (bht:num "1187855.825") 1187855.825 1e-9))
  (bht:st-chk "số sai" (null (bht:num "12a")))
  (bht:st-chk "fnum" (and (= (bht:fnum 0.5 3) "0.500") (= (bht:fnum -2.25 1) "-2.3") (= (bht:fnum 1187855.825 3) "1187855.825")))
  (bht:st-chk "parse km" (and (equal (bht:parse-km "Km39+050.5") 39050.5 1e-9) (equal (bht:parse-km "40+127") 40127.0 1e-9)
                       (equal (bht:parse-km "39000") 39000.0 1e-9) (null (bht:parse-km "abc"))))
  (bht:st-chk "format km" (and (= (bht:fmt-km 39050.5) "Km39+050.50") (= (bht:fmt-km 40000.0) "Km40+000.00")))
  (bht:st-chk "id hợp lệ" (and (bht:valid-id "BOT19-R-000001") (not (bht:valid-id "a b")) (not (bht:valid-id ""))))
  (bht:st-chk "make id" (= (bht:make-id "BOT19" "R" 7) "BOT19-R-000007"))
  (bht:st-chk "phân loại" (and (= (bht:classify "bbtron1m25 gioihan80") "BIEN_BAO") (= (bht:classify "coctiu.h5-48") "COC_TIEU")
                        (= (bht:classify "cockm45") "COT_KM") (= (bht:classify "bbqcphan  1.2x2.35") "BANG_QC")
                        (= (bht:classify "hoga") "CHUA_XAC_DINH")))
  (bht:st-chk "record mã hóa" (equal (bht:rec-decode (mapcar '(lambda (s) (cons 1 s))
                                               (mapcar 'cdr (bht:rec-encode (list (cons "a" "x=1") (cons "pt" "P1") (cons "pt" "P2"))))))
                              (list (cons "a" "x=1") (cons "pt" "P1") (cons "pt" "P2"))))
  ;; ly trinh: moc 0 -> 39000, gay tai 500 (39500/39600), 1000 -> 40100
  (setq marks '((0.0 39000.0 39000.0) (500.0 39500.0 39600.0) (1000.0 40100.0 40100.0)))
  (setq r (bht:km-from-dist marks 250.0 0.0 nil))
  (bht:st-chk "nội suy" (and (= (car r) "NOI_SUY") (equal (cadr r) 39250.0 1e-9)))
  (setq r (bht:km-from-dist marks 750.0 0.0 nil))
  (bht:st-chk "không nội suy qua điểm gãy" (equal (cadr r) 39850.0 1e-9))
  (bht:st-chk "ngoài mốc = chưa xác định" (= (car (bht:km-from-dist marks 1200.0 0.0 nil)) "CHUA_XAC_DINH"))
  (bht:st-chk "ngoại suy cho phép" (equal (cadr (bht:km-from-dist marks 1010.0 20.0 nil)) 40110.0 1e-9))
  (bht:st-chk "không mốc" (= (car (bht:km-from-dist nil 10.0 0.0 nil)) "CHUA_CO_MOC"))
  (bht:st-chk "1 mốc thiếu chiều" (= (car (bht:km-from-dist '((0.0 39000.0 39000.0)) 10.0 1e9 nil)) "CHUA_XAC_DINH"))
  (bht:st-chk "1 mốc có chiều" (equal (cadr (bht:km-from-dist '((0.0 39000.0 39000.0)) 10.0 1e9 1)) 39010.0 1e-9))
  (bht:st-chk "chiều giảm" (equal (cadr (bht:km-from-dist '((0.0 40000.0 40000.0) (1000.0 39000.0 39000.0)) 250.0 0.0 nil)) 39750.0 1e-9))
  (bht:st-chk "hệ số lệch -> cần kiểm tra" (= (car (bht:km-from-dist '((0.0 39000.0 39000.0) (1000.0 39100.0 39100.0)) 5.0 0.0 nil)) "CAN_KIEM_TRA"))
  ;; ung vien doan
  (setq segs (list (cons "DOAN02" (list (cons "km_start_m" "39000") (cons "km_end_m" "40127") (cons "side" "TRAI")))
                   (cons "DOAN12" (list (cons "km_start_m" "38723") (cons "km_end_m" "40127") (cons "side" "PHAI")))
                   (cons "DOAN01" (list (cons "km_start_m" "38622") (cons "km_end_m" "38697") (cons "side" "HAI_BEN")))))
  (bht:st-chk "đoạn theo phía trái" (equal (bht:seg-candidates 39250.0 "TRAI" segs) '("DOAN02")))
  (bht:st-chk "đoạn chưa rõ phía" (equal (bht:seg-candidates 39250.0 nil segs) '("DOAN02" "DOAN12")))
  (bht:st-chk "đoạn hai bên" (equal (bht:seg-candidates 38650.0 "PHAI" segs) '("DOAN01")))
  (bht:st-chk "ngoài đoạn" (null (bht:seg-candidates 45000.0 nil segs)))
  ;; chuyen doi toa do (so sanh voi cung cong thuc tinh doc lap bang Python)
  (setq en (bht:project 106.43828833333333 10.753013333333334 105.75 0.9999))
  (bht:st-chk "WGS84->VN2000 KTT 105°45'" (and (equal (car en) 575081.764 0.002) (equal (cadr en) 1189223.379 0.002)))
  (bht:st-chk "bỏ dấu tìm kiếm" (and (= (bht:fold-vi "Nhập điểm ĐƯỜNG") "Nhap diem DUONG")
                               (= (bht:fold-vi "từ — ảnh") "tu - anh")))
  ;; 0.3.2: nhan diem / anh
  (bht:st-chk "chế độ nhãn" (and (equal (bht:lbl-kinds-for "T" nil) '("TEN"))
                                  (equal (bht:lbl-kinds-for "tmc" T) '("TEN" "MOTA" "CAODO" "ID"))))
  (setq fp (list (cons 'id "BOT19-R-000384") (cons 'name "384") (cons 'desc "dgbtxuogthur") (cons 'z "2.909")
                 (cons 'xyz '(10.0 20.0 2.909))))
  (bht:st-chk "nội dung nhãn nguyên văn" (and (= (bht:lbl-text fp "TEN") "384") (= (bht:lbl-text fp "MOTA") "dgbtxuogthur")
                                               (= (bht:lbl-text fp "CAODO") "H = 2.909")
                                               (= (bht:lbl-text (subst (cons 'z "2.90") (assoc 'z fp) fp) "CAODO") "H = 2.90")))
  (setq r (bht:lbl-wanted (subst (cons 'desc "") (assoc 'desc fp) fp) '("TEN" "MOTA" "CAODO") 1.0 0.5))
  (bht:st-chk "bỏ nhãn mô tả rỗng" (and (= (length r) 2) (= (car (nth 1 r)) "CAODO")
                                        (equal (caddr (nth 1 r)) '(10.5 19.0 2.909) 1e-9)))
  (setq r (bht:group-pairs (list (cons "A" 1) (cons "B" 2) (cons "A" 3))))
  (bht:st-chk "gom nhãn trùng" (and (= (length r) 2) (= (length (assoc "A" r)) 3)))
  (setq rec (list (cons "duong_dan" "photos/origin_photo_0.jpg") (cons "goc" "C:\\BHT_ANH")))
  (bht:st-chk "đường dẫn ảnh tương đối" (= (car (bht:photo-path-candidates rec)) "C:\\BHT_ANH\\photos\\origin_photo_0.jpg"))
  (bht:st-chk "file không tồn tại" (and (not (bht:file-ok nil)) (not (bht:file-ok "Z:\\khong\\co.jpg"))))
  (bht:st-chk "dxf-put" (equal (bht:dxf-put '((1 . "a") (8 . "0")) 8 "L") '((1 . "a") (8 . "L"))))
  ;; 0.3.3: bo tri nhan, trang thai nhan, uu tien ho so, mau IRT
  (bht:st-chk "giao hộp" (and (equal (bht:box-ov '(0.0 0.0 2.0 2.0) '(1.0 1.0 3.0 3.0)) 1.0 1e-9)
                              (= (bht:box-ov '(0.0 0.0 1.0 1.0) '(1.0 0.0 2.0 1.0)) 0.0)))
  (setq r (bht:lbl-cands 10.0 20.0 4.0 1.0 0.5 1.0))
  (bht:st-chk "64 vị trí ứng viên, đầu tiên Đông-Bắc" (and (= (length r) 64) (equal (car r) '(10.5 20.5) 1e-9)))
  (bht:st-chk "cụm nhãn giữ khoảng dòng an toàn 1,5H" (equal (bht:lbl-line-step 2.0) 3.0 1e-9))
  (setq r (bht:lbl-layout (list (list "A" 0.0 0.0 4.0 1.25) (list "B" 0.0 0.0 4.0 1.25)) nil 0.5 1.0))
  (bht:st-chk "hai nhãn cùng vị trí không chồng nhau"
              (and (= (length r) 2)
                   (= (bht:box-ov (list (cadr (car r)) (caddr (car r)) (+ (cadr (car r)) 4.0) (+ (caddr (car r)) 1.25))
                                  (list (cadr (cadr r)) (caddr (cadr r)) (+ (cadr (cadr r)) 4.0) (+ (caddr (cadr r)) 1.25)))
                      0.0)))
  (setq r (bht:lbl-layout (list (list "A" 0.0 0.0 4.0 1.25)) (list '(0.0 0.0 10.0 10.0)) 0.5 1.0))
  (bht:st-chk "nhãn tránh vật cản" (and (= (cadddr (car r)) 0.0)
                                        (= (bht:box-ov (list (cadr (car r)) (caddr (car r)) (+ (cadr (car r)) 4.0) (+ (caddr (car r)) 1.25))
                                                       '(0.0 0.0 10.0 10.0)) 0.0)))
  (setq fp (list (cons 'id "X-R-1") (cons 'xyz '(10.0 20.0 0.0))))
  (bht:st-chk "vị trí mặc định nhãn 0.3.2" (and (equal (bht:lbl-legacy-pos fp "CAODO" '("TEN" "MOTA" "CAODO") 1.0 0.5) '(10.5 17.5) 1e-9)
                                              (equal (bht:lbl-legacy-pos fp "CAODO" '("TEN" "CAODO") 1.0 0.5) '(10.5 19.0) 1e-9)))
  (bht:st-chk "ưu tiên hồ sơ ẩn nhãn phụ" (and (equal (bht:lbl-kinds-point '("TEN" "MOTA" "CAODO") "P1" '(("P1" "OBJ-000001")) T) '("TEN"))
                                             (equal (bht:lbl-kinds-point '("TEN" "MOTA") "P2" '(("P1" "OBJ-000001")) T) '("TEN" "MOTA"))
                                             (equal (bht:lbl-kinds-point '("TEN" "MOTA") "P1" '(("P1" "OBJ-000001")) nil) '("TEN" "MOTA"))))
  (bht:st-chk "mẫu thư mục tile IRT (IRT\\ / IRT.cache), không nhầm thư mục ảnh BHT"
              (and (wcmatch (bht:path-norm "D:/Data/IRT/sat/18/x.jpg") *bht-irt-dir-pat*)
                   (wcmatch (bht:path-norm "C:\\u\\IRT.cache\\t.jpg") *bht-irt-dir-pat*)
                   (not (wcmatch (bht:path-norm "D:/anh/IRTX/a.jpg") *bht-irt-dir-pat*))
                   (not (wcmatch (bht:path-norm "D:/BHT/photos/origin_photo_0.jpg") *bht-irt-dir-pat*))))
  (bht:st-chk "mẫu nhận diện ảnh nền IRT" (and (wcmatch "IRT_GOOGLE" *bht-irt-layer-pat*) (not (wcmatch "BHT_ANH_RASTER" *bht-irt-layer-pat*))
                                              (wcmatch "GOOGLE_SAT_18_1" *bht-irt-file-pat*) (not (wcmatch "ORIGIN_PHOTO_0" *bht-irt-file-pat*))))
  ;; 0.4.0: API cho plugin .NET
  (bht:st-chk "API phiên bản" (equal (bht:api-version) (list "OK" *bht-version* *bht-api-level* *bht-build*)))
  (bht:st-chk "API tách danh sách ID" (equal (bht:api-ids "OBJ-1, OBJ-2;OBJ-3") '("OBJ-1" "OBJ-2" "OBJ-3")))
  (bht:st-chk "API bắt lỗi" (= (car (bht:api-run '(lambda () (/ 1 0)) nil)) "LOI"))
  (bht:msg (strcat "BHTTEST: " (itoa pass) " PASS, " (itoa fail) " FAIL (chỉ kiểm tra hàm thuần; không thay nghiệm thu CAD)."))
  (list pass fail)
)

(defun c:BHTTEST (/ *error*)
  (setq *error* bht:on-error)
  (bht:selftest)
  (princ)
)

;;; ----------------------------------------------------------------------
;;; Huong dan
;;; ----------------------------------------------------------------------

(defun bht:help-text ()
  (bht:msg (strcat "BHT " *bht-version* " (" *bht-build* ") - danh sách lệnh:"))
  (foreach l
    '("  Quy trình: 1 Nhập điểm RTK -> 2 Nhãn điểm -> 3 Nhập TimeMark -> 4 Kiểm tra/xem ảnh -> 5 Ghép ảnh"
      "             -> 6 Hồ sơ đối tượng -> 7 Ký hiệu -> 8 Tuyến + Km -> 9 Xuất thống kê (gõ BHT để mở bảng)"
      "  BHTNHAP      Nhập CSV RTK (MẶC ĐỊNH; tên, Bắc, Đông, Z, mô tả) -> POINT layer BHT_RTK, ID <dataset>-R-<dòng> (BHTIMPORT, BHTCSV)"
      "  BHTNHAPTSV   Nhập BHT_RTK.tsv (định dạng trao đổi/chuẩn hóa; KHÔNG cần nhập lại dữ liệu đã nhập bằng CSV) (BHTNK)"
      "  BHTNHANDIEM  Nhãn điểm RTK: tên / +mô tả / +cao độ, ưu tiên hồ sơ, ID nội bộ, sắp xếp, ẩn/hiện, cài đặt (BHTLABEL)"
      "  BHTSAPNHAN   Sắp xếp nhãn tránh chồng lấn theo vùng chọn / danh sách ID / tất cả (POINT không bị di chuyển)"
      "  BHTKIEUDIEM  Đặt POINT thành dấu X đúng tâm, mặc định 1 unit; tùy chọn sắp lại toàn bộ nhãn"
      "  BHTNHANTUDONG Trả nhãn đã dời tay về vị trí tự động   BHTANNHAN  Ẩn / hiện nhãn điểm RTK"
      "  BHTDOITUONG  Tạo hồ sơ đối tượng từ nhiều điểm RTK (điểm đã thuộc hồ sơ khác: xem / sửa / thêm điểm / tạo mới có xác nhận) (BHTTAG)"
      "  BHTSUADT     Sửa hồ sơ (BHTEDIT)      BHTXOADT   Xóa hồ sơ, giữ điểm (BHTDELETE)"
      "  BHTTHEMDIEM  Thêm điểm vào đối tượng  BHTBOTDIEM Gỡ điểm khỏi đối tượng (BHTUNTAG)"
      "  BHTKMZ       Giải nén KMZ TimeMark -> ảnh + BHT_PHOTO.tsv (giữ cả ảnh GPS 0,0)"
      "  BHTANHNAP    Nạp BHT_PHOTO.tsv vào bản vẽ (BHTDSANH)   BHTHETOADO  Chọn hệ VN-2000 cho ảnh GPS"
      "  BHTGHEPANH   Đề xuất ghép ảnh - điểm/đối tượng (CHỈ đề xuất)"
      "  BHTXACNHANANH Duyệt/xác nhận đề xuất   BHTGANANH  Gắn ảnh thủ công (BHTPHOTO)   BHTBOANH  Bỏ ảnh"
      "  BHTXEMANH    Xem ảnh: chọn ký hiệu ảnh / điểm RTK / nhập mã -> thông tin + mở JPG, ảnh trước/sau, gắn đối tượng"
      "  BHTANH       Mở ảnh theo mã (T = đặt thư mục ảnh)   BHTTHUMUCANH  Chỉ lại thư mục ảnh khi mất đường dẫn"
      "  BHTDONGBOANH Đồng bộ ký hiệu + nhãn mã ảnh + đường dẫn từ bản ghi (không trùng; ảnh GPS 0,0 không có ký hiệu) (BHTSYNCANH)"
      "  BHTNHANANH   Ẩn / hiện nhãn mã ảnh   BHTCHENANH  Chèn ảnh JPG đã chọn làm raster (+ đường dẫn tùy chọn; không chèn hàng loạt)"
      "  BHTTUYEN     Khai báo Polyline tuyến tham chiếu (từ chối proxy TDT)"
      "  BHTMOCKM     Thêm mốc Km đã xác nhận / điểm gãy Km   BHTDSMOC  Xem/xóa mốc"
      "  BHTLYTRINH   Tính lý trình/offset cho đối tượng (không mốc = chưa xác định)"
      "  BHTGOITHAU   Nạp BHT_GOI_THAU.tsv   BHTPHANDOAN  Gán đoạn/gói tự động   BHTGANDOAN  Gán tay"
      "  BHTDATTUDO   Chọn hướng, điểm trung gian và vị trí đặt ký hiệu tự do"
      "  BHTKYHIEU    Chèn / cập nhật ký hiệu theo object_id (giữ vị trí người dùng đặt; R = trả về tự động)"
      "  BHTBLOCK     Danh mục block chuẩn / nạp DWG tùy chọn / trở lại mặc định"
      "  BHTBBDANHMUC Danh mục biển báo từ ảnh KMZ DT830, đối chiếu QCVN 41:2024"
      "  BHTTHUTUVE   Thứ tự hiển thị: nhãn > ký hiệu/điểm > raster BHT > ảnh nền IRT"
      "  BHTXUAT      Xuất CSV: DIEM_RTK, DOI_TUONG, ANH, TONG_HOP (BHTEXPORT, BHTSUMMARY)"
      "  BHTKT        Kiểm tra toàn vẹn (BHTCHECK)   BHTINFO  Xem dữ liệu   BHTDIAG  Chẩn đoán đối tượng/proxy"
      "  BHTTRANGTHAI Trạng thái bản vẽ (điểm, nhãn, hồ sơ, ảnh, JPG, ghép, tuyến, lý trình)"
      "  BHTTEST      Tự kiểm tra hàm   BTH/BHT  Mở Palette   BHTHELP  Danh sách này"
      "  BHTLOAD      Kiểm tra / nạp lại Palette")
    (princ (strcat "\n" l)))
  (princ)
)
(defun c:BHTHELP () (bht:help-text))

;;; ----------------------------------------------------------------------
;;; 0.3.2: Trang thai ban ve (bang dieu khien + BHTTRANGTHAI)
;;; ----------------------------------------------------------------------

(defun bht:status-data (/ idx lg labeled objs chain)
  (setq idx (bht:pt-all) lg (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_NHAN" 2)) labeled 0 chain 0)
  (foreach it idx (if (assoc (strcat (car it) "|TEN") lg) (setq labeled (1+ labeled))))
  (setq objs (bht:obj-ids))
  (foreach o objs (if (/= (bht:get (bht:obj-read o) "ly_trinh_m") "") (setq chain (1+ chain))))
  (append (list (cons 'points (length idx)) (cons 'labeled labeled) (cons 'objects (length objs))
                (cons 'routes (length (bht:route-ids))) (cons 'chainage chain)
                (cons 'segments (length (bht:rec-keys "SEG"))))
          (bht:photo-stats))
)

(defun bht:stv (s k) (bht:str (cdr (assoc k s))))

;; Cac ghi chu giai thich trang thai (tieng Viet).
(defun bht:status-notes (s / out)
  (setq out nil)
  (if (and (= (cdr (assoc 'objects s)) 0) (> (cdr (assoc 'points s)) 0))
    (setq out (append out (list (strcat "Đã nhập " (bht:stv s 'points) " điểm RTK nhưng CHƯA nhóm thành hồ sơ đối tượng"
                                        " (dữ liệu không mất) - làm bước 6 \"Tạo hồ sơ đối tượng\".")))))
  (if (and (> (cdr (assoc 'points s)) 0) (< (cdr (assoc 'labeled s)) (cdr (assoc 'points s))))
    (setq out (append out (list (strcat (itoa (- (cdr (assoc 'points s)) (cdr (assoc 'labeled s))))
                                        " điểm chưa có nhãn - bước 2 \"Nhãn điểm RTK\" (BHTNHANDIEM).")))))
  (if (> (cdr (assoc 'jpg-missing s)) 0)
    (setq out (append out (list (strcat (bht:stv s 'jpg-missing) " ảnh không tìm thấy file JPG - \"Thư mục ảnh\" (BHTTHUMUCANH).")))))
  (if (> (cdr (assoc 'markers-missing s)) 0)
    (setq out (append out (list (strcat (bht:stv s 'markers-missing) " ảnh GPS chưa có ký hiệu - \"Đồng bộ ký hiệu ảnh\" (BHTDONGBOANH).")))))
  out
)

(defun bht:status-lines (/ s notes)
  (setq s (bht:status-data) notes (bht:status-notes s))
  (list
    (strcat "Điểm RTK đã nhập: " (bht:stv s 'points) "   |   Điểm đã có nhãn: " (bht:stv s 'labeled)
            "   |   Hồ sơ đối tượng: " (bht:stv s 'objects))
    (strcat "Ảnh đã nhập: " (bht:stv s 'total) "   |   Có file JPG: " (bht:stv s 'jpg-found)
            "   |   Đã ghép: " (bht:stv s 'linked) "   |   Chưa ghép: " (bht:stv s 'unlinked))
    (strcat "Tuyến đã khai báo: " (bht:stv s 'routes) "   |   Đối tượng có lý trình: " (bht:stv s 'chainage)
            "   |   Đoạn gói thầu: " (bht:stv s 'segments))
    (if notes (car notes) "Không có cảnh báo trạng thái."))
)

(defun c:BHTTRANGTHAI (/ *error* s)
  (setq *error* bht:on-error)
  (setq s (bht:status-data))
  (bht:msg (strcat "BHT " *bht-version* " - trạng thái bản vẽ:"))
  (foreach l (list
               (strcat "  Điểm RTK đã nhập: " (bht:stv s 'points))
               (strcat "  Điểm đã có nhãn: " (bht:stv s 'labeled))
               (strcat "  Hồ sơ đối tượng: " (bht:stv s 'objects))
               (strcat "  Ảnh đã nhập: " (bht:stv s 'total) " (GPS hợp lệ " (bht:stv s 'valid) ", thiếu GPS " (bht:stv s 'invalid) ")")
               (strcat "  Ảnh có file JPG: " (bht:stv s 'jpg-found) " (thiếu " (bht:stv s 'jpg-missing) ")")
               (strcat "  Ký hiệu ảnh: " (bht:stv s 'markers) " (thiếu " (bht:stv s 'markers-missing) ")")
               (strcat "  Ảnh đã ghép: " (bht:stv s 'linked) " | chưa ghép: " (bht:stv s 'unlinked))
               (strcat "  Tuyến đã khai báo: " (bht:stv s 'routes))
               (strcat "  Đối tượng có lý trình: " (bht:stv s 'chainage)))
    (princ (strcat "\n" l)))
  (foreach l (bht:status-notes s) (princ (strcat "\n  Lưu ý: " l)))
  (princ)
)

