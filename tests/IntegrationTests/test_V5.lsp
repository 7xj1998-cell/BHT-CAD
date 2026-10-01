;;; BHT 0.6.3 - phien V5: tim bien khong dau, Tinh trang, coc tieu / cot Km (khong ma bien,
;;; kiem tra trung), kieu chu nhan BHT_BIENBAO (VNRomancUpdate.shx), BHTSIGNSEARCH (Bridge). Ban ve moi.
(load "C:/Users/Le Bao/BHT_TEST_V044/t_common.lsp")
(vl-load-com)
(tbegin "V5")
(setq e (tload))
(tchk "V5-00" "nạp BHT-5.0; *bht-version* = 5.0; thông báo APPLOAD"
      (and (null e) (= *bht-version* "0.6.3") (= (bht:load-message) "BHT 0.6.3 đã nạp thành công."))
      (if e e (list *bht-version* (bht:load-message))))
;; --- 1. tim bien khong dau
(tchk "V5-01" "bỏ dấu tìm kiếm (cả đ/Đ) + chữ thường"
      (and (= (bht:search-fold "ĐI CHẬM") "di cham") (= (bht:search-fold "Đường đèo") "duong deo")) (bht:search-fold "ĐI CHẬM"))
(tchk "V5-02" "khớp mã + tên: 'di cham' / 'Đi Chậm' / 'w245a' / '245' khớp W.245a; 'toc do' không khớp"
      (and (bht:sign-match-p "di cham" "W.245a" "Đi chậm") (bht:sign-match-p "Đi Chậm" "W.245a" "Đi chậm")
           (bht:sign-match-p "w245a" "W.245a" "Đi chậm") (bht:sign-match-p "245" "W.245a" "Đi chậm")
           (not (bht:sign-match-p "toc do" "W.245a" "Đi chậm")) (not (bht:sign-match-p "di nhanh" "W.245a" "Đi chậm")))
      nil)
