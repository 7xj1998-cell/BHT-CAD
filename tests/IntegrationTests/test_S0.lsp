;;; BHT 0.6.10 - phien S0: nap, phien ban, BHTTEST, Palette va trang thai
(load "C:/Users/Le Bao/BHT_TEST_V044/t_common.lsp")
(tbegin "S0")
(setq e (tload))
(tchk "T00" "nạp BHT-5.0 (đường dẫn có dấu); *bht-version* = 5.0" (and (null e) (= *bht-version* "0.6.10")) (if e e (strcat *bht-version* " / " *bht-build*)))
(tchk "T01" "thông báo APPLOAD đúng nguyên văn" (= (bht:load-message) "BHT 0.6.10 đã nạp thành công.") (bht:load-message))
(setq r (tsafe "T02" "BHTTEST" '(lambda () (bht:selftest))))
(if r (tchk "T02" "BHTTEST tự kiểm tra hàm (0 FAIL, >= 45)" (and (= (cadr r) 0) (>= (car r) 45)) (strcat (itoa (car r)) " pass, " (itoa (cadr r)) " fail")))
(tchk "T03" "DCL dự phòng đã bỏ; các hàm tìm kiếm/trạng thái còn hoạt động"
      (and (not (bht:fn-defined-p 'c:BHTDCL)) (not (bht:fn-defined-p 'c:BHTUITEST))
           (not (bht:fn-defined-p 'bht:ui-write-dcl))
           (= (bht:search-fold "ĐI CHẬM") "di cham") (= (length (bht:status-lines)) 4)) nil)
(setq cmds '(c:BHTSAPNHAN c:BHTNHANTUDONG c:BHTTHUTUVE c:BHTKYHIEU c:BHTDOITUONG c:BHTCHENANH c:BHTDATTUDO))
(tchk "T04" "lệnh hiện hành có đủ; các lệnh nâng cấp cũ đã bỏ"
      (and (vl-every '(lambda (c) (eval c)) cmds) (not (bht:fn-defined-p 'c:BHTVEMODEL))
           (not (bht:fn-defined-p 'c:BHTNANGCAP)) (not (bht:fn-defined-p 'c:BHTROUTE))) nil)
(setq bad nil)
(foreach c '(c:BHTTEST c:BHTKT c:BHTTRANGTHAI c:BHTHELP)
  (if (vl-catch-all-error-p (vl-catch-all-apply c nil)) (setq bad (cons c bad))))
(tchk "T06" "chạy lệnh không tương tác trên bản vẽ trống: BHTTEST, BHTKT, BHTTRANGTHAI, BHTHELP" (null bad) bad)
;; --- API cho plugin .NET, Lisp khong phu thuoc palette ---
(tchk "T07" "19 hàm API đăng ký, gồm đặt biển nhanh" (= *bht-api-registered* 19) *bht-api-registered*)
(setq r (bht:api-version))
(tchk "T08" "bht:api-version = (OK 5.0 1 build)" (equal r (list "OK" "0.6.10" "1" *bht-build*)) r)
(setq *bht-screen-messages* nil)
(bht:msg "Thông báo có dấu từ Lisp")
(setq r (bht:api-messages "DRAIN") r2 (bht:api-messages "PEEK"))
(tchk "T08a" "Palette lấy được thông báo tiếng Việt từ Lisp và DRAIN xóa bộ đệm"
      (and (equal r '("OK" "Thông báo có dấu từ Lisp")) (equal r2 '("OK"))) (list r r2))
(setq r (bht:api-info-object "KHONG-CO"))
(tchk "T09" "API không hỏi người dùng, trả về danh sách chuỗi; hồ sơ không có -> dòng '(không có hồ sơ)'" (and (= (car r) "OK") (vl-every '(lambda (x) (= (type x) 'STR)) r)) r)
(setq r (bht:api-photo-path "KHONG-CO"))
(tchk "T10" "API báo LỖI rõ ràng (không ném lỗi): ảnh không có" (and (= (car r) "LOI") (= (type (cadr r)) 'STR)) r)
(setq r (bht:api-check))
(tchk "T11" "bht:api-check trên bản vẽ trống: OK + số lỗi/cảnh báo" (and (= (car r) "OK") (wcmatch (cadr r) "loi=*") (wcmatch (caddr r) "canh_bao=*")) (list (cadr r) (caddr r)))
(tchk "T12" "không còn c:BHT/c:BTH trong Lisp; đã bỏ DCL dự phòng; có lệnh nạp lại c:BHTLOAD"
      (and (not (eval 'c:BHT)) (not (eval 'c:BTH)) (not (bht:fn-defined-p 'c:BHTDCL)) (bht:fn-defined-p 'c:BHTLOAD)) nil)
(setq r (vl-catch-all-apply 'c:BHTLOAD nil))
(tchk "T13" "BHTLOAD khi DLL không nằm cạnh Lisp: báo rõ, không lỗi" (not (vl-catch-all-error-p r)) nil)
(setq r (bht:api-point-style "1"))
(tchk "T14" "POINT mặc định là dấu X đúng tâm, kích thước tuyệt đối 1 unit; API sắp nhãn chạy được"
      (and (= (car r) "OK") (= (getvar "PDMODE") 3) (equal (getvar "PDSIZE") 1.0 1e-9)) r)
(setq r (vl-catch-all-apply 'bht:block-load-dwg
                            (list (strcat *T-DIR* "run/route_src.dwg") "KHAC")))
(tchk "T15" "nạp DWG ngoài thành block tùy chọn, giữ hệ số đổi đơn vị, không để INSERT tạm"
      (and (not (vl-catch-all-error-p r)) r (tblsearch "BLOCK" r) (> *bht-block-load-factor* 0.0)
           (null (ssget "_X" (list '(0 . "INSERT") (cons 2 r)))))
      (if (vl-catch-all-error-p r) (vl-catch-all-error-message r) (list r *bht-block-load-factor*)))
(bht:symbol-blocks)
(setq bbmaps
  (list
    (list "W.207a" "BHT_KH_BB_W207_V044")
    (list "W-209" "BHT_KH_BB_W209_V044")
    (list "W.239a + S.509a" "BHT_KH_BB_W239A_V044")
    (list "W.245b" "BHT_KH_BB_W245A_V044")
    (list "R.412c" "BHT_KH_BB_R412_V044")
    (list "I.414a" "BHT_KH_BB_I414_V044")
    (list "I.423a" "BHT_KH_BB_I423A_V044")
    (list "I.428" "BHT_KH_BB_I428A_V044")
    (list "I.434a" "BHT_KH_BB_I434A_V044")
    (list "P.127 - 20" "BHT_KH_BB_P127_20_V044")
    (list "P.127/40" "BHT_KH_BB_P127_40_V044")
    (list "KHONG_RO" "BHT_KH_BIEN_BAO_V044")))
(setq bad nil)
(foreach p bbmaps
  (if (/= (bht:bb-block-for (car p)) (cadr p))
    (setq bad (cons (list (car p) (bht:bb-block-for (car p)) (cadr p)) bad))))
(tchk "T16" "mã biển báo và biến thể trong KMZ chọn đúng block chuẩn; mã lạ về block tổng quát"
      (null bad) bad)
(setq bbnames
  '("BHT_KH_BIEN_BAO_V044" "BHT_KH_BB_W207_V044" "BHT_KH_BB_W209_V044"
    "BHT_KH_BB_W239A_V044" "BHT_KH_BB_W245A_V044" "BHT_KH_BB_W201_V044"
    "BHT_KH_BB_W225_V044" "BHT_KH_BB_R412_V044" "BHT_KH_BB_I414_V044"
    "BHT_KH_BB_I423A_V044" "BHT_KH_BB_I428A_V044" "BHT_KH_BB_I434A_V044"
    "BHT_KH_BB_P115_V044" "BHT_KH_BB_P119_V044" "BHT_KH_BB_P124A_V044"
    "BHT_KH_BB_P125_V044" "BHT_KH_BB_P127_V044" "BHT_KH_BB_P127_20_V044"
    "BHT_KH_BB_P127_40_V044"))
(setq missing nil)
(foreach n bbnames (if (not (tblsearch "BLOCK" n)) (setq missing (cons n missing))))
(tchk "T17" "tạo đủ 19 block biển báo tích hợp trong một tệp Lisp"
      (and (null missing) (= (length bbnames) 19)) missing)
(defun t-bb-data (name / e d out done)
  (setq e (tblobjname "BLOCK" name) out nil done nil)
  (while (and e (not done) (setq e (entnext e)))
    (setq d (entget e))
    (if (= (cdr (assoc 0 d)) "ENDBLK") (setq done T) (setq out (cons d out))))
  (reverse out))
(setq bad nil)
(foreach n bbnames
  (foreach d (t-bb-data n)
    (cond
      ((= (cdr (assoc 0 d)) "ATTDEF") (setq bad (cons (list n "ATTDEF") bad)))
      ((and (= (cdr (assoc 0 d)) "TEXT") (or (null (assoc 40 d)) (<= (cdr (assoc 40 d)) 0.0)))
       (setq bad (cons (list n "TEXT_HEIGHT") bad)))
      ((and (= (cdr (assoc 0 d)) "LINE") (equal (cdr (assoc 10 d)) (cdr (assoc 11 d)) 1e-12))
       (setq bad (cons (list n "ZERO_LINE") bad))))))
(tchk "T18" "hình học biển báo không có ATTDEF, text âm/rỗng hoặc đường thẳng dài 0"
      (null bad) bad)
(setq rec '(("nhom" . "BIEN_BAO") ("ma_hieu" . "W.207a")))
(tchk "T19" "hồ sơ BIEN_BAO dùng mã hiệu để chọn block, không cần lệnh rời"
      (= (bht:kh-block rec) "BHT_KH_BB_W207_V044") (bht:kh-block rec))
(tend "S0")
(princ)

