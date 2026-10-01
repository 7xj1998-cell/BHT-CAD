;;; ----------------------------------------------------------------------
;;; Diem RTK: POINT layer BHT_RTK
;;;  XData "BHT_RTK" (tuong thich v0.1): ten diem, mo ta (<=80 ky tu dau)
;;;  XData "BHT_PT" (v0.2): id, dataset, dong, ten, N goc, E goc, Z goc,
;;;        phan loai goi y, file nguon, thoi diem nhap, <cac doan mo ta goc>
;;; ----------------------------------------------------------------------

(setq *bht-pt-layer* "BHT_RTK")

(defun bht:pt-from-ent (ent / x loc)
  (setq x (bht:xget ent "BHT_PT"))
  (if (and x (>= (length x) 10))
    (progn
      (setq loc (cdr (assoc 10 (entget ent))))
      (list (cons 'id (nth 0 x)) (cons 'ds (nth 1 x)) (cons 'row (nth 2 x))
            (cons 'name (nth 3 x)) (cons 'n (nth 4 x)) (cons 'e (nth 5 x))
            (cons 'z (nth 6 x)) (cons 'cls (nth 7 x)) (cons 'src (nth 8 x))
            (cons 'time (nth 9 x))
            (cons 'desc (apply 'strcat (cons "" (bht:nthcdr 10 x))))
            (cons 'ent ent) (cons 'xyz loc)))
    nil)
)

(defun bht:pv (p key) (cdr (assoc key p)))

;; Danh sach tat ca diem v0.2 trong DWG: ((id . p) ...)
(defun bht:pt-all (/ ss i p out)
  (setq out nil i 0
        ss (ssget "_X" (list '(0 . "POINT") '(-3 ("BHT_PT")))))
  (if ss
    (while (< i (sslength ss))
      (if (setq p (bht:pt-from-ent (ssname ss i)))
        (setq out (cons (cons (strcase (bht:pv p 'id)) p) out)))
      (setq i (1+ i))))
  (reverse out)
)

(defun bht:pt-find (id index)
  (cdr (assoc (strcase id) index))
)

;; Khoa noi dung (chuoi goc) de phat hien nhap trung duoi ID khac.
(defun bht:content-key (name n e z desc)
  (strcat name "|" (bht:trim n) "|" (bht:trim e) "|" (bht:trim z) "|" desc)
)

;; Khoa tuong thich v0.1 (ten + toa do 3 so le).
(defun bht:legacy-key (name east north z)
  (strcat name "|" (bht:fnum east 3) "|" (bht:fnum north 3) "|" (bht:fnum z 3))
)

(defun bht:pt-write-xdata (ent id ds row name n e z cls src desc tm)
  (and (bht:xset ent "BHT_RTK" (list name (if (> (strlen desc) 80) (substr desc 1 80) desc)))
       (bht:xset ent "BHT_PT" (append (list id ds (bht:str row) name n e z cls src tm)
                                      (bht:chunks desc 80))))
)

(defun bht:make-id (ds kind n)
  (strcat ds "-" kind "-" (bht:pad0 n 6))
)

;; Doc CSV 5 cot -> danh sach ban ghi (id ds row name n e z desc src) va loi.
;; Tra ve (records invalid-rows) ; invalid-rows = ((row . ly do) ...)
(defun bht:csv-records (path ds / lines row f name n e z desc recs bad src)
  (setq lines (bht:read-lines path) row 0 recs nil bad nil
        src (strcat (vl-filename-base path) (vl-filename-extension path)))
  (foreach line lines
    (setq row (1+ row))
    (if (/= (bht:trim line) "")
      (progn
        (setq f (bht:csv-fields line)
              name (bht:trim (nth 0 f))
              n (if (nth 1 f) (nth 1 f) "")
              e (if (nth 2 f) (nth 2 f) "")
              z (if (nth 3 f) (nth 3 f) "")
              desc (cond ((> (length f) 5)
                          (bht:join (cdr (cdr (cdr (cdr f)))) ","))
                         ((nth 4 f) (nth 4 f))
                         (T "")))
        (cond
          ((< (length f) 4) (setq bad (cons (cons row "thiếu cột") bad)))
          ((= name "") (setq bad (cons (cons row "tên điểm rỗng") bad)))
          ((> (strlen name) 80) (setq bad (cons (cons row "tên điểm quá dài") bad)))
          ((not (and (bht:num n) (bht:num e) (bht:num z)))
           (setq bad (cons (cons row "N/E/Z không phải số") bad)))
          (T (setq recs (cons (list (bht:make-id ds "R" row) ds row name
                                    (bht:trim n) (bht:trim e) (bht:trim z) desc src)
                              recs)))))))
  (list (reverse recs) (reverse bad))
)

;; Doc BHT_RTK.tsv (dinh dang V0.1): BHT_ID SRC_POINT NORTHING EASTING Z RAW_DESC SRC_ROW SOURCE_FILE
(defun bht:col (hdr f k / i)
  (setq i (vl-position k hdr))
  (if (and i (nth i f)) (nth i f) "")
)

(defun bht:tsv-rtk-records (path / lines hdr f recs bad row id ds)
  (setq lines (bht:read-lines path) recs nil bad nil row 1)
  (setq hdr (mapcar 'strcase (mapcar 'bht:trim (bht:split (car lines) "\t"))))
  (foreach line (cdr lines)
    (setq row (1+ row))
    (if (/= (bht:trim line) "")
      (progn
        (setq f (bht:split line "\t") id (strcase (bht:trim (bht:col hdr f "BHT_ID")))
              ds (if (vl-string-search "-R-" id) (substr id 1 (vl-string-search "-R-" id)) "TSV"))
        (if (and (bht:valid-id id) (/= (bht:col hdr f "SRC_POINT") "")
                 (bht:num (bht:col hdr f "NORTHING")) (bht:num (bht:col hdr f "EASTING")) (bht:num (bht:col hdr f "Z")))
          (setq recs (cons (list id ds (if (/= (bht:col hdr f "SRC_ROW") "") (bht:col hdr f "SRC_ROW") (itoa row))
                                 (bht:trim (bht:col hdr f "SRC_POINT")) (bht:trim (bht:col hdr f "NORTHING"))
                                 (bht:trim (bht:col hdr f "EASTING")) (bht:trim (bht:col hdr f "Z"))
                                 (bht:col hdr f "RAW_DESC")
                                 (if (/= (bht:col hdr f "SOURCE_FILE") "") (bht:col hdr f "SOURCE_FILE")
                                   (strcat (vl-filename-base path) ".tsv")))
                           recs))
          (setq bad (cons (cons row "dòng TSV không hợp lệ") bad))))))
  (list (reverse recs) (reverse bad))
)

;; Nhap danh sach ban ghi vao DWG, chong trung.
;; Tra ve assoc: added same conflict dupcontent adopted invalid dupfile
(defun bht:import-records (recs bad / index fresh cmap lmap ss i ent x loc p id ds row name n e z desc src
                                  key added same conflict dupc adopted dupfile seen tm cls old dsrec)
  (setq added 0 same 0 conflict 0 dupc 0 adopted 0 dupfile 0 seen nil tm (bht:now))
  (bht:layer *bht-pt-layer* 3)
  (bht:point-style-apply nil nil)
  (bht:regapp "BHT_RTK") (bht:regapp "BHT_PT")
  ;; Chi muc hien co
  (setq index (bht:pt-all) fresh (null index) cmap nil lmap nil)
  ;; DPSurvey tach kieu diem khoi du lieu. BHT cung chi dat kieu RTK gon cho
  ;; BAN VE MOI: VNRomancUpdate.shx / Unicode cho nhan CAD.
  (if (and fresh (= (bht:get (bht:rec-read "META" "CONFIG") "nhan_kieu_chu") ""))
    (bht:meta-set "nhan_kieu_chu" "BHT_TCVN"))
  (foreach it index
    (setq p (cdr it))
    (setq cmap (cons (cons (bht:content-key (bht:pv p 'name) (bht:pv p 'n) (bht:pv p 'e)
                                            (bht:pv p 'z) (bht:pv p 'desc))
                           (bht:pv p 'id)) cmap)))
  ;; Diem v0.1 chua co BHT_PT
  (setq ss (ssget "_X" (list '(0 . "POINT") (cons 8 *bht-pt-layer*) '(-3 ("BHT_RTK")))) i 0)
  (if ss
    (while (< i (sslength ss))
      (setq ent (ssname ss i))
      (if (not (bht:xget ent "BHT_PT"))
        (progn
          (setq x (bht:xget ent "BHT_RTK") loc (cdr (assoc 10 (entget ent))))
          (setq lmap (cons (cons (bht:legacy-key (car x) (car loc) (cadr loc) (caddr loc)) ent) lmap))))
      (setq i (1+ i))))
  (foreach r recs
    (setq id (nth 0 r) ds (nth 1 r) row (nth 2 r) name (nth 3 r) n (nth 4 r) e (nth 5 r)
          z (nth 6 r) desc (nth 7 r) src (nth 8 r)
          key (bht:content-key name n e z desc)
          cls (bht:classify desc))
    (if (member key seen)
      (progn (setq dupfile (1+ dupfile))
             (bht:log (strcat "CẢNH BÁO trùng nội dung trong cùng file: " id " (" name ")"))))
    (setq seen (cons key seen))
    (cond
      ((setq p (bht:pt-find id index))
       (if (= (bht:content-key (bht:pv p 'name) (bht:pv p 'n) (bht:pv p 'e) (bht:pv p 'z) (bht:pv p 'desc)) key)
         (setq same (1+ same))
         (progn (setq conflict (1+ conflict))
                (bht:log (strcat "XUNG ĐỘT ID " id ": dữ liệu mới khác dữ liệu đã nhập; KHÔNG ghi đè. Mới: "
                                 name "," n "," e "," z "," desc)))))
      ((setq old (cdr (assoc key cmap)))
       (setq dupc (1+ dupc))
       (bht:log (strcat "TRÙNG NỘI DUNG: " id " giống điểm đã có " old "; bỏ qua.")))
      ((setq ent (cdr (assoc (bht:legacy-key name (bht:num e) (bht:num n) (bht:num z)) lmap)))
       (if (bht:pt-write-xdata ent id ds row name n e z cls src desc tm)
         (progn (setq adopted (1+ adopted)
                      lmap (vl-remove (assoc (bht:legacy-key name (bht:num e) (bht:num n) (bht:num z)) lmap) lmap)
                      index (cons (cons (strcase id) (bht:pt-from-ent ent)) index)
                      cmap (cons (cons key id) cmap)))))
      (T
       (setq ent (entmakex (list '(0 . "POINT") '(410 . "Model") (cons 8 *bht-pt-layer*)
                                 (list 10 (bht:num e) (bht:num n) (bht:num z)))))
       (if (and ent (bht:pt-write-xdata ent id ds row name n e z cls src desc tm))
         (setq added (1+ added)
               index (cons (cons (strcase id) (list (cons 'id id))) index)
               cmap (cons (cons key id) cmap))
         (bht:log (strcat "LỖI tạo điểm " id))))))
  (foreach b bad (bht:log (strcat "DÒNG LỖI " (itoa (car b)) ": " (cdr b))))
  (list (cons 'added added) (cons 'same same) (cons 'conflict conflict)
        (cons 'dupcontent dupc) (cons 'adopted adopted) (cons 'invalid (length bad))
        (cons 'dupfile dupfile))
)

(defun bht:import-report (res)
  (bht:msg (strcat "BHT nhập điểm: thêm mới " (itoa (cdr (assoc 'added res)))
                   ", đã có (giống hệt) " (itoa (cdr (assoc 'same res)))
                   ", xung đột ID " (itoa (cdr (assoc 'conflict res)))
                   ", trùng nội dung ID khác " (itoa (cdr (assoc 'dupcontent res)))
                   ", nhận điểm v0.1 " (itoa (cdr (assoc 'adopted res)))
                   ", dòng lỗi " (itoa (cdr (assoc 'invalid res)))
                   ", trùng trong file " (itoa (cdr (assoc 'dupfile res))) "."))
  (if (or (> (cdr (assoc 'conflict res)) 0) (> (cdr (assoc 'invalid res)) 0)
          (> (cdr (assoc 'dupcontent res)) 0))
    (bht:msg "  Xem chi tiết trong thư mục BHT_LOG cạnh bản vẽ."))
)

(defun bht:dataset-register (ds path nrec res)
  (bht:dataset-register-fmt ds path nrec res "")
)

;; 0.3.3: ghi them dinh dang nhap (CSV / TSV) de canh bao nhap trung dinh dang.
(defun bht:dataset-register-fmt (ds path nrec res fmt / rec old)
  (setq rec (bht:rec-read "DATASET" ds))
  (if (null rec)
    (setq rec (list (cons "dataset_id" ds) (cons "tao_luc" (bht:now)))))
  (setq old (bht:get rec "dinh_dang"))
  (setq rec (bht:set rec "file_nguon" (if path path ""))
        rec (bht:set rec "so_dong_hop_le" (itoa nrec))
        rec (bht:set rec "lan_nhap_cuoi" (bht:now))
        rec (bht:set rec "crs" "CHUA_XAC_NHAN (giả định VN-2000, đơn vị mét)")
        rec (bht:set rec "ket_qua" (strcat "them=" (itoa (cdr (assoc 'added res)))
                                           " trung=" (itoa (cdr (assoc 'same res)))
                                           " xungdot=" (itoa (cdr (assoc 'conflict res))))))
  (if (/= fmt "")
    (setq rec (bht:set rec "dinh_dang" (cond ((= old "") fmt)
                                             ((vl-string-search fmt old) old)
                                             (T (strcat old "+" fmt))))))
  (bht:rec-write "DATASET" ds rec)
)

;; 0.3.3: canh bao khi cung du lieu duoc nhap lai bang dinh dang khac (CSV <-> TSV).
;; Tra ve T neu du lieu da co san hoan toan (khong them diem nao).
(defun bht:dual-import-check (dss fmt res / other hit)
  (setq other (if (= fmt "CSV") "TSV" "CSV") hit nil)
  (foreach d dss
    (if (vl-string-search other (bht:get (bht:rec-read "DATASET" d) "dinh_dang"))
      (setq hit (cons d hit))))
  (cond
    ((and res (= (cdr (assoc 'added res)) 0)
          (> (+ (cdr (assoc 'same res)) (cdr (assoc 'dupcontent res)) (cdr (assoc 'adopted res))) 0))
     (bht:msg (strcat "BHT LƯU Ý: dữ liệu trong file " fmt " này ĐÃ CÓ trong bản vẽ"
                      (if hit (strcat " (dataset " (bht:join hit ", ") " đã nhập bằng " other ")") "")
                      " - không thêm điểm nào, không tạo trùng. KHÔNG cần nhập cùng một bộ dữ liệu bằng cả CSV và TSV."))
     T)
    (hit
     (bht:msg (strcat "BHT LƯU Ý: dataset " (bht:join hit ", ") " trước đây nhập bằng " other
                      ". Mặc định dùng CSV trực tiếp; TSV chỉ là định dạng trao đổi/chuẩn hóa - không cần nhập cả hai."))
     nil)
    (T nil))
)

;; Ham chinh nhap CSV (goi duoc tu script kiem thu). CSV la cach nhap MAC DINH.
(defun bht:import-csv (path ds / pack res)
  (setq ds (strcase (bht:trim ds)))
  (if (not (bht:valid-id ds))
    (progn (bht:warn "BHT: mã dataset không hợp lệ (chỉ A-Z 0-9 _ - .).") nil)
    (if (not (bht:file-exists path))
      (progn (bht:err "BHT: không mở được file CSV.") nil)
      (progn
        (setq pack (bht:csv-records path ds)
              res (bht:import-records (car pack) (cadr pack)))
        (bht:dual-import-check (list ds) "CSV" res)
        (bht:dataset-register-fmt ds path (length (car pack)) res "CSV")
        (bht:log (strcat "Nhập CSV " path " dataset " ds))
        (bht:import-report res)
        (bht:log-flush)
        res)))
)

;; TSV = dinh dang trao doi / chuan hoa (BHT_RTK.tsv V0.1), khong bat buoc.
(defun bht:import-tsv (path / pack res dss)
  (if (not (bht:file-exists path))
    (progn (bht:err "BHT: không mở được file TSV.") nil)
    (progn
      (setq pack (bht:tsv-rtk-records path)
            res (bht:import-records (car pack) (cadr pack)))
      (setq dss nil)
      (foreach r (car pack) (setq dss (bht:unique-add dss (nth 1 r))))
      (bht:dual-import-check dss "TSV" res)
      (foreach d dss (bht:dataset-register-fmt d path (length (car pack)) res "TSV"))
      (bht:import-report res)
      (bht:log-flush)
      res))
)

(defun bht:ask-string (msg default / v)
  (setq v (getstring T (strcat "\n" msg (if (and default (/= default "")) (strcat " <" default ">") "") ": ")))
  (if (= (bht:trim v) "") (if default default "") (bht:trim v))
)

;;; --- Lenh nhap lieu: UI wrappers; engine TSV/CSV o section phia tren ---
(defun c:BHTNHAP (/ *error* path ds)
  (setq *error* bht:on-error)
  (if (setq path (getfiled "Chọn CSV khảo sát RTK (tên, Bắc, Đông, Z, mô tả; không tiêu đề)" (bht:dwg-folder) "csv;txt" 0))
    (progn
      (setq ds (strcase (bht:ask-string "Mã dataset (tiền tố ID, vd BOT19)" (bht:meta "dataset_cuoi" "BOT19"))))
      (if (bht:import-csv path ds)
        (progn
          (bht:meta-set "dataset_cuoi" ds)
          (bht:ask-labels-after-import)))))
  (bht:log-flush)
  (princ)
)
(defun c:BHTIMPORT () (c:BHTNHAP))
(defun c:BHTCSV () (c:BHTNHAP))

(defun c:BHTNHAPTSV (/ *error* path)
  (setq *error* bht:on-error)
  (if (setq path (getfiled "Chọn BHT_RTK.tsv (định dạng trao đổi; CSV là cách nhập mặc định)" (bht:dwg-folder) "tsv;txt" 0))
    (if (bht:import-tsv path) (bht:ask-labels-after-import)))
  (bht:log-flush)
  (princ)
)
(defun c:BHTNK () (c:BHTNHAPTSV))

;;; --- Engine nhan RTK: cau hinh, bao toan nhan tay va bo tri ---
;; Sau khi nhap diem: hoi tao/cap nhat nhan (cap nhat tai cho, khong nhan doi).
(defun bht:ask-labels-after-import ()
  (if (= (strcase (bht:ask-string "Tạo/cập nhật nhãn điểm RTK ngay (BHTNHANDIEM)? [C/K]" "C")) "C")
    (bht:lbl-report (bht:lbl-sync))
    (bht:msg "BHT: chưa tạo nhãn. Dùng BHTNHANDIEM khi cần."))
)

