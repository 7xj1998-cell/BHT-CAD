;;; ----------------------------------------------------------------------
;;; 0.3.3: Thu tu hien thi (BHTTHUTUVE)
;;;  Tren -> duoi: nhan (RTK, ky hieu, ma anh) > ky hieu / POINT / ky hieu anh /
;;;  duong dan > raster anh BHT > (cac thuc the khac) > anh nen IRT.
;;;  Chi dung thuc the nhan dien CHINH XAC bang XData BHT. Anh nen IRT: chi
;;;  IMAGE o khong gian mo hinh co layer / ten IMAGEDEF / TEN FILE (khong xet thu muc) khop
;;;  mau IRT (cai dat duoc), KHONG mang XData BHT; chi dua XUONG DUOI, khong
;;;  sua / xoa. Anh trong Xref hoac khong nhan dien duoc: bo qua va bao cao.
;;;  Dung lenh DRAWORDER (bang SORTENTS cua AutoCAD).
;;; ----------------------------------------------------------------------

(setq *bht-irt-layer-pat* "IRT*,*_IRT*,*-IRT*,*VE_TINH*,*VETINH*,*SATELLITE*,*GOOGLE*,*BING*,*ESRI*,*ARCGIS*,*TILE*")
(setq *bht-irt-file-pat* "IRT*,*_IRT*,*-IRT*,*TILE*,*SATELLITE*,*GOOGLE*,*BING*,*ARCGIS*,*ESRI*,*VIRTUALEARTH*,*VETINH*,*VE_TINH*")

;; ename IMAGEDEF -> ten trong ACAD_IMAGE_DICT
(defun bht:imagedef-names (/ d out nm)
  (setq out nil nm nil)
  (if (setq d (dictsearch (namedobjdict) "ACAD_IMAGE_DICT"))
    (foreach g d
      (cond ((= (car g) 3) (setq nm (cdr g)))
            ((and (= (car g) 350) nm) (setq out (cons (cons (cdr g) nm) out) nm nil)))))
  out
)

;; 0.4.0: mau THU MUC trong duong dan file anh (IRTv6 luu tile trong bo nho dem thu muc "IRT\" / "IRT.cache";
;; tile thuong nam tren layer hien hanh, vd layer 0 -> mau layer KHONG du tin cay). So tren duong dan
;; da doi "/" -> "\" va STRCASE. Cau hinh: BHTTHUTUVE > C (meta irt_mau_thumuc).
(setq *bht-irt-dir-pat* "*\\IRT\\*,IRT\\*,*\\IRT.CACHE\\*,*\\IRT.CACHE,*\\IRT_CACHE\\*")

;; Cau hinh nhan dien doc 1 lan cho ca luoi tile: (lp fp dp thu_muc_anh_BHT) - da STRCASE
(defun bht:irt-cfg (/ ph)
  (setq ph (bht:path-norm (bht:meta "thu_muc_anh" "")))
  (list (strcase (bht:meta "irt_mau_lop" *bht-irt-layer-pat*))
        (strcase (bht:meta "irt_mau_file" *bht-irt-file-pat*))
        (strcase (bht:meta "irt_mau_thumuc" *bht-irt-dir-pat*))
        ph)
)

;; Duong dan chuan hoa de so mau: "/" -> "\", chu HOA
(defun bht:path-norm (p / i)
  (setq p (strcase (bht:str p)))
  (while (setq i (vl-string-search "/" p)) (setq p (strcat (substr p 1 i) "\\" (substr p (+ i 2)))))
  p
)

