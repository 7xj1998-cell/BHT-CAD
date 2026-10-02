;;; ----------------------------------------------------------------------
;;; Ky hieu (lop the hien) - INSERT layer BHT_KYHIEU + TEXT layer BHT_NHAN
;;;  XData "BHT_KH":
;;;   0.3.2: (object_id) tren ca INSERT va TEXT.
;;;   0.3.3 INSERT: (object_id trang_thai x y goc ty_le)
;;;         TEXT  : (object_id "NHAN" trang_thai x y)
;;;   trang_thai TU_DONG: BHT dat (x y goc ty_le = gia tri BHT dat lan cuoi);
;;;   TAY: nguoi dung da doi vi tri / goc / ty le -> GIU NGUYEN khi cap nhat.
;;;  Vi tri tu dong = trung binh toa do RTK cua doi tuong (khong dich trinh bay).
;;;  Cap nhat theo object_id: tao thieu, sua thay doi, chi xoa ky hieu cua ho so
;;;  da xoa. Khong dung vao thuc the khong mang XData BHT_KH. Ho so (XRecord)
;;;  la nguon du lieu; ky hieu chi la lop the hien.
;;; ----------------------------------------------------------------------

(setq *bht-bb-catalog*
  '(("W.207"  "BHT_KH_BB_W207_V044"       "Giao nhau với đường không ưu tiên")
    ("W.209"  "BHT_KH_BB_W209_V044"       "Giao nhau có tín hiệu đèn")
    ("W.239a" "BHT_KH_BB_W239A_V044"      "Đường cáp điện phía trên + S.509a")
    ("W.245a" "BHT_KH_BB_W245A_V044"      "Đi chậm")
    ("W.201"  "BHT_KH_BB_W201_V044"       "Chỗ ngoặt nguy hiểm")
    ("W.225"  "BHT_KH_BB_W225_V044"       "Trẻ em")
    ("R.412"  "BHT_KH_BB_R412_V044"       "Làn dành riêng cho từng loại xe")
    ("I.414"  "BHT_KH_BB_I414_V044"       "Chỉ hướng đường")
    ("I.423a" "BHT_KH_BB_I423A_V044"      "Vị trí người đi bộ sang ngang")
    ("I.428a" "BHT_KH_BB_I428A_V044"      "Cửa hàng xăng dầu")
    ("I.434a" "BHT_KH_BB_I434A_V044"      "Bến xe buýt")
    ("P.115"  "BHT_KH_BB_P115_V044"       "Hạn chế trọng tải toàn bộ xe")
    ("P.119"  "BHT_KH_BB_P119_V044"       "Hạn chế chiều dài xe")
    ("P.124a" "BHT_KH_BB_P124A_V044"      "Cấm quay đầu xe")
    ("P.125"  "BHT_KH_BB_P125_V044"       "Cấm vượt")
    ("P.127"  "BHT_KH_BB_P127_V044"       "Tốc độ tối đa cho phép")))

(defun bht:bb-code-key (s / u)
  (setq u (strcase (bht:trim s)))
  (foreach ch '(" " "." "-" "_" "/" "+" "," ";" ":")
    (setq u (bht:replace u ch "")))
  u
)

;; Chon block theo ma hieu ho so. Bien the a,b,c... dung chung hinh tong quat
;; cua cung ma; gia tri so 20/40 cua P.127 duoc giu rieng neu co trong ma.
(defun bht:tdt-block-name (code / s out i ch a under)
  (setq s (strcase (bht:trim code)) out "BHT_TDT_V51_" i 1 under nil)
  (while (<= i (strlen s))
    (setq ch (substr s i 1) a (ascii ch))
    (if (or (and (>= a 48) (<= a 57)) (and (>= a 65) (<= a 90)))
      (progn (setq out (strcat out ch)) (setq under nil))
      (if (not under) (progn (setq out (strcat out "_")) (setq under T))))
    (setq i (1+ i)))
  (vl-string-right-trim "_" out)
)