(setq BHTSIGNSEARCH nil)
(setq h1 (bht:sign-search "di cham" 30) h2 (bht:sign-search "toc do toi da" 30))
(tchk "V5-03" "bht:sign-search (danh mục nội bộ khi chưa có Bridge): 'di cham' -> W.245a; 'toc do toi da' -> P.127"
      (and (assoc "W.245a" h1) (vl-every '(lambda (h) (vl-string-search "di cham" (bht:search-fold (cadr h)))) h1) (assoc "P.127" h2)) (list h1 h2))
;; --- 2. Tinh trang
(tchk "V5-04" "Tình trạng: 1/2/3 -> Tốt/Bình thường/Hư hỏng; 'hu hong' -> Hư hỏng; chữ tự do cũ giữ nguyên"
      (and (= (bht:condition-value "1") "Tốt") (= (bht:condition-value "2") "Bình thường") (= (bht:condition-value "3") "Hư hỏng")
           (= (bht:condition-value "hu hong") "Hư hỏng") (= (bht:condition-value "tốt, nghiêng nhẹ") "tốt, nghiêng nhẹ")
           (= (bht:condition-value "") "") (equal *bht-conditions* '("Tốt" "Bình thường" "Hư hỏng")))
      (mapcar 'bht:condition-value '("1" "2" "3" "hu hong")))
;; --- 3. du lieu diem
(setq r (tsafe "V5-05" "nhập CSV" '(lambda () (bht:import-csv (strcat *T-DIR* "data/survey.csv") "BOT19"))))
(setq idx (bht:pt-all))
(defun t5-xy (pid) (bht:pv (bht:pt-find pid idx) 'xyz))
(setq P20 "BOT19-R-000020" P21 "BOT19-R-000021" P30 "BOT19-R-000030" P40 "BOT19-R-000040")
(setq snap0 (mapcar '(lambda (p) (list (car p) (bht:pv (cdr p) 'xyz) (bht:pv (cdr p) 'ent))) idx))
(tchk "V5-05" "có điểm RTK để thử" (and (t5-xy P20) (t5-xy P21) (t5-xy P30) (t5-xy P40)) (length idx))
(setq d21 (distance (list (car (t5-xy P20)) (cadr (t5-xy P20))) (list (car (t5-xy P21)) (cadr (t5-xy P21)))))
;; --- 4. coc tieu: khong ma bien, trung
(setq ra (bht:obj-create "OBJ-V1" '(("nhom" . "COC_TIEU") ("so_tru" . "1")) (list P20) nil))
(setq hs (bht:obj-dup-find "" "COC_TIEU" (list P20) "" nil)
      hi (bht:obj-dup-find "" "COC_TIEU" (list P20) "" T))
(tchk "V5-06" "cọc tiêu cùng điểm RTK với cọc tiêu khác -> trùng (nêu ID + điểm); đã xác nhận dùng chung -> không hỏi lại"
      (and (car ra) (= (length hs) 1) (= (car (car hs)) "OBJ-V1") (vl-string-search P20 (cadr (car hs))) (null hi)) (list hs hi))
(bht:meta-set "trung_kc_m" (bht:fnum (+ d21 0.01) 3))
(setq hn (bht:obj-dup-find "" "COC_TIEU" (list P21) "" nil))
(bht:meta-set "trung_kc_m" (bht:fnum (max 0.001 (/ d21 2.0)) 3))
(setq hf (bht:obj-dup-find "" "COC_TIEU" (list P21) "" nil))
(tchk "V5-07" "cọc tiêu cách <= ngưỡng (meta trung_kc_m cấu hình được) -> trùng; > ngưỡng -> không; nhóm khác không so"
      (and (<= d21 100.0) (assoc "OBJ-V1" hn) (not (assoc "OBJ-V1" hf)) (null (bht:obj-dup-find "" "BIEN_BAO" (list P20) "" nil)))
      (list d21 hn hf))
(bht:meta-set "trung_kc_m" "abc")
(tchk "V5-08" "ngưỡng không hợp lệ -> mặc định 0.5 m" (= (bht:dup-tolerance) 0.5) (bht:dup-tolerance))
(bht:meta-set "trung_kc_m" "0.5")
;; cot Km trung gia tri Km
(setq rk (bht:obj-create "OBJ-V2" '(("nhom" . "COT_KM")) (list P30) nil))
(bht:obj-write "OBJ-V2" (bht:set-all (bht:obj-read "OBJ-V2") "ly_trinh_km" '("Km12+345.00")))
(setq hk (bht:obj-dup-find "" "COT_KM" (list P40) "12+345" nil) hk2 (bht:obj-dup-find "" "COT_KM" (list P40) "12+346" nil))
(tchk "V5-09" "cột Km trùng giá trị Km -> trùng; Km khác -> không"
      (and (car rk) (assoc "OBJ-V2" hk) (vl-string-search "trùng Km" (cadr (assoc "OBJ-V2" hk))) (not (assoc "OBJ-V2" hk2))) (list hk hk2))
;; lenh tao ho so (thay ham hoi, KHONG thay logic): coc tieu trung -> mac dinh huy
(setq SV-ASK bht:ask-string SV-GRP bht:ask-group SV-CNT bht:ask-count SV-SIDE bht:ask-side)
(setq *ANS* nil *ASKED* nil)
(defun bht:ask-string (m d / hit)
  (setq *ASKED* (cons m *ASKED*))
  (setq hit (vl-some '(lambda (pr) (if (vl-string-search (car pr) m) pr)) *ANS*))
  (if hit (progn (setq *ANS* (vl-remove hit *ANS*)) (cdr hit)) (if d d "")))
(defun bht:ask-group (s) "COC_TIEU")
(defun bht:ask-count (m d) (if d d ""))
(defun bht:ask-side (d) (if d d ""))
(bht:meta-set "trung_kc_m" (bht:fnum (+ d21 0.01) 3))
(setq *ANS* '(("ID đối tượng" . "OBJ-V3") ("Chèn ký hiệu" . "K")))
(setq r1 (bht:obj-create-interactive (list P21) nil))
(setq asked1 *ASKED*)
(setq *ANS* '(("ID đối tượng" . "OBJ-V4") ("Vẫn tạo" . "C") ("Chèn ký hiệu" . "K")) *ASKED* nil)
(setq r2 (bht:obj-create-interactive (list P21) nil))
(tchk "V5-10" "tạo cọc tiêu trùng: hỏi 'Vẫn tạo...' mặc định K = HỦY; C = vẫn tạo"
      (and (null (car r1)) (not (bht:obj-read "OBJ-V3")) (vl-some '(lambda (m) (vl-string-search "Vẫn tạo" m)) asked1)
           (car r2) (bht:obj-read "OBJ-V4"))
      (list r1 r2))
(tchk "V5-11" "cọc tiêu: Mã hiệu hỏi 'không có mã biển', mặc định trống; hồ sơ lưu ma_hieu rỗng"
      (and (vl-some '(lambda (m) (vl-string-search "không có mã biển" m)) asked1) (= (bht:get (bht:obj-read "OBJ-V4") "ma_hieu") ""))
      (bht:get (bht:obj-read "OBJ-V4") "ma_hieu"))
(setq bht:ask-string SV-ASK bht:ask-group SV-GRP bht:ask-count SV-CNT bht:ask-side SV-SIDE)
(bht:meta-set "trung_kc_m" "0.5")
(setq snap1 (mapcar '(lambda (p) (list (car p) (bht:pv (cdr p) 'xyz) (bht:pv (cdr p) 'ent))) (bht:pt-all)))
(tchk "V5-12" "kiểm tra trùng không di chuyển / sửa / xóa điểm RTK" (equal snap0 snap1) (list (length snap0) (length snap1)))
;; --- 5. kieu chu nhan bien
(setq ff (bht:sign-font-file))
(setq st (bht:sign-label-style))
(tchk "V5-13" "kiểu chữ BHT_BIENBAO = VNRomancUpdate.shx (tìm thấy phông qua Support Path); không thấy -> BHT_ARIAL"
      (if ff (and (= st "BHT_BIENBAO") (= (strcase (cdr (assoc 3 (tblsearch "STYLE" "BHT_BIENBAO")))) "VNROMANCUPDATE.SHX"))
             (= st "BHT_ARIAL"))
      (list ff st))
(tchk "V5-14" "nhãn ASCII và có dấu đều dùng kiểu phông Unicode đã chọn"
      (and (bht:ascii-p "W.245a  Km1+200.00") (not (bht:ascii-p "Cọc tiêu")) (= (bht:kh-label-style "Cọc tiêu") st)
           (= (bht:kh-label-style "W.245a") st))
      nil)
(setq rb (bht:obj-create "OBJ-V5" '(("nhom" . "BIEN_BAO") ("ma_hieu" . "W.245a")) (list P40) nil))
(setq other (entmakex '((0 . "TEXT") (8 . "KHAO_SAT") (10 1.0 1.0 0.0) (40 . 1.0) (1 . "W.245a") (7 . "Standard"))))
(bht:symbol-sync (list "OBJ-V5" "OBJ-V1"))
(defun t5-lbl (oid / g) (setq g (assoc oid (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_KH" 1)))) (if g (cadr g)))
(setq l5 (t5-lbl "OBJ-V5") l1 (t5-lbl "OBJ-V1"))
(tchk "V5-15" "nhãn biển và cọc tiêu dùng cùng kiểu phông Unicode; giữ chữ có dấu"
      (and (car rb) l5 l1 (= (cdr (assoc 7 (entget l5))) st) (= (cdr (assoc 1 (entget l5))) "W.245a")
           (= (cdr (assoc 7 (entget l1))) st) (= (cdr (assoc 1 (entget l1))) "Cọc tiêu"))
      (list (if l5 (list (cdr (assoc 1 (entget l5))) (cdr (assoc 7 (entget l5))))) (if l1 (list (cdr (assoc 1 (entget l1))) (cdr (assoc 7 (entget l1)))))))
(entmod (subst '(7 . "Standard") (assoc 7 (entget l5)) (entget l5)))
(bht:symbol-sync (list "OBJ-V5"))
(tchk "V5-16" "cập nhật ký hiệu: nhãn BHT cũ (Standard) đổi sang kiểu nhãn biển; TEXT khảo sát không mang XData giữ nguyên"
      (and (= (cdr (assoc 7 (entget (t5-lbl "OBJ-V5")))) st) (= (cdr (assoc 7 (entget other))) "Standard") (= (cdr (assoc 8 (entget other))) "KHAO_SAT"))
      (list (cdr (assoc 7 (entget (t5-lbl "OBJ-V5")))) (cdr (assoc 7 (entget other)))))
;; --- 6. BHTBLOCK -> D -> tim
(setq SV-ASK bht:ask-string *ANS* '(("Chọn nhóm" . "1") ("D=Danh" . "D") ("Tìm biển" . "đi chậm")) *ASKED* nil)
(defun bht:ask-string (m d / hit)
  (setq *ASKED* (cons m *ASKED*))
  (setq hit (vl-some '(lambda (pr) (if (vl-string-search (car pr) m) pr)) *ANS*))
  (if hit (progn (setq *ANS* (vl-remove hit *ANS*)) (cdr hit)) (if d d "")))
(setq *bht-screen-messages* nil)
(setq r (vl-catch-all-apply 'c:BHTBLOCK nil))
(setq bht:ask-string SV-ASK)
(tchk "V5-17" "BHTBLOCK > D > tìm 'đi chậm' in W.245a - Đi chậm"
      (and (not (vl-catch-all-error-p r)) (vl-some '(lambda (m) (and (vl-string-search "W.245a" m) (vl-string-search "Đi chậm" m))) *bht-screen-messages*))
      (if (vl-catch-all-error-p r) (vl-catch-all-error-message r) (vl-remove-if-not '(lambda (m) (vl-string-search "W.245" m)) *bht-screen-messages*)))
;; --- 7. BHTSIGNSEARCH that (BHT.Bridge, danh muc TDT tren may)
(setq ec (t-netload "BHT.Core.dll") eb (t-netload "BHT.Bridge.dll"))
(if (= (type BHTSIGNSEARCH) 'EXRXSUBR)
  (progn
    (setq s1 (BHTSIGNSEARCH "di cham" 30) s2 (BHTSIGNSEARCH "cam do xe trong khu vuc" 50) s3 (BHTSIGNSEARCH "W245A" 5))
    (tchk "V5-18" "BHTSIGNSEARCH 'di cham' -> OK + W.245a|Đi chậm (danh mục TDT hoặc nội bộ)"
          (and (= (car s1) "OK") (member "W.245a|Đi chậm" s1)) s1)
    (tchk "V5-19" "mã bỏ dấu chấm 'W245A' -> W.245a đứng đầu" (and (= (car s3) "OK") (wcmatch (cadr s3) "W.245a|*")) s3)
    (if (findfile "C:/Program Files (x86)/TDT Solution 2022/Data/Bien bao/Bienbao.xml")
      (tchk "V5-20" "tên bổ sung theo mã cùng thư viện TDT: 'Biển số E,9a' <- R.E,9a (Cấm đỗ xe trong khu vực)"
            (member "Biển số E,9a|Cấm đỗ xe trong khu vực" s2) s2)
      (tskip "V5-20" "tên bổ sung theo thư viện TDT" "BLOCKED" "máy không có TDT Solution 2022")))
  (tchk "V5-18" "NETLOAD BHT.Bridge: BHTSIGNSEARCH đăng ký" nil (list ec eb (type BHTSIGNSEARCH))))
(tend "V5")
(princ)
