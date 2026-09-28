;;; BHT 0.4.5 - phien S0: nap, phien ban, BHTTEST, DCL tinh
(load "C:/Users/Le Bao/BHT_TEST_V044/t_common.lsp")
(tbegin "S0")
(setq e (tload))
(tchk "T00" "nạp BHT-0.4.5 (đường dẫn có dấu); *bht-version* = 0.4.5" (and (null e) (= *bht-version* "0.4.5")) (if e e (strcat *bht-version* " / " *bht-build*)))
(tchk "T01" "thông báo APPLOAD đúng nguyên văn" (= (bht:load-message) "BHT 0.4.5 đã nạp thành công.") (bht:load-message))
(setq r (tsafe "T02" "BHTTEST" '(lambda () (bht:selftest))))
(if r (tchk "T02" "BHTTEST tự kiểm tra hàm (0 FAIL, >= 45)" (and (= (cadr r) 0) (>= (car r) 45)) (strcat (itoa (car r)) " pass, " (itoa (cadr r)) " fail")))
(setq bad nil keys nil)
(foreach b *bht-ui-buttons*
  (if (and (/= (caddr b) "BHTUIREFRESH") (not (eval (read (strcat "C:" (caddr b)))))) (setq bad (cons (caddr b) bad)))
  (if (member (car b) keys) (setq bad (cons (strcat "trùng khóa " (car b)) bad)) (setq keys (cons (car b) keys))))
(setq tpl (bht:ui-dcl-template) opn 0 cls 0 unk nil)
(foreach l tpl
  (setq opn (+ opn (length (vl-remove-if-not '(lambda (c) (= c 123)) (vl-string->list l))))
        cls (+ cls (length (vl-remove-if-not '(lambda (c) (= c 125)) (vl-string->list l))))))
(foreach b *bht-ui-buttons* (if (not (vl-some '(lambda (l) (vl-string-search (strcat "key = \"" (car b) "\"") l)) tpl)) (setq unk (cons (car b) unk))))
(setq path (bht:ui-write-dcl) left nil)
(if path (progn (setq f (open path "r"))
                (while (setq l (read-line f)) (if (wcmatch l "*`@*`@*") (setq left (cons l left))))
                (close f) (vl-file-delete path)))
(tchk "T03" "DCL tĩnh: mọi nút gọi lệnh có thật, khóa duy nhất, nút nào cũng có trong mẫu, không sót @nhãn@, { } cân bằng (42 nút)"
      (and (null bad) (null unk) (= opn cls) path (null left) (= (length *bht-ui-buttons*) 42))
      (strcat "nút=" (itoa (length *bht-ui-buttons*)) " lỗi=" (vl-princ-to-string bad) " thiếu=" (vl-princ-to-string unk)
              " {=" (itoa opn) " }=" (itoa cls) " sót=" (vl-princ-to-string left)))
(setq cmds '(c:BHTSAPNHAN c:BHTNHANTUDONG c:BHTTHUTUVE c:BHTVEMODEL c:BHTKYHIEU c:BHTDOITUONG c:BHTCHENANH))
(tchk "T04" "lệnh 0.3.3 vẫn được định nghĩa trong 0.4.5" (vl-every '(lambda (c) (eval c)) cmds) nil)
(setq r (vl-catch-all-apply 'bht:ui-validate nil))
(if (and (not (vl-catch-all-error-p r)) r)
  (tchk "T05" "load_dialog DCL trong Core Console" T nil)
  (tskip "T05" "mở bảng DCL BHT (load_dialog / new_dialog / start_dialog)" "BLOCKED" "Core Console không có DCL - kiểm tra thủ công theo CHECKLIST"))
(setq bad nil)
(foreach c '(c:BHTTEST c:BHTKT c:BHTTRANGTHAI c:BHTHELP)
  (if (vl-catch-all-error-p (vl-catch-all-apply c nil)) (setq bad (cons c bad))))
(tchk "T06" "chạy lệnh không tương tác trên bản vẽ trống: BHTTEST, BHTKT, BHTTRANGTHAI, BHTHELP" (null bad) bad)
;; --- API cho plugin .NET, Lisp khong phu thuoc palette ---
(tchk "T07" "14 hàm bht:api-* đăng ký vl-acad-defun (gọi được từ .NET Application.Invoke)" (= *bht-api-registered* 14) *bht-api-registered*)
(setq r (bht:api-version))
(tchk "T08" "bht:api-version = (OK 0.4.5 1 build)" (equal r (list "OK" "0.4.5" "1" *bht-build*)) r)
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
(tchk "T12" "không còn c:BHT/c:BTH trong Lisp; DCL dự phòng là c:BHTDCL; có lệnh nạp lại c:BHTLOAD"
      (and (not (eval 'c:BHT)) (not (eval 'c:BTH)) c:BHTDCL c:BHTLOAD) nil)
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