;; BHTTDTBLOCK do BHT.Bridge dang ky. Ham clone dung block cua thu vien TDT
;; tren may, boc lai voi cot cao 0.6 va mat bien cao 1.8 theo extents.
;; Neu may khong co TDT/Bridge hoac ma khong co hinh, BHT dung block noi bo ben duoi.
;; 0.4.6-fix2: khi Bridge chua dang ky BHTTDTBLOCK, (vl-catch-all-apply 'BHTTDTBLOCK ...)
;; nem "bad function: BHTTDTBLOCK" ra ngoai (vl-catch-all-apply khong bat duoc) -> kiem tra truoc.
(defun bht:tdt-import-block (code description / want r)
  (if (bht:fn-defined-p 'BHTSIGNVALIDATE)
    (progn
      (setq r (BHTSIGNVALIDATE code))
      (if (/= r "") (vl-exit-with-error r))))
  (setq want (bht:tdt-block-name code))
  (cond
    ((and (= description "") (not (bht:fn-defined-p 'BHTTDTBLOCK)) (tblsearch "BLOCK" want)) want)
    ((= (bht:trim code) "") nil)
    ((not (bht:fn-defined-p 'BHTTDTBLOCK)) nil)
    (T
     (setq r (vl-catch-all-apply 'BHTTDTBLOCK (list code description)))
     (if (and (not (vl-catch-all-error-p r)) (listp r) (= (strcase (bht:str (car r))) "OK")
              (cadr r) (tblsearch "BLOCK" (cadr r)))
       (cadr r)
       nil)))
)

;; Native fallback accepts a family code or one letter variant, never an arbitrary substring.
(defun bht:bb-family-p (key base / suffix)
  (and (bht:starts key base)
       (or (= key base)
           (and (= (strlen key) (1+ (strlen base)))
                (setq suffix (ascii (substr key (1+ (strlen base)))))
                (<= 65 suffix) (<= suffix 90)))))

(defun bht:bb-block-for (code / k tdt speed name)
  (setq k (bht:bb-code-key code) tdt (bht:tdt-import-block code ""))
  ;; Exact legacy combined plate, not an arbitrary substring match.
  (if (= k "W239AS509A") (setq k "W239A"))
  (cond
    (tdt tdt)
    ((or (vl-string-search "@" code) (member (strcase code) '("S.501" "S.502" "S.509A"))) (bht:bb-metre-native code))
    ((bht:bb-family-p k "W207") "BHT_KH_BB_W207_V044")
    ((bht:bb-family-p k "W209") "BHT_KH_BB_W209_V044")
    ((bht:bb-family-p k "W239") "BHT_KH_BB_W239A_V044")
    ((bht:bb-family-p k "W245") "BHT_KH_BB_W245A_V044")
    ((bht:bb-family-p k "W201") "BHT_KH_BB_W201_V044")
    ((bht:bb-family-p k "W225") "BHT_KH_BB_W225_V044")
    ((bht:bb-family-p k "R412") "BHT_KH_BB_R412_V044")
    ((bht:bb-family-p k "I414") "BHT_KH_BB_I414_V044")
    ((bht:bb-family-p k "I423") "BHT_KH_BB_I423A_V044")
    ((bht:bb-family-p k "I428") "BHT_KH_BB_I428A_V044")
    ((bht:bb-family-p k "I434") "BHT_KH_BB_I434A_V044")
    ((bht:bb-family-p k "P115") "BHT_KH_BB_P115_V044")
    ((bht:bb-family-p k "P119") "BHT_KH_BB_P119_V044")
    ((bht:bb-family-p k "P124") "BHT_KH_BB_P124A_V044")
    ((bht:bb-family-p k "P125") "BHT_KH_BB_P125_V044")
    ((and (bht:starts k "P127") (setq speed (bht:num (substr k 5))) (= speed (fix speed)) (<= 5 speed) (<= speed 130))
      (cond ((= speed 20) "BHT_KH_BB_P127_20_V044") ((= speed 40) "BHT_KH_BB_P127_40_V044")
        (T (setq name (strcat "BHT_KH_BB_P127_" (itoa (fix speed)) "_NATIVE"))
           (bht:block name (bht:bb-speed-g (itoa (fix speed)))) name)))
    ((= k "P127") "BHT_KH_BB_P127_V044")
    (T "BHT_KH_BIEN_BAO_V044"))
)

(defun bht:bb-metre-native (code / dot base value name parts e d text x)
  (setq dot (vl-string-search "@" code) base (strcase (if dot (substr code 1 dot) code)))
  (if (null dot) (setq code (strcat code "@" (cond ((= base "S.501") "800") ((= base "S.502") "200") (T "5")))))
  (if (not (bht:fn-defined-p 'BHTMETRETEXT)) (vl-exit-with-error "Nạp BHT.Bridge.dll để nhập giá trị mét."))
  (setq value (BHTMETRETEXT code "0"))
  (if (= value "0") (vl-exit-with-error "Giá trị mét không hợp lệ."))
  (setq name (strcat "BHT_NATIVE_METRE_" (bht:tdt-block-name code)))
  (cond
    ((tblsearch "BLOCK" name) name)
    ((= base "P.119")
      (setq e (tblobjname "BLOCK" "BHT_KH_BB_P119_V044") parts nil)
      (while (and (setq e (entnext e)) (/= (cdr (assoc 0 (setq d (entget e)))) "ENDBLK"))
        (setq d (vl-remove-if '(lambda (g) (member (car g) '(-1 5 330 360))) d))
        (if (= (cdr (assoc 0 d)) "TEXT") (setq d (bht:dxf-put d 1 (BHTMETRETEXT code (cdr (assoc 1 d))))))
        (setq parts (append parts (list d))))
      (bht:block name parts) name)
    ((member base '("S.501" "S.502" "S.509A"))
      (setq parts (append (bht:bb-post-g)
        (list (bht:rect-fill-g -1.3 0.62 1.3 2.42 (if (= base "S.509A") 5 7)))
        (bht:poly-color-g '((-1.3 0.62 0.0) (1.3 0.62 0.0) (1.3 2.42 0.0) (-1.3 2.42 0.0)) (if (= base "S.509A") 7 250))))
      (if (= base "S.509A")
        (setq parts (append parts (list (bht:text-center-color-g "CHIỀU CAO" '(0.0 2.08 0.0) 0.28 7)
          (bht:text-center-color-g "AN TOÀN" '(0.0 1.61 0.0) 0.28 7)
          (bht:text-center-color-g (strcat value " m") '(0.0 1.08 0.0) 0.38 7))))
        (progn
          (setq parts (append parts (list (bht:text-center-color-g (strcat value " m") '(0.0 1.52 0.0) 0.4 250))))
          (if (= base "S.501")
            (foreach x '(-1.03 1.03)
              (setq parts (append parts (list (bht:rect-fill-g (- x 0.055) 0.86 (+ x 0.055) 1.97 250)
                (bht:solid-g (list x 2.20 0.0) (list (- x 0.17) 1.95 0.0) (list (+ x 0.17) 1.95 0.0) (list (+ x 0.17) 1.95 0.0) 250))))))))
      (bht:block name parts) name)
    (T (vl-exit-with-error "Biển mét này cần block TDT hoặc block tùy chỉnh; không dùng số mặc định thay thế."))))

(defun bht:bb-post-g ()
  (list (bht:line-color-g '(0.0 0.0 0.0) '(0.0 0.62 0.0) 7)
        (bht:circle-g '(0.0 0.0 0.0) 0.07))
)

(defun bht:bb-triangle-base (/ ot ol orr it il ir)
  (setq ot '(0.0 1.86 0.0) ol '(-0.75 0.56 0.0) orr '(0.75 0.56 0.0)
        it '(0.0 1.68 0.0) il '(-0.58 0.67 0.0) ir '(0.58 0.67 0.0))
  (append (bht:bb-post-g)
          (list (bht:solid-g ot ol orr orr 1)
                (bht:solid-g it il ir ir 2))
          (bht:poly-color-g (list ot ol orr) 1)
          (bht:poly-color-g (list it il ir) 1))
)

(defun bht:bb-circle-base (/ c)
  (setq c '(0.0 1.20 0.0))
  (append (bht:bb-post-g)
          (bht:disc-g c 0.63 24 1)
          (bht:disc-g c 0.49 24 7)
          (list (bht:circle-g c 0.63) (bht:circle-g c 0.49)))
)

(defun bht:bb-blue-base (/ out)
  (append (bht:bb-post-g)
          (list (bht:rect-fill-g -0.68 0.56 0.68 1.84 5)
                (bht:rect-fill-g -0.51 0.72 0.51 1.68 7))
          (bht:poly-color-g '((-0.68 0.56 0.0) (0.68 0.56 0.0)
                              (0.68 1.84 0.0) (-0.68 1.84 0.0)) 5))
)

(defun bht:bb-blue-wide-base ()
  (append (bht:bb-post-g)
          (list (bht:rect-fill-g -1.08 0.62 1.08 1.72 5))
          (bht:poly-color-g '((-1.08 0.62 0.0) (1.08 0.62 0.0)
                              (1.08 1.72 0.0) (-1.08 1.72 0.0)) 7))
)

(defun bht:bb-speed-g (value)
  (append (bht:bb-circle-base)
          (list (bht:text-center-color-g value '(0.0 1.20 0.0) 0.30 250)))
)

(defun bht:bb-catalog-report (/ item)
  (bht:msg "BHT - Danh mục block biển báo chuẩn theo ảnh KMZ DT830:")
  (foreach item *bht-bb-catalog*
    (bht:msg (strcat "  " (car item) " - " (caddr item))))
  (bht:msg "Nhập mã này vào trường Mã của hồ sơ BIEN_BAO, rồi chạy BHTKYHIEU.")
  (bht:msg "Mã chưa nhận diện dùng block biển báo tổng quát; BHTBLOCK vẫn cho nạp DWG tùy chọn.")
  (princ)
)

;;; 5.0: tim bien khi go - khong dau (ca đ -> d), khong phan biet hoa, moi tu
;;; cua truy van phai co trong MA hoac TEN. Ma so khop ca dang bo dau cham
;;; ("w245a" = "W.245a"). Uu tien danh muc bien TDT day du (BHTSIGNSEARCH cua
;;; BHT.Bridge); khong co Bridge -> danh muc noi bo *bht-bb-catalog*.
;; Vietnamese accent folding shared by sign search and condition input.
(defun bht:fold-vi (s / p)
  (foreach p
    '(("À" "A") ("Á" "A") ("Ả" "A") ("Ã" "A") ("Ạ" "A")
      ("Ă" "A") ("Ằ" "A") ("Ắ" "A") ("Ẳ" "A") ("Ẵ" "A") ("Ặ" "A")
      ("Â" "A") ("Ầ" "A") ("Ấ" "A") ("Ẩ" "A") ("Ẫ" "A") ("Ậ" "A")
      ("È" "E") ("É" "E") ("Ẻ" "E") ("Ẽ" "E") ("Ẹ" "E")
      ("Ê" "E") ("Ề" "E") ("Ế" "E") ("Ể" "E") ("Ễ" "E") ("Ệ" "E")
      ("Ì" "I") ("Í" "I") ("Ỉ" "I") ("Ĩ" "I") ("Ị" "I")
      ("Ò" "O") ("Ó" "O") ("Ỏ" "O") ("Õ" "O") ("Ọ" "O")
      ("Ô" "O") ("Ồ" "O") ("Ố" "O") ("Ổ" "O") ("Ỗ" "O") ("Ộ" "O")
      ("Ơ" "O") ("Ờ" "O") ("Ớ" "O") ("Ở" "O") ("Ỡ" "O") ("Ợ" "O")
      ("Ù" "U") ("Ú" "U") ("Ủ" "U") ("Ũ" "U") ("Ụ" "U")
      ("Ư" "U") ("Ừ" "U") ("Ứ" "U") ("Ử" "U") ("Ữ" "U") ("Ự" "U")
      ("Ỳ" "Y") ("Ý" "Y") ("Ỷ" "Y") ("Ỹ" "Y") ("Ỵ" "Y")
      ("Đ" "D")
      ("à" "a") ("á" "a") ("ả" "a") ("ã" "a") ("ạ" "a")
      ("ă" "a") ("ằ" "a") ("ắ" "a") ("ẳ" "a") ("ẵ" "a") ("ặ" "a")
      ("â" "a") ("ầ" "a") ("ấ" "a") ("ẩ" "a") ("ẫ" "a") ("ậ" "a")
      ("è" "e") ("é" "e") ("ẻ" "e") ("ẽ" "e") ("ẹ" "e")
      ("ê" "e") ("ề" "e") ("ế" "e") ("ể" "e") ("ễ" "e") ("ệ" "e")
      ("ì" "i") ("í" "i") ("ỉ" "i") ("ĩ" "i") ("ị" "i")
      ("ò" "o") ("ó" "o") ("ỏ" "o") ("õ" "o") ("ọ" "o")
      ("ô" "o") ("ồ" "o") ("ố" "o") ("ổ" "o") ("ỗ" "o") ("ộ" "o")
      ("ơ" "o") ("ờ" "o") ("ớ" "o") ("ở" "o") ("ỡ" "o") ("ợ" "o")
      ("ù" "u") ("ú" "u") ("ủ" "u") ("ũ" "u") ("ụ" "u")
      ("ư" "u") ("ừ" "u") ("ứ" "u") ("ử" "u") ("ữ" "u") ("ự" "u")
      ("ỳ" "y") ("ý" "y") ("ỷ" "y") ("ỹ" "y") ("ỵ" "y")
      ("đ" "d")
      ("—" "-") ("–" "-") ("•" "*"))
    (setq s (bht:replace s (car p) (cadr p))))
  s
)

(defun bht:search-fold (s) (strcase (bht:fold-vi (bht:str s)) T))

(defun bht:sign-match-p (q code name / hay key ok k)
  (setq hay (strcat (bht:search-fold code) " " (bht:search-fold name))
        key (strcase (bht:bb-code-key (bht:fold-vi (bht:str code))) T) ok T)
  (foreach w (vl-remove "" (bht:split (bht:search-fold q) " "))
    (setq k (strcase (bht:bb-code-key w) T))
    (if (not (or (vl-string-search w hay) (and (/= k "") (vl-string-search k key))))
      (setq ok nil)))
  ok
)

;; Tra ve danh sach (ma ten), toi da maxn muc.
(defun bht:sign-search (q maxn / r out)
  (if (and (bht:bridge-load 'BHTSIGNSEARCH)
           (setq r (vl-catch-all-apply 'BHTSIGNSEARCH (list (bht:str q) maxn)))
           (not (vl-catch-all-error-p r)) (listp r) (= (car r) "OK"))
    (mapcar '(lambda (x / p) (setq p (vl-string-search "|" x))
               (if p (list (substr x 1 p) (substr x (+ p 2))) (list x "")))
            (cdr r))
    (progn
      (foreach item *bht-bb-catalog*
        (if (and (< (length out) maxn) (bht:sign-match-p q (car item) (caddr item)))
          (setq out (append out (list (list (car item) (caddr item)))))))
      out))
)

(defun bht:sign-search-report (q / hits)
  (setq hits (bht:sign-search q 30))
  (if hits
    (progn
      (bht:msg (strcat "BHT - biển khớp \"" q "\" (" (itoa (length hits)) " kết quả, tối đa 30):"))
      (foreach h hits (bht:msg (strcat "  " (car h) (if (/= (cadr h) "") (strcat " - " (cadr h)) " - (chưa có tên trong thư viện TDT)")))))
    (bht:msg (strcat "BHT: không có biển nào khớp \"" q "\".")))
  hits
)

(defun c:BHTBBDANHMUC (/ *error*)
  (setq *error* bht:on-error)
  (bht:symbol-blocks)
  (bht:bb-catalog-report)
)

(defun bht:symbol-blocks ()
  ;; Block tong quat: diem chen o chan cot; dau hoi cho biet chua co ma QCVN.
  (bht:block "BHT_KH_BIEN_BAO_V044"
    (append (bht:bb-post-g)
            (list (bht:rect-fill-g -0.58 0.66 0.58 1.70 8)
                  (bht:text-center-color-g "?" '(0.0 1.18 0.0) 0.45 7))))

  ;; W.207 - nhom pho bien nhat trong KMZ: truc duong chinh va nhanh ben.
  (bht:block "BHT_KH_BB_W207_V044"
    (append (bht:bb-triangle-base)
            (list (bht:rect-fill-g -0.07 0.82 0.07 1.48 250)
                  (bht:rect-fill-g 0.04 1.13 0.42 1.27 250))))
  ;; W.209 - den tin hieu theo thu tu do, vang, xanh.
  (bht:block "BHT_KH_BB_W209_V044"
    (append (bht:bb-triangle-base)
            (list (bht:rect-fill-g -0.18 0.83 0.18 1.52 250))
            (bht:disc-g '(0.0 1.39 0.0) 0.09 12 1)
            (bht:disc-g '(0.0 1.18 0.0) 0.09 12 2)
            (bht:disc-g '(0.0 0.97 0.0) 0.09 12 3)))
  ;; W.239a + S.509a: bo canh bao cap dien / chieu cao 4,75 m gap nhieu tren DT830.
  (bht:block "BHT_KH_BB_W239A_V044"
    (append (bht:bb-triangle-base)
            (list (bht:solid-g '(-0.08 1.53 0.0) '(0.18 1.53 0.0)
                                '(-0.02 1.17 0.0) '(0.08 1.20 0.0) 250)
                  (bht:solid-g '(-0.02 1.23 0.0) '(0.16 1.23 0.0)
                                '(-0.20 0.84 0.0) '(-0.07 1.16 0.0) 250)
                  (bht:rect-fill-g -0.58 0.15 0.58 0.50 5)
                  (bht:text-center-color-g "4,75 m" '(0.0 0.33 0.0) 0.16 7))))
  (bht:block "BHT_KH_BB_W245A_V044"
    (append (bht:bb-triangle-base)
            (list (bht:text-center-color-g "ĐI" '(0.0 1.34 0.0) 0.17 250)
                  (bht:text-center-color-g "CHẬM" '(0.0 1.08 0.0) 0.13 250))))
  (bht:block "BHT_KH_BB_W201_V044"
    (append (bht:bb-triangle-base)
            (list (bht:line-color-g '(-0.28 0.88 0.0) '(-0.05 1.08 0.0) 250)
                  (bht:line-color-g '(-0.05 1.08 0.0) '(0.08 1.36 0.0) 250)
                  (bht:line-color-g '(0.08 1.36 0.0) '(0.31 1.49 0.0) 250))))
  (bht:block "BHT_KH_BB_W225_V044"
    (append (bht:bb-triangle-base)
            (bht:disc-g '(-0.12 1.37 0.0) 0.07 10 250)
            (bht:disc-g '(0.19 1.28 0.0) 0.06 10 250)
            (list (bht:line-color-g '(-0.12 1.30 0.0) '(-0.02 1.02 0.0) 250)
                  (bht:line-color-g '(0.19 1.22 0.0) '(0.10 0.98 0.0) 250)
                  (bht:line-color-g '(-0.08 1.18 0.0) '(0.18 1.12 0.0) 250))))

  ;; R.412 - so do phan lan tong quat, dung cho cac bang nhom xe trong KMZ.
  (bht:block "BHT_KH_BB_R412_V044"
    (append (bht:bb-blue-wide-base)
            (list (bht:line-color-g '(0.0 0.72 0.0) '(0.0 1.62 0.0) 7)
                  (bht:line-color-g '(-0.48 0.82 0.0) '(-0.48 1.52 0.0) 7)
                  (bht:line-color-g '(0.48 0.82 0.0) '(0.48 1.52 0.0) 7)
                  (bht:text-center-color-g "Ô TÔ" '(-0.52 1.16 0.0) 0.17 7)
                  (bht:text-center-color-g "XE MÁY" '(0.52 1.16 0.0) 0.15 7))))
  (bht:block "BHT_KH_BB_I414_V044"
    (append (bht:bb-blue-wide-base)
            (list (bht:line-color-g '(-0.75 1.17 0.0) '(0.62 1.17 0.0) 7)
                  (bht:line-color-g '(0.62 1.17 0.0) '(0.34 1.43 0.0) 7)
                  (bht:line-color-g '(0.62 1.17 0.0) '(0.34 0.91 0.0) 7)
                  (bht:text-center-color-g "HƯỚNG" '(-0.30 1.48 0.0) 0.14 7))))
  (bht:block "BHT_KH_BB_I423A_V044"
    (append (bht:bb-blue-base)
            (list (bht:solid-g '(0.0 1.58 0.0) '(-0.40 0.80 0.0)
                                '(0.40 0.80 0.0) '(0.40 0.80 0.0) 7))
            (bht:disc-g '(0.0 1.32 0.0) 0.06 10 250)
            (list (bht:line-color-g '(0.0 1.25 0.0) '(-0.08 1.06 0.0) 250)
                  (bht:line-color-g '(-0.08 1.06 0.0) '(-0.24 0.89 0.0) 250)
                  (bht:line-color-g '(-0.08 1.06 0.0) '(0.14 0.91 0.0) 250))))
  (bht:block "BHT_KH_BB_I428A_V044"
    (append (bht:bb-blue-base)
            (list (bht:rect-fill-g -0.20 0.88 0.12 1.48 250)
                  (bht:rect-fill-g -0.14 1.31 0.06 1.42 7)
                  (bht:line-color-g '(0.12 1.39 0.0) '(0.28 1.28 0.0) 250)
                  (bht:line-color-g '(0.28 1.28 0.0) '(0.28 0.98 0.0) 250))))
  (bht:block "BHT_KH_BB_I434A_V044"
    (append (bht:bb-blue-base)
            (list (bht:rect-fill-g -0.35 0.97 0.35 1.43 250)
                  (bht:rect-fill-g -0.27 1.23 0.27 1.36 7))
            (bht:disc-g '(-0.22 0.94 0.0) 0.07 10 250)
            (bht:disc-g '(0.22 0.94 0.0) 0.07 10 250)))

  ;; Nhom bien cam ghi tri so / hinh tu anh KMZ.
  (bht:block "BHT_KH_BB_P115_V044"
    (append (bht:bb-circle-base)
            (list (bht:text-center-color-g "2,5 t" '(0.0 1.20 0.0) 0.25 250))))
  (bht:block "BHT_KH_BB_P119_V044"
    (append (bht:bb-circle-base)
            (list (bht:text-center-color-g "8 m" '(0.0 1.20 0.0) 0.25 250)
                  (bht:line-color-g '(-0.34 0.94 0.0) '(0.34 0.94 0.0) 250))))
  (bht:block "BHT_KH_BB_P124A_V044"
    (append (bht:bb-circle-base)
            (list (bht:text-center-color-g "U" '(0.0 1.20 0.0) 0.42 250)
                  (bht:line-color-g '(-0.40 1.60 0.0) '(0.40 0.80 0.0) 1))))
  (bht:block "BHT_KH_BB_P125_V044"
    (append (bht:bb-circle-base)
            (list (bht:rect-fill-g -0.36 1.08 -0.04 1.30 250)
                  (bht:rect-fill-g 0.04 1.08 0.36 1.30 1))
            (bht:disc-g '(-0.28 1.05 0.0) 0.06 10 250)
            (bht:disc-g '(-0.10 1.05 0.0) 0.06 10 250)
            (bht:disc-g '(0.10 1.05 0.0) 0.06 10 1)
            (bht:disc-g '(0.28 1.05 0.0) 0.06 10 1)))
  (bht:block "BHT_KH_BB_P127_V044" (bht:bb-speed-g "MAX"))
  (bht:block "BHT_KH_BB_P127_20_V044" (bht:bb-speed-g "20"))
  (bht:block "BHT_KH_BB_P127_40_V044" (bht:bb-speed-g "40"))

  ;; Coc tieu: diem chen tai chan vuong trang (0,0); dau do ve phia -X.

  (bht:block "BHT_KH_COC_TIEU"
    (list
      (bht:solid-g '(-1.82 -0.22 0.0) '(-1.52 -0.22 0.0) '(-1.82 0.22 0.0) '(-1.52 0.22 0.0) 1)
      (bht:line-color-g '(-1.82 -0.22 0.0) '(-0.10 -0.22 0.0) 7)
      (bht:line-color-g '(-0.10 -0.22 0.0) '(-0.10 0.22 0.0) 7)
      (bht:line-color-g '(-0.10 0.22 0.0) '(-1.82 0.22 0.0) 7)
      (bht:line-color-g '(-1.82 0.22 0.0) '(-1.82 -0.22 0.0) 7)
      (bht:line-color-g '(-0.27 -0.34 0.0) '(0.26 -0.34 0.0) 3)
      (bht:line-color-g '(0.26 -0.34 0.0) '(0.26 0.34 0.0) 3)
      (bht:line-color-g '(0.26 0.34 0.0) '(-0.27 0.34 0.0) 3)
      (bht:line-color-g '(-0.27 0.34 0.0) '(-0.27 -0.34 0.0) 3)
      (bht:solid-g '(-0.12 -0.18 0.0) '(0.14 -0.18 0.0) '(-0.12 0.18 0.0) '(0.14 0.18 0.0) 7)))
  ;; 0.4.3: cot Km theo mau: nua tron do, than bang trang, chu KM va nep trang.
  ;; Diem chen = tam mat phang phia nua tron (0,0).
  (bht:block "BHT_KH_COT_KM_V043"
    (list
      (bht:solid-g '(0.0 0.0 0.0) '(0.0 0.75 0.0) '(-0.287 0.693 0.0) '(-0.287 0.693 0.0) 1)
      (bht:solid-g '(0.0 0.0 0.0) '(-0.287 0.693 0.0) '(-0.530 0.530 0.0) '(-0.530 0.530 0.0) 1)
      (bht:solid-g '(0.0 0.0 0.0) '(-0.530 0.530 0.0) '(-0.693 0.287 0.0) '(-0.693 0.287 0.0) 1)
      (bht:solid-g '(0.0 0.0 0.0) '(-0.693 0.287 0.0) '(-0.750 0.0 0.0) '(-0.750 0.0 0.0) 1)
      (bht:solid-g '(0.0 0.0 0.0) '(-0.750 0.0 0.0) '(-0.693 -0.287 0.0) '(-0.693 -0.287 0.0) 1)
      (bht:solid-g '(0.0 0.0 0.0) '(-0.693 -0.287 0.0) '(-0.530 -0.530 0.0) '(-0.530 -0.530 0.0) 1)
      (bht:solid-g '(0.0 0.0 0.0) '(-0.530 -0.530 0.0) '(-0.287 -0.693 0.0) '(-0.287 -0.693 0.0) 1)
      (bht:solid-g '(0.0 0.0 0.0) '(-0.287 -0.693 0.0) '(0.0 -0.75 0.0) '(0.0 -0.75 0.0) 1)
      (bht:line-color-g '(0.0 -0.75 0.0) '(1.75 -0.75 0.0) 7)
      (bht:line-color-g '(1.75 -0.75 0.0) '(1.75 0.75 0.0) 7)
      (bht:line-color-g '(1.75 0.75 0.0) '(0.0 0.75 0.0) 7)
      (bht:line-color-g '(0.0 0.75 0.0) '(0.0 -0.75 0.0) 7)
      (bht:solid-g '(1.62 -0.78 0.0) '(1.88 -0.78 0.0) '(1.62 0.78 0.0) '(1.88 0.78 0.0) 7)
      (bht:text-color-g "KM" '(0.35 -0.28 0.0) 0.58 7)))
  (bht:block "BHT_KH_BANG_CHI_DAN" (bht:poly-g '((-1.5 -0.7 0.0) (1.5 -0.7 0.0) (1.5 0.7 0.0) (-1.5 0.7 0.0))))
  (bht:block "BHT_KH_BANG_QC" (append (bht:poly-g '((-1.5 -0.7 0.0) (1.5 -0.7 0.0) (1.5 0.7 0.0) (-1.5 0.7 0.0)))
                                      (list (bht:line-g '(-1.5 -0.7 0.0) '(1.5 0.7 0.0)))))
  (bht:block "BHT_KH_DEN" (list (bht:circle-g '(0.0 0.0 0.0) 0.8) (bht:line-g '(-0.8 0.0 0.0) '(0.8 0.0 0.0))
                                (bht:line-g '(0.0 -0.8 0.0) '(0.0 0.8 0.0))))
  (bht:block "BHT_KH_CONG_TRINH" (bht:poly-g '((0.0 1.0 0.0) (1.0 0.0 0.0) (0.0 -1.0 0.0) (-1.0 0.0 0.0))))
  (bht:block "BHT_KH_KHAC" (bht:poly-g '((0.0 1.0 0.0) (1.0 0.0 0.0) (0.0 -1.0 0.0) (-1.0 0.0 0.0))))
  (bht:block "BHT_KH_CHUA_XAC_DINH" (list (bht:circle-g '(0.0 0.0 0.0) 0.6)
                                          (bht:line-g '(-0.6 -0.6 0.0) '(0.6 0.6 0.0))))
)

;; Xoa ky hieu (INSERT + TEXT mang BHT_KH) cua 1 ho so; oid nil = xoa MOI ky hieu BHT.
(defun bht:symbol-delete (oid / ss i ent x n)
  (setq ss (ssget "_X" (list '(-3 ("BHT_KH")))) i 0 n 0)
  (if ss
    (while (< i (sslength ss))
      (setq ent (ssname ss i) x (bht:xget ent "BHT_KH"))
      (if (or (null oid) (and x (= (strcase (car x)) (strcase oid))))
        (progn (entdel ent) (setq n (1+ n))))
      (setq i (1+ i))))
  n
)

(defun bht:symbol-exists (oid)
  (assoc (strcase oid) (bht:tagged-pairs "INSERT" "BHT_KH" 1))
)

(defun bht:kh-scale (/ s) (setq s (bht:num (bht:meta "kh_scale" "1"))) (if (and s (> s 0)) s 1.0))
(defun bht:kh-h (/ s)
  (setq s (bht:num (bht:meta "kh_h" "0.35")))
  (if (and s (> s 0) (not (equal s 1.5 1e-8))) s 0.35))
(defun bht:kh-label-height (rec) (* 0.36 (bht:kh-scale)))
(defun bht:kh-sign-label-layout (blk anchor / bounds sc rot pos center height y)
  (setq sc (cadr anchor) rot (caddr anchor) pos (car anchor)
        bounds (if (bht:fn-defined-p 'BHTSIGNBOUNDS)
                 (vl-catch-all-apply 'BHTSIGNBOUNDS (list blk)) nil))
  (if (or (vl-catch-all-error-p bounds) (not (listp bounds)) (/= (length bounds) 4))
    (setq bounds '(-0.9 -0.06 0.9 2.4)))
  (setq center (* 0.5 (+ (nth 0 bounds) (nth 2 bounds)))
        height (- (nth 3 bounds) (nth 1 bounds))
        y (- (nth 1 bounds) (* 0.08 height)))
  (list
    (list (+ (car pos) (* sc (- (* center (cos rot)) (* y (sin rot)))))
          (+ (cadr pos) (* sc (+ (* center (sin rot)) (* y (cos rot))))) (caddr pos))
    (* 0.15 (min height 2.46) sc)))
(defun bht:sign-layers (/ e d)
  (bht:layer "BHT_KYHIEU" 7)
  (if (and (setq e (tblobjname "LAYER" "BHT_KYHIEU")) (= (cdr (assoc 62 (setq d (entget e)))) 1))
    (entmod (bht:dxf-put d 62 7))))

(defun bht:kh-custom-key (group) (strcat "kh_block_" (strcase group T)))
(defun bht:kh-custom-src-key (group) (strcat "kh_block_src_" (strcase group T)))
(defun bht:kh-custom-factor-key (group) (strcat "kh_block_factor_" (strcase group T)))

(defun bht:kh-default-block (group code)
  (cond ((= group "BIEN_BAO") (bht:bb-block-for code))
        ((= group "COC_TIEU") "BHT_KH_COC_TIEU")
        ((= group "COT_KM") "BHT_KH_COT_KM_V043")
        (T (strcat "BHT_KH_" group)))
)

;; Nap 1 DWG ngoai thanh 1 dinh nghia block rieng BHT_USER_<NHOM>.
;; Chen tham chieu tam bang ActiveX roi xoa tham chieu; dinh nghia block van
;; duoc luu trong DWG hien tai. Ban ve nguon khong bi sua.
(defun bht:block-load-vla (tmp / app doc ms br name err)
  (setq app (vl-catch-all-apply 'vlax-get-acad-object nil)
        doc (if (vl-catch-all-error-p app) nil
              (vl-catch-all-apply 'vla-get-ActiveDocument (list app))))
  (if (or (null doc) (vl-catch-all-error-p doc))
    'NO_ACTIVE_DOCUMENT
    (progn
      (setq ms (vla-get-ModelSpace doc)
            br (vl-catch-all-apply 'vla-InsertBlock
                 (list ms (vlax-3d-point '(0.0 0.0 0.0)) tmp 1.0 1.0 1.0 0.0)))
      (if (vl-catch-all-error-p br)
        (progn (setq *bht-block-load-error* (vl-catch-all-error-message br)) nil)
        (progn
          (setq name (vla-get-Name br)
                *bht-block-load-factor* (abs (vla-get-XScaleFactor br))
                err (vl-catch-all-apply 'vla-Delete (list br)))
          (vlax-release-object br)
          (if (vl-catch-all-error-p err)
            (progn (setq *bht-block-load-error* (vl-catch-all-error-message err)) nil)
            name)))))
)

(defun bht:block-load-cmd (tmp group / name err e d)
  (setq name (strcat "BHT_USER_" group)
        err (vl-catch-all-apply
              '(lambda ()
                 (vl-cmdf "_.-INSERT" (strcat name "=" tmp) '(0.0 0.0 0.0) 1.0 1.0 0.0)
                 (entlast)) nil))
  (cond
    ((vl-catch-all-error-p err)
     (setq *bht-block-load-error* (vl-catch-all-error-message err)) nil)
    ((not (and (setq e err) (setq d (entget e)) (= (cdr (assoc 0 d)) "INSERT")))
     (setq *bht-block-load-error* "-INSERT không tạo được tham chiếu block tạm") nil)
    (T
     (setq name (cdr (assoc 2 d))
           *bht-block-load-factor* (abs (cdr (assoc 41 d))))
     (entdel e)
     name))
)

(defun bht:block-load-dwg (path group / tmp name)
  (setq *bht-block-load-error* "" *bht-block-load-factor* 1.0
        tmp (strcat (getvar "TEMPPREFIX") "BHT_USER_" group ".dwg"))
  (if (findfile tmp) (vl-file-delete tmp))
  (if (not (vl-file-copy path tmp))
    (progn (setq *bht-block-load-error* "không sao chép được DWG vào thư mục tạm") nil)
    (progn
      (setq name (bht:block-load-vla tmp))
      (if (= name 'NO_ACTIVE_DOCUMENT) (setq name (bht:block-load-cmd tmp group)))
      (vl-file-delete tmp)
      name))
)

(defun bht:kh-group-oids (group / out rec)
  (setq out nil)
  (foreach oid (bht:obj-ids)
    (setq rec (bht:obj-read oid))
    (if (= (bht:get rec "nhom") group) (setq out (cons oid out))))
  (reverse out)
)

(defun bht:effective-sign-code (rec / result)
  (if (bht:fn-defined-p 'BHTNATIVESIGNCODE)
    (setq result (vl-catch-all-apply 'BHTNATIVESIGNCODE (list (bht:get rec "ma_hieu") (bht:get rec "mo_ta")))))
  (if (= (type result) 'STR) result (bht:get rec "ma_hieu")))
(defun bht:kh-base-block (rec / blk custom own codes count blocks value result)
  (bht:symbol-blocks)
  (setq own (bht:get rec "custom_block")
        custom (bht:meta (bht:kh-custom-key (bht:get rec "nhom")) ""))
  (cond
    ((and (/= own "") (tblsearch "BLOCK" own)) own)
    ((and (/= custom "") (tblsearch "BLOCK" custom)) custom)
    (T
      (setq blk (if (= (bht:get rec "nhom") "BIEN_BAO")
                    (bht:tdt-import-block (bht:get rec "ma_hieu") (bht:get rec "mo_ta")) nil))
      (if (null blk) (setq blk (bht:kh-default-block (bht:get rec "nhom") (bht:effective-sign-code rec))))
      (if (= (bht:get rec "nhom") "BIEN_BAO")
        (progn
          (setq codes (bht:get-all rec "mat") count (bht:int (bht:get rec "so_mat")))
          (if (null codes) (setq codes (list (bht:get rec "ma_hieu"))))
          (if (or (> count 20) (> (length codes) 20)) (vl-exit-with-error "Một trụ hỗ trợ tối đa 20 mặt biển."))
          (while (and (< (length codes) count) (< (length codes) 20)) (setq codes (append codes (list (car codes)))))
          (if (and (> (length codes) 1) (not (bht:fn-defined-p 'BHTSIGNASSEMBLY)))
            (vl-exit-with-error "Nạp BHT.Bridge.dll trước khi chèn cụm nhiều mặt biển."))
          (if (and (> (length codes) 1) (bht:fn-defined-p 'BHTSIGNASSEMBLY))
            (progn
              (setq blocks nil)
              (foreach value codes
                (setq result (bht:tdt-import-block value (bht:get rec "mo_ta")))
                (if (null result) (setq result (bht:kh-default-block "BIEN_BAO" value)))
                (setq blocks (append blocks (list result))))
              (setq result (vl-catch-all-apply 'BHTSIGNASSEMBLY (list (bht:join blocks ";"))))
              (if (and (= (type result) 'STR) (tblsearch "BLOCK" result)) (setq blk result)
                (vl-exit-with-error "Không tạo được đủ các mặt biển. Kiểm tra thư viện hoặc BHT.Bridge.dll."))))))
      (if (tblsearch "BLOCK" blk) blk "BHT_KH_CHUA_XAC_DINH"))))

(defun bht:kh-block (rec / blk result)
  (setq blk (bht:kh-base-block rec))
  (if (and (= (bht:get rec "nhom") "BIEN_BAO") (= (bht:meta "sign_fill_all" "1") "0"))
    (progn
      (setq result (if (bht:fn-defined-p 'BHTSIGNOUTLINE)
                     (vl-catch-all-apply 'BHTSIGNOUTLINE (list blk)) nil))
      (if (or (vl-catch-all-error-p result) (/= (type result) 'STR))
        (progn (bht:msg "Không tạo được biển không tô màu. Kiểm tra BHT.Bridge.dll. Đang giữ block tô màu.") blk)
        result))
    blk))

(defun bht:kh-scale-for (rec / custom f)
  (setq custom (bht:meta (bht:kh-custom-key (bht:get rec "nhom")) "")
        f (bht:num (bht:meta (bht:kh-custom-factor-key (bht:get rec "nhom")) "1")))
  (* (bht:kh-scale) (if (and (= (bht:get rec "custom_block") "") (/= custom "") f (> f 0.0)) f 1.0))
)

(defun bht:all-zero-p (s / ok i)
  (setq ok T i 1)
  (while (and ok (<= i (strlen s)))
    (if (/= (substr s i 1) "0") (setq ok nil))
    (setq i (1+ i)))
  ok
)

(defun bht:kh-code-label (group code / prefix value upper dot decimals)
  (setq value (vl-string-trim " " (bht:str code))
        prefix (strcat (strcase group) "_")
        upper (strcase value))
  ;; Ma luu co the la COC_TIEU_KM48+500; bo tien to noi bo khoi nhan ban ve.
  (if (and (>= (strlen upper) (strlen prefix)) (= (substr upper 1 (strlen prefix)) prefix))
    (setq value (substr value (1+ (strlen prefix))) upper (strcase value)))
  (if (and (= group "BIEN_BAO") (setq dot (vl-string-search "@" value)))
    (setq value (strcat (substr value 1 dot) " (" (substr value (+ dot 2)) " m)")))
  (if (= (substr upper 1 (min 2 (strlen upper))) "KM")
    (progn
      (setq value (vl-string-trim " " (substr value 3))
            dot (vl-string-search "." value))
      (if dot
        (progn
          (setq decimals (substr value (+ dot 2)))
          (if (bht:all-zero-p decimals) (setq value (substr value 1 dot)))))
      (strcat "Km " value))
    value)
)

(defun bht:kh-label (oid rec / group code chainage detail)
  ;; Nhan hien thi la ten nghiep vu + ma/ly trinh; object_id chi giu trong XData.
  (setq group (bht:get rec "nhom")
        code (bht:get rec "ma_hieu")
        chainage (bht:get rec "ly_trinh_km")
        detail (cond ((/= code "") (bht:kh-code-label group code))
                     ((/= chainage "") (bht:kh-code-label group chainage))
                     (T "")))
  (if (= group "BIEN_BAO")
    (strcat (if (/= code "") (bht:kh-code-label group code) "Biển báo")
            (if (/= chainage "") (strcat "  " chainage) ""))
    (strcat (bht:group-label group) (if (/= detail "") (strcat " " detail) "")))
)

;; Vi tri/goc ky hieu tu dong theo tim: bien bao duoc day ra ngoai phia duong,
;; giu diem RTK lam moc that va noi bang duong dan. Cac nhom khac dat dung tam diem.
(defun bht:kh-route-transform (rec pos sc / rid rrec ent pr cp par der dl off ux uy side gap rot)
  (if (or (null pos) (null rec))
    (list pos 0.0)
    (progn
      (setq rid (bht:get rec "route_id") rrec (if (/= rid "") (bht:route-read rid) nil)
            ent (if rrec (bht:route-ent rrec) nil) pr (if ent (bht:curve-project ent pos) nil)
            side (strcase (if (/= (bht:get rec "phia_tuyen") "") (bht:get rec "phia_tuyen") (bht:get rec "phia_duong")))
            gap (if (= (bht:get rec "nhom") "BIEN_BAO") (* 2.8 sc) 0.0))
      (if pr
        (progn
          (setq cp (cadddr pr) par (vl-catch-all-apply 'vlax-curve-getParamAtPoint (list ent cp))
                der (if (and par (not (vl-catch-all-error-p par)))
                      (vl-catch-all-apply 'vlax-curve-getFirstDeriv (list ent par)) nil))
          (if (or (null der) (vl-catch-all-error-p der))
            (list pos 0.0)
            (progn
              (setq dl (distance '(0.0 0.0 0.0) (list (car der) (cadr der) 0.0))
                    off (distance (list (car cp) (cadr cp)) (list (car pos) (cadr pos))))
              (if (< dl 1e-9)
                (list pos 0.0)
                (progn
                  (if (= (bht:int (bht:get rrec "direction")) -1)
                    (setq der (mapcar '- der)))
                  (if (not (member side '("TRAI" "PHAI")))
                    (setq side (if (> (* (if (= (bht:int (bht:get rrec "direction")) -1) -1 1) (caddr pr)) 0) "TRAI" "PHAI")))
                  (setq rot (+ (atan (cadr der) (car der))
                               (if (= side "TRAI") (- (/ pi 2.0)) (/ pi 2.0))))
                  (if (> off 0.05)
                    (setq ux (/ (- (car pos) (car cp)) off) uy (/ (- (cadr pos) (cadr cp)) off))
                    (if (= side "TRAI")
                      (setq ux (/ (- (cadr der)) dl) uy (/ (car der) dl))
                      (setq ux (/ (cadr der) dl) uy (/ (- (car der)) dl))))
                  (list (list (+ (car pos) (* gap ux)) (+ (cadr pos) (* gap uy)) (caddr pos)) rot))))))
        ;; Chua co tim: van tach bien khoi dau diem theo phia da khai bao.
        (if (= side "TRAI")
          (list (list (- (car pos) gap) (+ (cadr pos) gap) (caddr pos)) 0.0)
          (list (list (+ (car pos) gap) (+ (cadr pos) gap) (caddr pos)) 0.0))))))

;; Free placement overrides only display; RTK coordinates and route links remain unchanged.
(defun bht:kh-free-transform (rec / x y z r)
  (if (and (= (bht:get rec "kh_mode") "TU_DO")
           (setq x (bht:num (bht:get rec "kh_free_x")))
           (setq y (bht:num (bht:get rec "kh_free_y")))
           (setq z (bht:num (bht:get rec "kh_free_z")))
           (setq r (bht:num (bht:get rec "kh_free_rot"))))
    (list (list x y z) r)))
(defun bht:kh-auto-transform (rec pos sc / free)
  (if (setq free (bht:kh-free-transform rec)) free (bht:kh-route-transform rec pos sc)))
(defun bht:kh-via-points (rec / out value nums)
  (setq out nil)
  (if (= (bht:get rec "kh_mode") "TU_DO")
    (foreach value (bht:get-all rec "kh_via")
      (setq nums (mapcar 'bht:num (bht:split value ",")))
      (if (and (= (length nums) 3) (vl-every 'numberp nums)) (setq out (append out (list nums))))))
  out)
(defun bht:kh-free-clear (rec)
  (vl-remove-if '(lambda (pair) (member (car pair) '("kh_mode" "kh_free_x" "kh_free_y" "kh_free_z" "kh_free_rot" "kh_via"))) rec))
;; Called after every input succeeds. No drawing changes during interactive picking.
(defun bht:kh-free-apply (oid target rot via / rec d pair pt)
  (setq rec (bht:obj-read oid))
  (if (and rec target (numberp rot))
    (progn
      (setq rec (bht:kh-free-clear rec))
      (foreach pair (list (cons "kh_mode" "TU_DO") (cons "kh_free_x" (bht:fnum (car target) 8))
        (cons "kh_free_y" (bht:fnum (cadr target) 8)) (cons "kh_free_z" (bht:fnum (caddr target) 8))
        (cons "kh_free_rot" (bht:fnum rot 8))) (setq rec (append rec (list pair))))
      (foreach pt via (setq rec (append rec (list (cons "kh_via" (strcat (bht:fnum (car pt) 8) "," (bht:fnum (cadr pt) 8) "," (bht:fnum (caddr pt) 8)))))))
      (bht:obj-write oid rec)
      ;; Explicit placement replaces an earlier manual INSERT position/angle.
      (foreach pr (bht:tagged-pairs "INSERT" "BHT_KH" 1)
        (if (= (strcase (car pr)) (strcase oid))
          (progn (setq d (entget (cdr pr)))
            (entmod (append d (list (bht:kh-xdata-ins oid "TU_DONG" (cdr (assoc 10 d)) (cdr (assoc 50 d)) (cdr (assoc 41 d)))))))))
      (bht:symbol-sync (list oid)))))
(defun bht:kh-place-free (oid / rec source base angle0 rotation picked via cursor done target dir)
  (setq oid (strcase (bht:trim (bht:str oid))) rec (bht:obj-read oid))
  (cond
    ((null rec) (list 'LOI "Không có hồ sơ này."))
    ((null (setq source (bht:obj-position rec (bht:pt-all)))) (list 'LOI "Hồ sơ chưa có điểm RTK hợp lệ."))
    (T
      (setq base (trans source 0 1) via nil cursor base done nil)
      (setq angle0 (getangle base "\nHướng ký hiệu (chỉ hướng hoặc nhập góc) <0>: "))
      (if (null angle0) (setq angle0 0.0))
      ;; UCS angle -> WCS block rotation, without ANGBASE/ANGDIR assumptions.
      (setq dir (trans (list (cos angle0) (sin angle0) 0.0) 1 0 T) rotation (atan (cadr dir) (car dir)))
      (while (not done)
        (initget "Dat Xoa")
        (setq picked (getpoint cursor "\nĐiểm trung gian hoặc [Dat ký hiệu/Xoa điểm cuối] <Dat ký hiệu>: "))
        (cond
          ((or (null picked) (= picked "Dat")) (setq done T))
          ((= picked "Xoa") (if via (setq via (reverse (cdr (reverse via))))) (setq cursor (if via (trans (last via) 0 1) base)))
          ((listp picked) (setq via (append via (list (trans picked 1 0))) cursor picked))))
      (if (setq target (getpoint cursor "\nChọn vị trí đặt ký hiệu (Enter = hủy): "))
        (progn (setq target (trans target 1 0)) (bht:kh-free-apply oid target rotation via))
        (list 'HUY)))))
(defun bht:kh-place-options (oid mode direction degrees / rec source target rot via route picked dir ang cursor done)
  (setq oid (strcase (bht:trim (bht:str oid))) rec (bht:obj-read oid))
  (cond
    ((null rec) (list 'LOI "Không có hồ sơ này."))
    ((not (member mode '("DIRECT" "ELBOW" "WAYPOINT"))) (list 'LOI "Chế độ đặt ký hiệu không hợp lệ."))
    ((not (member direction '("HORIZONTAL" "ROUTE" "PICK" "ANGLE"))) (list 'LOI "Hướng ký hiệu không hợp lệ."))
    ((and (= direction "ANGLE") (null (bht:num degrees))) (list 'LOI "Góc nhập không hợp lệ."))
    ((null (setq source (bht:obj-position rec (bht:pt-all)))) (list 'LOI "Hồ sơ chưa có điểm RTK hợp lệ."))
    (T
      (setq via nil cursor (trans source 0 1) done nil)
      (if (= mode "WAYPOINT")
        (while (not done)
          (initget "Dat Xoa")
          (setq picked (getpoint cursor "\nĐiểm trung gian hoặc [Dat/Xoa điểm cuối] <Dat>: "))
          (cond
            ((or (null picked) (= picked "Dat")) (setq done T))
            ((= picked "Xoa") (if via (setq via (reverse (cdr (reverse via))))) (setq cursor (if via (trans (last via) 0 1) (trans source 0 1))))
            (T (setq via (append via (list (trans picked 1 0))) cursor picked)))))
      (if (null (setq picked (getpoint cursor "\nChọn vị trí ký hiệu (Enter = hủy): "))) (list 'HUY)
        (progn
          (setq target (trans picked 1 0) rot 0.0 ang nil)
          (cond
            ((= direction "ROUTE") (setq route (bht:kh-route-transform rec source (bht:kh-scale)) rot (if route (cadr route) 0.0)))
            ((= direction "ANGLE") (setq rot (* pi (/ (bht:num degrees) 180.0))))
            ((= direction "PICK")
              (setq ang (getangle picked "\nChọn hướng ký hiệu (Enter = hủy): "))
              (if ang (setq dir (trans (list (cos ang) (sin ang) 0.0) 1 0 T) rot (atan (cadr dir) (car dir))))))
          (if (and (= direction "PICK") (null ang)) (list 'HUY)
            (progn
              (if (and (= mode "ELBOW") (not (equal (car source) (car target) 1e-8)) (not (equal (cadr source) (cadr target) 1e-8)))
                (setq via (list (list (car source) (cadr target) (caddr source)))))
              (bht:kh-free-apply oid target rot via))))))))
(defun c:BHTDATTUDO (/ *error* oid r)
  (setq *error* bht:on-error)
  (bht:ensure-model)
  (setq oid (bht:ask-string "ID hồ sơ cần đặt ký hiệu tự do" ""))
  (if (/= oid "")
    (progn (setq r (bht:kh-place-free oid))
      (cond ((eq (car r) 'LOI) (bht:warn (cadr r))) ((eq (car r) 'HUY) (bht:msg "Đã hủy chèn tự do."))
            (T (bht:symbol-report r)))))
  (princ))

(defun bht:kh-readable-angle (a / two)
  (setq two (* 2.0 pi))
  (while (< a 0.0) (setq a (+ a two)))
  (while (>= a two) (setq a (- a two)))
  (if (and (> a (/ pi 2.0)) (< a (* 1.5 pi))) (- a pi) a)
)

(defun bht:kh-leader-xdata (oid)
  (list -3 (list "BHT_KH" (cons 1000 oid) (cons 1000 "DAN")))
)

;; Dong bo mot duong dan. Tra ve so ban trung/thua da xoa.
(defun bht:kh-leader-xy (points)
  (mapcar '(lambda (pt) (list (car pt) (cadr pt))) points))
(defun bht:kh-leader-matches-p (d points elevation)
  (and (equal (mapcar 'cdr (vl-remove-if-not '(lambda (pair) (= (car pair) 10)) d)) (bht:kh-leader-xy points) 1e-8)
       (equal (cdr (assoc 38 d)) elevation 1e-8)))
(defun bht:kh-leader-sync-one (oid a b ents via / e d nd n points kind)
  (setq e (car ents) n 0)
  (foreach e2 (cdr ents) (if (entget e2) (progn (entdel e2) (setq n (1+ n)))))
  (setq points (if (and a b) (append (list a) via (list b)) nil)
        kind (if via "LWPOLYLINE" "LINE"))
  (if (and e (setq d (entget e)) (/= (cdr (assoc 0 d)) kind))
    (progn (entdel e) (setq e nil d nil)))
  (if (and a b (or via (> (distance a b) 0.05)))
    (progn
      (if e
        (setq nd (if via
          (if (bht:kh-leader-matches-p d points (caddr a)) d
            (append (bht:dxf-put (vl-remove-if '(lambda (pair) (member (car pair) '(10 90))) d) 38 (caddr a))
                    (list (cons 90 (length points))) (mapcar '(lambda (pt) (cons 10 (list (car pt) (cadr pt)))) points)))
          (bht:dxf-put (bht:dxf-put d 10 a) 11 b)))
        (setq nd (if via
          (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (410 . "Model") (8 . "BHT_DUONG_DAN") (100 . "AcDbPolyline"))
            (list (cons 90 (length points)) '(70 . 0) (cons 38 (caddr a)))
            (mapcar '(lambda (pt) (cons 10 (list (car pt) (cadr pt)))) points))
          (list '(0 . "LINE") '(410 . "Model") '(8 . "BHT_DUONG_DAN") (cons 10 a) (cons 11 b)))))
      (setq nd (bht:dxf-put nd 8 "BHT_DUONG_DAN"))
      (if e
        (if (not (equal nd d)) (progn (entmod (append nd (list (bht:kh-leader-xdata oid)))) (entupd e)))
        (entmakex (append nd (list (bht:kh-leader-xdata oid))))))
    (if (and e (entget e)) (progn (entdel e) (setq n (1+ n)))))
  n)

(defun bht:kh-xdata-ins (oid state pt rot sc)
  (list -3 (list "BHT_KH" (cons 1000 oid) (cons 1000 state) (cons 1000 (bht:fnum (car pt) 6))
                 (cons 1000 (bht:fnum (cadr pt) 6)) (cons 1000 (bht:fnum rot 8)) (cons 1000 (bht:fnum sc 8))))
)

(defun bht:kh-xdata-txt (oid state pt)
  (list -3 (list "BHT_KH" (cons 1000 oid) (cons 1000 "NHAN") (cons 1000 state)
                 (cons 1000 (bht:fnum (car pt) 6)) (cons 1000 (bht:fnum (cadr pt) 6))))
)

;; Trang thai ky hieu INSERT: 'AUTO / 'TAY. autopos: vi tri tu dong hien tai (de nhan ra ky hieu 0.3.2).
(defun bht:kh-ins-state (e autopos / d x pos)
  (setq d (entget e) x (bht:xget e "BHT_KH") pos (cdr (assoc 10 d)))
  (cond
    ((>= (length x) 6)
     (if (and (= (nth 1 x) "TU_DONG")
              (bht:pt-near pos (list (bht:num (nth 2 x)) (bht:num (nth 3 x))) *bht-lbl-tol*)
              (equal (cdr (assoc 50 d)) (bht:num (nth 4 x)) 1e-6)
              (equal (cdr (assoc 41 d)) (bht:num (nth 5 x)) 1e-6))
       'AUTO 'TAY))
    ;; 0.3.2: dat o trung binh diem, goc 0, ty le kh_scale -> tu dong
    ((and autopos (bht:pt-near pos autopos *bht-lbl-tol*) (equal (cdr (assoc 50 d)) 0.0 1e-9)
          (equal (cdr (assoc 41 d)) (bht:kh-scale) 1e-6))
     'AUTO)
    (T 'TAY))
)

;; Trang thai nhan ky hieu: legacy-pos = vi tri 0.3.2 (theo ky hieu + ty le).
(defun bht:kh-txt-state (e legacy-pos / d x pos)
  (setq d (entget e) x (bht:xget e "BHT_KH") pos (cdr (assoc (if (= (cdr (assoc 72 d)) 1) 11 10) d)))
  (cond
    ((and (>= (length x) 5) (= (nth 1 x) "NHAN"))
     (if (and (= (nth 2 x) "TU_DONG") (bht:pt-near pos (list (bht:num (nth 3 x)) (bht:num (nth 4 x))) *bht-lbl-tol*))
       'AUTO 'TAY))
    ((and legacy-pos (bht:pt-near pos legacy-pos *bht-lbl-tol*)) 'AUTO)
    (T 'TAY))
)

;; Thuc the khong doi: du lieu DXF va XData giong ban moi.
(defun bht:ent-same-p (e d nd nx)
  (and (equal d nd) (equal (bht:xget e (car (cadr nx))) (mapcar 'cdr (cdr (cadr nx)))))
)

;; Cap nhat ky hieu cua ho so theo object_id.
;;  scope nil = moi ho so (tao ky hieu con thieu); danh sach oid = chi cac ho so do.
;;  create nil = chi cap nhat ky hieu da co (khong tao moi).
;; Ky hieu mo coi (ho so da xoa) luon bi xoa. Tra ve assoc:
;;  created updated unchanged removed duplicates manual nopos total
(defun bht:symbol-sync-ex (scope create / s h ins txt dan index oids rec pos blk g e d nd nx st anchor sc rot lpos
                                       auto tr trot layout created updated same removed dup manual nopos all lbl ok)
  (setq s (bht:kh-scale) h (bht:kh-h) created 0 updated 0 same 0 removed 0 dup 0 manual 0 nopos 0)
  (bht:sign-layers) (bht:layer "BHT_NHAN" 2) (bht:layer "BHT_DUONG_DAN" 6)
  (bht:regapp "BHT_KH")
  (bht:symbol-blocks)
  (setq ins (bht:group-pairs (bht:tagged-pairs "INSERT" "BHT_KH" 1))
        txt (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_KH" 1))
        dan (bht:group-pairs (append (bht:tagged-pairs "LINE" "BHT_KH" 1) (bht:tagged-pairs "LWPOLYLINE" "BHT_KH" 1)))
        all (bht:obj-ids) index (bht:pt-all)
        oids (if scope (mapcar 'strcase scope) all))
  ;; ky hieu cua ho so da xoa
  (foreach gr (append ins txt dan)
    (if (not (member (car gr) all))
      (foreach e2 (cdr gr) (if (entget e2) (progn (entdel e2) (setq removed (1+ removed)))))))
  (foreach oid oids
    (setq rec (bht:obj-read oid))
    (if rec
      (progn
        (setq pos (bht:obj-position rec index) blk (bht:kh-block rec) sc (bht:kh-scale-for rec)
              tr (bht:kh-auto-transform rec pos sc) auto (car tr) rot (cadr tr)
              g (cdr (assoc oid ins)) anchor nil)
        (foreach e2 (cdr g) (entdel e2) (setq dup (1+ dup)))
        (cond
          ((setq e (car g))
           (setq d (entget e) st (bht:kh-ins-state e auto))
           (cond
             ((and (eq st 'AUTO) auto)
               (setq nd (bht:dxf-put (bht:dxf-put (bht:dxf-put (bht:dxf-put (bht:dxf-put d 10 auto) 41 sc) 42 sc) 43 sc) 50 rot)
                    nd (bht:dxf-put (bht:dxf-put nd 2 blk) 8 "BHT_KYHIEU")
                    nx (bht:kh-xdata-ins oid "TU_DONG" auto rot sc)))
             ((eq st 'AUTO)
              ;; ho so khong con diem hop le: giu ky hieu tai cho
              (setq nopos (1+ nopos) nd (bht:dxf-put d 2 blk)
                    nx (bht:kh-xdata-ins oid "TU_DONG" (cdr (assoc 10 d)) (cdr (assoc 50 d)) (cdr (assoc 41 d)))))
             (T
              (setq manual (1+ manual) nd (bht:dxf-put d 2 blk)
                    nx (bht:kh-xdata-ins oid "TAY" (cdr (assoc 10 d)) (cdr (assoc 50 d)) (cdr (assoc 41 d))))))
           (if (bht:ent-same-p e d nd nx)
             (setq same (1+ same))
             (progn (entmod (append nd (list nx))) (entupd e) (setq updated (1+ updated))))
           (setq d (entget e) anchor (list (cdr (assoc 10 d)) (abs (cdr (assoc 41 d))) (cdr (assoc 50 d)))))
          ((and auto create)
            (setq e (bht:insert blk auto "BHT_KYHIEU" sc))
           (if e
             (progn
                (setq d (bht:dxf-put (entget e) 50 rot))
                (entmod (append d (list (bht:kh-xdata-ins oid "TU_DONG" auto rot sc))))
               (entupd e)
                (setq created (1+ created) anchor (list auto sc rot)))))
          ((null pos) (setq nopos (1+ nopos))))
        (setq dup (+ dup (bht:kh-leader-sync-one oid pos (if anchor (car anchor) nil) (cdr (assoc oid dan)) (bht:kh-via-points rec))))
        ;; nhan ky hieu (theo vi tri ky hieu thuc te)
        (if anchor
          (progn
            (setq h (bht:kh-label-height rec) lbl (bht:kh-label oid rec) sc (cadr anchor) rot (caddr anchor)
                  trot (bht:kh-readable-angle rot)
                  lpos (polar (car anchor) (+ rot (/ pi 2.0)) (* 2.65 sc)))
            (if (= (bht:get rec "nhom") "BIEN_BAO")
              (setq layout (bht:kh-sign-label-layout blk anchor) lpos (car layout) h (cadr layout) trot rot))
            (if (and (= (bht:get rec "nhom") "COC_TIEU") (= blk "BHT_KH_COC_TIEU"))
              (setq lpos (polar (polar (car anchor) rot (* -1.67 sc)) (+ rot (/ pi 2.0)) (* 0.75 sc)) h (* 0.35 sc)))
            (setq trot rot g (cdr (assoc oid txt)))
            (foreach e2 (cdr g) (entdel e2) (setq dup (1+ dup)))
            (if (setq e (car g))
              (progn
                (setq d (entget e)
                      st (bht:kh-txt-state e (if pos (list (+ (car pos) (* 1.5 (bht:kh-scale))) (+ (cadr pos) (* 1.0 (bht:kh-scale)))) nil)))
                (if anchor
                  (setq nd (bht:dxf-put (bht:dxf-put (bht:dxf-put (bht:dxf-put (bht:dxf-put d 10 lpos) 1 (bht:cad-text lbl (bht:kh-label-style lbl))) 40 h) 8 "BHT_NHAN") 50 trot)
                        nx (bht:kh-xdata-txt oid "TU_DONG" lpos))
                  (setq manual (1+ manual)
                        nd (bht:dxf-put (bht:dxf-put d 1 (bht:cad-text lbl (bht:kh-label-style lbl))) 40 h)
                        nx (bht:kh-xdata-txt oid "TAY" (cdr (assoc 10 d)))))
                (if anchor
                  (setq nd (bht:dxf-put (bht:dxf-put (bht:dxf-put (bht:dxf-put nd 10 lpos) 11 lpos) 72 1) 73 3)))
                ;; 5.0: kieu chu nhan (chi nhan BHT_KH do BHT tao; vi tri tay van giu)
                (setq nd (bht:dxf-put nd 7 (bht:kh-label-style lbl)))
                (if (not (bht:ent-same-p e d nd nx))
                  (progn (entmod (append nd (list nx))) (entupd e))))
              (progn
                (setq e (bht:text lbl lpos h "BHT_NHAN"))
                (if e (progn
                  (setq nd (bht:dxf-put (bht:dxf-put (entget e) 50 trot) 7 (bht:kh-label-style lbl)))
                  (if anchor
                    (setq nd (bht:dxf-put (bht:dxf-put (bht:dxf-put (bht:dxf-put nd 10 lpos) 11 lpos) 72 1) 73 3)))
                  (entmod (append nd
                                             (list (bht:kh-xdata-txt oid "TU_DONG" lpos)))) (entupd e))))))))))
  (bht:log (strcat "Ký hiệu theo ID: tạo " (itoa created) ", cập nhật " (itoa updated) ", giữ " (itoa same)
                   ", xóa (hồ sơ đã xóa) " (itoa removed) ", xóa trùng " (itoa dup) ", vị trí tay giữ " (itoa manual)))
  (list (cons 'created created) (cons 'updated updated) (cons 'unchanged same) (cons 'removed removed)
        (cons 'duplicates dup) (cons 'manual manual) (cons 'nopos nopos)
        (cons 'total (length (bht:tagged-pairs "INSERT" "BHT_KH" 1))))
)

(defun bht:symbol-sync (scope) (bht:symbol-sync-ex scope T))

;; Chi cap nhat ky hieu DA CO cua cac ho so (khong tao moi).
(defun bht:symbol-refresh (oids / have)
  (setq have (mapcar 'car (bht:tagged-pairs "INSERT" "BHT_KH" 1)))
  (setq oids (vl-remove-if-not '(lambda (o) (member (strcase o) have)) oids))
  (if oids (bht:symbol-sync-ex oids nil) nil)
)

;; Bo trang thai TAY cua ky hieu (+ nhan) cac ho so -> ve lai vi tri tu dong.
(defun bht:symbol-reset (oids / up n d x oid)
  (setq up (mapcar 'strcase oids) n 0)
  (foreach oid up (if (bht:obj-read oid) (bht:obj-write oid (bht:kh-free-clear (bht:obj-read oid)))))
  (foreach pr (append (bht:tagged-pairs "INSERT" "BHT_KH" 1) (bht:tagged-pairs "TEXT" "BHT_KH" 1))
    (if (member (car pr) up)
      (progn
        (setq d (entget (cdr pr)) x (bht:xget (cdr pr) "BHT_KH"))
        (entmod (append d (list (if (= (cdr (assoc 0 d)) "INSERT")
                                  (bht:kh-xdata-ins (car pr) "TU_DONG" (cdr (assoc 10 d)) (cdr (assoc 50 d)) (cdr (assoc 41 d)))
                                  (bht:kh-xdata-txt (car pr) "TU_DONG" (cdr (assoc 10 d)))))))
        (entupd (cdr pr))
        (setq n (1+ n)))))
  (list n (bht:symbol-sync-ex up nil))
)

;; Tuong thich 0.3.2: "ve lai" = cap nhat theo ID. Tra ve so doi tuong co ky hieu.
(defun bht:symbols-draw (scale h / r)
  (bht:meta-set "kh_scale" (bht:fnum scale 3)) (bht:meta-set "kh_h" (bht:fnum h 3))
  (setq r (bht:symbol-sync nil))
  (cdr (assoc 'total r))
)

(defun bht:symbol-report (r)
  (bht:msg (strcat "BHT ký hiệu (cập nhật theo object_id): tạo " (itoa (cdr (assoc 'created r)))
                   ", cập nhật " (itoa (cdr (assoc 'updated r))) ", giữ nguyên " (itoa (cdr (assoc 'unchanged r)))
                   ", xóa của hồ sơ đã xóa " (itoa (cdr (assoc 'removed r)))
                   ", xóa trùng " (itoa (cdr (assoc 'duplicates r)))
                   " | vị trí/góc/tỷ lệ người dùng đặt được giữ: " (itoa (cdr (assoc 'manual r)))
                   " | hồ sơ chưa có vị trí: " (itoa (cdr (assoc 'nopos r)))
                   " | tổng ký hiệu: " (itoa (cdr (assoc 'total r))) "."))
)

(defun c:BHTKYHIEU (/ *error* s h v r ss i x oids)
  (setq *error* bht:on-error)
  (setq v (strcase (bht:ask-string "[Enter=Cập nhật theo ID/R=Trả ký hiệu chọn về vị trí tự động/C=Cài đặt tỷ lệ, cao chữ]" "")))
  (cond
    ((= v "C")
     (setq s (bht:num (bht:ask-string "Tỷ lệ ký hiệu" (bht:meta "kh_scale" "1")))
           h (bht:num (bht:ask-string "Chiều cao chữ nhãn" (bht:meta "kh_h" "1.5"))))
     (if (and s h (> s 0) (> h 0))
       (progn (bht:meta-set "kh_scale" (bht:fnum s 3)) (bht:meta-set "kh_h" (bht:fnum h 3))
              (bht:symbol-report (bht:symbol-sync nil)))
       (bht:msg "BHT: giá trị không hợp lệ.")))
    ((= v "R")
     (bht:msg "Chọn ký hiệu / nhãn ký hiệu BHT cần trả về vị trí tự động: ")
     (setq ss (ssget '((-3 ("BHT_KH")))) i 0 oids nil)
     (if ss (while (< i (sslength ss))
              (if (setq x (bht:xget (ssname ss i) "BHT_KH")) (setq oids (bht:unique-add oids (strcase (car x)))))
              (setq i (1+ i))))
     (if oids
       (progn (setq r (bht:symbol-reset oids))
              (bht:msg (strcat "BHT: trả " (itoa (car r)) " ký hiệu/nhãn về vị trí tự động."))
              (bht:symbol-report (cadr r)))
       (bht:msg "BHT: không chọn được ký hiệu BHT nào.")))
    (T (bht:symbol-report (bht:symbol-sync nil))))
  (bht:log-flush)
  (princ)
)

;; Thu vien block tuy chon: moi file DWG la 1 block, INSBASE cua file nguon la
;; tam chen. BHT chi luu ten dinh nghia block theo nhom; hinh hoc nguon giu nguyen.
(defun c:BHTBLOCK (/ *error* gv group action path name oids r q)
  (setq *error* bht:on-error)
  (bht:msg "Nhóm block: 1=Biển báo, 2=Cọc tiêu, 3=Cột Km, 4=Bảng chỉ dẫn, 5=Bảng QC, 6=Đèn, 7=Công trình, 8=Khác, 0=Chưa xác định.")
  (setq gv (bht:ask-string "Chọn nhóm (số hoặc mã nhóm)" "1")
        group (bht:group-code gv))
  (if group
    (setq action (strcase (bht:ask-string "[D=Danh mục chuẩn/N=Nạp DWG tùy chọn/M=Dùng block mặc định/X=Xem cấu hình]"
                                          (if (= group "BIEN_BAO") "D" "N")))))
  (cond
    ((null group)
     (bht:warn "BHT: nhóm không hợp lệ."))
    ((= action "D")
     (if (= group "BIEN_BAO")
       (progn
         (setq q (bht:ask-string "Tìm biển theo mã hoặc tên, có dấu hay không dấu (vd di cham, 245a; Enter = xem danh mục chuẩn)" ""))
         (if (= q "") (bht:bb-catalog-report) (bht:sign-search-report q)))
       (bht:msg (strcat "BHT: nhóm " group " dùng block mặc định " (bht:kh-default-block group "") "."))))
    ((= action "M")
     (bht:meta-set (bht:kh-custom-key group) "")
     (bht:meta-set (bht:kh-custom-src-key group) "")
     (bht:meta-set (bht:kh-custom-factor-key group) "")
     (setq oids (bht:kh-group-oids group)
           r (if oids (bht:symbol-sync-ex oids nil) nil))
     (bht:msg (strcat "BHT: nhóm " group " dùng lại block mặc định."
                      (if r (strcat " Đã cập nhật " (itoa (length oids)) " hồ sơ.") ""))))
    ((= action "X")
     (setq name (bht:meta (bht:kh-custom-key group) ""))
     (bht:msg (strcat "BHT: nhóm " group " -> "
                      (if (= name "")
                         (strcat "mặc định " (bht:kh-default-block group "")
                                 (if (= group "BIEN_BAO") " (tự chọn theo trường Mã)" ""))
                        (strcat name " | hệ số đơn vị " (bht:meta (bht:kh-custom-factor-key group) "1")
                                " | nguồn " (bht:meta (bht:kh-custom-src-key group) ""))))))
    (T
     (setq path (getfiled (strcat "Chọn DWG block cho nhóm " group) (bht:dwg-folder) "dwg" 0))
     (cond
       ((null path) (bht:msg "BHT: đã hủy chọn DWG block."))
       ((null (setq name (bht:block-load-dwg path group)))
        (bht:err (strcat "BHT: không nạp được block - " *bht-block-load-error*)))
       (T
        (bht:meta-set (bht:kh-custom-key group) name)
        (bht:meta-set (bht:kh-custom-src-key group) path)
        (bht:meta-set (bht:kh-custom-factor-key group) (bht:fnum *bht-block-load-factor* 8))
        (setq oids (bht:kh-group-oids group)
              r (if oids (bht:symbol-sync-ex oids nil) nil))
        (bht:msg (strcat "BHT: đã nạp " name " cho nhóm " group ". INSBASE của DWG là tâm chèn."
                         (if r (strcat " Đã cập nhật " (itoa (length oids)) " hồ sơ.") "")))))))
  (bht:log-flush)
  (princ)
)



