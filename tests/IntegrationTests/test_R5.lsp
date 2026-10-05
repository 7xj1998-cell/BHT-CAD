;;; BHT 0.6.13 - Route Model V5: StartPoint/direction/closed/revision/diagnostics + stake scanner read-only.
(load "C:/Users/Le Bao/BHT_TEST_V044/t_common.lsp")
(vl-load-com)
(tbegin "R5")
(setq e (tload))
(tchk "R5-00" "nạp BHT-5.0" (and (null e) (= *bht-version* "0.6.13")) e)
(setq wipe (ssget "_X") wi 0)
(if wipe (repeat (sslength wipe) (entdel (ssname wipe wi)) (setq wi (1+ wi))))

;; Polyline mo; diem dau giua segment.
(setq pl (entmakex '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline")
                     (90 . 2) (70 . 0) (10 0.0 0.0) (10 100.0 0.0))))
(setq rc (bht:route-create "R5OPEN" pl "TIM_DUONG" 20.0 0.0 nil "R5 test"))
(setq rs (bht:route-set-start-dir "R5OPEN" '(25.0 0.0 0.0) 1) rr (bht:route-read "R5OPEN"))
(tchk "R5-A-D-E" "Polyline mở; StartPoint giữa segment; forward; schema/revision V5"
      (and (car rc) (car rs) (= (bht:get rr "start_dist") "25.000000") (= (bht:get rr "direction") "1")
           (= (bht:get rr "route_revision") "2")
           (vl-string-search "0.000000,0.000000" (bht:get rr "geometry_signature"))) rr)
(bht:route-add-mark "R5OPEN" 0.0 1000.0 1000.0 "TEST" "")
(bht:route-add-mark "R5OPEN" 75.0 1075.0 1075.0 "TEST" "")
(setq s (bht:station-route (bht:route-read "R5OPEN") '(50.0 5.0 0.0)))
(tchk "R5-M-N" "station/offset/LEFT theo chiều tăng lý trình"
      (and (= (rv s 'status) "NOI_SUY") (equal (rv s 'station) 1025.0 1e-8)
           (equal (rv s 'offset) 5.0 1e-8) (= (rv s 'side) "TRAI") (rv s 'revision)) s)
(setq before (bht:station-route (bht:route-read "R5OPEN") '(10.0 0.0 0.0)))
(tchk "R5-OPEN-RANGE" "Polyline mở: điểm sau lưng StartPoint bị loại" (= (rv before 'status) "NGOAI_PHAM_VI_HINH_HOC") before)

;; Reverse: cung StartPoint, left/right phai dao.
(setq rs2 (bht:route-set-start-dir "R5OPEN" '(75.0 0.0 0.0) -1) rr2 (bht:route-read "R5OPEN"))
(setq pr (bht:route-project rr2 pl '(50.0 5.0 0.0)))
(tchk "R5-F-L" "reverse + đổi chiều tăng revision + đảo LEFT/RIGHT"
      (and (car rs2) (= (bht:get rr2 "direction") "-1") (= (nth 2 pr) -1)
           (= (bht:get rr2 "station_control_status") "NEEDS_REVIEW") (> (bht:route-revision rr2) 2)) rr2)

;; Polyline kin, wrap qua diem 0 khi StartPoint o raw distance 10.
(setq pc (entmakex '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline")
                     (90 . 4) (70 . 1) (10 0.0 0.0) (10 10.0 0.0) (10 10.0 10.0) (10 0.0 10.0))))
(bht:route-create "R5CLOSED" pc "KHAC" 20.0 0.0 nil "R5 closed")
(bht:route-set-start-dir "R5CLOSED" '(10.0 0.0 0.0) 1)
(setq crc (bht:route-read "R5CLOSED") cp (bht:route-project crc pc '(0.0 0.0 0.0)))
(tchk "R5-B-C-G" "Polyline kín; StartPoint vertex; wrap điểm trước điểm đầu" (and cp (equal (car cp) 30.0 1e-8)) cp)

;; Station break.
(setq marks '((0.0 39000.0 39000.0 "" "") (1000.0 40000.0 40020.0 "" "") (1100.0 40120.0 40120.0 "" "")))
(setq j0 (bht:km-from-dist marks 1000.0 0.0 1) j1 (bht:km-from-dist marks 1050.0 0.0 1))
(tchk "R5-J" "Station break: tại gãy dùng back, sau gãy dùng ahead" (and (equal (cadr j0) 40000.0 1e-8) (equal (cadr j1) 40070.0 1e-8)) (list j0 j1))

;; Bản ghi route cũ không có start/direction/revision vẫn chạy mặc định.
(setq legacy (list (cons "route_id" "R5LEGACY") (cons "handle" (cdr (assoc 5 (entget pl))))
                   (cons "loai" "KHAC") (cons "max_offset" "20") (cons "ngoai_suy_m" "0")
                   (cons "chieu" "1") (cons "moc" "0|1000|1000|legacy|") (cons "moc" "100|1100|1100|legacy|")))
(bht:route-write "R5LEGACY" legacy)
(setq ls (bht:station-route (bht:route-read "R5LEGACY") '(50.0 -3.0 0.0)))
(tchk "R5-O" "Route schema cũ tự dùng start=0, direction=forward, revision=1"
      (and (= (rv ls 'status) "NOI_SUY") (equal (rv ls 'station) 1050.0 1e-8) (= (rv ls 'revision) 1)) ls)

;; Scanner cọc: dữ liệu mô phỏng TEXT/MTEXT; chỉ đọc, phát hiện station jump và không tự nạp cọc lỗi.
(setq t1 (entmakex '((0 . "TEXT") (100 . "AcDbEntity") (8 . "KM_TDT") (100 . "AcDbText") (10 20.0 2.0 0.0) (40 . 1.0) (1 . "Km1+020"))))
(setq t2 (entmakex '((0 . "TEXT") (100 . "AcDbEntity") (8 . "KM_TDT") (100 . "AcDbText") (10 40.0 2.0 0.0) (40 . 1.0) (1 . "KM1+040"))))
(setq t3 (entmakex '((0 . "TEXT") (100 . "AcDbEntity") (8 . "KM_TDT") (100 . "AcDbText") (10 60.0 2.0 0.0) (40 . 1.0) (1 . "Km1+300"))))
(bht:route-create "R5STAKES" pl "TIM_DUONG" 10.0 0.0 nil "R5 stakes")
(setq ec (t-netload "BHT.Core.dll") eb (t-netload "BHT.Bridge.dll"))
(setq sr (if (= (type BHTTDT91STAKES) 'EXRXSUBR) (BHTTDT91STAKES (cdr (assoc 5 (entget pl))) 10.0) nil))
(tchk "R5-H-SCAN" "BHTTDT91STAKES đọc TEXT Km theo ForRead và project lên tuyến"
      (and sr (= (car sr) "OK") (= (length (cdr sr)) 3)) (list ec eb sr))
(setq sc (bht:tdt-stake-candidates (bht:route-read "R5STAKES")) si (if (and sc (/= (car sc) 'LOI)) (bht:tdt-stake-issues sc) nil))
(tchk "R5-I" "chuỗi cọc phát hiện một station jump, không tự sửa" (and (= (length sc) 3) (= (length si) 1) (= (caar si) (cdr (assoc 5 (entget t3))))) (list sc si))
(setq ar (bht:route-add-tdt-stakes "R5STAKES" sc si) rrs (bht:route-read "R5STAKES"))
(tchk "R5-H-I-ACCEPT" "chỉ nạp cọc không cảnh báo sau xác nhận; lưu nguồn/revision"
      (and (= (car ar) 2) (= (cadr ar) 1) (= (length (bht:route-marks rrs)) 2)
           (= (bht:get rrs "station_source") "TDT_STAKES") (> (bht:route-revision rrs) 1)) (list ar rrs))

;; Geometry thay đổi -> chẩn đoán báo nguồn đổi, không dịch điểm nào.
(setq diag0 (bht:route-diag-lines "R5STAKES") d (entget pl) old (assoc 10 (reverse d)))
;; Sửa vertex cuối của POLYLINE TEST, không phải dữ liệu khảo sát.
(entmod (subst (list 10 101.0 0.0) old d))
(setq diag1 (bht:route-diag-lines "R5STAKES"))
(tchk "R5-K-DIAG" "diagnostic phát hiện geometry nguồn thay đổi"
      (and (vl-some '(lambda (x) (vl-string-search "Geometry verified: CÓ" x)) diag0)
           (vl-some '(lambda (x) (vl-string-search "nguồn đã thay đổi" x)) diag1)) (list diag0 diag1))

(tend "R5")
(princ)
