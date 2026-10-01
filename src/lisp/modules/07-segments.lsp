;;; ----------------------------------------------------------------------
;;; Goi thau / doan tuyen - dictionary "SEG" (nap tu BHT_GOI_THAU.tsv,
;;; bang nay sinh tu "Phan chia goi thau.xlsx" cua nguoi dung)
;;; ----------------------------------------------------------------------

(defun bht:seg-load (path replace / lines hdr f id rec n recs)
  (setq lines (bht:read-lines path) n 0)
  (setq hdr (mapcar 'strcase (mapcar 'bht:trim (bht:split (car lines) "\t"))))
  (if (not (and (member "SEGMENT_ID" hdr) (member "KM_START_M" hdr) (member "KM_END_M" hdr)))
    (progn (bht:err "BHT: file không đúng định dạng BHT_GOI_THAU.tsv.") nil)
    (progn
      ;; 0.3.2: doc het file truoc; chi khi co doan hop le moi ghi, roi moi xoa doan cu
      (setq recs nil)
      (foreach line (cdr lines)
        (if (/= (bht:trim line) "")
          (progn
            (setq f (bht:split line "\t") id (strcase (bht:trim (bht:col hdr f "SEGMENT_ID"))))
            (if (and (bht:valid-id id) (bht:num (bht:col hdr f "KM_START_M")) (bht:num (bht:col hdr f "KM_END_M")))
              (progn
                (setq rec nil)
                (foreach h hdr (setq rec (append rec (list (cons (strcase h T) (bht:col hdr f h))))))
                (setq recs (cons (cons id rec) recs)))))))
      (if (null recs)
        (progn (bht:err "BHT: file không có đoạn hợp lệ - giữ nguyên bảng gói thầu cũ.") nil)
        (progn
          (foreach r (reverse recs) (if (bht:rec-write "SEG" (car r) (cdr r)) (setq n (1+ n))))
          (if replace
            (foreach k (bht:rec-keys "SEG")
              (if (not (assoc (strcase k) recs)) (bht:rec-delete "SEG" k))))
          (bht:meta-set "goi_thau_nguon" path)
          (bht:log (strcat "Nạp bảng gói thầu/đoạn " path ": " (itoa n) " đoạn"))
          n))))
)