;; Phan loai 1 IMAGE: 'BHT (raster BHT), 'IRT (khop mau IRT), 'KHAC.
;; 0.4.0: anh nen IRT la LUOI NHIEU TILE (moi tile 1 IMAGE rieng) -> cfg doc 1 lan (bht:irt-cfg);
;; KHONG BAO GIO coi la IRT: thuc the co XData BHT, layer BHT*, file nam trong thu muc anh BHT.
;; Kiem tra: layer -> duong dan (thu muc IRT\ / IRT.cache, ten file) -> ten trong ACAD_IMAGE_DICT.
(defun bht:image-kind (e names cfg / d x lay def dd path nm lp fp dp ph)
  (if (null cfg) (setq cfg (bht:irt-cfg)))
  (setq lp (nth 0 cfg) fp (nth 1 cfg) dp (nth 2 cfg) ph (nth 3 cfg))
  (setq d (entget e '("BHT_ANHRS" "BHT_PT" "BHT_NHAN" "BHT_KH" "BHT_ANHPT" "BHT_ANHTEN"))
        x (cdr (assoc -3 d)) lay (strcase (cdr (assoc 8 d))) def (cdr (assoc 340 d)) path "")
  (if (and def (setq dd (entget def)) (assoc 1 dd)) (setq path (bht:path-norm (cdr (assoc 1 dd)))))
  (cond
    ((assoc "BHT_ANHRS" x) 'BHT)
    (x 'KHAC)
    ((wcmatch lay "BHT*") 'KHAC)
    ((and (/= ph "") (/= path "") (= (strcase (substr path 1 (strlen ph))) ph)) 'KHAC)
    ((wcmatch lay lp) 'IRT)
    ((and (/= path "") (wcmatch path dp)) 'IRT)
    ((and (/= path "") (wcmatch (vl-filename-base path) fp)) 'IRT)
    ((and def (setq nm (cdr (assoc def names))) (/= nm "") (wcmatch (strcase nm) fp)) 'IRT)
    (T 'KHAC))
)

;; Layer dang khoa? (DRAWORDER cua AutoCAD bo qua doi tuong tren layer khoa - chi de bao cao)
(defun bht:layer-locked-p (lay / t8)
  (and lay (setq t8 (tblsearch "LAYER" lay)) (= 4 (logand 4 (cdr (assoc 70 t8)))))
)

(defun bht:ss-from-list (ents / ss)
  (setq ss (ssadd))
  (foreach e ents (if (entget e) (ssadd e ss)))
  (if (> (sslength ss) 0) ss nil)
)

(defun bht:ents-tagged (etype apps / out ss i)
  (setq out nil)
  (foreach a apps
    (setq ss (ssget "_X" (list (cons 0 etype) '(410 . "Model") (list -3 (list a)))) i 0)
    (if ss (while (< i (sslength ss)) (setq out (cons (ssname ss i) out) i (1+ i)))))
  out
)

;; Nhom thuc the theo tang hien thi. Tra ve assoc: labels mid raster irt other-images xref
(defun bht:draworder-groups (/ names ss i e k irt oth labels mid raster xr cfg lk)
  (setq names (bht:imagedef-names) irt nil oth nil xr 0 lk 0 cfg (bht:irt-cfg))
  (setq labels (append (bht:ents-tagged "TEXT" '("BHT_NHAN" "BHT_KH" "BHT_ANHTEN")))
        mid (append (bht:ents-tagged "INSERT" '("BHT_KH" "BHT_ANHPT"))
                    (bht:ents-tagged "POINT" '("BHT_PT" "BHT_RTK"))
                    (bht:ents-tagged "LINE" '("BHT_ANHDAN" "BHT_KH")))
        raster (bht:ents-tagged "IMAGE" '("BHT_ANHRS")))
  (setq ss (ssget "_X" '((0 . "IMAGE") (410 . "Model"))) i 0)
  (if ss
    (while (< i (sslength ss))
      (setq e (ssname ss i) k (bht:image-kind e names cfg))
      (if (and (eq k 'IRT) (bht:layer-locked-p (cdr (assoc 8 (entget e))))) (setq lk (1+ lk)))
      (cond ((eq k 'IRT) (setq irt (cons e irt)))
            ((eq k 'KHAC) (setq oth (cons e oth))))
      (setq i (1+ i))))
  ;; Xref: chi dem de bao cao (khong dong vao)
  (setq e (tblnext "BLOCK" T))
  (while e (if (= 4 (logand 4 (cdr (assoc 70 e)))) (setq xr (1+ xr))) (setq e (tblnext "BLOCK")))
  (list (cons 'labels labels) (cons 'mid mid) (cons 'raster raster) (cons 'irt irt)
        (cons 'other-images oth) (cons 'xref xr) (cons 'irt-locked lk))
)

(defun bht:draworder-cmd (ss how)
  (if ss
    (progn
      (vl-cmdf "_.DRAWORDER" ss "" how)
      (while (= 1 (logand 1 (getvar "CMDACTIVE"))) (command ""))
      (sslength ss))
    0)
)

;; Sap thu tu hien thi. Tra ve assoc so luong tung tang.
(defun bht:draworder-sync (/ g n)
  (setq g (bht:draworder-groups))
  (bht:sv-set "CMDECHO" 0)
  (bht:ensure-model)
  (setq n (list (cons 'irt (bht:draworder-cmd (bht:ss-from-list (cdr (assoc 'irt g))) "_Back"))
                (cons 'raster (bht:draworder-cmd (bht:ss-from-list (cdr (assoc 'raster g))) "_Front"))
                (cons 'mid (bht:draworder-cmd (bht:ss-from-list (cdr (assoc 'mid g))) "_Front"))
                (cons 'labels (bht:draworder-cmd (bht:ss-from-list (cdr (assoc 'labels g))) "_Front"))
                (cons 'other-images (length (cdr (assoc 'other-images g))))
                (cons 'xref (cdr (assoc 'xref g)))
                (cons 'irt-locked (cdr (assoc 'irt-locked g)))
                (cons 'outside (length (bht:ents-outside-model)))))
  (bht:sv-restore)
  (bht:log (strcat "Thứ tự hiển thị: nhãn " (itoa (cdr (assoc 'labels n))) ", ký hiệu/điểm " (itoa (cdr (assoc 'mid n)))
                   ", raster BHT " (itoa (cdr (assoc 'raster n))) ", ảnh nền IRT " (itoa (cdr (assoc 'irt n)))))
  n
)

(defun bht:draworder-report (n)
  (bht:msg (strcat "BHT thứ tự hiển thị (trên -> dưới): nhãn " (itoa (cdr (assoc 'labels n)))
                   " > ký hiệu / điểm RTK / ký hiệu ảnh " (itoa (cdr (assoc 'mid n)))
                   " > raster ảnh BHT " (itoa (cdr (assoc 'raster n)))
                   " > ... > ảnh nền IRT " (itoa (cdr (assoc 'irt n))) " (đưa xuống dưới cùng)."))
  (if (> (if (numberp (cdr (assoc 'irt-locked n))) (cdr (assoc 'irt-locked n)) 0) 0)
    (bht:msg (strcat "  " (itoa (cdr (assoc 'irt-locked n)))
                     " ảnh nền IRT nằm trên layer đang KHÓA - vẫn được sắp thứ tự (chỉ đổi bảng thứ tự hiển thị); BHT không mở khóa, không sửa ảnh.")))
  (if (> (cdr (assoc 'other-images n)) 0)
    (bht:msg (strcat "  " (itoa (cdr (assoc 'other-images n)))
                     " ảnh IMAGE không nhận diện chắc chắn là IRT - GIỮ NGUYÊN thứ tự (có thể đặt mẫu nhận diện: BHTTHUTUVE > C).")))
  (if (> (cdr (assoc 'xref n)) 0)
    (bht:msg (strcat "  Bản vẽ có " (itoa (cdr (assoc 'xref n))) " Xref: ảnh bên trong Xref KHÔNG được sắp (không sửa Xref).")))
  (if (> (cdr (assoc 'outside n)) 0)
    (bht:msg (strcat "  " (itoa (cdr (assoc 'outside n))) " thực thể BHT nằm trong Layout - không sắp; hãy kiểm tra vị trí thực thể trong Layout.")))
  (if (and (getvar "DRAWORDERCTL") (= (getvar "DRAWORDERCTL") 0))
    (bht:msg "  Lưu ý: DRAWORDERCTL = 0 - AutoCAD tắt thứ tự hiển thị; đặt DRAWORDERCTL = 3 để thấy kết quả."))
)

(defun c:BHTTHUTUVE (/ *error* v)
  (setq *error* bht:on-error)
  (setq v (strcase (bht:ask-string "[Enter=Sắp thứ tự hiển thị/C=Cài đặt mẫu nhận diện ảnh nền IRT]" "")))
  (if (= v "C")
    (progn
      (bht:meta-set "irt_mau_lop" (bht:ask-string "Mẫu tên layer ảnh nền IRT (wcmatch, cách nhau dấu phẩy)" (bht:meta "irt_mau_lop" *bht-irt-layer-pat*)))
      (bht:meta-set "irt_mau_file" (bht:ask-string "Mẫu tên ảnh / tên file IRT" (bht:meta "irt_mau_file" *bht-irt-file-pat*)))
      (bht:meta-set "irt_mau_thumuc" (bht:ask-string "Mẫu đường dẫn thư mục tile IRT (vd *\\IRT\\*; \"/\" coi như \"\\\")" (bht:meta "irt_mau_thumuc" *bht-irt-dir-pat*)))))
  (bht:draworder-report (bht:draworder-sync))
  (bht:log-flush)
  (princ)
)

;;; ----------------------------------------------------------------------
;;; 0.3.3: Khong gian ve (Model / Layout)
;;;  Tu 0.3.3 moi thuc the BHT duoc tao trong MODEL (410 . "Model") du nguoi dung
;;;  dang o tab Layout. Lenh AutoCAD (-IMAGE, DRAWORDER) tam chuyen sang Model
;;;  (TILEMODE) roi tra lai. Ban ve cu (0.3.2 tro ve truoc) neu da chay BHT khi
;;;  dang o Layout se co thuc the BHT nam trong Layout: BHTKT canh bao,
;;;  Cac thuc the moi luon duoc tao trong Model.
;;; ----------------------------------------------------------------------

(setq *bht-apps* '("BHT_PT" "BHT_RTK" "BHT_NHAN" "BHT_ANHPT" "BHT_ANHTEN" "BHT_ANHRS" "BHT_KH" "BHT_ANHDAN"))

;; Dang o paper space cua Layout -> tam bat TILEMODE=1 (bht:sv-restore tra lai).
(defun bht:ensure-model ()
  (if (and (= (getvar "TILEMODE") 0) (= (getvar "CVPORT") 1)) (bht:sv-set "TILEMODE" 1))
)

;; Thuc the mang XData BHT KHONG nam trong Model. Tra ve danh sach ename.
(defun bht:ents-outside-model (/ out ss i e)
  (setq out nil)
  (foreach a *bht-apps*
    (setq ss (ssget "_X" (list (list -3 (list a)))) i 0)
    (if ss
      (while (< i (sslength ss))
        (setq e (ssname ss i))
        (if (and (/= (strcase (bht:str (cdr (assoc 410 (entget e))))) "MODEL") (not (member e out)))
          (setq out (cons e out)))
        (setq i (1+ i)))))
  out
)

