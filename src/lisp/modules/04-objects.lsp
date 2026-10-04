;;; ----------------------------------------------------------------------
;;; Ho so doi tuong (object) - dictionary "OBJ"
;;; Truong: object_id nhom ma_hieu loai_ma mo_ta so_tru so_mat mat* tinh_trang
;;;  trang_thai_kt ghi_chu phia_duong pt* anh* anh_file* route_id ly_trinh_m
;;;  ly_trinh_km offset_m phia_tuyen trang_thai_km nguon_km doan goi
;;;  gan_doan_pp doan_ung_vien tao_luc sua_luc
;;; ----------------------------------------------------------------------

(defun bht:obj-read (id) (bht:rec-read "OBJ" id))
(defun bht:obj-write (id rec) (bht:rec-write "OBJ" id (bht:set rec "sua_luc" (bht:now))))
(defun bht:obj-ids () (bht:rec-keys "OBJ"))

;; ID tu dong KHONG dung lai so cua doi tuong da xoa (0.3.2: moc cao nhat luu META obj_seq).
(defun bht:obj-seq-num (id)
  (if (and id (wcmatch id "OBJ-######")) (bht:int (substr id 5)) nil)
)

(defun bht:obj-next-id (/ n id keys v)
  (setq keys (bht:obj-ids) n (bht:int (bht:meta "obj_seq" "0")))
  (if (null n) (setq n 0))
  (foreach k keys (if (and (setq v (bht:obj-seq-num k)) (> v n)) (setq n v)))
  (setq n (1+ n) id (strcat "OBJ-" (bht:pad0 n 6)))
  (while (member id keys)
    (setq n (1+ n) id (strcat "OBJ-" (bht:pad0 n 6))))
  id
)

;; Ban do: survey_point_id -> danh sach object_id
(defun bht:pt-owner-map (/ out it)
  (setq out nil)
  (foreach o (bht:rec-all "OBJ")
    (foreach pid (bht:get-all (cdr o) "pt")
      (setq pid (strcase pid))
      (if (setq it (assoc pid out))
        (setq out (subst (cons pid (append (cdr it) (list (car o)))) it out))
        (setq out (cons (list pid (car o)) out)))))
  out
)

