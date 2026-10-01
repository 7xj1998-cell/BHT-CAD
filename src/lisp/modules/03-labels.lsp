;;; ----------------------------------------------------------------------
;;; Nhan diem RTK (TEXT) - BHTNHANDIEM / BHTANNHAN / BHTSAPNHAN / BHTNHANTUDONG
;;;  Moi nhan la 1 TEXT mang XData "BHT_NHAN".
;;;   0.3.2: (survey_point_id loai)
;;;   0.3.3: (survey_point_id loai trang_thai x y)
;;;     trang_thai TU_DONG: BHT dat nhan; x y = vi tri BHT dat lan cuoi.
;;;     trang_thai TAY: nguoi dung da doi cho nhan; x y = vi tri ghi nhan.
;;;   Neu vi tri thuc cua nhan TU_DONG khac x y -> nguoi dung da keo nhan ->
;;;   chuyen sang TAY va GIU NGUYEN vi tri o moi lan cap nhat sau.
;;;   Nhan 0.3.2 (khong co trang thai): dang o vi tri mac dinh 0.3.2 -> TU_DONG,
;;;   khac vi tri do -> TAY (nang cap XData mot lan, truoc khi doi cai dat).
;;;  loai: TEN / MOTA / CAODO / ID. Chi TEXT co XData nay moi bi cap nhat
;;;  hoac xoa. POINT va du lieu khao sat KHONG bao gio bi sua / di chuyen.
;;;  Noi dung nhan lay nguyen van chuoi goc (ten, mo ta, Z) trong XData.
;;;  Cai dat luu trong tu dien ban ve (META/CONFIG): nhan_che_do (T/TM/TMC),
;;;  nhan_id (0/1), nhan_an (0/1), nhan_h, nhan_offset, nhan_kieu_chu,
;;;  nhan_uu_tien_dt (0/1: an nhan phu cua diem da thuoc ho so doi tuong).
;;;  Bo tri: moi diem = 1 khoi nhan (cac dong xep chong); thu 8 huong x 4
;;;  ban kinh quanh diem, chon vi tri it chong lan nhat voi nhan khac, ky
;;;  hieu BHT, ky hieu / nhan anh va cac diem RTK. Khu vuc day co the van
;;;  con chong lan - so luong duoc bao cao, khong khang dinh bang 0.
;;; ----------------------------------------------------------------------

(setq *bht-lbl-kinds*
  '(("TEN"   "BHT_RTK_TEN"    7)
    ("MOTA"  "BHT_RTK_MOTA"   3)
    ("CAODO" "BHT_RTK_CAO_DO" 5)
    ("ID"    "BHT_RTK_ID"     8)))

