;;; BHT 0.6.12 - phien TX: tim TDT 9.1 dang proxy tren BAN SAO ban ve tuyen that (tdt/tdt_copy.dwg), khong luu.
;;; Bridge phai tu choi proxy, khong tao Polyline, khong sua doi tuong goc.
(load "C:/Users/Le Bao/BHT_TEST_V044/t_common.lsp")
(vl-load-com)
(tbegin "TX")
(setq e (tload))
(tchk "X00" "nạp BHT-5.0" (and (null e) (= *bht-version* "0.6.12")) e)
(defun t-x-types (/ ent d n out k)
  (setq ent (entnext) out nil)
  (while ent
    (setq d (entget ent) k (cdr (assoc 0 d)))
    (if (or (wcmatch (strcase k) "*TDT*,*PROXY*,*ALIGN*") )
      (setq out (if (assoc k out) (subst (cons k (1+ (cdr (assoc k out)))) (assoc k out) out) (cons (cons k 1) out))))
    (setq ent (entnext ent)))
  out)
(tlog (strcat "INFO X01 thực thể TDT/proxy trong model/paper: " (vl-princ-to-string (t-x-types))))
(setq nc (t-netload "BHT.Core.dll") nb (t-netload "BHT.Bridge.dll"))
(tchk "X02" "NETLOAD Core + Bridge" (and (null nc) (null nb)) (list nc nb))
(defun t-x-first (/ ent d hit)
  (setq ent (entnext) hit nil)
  (while (and ent (null hit))
    (setq d (entget ent))
    (if (wcmatch (strcase (cdr (assoc 0 d))) "*TDTDBALIGNMENT*,ACAD_PROXY_ENTITY") (setq hit ent))
    (setq ent (entnext ent)))
  hit)
(setq src (t-x-first))
(if src
  (progn
    (tlog (strcat "INFO X03 đối tượng: " (cdr (assoc 0 (entget src))) " handle " (cdr (assoc 5 (entget src)))
                  " lớp gốc=" (vl-princ-to-string (cdr (assoc 1 (entget src))))))
    (setq before (entget src))
    (setq r (vl-catch-all-apply 'BHTTDT91ROUTE (list (cdr (assoc 5 (entget src))) "")))
    (tlog (strcat "INFO X04 BHTTDT91ROUTE = " (vl-princ-to-string r)))
    (tchk "X04" "đối tượng TDT dạng proxy (chưa có module TDT): Bridge từ chối, không tạo Polyline"
          (and (listp r) (= (car r) "LOI") (wcmatch (cadr r) "*proxy*") (null (ssget "_X" '((8 . "BHT_TUYEN_TDT"))))) r)
    (tchk "X04b" "từ 0.4.6-fix3: thông báo proxy giải thích phiên AutoCAD chưa nạp TDTSolution 9.1 và cách mở lại bằng profile TDT"
          (and (listp r) (= (car r) "LOI") (wcmatch (cadr r) "*chưa nạp TDTSolution 9.1*")
               (wcmatch (cadr r) "*profile TDTSolution 9.1*") (wcmatch (cadr r) "*khóa USB*")) (cadr r))
    (tchk "X05" "đối tượng TDT gốc không đổi sau BHTTDT91ROUTE" (equal (entget src) before) nil))
  (tskip "X03" "tim TDT trong bản sao" "BLOCKED" "không có TDTDBALIGNMENT/proxy trong bản vẽ"))
;; Tim TDT "song" (module TDT 9.1 da nap) KHONG kiem duoc trong Core Console: arxload TDTObjects.dbx
;; lam Core Console dung ("Class 'TdtDbMeasurePointObj' parent named 'TdtDbPointObj' not found") vi can
;; ca bo module/profile TDT va khoa USB. Muc nay de nghiem thu thu cong trong AutoCAD day du.
(tskip "X06" "BHTTUYENTDT trên tim TDT 9.1 sống (module TDT + khóa USB)" "BLOCKED" "Core Console không nạp được module TDT 9.1; kiểm tra thủ công theo CHECKLIST_NGHIEM_THU_5.0")
(tend "TX")
(princ)
