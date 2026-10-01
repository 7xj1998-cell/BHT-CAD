;;; ----------------------------------------------------------------------
;;; Xuat CSV (UTF-8 co BOM, dau phay) cho Excel
;;; ----------------------------------------------------------------------

(defun bht:write-csv (path header rows / f)
  (if (setq f (bht:open-write-bom path))
    (progn
      (write-line (bht:csv-line header) f)
      (foreach r rows (write-line (bht:csv-line r) f))
      (close f)
      (length rows))
    (progn (bht:err (strcat "BHT: không ghi được " path " (file đang mở trong Excel?)")) nil))
)

(defun bht:num-or-zero (s / v) (setq v (bht:int s)) (if v v 0))

;; Xuat tat ca. Tra ve assoc so dong moi file.
(defun bht:export-all (folder prefix / index owners rows r st p segs seg objs rec photos groups key it
                       cnt sums nobj res pkey)
  (setq folder (bht:slash folder) index (bht:pt-all) owners (bht:pt-owner-map)
        segs (bht:seg-all) res nil)
  (bht:station-objects)
  ;; 1. Diem RTK
  (setq rows nil)
  (foreach it (vl-sort index '(lambda (a b) (< (car a) (car b))))
    (setq p (cdr it) r (bht:station (bht:pv p 'xyz)) st (cdr (assoc 'status r)))
    (setq rows (cons (list (bht:pv p 'id) (bht:pv p 'ds) (bht:pv p 'row) (bht:pv p 'name)
                           (bht:pv p 'n) (bht:pv p 'e) (bht:pv p 'z) (bht:pv p 'desc) (bht:pv p 'cls)
                           (bht:join (cdr (assoc (car it) owners)) ";")
                           (bht:str (cdr (assoc 'route r)))
                           (if (bht:station-determined st) (bht:fnum (cdr (assoc 'station r)) 3) "")
                           (if (bht:station-determined st) (bht:fmt-km (cdr (assoc 'station r))) "")
                           (if (cdr (assoc 'offset r)) (bht:fnum (cdr (assoc 'offset r)) 3) "")
                           (bht:str (cdr (assoc 'side r))) st
                           (if (bht:station-determined st) (bht:join (bht:seg-candidates (cdr (assoc 'station r)) nil segs) ";") "")
                           (bht:pv p 'src))
                     rows)))
  (setq res (cons (cons 'points (bht:write-csv (strcat folder prefix "DIEM_RTK.csv")
    '("ID điểm khảo sát" "Mã bộ dữ liệu" "Dòng nguồn" "Tên điểm" "Tọa độ Bắc gốc" "Tọa độ Đông gốc" "Cao độ gốc" "Mô tả gốc"
      "Phân loại gợi ý" "ID hồ sơ" "ID tuyến" "Lý trình (m)" "Lý trình Km" "Độ lệch (m)" "Phía so với tuyến"
      "Trạng thái lý trình" "Đoạn ứng viên theo Km" "Tệp nguồn")
    (reverse rows))) res))
  ;; 2. Doi tuong
  (setq rows nil objs nil)
  (foreach oid (bht:obj-ids)
    (setq rec (bht:obj-read oid) objs (cons (cons oid rec) objs)
          seg (bht:rec-read "SEG" (bht:get rec "doan")))
    (setq rows (cons (list oid (bht:get rec "nhom") (bht:group-label (bht:get rec "nhom"))
                           (bht:get rec "ma_hieu") (bht:get rec "loai_ma") (bht:get rec "mo_ta")
                           (bht:get rec "so_tru") (bht:get rec "so_mat") (bht:join (bht:get-all rec "mat") ";")
                           (bht:get rec "tinh_trang") (bht:get rec "trang_thai_kt") (bht:get rec "phia_duong")
                           (itoa (length (bht:get-all rec "pt"))) (bht:join (bht:get-all rec "pt") ";")
                           (bht:get rec "vi_tri_e") (bht:get rec "vi_tri_n")
                           (bht:get rec "route_id") (bht:get rec "ly_trinh_m") (bht:get rec "ly_trinh_km")
                           (bht:get rec "offset_m") (bht:get rec "phia_tuyen") (bht:get rec "trang_thai_km")
                           (bht:get rec "nguon_km")
                           (bht:get rec "goi") (if seg (bht:get seg "package_name") "")
                           (bht:get rec "doan") (bht:get rec "gan_doan_pp") (bht:get rec "doan_ung_vien")
                           (itoa (length (bht:get-all rec "anh")))
                           (bht:join (mapcar '(lambda (a) (car (bht:split a "|"))) (bht:get-all rec "anh")) ";")
                           (bht:join (bht:get-all rec "anh_file") ";")
                           (bht:get rec "ghi_chu") (bht:get rec "tao_luc") (bht:get rec "sua_luc"))
                     rows)))
  (setq res (cons (cons 'objects (bht:write-csv (strcat folder prefix "DOI_TUONG.csv")
    '("ID hồ sơ" "Mã nhóm" "Tên nhóm" "Mã hiệu" "Loại mã" "Mô tả" "Số trụ/chân" "Số mặt biển" "Mã các mặt"
      "Tình trạng" "Trạng thái kiểm tra" "Phía đường" "Số điểm RTK" "ID điểm khảo sát" "Vị trí Đông trung bình" "Vị trí Bắc trung bình"
      "ID tuyến" "Lý trình (m)" "Lý trình Km" "Độ lệch (m)" "Phía so với tuyến" "Trạng thái lý trình" "Nguồn lý trình"
      "ID gói thầu" "Tên gói thầu" "ID đoạn" "Phương pháp gán đoạn" "Đoạn ứng viên"
      "Số ảnh xác nhận" "ID ảnh" "Tệp ảnh khác" "Ghi chú" "Tạo lúc" "Sửa lúc")
    (reverse rows))) res))
  ;; 3. Anh
  (setq rows nil)
  (foreach pid (bht:rec-keys "PHOTO")
    (setq rec (bht:photo-read pid))
    (setq rows (cons (list pid (bht:get rec "ten") (bht:get rec "thoi_gian") (bht:get rec "lon") (bht:get rec "lat")
                           (bht:get rec "gps_hop_le") (bht:get rec "e") (bht:get rec "n") (bht:get rec "crs")
                           (bht:get rec "trang_thai") (bht:join (bht:get-all rec "de_xuat") ";") (bht:get rec "kc")
                           (bht:join (bht:get-all rec "doi_tuong") ";") (bht:get rec "duong_dan")
                           (bht:get rec "antifake") (bht:get rec "dia_chi"))
                     rows)))
  (setq res (cons (cons 'photos (bht:write-csv (strcat folder prefix "ANH.csv")
    '("ID ảnh" "Tên điểm ảnh" "Thời gian chụp" "Kinh độ" "Vĩ độ" "GPS hợp lệ" "Tọa độ Đông vị trí chụp" "Tọa độ Bắc vị trí chụp"
      "Hệ tọa độ tính" "Trạng thái ghép" "Đề xuất" "Khoảng cách gần nhất (m)" "ID hồ sơ xác nhận" "Đường dẫn" "Chống giả mạo" "Địa chỉ")
    (reverse rows))) res))
  ;; 4. Tong hop theo goi / doan / nhom - moi doi tuong dem DUNG MOT lan
  (setq groups nil)
  (foreach o objs
    (setq rec (cdr o)
          key (list (if (/= (bht:get rec "goi") "") (bht:get rec "goi") "(CHUA_GAN)")
                    (if (/= (bht:get rec "doan") "") (bht:get rec "doan") (bht:get rec "gan_doan_pp"))
                    (bht:get rec "nhom")))
    (setq it (assoc key groups)
          cnt (if it (cdr it) (list 0 0 0 0 0 0 0 0)))
    ;; cnt: so_dt so_tru so_mat dt_thieu_tru dt_thieu_mat so_diem so_anh can_xac_nhan
    (setq cnt (list (1+ (nth 0 cnt))
                    (+ (nth 1 cnt) (bht:num-or-zero (bht:get rec "so_tru")))
                    (+ (nth 2 cnt) (bht:num-or-zero (bht:get rec "so_mat")))
                    (+ (nth 3 cnt) (if (bht:int (bht:get rec "so_tru")) 0 1))
                    (+ (nth 4 cnt) (if (bht:int (bht:get rec "so_mat")) 0 1))
                    (+ (nth 5 cnt) (length (bht:get-all rec "pt")))
                    (+ (nth 6 cnt) (length (bht:get-all rec "anh")))
                    (+ (nth 7 cnt) (if (or (/= (bht:get rec "gan_doan_pp") "TU_DONG")
                                           (/= (bht:get rec "trang_thai_kt") "DA_KIEM_TRA")) 1 0))))
    (if it (setq groups (subst (cons key cnt) it groups)) (setq groups (cons (cons key cnt) groups))))
  (setq groups (vl-sort groups '(lambda (a b) (< (bht:join (car a) "|") (bht:join (car b) "|")))))
  (setq rows nil sums (list 0 0 0 0 0 0 0 0))
  (foreach g groups
    (setq seg (bht:rec-read "SEG" (cadr (car g))))
    (setq rows (cons (append (list (car (car g)) (if seg (bht:get seg "package_name") "")
                                   (cadr (car g))
                                   (if seg (strcat (bht:get seg "km_start_text") " - " (bht:get seg "km_end_text")) "")
                                   (if seg (bht:get seg "side") "")
                                   (caddr (car g)) (bht:group-label (caddr (car g))))
                             (mapcar 'itoa (cdr g)))
                     rows)
          sums (mapcar '+ sums (cdr g))))
  (setq rows (cons (append (list "TONG" "" "" "" "" "" "Tất cả đối tượng") (mapcar 'itoa sums)) rows))
  (setq res (cons (cons 'summary (bht:write-csv (strcat folder prefix "TONG_HOP.csv")
    '("ID gói thầu" "Tên gói thầu" "ID đoạn hoặc trạng thái" "Phạm vi Km" "Phía" "Mã nhóm" "Tên nhóm"
      "Số đối tượng" "Số trụ/chân" "Số mặt biển" "Số đối tượng chưa rõ số trụ" "Số đối tượng chưa rõ số mặt"
      "Số điểm RTK" "Số ảnh xác nhận" "Số đối tượng chưa chốt")
    (reverse rows))) res))
  (setq res (cons (cons 'total-objects (car sums)) res))
  (bht:log (strcat "Xuất CSV vào " folder))
  res
)

(defun c:BHTXUAT (/ *error* path folder pre res)
  (setq *error* bht:on-error)
  (if (setq path (getfiled "Chọn thư mục + tiền tố file xuất (vd BHT_.csv)" (strcat (bht:dwg-folder) "BHT_.csv") "csv" 1))
    (progn
      (setq folder (vl-filename-directory path)
            pre (vl-filename-base path))
      (setq res (bht:export-all folder pre))
      (bht:msg (strcat "BHT xuất: " (bht:str (cdr (assoc 'points res))) " điểm RTK, "
                       (bht:str (cdr (assoc 'objects res))) " đối tượng, "
                       (bht:str (cdr (assoc 'photos res))) " ảnh, tổng hợp "
                       (bht:str (cdr (assoc 'summary res))) " dòng -> " (bht:slash folder) pre "*.csv"))))
  (bht:log-flush)
  (princ)
)
(defun c:BHTEXPORT () (c:BHTXUAT))
(defun c:BHTSUMMARY () (c:BHTXUAT))