(setq *bht-lbl-dirs* '((1 1) (1 0) (1 -1) (-1 1) (-1 0) (-1 -1) (0 1) (0 -1)))
(setq *bht-lbl-tol* 1e-4)

(defun bht:lbl-settings (/ h off)
  (setq h (bht:num (bht:meta "nhan_h" "0.5")) off (bht:num (bht:meta "nhan_offset" "0.65")))
  (list (cons 'mode (strcase (bht:meta "nhan_che_do" "TMC")))
        (cons 'id (= (bht:meta "nhan_id" "0") "1"))
        (cons 'h (if (and h (> h 0)) h 0.5))
        (cons 'off (if off off 0.65))
        ;; 0.5.1: cac mac dinh BHT cu duoc chuyen sang BHT_TCVN; kieu rieng van giu.
        (cons 'style (bht:default-label-style))
        (cons 'hidden (= (bht:meta "nhan_an" "0") "1"))
        (cons 'prio (= (bht:meta "nhan_uu_tien_dt" "0") "1")))
)

(defun bht:lbl-mode-name (mode)
  (cond ((= mode "T") "tên")
        ((= mode "TM") "tên + mô tả")
        (T "tên + mô tả + cao độ"))
)

;; Cac loai nhan theo che do: T / TM / TMC (+ ID neu bat).
(defun bht:lbl-kinds-for (mode showid / out)
  (setq mode (strcase mode) out (list "TEN"))
  (if (member mode '("TM" "TMC")) (setq out (append out (list "MOTA"))))
  (if (= mode "TMC") (setq out (append out (list "CAODO"))))
  (if showid (setq out (append out (list "ID"))))
  out
)

;; Che do uu tien ho so: diem thuoc ho so doi tuong chi giu nhan TEN.
(defun bht:lbl-kinds-point (kinds pid owners prio)
  (if (and prio (assoc (strcase pid) owners))
    (vl-remove-if-not '(lambda (k) (= k "TEN")) kinds)
    kinds)
)

;; Noi dung nhan - NGUYEN VAN chuoi goc (khong dinh dang lai so).
(defun bht:lbl-text (p kind)
  (cond ((= kind "TEN") (bht:str (bht:pv p 'name)))
        ((= kind "MOTA") (bht:str (bht:pv p 'desc)))
        ((= kind "CAODO") (if (/= (bht:trim (bht:pv p 'z)) "") (strcat "H = " (bht:pv p 'z)) ""))
        ((= kind "ID") (bht:str (bht:pv p 'id)))
        (T ""))
)

;; (0.3.2, giu de tuong thich / nhan dien vi tri cu) nhan can co cho 1 diem:
;; ((loai chuoi diem_chen layer) ...) theo cach dat 0.3.2 (dong dau o diem + lech).
(defun bht:lbl-wanted (p kinds h off / xyz x y z out line s)
  (setq xyz (bht:pv p 'xyz) x (+ (car xyz) off) y (+ (cadr xyz) off) z (caddr xyz) out nil line 0)
  (foreach k kinds
    (setq s (bht:lbl-text p k))
    (if (/= s "")
      (setq out (append out (list (list k s (list x (- y (* line 1.5 h)) z)
                                        (cadr (assoc k *bht-lbl-kinds*)))))
            line (1+ line))))
  out
)

;; Cac dong nhan can co (0.3.3): ((loai chuoi layer) ...), bo chuoi rong.
(defun bht:lbl-lines (p kinds / out s)
  (setq out nil)
  (foreach k kinds
    (setq s (bht:lbl-text p k))
    (if (/= s "") (setq out (append out (list (list k s (cadr (assoc k *bht-lbl-kinds*))))))))
  out
)

;; Khoang dong compact: cac dong ten / mo ta / cao do cua cung mot diem
;; luon la mot cum nhan, khong bi tach va tan ra rieng le.
(defun bht:lbl-line-step (h) (* 1.5 h))

(defun bht:lbl-xdata (pid kind state pt)
  (list -3 (list "BHT_NHAN" (cons 1000 pid) (cons 1000 kind) (cons 1000 state)
                 (cons 1000 (bht:fnum (car pt) 6)) (cons 1000 (bht:fnum (cadr pt) 6))))
)

(defun bht:lbl-make (pid kind s pt h style layer)
  (entmakex (list '(0 . "TEXT") '(410 . "Model") (cons 8 layer) (cons 10 pt) (cons 40 h) (cons 1 (bht:cad-text s style)) '(50 . 0.0)
                  (cons 7 style) '(72 . 0) '(73 . 0)
                  (bht:lbl-xdata pid kind "TU_DONG" pt)))
)

(defun bht:lbl-apply (d s pt h style layer)
  (setq d (bht:dxf-put d 1 (bht:cad-text s style)) d (bht:dxf-put d 40 h) d (bht:dxf-put d 7 style) d (bht:dxf-put d 8 layer))
  (bht:dxf-put d 10 pt)
)

(defun bht:lbl-visibility (hidden)
  (foreach k *bht-lbl-kinds* (bht:layer-on (cadr k) (not hidden)))
)

;; ---- Hinh hoc hop bao --------------------------------------------------

;; Sap xep KHONG bo phan tu trung (vl-sort co the bo phan tu trung nhau).
(defun bht:sort-by (lst fn)
  (mapcar '(lambda (i) (nth i lst)) (vl-sort-i lst fn))
)

;; Dien tich giao cua 2 hop (x1 y1 x2 y2).
(defun bht:box-ov (a b / w h)
  (setq w (- (min (caddr a) (caddr b)) (max (car a) (car b)))
        h (- (min (cadddr a) (cadddr b)) (max (cadr a) (cadr b))))
  (if (and (> w 0.0) (> h 0.0)) (* w h) 0.0)
)

;; Hai hop co giao nhau (ke ca cham canh)?
(defun bht:box-hit (a b)
  (and (<= (car a) (caddr b)) (>= (caddr a) (car b)) (<= (cadr a) (cadddr b)) (>= (cadddr a) (cadr b)))
)

;; Hop chu (tuong doi diem chen) cho chuoi s, cao h, kieu chu style: ((x1 y1) (x2 y2)).
(defun bht:lbl-tbox (s h style / tb)
  (setq tb (vl-catch-all-apply 'textbox (list (list (cons 0 "TEXT") (cons 1 (bht:cad-text s style)) (cons 40 h) (cons 7 style)))))
  (if (or (null tb) (vl-catch-all-error-p tb) (/= (type tb) 'LIST))
    (list (list 0.0 0.0) (list (* 0.62 h (strlen s)) h))
    (list (list (car (car tb)) (cadr (car tb))) (list (car (cadr tb)) (cadr (cadr tb)))))
)

;; Hop bao tuyet doi cua 1 TEXT tren ban ve (nhan BHT luon goc quay 0).
(defun bht:text-box (e / d tb p h)
  (setq d (entget e) p (cdr (assoc 10 d)) h (cdr (assoc 40 d))
        tb (vl-catch-all-apply 'textbox (list d)))
  (if (or (null tb) (vl-catch-all-error-p tb) (/= (type tb) 'LIST))
    (setq tb (list (list 0.0 0.0) (list (* 0.62 h (strlen (cdr (assoc 1 d)))) h))))
  (list (+ (car p) (car (car tb))) (+ (cadr p) (cadr (car tb)))
        (+ (car p) (car (cadr tb))) (+ (cadr p) (cadr (cadr tb))))
)

(defun bht:box-around (p rx ry)
  (list (- (car p) rx) (- (cadr p) ry) (+ (car p) rx) (+ (cadr p) ry))
)

;; Vat can co dinh cho bo tri nhan: moi diem RTK, ky hieu doi tuong, ky hieu anh,
;; nhan ky hieu doi tuong, nhan ma anh, duong dan anh. Tra ve danh sach hop.
(defun bht:lbl-obstacles (index h / out r e d sc)
  ;; Bao tron nua kich thuoc dau X + khe ho 0.15 lan chieu cao chu.
  ;; Nhan khong duoc che tam POINT, ke ca khi PDSIZE = 1 unit.
  (setq out nil r (+ (/ (bht:point-size) 2.0) (* 0.15 h)))
  (foreach it index (setq out (cons (bht:box-around (bht:pv (cdr it) 'xyz) r r) out)))
  (foreach pr (bht:tagged-pairs "INSERT" "BHT_KH" 1)
    (setq d (entget (cdr pr)) sc (abs (cdr (assoc 41 d))))
    (setq out (cons (bht:box-around (cdr (assoc 10 d)) (* 1.5 sc) (* 2.0 sc)) out)))
  (foreach pr (bht:tagged-pairs "INSERT" "BHT_ANHPT" 1)
    (setq d (entget (cdr pr)) sc (abs (cdr (assoc 41 d))))
    (setq out (cons (bht:box-around (cdr (assoc 10 d)) (* 1.0 sc) (* 1.0 sc)) out)))
  (foreach pr (bht:tagged-pairs "TEXT" "BHT_KH" 1) (setq out (cons (bht:text-box (cdr pr)) out)))
  (foreach pr (bht:tagged-pairs "TEXT" "BHT_ANHTEN" 1) (setq out (cons (bht:text-box (cdr pr)) out)))
  out
)

;; Vi tri ung vien (goc duoi-trai cua khoi nhan rong w cao hh) quanh diem (px py).
;; Thu tu: ban kinh tang dan, moi ban kinh 8 huong (DB, D, DN, TB, T, TN, B, N).
(defun bht:lbl-cands (px py w hh off h / out)
  (setq out nil)
  (foreach g (list off (+ off (* 1.5 h)) (+ off (* 3.0 h)) (+ off (* 5.0 h))
                   (+ off (* 8.0 h)) (+ off (* 12.0 h)) (+ off (* 18.0 h)) (+ off (* 25.0 h)))
    (foreach dd *bht-lbl-dirs*
      (setq out (cons (list (cond ((= (car dd) 1) (+ px g)) ((= (car dd) -1) (- px g w)) (T (- px (/ w 2.0))))
                            (cond ((= (cadr dd) 1) (+ py g)) ((= (cadr dd) -1) (- py g hh)) (T (- py (/ hh 2.0)))))
                      out))))
  (reverse out)
)

;; BO TRI NHAN (ham thuan, khong dung ban ve).
;; items = ((khoa px py rong cao) ...), obs = danh sach hop vat can co dinh.
;; 2 luot: luot 1 tham lam trai -> phai; luot 2 dat lai tung khoi khi da biet
;; moi khoi lan can. Tra ve ((khoa bx by chi_phi) ...), chi_phi = tong dien tich chong lan.
(defun bht:lbl-layout (items obs off h / sorted lst i sym rmax maxow lo olo el px py it w hh nb j bx ri reach
                                        best bestc k area b cost c cands done out pass)
  (setq sorted (bht:sort-by items '(lambda (a b) (< (cadr a) (cadr b)))) lst nil i 0 rmax 0.0 maxow 0.0)
  (foreach it sorted
    (setq sym (read (strcat "BHT-LB-" (itoa i))))
    (set sym nil)
    (setq lst (cons (list (cadr it) (caddr it) sym it) lst) i (1+ i)
          rmax (max rmax (+ off (* 25.0 h) (max (nth 3 it) (nth 4 it))))))
  (setq lst (reverse lst)
        obs (bht:sort-by obs '(lambda (a b) (< (car a) (car b)))))
  (foreach b obs (setq maxow (max maxow (- (caddr b) (car b)))))
  (setq pass 0)
  (repeat 2
    (setq pass (1+ pass) lo lst olo obs)
    (foreach el lst
      (setq px (car el) py (cadr el) it (cadddr el) w (nth 3 it) hh (nth 4 it) nb nil)
      ;; khoi nhan lan can (cua diem khac) da dat
      (while (and lo (< (car (car lo)) (- px (* 2.0 rmax)))) (setq lo (cdr lo)))
      (setq ri (+ off (* 25.0 h) (max w hh))
            reach (list (- px ri) (- py ri) (+ px ri) (+ py ri)))
      (setq j lo)
      (while (and j (<= (car (car j)) (+ px (* 2.0 rmax))))
        (if (and (not (eq (car j) el)) (setq bx (eval (caddr (car j)))) (bht:box-hit bx reach))
          (setq nb (cons bx nb)))
        (setq j (cdr j)))
      ;; vat can co dinh trong cua so
      (while (and olo (< (car (car olo)) (- px ri maxow))) (setq olo (cdr olo)))
      (setq j olo)
      (while (and j (<= (car (car j)) (+ px rmax)))
        (if (bht:box-hit (car j) reach) (setq nb (cons (car j) nb)))
        (setq j (cdr j)))
      ;; chon ung vien chi phi nho nhat (dung ngay khi gap vi tri khong chong lan)
      (setq best nil bestc nil k 0 area (* w hh) cands (bht:lbl-cands px py w hh off h) done nil)
      (while (and cands (not done))
        (setq c (car cands) cands (cdr cands)
              b (list (car c) (cadr c) (+ (car c) w) (+ (cadr c) hh)) cost 0.0)
        (foreach o nb (setq cost (+ cost (bht:box-ov b o))))
        (if (or (null bestc) (< (+ cost (* k 0.0005 area)) (car bestc)))
          (setq bestc (list (+ cost (* k 0.0005 area)) cost) best b))
        (if (<= cost 1e-12) (setq done T))
        (setq k (1+ k)))
      (set (caddr el) best)
      (set (read (strcat (vl-symbol-name (caddr el)) "-C")) (cadr bestc))))
  (setq out nil)
  (foreach el lst
    (setq b (eval (caddr el)) sym (read (strcat (vl-symbol-name (caddr el)) "-C")))
    (setq out (cons (list (car (cadddr el)) (car b) (cadr b) (eval sym)) out))
    (set (caddr el) nil) (set sym nil))
  (reverse out)
)

;; ---- Trang thai nhan (tu dong / tay) ---------------------------------------

;; Vi tri mac dinh 0.3.2 cua nhan loai kind cho diem p, biet cac loai nhan hien co.
(defun bht:lbl-legacy-pos (p kind exist-kinds h off / line xyz)
  (setq line 0 xyz (bht:pv p 'xyz))
  (foreach kd *bht-lbl-kinds*
    (if (and (member (car kd) exist-kinds)
             (< (vl-position (car kd) (mapcar 'car *bht-lbl-kinds*)) (vl-position kind (mapcar 'car *bht-lbl-kinds*))))
      (setq line (1+ line))))
  (list (+ (car xyz) off) (- (+ (cadr xyz) off) (* line 1.5 h)))
)

(defun bht:pt-near (a b tol)
  (and a b (<= (abs (- (car a) (car b))) tol) (<= (abs (- (cadr a) (cadr b))) tol))
)

;; Trang thai nhan: 'TAY hoac 'AUTO (khong sua gi).
(defun bht:lbl-state (e / x pos)
  (setq x (bht:xget e "BHT_NHAN") pos (cdr (assoc 10 (entget e))))
  (cond ((< (length x) 5) 'LEGACY)
        ((= (nth 2 x) "TAY") 'TAY)
        ((bht:pt-near pos (list (bht:num (nth 3 x)) (bht:num (nth 4 x))) *bht-lbl-tol*) 'AUTO)
        (T 'TAY))
)

;; Ghi trang thai vao XData cua nhan (giu vi tri).
(defun bht:lbl-set-state (e state / d x)
  (setq d (entget e) x (bht:xget e "BHT_NHAN"))
  (if (entmod (append d (list (bht:lbl-xdata (car x) (cadr x) state (cdr (assoc 10 d))))))
    (progn (entupd e) T) nil)
)

;; Nang cap XData nhan 0.3.2 -> 0.3.3 (goi TRUOC khi doi cai dat nhan).
;; Tra ve (so_tu_dong so_tay).
(defun bht:lbl-sync () (bht:lbl-sync-scope nil))

;; scope: nil = chi bo tri diem moi / doi noi dung; 'ALL = bo tri lai moi diem;
;; danh sach survey id = bo tri lai cac diem do (nhan tay van giu nguyen).
;; Tra ve assoc: points created updated unchanged deleted laidout manual cost
(defun bht:lbl-sync-scope (scope / st kinds h off style prio groups index owners created updated same deleted
                                   manual n seen plans items fixed pid p want exist e d k autol manl need
                                   lines w hh tb res pl bx by nl i pt new cost ex)
  (setq st (bht:lbl-settings)
        kinds (bht:lbl-kinds-for (cdr (assoc 'mode st)) (cdr (assoc 'id st)))
        h (cdr (assoc 'h st)) off (cdr (assoc 'off st)) prio (cdr (assoc 'prio st))
        style (bht:text-style (cdr (assoc 'style st)))
        created 0 updated 0 same 0 deleted 0 manual 0 n 0 seen nil plans nil items nil fixed nil cost 0.0)
  (if (and scope (listp scope)) (setq scope (mapcar 'strcase scope)))
  (bht:regapp "BHT_NHAN")
  (foreach kd *bht-lbl-kinds* (bht:layer (cadr kd) (caddr kd)))
  (setq groups (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_NHAN" 2))
        index (bht:pt-all)
        owners (if prio (bht:pt-owner-map) nil))
  (foreach it index
    (setq pid (car it) p (cdr it) n (1+ n)
          want (bht:lbl-lines p (bht:lbl-kinds-point kinds pid owners prio))
          autol nil manl nil need nil exist nil)
    (foreach kd *bht-lbl-kinds*
      (setq k (strcat pid "|" (car kd)))
      (if (setq ex (cdr (assoc k groups)))
        (progn
          ;; nhan trung cho cung khoa: giu cai dau, xoa phan thua (chi TEXT mang BHT_NHAN)
          (foreach e2 (cdr ex) (entdel e2) (setq deleted (1+ deleted)))
          (setq exist (cons (cons (car kd) (car ex)) exist)))))
    (foreach wl want
      (setq k (car wl) e (cdr (assoc k exist)) seen (cons (strcat pid "|" k) seen))
      (cond
        ((null e) (setq need T autol (append autol (list (list k (cadr wl) (caddr wl) nil)))))
        ((eq (bht:lbl-state e) 'TAY)
         ;; nhan tay: cap nhat noi dung / kieu, GIU vi tri
         (setq d (entget e) pt (cdr (assoc 10 d))
               new (bht:lbl-apply d (cadr wl) pt h style (caddr wl)))
         (setq new (append new (list (bht:lbl-xdata pid k "TAY" pt))))
         (entmod new) (entupd e)
         (setq manual (1+ manual) manl (cons e manl)))
        (T
         (setq d (entget e))
         (if (or (/= (cdr (assoc 1 d)) (bht:cad-text (cadr wl) style)) (not (equal (cdr (assoc 40 d)) h 1e-9))
                 (/= (strcase (cdr (assoc 7 d))) (strcase style)))
           (setq need T))
         (setq autol (append autol (list (list k (cadr wl) (caddr wl) e)))))))
    ;; nhan tu dong khong con can (doi che do / uu tien ho so) -> khoi nhan doi -> bo tri lai
    (foreach ex exist
      (if (and (not (assoc (car ex) want)) (not (eq (bht:lbl-state (cdr ex)) 'TAY))) (setq need T)))
    (if (or (= scope 'ALL) (and scope (member pid scope))) (setq need T))
    (cond
      ((null autol) nil)
      (need
       (setq w 0.0 nl (length autol))
       (foreach al autol
         (setq tb (bht:lbl-tbox (cadr al) h style) w (max w (car (cadr tb)))))
        (setq hh (+ h (* (1- nl) (bht:lbl-line-step h)) (* 0.25 h)))
       (setq items (cons (list pid (car (bht:pv p 'xyz)) (cadr (bht:pv p 'xyz)) w hh) items)
             plans (cons (list pid autol (bht:pv p 'xyz) hh) plans)))
      (T
       ;; khong can bo tri: giu vi tri, cap nhat layer neu can
       (foreach al autol
         (setq d (entget (nth 3 al)))
         (if (/= (cdr (assoc 8 d)) (nth 2 al))
           (progn (entmod (bht:dxf-put d 8 (nth 2 al))) (entupd (nth 3 al)) (setq updated (1+ updated)))
           (setq same (1+ same)))
         (setq fixed (cons (nth 3 al) fixed)))))
    (foreach e2 manl (setq fixed (cons e2 fixed)))
    (bht:test-tick))
  ;; nhan khong con can: diem da xoa, doi che do, mo ta rong, uu tien ho so
  (foreach g2 groups
    (if (not (member (car g2) seen))
      (foreach e2 (cdr g2) (if (entget e2) (progn (entdel e2) (setq deleted (1+ deleted)))))))
  ;; bo tri cac khoi nhan can dat
  (if items
    (progn
      (setq res (bht:lbl-layout items
                                (append (mapcar 'bht:text-box fixed) (bht:lbl-obstacles index h))
                                off h))
      (foreach r res
        (setq pl (assoc (car r) plans) bx (cadr r) by (caddr r) nl (length (cadr pl)) i 0
              cost (+ cost (cadddr r)))
        (foreach al (cadr pl)
          (setq pt (list bx (+ by (* 0.25 h) (* (- nl 1 i) (bht:lbl-line-step h))) (caddr (caddr pl))))
          (if (nth 3 al)
            (progn
              (setq d (entget (nth 3 al))
                    new (append (bht:lbl-apply d (cadr al) pt h style (nth 2 al))
                                (list (bht:lbl-xdata (car pl) (car al) "TU_DONG" pt))))
              (entmod new) (entupd (nth 3 al)) (setq updated (1+ updated)))
            (if (bht:lbl-make (car pl) (car al) (cadr al) pt h style (nth 2 al))
              (setq created (1+ created))
              (bht:log (strcat "LỖI tạo nhãn " (car pl) "|" (car al)))))
          (setq i (1+ i))))))
  (bht:lbl-visibility (cdr (assoc 'hidden st)))
  (bht:log (strcat "Nhãn điểm RTK: " (itoa n) " điểm, tạo " (itoa created) ", cập nhật " (itoa updated)
                   ", giữ " (itoa same) ", xóa " (itoa deleted) ", bố trí " (itoa (length items))
                   " khối, nhãn tay giữ nguyên " (itoa manual)))
  (list (cons 'points n) (cons 'created created) (cons 'updated updated) (cons 'unchanged same)
        (cons 'deleted deleted) (cons 'laidout (length items)) (cons 'manual manual) (cons 'cost cost))
)

;; Dem chong lan tren ban ve (chi doc): nhan diem RTK voi nhau (khac diem) va
;; voi vat can (diem RTK khac, ky hieu, ky hieu anh, nhan ky hieu / ma anh).
;; scope nil = moi nhan; danh sach id = chi nhan cua cac diem do.
;; Tra ve assoc: labels pairs obstacle overlapped
(defun bht:lbl-overlaps (scope / lb index h boxes obs sorted pairs ob ovl lst j a b pid seen mark r own maxow olo cnt)
  (setq index (bht:pt-all) h (cdr (assoc 'h (bht:lbl-settings))) boxes nil pairs 0 ob 0 seen nil)
  (if scope (setq scope (mapcar 'strcase scope)))
  (foreach pr (bht:tagged-pairs "TEXT" "BHT_NHAN" 2)
    (setq pid (car (bht:split (car pr) "|")))
    (setq boxes (cons (list (bht:text-box (cdr pr)) pid (cdr pr)) boxes)))
  (setq sorted (bht:sort-by boxes '(lambda (a b) (< (car (car a)) (car (car b))))))
  ;; nhan - nhan (khac diem)
  (setq lst sorted)
  (while lst
    (setq a (car lst) j (cdr lst))
    (while (and j (< (car (car (car j))) (caddr (car a))))
      (setq b (car j))
      (if (and (/= (cadr a) (cadr b)) (> (bht:box-ov (car a) (car b)) 1e-9)
               (or (null scope) (member (cadr a) scope) (member (cadr b) scope)))
        (progn (setq pairs (1+ pairs))
               (setq seen (bht:unique-add (bht:unique-add seen (caddr a)) (caddr b)))))
      (setq j (cdr j)))
    (setq lst (cdr lst)))
  ;; nhan - vat can
  (setq r (* 0.2 h) obs nil)
  (foreach it index (setq obs (cons (list (bht:box-around (bht:pv (cdr it) 'xyz) r r) (car it)) obs)))
  (foreach b (bht:lbl-obstacles nil h) (setq obs (cons (list b nil) obs)))
  (setq obs (bht:sort-by obs '(lambda (a b) (< (car (car a)) (car (car b))))) maxow 0.0)
  (foreach o obs (setq maxow (max maxow (- (caddr (car o)) (car (car o))))))
  (setq olo obs)
  (foreach a sorted
    (while (and olo (< (car (car (car olo))) (- (car (car a)) maxow))) (setq olo (cdr olo)))
    (if (or (null scope) (member (cadr a) scope))
      (progn
        (setq mark nil j olo)
        (while (and j (not mark) (< (car (car (car j))) (caddr (car a))))
          (if (and (/= (cadr (car j)) (cadr a)) (> (bht:box-ov (car a) (car (car j))) 1e-9))
            (setq mark T))
          (setq j (cdr j)))
        (if mark (setq ob (1+ ob) seen (bht:unique-add seen (caddr a)))))))
  (list (cons 'labels (length (if scope (vl-remove-if-not '(lambda (x) (member (cadr x) scope)) boxes) boxes)))
        (cons 'pairs pairs) (cons 'obstacle ob) (cons 'overlapped (length seen)))
)

(defun bht:lbl-overlap-text (o)
  (strcat (itoa (cdr (assoc 'overlapped o))) " / " (itoa (cdr (assoc 'labels o)))
          " nhãn còn chồng lấn (cặp nhãn-nhãn " (itoa (cdr (assoc 'pairs o)))
          ", nhãn đè ký hiệu/điểm " (itoa (cdr (assoc 'obstacle o))) ")")
)

;; Xoa MOI nhan diem BHT (chi TEXT mang BHT_NHAN). Diem RTK giu nguyen.
(defun bht:lbl-remove-all (/ n)
  (setq n 0)
  (foreach p (bht:tagged-pairs "TEXT" "BHT_NHAN" 2) (entdel (cdr p)) (setq n (1+ n)))
  n
)

;; So diem RTK dang co nhan ten.
(defun bht:lbl-count-points (/ g n)
  (setq g (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_NHAN" 2)) n 0)
  (foreach it (bht:pt-all) (if (assoc (strcat (car it) "|TEN") g) (setq n (1+ n))))
  n
)

;; Dua nhan cua cac diem ve vi tri tu dong (bo trang thai TAY) roi bo tri lai.
(defun bht:lbl-reset (pids / n up)
  (setq n 0 up (mapcar 'strcase pids))
  (foreach pr (bht:tagged-pairs "TEXT" "BHT_NHAN" 2)
    (if (member (car (bht:split (car pr) "|")) up)
      (if (/= (bht:lbl-state (cdr pr)) 'AUTO)
        (progn (bht:lbl-set-state (cdr pr) "TU_DONG") (setq n (1+ n))))))
  (list n (bht:lbl-sync-scope up))
)

;; Survey id tu tap chon: POINT BHT_PT va nhan BHT_NHAN.
(defun bht:ss-label-pids (ss / i out x e)
  (setq i 0 out nil)
  (if ss
    (while (< i (sslength ss))
      (setq e (ssname ss i))
      (cond ((setq x (bht:xget e "BHT_PT")) (setq out (bht:unique-add out (strcase (car x)))))
            ((setq x (bht:xget e "BHT_NHAN")) (setq out (bht:unique-add out (strcase (car x))))))
      (setq i (1+ i))))
  out
)

(defun bht:lbl-report (r)
  (bht:msg (strcat "BHT nhãn điểm: " (itoa (cdr (assoc 'points r))) " điểm RTK | tạo mới "
                   (itoa (cdr (assoc 'created r))) ", cập nhật " (itoa (cdr (assoc 'updated r)))
                   ", giữ nguyên " (itoa (cdr (assoc 'unchanged r))) ", xóa nhãn thừa "
                   (itoa (cdr (assoc 'deleted r))) " | bố trí lại " (itoa (cdr (assoc 'laidout r)))
                   " điểm, nhãn đã dời tay được giữ " (itoa (cdr (assoc 'manual r))) "."))
  (if (= (bht:meta "nhan_an" "0") "1")
    (bht:msg "  Nhãn đang ẨN (layer tắt). Dùng BHTANNHAN hoặc BHTNHANDIEM > H để hiện."))
  (if (= (bht:meta "nhan_uu_tien_dt" "0") "1")
    (bht:msg "  Chế độ ưu tiên hồ sơ: điểm đã thuộc hồ sơ đối tượng chỉ hiện nhãn tên."))
)

(defun bht:lbl-ask-settings (/ h off sty)
  (setq h (bht:num (bht:ask-string "Chiều cao chữ nhãn" (bht:meta "nhan_h" "0.5")))
        off (bht:num (bht:ask-string "Khoảng lệch nhãn so với điểm (đơn vị bản vẽ)" (bht:meta "nhan_offset" "0.65")))
        sty (bht:ask-string "Kiểu chữ (BHT_TCVN = VNRomancUpdate.shx, bảng mã Unicode)" (bht:default-label-style)))
  (cond
    ((not (and h (> h 0) off)) (bht:warn "BHT: giá trị không hợp lệ, giữ cài đặt cũ.") nil)
    ((and (not (member (strcase sty) '("BHT_ARIAL" "BHT_RTK" "BHT_TCVN"))) (not (tblsearch "STYLE" sty)))
     (bht:warn (strcat "BHT: không có kiểu chữ " sty " trong bản vẽ, giữ cài đặt cũ.")) nil)
    (T (bht:meta-set "nhan_h" (bht:fnum h 3))
       (bht:meta-set "nhan_offset" (bht:fnum off 3))
       (bht:meta-set "nhan_kieu_chu" sty)
       T))
)

;; Hoi pham vi: V = vung chon, D = danh sach ID/ten, T = tat ca. Tra ve 'ALL / list / nil.
(defun bht:ask-label-scope (/ v ids idx out)
  (setq v (strcase (bht:ask-string "Phạm vi sắp xếp [V=vùng chọn/D=danh sách ID hoặc tên điểm/T=tất cả]" "V")))
  (cond
    ((= v "T") 'ALL)
    ((= v "D")
     (setq ids (vl-remove "" (bht:split (bht:replace (bht:ask-string "ID hoặc tên điểm (cách nhau dấu cách/phẩy)" "") "," " ") " "))
           idx (bht:pt-all) out nil)
     (foreach s ids
       (cond ((bht:pt-find s idx) (setq out (bht:unique-add out (strcase s))))
             (T (foreach it idx (if (= (strcase (bht:pv (cdr it) 'name)) (strcase s)) (setq out (bht:unique-add out (car it))))))))
     (if (null out) (bht:warn "BHT: không tìm thấy điểm nào theo danh sách."))
     out)
    (T
     (bht:msg "Chọn vùng có điểm RTK / nhãn cần sắp xếp: ")
     (bht:ss-label-pids (ssget (list '(-4 . "<OR") '(0 . "POINT") '(0 . "TEXT") '(-4 . "OR>"))))))
)

(defun bht:lbl-layout-cmd (scope / before r after)
  (if (null scope)
    (bht:warn "BHT: không có điểm nào trong phạm vi.")
    (progn
      (setq before (bht:lbl-overlaps (if (= scope 'ALL) nil scope)))
      (setq r (bht:lbl-sync-scope scope))
      (setq after (bht:lbl-overlaps (if (= scope 'ALL) nil scope)))
      (bht:lbl-report r)
      (bht:msg (strcat "  Chồng lấn trong phạm vi - trước: " (bht:lbl-overlap-text before)))
      (bht:msg (strcat "  Chồng lấn trong phạm vi - sau:   " (bht:lbl-overlap-text after)))
      (if (> (cdr (assoc 'overlapped after)) 0)
        (bht:msg "  Khu vực dày điểm có thể vẫn còn chồng lấn: kéo nhãn bằng tay (BHT giữ vị trí tay), hoặc giảm cao chữ / đổi chế độ nhãn."))
      (list r before after)))
)

(defun bht:lbl-set-hidden (hidden)
  (bht:meta-set "nhan_an" (if hidden "1" "0"))
  (if hidden
    (progn (bht:lbl-visibility T) (bht:msg "BHT: đã ẨN nhãn điểm RTK (layer tắt, không xóa).") nil)
    (bht:lbl-sync)))

(defun c:BHTNHANDIEM (/ *error* st v r cur n)
  (setq *error* bht:on-error)
  (setq st (bht:lbl-settings)
        cur (cond ((= (cdr (assoc 'mode st)) "T") "1") ((= (cdr (assoc 'mode st)) "TM") "2") (T "3")))
  (bht:msg (strcat "Nhãn điểm RTK: chế độ " (bht:lbl-mode-name (cdr (assoc 'mode st)))
                   (if (cdr (assoc 'id st)) " + ID nội bộ" "")
                   (if (cdr (assoc 'prio st)) " | ưu tiên hồ sơ: BẬT" "")
                   " | cao chữ " (bht:meta "nhan_h" "0.5") " | lệch " (bht:meta "nhan_offset" "0.65")
                   " | kiểu chữ " (bht:default-label-style)
                   (if (cdr (assoc 'hidden st)) " | ĐANG ẨN" "")))
  (setq v (strcase (bht:ask-string "[1=Tên/2=Tên+mô tả/3=Tên+mô tả+cao độ/4=Ưu tiên hồ sơ bật-tắt/I=Bật-tắt ID nội bộ/S=Sắp xếp lại/R=Trả nhãn về tự động/A=Ẩn/H=Hiện/C=Cài đặt/X=Xóa nhãn]" cur)))
  (cond
    ((member v '("1" "2" "3"))
     (bht:meta-set "nhan_che_do" (nth (1- (atoi v)) '("T" "TM" "TMC")))
     (bht:meta-set "nhan_an" "0")
     (setq r (bht:lbl-sync)))
    ((= v "4")
     (bht:meta-set "nhan_uu_tien_dt" (if (cdr (assoc 'prio st)) "0" "1"))
     (setq r (bht:lbl-sync)))
    ((= v "I")
     (bht:meta-set "nhan_id" (if (cdr (assoc 'id st)) "0" "1"))
     (setq r (bht:lbl-sync)))
    ((= v "S") (bht:lbl-layout-cmd (bht:ask-label-scope)))
    ((= v "R") (c:BHTNHANTUDONG))
    ((= v "A") (bht:lbl-set-hidden T))
    ((= v "H") (setq r (bht:lbl-set-hidden nil)))
    ((= v "C")
     (if (bht:lbl-ask-settings) (setq r (bht:lbl-sync))))
    ((= v "X")
     (if (= (strcase (bht:ask-string "Xóa MỌI nhãn điểm BHT (điểm RTK và dữ liệu giữ nguyên)? [C/K]" "K")) "C")
       (progn (setq n (bht:lbl-remove-all))
              (bht:msg (strcat "BHT: đã xóa " (itoa n) " nhãn điểm."))))))
  (if r
    (progn (bht:lbl-report r)
           (bht:msg (strcat "  Chồng lấn hiện tại (toàn bản vẽ): " (bht:lbl-overlap-text (bht:lbl-overlaps nil))))))
  (bht:log-flush)
  (princ)
)
(defun c:BHTLABEL () (c:BHTNHANDIEM))

;; Sap xep lai nhan theo pham vi (khong di chuyen POINT).
(defun c:BHTSAPNHAN (/ *error*)
  (setq *error* bht:on-error)
  (bht:msg "Sắp xếp nhãn điểm RTK tránh chồng lấn (POINT không bao giờ bị di chuyển; nhãn đã dời tay được giữ).")
  (bht:lbl-layout-cmd (bht:ask-label-scope))
  (bht:log-flush)
  (princ)
)

;; Tra nhan da doi tay ve vi tri tu dong (chon diem hoac nhan).
(defun c:BHTNHANTUDONG (/ *error* pids r)
  (setq *error* bht:on-error)
  (bht:msg "Chọn điểm RTK / nhãn cần trả về vị trí tự động: ")
  (setq pids (bht:ss-label-pids (ssget (list '(-4 . "<OR") '(0 . "POINT") '(0 . "TEXT") '(-4 . "OR>")))))
  (if pids
    (progn
      (setq r (bht:lbl-reset pids))
      (bht:msg (strcat "BHT: bỏ trạng thái dời tay cho " (itoa (car r)) " nhãn của " (itoa (length pids)) " điểm."))
      (bht:lbl-report (cadr r)))
    (bht:msg "BHT: không chọn được điểm / nhãn BHT nào."))
  (bht:log-flush)
  (princ)
)

;; Bat/tat hien nhan diem (khong xoa gi).
(defun c:BHTANNHAN (/ *error* r)
  (setq *error* bht:on-error)
  (setq r (bht:lbl-set-hidden (/= (bht:meta "nhan_an" "0") "1")))
  (if r (bht:lbl-report r))
  (bht:log-flush)
  (princ)
)

;; Dat POINT thanh dau X dung tam, kich thuoc tuyet doi; tuy chon sap lai nhan.
(defun c:BHTKIEUDIEM (/ *error* s v r)
  (setq *error* bht:on-error
        s (bht:num (bht:ask-string "Kích thước dấu X theo đơn vị bản vẽ" (bht:meta "pt_size" "1.0"))))
  (if (and s (> s 0.0))
    (progn
      (setq v (strcase (bht:ask-string "Sắp lại toàn bộ nhãn để tránh dấu X và điểm liền kề? [C/K]" "C"))
            r (bht:point-style-apply s (= v "C")))
      (bht:msg (strcat "BHT: POINT = dấu X, kích thước " (bht:fnum s 3) " unit; tâm X giữ đúng tọa độ điểm."
                       (if (= v "C") " Đã sắp lại nhãn tự động." ""))))
    (bht:warn "BHT: kích thước phải lớn hơn 0."))
  (bht:log-flush)
  (princ)
)

