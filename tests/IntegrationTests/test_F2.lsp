;;; BHT 0.6.13 - phien F2: sua loi BHTTUYENTDT ("no function definition" do goi ham kiem tra
;;; kieu Common Lisp khong co trong AutoLISP) va tu nap BHT.Bridge.dll. Ban ve moi, khong dung du lieu khao sat.
;;; Script sau khi nap: BHTTUYENTDT / 5,0 / TUYENF2 / 100 / 0 / (t-f2-after)
(load "C:/Users/Le Bao/BHT_TEST_V044/t_common.lsp")
(vl-load-com)
(tbegin "F2")
(setq e (tload))
(tchk "F00" "nạp BHT-5.0; *bht-version* = 5.0" (and (null e) (= *bht-version* "0.6.13")) (if e e *bht-version*))
(tchk "F01" "thông báo APPLOAD đúng nguyên văn" (= (bht:load-message) "BHT 0.6.13 đã nạp thành công.") (bht:load-message))
(tchk "F02" "bht:fn-defined-p: nhận SUBR/USUBR, từ chối ký hiệu chưa định nghĩa, biến chuỗi, nil, chuỗi"
      (and (bht:fn-defined-p 'strcat) (bht:fn-defined-p 'bht:trim) (bht:fn-defined-p 'c:BHTTUYENTDT)
           (not (bht:fn-defined-p 'bht-khong-co-ham-nay)) (not (bht:fn-defined-p '*bht-version*))
           (not (bht:fn-defined-p nil)) (not (bht:fn-defined-p "strcat")))
      (list (type strcat) (type bht:trim)))
(tchk "F03" "phiên mới: BHTTDT91ROUTE chưa có khi chưa NETLOAD Bridge" (not (bht:fn-defined-p 'BHTTDT91ROUTE)) (type BHTTDT91ROUTE))
(setq r (vl-catch-all-apply 'bht:tdt-import-block (list "W.225")))
(tchk "F03b" "bht:tdt-import-block khi chưa có Bridge: trả nil, không lỗi 'bad function: BHTTDTBLOCK'"
      (and (not (vl-catch-all-error-p r)) (null r)) (if (vl-catch-all-error-p r) (vl-catch-all-error-message r) r))
;; Lisp nam trong thu muc kiem thu, khong co DLL canh file -> BHTTUYENTDT phai bao ro, khong nem loi.
(setq *bht-screen-messages* nil)
(setq r (vl-catch-all-apply 'c:BHTTUYENTDT nil))
(setq m (bht:api-messages "DRAIN"))
(tchk "F04" "BHTTUYENTDT khi không có Bridge: không lỗi 'no function definition', báo chưa nạp BHT.Bridge.dll"
      (and (not (vl-catch-all-error-p r))
           (vl-some '(lambda (s) (wcmatch s "*chưa nạp được BHT.Bridge.dll*")) (cdr m)))
      (if (vl-catch-all-error-p r) (vl-catch-all-error-message r) m))
;; Palette truoc (nhu Application Bundle / APPLOAD), roi Bridge qua bht:bridge-load.
(setq ep (t-netload "BHT.Core.dll"))
(setq ep (t-netload "BHT.Palette.dll"))
(tlog (strcat "INFO F05 sau NETLOAD BHT.Palette.dll: BHTTDT91ROUTE "
              (if (bht:fn-defined-p 'BHTTDT91ROUTE) "ĐÃ có" "CHƯA có") " (type=" (vl-princ-to-string (type BHTTDT91ROUTE)) ")"))
(setq *bht-bridge-dll* (strcat *T-BIN* "BHT.Bridge.dll"))
(setq ok (vl-catch-all-apply 'bht:bridge-load (list 'BHTTDT91ROUTE)))
(tchk "F06" "bht:bridge-load nạp BHT.Bridge.dll; BHTTDT91ROUTE là EXRXSUBR"
      (and (= ok T) (bht:fn-defined-p 'BHTTDT91ROUTE) (= (type BHTTDT91ROUTE) 'EXRXSUBR))
      (list ok (type BHTTDT91ROUTE)))
(setq st (vl-catch-all-apply 'BHTTDT91STATUS nil))
(tlog (strcat "INFO F07 BHTTDT91STATUS = " (vl-princ-to-string st)))
(setq ok2 (bht:bridge-load 'BHTTDT91ROUTE))
(tchk "F08" "gọi lại bht:bridge-load khi Bridge đã có: không NETLOAD lại, trả T" (= ok2 T) ok2)
(setq e2 (t-netload "BHT.Bridge.dll"))
(tchk "F08b" "NETLOAD BHT.Bridge.dll lần 2 không lỗi, BHTTDT91ROUTE vẫn dùng được" (and (null e2) (bht:fn-defined-p 'BHTTDT91ROUTE)) e2)
;; Polyline thuong (khong phai tim TDT) de chay tron lenh BHTTUYENTDT qua script.
(setq *t-f2-pl* (entmakex '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline") (90 . 2) (70 . 0) (10 0.0 0.0) (10 10.0 0.0))))
(setq *t-f2-pl-data* (entget *t-f2-pl*))
(setq *t-f2-routes* (length (bht:route-ids)))
(setq *bht-screen-messages* nil)
(command "_.ZOOM" "_W" "-5,-5" "15,5")
(tlog "   (tiếp theo: BHTTUYENTDT chọn Polyline thường tại 5,0 rồi (t-f2-after))")
(defun t-f2-after (/ m pr)
  (setq pr (bht:api-problems "DRAIN"))
  (setq m (bht:api-messages "DRAIN"))
  (tlog (strcat "   thông báo: " (vl-princ-to-string (cdr m))))
  (tchk "F09" "BHTTUYENTDT chạy hết đường Lisp -> Bridge với Polyline thường: Bridge từ chối rõ ràng, không 'BHT lỗi'"
        (and (vl-some '(lambda (s) (wcmatch s "*không phải tim tuyến TDTSolution 9.1*")) (cdr m))
             (not (vl-some '(lambda (s) (wcmatch s "BHT lỗi*")) (cdr m))))
        (cdr m))
  (tchk "F10" "không tạo tuyến, không tạo Polyline BHT_TUYEN_TDT, Polyline nguồn không đổi"
        (and (= (length (bht:route-ids)) *t-f2-routes*)
             (null (ssget "_X" '((8 . "BHT_TUYEN_TDT"))))
             (equal (entget *t-f2-pl*) *t-f2-pl-data*))
        (list (length (bht:route-ids)) (entget *t-f2-pl*)))
  (tchk "F11" "5.0: lỗi Bridge của BHTTUYENTDT được ghi cho Palette (bht:api-problems ERROR) -> trạng thái báo thất bại"
        (and (vl-some '(lambda (s) (wcmatch s "ERROR|*không phải tim tuyến TDTSolution 9.1*")) (cdr pr))) pr)
  (entdel *t-f2-pl*)
  (tend "F2")
  (princ))
(princ)
