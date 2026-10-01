;;; BHT 0.6.5 - phien F3: cua so thong bao loi / canh bao (bht:err / bht:warn / *error*),
;;; tu tat trong Core Console va khi chay script, bht:api-problems cho Palette. Ban ve moi.
(load "C:/Users/Le Bao/BHT_TEST_V044/t_common.lsp")
(vl-load-com)
(tbegin "F3")
(setq e (tload))
(tchk "F3-00" "nạp BHT-5.0; *bht-version* = 5.0; thông báo APPLOAD"
      (and (null e) (= *bht-version* "0.6.5") (= (bht:load-message) "BHT 0.6.5 đã nạp thành công."))
      (if e e (list *bht-version* (bht:load-message))))
(tchk "F3-01" "Core Console được nhận ra (vlax-get-acad-object không trả VLA-OBJECT)"
      (= (bht:core-console-p) T) (list (getvar "PROGRAM") (type (vl-catch-all-apply 'vlax-get-acad-object nil))))
(tchk "F3-02" "đang chạy script (CMDACTIVE bit 4) + Core Console -> không hiện cửa sổ"
      (and (= 4 (logand (getvar "CMDACTIVE") 4)) (null (bht:popup-enabled-p)) (= *bht-popup* T))
      (getvar "CMDACTIVE"))
(setq *bht-screen-messages* nil *bht-screen-problems* nil)
(setq r (vl-catch-all-apply 'bht:err (list "BHT: lỗi thử F3")))
(tchk "F3-03" "bht:err: in dòng lệnh + giữ cho Palette + ghi ERROR, không treo"
      (and (not (vl-catch-all-error-p r))
           (member "BHT: lỗi thử F3" *bht-screen-messages*)
           (equal *bht-screen-problems* '("ERROR|BHT: lỗi thử F3")))
      (list *bht-screen-messages* *bht-screen-problems*))
(setq r (vl-catch-all-apply 'bht:warn (list "BHT: cảnh báo thử F3")))
(tchk "F3-04" "bht:warn: in dòng lệnh + ghi WARN"
      (and (not (vl-catch-all-error-p r)) (member "BHT: cảnh báo thử F3" *bht-screen-messages*)
           (= (car *bht-screen-problems*) "WARN|BHT: cảnh báo thử F3"))
      *bht-screen-problems*)
(setq p1 (bht:api-problems "PEEK") p2 (bht:api-problems "DRAIN") p3 (bht:api-problems "PEEK"))
(tchk "F3-05" "bht:api-problems PEEK / DRAIN theo đúng thứ tự, DRAIN xóa"
      (and (equal p1 '("OK" "ERROR|BHT: lỗi thử F3" "WARN|BHT: cảnh báo thử F3")) (equal p2 p1) (equal p3 '("OK")))
      (list p1 p3))
(bht:err "BHT: lỗi thử F3 lần 2")
(bht:api-messages "DRAIN")
(tchk "F3-06" "bht:api-messages DRAIN xóa luôn lỗi còn lại (Palette xóa trước khi gửi lệnh mới)"
      (null *bht-screen-problems*) *bht-screen-problems*)
(bht:on-error "bad argument type: thu F3")
(tchk "F3-07" "*error* của BHT: lỗi thật -> 'BHT lỗi: ...' + ERROR"
      (and (member "BHT lỗi: bad argument type: thu F3" *bht-screen-messages*)
           (equal *bht-screen-problems* '("ERROR|BHT lỗi: bad argument type: thu F3")))
      *bht-screen-problems*)
(setq *bht-screen-messages* nil *bht-screen-problems* nil)
(bht:on-error "Function cancelled")
(tchk "F3-08" "*error* khi hủy lệnh: chỉ in 'lệnh bị hủy', KHÔNG ghi lỗi"
      (and (vl-some '(lambda (s) (wcmatch s "*lệnh bị hủy*")) *bht-screen-messages*) (null *bht-screen-problems*))
      (list *bht-screen-messages* *bht-screen-problems*))
;; --- Gia lap AutoCAD day du (cua so duoc phep) va BHTPOPUP gia de ghi lai cac lan hien cua so.
(setq *t-orig-enabled* bht:popup-enabled-p *t-pop* nil)
(defun bht:popup-enabled-p () T)
(defun BHTPOPUP (k s) (setq *t-pop* (cons (list k s) *t-pop*)) "SHOWN")
(bht:err "BHT: lỗi thử cửa sổ")
(bht:warn "BHT: cảnh báo thử cửa sổ")
(tchk "F3-09" "AutoCAD đầy đủ: bht:err -> BHTPOPUP ERROR, bht:warn -> BHTPOPUP WARN (nội dung nguyên văn)"
      (equal *t-pop* '(("WARN" "BHT: cảnh báo thử cửa sổ") ("ERROR" "BHT: lỗi thử cửa sổ"))) *t-pop*)
(setq *t-pop* nil)
(bht:on-error "Function cancelled")
(bht:on-error "*Cancel*")
(bht:msg "BHT: thông tin thường")
(tchk "F3-10" "hủy lệnh (*Cancel*) và thông tin thường: KHÔNG hiện cửa sổ" (null *t-pop*) *t-pop*)
(bht:on-error "no function definition: THU")
(tchk "F3-11" "*error* lỗi thật: hiện cửa sổ ERROR 'BHT lỗi: ...'"
      (equal *t-pop* '(("ERROR" "BHT lỗi: no function definition: THU"))) *t-pop*)
(setq *t-pop* nil)
(setq r (vl-catch-all-apply 'bht:ask-route nil))
(tchk "F3-12" "đường thật: chưa có tuyến -> cảnh báo 'chưa có tuyến. Dùng BHTTUYEN trước.' hiện cửa sổ"
      (and (not (vl-catch-all-error-p r)) (null r)
           (equal *t-pop* '(("WARN" "BHT: chưa có tuyến. Dùng BHTTUYEN trước.")))) (list r *t-pop*))
(setq *bht-popup* nil *t-pop* nil)
(defun bht:popup-enabled-p () (and *bht-popup* T))
(bht:err "BHT: lỗi khi đã tắt cửa sổ")
(tchk "F3-13" "(setq *bht-popup* nil): không hiện cửa sổ, vẫn in dòng lệnh"
      (and (null *t-pop*) (member "BHT: lỗi khi đã tắt cửa sổ" *bht-screen-messages*)) *t-pop*)
(setq *bht-popup* T)
(defun bht:popup-enabled-p () T)
(setq BHTPOPUP nil)
(setq r (vl-catch-all-apply 'bht:err (list "BHT: thử alert dự phòng (Palette chưa nạp)")))
(tchk "F3-14" "Palette chưa nạp (không có BHTPOPUP): dùng alert dự phòng, không lỗi / không treo"
      (not (vl-catch-all-error-p r)) (if (vl-catch-all-error-p r) (vl-catch-all-error-message r) "alert đã tự đóng (Core Console)"))
(setq bht:popup-enabled-p *t-orig-enabled*)
(tchk "F3-15" "khôi phục bht:popup-enabled-p: Core Console lại tắt cửa sổ" (null (bht:popup-enabled-p)) nil)
;; --- BHTPOPUP that trong BHT.Palette.dll
(setq ec (t-netload "BHT.Core.dll") eb (t-netload "BHT.Bridge.dll") ep (t-netload "BHT.Palette.dll"))
(tchk "F3-16" "NETLOAD Palette: BHTPOPUP đăng ký (EXRXSUBR)" (= (type BHTPOPUP) 'EXRXSUBR) (list ec eb ep (type BHTPOPUP)))
(setq r (if (= (type BHTPOPUP) 'EXRXSUBR) (vl-catch-all-apply 'BHTPOPUP (list "ERROR" "BHT: thử BHTPOPUP trong Core Console")) 'KHONG_CO))
(tchk "F3-17" "BHTPOPUP trong Core Console trả \"SKIP\" (không mở MessageBox, không treo)" (= r "SKIP") r)
(setq *t-pop* nil)
(defun bht:popup-enabled-p () T)
(setq r (vl-catch-all-apply 'bht:warn (list "BHT: thử qua BHTPOPUP thật")))
(setq bht:popup-enabled-p *t-orig-enabled*)
(tchk "F3-18" "bht:warn qua BHTPOPUP thật (SKIP): không lỗi, không rơi về alert" (not (vl-catch-all-error-p r)) r)
(tchk "F3-19" "bht:api-problems nằm trong danh sách hàm API đăng ký cho Palette"
      (and (member 'bht:api-problems *bht-api-functions*) (bht:fn-defined-p 'bht:api-problems)) nil)
(tend "F3")
(princ)