(defun bht:seg-all ()
  (vl-sort (bht:rec-all "SEG")
           '(lambda (a b) (< (bht:num (bht:get (cdr a) "km_start_m")) (bht:num (bht:get (cdr b) "km_start_m")))))
)

;; Ung vien doan theo ly trinh + phia. side: TRAI/PHAI/nil
(defun bht:seg-candidates (station side segs / out s0 s1 ss)
  (setq out nil)
  (foreach s segs
    (setq s0 (bht:num (bht:get (cdr s) "km_start_m")) s1 (bht:num (bht:get (cdr s) "km_end_m"))
          ss (bht:get (cdr s) "side"))
    (if (and station (>= station (- s0 1e-6)) (<= station (+ s1 1e-6))
             (or (null side) (= ss "HAI_BEN") (= ss side)))
      (setq out (cons (car s) out))))
  (acad_strlsort out)
)

;; Phan doan tu dong. Giu nguyen doi tuong gan THU_CONG.
(defun bht:assign-segments (/ segs rec st sta side cands pp auto amb out und manual seg)
  (setq segs (bht:seg-all) auto 0 amb 0 out 0 und 0 manual 0)
  (foreach oid (bht:obj-ids)
    (setq rec (bht:obj-read oid))
    (if (= (bht:get rec "gan_doan_pp") "THU_CONG")
      (setq manual (1+ manual))
      (progn
        (setq st (bht:get rec "trang_thai_km") sta (bht:num (bht:get rec "ly_trinh_m")))
        ;; phia: uu tien khai bao tay; neu tuyen la tim duong thi dung phia so voi tuyen
        (setq side (cond ((member (bht:get rec "phia_duong") '("TRAI" "PHAI")) (bht:get rec "phia_duong"))
                         ((and (= (bht:get rec "loai_tuyen") "TIM_DUONG") (member (bht:get rec "phia_tuyen") '("TRAI" "PHAI")))
                          (bht:get rec "phia_tuyen"))
                         (T nil)))
        (cond
          ((or (not (bht:station-determined st)) (null sta))
           (setq rec (bht:set rec "gan_doan_pp" "CHUA_XAC_DINH_KM") rec (bht:set rec "doan" "")
                 rec (bht:set rec "goi" "") rec (bht:set rec "doan_ung_vien" "") und (1+ und)))
          (T
           (setq cands (bht:seg-candidates sta side segs))
           (cond
             ((null cands)
              (setq rec (bht:set rec "gan_doan_pp" "NGOAI_PHAM_VI") rec (bht:set rec "doan" "")
                    rec (bht:set rec "goi" "") rec (bht:set rec "doan_ung_vien" "") out (1+ out)))
             ((= (length cands) 1)
              (setq seg (bht:rec-read "SEG" (car cands)))
              (setq rec (bht:set rec "gan_doan_pp" (if (= st "NOI_SUY") "TU_DONG" "TU_DONG_CAN_XAC_NHAN"))
                    rec (bht:set rec "doan" (car cands)) rec (bht:set rec "goi" (bht:get seg "package_id"))
                    rec (bht:set rec "doan_ung_vien" (car cands)) auto (1+ auto)))
             (T
              (setq rec (bht:set rec "gan_doan_pp" "NHIEU_DOAN") rec (bht:set rec "doan" "")
                    rec (bht:set rec "goi" "") rec (bht:set rec "doan_ung_vien" (bht:join cands ";"))
                    amb (1+ amb))))))
        (bht:obj-write oid rec))))
  (list (cons 'auto auto) (cons 'ambiguous amb) (cons 'outside out) (cons 'undetermined und) (cons 'manual manual))
)

(defun bht:assign-manual (oid segid / rec seg)
  (setq rec (bht:obj-read oid) seg (bht:rec-read "SEG" segid))
  (cond
    ((null rec) (list nil "không có đối tượng"))
    ((null seg) (list nil "không có đoạn (nạp BHTGOITHAU trước)"))
    (T (bht:obj-write oid (bht:set (bht:set (bht:set rec "doan" (strcase segid)) "goi" (bht:get seg "package_id"))
                                   "gan_doan_pp" "THU_CONG"))
       (bht:log (strcat "Gán tay " oid " -> " segid))
       (list T segid)))
)

(defun c:BHTGOITHAU (/ *error* path def n)
  (setq *error* bht:on-error)
  (setq def (findfile "BHT_GOI_THAU.tsv"))
  (if (setq path (getfiled "Chọn BHT_GOI_THAU.tsv (tạo từ Phan chia goi thau.xlsx)" (if def def (bht:dwg-folder)) "tsv;txt" 0))
    (if (setq n (bht:seg-load path T))
      (progn
        (bht:msg (strcat "BHT: đã nạp " (itoa n) " đoạn tuyến."))
        (foreach s (bht:seg-all)
          (princ (strcat "\n  " (car s) "  " (bht:get (cdr s) "package_id") "  " (bht:get (cdr s) "km_start_text")
                         " - " (bht:get (cdr s) "km_end_text") "  " (bht:get (cdr s) "side")))))))
  (bht:log-flush)
  (princ)
)

(defun c:BHTPHANDOAN (/ *error* r)
  (setq *error* bht:on-error)
  (if (null (bht:rec-keys "SEG"))
    (bht:warn "BHT: chưa nạp bảng gói thầu. Chạy BHTGOITHAU trước.")
    (progn
      (bht:station-objects)
      (setq r (bht:assign-segments))
      (bht:msg (strcat "BHT phân đoạn: tự động " (itoa (cdr (assoc 'auto r)))
                       ", nhiều đoạn (cần BHTGANDOAN) " (itoa (cdr (assoc 'ambiguous r)))
                       ", ngoài phạm vi " (itoa (cdr (assoc 'outside r)))
                       ", chưa xác định Km " (itoa (cdr (assoc 'undetermined r)))
                       ", gán tay giữ nguyên " (itoa (cdr (assoc 'manual r))) "."))))
  (bht:log-flush)
  (princ)
)

(defun c:BHTGANDOAN (/ *error* oid v res)
  (setq *error* bht:on-error)
  (if (setq oid (bht:pick-object "Chọn đối tượng cần gán đoạn"))
    (progn
      (bht:msg (strcat oid ": lý trình " (bht:get (bht:obj-read oid) "ly_trinh_km") " | ứng viên: "
                       (bht:get (bht:obj-read oid) "doan_ung_vien")))
      (setq v (strcase (bht:ask-string "Mã đoạn (vd DOAN02) hoặc X = bỏ gán tay" "")))
      (cond
        ((= v "X")
         (bht:obj-write oid (bht:set (bht:obj-read oid) "gan_doan_pp" "CHUA_PHAN_DOAN"))
         (bht:msg "BHT: đã bỏ gán tay; chạy BHTPHANDOAN để phân lại."))
        ((/= v "")
         (setq res (bht:assign-manual oid v))
         (if (car res) (bht:msg (strcat "BHT: " oid " -> " v)) (bht:err (strcat "BHT: " (cadr res))))))))
  (bht:log-flush)
  (princ)
)