;; Tao doi tuong. fields = (("nhom" . ..) ...). pids = danh sach survey id.
;; allow-shared: cho phep diem da thuoc doi tuong khac.
;; Tra ve (T id) hoac (nil "ly do").
(defun bht:obj-create (id fields pids allow-shared / index owners bad shared rec grp)
  (setq id (strcase (bht:trim id)) index (bht:pt-all) owners (bht:pt-owner-map) bad nil shared nil)
  (foreach pid pids
    (if (not (bht:pt-find pid index)) (setq bad (cons pid bad)))
    (if (assoc (strcase pid) owners) (setq shared (cons pid shared))))
  (setq grp (bht:group-code (bht:get fields "nhom")))
  (cond
    ((not (bht:valid-id id)) (list nil "ID không hợp lệ (A-Z 0-9 _ - .)"))
    ((bht:obj-read id) (list nil (strcat "ID " id " đã tồn tại")))
    ((null pids) (list nil "chưa chọn điểm RTK nào"))
    (bad (list nil (strcat "không tìm thấy điểm: " (bht:join bad ", "))))
    ((and shared (not allow-shared))
     (list nil (strcat "điểm đã thuộc đối tượng khác: " (bht:join shared ", "))))
    (T
     (setq rec (list (cons "object_id" id)
                     (cons "nhom" (if grp grp "CHUA_XAC_DINH"))
                     (cons "ma_hieu" (bht:get fields "ma_hieu"))
                     (cons "loai_ma" (if (/= (bht:get fields "loai_ma") "") (bht:get fields "loai_ma") "CHUA_XAC_DINH"))
                     (cons "mo_ta" (bht:get fields "mo_ta"))
                     (cons "so_tru" (bht:get fields "so_tru"))
                     (cons "so_mat" (bht:get fields "so_mat"))
                     (cons "tinh_trang" (bht:get fields "tinh_trang"))
                     (cons "trang_thai_kt" (if (/= (bht:get fields "trang_thai_kt") "") (bht:get fields "trang_thai_kt") "CHUA_KIEM_TRA"))
                     (cons "ghi_chu" (bht:get fields "ghi_chu"))
                     (cons "phia_duong" (if (/= (bht:get fields "phia_duong") "") (bht:get fields "phia_duong") "CHUA_XAC_DINH"))
                     (cons "doan" "") (cons "goi" "") (cons "gan_doan_pp" "CHUA_PHAN_DOAN")
                     (cons "trang_thai_km" "CHUA_TINH")
                     (cons "tao_luc" (bht:now))))
     (if (assoc "custom_block" fields) (setq rec (bht:set rec "custom_block" (bht:get fields "custom_block"))))
     (foreach key '("bridge_name" "sign_chainage" "road_name" "marker_km" "marker_h")
       (if (assoc key fields) (setq rec (bht:set rec key (bht:get fields key)))))
     (setq rec (bht:set-all rec "mat" (bht:get-all fields "mat")))
     (setq rec (bht:set-all rec "pt" (mapcar 'strcase pids)))
     (bht:obj-write id rec)
     (if (and (bht:obj-seq-num id) (> (bht:obj-seq-num id) (bht:num-or-zero (bht:meta "obj_seq" "0"))))
       (bht:meta-set "obj_seq" (itoa (bht:obj-seq-num id))))
     (bht:log (strcat "Tạo đối tượng " id " gồm " (itoa (length pids)) " điểm"))
     (list T id)))
)

(defun bht:obj-delete (id / rec)
  (setq id (strcase id) rec (bht:obj-read id))
  (if rec
    (progn
      ;; bo lien ket nguoc trong ho so anh
      (foreach a (bht:get-all rec "anh")
        (bht:photo-unlink-side (car (bht:split a "|")) id))
      (bht:rec-delete "OBJ" id)
      (bht:symbol-delete id)
      (bht:log (strcat "Xóa hồ sơ đối tượng " id " (điểm RTK giữ nguyên)"))
      T)
    nil)
)

(defun bht:obj-add-points (id pids / rec cur)
  (setq rec (bht:obj-read id))
  (if rec
    (progn
      (setq cur (bht:get-all rec "pt"))
      (foreach p pids (setq cur (bht:unique-add cur (strcase p))))
      (bht:obj-write id (bht:set-all rec "pt" cur))
      (length cur))
    nil)
)

(defun bht:obj-remove-points (id pids / rec cur up)
  (setq rec (bht:obj-read id) up (mapcar 'strcase pids))
  (if rec
    (progn
      (setq cur (vl-remove-if '(lambda (p) (member (strcase p) up)) (bht:get-all rec "pt")))
      (bht:obj-write id (bht:set-all rec "pt" cur))
      (length cur))
    nil)
)

;; Vi tri dai dien = trung binh toa do cac diem RTK (toa do goc, khong dich).
(defun bht:obj-position (rec index / sx sy sz n p xyz)
  (setq sx 0.0 sy 0.0 sz 0.0 n 0)
  (foreach pid (bht:get-all rec "pt")
    (if (and (setq p (bht:pt-find pid index)) (setq xyz (bht:pv p 'xyz)))
      (setq sx (+ sx (car xyz)) sy (+ sy (cadr xyz)) sz (+ sz (caddr xyz)) n (1+ n))))
  (if (> n 0) (list (/ sx n) (/ sy n) (/ sz n)) nil)
)

;; Chon doi tuong: chon ky hieu/diem, hoac nhap ID.
(defun bht:pick-object (msg / sel ent id owners pid lst)
  (initget "Id")
  (setq sel (entsel (strcat "\n" msg " [Id]: ")))
  (cond
    ((= sel "Id") (setq id (strcase (bht:ask-string "Nhập ID đối tượng" ""))))
    ((and sel (setq ent (car sel)))
     (cond
       ((bht:xget ent "BHT_KH") (setq id (car (bht:xget ent "BHT_KH"))))
       ((bht:xget ent "BHT_PT")
        (setq pid (strcase (car (bht:xget ent "BHT_PT")))
              lst (cdr (assoc pid (bht:pt-owner-map))))
        (cond ((null lst) (bht:msg (strcat "Điểm " pid " chưa thuộc đối tượng nào.")))
              ((= (length lst) 1) (setq id (car lst)))
              (T (bht:msg (strcat "Điểm thuộc nhiều đối tượng: " (bht:join lst ", ")))
                 (setq id (strcase (bht:ask-string "Nhập ID đối tượng" (car lst)))))))
       (T (bht:msg "Đối tượng chọn không phải điểm BHT hoặc ký hiệu BHT.")))))
  (if (and id (bht:obj-read id)) id
    (progn (if id (bht:warn (strcat "Không có đối tượng " id "."))) nil))
)

;; Lay survey id tu tap chon.
(defun bht:ss-point-ids (ss / i out x)
  (setq i 0 out nil)
  (if ss
    (while (< i (sslength ss))
      (if (setq x (bht:xget (ssname ss i) "BHT_PT"))
        (setq out (bht:unique-add out (strcase (car x)))))
      (setq i (1+ i))))
  out
)

(defun bht:select-points (msg)
  (bht:msg msg)
  (bht:ss-point-ids (ssget (list '(0 . "POINT") '(-3 ("BHT_PT")))))
)

(defun bht:print-groups ()
  (bht:msg "Nhóm đối tượng:")
  (foreach g *bht-groups* (princ (strcat "\n   " (car g) " = " (caddr g) " (" (cadr g) ")")))
)

(defun bht:ask-group (default / v g)
  (bht:print-groups)
  (setq v (bht:ask-string "Chọn nhóm (số hoặc mã)" default)
        g (bht:group-code v))
  (if g g (progn (bht:msg "Nhóm không hợp lệ -> CHUA_XAC_DINH.") "CHUA_XAC_DINH"))
)

(defun bht:ask-count (msg default / v)
  (setq v (bht:ask-string (strcat msg " (Enter = chưa rõ)") default))
  (cond ((= v "") "")
        ((and (bht:int v) (>= (bht:int v) 0)) (itoa (bht:int v)))
        (T (bht:msg "Không phải số nguyên -> để trống (chưa rõ).") ""))
)

(defun bht:ask-side (default / v u)
  (setq v (bht:ask-string "Phía đường [T=Trái/P=Phải/H=Hai bên/Enter=chưa xác định]" default)
        u (strcase v))
  (cond ((member u '("T" "TRAI")) "TRAI")
        ((member u '("P" "PHAI")) "PHAI")
        ((member u '("H" "HAI_BEN")) "HAI_BEN")
        (T "CHUA_XAC_DINH"))
)

;; 5.0: Tinh trang chuan (giong ConditionOptions cua BHT.Core). Gia tri tu do cu giu nguyen.
(setq *bht-conditions* '("Tốt" "Bình thường" "Hư hỏng"))
(defun bht:condition-value (v / t1)
  (setq t1 (bht:trim (bht:str v)))
  (cond ((= t1 "1") "Tốt") ((= t1 "2") "Bình thường") ((= t1 "3") "Hư hỏng")
        ((vl-some '(lambda (c) (if (= (strcase (bht:fold-vi c) T) (strcase (bht:fold-vi t1) T)) c)) *bht-conditions*))
        (T t1))
)

;; Hoi cac truong ho so (dung chung tao/sua).
(defun bht:ask-fields (rec suggest / f grp nmat faces i code)
  (setq grp (bht:ask-group (if (and rec (/= (bht:get rec "nhom") "")) (bht:get rec "nhom") suggest)))
  (setq f (list (cons "nhom" grp)))
  ;; 5.0: coc tieu / cot Km khong co ma bien - mac dinh de trong, khong bat buoc.
  (setq f (append f (list (cons "ma_hieu" (bht:ask-string (if (member grp '("COC_TIEU" "COT_KM"))
                                                            "Mã hiệu (cọc tiêu / cột Km không có mã biển - Enter = để trống)"
                                                            "Mã hiệu (vd 207a; Enter = chưa rõ; ngoài QCVN ghi mã nội bộ)")
                                                          (bht:get rec "ma_hieu"))))))
  (setq code (strcase (bht:ask-string "Loại mã [Q=QCVN/N=Nội bộ/Enter=chưa xác định]" "")))
  (setq f (append f (list (cons "loai_ma" (cond ((= code "Q") "QCVN") ((= code "N") "NOI_BO")
                                                ((/= (bht:get rec "loai_ma") "") (bht:get rec "loai_ma"))
                                                (T "CHUA_XAC_DINH"))))))
  (setq f (append f (list (cons "mo_ta" (bht:ask-string "Mô tả" (bht:get rec "mo_ta"))))))
  (setq f (append f (list (cons "so_tru" (bht:ask-count "Số trụ/cột/chân" (bht:get rec "so_tru"))))))
  (setq nmat (bht:ask-count "Số mặt biển" (bht:get rec "so_mat")))
  (setq f (append f (list (cons "so_mat" nmat))))
  (setq faces nil i 1)
  (if (and (/= nmat "") (> (atoi nmat) 0) (<= (atoi nmat) 20))
    (repeat (atoi nmat)
      (setq faces (append faces (list (bht:ask-string (strcat "  Mã mặt biển " (itoa i) " (Enter = chưa rõ)")
                                                      (if (nth (1- i) (bht:get-all rec "mat")) (nth (1- i) (bht:get-all rec "mat")) ""))))
            i (1+ i))))
  (foreach m faces (setq f (append f (list (cons "mat" m)))))
  (setq f (append f (list (cons "tinh_trang" (bht:condition-value (bht:ask-string "Tình trạng [1=Tốt/2=Bình thường/3=Hư hỏng/hoặc gõ tự do]" (bht:get rec "tinh_trang")))))))
  (setq f (append f (list (cons "phia_duong" (bht:ask-side (bht:get rec "phia_duong"))))))
  (setq code (strcase (bht:ask-string "Đã kiểm tra hiện trường? [C=Có/K=Chưa]" (if (= (bht:get rec "trang_thai_kt") "DA_KIEM_TRA") "C" "K"))))
  (setq f (append f (list (cons "trang_thai_kt" (if (= code "C") "DA_KIEM_TRA" "CHUA_KIEM_TRA")))))
  (setq f (append f (list (cons "ghi_chu" (bht:ask-string "Ghi chú" (bht:get rec "ghi_chu"))))))
  f
)

;; Goi y nhom tu mo ta cac diem.
(defun bht:suggest-group (pids index / p c)
  (setq c nil)
  (foreach pid pids
    (if (and (null c) (setq p (bht:pt-find pid index))
             (/= (bht:pv p 'cls) "CHUA_XAC_DINH"))
      (setq c (bht:pv p 'cls))))
  (if c (car (vl-some '(lambda (g) (if (= (cadr g) c) (list (car g)))) *bht-groups*)) "0")
)

;; 0.3.3: Kiem tra diem da chon truoc khi tao ho so.
;; Tra ve (ho_so_co_diem_chung ho_so_trung_khop_bo_diem).
(defun bht:obj-overlap (pids / up owners hits same s)
  (setq up (mapcar 'strcase pids) owners (bht:pt-owner-map) hits nil same nil)
  (foreach p up (foreach o (cdr (assoc p owners)) (setq hits (bht:unique-add hits o))))
  (foreach o hits
    (setq s (mapcar 'strcase (bht:get-all (bht:obj-read o) "pt")))
    (if (and (= (length s) (length up)) (vl-every '(lambda (x) (member x up)) s))
      (setq same (append same (list o)))))
  (list hits same)
)

;; 1 dong tom tat ho so (dung khi canh bao diem da thuoc ho so khac).
(defun bht:obj-summary (oid pids / rec pts common)
  (setq rec (bht:obj-read oid) pts (mapcar 'strcase (bht:get-all rec "pt")) common nil)
  (foreach p (mapcar 'strcase pids) (if (member p pts) (setq common (append common (list p)))))
  (strcat "  " oid " | nhóm " (bht:group-label (bht:get rec "nhom"))
          (if (/= (bht:get rec "ma_hieu") "") (strcat " | mã " (bht:get rec "ma_hieu")) "")
          (if (/= (bht:get rec "so_tru") "") (strcat " | số trụ " (bht:get rec "so_tru")) "")
          " | " (itoa (length pts)) " điểm (" (bht:join pts ", ") ")"
          " | ảnh " (itoa (length (bht:get-all rec "anh")))
          " | điểm chung: " (bht:join common ", "))
)

;; Hoi va ghi sua ho so (dung chung BHTSUADT va BHTDOITUONG > S).
(defun bht:obj-edit-interactive (id / rec f)
  (setq rec (bht:obj-read id))
  (bht:obj-info id)
  (setq f (bht:ask-fields rec (bht:get rec "nhom")))
  (setq rec (bht:set-all rec "mat" nil))
  (foreach p f
    (if (= (car p) "mat")
      (setq rec (append rec (list p)))
      (setq rec (bht:set rec (car p) (cdr p)))))
  (bht:obj-write id rec)
  (bht:msg (strcat "BHT: đã cập nhật " id "."))
  (bht:symbol-after-change id)
)

;; Sau khi tao/sua ho so: cap nhat ky hieu neu da co; neu chua co thi hoi chen.
(defun bht:symbol-after-change (id / r)
  (if (bht:symbol-exists id)
    (progn (setq r (bht:symbol-sync (list id)))
           (bht:msg (strcat "BHT: đã cập nhật ký hiệu " id " (vị trí người dùng đã đặt được giữ).")))
    (if (= (strcase (bht:ask-string (strcat "Chèn ký hiệu cho " id " ngay? [C/K]") "C")) "C")
      (progn (setq r (bht:symbol-sync (list id)))
             (if (> (cdr (assoc 'created r)) 0)
               (bht:msg (strcat "BHT: đã chèn ký hiệu " id " (layer BHT_KYHIEU)."))
               (bht:warn (strcat "BHT: chưa chèn được ký hiệu " id " (hồ sơ chưa có điểm RTK hợp lệ?)."))))))
)

;;; ----------------------------------------------------------------------
;;; 5.0: kiem tra TRUNG khi tao ho so Coc tieu / Cot Km (CHI doc; khong dich,
;;; khong sua diem RTK). So voi ho so CUNG nhom:
;;;  - dung chung diem RTK (bo qua khi nguoi dung da xac nhan dung chung);
;;;  - vi tri (trung binh diem RTK) cach <= nguong (meta "trung_kc_m", mac dinh 0.5 m);
;;;  - Cot Km: trung gia tri Km (ly_trinh_km, sai lech <= 0.005 m).
;;; Tra ve danh sach (oid "ly do").
;;; ----------------------------------------------------------------------
(defun bht:dup-tolerance (/ v)
  (setq v (bht:num (bht:meta "trung_kc_m" "0.5")))
  (if (and v (> v 0.0) (<= v 100.0)) v 0.5)
)

(defun bht:dup-applies-p (grp) (member (bht:group-code grp) '("COC_TIEU" "COT_KM")))

(defun bht:obj-dup-find (self grp pids km ignore-shared / index tol mine pos out rec theirs shared op d reasons okm mykm g)
  (setq g (bht:group-code grp) out nil)
  (if (bht:dup-applies-p g)
    (progn
      (setq index (bht:pt-all) tol (bht:dup-tolerance) self (strcase (bht:str self))
            mine (mapcar 'strcase pids)
            pos (bht:obj-position (bht:set-all nil "pt" mine) index)
            mykm (if (and (= g "COT_KM") (/= (bht:trim (bht:str km)) "")) (bht:parse-km km) nil))
      (foreach oid (bht:obj-ids)
        (if (/= (strcase oid) self)
          (progn
            (setq rec (bht:obj-read oid))
            (if (and rec (= (bht:group-code (bht:get rec "nhom")) g))
              (progn
                (setq theirs (mapcar 'strcase (bht:get-all rec "pt"))
                      shared (vl-remove-if-not '(lambda (p) (member p mine)) theirs)
                      reasons nil)
                (if (and shared (not ignore-shared))
                  (setq reasons (append reasons (list (strcat "cùng điểm RTK " (bht:join shared ", "))))))
                (if (and pos (null shared) (setq op (bht:obj-position rec index))
                         (<= (setq d (distance (list (car pos) (cadr pos)) (list (car op) (cadr op)))) tol))
                  (setq reasons (append reasons (list (strcat "cách " (bht:fnum d 2) " m (≤ " (bht:fnum tol 2) " m)")))))
                (if (and mykm (setq okm (bht:parse-km (bht:get rec "ly_trinh_km"))) (<= (abs (- okm mykm)) 0.005))
                  (setq reasons (append reasons (list (strcat "trùng Km " (bht:get rec "ly_trinh_km"))))))
                (if reasons (setq out (append out (list (list (strcase oid) (bht:join reasons "; ")))))))))))))
  out
)

;; Hoi xac nhan khi co trung. T = tiep tuc tao, nil = huy (mac dinh).
(defun bht:obj-dup-confirm (grp pids ignore-shared / hits msg)
  (setq hits (bht:obj-dup-find "" grp pids "" ignore-shared))
  (if (null hits)
    T
    (progn
      (setq msg (strcat "BHT: " (bht:group-label (bht:group-code grp)) " mới có thể TRÙNG với: "
                        (bht:join (mapcar '(lambda (h) (strcat (car h) " (" (cadr h) ")")) hits) ", ")
                        ". Ngưỡng " (bht:fnum (bht:dup-tolerance) 2) " m (meta trung_kc_m). Điểm RTK không bị di chuyển hay sửa."))
      (bht:warn msg)
      (if (= (strcase (bht:ask-string "Vẫn tạo hồ sơ trùng? [C=Có/K=Không, hủy]" "K")) "C")
        T
        (progn (bht:msg "BHT: đã hủy - không tạo hồ sơ (trùng).") nil))))
)

;; Tao ho so tu cac diem (hoi truong + chen ky hieu). allow-shared: da xac nhan dung chung.
;; 5.0: Coc tieu / Cot Km -> kiem tra trung truoc khi tao (bht:obj-dup-confirm).
(defun bht:obj-create-interactive (pids allow-shared / index id fields res)
  (setq index (bht:pt-all))
  (setq id (strcase (bht:ask-string "ID đối tượng" (bht:obj-next-id))))
  (setq fields (bht:ask-fields nil (bht:suggest-group pids index)))
  (if (not (bht:obj-dup-confirm (bht:get fields "nhom") pids allow-shared))
    (setq res (list nil "trùng - người dùng hủy"))
    (progn
      (setq res (bht:obj-create id fields pids allow-shared))
      (if (car res)
        (progn
          (bht:msg (strcat "BHT: đã tạo đối tượng " (cadr res) " với " (itoa (length pids)) " điểm RTK."))
          (bht:symbol-after-change (cadr res)))
        (bht:err (strcat "BHT: không tạo được đối tượng: " (cadr res))))))
  res
)

(defun c:BHTDOITUONG (/ *error* pids ov hits same ans tid n)
  (setq *error* bht:on-error)
  (setq pids (bht:select-points "Chọn các điểm RTK thuộc CÙNG MỘT đối tượng (bảng 2 chân = 1 đối tượng): "))
  (if pids
    (progn
      (setq ov (bht:obj-overlap pids) hits (car ov) same (cadr ov))
      (if (null hits)
        (bht:obj-create-interactive pids nil)
        (progn
          (bht:msg "Điểm đã chọn ĐÃ THUỘC hồ sơ đối tượng khác:")
          (foreach o hits (bht:msg (bht:obj-summary o pids)))
          (if same
            (bht:msg (strcat "CẢNH BÁO: bộ điểm đã chọn TRÙNG KHỚP hồ sơ " (bht:join same ", ")
                             " - có thể hồ sơ này đã được tạo rồi.")))
          (setq ans (strcase (bht:ask-string "[X=Xem hồ sơ/S=Sửa hồ sơ/T=Thêm điểm đã chọn vào hồ sơ/M=Tạo hồ sơ MỚI dùng chung điểm/H=Hủy]" "H")))
          (if (member ans '("X" "S" "T"))
            (setq tid (if (= (length hits) 1) (car hits)
                        (strcase (bht:ask-string (strcat "ID hồ sơ (" (bht:join hits ", ") ")") (car hits))))))
          (cond
            ((and (member ans '("X" "S" "T")) (not (bht:obj-read tid)))
             (bht:warn (strcat "BHT: không có hồ sơ " (bht:str tid) ". Không làm gì.")))
            ((= ans "X") (bht:obj-info tid))
            ((= ans "S") (bht:obj-edit-interactive tid))
            ((= ans "T")
             (setq n (bht:obj-add-points tid pids))
             (bht:msg (strcat "BHT: " tid " hiện có " (itoa n) " điểm."))
             (bht:symbol-refresh (list tid)))
            ((= ans "M")
             (if (= (strcase (bht:ask-string (strcat "XÁC NHẬN tạo hồ sơ MỚI dùng chung điểm với " (bht:join hits ", ")
                                                     (if same " (bộ điểm trùng khớp!)" "") "? [C/K]") "K")) "C")
               (bht:obj-create-interactive pids T)
               (bht:msg "BHT: không tạo hồ sơ mới.")))
            (T (bht:msg "BHT: đã hủy - không tạo hồ sơ mới.")))))))
  (bht:log-flush)
  (princ)
)
(defun c:BHTSUADT (/ *error* id)
  (setq *error* bht:on-error)
  (if (setq id (bht:pick-object "Chọn đối tượng cần sửa"))
    (bht:obj-edit-interactive id))
  (bht:log-flush)
  (princ)
)
(defun c:BHTXOADT (/ *error* id ans)
  (setq *error* bht:on-error)
  (if (setq id (bht:pick-object "Chọn đối tượng cần xóa hồ sơ"))
    (progn
      (setq ans (strcase (bht:ask-string (strcat "Xóa hồ sơ " id " (điểm RTK và ảnh giữ nguyên; ký hiệu của hồ sơ bị gỡ)? [C/K]") "K")))
      (if (= ans "C")
        (if (bht:obj-delete id) (bht:msg (strcat "BHT: đã xóa hồ sơ " id "."))))))
  (bht:log-flush)
  (princ)
)
(defun c:BHTTHEMDIEM (/ *error* id pids n ov other)
  (setq *error* bht:on-error)
  (if (setq id (bht:pick-object "Chọn đối tượng cần thêm điểm"))
    (if (setq pids (bht:select-points "Chọn điểm RTK cần thêm: "))
      (progn
        (setq ov (bht:obj-overlap pids) other (vl-remove id (car ov)))
        (if (and other
                 (/= (strcase (bht:ask-string (strcat "Có điểm đã thuộc hồ sơ khác (" (bht:join other ", ")
                                                      "). Vẫn thêm (điểm dùng chung)? [C/K]") "K")) "C"))
          (bht:msg "BHT: không thêm điểm.")
          (if (setq n (bht:obj-add-points id pids))
            (progn (bht:msg (strcat "BHT: " id " hiện có " (itoa n) " điểm."))
                   (bht:symbol-refresh (list id))))))))
  (bht:log-flush)
  (princ)
)

(defun c:BHTBOTDIEM (/ *error* pids owners n cnt touched)
  (setq *error* bht:on-error)
  (setq pids (bht:select-points "Chọn điểm RTK cần gỡ khỏi đối tượng: ") cnt 0 touched nil)
  (if pids
    (progn
      (setq owners (bht:pt-owner-map))
      (foreach p pids
        (foreach o (cdr (assoc p owners))
          (bht:obj-remove-points o (list p))
          (setq touched (bht:unique-add touched o))
          (setq cnt (1+ cnt))))
      (if touched (bht:symbol-refresh touched))
      (bht:msg (strcat "BHT: đã gỡ " (itoa cnt) " liên kết điểm-đối tượng."))))
  (bht:log-flush)
  (princ)
)
