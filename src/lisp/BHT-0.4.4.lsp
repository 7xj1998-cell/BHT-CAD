;;; ======================================================================
;;; BHT-0.4.4.lsp - BHT 0.4.4 (build 2026-09-28)
;;; Quan ly khao sat bao hieu / coc tieu / cot Km / bang va cong trinh ven
;;; tuyen: diem RTK, ho so doi tuong, anh TimeMark (KMZ), tuyen tham chieu,
;;; ly trinh, goi thau / doan tuyen, xuat CSV cho Excel.
;;;
;;; Tiep noi truc tiep BHT 0.3.2 (release\BHT-0.3.2\BHT-0.3.2.lsp, giu nguyen
;;; khong sua) va BHT 0.1 / 0.2.0 / 0.3.x:
;;;  - giu POINT tren layer BHT_RTK + XData "BHT_RTK" (ten, ma) nhu v0.1;
;;;  - ID on dinh, ho so doi tuong, anh, tuyen/moc Km, goi thau (v0.2);
;;;  - bang dieu khien DCL (v0.3).
;;; Muc tieu: AutoCAD 2021-2024, Civil 3D 2023 (Windows). File luu UTF-8,
;;; can LISPSYS = 1 (mac dinh tu AutoCAD 2021) de hien tieng Viet co dau.
;;;
;;; NHAT KY THAY DOI 0.4.4 (chi tiet: CHANGELOG.md)
;;;  + Hop nhat thu vien block vao mot file Lisp duy nhat; khong can nap
;;;    BHT-BIENBAO.lsp rieng.
;;;  + Thu vien bien bao duoc xay dung tu 205 anh trong KMZ DT830, uu tien
;;;    cac mau xuat hien tren tuyen va doi chieu QCVN 41:2024/BGTVT.
;;;  + Tu chon block bien bao theo ma hieu cua ho so (W.207, W.209, W.239a,
;;;    W.245a, R.412, I.414, I.423a, I.428a, I.434a, P.115, P.119,
;;;    P.124a, P.125, P.127); diem chen cua moi block la chan cot (0,0).
;;;  + BHTBBDANHMUC liet ke thu vien chuan; BHTBLOCK > D mo cung danh muc.
;;;
;;; NHAT KY THAY DOI 0.4.3
;;;  + BTH / BHT mo mot Palette .NET duy nhat; Lisp tu nap DLL cung thu muc.
;;;  + DCL chi con la giao dien du phong BHTDCL, khong mo trong luong thuong.
;;;  + File DCL tam ghi UTF-8 BOM de AutoCAD 2024 doc dung tieng Viet.
;;;  + POINT mac dinh dau X kich thuoc 1; bo tri nhan 8 huong x 8 ban kinh.
;;;  + BHTBLOCK nap DWG ky hieu tuy chon theo nhom, INSBASE la tam chen.
;;;  + Nhan ky hieu hien ten nghiep vu + ma/ly trinh; ID noi bo chi o XData.
;;;  + Block coc tieu / cot Km theo mau; Palette co mau va thong bao tai cho.
;;;
;;; NHAT KY THAY DOI 0.4.0
;;;  + Ham API bht:api-* (dang ky vl-acad-defun) cho plugin .NET BHT.Palette:
;;;    thong tin (giong BHTINFO), ky hieu, nhan, ky hieu anh, kiem tra, thu tu
;;;    hien thi, duong dan JPG. Lisp khong phu thuoc palette; BHT van mo DCL.
;;;  + BHTPALETTE (khi chua NETLOAD BHT.Palette.dll): huong dan nap plugin.
;;;  = Du lieu DWG (dictionary BHT_V02 / XRecord / XData) giu nguyen dinh dang
;;;    0.3.3; ban ve 0.3.2 / 0.3.3 mo binh thuong.
;;;
;;; NHAT KY THAY DOI 0.3.3
;;;  + Nhan diem RTK: bo tri tranh chong lap (8 huong x 4 ban kinh, hop bao
;;;    textbox, tranh nhan khac / ky hieu / ky hieu anh / diem), sap xep lai
;;;    theo pham vi (vung chon / danh sach ID / tat ca) - BHTSAPNHAN;
;;;    nhan bi nguoi dung doi cho duoc nhan ra (XData luu vi tri tu dong) va
;;;    giu nguyen o lan cap nhat sau; BHTNHANTUDONG tra ve vi tri tu dong.
;;;    Che do "uu tien ho so": an nhan phu (mo ta, cao do, ID) cua diem da
;;;    thuoc ho so doi tuong.
;;;  + BHTDOITUONG: diem da thuoc ho so khac -> hien ho so, cho chon xem /
;;;    sua / them diem / tao moi dung chung (phai xac nhan); mac dinh HUY.
;;;    Phat hien bo diem trung khop ho so da co.
;;;  + BHTKYHIEU: cap nhat theo object_id (tao thieu, sua thay doi, chi xoa
;;;    ky hieu cua ho so da xoa), giu vi tri / goc / ty le nguoi dung da dat.
;;;  + BHTTHUTUVE: thu tu hien thi nhan > ky hieu/diem/ky hieu anh > raster
;;;    BHT > anh nen IRT (chi anh nhan dien chac chan; chi dua xuong duoi).
;;;  + Duong dan tu ky hieu anh toi raster (tuy chon). Canh bao nhap cung du
;;;    lieu bang ca CSV va TSV. Bang dieu khien: muc bao tri du lieu cu.
;;;  * SUA LOI (co tu 0.1): chay BHT khi dang o tab Layout thi diem / nhan /
;;;    ky hieu bi tao trong paper space. Tu 0.3.3 luon tao trong Model;
;;;    -IMAGE / DRAWORDER tam chuyen sang Model. BHTVEMODEL chuyen thuc the BHT
;;;    da lo tao trong Layout ve Model (giu toa do + XData), BHTKT canh bao.
;;;  * BHTTHUMUCANH: thu muc nguoi dung chi dinh duoc uu tien hon thu muc goc.
;;;
;;; Quy uoc bat buoc:
;;;  - CSV nguon: ten diem, Northing (Bac), Easting (Dong), Z, mo ta; khong
;;;    tieu de. CAD: X = Easting, Y = Northing, Z = cao do. Khong lam tron,
;;;    khong hoan doi; chuoi goc duoc luu nguyen van trong XData.
;;;  - Mot diem RTK khong phai mot bien. Doi tuong (object) co ID rieng,
;;;    gom nhieu diem RTK, nhieu anh, so tru va so mat bien tach rieng.
;;;  - GPS anh chi la vi tri chup; ghep anh tu dong chi la DE XUAT.
;;;  - Khong dung vlax-curve-* / bounding box tren proxy TDT (TDTDBALIGNMENT).
;;;    Ly trinh chi tinh tren Polyline tham chieu + moc Km da xac nhan.
;;;  - Khong suy goi thau tu ten DWG; dung bang BHT_GOI_THAU.tsv (tu xlsx).
;;;  - Nhan / ky hieu chi cap nhat-xoa thuc the mang XData BHT tuong ung.
;;;  - KHONG BAO GIO di chuyen POINT RTK (ke ca khi bo tri nhan).
;;; ======================================================================

(vl-load-com)

(setq *bht-version* "0.4.4")
(setq *bht-build* "2026-09-28")

;; Luu duong dan ngay khi APPLOAD / Application Bundle nap Lisp. DLL dat canh
;; file Lisp de nguoi dung chi can APPLOAD mot lan, khong phai tu NETLOAD.
(setq *bht-lsp-file* (findfile "BHT-0.4.4.lsp"))
(setq *bht-lsp-dir*
  (if *bht-lsp-file* (vl-filename-directory *bht-lsp-file*) nil))
(setq *bht-palette-dll*
  (if *bht-lsp-dir* (strcat *bht-lsp-dir* "\\BHT.Palette.dll") nil))

;;; ----------------------------------------------------------------------
;;; Chuoi / so
;;; ----------------------------------------------------------------------

(defun bht:trim (s)
  (vl-string-trim " \t\r\n" (if s s ""))
)

(defun bht:str (v)
  (cond ((null v) "")
        ((= (type v) 'STR) v)
        ((= (type v) 'INT) (itoa v))
        ((= (type v) 'REAL) (bht:fnum v 3))
        (T (vl-princ-to-string v)))
)

;; Tach chuoi theo mot ky tu phan cach (giu truong rong).
(defun bht:split (s sep / out pos start)
  (setq out nil start 0)
  (if (null s) (setq s ""))
  (while (setq pos (vl-string-search sep s start))
    (setq out (cons (substr s (1+ start) (- pos start)) out)
          start (+ pos (strlen sep))))
  (reverse (cons (substr s (1+ start)) out))
)

(defun bht:join (items separator / out first)
  (setq out "" first T)
  (foreach item items
    (setq out (strcat out (if first "" separator) (bht:str item))
          first nil))
  out
)

(defun bht:replace (s old new / pos out)
  (setq out "")
  (while (setq pos (vl-string-search old s))
    (setq out (strcat out (substr s 1 pos) new)
          s (substr s (+ pos 1 (strlen old)))))
  (strcat out s)
)

;; Bo tab/xuong dong (dung cho TSV, XData).
(defun bht:clean (s)
  (setq s (bht:str s))
  (setq s (bht:replace s "\t" " "))
  (setq s (bht:replace s "\r" " "))
  (bht:replace s "\n" " ")
)

(defun bht:starts (s prefix)
  (and s prefix (>= (strlen s) (strlen prefix))
       (= (strcase (substr s 1 (strlen prefix))) (strcase prefix)))
)

(defun bht:pad0 (n width / s)
  (setq s (itoa n))
  (while (< (strlen s) width) (setq s (strcat "0" s)))
  s
)

;; So tu chuoi: tra ve REAL hoac nil. Chi chap nhan so thap phan dau cham.
(defun bht:num (s / v i c ok)
  (setq s (bht:trim s) ok (/= s "") i 1)
  (while (and ok (<= i (strlen s)))
    (setq c (substr s i 1))
    (if (not (or (and (>= c "0") (<= c "9")) (member c '("." "-" "+" "e" "E"))))
      (setq ok nil))
    (setq i (1+ i)))
  (if ok
    (progn
      (setq v (vl-catch-all-apply 'distof (list s 2)))
      (if (and v (not (vl-catch-all-error-p v))) (float v) nil))
    nil)
)

(defun bht:int (s / v)
  (setq v (bht:num s))
  (if v (fix v) nil)
)

;; Dinh dang so thap phan KHONG phu thuoc DIMZIN/LUNITS.
(defun bht:fnum (x dec / neg ip fp scale fs)
  (if (null x)
    ""
    (progn
      (setq x (float x) neg (< x 0.0) x (abs x)
            scale (expt 10.0 dec)
            ip (fix x)
            fp (fix (+ (* (- x ip) scale) 0.5)))
      (if (>= fp (fix scale)) (setq ip (1+ ip) fp 0))
      (setq fs (if (> dec 0) (strcat "." (bht:pad0 fp dec)) ""))
      (if (and neg (or (> ip 0) (> fp 0)))
        (strcat "-" (itoa ip) fs)
        (strcat (itoa ip) fs))))
)

;; Ly trinh (m) -> "Km39+050.00"
(defun bht:fmt-km (s / neg km m ms)
  (if (null s)
    ""
    (progn
      (setq neg (< s 0.0) s (abs s)
            s (/ (fix (+ (* s 100.0) 0.5)) 100.0)
            km (fix (/ s 1000.0))
            m (- s (* km 1000.0)))
      (if (< m 0.0) (setq m 0.0))
      (setq ms (bht:fnum m 2))
      (while (< (strlen ms) 6) (setq ms (strcat "0" ms)))
      (strcat (if neg "-" "") "Km" (itoa km) "+" ms)))
)

;; "Km39+050.5" / "39+050" / "39050" -> 39050.5 ; nil neu sai.
(defun bht:parse-km (s / u pos a b)
  (setq u (strcase (bht:replace (bht:trim s) " " "")))
  (if (bht:starts u "KM") (setq u (substr u 3)))
  (cond
    ((= u "") nil)
    ((setq pos (vl-string-search "+" u))
     (setq a (bht:num (substr u 1 pos)) b (bht:num (substr u (+ pos 2))))
     (if (and a b (= a (fix a)) (>= b 0.0)) (+ (* a 1000.0) b) nil))
    (T (bht:num u)))
)

;; ID hop le: A-Z 0-9 _ - . (khong dau cach), toi da 60 ky tu.
(defun bht:valid-id (s / i c ok)
  (setq ok (and s (> (strlen s) 0) (<= (strlen s) 60)) i 1)
  (while (and ok (<= i (strlen s)))
    (setq c (substr s i 1))
    (if (not (or (and (>= c "A") (<= c "Z")) (and (>= c "0") (<= c "9"))
                 (member c '("_" "-" "."))))
      (setq ok nil))
    (setq i (1+ i)))
  ok
)

(defun bht:now (/ s parts d f)
  (setq s (rtos (getvar "CDATE") 2 6)
        parts (bht:split s ".")
        d (car parts)
        f (if (cadr parts) (cadr parts) ""))
  (while (< (strlen f) 6) (setq f (strcat f "0")))
  (strcat (substr d 1 4) "-" (substr d 5 2) "-" (substr d 7 2) " "
          (substr f 1 2) ":" (substr f 3 2) ":" (substr f 5 2))
)

(defun bht:unique-add (items value)
  (if (member value items) items (append items (list value)))
)

(defun bht:nthcdr (n lst)
  (repeat n (setq lst (cdr lst)))
  lst
)

;; Sap xep chuoi tang dan.
(defun bht:sort-str (lst)
  (mapcar '(lambda (i) (nth i lst)) (vl-sort-i lst '<))
)

;;; ----------------------------------------------------------------------
;;; CSV
;;; ----------------------------------------------------------------------

(defun bht:csv-fields (line / i c quoted field fields n)
  (setq i 1 quoted nil field "" fields nil n (strlen line))
  (while (<= i n)
    (setq c (substr line i 1))
    (cond
      ((= c "\"")
       (if (and quoted (< i n) (= (substr line (1+ i) 1) "\""))
         (setq field (strcat field "\"") i (1+ i))
         (setq quoted (not quoted))))
      ((and (= c ",") (not quoted))
       (setq fields (cons field fields) field ""))
      (T (setq field (strcat field c))))
    (setq i (1+ i)))
  (reverse (cons field fields))
)

(defun bht:csv-cell (value / s)
  (setq s (bht:str value))
  (if (or (vl-string-search "," s) (vl-string-search "\"" s)
          (vl-string-search "\n" s) (vl-string-search "\r" s)
          (vl-string-search ";" s))
    (strcat "\"" (bht:replace s "\"" "\"\"") "\"")
    s)
)

(defun bht:csv-line (values)
  (bht:join (mapcar 'bht:csv-cell values) ",")
)

;; Bo ky tu BOM (U+FEFF) o dau dong neu co.
(defun bht:strip-bom (s)
  (if (and s (> (strlen s) 0) (= (ascii (substr s 1 1)) 65279))
    (substr s 2)
    s)
)

;; Mo file ghi UTF-8 co BOM (Excel doc dung tieng Viet); du phong utf8.
(defun bht:open-write-bom (path / f)
  (setq f (vl-catch-all-apply 'open (list path "w" "utf8-bom")))
  (if (or (null f) (vl-catch-all-error-p f))
    (setq f (vl-catch-all-apply 'open (list path "w" "utf8"))))
  (if (or (null f) (vl-catch-all-error-p f)) nil f)
)

(defun bht:open-write-utf8 (path / f)
  (setq f (vl-catch-all-apply 'open (list path "w" "utf8")))
  (if (or (null f) (vl-catch-all-error-p f)) nil f)
)

(defun bht:read-lines (path / f line out)
  (if (setq f (open path "r"))
    (progn
      (while (setq line (read-line f)) (setq out (cons line out)))
      (close f)
      (setq out (reverse out))
      (if out (setq out (cons (bht:strip-bom (car out)) (cdr out))))
      out)
    nil)
)

(defun bht:file-exists (path)
  (and path (/= path "") (or (vl-file-size path) (findfile path)))
)

(defun bht:slash (dir)
  (if (or (= dir "") (member (substr dir (strlen dir)) '("\\" "/")))
    dir
    (strcat dir "\\"))
)

(defun bht:dwg-folder ()
  (bht:slash (getvar "DWGPREFIX"))
)

;;; ----------------------------------------------------------------------
;;; Nhat ky
;;; ----------------------------------------------------------------------

(setq *bht-log-lines* nil)

(setq *bht-screen-messages* nil)

;; Moi thong bao nghiep vu van hien o dong lenh va dong thoi duoc giu lai de
;; Palette doc sau khi lenh ket thuc. Gioi han 40 dong de khong phinh bo nho.
(defun bht:screen-message-add (s)
  (setq *bht-screen-messages* (cons (bht:str s) *bht-screen-messages*))
  (if (> (length *bht-screen-messages*) 40)
    (setq *bht-screen-messages* (reverse (cdr (reverse *bht-screen-messages*)))))
  s
)

(defun bht:msg (s)
  (bht:screen-message-add s)
  (princ (strcat "\n" s))
)

(defun bht:log (s)
  (setq *bht-log-lines* (cons (strcat (bht:now) "  " s) *bht-log-lines*))
)

;; Ghi nhat ky tich luy vao <thu muc DWG>\BHT_LOG\BHT_<ngay>.log (noi tiep).
(defun bht:log-flush (/ dir path f)
  (if *bht-log-lines*
    (progn
      (setq dir (strcat (bht:dwg-folder) "BHT_LOG"))
      (vl-mkdir dir)
      (setq path (strcat dir "\\BHT_" (substr (bht:replace (bht:now) "-" "") 1 8) ".log"))
      (setq f (vl-catch-all-apply 'open (list path "a" "utf8")))
      (if (and f (not (vl-catch-all-error-p f)))
        (progn
          (foreach l (reverse *bht-log-lines*) (write-line l f))
          (close f)
          (setq *bht-log-lines* nil)
          path)
        nil)))
)

(defun bht:on-error (msg)
  (bht:sv-restore)
  (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*BREAK*,*EXIT*")))
    (bht:msg (strcat "BHT lỗi: " msg))
    (bht:msg "BHT: lệnh bị hủy. Dữ liệu đã ghi trước đó được giữ; chạy lại lệnh để hoàn tất (không tạo trùng)."))
  (bht:log-flush)
  (princ)
)

;;; ----------------------------------------------------------------------
;;; XData
;;; ----------------------------------------------------------------------

(defun bht:regapp (name)
  (if (not (tblsearch "APPID" name)) (regapp name))
)

(defun bht:xget (ent app / rec)
  (setq rec (assoc -3 (entget ent (list app))))
  (if rec (mapcar 'cdr (cdadr rec)) nil)
)

(defun bht:xset (ent app strings / data)
  (bht:regapp app)
  (setq data (entget ent))
  (if (entmod (append data (list (list -3 (cons app (mapcar '(lambda (s) (cons 1000 (bht:str s))) strings))))))
    (progn (entupd ent) T)
    nil)
)

(defun bht:xclear (ent app / data)
  (if (and ent (bht:xget ent app))
    (progn
      (setq data (entget ent))
      (if (entmod (append data (list (list -3 (list app)))))
        (progn (entupd ent) T) nil))
    nil)
)

;; Chia chuoi dai thanh cac doan <= n ky tu (XData 1000 gioi han 255 byte).
(defun bht:chunks (s n / out)
  (setq out nil)
  (while (> (strlen s) n)
    (setq out (cons (substr s 1 n) out) s (substr s (1+ n))))
  (reverse (cons s out))
)

;;; ----------------------------------------------------------------------
;;; Kho du lieu trong DWG: Named Object Dictionary "BHT_V02"
;;; Moi ban ghi = XRECORD, cac truong (1 . "khoa=gia tri"), gia tri dai
;;; duoc noi bang (1 . "khoa+=phan tiep").
;;; ----------------------------------------------------------------------

(defun bht:new-dict (/ e)
  (entmakex '((0 . "DICTIONARY") (100 . "AcDbDictionary")))
)

(defun bht:dict-root (/ d e)
  (if (setq d (dictsearch (namedobjdict) "BHT_V02"))
    (cdr (assoc -1 d))
    (progn (setq e (bht:new-dict)) (dictadd (namedobjdict) "BHT_V02" e) e))
)

(defun bht:subdict (name / root d e)
  (setq root (bht:dict-root))
  (if (setq d (dictsearch root name))
    (cdr (assoc -1 d))
    (progn (setq e (bht:new-dict)) (dictadd root name e) e))
)

(defun bht:rec-encode (rec / out k v parts first)
  (setq out nil)
  (foreach p rec
    (setq k (car p) v (bht:str (cdr p)) parts (bht:chunks v 200) first T)
    (foreach part parts
      (setq out (cons (cons 1 (strcat k (if first "=" "+=") part)) out)
            first nil)))
  (reverse out)
)

(defun bht:rec-decode (data / out s pos k v)
  (setq out nil)
  (foreach g data
    (if (= (car g) 1)
      (progn
        (setq s (cdr g) pos (vl-string-search "=" s))
        (if pos
          (progn
            (setq k (substr s 1 pos) v (substr s (+ pos 2)))
            (if (and (> (strlen k) 1) (= (substr k (strlen k)) "+") out)
              (setq out (cons (cons (car (car out)) (strcat (cdr (car out)) v)) (cdr out)))
              (setq out (cons (cons k v) out))))))))
  (reverse out)
)

(defun bht:rec-read (dname key / d)
  (setq d (dictsearch (bht:subdict dname) (strcase key)))
  (if d (bht:rec-decode d) nil)
)

(defun bht:xrec-make (rec)
  (entmakex (append '((0 . "XRECORD") (100 . "AcDbXrecord") (280 . 1)) (bht:rec-encode rec)))
)

;; Ghi ban ghi AN TOAN (0.3.2): tao XRECORD moi TRUOC; chi khi tao duoc moi
;; doi ten ban cu -> gan ban moi -> xoa ban cu. Loi o bat ky buoc nao: giu ban cu.
(defun bht:rec-write (dname key rec / sd old xr bak)
  (setq sd (bht:subdict dname) key (strcase key) bak (strcat key "__BHT_CU"))
  (if (dictsearch sd bak) (progn (setq old (dictremove sd bak)) (if old (entdel old))))
  (setq old nil xr (bht:xrec-make rec))
  (cond
    ((null xr)
     (bht:log (strcat "LỖI ghi bản ghi " dname "/" key ": không tạo được XRECORD mới - GIỮ NGUYÊN bản cũ"))
     nil)
    (T
     (if (dictsearch sd key)
       (progn (setq old (cdr (assoc -1 (dictsearch sd key)))) (dictrename sd key bak)))
     (if (dictadd sd key xr)
       (progn (if old (progn (dictremove sd bak) (entdel old))) xr)
       (progn
         (if old (dictrename sd bak key))
         (entdel xr)
         (bht:log (strcat "LỖI gắn bản ghi " dname "/" key " - GIỮ NGUYÊN bản cũ"))
         nil))))
)

(defun bht:rec-delete (dname key / sd old)
  (setq sd (bht:subdict dname) key (strcase key))
  (if (dictsearch sd key)
    (progn (setq old (dictremove sd key)) (if old (entdel old)) T)
    nil)
)

(defun bht:rec-keys (dname / out)
  (setq out nil)
  (foreach g (entget (bht:subdict dname))
    (if (and (= (car g) 3) (not (wcmatch (cdr g) "*__BHT_CU"))) (setq out (cons (cdr g) out))))
  (reverse out)
)

(defun bht:rec-all (dname)
  (mapcar '(lambda (k) (cons k (bht:rec-read dname k))) (bht:rec-keys dname))
)

(defun bht:get (rec key / p)
  (setq p (assoc key rec))
  (if p (cdr p) "")
)

(defun bht:get-all (rec key / out)
  (setq out nil)
  (foreach p rec (if (= (car p) key) (setq out (cons (cdr p) out))))
  (reverse out)
)

(defun bht:set (rec key value / out done)
  (setq out nil done nil)
  (foreach p rec
    (if (= (car p) key)
      (if (not done) (setq out (cons (cons key (bht:str value)) out) done T))
      (setq out (cons p out))))
  (if (not done) (setq out (cons (cons key (bht:str value)) out)))
  (reverse out)
)

(defun bht:set-all (rec key values / out)
  (setq out nil)
  (foreach p rec (if (/= (car p) key) (setq out (cons p out))))
  (setq out (reverse out))
  (foreach v values (setq out (append out (list (cons key (bht:str v))))))
  out
)

;; Cau hinh chung (META).
(defun bht:meta (key default / v)
  (setq v (bht:get (bht:rec-read "META" "CONFIG") key))
  (if (= v "") default v)
)

(defun bht:meta-set (key value / rec)
  (setq rec (bht:rec-read "META" "CONFIG"))
  (bht:rec-write "META" "CONFIG" (bht:set rec key value))
)

;; Kieu POINT BHT: dau X co tam trung chinh xac voi toa do DXF 10.
;; PDSIZE duong la kich thuoc tuyet doi theo don vi ban ve (mac dinh 1 unit).
(defun bht:point-size (/ s)
  (setq s (bht:num (bht:meta "pt_size" "1.0")))
  (if (and s (> s 0.0)) s 1.0)
)

(defun bht:point-style-apply (size arrange / s r app doc)
  (setq s (if (and size (> size 0.0)) size (bht:point-size)))
  (if (and size (> size 0.0)) (bht:meta-set "pt_size" (bht:fnum s 3)))
  (setvar "PDMODE" 3)
  (setvar "PDSIZE" s)
  (setq app (vl-catch-all-apply 'vlax-get-acad-object nil)
        doc (if (vl-catch-all-error-p app) nil
              (vl-catch-all-apply 'vla-get-ActiveDocument (list app))))
  (if (and doc (not (vl-catch-all-error-p doc)))
    (vl-catch-all-apply 'vla-Regen (list doc 1))) ; acAllViewports
  (setq r (if arrange (bht:lbl-sync-scope 'ALL) nil))
  (list (cons 'pdmode 3) (cons 'pdsize s)
        (cons 'labels (if r (cdr (assoc 'total r)) 0)))
)

;;; ----------------------------------------------------------------------
;;; Layer / Block
;;; ----------------------------------------------------------------------

(defun bht:layer (name color)
  (if (not (tblsearch "LAYER" name))
    (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord")
                   '(100 . "AcDbLayerTableRecord") (cons 2 name) '(70 . 0)
                   (cons 62 color) '(6 . "Continuous"))))
  name
)

(defun bht:block (name geoms)
  (if (not (tblsearch "BLOCK" name))
    (progn
      (entmake (list '(0 . "BLOCK") (cons 2 name) '(70 . 0) '(10 0.0 0.0 0.0)))
      (foreach g geoms (entmake g))
      (entmake '((0 . "ENDBLK")))))
  name
)

(defun bht:line-g (a b) (list '(0 . "LINE") '(8 . "0") '(62 . 0) (cons 10 a) (cons 11 b)))
(defun bht:circle-g (c r) (list '(0 . "CIRCLE") '(8 . "0") '(62 . 0) (cons 10 c) (cons 40 r)))
(defun bht:line-color-g (a b color) (list '(0 . "LINE") '(8 . "0") (cons 62 color) (cons 10 a) (cons 11 b)))
(defun bht:solid-g (a b c d color)
  (list '(0 . "SOLID") '(8 . "0") (cons 62 color) (cons 10 a) (cons 11 b) (cons 12 c) (cons 13 d)))
(defun bht:text-color-g (s p h color)
  (list '(0 . "TEXT") '(8 . "0") (cons 62 color) (cons 10 p) (cons 40 h) (cons 1 s) '(50 . 0.0)))

;; TEXT can giua theo ca hai truc. Dung cho noi dung ngan ben trong mat bien.
(defun bht:text-center-color-g (s p h color)
  (list '(0 . "TEXT") '(8 . "0") (cons 62 color) (cons 10 p) (cons 11 p)
        (cons 40 h) (cons 1 s) '(50 . 0.0) '(72 . 1) '(73 . 2)))

;; Hinh tron to mau bang cac tam giac SOLID; n >= 8. Entity tao sau nam tren
;; entity tao truoc, cho phep ghep dia mau thanh vong tron co vien.
(defun bht:disc-g (c r n color / out i a1 a2 p1 p2)
  (setq out nil i 0)
  (repeat n
    (setq a1 (* 2.0 pi (/ (* 1.0 i) n))
          a2 (* 2.0 pi (/ (* 1.0 (1+ i)) n))
          p1 (list (+ (car c) (* r (cos a1))) (+ (cadr c) (* r (sin a1))) (caddr c))
          p2 (list (+ (car c) (* r (cos a2))) (+ (cadr c) (* r (sin a2))) (caddr c))
          out (cons (bht:solid-g c p1 p2 p2 color) out)
          i (1+ i)))
  (reverse out)
)

(defun bht:rect-fill-g (x1 y1 x2 y2 color)
  (bht:solid-g (list x1 y1 0.0) (list x2 y1 0.0)
               (list x1 y2 0.0) (list x2 y2 0.0) color)
)

(defun bht:poly-g (pts / out i)
  (setq out nil i 0)
  (while (< i (length pts))
    (setq out (cons (bht:line-g (nth i pts) (nth (rem (1+ i) (length pts)) pts)) out)
          i (1+ i)))
  out
)

(defun bht:poly-color-g (pts color / out i)
  (setq out nil i 0)
  (while (< i (length pts))
    (setq out (cons (bht:line-color-g (nth i pts) (nth (rem (1+ i) (length pts)) pts) color) out)
          i (1+ i)))
  (reverse out)
)

(defun bht:insert (blk pt layer scale / )
  (entmakex (list '(0 . "INSERT") '(410 . "Model") (cons 2 blk) (cons 8 layer) (cons 10 pt)
                  (cons 41 scale) (cons 42 scale) (cons 43 scale) '(50 . 0.0)))
)

(defun bht:text (str pt h layer)
  (entmakex (list '(0 . "TEXT") '(410 . "Model") (cons 8 layer) (cons 10 pt) (cons 40 h)
                  (cons 1 str) '(50 . 0.0)))
)

;;; ----------------------------------------------------------------------
;;; 0.3.2: bien he thong, kieu chu, layer bat/tat, tra cuu thuc the BHT
;;; ----------------------------------------------------------------------

(setq *bht-sv-saved* nil)
(setq *bht-test-abort-after* nil)
(setq *bht-test-ticks* 0)
(setq *bht-no-launch* nil)

;; Doi bien he thong va nho gia tri cu (khoi phuc bang bht:sv-restore / *error*).
(defun bht:sv-set (name value)
  (if (not (assoc name *bht-sv-saved*))
    (setq *bht-sv-saved* (cons (cons name (getvar name)) *bht-sv-saved*)))
  (vl-catch-all-apply 'setvar (list name value))
)

(defun bht:sv-restore ()
  (foreach p *bht-sv-saved* (vl-catch-all-apply 'setvar (list (car p) (cdr p))))
  (setq *bht-sv-saved* nil)
)

;; Diem ngat dung cho kiem thu huy lenh giua chung (binh thuong khong lam gi).
(defun bht:test-tick ()
  (setq *bht-test-ticks* (1+ *bht-test-ticks*))
  (if (and *bht-test-abort-after* (>= *bht-test-ticks* *bht-test-abort-after*))
    (progn (setq *bht-test-abort-after* nil) (exit)))
)

;; Kieu chu TrueType hien tieng Viet. Tra ve ten kieu dung duoc.
(defun bht:text-style (name)
  (if (or (null name) (= name "")) (setq name "BHT_ARIAL"))
  (if (and (= (strcase name) "BHT_ARIAL") (not (tblsearch "STYLE" name)))
    (entmake (list '(0 . "STYLE") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbTextStyleTableRecord")
                   (cons 2 name) '(70 . 0) '(40 . 0.0) '(41 . 1.0) '(50 . 0.0) '(71 . 0)
                   '(42 . 1.0) '(3 . "arial.ttf") '(4 . ""))))
  (if (tblsearch "STYLE" name) name "Standard")
)

;; Bat/tat layer (mau am = tat). Khong dong bang, khong xoa thuc the.
(defun bht:layer-on (name on / e d c)
  (if (setq e (tblobjname "LAYER" name))
    (progn
      (setq d (entget e) c (cdr (assoc 62 d)))
      (if (and c (/= (> c 0) (if on T nil)))
        (entmod (subst (cons 62 (if on (abs c) (- (abs c)))) (assoc 62 d) d)))
      T)
    nil)
)

(defun bht:layer-is-on (name / e)
  (and (setq e (tblobjname "LAYER" name)) (> (cdr (assoc 62 (entget e))) 0))
)

;; Thay/them 1 ma DXF trong danh sach entget.
(defun bht:dxf-put (d code val)
  (if (assoc code d)
    (subst (cons code val) (assoc code d) d)
    (append d (list (cons code val))))
)

;; (khoa . ename) cua cac thuc the loai etype mang XData app.
;; khoa = chuoi XData thu nhat (nkey = 1) hoac "thu1|thu2" (nkey = 2), viet hoa.
(defun bht:tagged-pairs (etype app nkey / ss i ent x out k)
  (setq out nil i 0 ss (ssget "_X" (list (cons 0 etype) (list -3 (list app)))))
  (if ss
    (while (< i (sslength ss))
      (setq ent (ssname ss i) x (bht:xget ent app))
      (if (and x (>= (length x) nkey))
        (progn
          (setq k (strcase (car x)))
          (if (= nkey 2) (setq k (strcat k "|" (strcase (cadr x)))))
          (setq out (cons (cons k ent) out))))
      (setq i (1+ i))))
  out
)

;; Gom cap (khoa . ename) thanh ((khoa e1 e2 ...) ...).
(defun bht:group-pairs (pairs / sorted out cur)
  (setq sorted (vl-sort pairs '(lambda (a b) (< (car a) (car b)))) out nil cur nil)
  (foreach p sorted
    (if (and cur (= (car cur) (car p)))
      (setq cur (append cur (list (cdr p))))
      (progn (if cur (setq out (cons cur out))) (setq cur (list (car p) (cdr p))))))
  (if cur (setq out (cons cur out)))
  out
)

(defun bht:file-ok (p / s)
  (and p (= (type p) 'STR) (/= p "") (setq s (vl-file-size p)) (> s 0))
)

;;; ----------------------------------------------------------------------
;;; Phan loai goi y tu mo ta may do (KHONG phai ma QCVN; chi la goi y).
;;; ----------------------------------------------------------------------

(setq *bht-groups*
  '(("1" "BIEN_BAO"      "Biển báo")
    ("2" "COC_TIEU"      "Cọc tiêu")
    ("3" "COT_KM"        "Cột Km")
    ("4" "BANG_CHI_DAN"  "Bảng chỉ dẫn")
    ("5" "BANG_QC"       "Bảng quảng cáo")
    ("6" "DEN"           "Đèn chiếu sáng / tín hiệu")
    ("7" "CONG_TRINH"    "Công trình ven tuyến")
    ("8" "KHAC"          "Khác")
    ("0" "CHUA_XAC_DINH" "Chưa xác định")))

(defun bht:group-code (s / u hit)
  (setq u (strcase (bht:trim s)) hit nil)
  (foreach g *bht-groups*
    (if (or (= u (car g)) (= u (cadr g))) (setq hit (cadr g))))
  hit
)

(defun bht:group-label (code / hit)
  (setq hit (vl-some '(lambda (g) (if (= (cadr g) code) (caddr g))) *bht-groups*))
  (if hit hit code)
)

;; Quy tac: tien to mo ta (khong phan biet hoa/thuong). Thu tu quan trong.
(setq *bht-class-rules*
  '(("bbqc" "BANG_QC") ("bb.qc" "BANG_QC") ("bangqc" "BANG_QC") ("pano" "BANG_QC")
    ("cockm" "COT_KM") ("cotkm" "COT_KM") ("coc.km" "COT_KM")
    ("coctiu" "COC_TIEU") ("coctieu" "COC_TIEU") ("c.tiu" "COC_TIEU") ("c.tieu" "COC_TIEU")
    ("bangcd" "BANG_CHI_DAN") ("bb" "BIEN_BAO") ("b.cn" "BIEN_BAO")
    ("dentinhieu" "DEN") ("dengt" "DEN") ("truden" "DEN") ("dendg" "DEN") ("đendg" "DEN")))

(defun bht:classify (desc / d hit)
  (setq d (bht:trim desc) hit nil)
  (foreach r *bht-class-rules*
    (if (and (null hit) (bht:starts d (car r))) (setq hit (cadr r))))
  (if hit hit "CHUA_XAC_DINH")
)

;;; ----------------------------------------------------------------------
;;; Diem RTK: POINT layer BHT_RTK
;;;  XData "BHT_RTK" (tuong thich v0.1): ten diem, mo ta (<=80 ky tu dau)
;;;  XData "BHT_PT" (v0.2): id, dataset, dong, ten, N goc, E goc, Z goc,
;;;        phan loai goi y, file nguon, thoi diem nhap, <cac doan mo ta goc>
;;; ----------------------------------------------------------------------

(setq *bht-pt-layer* "BHT_RTK")

(defun bht:pt-from-ent (ent / x loc)
  (setq x (bht:xget ent "BHT_PT"))
  (if (and x (>= (length x) 10))
    (progn
      (setq loc (cdr (assoc 10 (entget ent))))
      (list (cons 'id (nth 0 x)) (cons 'ds (nth 1 x)) (cons 'row (nth 2 x))
            (cons 'name (nth 3 x)) (cons 'n (nth 4 x)) (cons 'e (nth 5 x))
            (cons 'z (nth 6 x)) (cons 'cls (nth 7 x)) (cons 'src (nth 8 x))
            (cons 'time (nth 9 x))
            (cons 'desc (apply 'strcat (cons "" (bht:nthcdr 10 x))))
            (cons 'ent ent) (cons 'xyz loc)))
    nil)
)

(defun bht:pv (p key) (cdr (assoc key p)))

;; Danh sach tat ca diem v0.2 trong DWG: ((id . p) ...)
(defun bht:pt-all (/ ss i p out)
  (setq out nil i 0
        ss (ssget "_X" (list '(0 . "POINT") '(-3 ("BHT_PT")))))
  (if ss
    (while (< i (sslength ss))
      (if (setq p (bht:pt-from-ent (ssname ss i)))
        (setq out (cons (cons (strcase (bht:pv p 'id)) p) out)))
      (setq i (1+ i))))
  (reverse out)
)

(defun bht:pt-find (id index)
  (cdr (assoc (strcase id) index))
)

;; Khoa noi dung (chuoi goc) de phat hien nhap trung duoi ID khac.
(defun bht:content-key (name n e z desc)
  (strcat name "|" (bht:trim n) "|" (bht:trim e) "|" (bht:trim z) "|" desc)
)

;; Khoa tuong thich v0.1 (ten + toa do 3 so le).
(defun bht:legacy-key (name east north z)
  (strcat name "|" (bht:fnum east 3) "|" (bht:fnum north 3) "|" (bht:fnum z 3))
)

(defun bht:pt-write-xdata (ent id ds row name n e z cls src desc tm)
  (and (bht:xset ent "BHT_RTK" (list name (if (> (strlen desc) 80) (substr desc 1 80) desc)))
       (bht:xset ent "BHT_PT" (append (list id ds (bht:str row) name n e z cls src tm)
                                      (bht:chunks desc 80))))
)

(defun bht:make-id (ds kind n)
  (strcat ds "-" kind "-" (bht:pad0 n 6))
)

;; Doc CSV 5 cot -> danh sach ban ghi (id ds row name n e z desc src) va loi.
;; Tra ve (records invalid-rows) ; invalid-rows = ((row . ly do) ...)
(defun bht:csv-records (path ds / lines row f name n e z desc recs bad src)
  (setq lines (bht:read-lines path) row 0 recs nil bad nil
        src (strcat (vl-filename-base path) (vl-filename-extension path)))
  (foreach line lines
    (setq row (1+ row))
    (if (/= (bht:trim line) "")
      (progn
        (setq f (bht:csv-fields line)
              name (bht:trim (nth 0 f))
              n (if (nth 1 f) (nth 1 f) "")
              e (if (nth 2 f) (nth 2 f) "")
              z (if (nth 3 f) (nth 3 f) "")
              desc (cond ((> (length f) 5)
                          (bht:join (cdr (cdr (cdr (cdr f)))) ","))
                         ((nth 4 f) (nth 4 f))
                         (T "")))
        (cond
          ((< (length f) 4) (setq bad (cons (cons row "thiếu cột") bad)))
          ((= name "") (setq bad (cons (cons row "tên điểm rỗng") bad)))
          ((> (strlen name) 80) (setq bad (cons (cons row "tên điểm quá dài") bad)))
          ((not (and (bht:num n) (bht:num e) (bht:num z)))
           (setq bad (cons (cons row "N/E/Z không phải số") bad)))
          (T (setq recs (cons (list (bht:make-id ds "R" row) ds row name
                                    (bht:trim n) (bht:trim e) (bht:trim z) desc src)
                              recs)))))))
  (list (reverse recs) (reverse bad))
)

;; Doc BHT_RTK.tsv (dinh dang V0.1): BHT_ID SRC_POINT NORTHING EASTING Z RAW_DESC SRC_ROW SOURCE_FILE
(defun bht:col (hdr f k / i)
  (setq i (vl-position k hdr))
  (if (and i (nth i f)) (nth i f) "")
)

(defun bht:tsv-rtk-records (path / lines hdr f recs bad row id ds)
  (setq lines (bht:read-lines path) recs nil bad nil row 1)
  (setq hdr (mapcar 'strcase (mapcar 'bht:trim (bht:split (car lines) "\t"))))
  (foreach line (cdr lines)
    (setq row (1+ row))
    (if (/= (bht:trim line) "")
      (progn
        (setq f (bht:split line "\t") id (strcase (bht:trim (bht:col hdr f "BHT_ID")))
              ds (if (vl-string-search "-R-" id) (substr id 1 (vl-string-search "-R-" id)) "TSV"))
        (if (and (bht:valid-id id) (/= (bht:col hdr f "SRC_POINT") "")
                 (bht:num (bht:col hdr f "NORTHING")) (bht:num (bht:col hdr f "EASTING")) (bht:num (bht:col hdr f "Z")))
          (setq recs (cons (list id ds (if (/= (bht:col hdr f "SRC_ROW") "") (bht:col hdr f "SRC_ROW") (itoa row))
                                 (bht:trim (bht:col hdr f "SRC_POINT")) (bht:trim (bht:col hdr f "NORTHING"))
                                 (bht:trim (bht:col hdr f "EASTING")) (bht:trim (bht:col hdr f "Z"))
                                 (bht:col hdr f "RAW_DESC")
                                 (if (/= (bht:col hdr f "SOURCE_FILE") "") (bht:col hdr f "SOURCE_FILE")
                                   (strcat (vl-filename-base path) ".tsv")))
                           recs))
          (setq bad (cons (cons row "dòng TSV không hợp lệ") bad))))))
  (list (reverse recs) (reverse bad))
)

;; Nhap danh sach ban ghi vao DWG, chong trung.
;; Tra ve assoc: added same conflict dupcontent adopted invalid dupfile
(defun bht:import-records (recs bad / index cmap lmap ss i ent x loc p id ds row name n e z desc src
                                 key added same conflict dupc adopted dupfile seen tm cls old dsrec)
  (setq added 0 same 0 conflict 0 dupc 0 adopted 0 dupfile 0 seen nil tm (bht:now))
  (bht:layer *bht-pt-layer* 3)
  (bht:point-style-apply nil nil)
  (bht:regapp "BHT_RTK") (bht:regapp "BHT_PT")
  ;; Chi muc hien co
  (setq index (bht:pt-all) cmap nil lmap nil)
  (foreach it index
    (setq p (cdr it))
    (setq cmap (cons (cons (bht:content-key (bht:pv p 'name) (bht:pv p 'n) (bht:pv p 'e)
                                            (bht:pv p 'z) (bht:pv p 'desc))
                           (bht:pv p 'id)) cmap)))
  ;; Diem v0.1 chua co BHT_PT
  (setq ss (ssget "_X" (list '(0 . "POINT") (cons 8 *bht-pt-layer*) '(-3 ("BHT_RTK")))) i 0)
  (if ss
    (while (< i (sslength ss))
      (setq ent (ssname ss i))
      (if (not (bht:xget ent "BHT_PT"))
        (progn
          (setq x (bht:xget ent "BHT_RTK") loc (cdr (assoc 10 (entget ent))))
          (setq lmap (cons (cons (bht:legacy-key (car x) (car loc) (cadr loc) (caddr loc)) ent) lmap))))
      (setq i (1+ i))))
  (foreach r recs
    (setq id (nth 0 r) ds (nth 1 r) row (nth 2 r) name (nth 3 r) n (nth 4 r) e (nth 5 r)
          z (nth 6 r) desc (nth 7 r) src (nth 8 r)
          key (bht:content-key name n e z desc)
          cls (bht:classify desc))
    (if (member key seen)
      (progn (setq dupfile (1+ dupfile))
             (bht:log (strcat "CẢNH BÁO trùng nội dung trong cùng file: " id " (" name ")"))))
    (setq seen (cons key seen))
    (cond
      ((setq p (bht:pt-find id index))
       (if (= (bht:content-key (bht:pv p 'name) (bht:pv p 'n) (bht:pv p 'e) (bht:pv p 'z) (bht:pv p 'desc)) key)
         (setq same (1+ same))
         (progn (setq conflict (1+ conflict))
                (bht:log (strcat "XUNG ĐỘT ID " id ": dữ liệu mới khác dữ liệu đã nhập; KHÔNG ghi đè. Mới: "
                                 name "," n "," e "," z "," desc)))))
      ((setq old (cdr (assoc key cmap)))
       (setq dupc (1+ dupc))
       (bht:log (strcat "TRÙNG NỘI DUNG: " id " giống điểm đã có " old "; bỏ qua.")))
      ((setq ent (cdr (assoc (bht:legacy-key name (bht:num e) (bht:num n) (bht:num z)) lmap)))
       (if (bht:pt-write-xdata ent id ds row name n e z cls src desc tm)
         (progn (setq adopted (1+ adopted)
                      lmap (vl-remove (assoc (bht:legacy-key name (bht:num e) (bht:num n) (bht:num z)) lmap) lmap)
                      index (cons (cons (strcase id) (bht:pt-from-ent ent)) index)
                      cmap (cons (cons key id) cmap)))))
      (T
       (setq ent (entmakex (list '(0 . "POINT") '(410 . "Model") (cons 8 *bht-pt-layer*)
                                 (list 10 (bht:num e) (bht:num n) (bht:num z)))))
       (if (and ent (bht:pt-write-xdata ent id ds row name n e z cls src desc tm))
         (setq added (1+ added)
               index (cons (cons (strcase id) (list (cons 'id id))) index)
               cmap (cons (cons key id) cmap))
         (bht:log (strcat "LỖI tạo điểm " id))))))
  (foreach b bad (bht:log (strcat "DÒNG LỖI " (itoa (car b)) ": " (cdr b))))
  (list (cons 'added added) (cons 'same same) (cons 'conflict conflict)
        (cons 'dupcontent dupc) (cons 'adopted adopted) (cons 'invalid (length bad))
        (cons 'dupfile dupfile))
)

(defun bht:import-report (res)
  (bht:msg (strcat "BHT nhập điểm: thêm mới " (itoa (cdr (assoc 'added res)))
                   ", đã có (giống hệt) " (itoa (cdr (assoc 'same res)))
                   ", xung đột ID " (itoa (cdr (assoc 'conflict res)))
                   ", trùng nội dung ID khác " (itoa (cdr (assoc 'dupcontent res)))
                   ", nhận điểm v0.1 " (itoa (cdr (assoc 'adopted res)))
                   ", dòng lỗi " (itoa (cdr (assoc 'invalid res)))
                   ", trùng trong file " (itoa (cdr (assoc 'dupfile res))) "."))
  (if (or (> (cdr (assoc 'conflict res)) 0) (> (cdr (assoc 'invalid res)) 0)
          (> (cdr (assoc 'dupcontent res)) 0))
    (bht:msg "  Xem chi tiết trong thư mục BHT_LOG cạnh bản vẽ."))
)

(defun bht:dataset-register (ds path nrec res)
  (bht:dataset-register-fmt ds path nrec res "")
)

;; 0.3.3: ghi them dinh dang nhap (CSV / TSV) de canh bao nhap trung dinh dang.
(defun bht:dataset-register-fmt (ds path nrec res fmt / rec old)
  (setq rec (bht:rec-read "DATASET" ds))
  (if (null rec)
    (setq rec (list (cons "dataset_id" ds) (cons "tao_luc" (bht:now)))))
  (setq old (bht:get rec "dinh_dang"))
  (setq rec (bht:set rec "file_nguon" (if path path ""))
        rec (bht:set rec "so_dong_hop_le" (itoa nrec))
        rec (bht:set rec "lan_nhap_cuoi" (bht:now))
        rec (bht:set rec "crs" "CHUA_XAC_NHAN (giả định VN-2000, đơn vị mét)")
        rec (bht:set rec "ket_qua" (strcat "them=" (itoa (cdr (assoc 'added res)))
                                           " trung=" (itoa (cdr (assoc 'same res)))
                                           " xungdot=" (itoa (cdr (assoc 'conflict res))))))
  (if (/= fmt "")
    (setq rec (bht:set rec "dinh_dang" (cond ((= old "") fmt)
                                             ((vl-string-search fmt old) old)
                                             (T (strcat old "+" fmt))))))
  (bht:rec-write "DATASET" ds rec)
)

;; 0.3.3: canh bao khi cung du lieu duoc nhap lai bang dinh dang khac (CSV <-> TSV).
;; Tra ve T neu du lieu da co san hoan toan (khong them diem nao).
(defun bht:dual-import-check (dss fmt res / other hit)
  (setq other (if (= fmt "CSV") "TSV" "CSV") hit nil)
  (foreach d dss
    (if (vl-string-search other (bht:get (bht:rec-read "DATASET" d) "dinh_dang"))
      (setq hit (cons d hit))))
  (cond
    ((and res (= (cdr (assoc 'added res)) 0)
          (> (+ (cdr (assoc 'same res)) (cdr (assoc 'dupcontent res)) (cdr (assoc 'adopted res))) 0))
     (bht:msg (strcat "BHT LƯU Ý: dữ liệu trong file " fmt " này ĐÃ CÓ trong bản vẽ"
                      (if hit (strcat " (dataset " (bht:join hit ", ") " đã nhập bằng " other ")") "")
                      " - không thêm điểm nào, không tạo trùng. KHÔNG cần nhập cùng một bộ dữ liệu bằng cả CSV và TSV."))
     T)
    (hit
     (bht:msg (strcat "BHT LƯU Ý: dataset " (bht:join hit ", ") " trước đây nhập bằng " other
                      ". Mặc định dùng CSV trực tiếp; TSV chỉ là định dạng trao đổi/chuẩn hóa - không cần nhập cả hai."))
     nil)
    (T nil))
)

;; Ham chinh nhap CSV (goi duoc tu script kiem thu). CSV la cach nhap MAC DINH.
(defun bht:import-csv (path ds / pack res)
  (setq ds (strcase (bht:trim ds)))
  (if (not (bht:valid-id ds))
    (progn (bht:msg "BHT: mã dataset không hợp lệ (chỉ A-Z 0-9 _ - .).") nil)
    (if (not (bht:file-exists path))
      (progn (bht:msg "BHT: không mở được file CSV.") nil)
      (progn
        (setq pack (bht:csv-records path ds)
              res (bht:import-records (car pack) (cadr pack)))
        (bht:dual-import-check (list ds) "CSV" res)
        (bht:dataset-register-fmt ds path (length (car pack)) res "CSV")
        (bht:log (strcat "Nhập CSV " path " dataset " ds))
        (bht:import-report res)
        (bht:log-flush)
        res)))
)

;; TSV = dinh dang trao doi / chuan hoa (BHT_RTK.tsv V0.1), khong bat buoc.
(defun bht:import-tsv (path / pack res dss)
  (if (not (bht:file-exists path))
    (progn (bht:msg "BHT: không mở được file TSV.") nil)
    (progn
      (setq pack (bht:tsv-rtk-records path)
            res (bht:import-records (car pack) (cadr pack)))
      (setq dss nil)
      (foreach r (car pack) (setq dss (bht:unique-add dss (nth 1 r))))
      (bht:dual-import-check dss "TSV" res)
      (foreach d dss (bht:dataset-register-fmt d path (length (car pack)) res "TSV"))
      (bht:import-report res)
      (bht:log-flush)
      res))
)

(defun bht:ask-string (msg default / v)
  (setq v (getstring T (strcat "\n" msg (if (and default (/= default "")) (strcat " <" default ">") "") ": ")))
  (if (= (bht:trim v) "") (if default default "") (bht:trim v))
)

(defun c:BHTNHAP (/ *error* path ds)
  (setq *error* bht:on-error)
  (if (setq path (getfiled "Chọn CSV khảo sát RTK (tên, Bắc, Đông, Z, mô tả; không tiêu đề)" (bht:dwg-folder) "csv;txt" 0))
    (progn
      (setq ds (strcase (bht:ask-string "Mã dataset (tiền tố ID, vd BOT19)" (bht:meta "dataset_cuoi" "BOT19"))))
      (if (bht:import-csv path ds)
        (progn
          (bht:meta-set "dataset_cuoi" ds)
          (bht:ask-labels-after-import)))))
  (bht:log-flush)
  (princ)
)
(defun c:BHTIMPORT () (c:BHTNHAP))
(defun c:BHTCSV () (c:BHTNHAP))

(defun c:BHTNHAPTSV (/ *error* path)
  (setq *error* bht:on-error)
  (if (setq path (getfiled "Chọn BHT_RTK.tsv (định dạng trao đổi; CSV là cách nhập mặc định)" (bht:dwg-folder) "tsv;txt" 0))
    (if (bht:import-tsv path) (bht:ask-labels-after-import)))
  (bht:log-flush)
  (princ)
)
(defun c:BHTNK () (c:BHTNHAPTSV))

;; Sau khi nhap diem: hoi tao/cap nhat nhan (cap nhat tai cho, khong nhan doi).
(defun bht:ask-labels-after-import ()
  (if (= (strcase (bht:ask-string "Tạo/cập nhật nhãn điểm RTK ngay (BHTNHANDIEM)? [C/K]" "C")) "C")
    (bht:lbl-report (bht:lbl-sync))
    (bht:msg "BHT: chưa tạo nhãn. Dùng BHTNHANDIEM khi cần."))
)

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
  (setq h (bht:num (bht:meta "nhan_h" "1.0")) off (bht:num (bht:meta "nhan_offset" "0.5")))
  (list (cons 'mode (strcase (bht:meta "nhan_che_do" "TMC")))
        (cons 'id (= (bht:meta "nhan_id" "0") "1"))
        (cons 'h (if (and h (> h 0)) h 1.0))
        (cons 'off (if off off 0.5))
        (cons 'style (bht:meta "nhan_kieu_chu" "BHT_ARIAL"))
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

(defun bht:lbl-xdata (pid kind state pt)
  (list -3 (list "BHT_NHAN" (cons 1000 pid) (cons 1000 kind) (cons 1000 state)
                 (cons 1000 (bht:fnum (car pt) 6)) (cons 1000 (bht:fnum (cadr pt) 6))))
)

(defun bht:lbl-make (pid kind s pt h style layer)
  (entmakex (list '(0 . "TEXT") '(410 . "Model") (cons 8 layer) (cons 10 pt) (cons 40 h) (cons 1 s) '(50 . 0.0)
                  (cons 7 style) '(72 . 0) '(73 . 0)
                  (bht:lbl-xdata pid kind "TU_DONG" pt)))
)

(defun bht:lbl-apply (d s pt h style layer)
  (setq d (bht:dxf-put d 1 s) d (bht:dxf-put d 40 h) d (bht:dxf-put d 7 style) d (bht:dxf-put d 8 layer))
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
  (setq tb (vl-catch-all-apply 'textbox (list (list (cons 0 "TEXT") (cons 1 s) (cons 40 h) (cons 7 style)))))
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
(defun bht:lbl-upgrade-legacy (/ st h off groups index p pid kind exist na nt)
  (setq st (bht:lbl-settings) h (cdr (assoc 'h st)) off (cdr (assoc 'off st)) na 0 nt 0
        groups (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_NHAN" 2)) index nil)
  (foreach g groups
    (foreach e (cdr g)
      (if (= (bht:lbl-state e) 'LEGACY)
        (progn
          (if (null index) (setq index (bht:pt-all)))
          (setq pid (car (bht:split (car g) "|")) kind (cadr (bht:split (car g) "|"))
                p (bht:pt-find pid index) exist nil)
          (foreach kd *bht-lbl-kinds* (if (assoc (strcat pid "|" (car kd)) groups) (setq exist (cons (car kd) exist))))
          (if (and p (bht:pt-near (cdr (assoc 10 (entget e))) (bht:lbl-legacy-pos p kind exist h off) *bht-lbl-tol*))
            (progn (bht:lbl-set-state e "TU_DONG") (setq na (1+ na)))
            (progn (bht:lbl-set-state e "TAY") (setq nt (1+ nt))))))))
  (if (> (+ na nt) 0)
    (bht:log (strcat "Nâng cấp XData nhãn 0.3.2: tự động " (itoa na) ", đã dời tay " (itoa nt))))
  (list na nt)
)

;; ---- Dong bo nhan ------------------------------------------------------------

;; Tao/cap nhat nhan cho MOI diem RTK (tuong thich 0.3.2).
(defun bht:lbl-sync () (bht:lbl-sync-scope nil))

;; scope: nil = chi bo tri diem moi / doi noi dung; 'ALL = bo tri lai moi diem;
;; danh sach survey id = bo tri lai cac diem do (nhan tay van giu nguyen).
;; Tra ve assoc: points created updated unchanged deleted laidout manual cost
(defun bht:lbl-sync-scope (scope / st kinds h off style prio groups index owners created updated same deleted
                                   manual n seen plans items fixed pid p want exist e d k autol manl need
                                   lines w hh tb res pl bx by nl i pt new cost ex)
  (bht:lbl-upgrade-legacy)
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
         (if (or (/= (cdr (assoc 1 d)) (cadr wl)) (not (equal (cdr (assoc 40 d)) h 1e-9))
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
       (setq hh (+ h (* (1- nl) 1.5 h) (* 0.25 h)))
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
          (setq pt (list bx (+ by (* 0.25 h) (* (- nl 1 i) 1.5 h)) (caddr (caddr pl))))
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
  (setq h (bht:num (bht:ask-string "Chiều cao chữ nhãn" (bht:meta "nhan_h" "1.0")))
        off (bht:num (bht:ask-string "Khoảng lệch nhãn so với điểm (đơn vị bản vẽ)" (bht:meta "nhan_offset" "0.5")))
        sty (bht:ask-string "Kiểu chữ (BHT_ARIAL = Arial TrueType, hiện tiếng Việt)" (bht:meta "nhan_kieu_chu" "BHT_ARIAL")))
  (cond
    ((not (and h (> h 0) off)) (bht:msg "BHT: giá trị không hợp lệ, giữ cài đặt cũ.") nil)
    ((and (/= (strcase sty) "BHT_ARIAL") (not (tblsearch "STYLE" sty)))
     (bht:msg (strcat "BHT: không có kiểu chữ " sty " trong bản vẽ, giữ cài đặt cũ.")) nil)
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
     (if (null out) (bht:msg "BHT: không tìm thấy điểm nào theo danh sách."))
     out)
    (T
     (bht:msg "Chọn vùng có điểm RTK / nhãn cần sắp xếp: ")
     (bht:ss-label-pids (ssget (list '(-4 . "<OR") '(0 . "POINT") '(0 . "TEXT") '(-4 . "OR>"))))))
)

(defun bht:lbl-layout-cmd (scope / before r after)
  (if (null scope)
    (bht:msg "BHT: không có điểm nào trong phạm vi.")
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

(defun c:BHTNHANDIEM (/ *error* st v r cur n)
  (setq *error* bht:on-error)
  (bht:lbl-upgrade-legacy)
  (setq st (bht:lbl-settings)
        cur (cond ((= (cdr (assoc 'mode st)) "T") "1") ((= (cdr (assoc 'mode st)) "TM") "2") (T "3")))
  (bht:msg (strcat "Nhãn điểm RTK: chế độ " (bht:lbl-mode-name (cdr (assoc 'mode st)))
                   (if (cdr (assoc 'id st)) " + ID nội bộ" "")
                   (if (cdr (assoc 'prio st)) " | ưu tiên hồ sơ: BẬT" "")
                   " | cao chữ " (bht:meta "nhan_h" "1.0") " | lệch " (bht:meta "nhan_offset" "0.5")
                   " | kiểu chữ " (bht:meta "nhan_kieu_chu" "BHT_ARIAL")
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
    ((= v "A")
     (bht:meta-set "nhan_an" "1")
     (bht:lbl-visibility T)
     (bht:msg "BHT: đã ẨN nhãn điểm (tắt layer BHT_RTK_*; nhãn và dữ liệu vẫn còn)."))
    ((= v "H")
     (bht:meta-set "nhan_an" "0")
     (setq r (bht:lbl-sync)))
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
  (bht:lbl-upgrade-legacy)
  (bht:msg "Sắp xếp nhãn điểm RTK tránh chồng lấn (POINT không bao giờ bị di chuyển; nhãn đã dời tay được giữ).")
  (bht:lbl-layout-cmd (bht:ask-label-scope))
  (bht:log-flush)
  (princ)
)

;; Tra nhan da doi tay ve vi tri tu dong (chon diem hoac nhan).
(defun c:BHTNHANTUDONG (/ *error* pids r)
  (setq *error* bht:on-error)
  (bht:lbl-upgrade-legacy)
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
  (if (= (bht:meta "nhan_an" "0") "1")
    (progn (bht:meta-set "nhan_an" "0") (setq r (bht:lbl-sync)) (bht:lbl-report r))
    (progn (bht:meta-set "nhan_an" "1") (bht:lbl-visibility T)
           (bht:msg "BHT: đã ẨN nhãn điểm RTK (layer tắt, không xóa). Gõ lại BHTANNHAN để hiện.")))
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
    (bht:msg "BHT: kích thước phải lớn hơn 0."))
  (bht:log-flush)
  (princ)
)

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
    (progn (if id (bht:msg (strcat "Không có đối tượng " id "."))) nil))
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

;; Hoi cac truong ho so (dung chung tao/sua).
(defun bht:ask-fields (rec suggest / f grp nmat faces i code)
  (setq grp (bht:ask-group (if (and rec (/= (bht:get rec "nhom") "")) (bht:get rec "nhom") suggest)))
  (setq f (list (cons "nhom" grp)))
  (setq f (append f (list (cons "ma_hieu" (bht:ask-string "Mã hiệu (vd 207a; Enter = chưa rõ; ngoài QCVN ghi mã nội bộ)" (bht:get rec "ma_hieu"))))))
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
  (setq f (append f (list (cons "tinh_trang" (bht:ask-string "Tình trạng (tốt/hư hỏng/...)" (bht:get rec "tinh_trang"))))))
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
               (bht:msg (strcat "BHT: chưa chèn được ký hiệu " id " (hồ sơ chưa có điểm RTK hợp lệ?)."))))))
)

;; Tao ho so tu cac diem (hoi truong + chen ky hieu). allow-shared: da xac nhan dung chung.
(defun bht:obj-create-interactive (pids allow-shared / index id fields res)
  (setq index (bht:pt-all))
  (setq id (strcase (bht:ask-string "ID đối tượng" (bht:obj-next-id))))
  (setq fields (bht:ask-fields nil (bht:suggest-group pids index)))
  (setq res (bht:obj-create id fields pids allow-shared))
  (if (car res)
    (progn
      (bht:msg (strcat "BHT: đã tạo đối tượng " (cadr res) " với " (itoa (length pids)) " điểm RTK."))
      (bht:symbol-after-change (cadr res)))
    (bht:msg (strcat "BHT: không tạo được đối tượng: " (cadr res))))
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
             (bht:msg (strcat "BHT: không có hồ sơ " (bht:str tid) ". Không làm gì.")))
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
(defun c:BHTTAG () (c:BHTDOITUONG))

(defun c:BHTSUADT (/ *error* id)
  (setq *error* bht:on-error)
  (if (setq id (bht:pick-object "Chọn đối tượng cần sửa"))
    (bht:obj-edit-interactive id))
  (bht:log-flush)
  (princ)
)
(defun c:BHTEDIT () (c:BHTSUADT))

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
(defun c:BHTDELETE () (c:BHTXOADT))

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
(defun c:BHTUNTAG () (c:BHTBOTDIEM))

;;; ----------------------------------------------------------------------
;;; He toa do cho anh GPS: WGS84 -> VN-2000 (7 tham so, cung bo so voi
;;; IRTv6_2026-09-25_google-satellite-tiles-fix-5.lsp, viet lai doc lap,
;;; KHONG can nap IRT). Chi dung de dat vi tri CHUP anh / de xuat ghep.
;;; ----------------------------------------------------------------------

(setq *bht-zones*
  '(("1" "VN-2000 múi 3°, KTT 105°45', k=0.9999 (Long An / Tây Ninh cũ)" 105.75 0.9999)
    ("2" "VN-2000 múi 3°, KTT 105°30', k=0.9999" 105.5 0.9999)
    ("3" "VN-2000 múi 3°, KTT 105°00', k=0.9999" 105.0 0.9999)
    ("4" "VN-2000 múi 3°, KTT 106°00', k=0.9999" 106.0 0.9999)
    ("5" "VN-2000 múi 3°, KTT 106°15', k=0.9999" 106.25 0.9999)
    ("6" "VN-2000 múi 3°, KTT 106°30', k=0.9999" 106.5 0.9999)
    ("7" "VN-2000 UTM 48N, KTT 105°, k=0.9996" 105.0 0.9996)))

(defun bht:geo-init (/ f as)
  (setq f (/ 1.0 298.257223563) as (/ pi 648000.0)
        *bht-a* 6378137.0
        *bht-e2* (- (* 2.0 f) (* f f))
        *bht-ep2* (/ *bht-e2* (- 1.0 *bht-e2*))
        *bht-tx* -191.90441429 *bht-ty* -39.30318279 *bht-tz* -111.45032835
        *bht-s* (/ 0.252906278 1000000.0)
        *bht-rx* (* -0.00928836 as) *bht-ry* (* 0.01975479 as) *bht-rz* (* -0.00427372 as))
)
(bht:geo-init)

(defun bht:ecef (lat lon / la lo n)
  (setq la (* lat (/ pi 180.0)) lo (* lon (/ pi 180.0))
        n (/ *bht-a* (sqrt (- 1.0 (* *bht-e2* (sin la) (sin la))))))
  (list (* n (cos la) (cos lo)) (* n (cos la) (sin lo)) (* n (- 1.0 *bht-e2*) (sin la)))
)

(defun bht:to-vn (x y z / m dx dy dz)
  (setq m (+ 1.0 *bht-s*)
        dx (/ (- x *bht-tx*) m) dy (/ (- y *bht-ty*) m) dz (/ (- z *bht-tz*) m))
  (list (+ dx (* (- *bht-rz*) dy) (* *bht-ry* dz))
        (+ (* *bht-rz* dx) dy (* (- *bht-rx*) dz))
        (+ (* (- *bht-ry*) dx) (* *bht-rx* dy) dz))
)

(defun bht:geod (x y z / lon p lat n h)
  (setq lon (atan y x) p (sqrt (+ (* x x) (* y y)))
        lat (atan (/ z (* p (- 1.0 *bht-e2*)))))
  (repeat 6
    (setq n (/ *bht-a* (sqrt (- 1.0 (* *bht-e2* (sin lat) (sin lat)))))
          h (- (/ p (cos lat)) n)
          lat (atan (/ z (* p (- 1.0 (* *bht-e2* (/ n (+ n h)))))))))
  (list lat lon)
)

(defun bht:tm (lat lon lon0 k0 / a e2 e4 e6 ep2 A0 A2 A4 A6 M si c tt nu eta2 dl c3 c5)
  (setq a *bht-a* e2 *bht-e2* ep2 *bht-ep2* e4 (* e2 e2) e6 (* e4 e2)
        A0 (- 1.0 (/ e2 4.0) (/ (* 3.0 e4) 64.0) (/ (* 5.0 e6) 256.0))
        A2 (* (/ 3.0 8.0) (+ e2 (/ e4 4.0) (/ (* 15.0 e6) 128.0)))
        A4 (* (/ 15.0 256.0) (+ e4 (/ (* 3.0 e6) 4.0)))
        A6 (/ (* 35.0 e6) 3072.0)
        M (* a (- (+ (* A0 lat) (* A4 (sin (* 4.0 lat)))) (* A2 (sin (* 2.0 lat))) (* A6 (sin (* 6.0 lat)))))
        si (sin lat) c (cos lat) tt (/ si c)
        nu (/ a (sqrt (- 1.0 (* e2 si si))))
        eta2 (* ep2 c c) dl (- lon lon0) c3 (* c c c) c5 (* c3 c c))
  (list
    (+ 500000.0
       (* k0 nu (+ (* dl c)
                   (* (/ (expt dl 3) 6.0) c3 (+ 1.0 (- (* tt tt)) eta2))
                   (* (/ (expt dl 5) 120.0) c5 (+ 5.0 (- (* 18.0 tt tt)) (expt tt 4) (* 14.0 eta2) (- (* 58.0 tt tt eta2)))))))
    (* k0 (+ M (* nu si (+ (* (/ (expt dl 2) 2.0) c)
                           (* (/ (expt dl 4) 24.0) c3 (+ 5.0 (- (* tt tt)) (* 9.0 eta2) (* 4.0 eta2 eta2)))
                           (* (/ (expt dl 6) 720.0) c5 (+ 61.0 (- (* 58.0 tt tt)) (expt tt 4) (* 270.0 eta2) (- (* 330.0 tt tt eta2)))))))))
)

;; (lon lat) WGS84 -> (E N) VN-2000 theo KTT cm, he so k0.
(defun bht:project (lon lat cm k0 / p g)
  (setq p (bht:ecef lat lon) p (bht:to-vn (car p) (cadr p) (caddr p))
        g (bht:geod (car p) (cadr p) (caddr p)))
  (bht:tm (car g) (cadr g) (* cm (/ pi 180.0)) k0)
)

(defun bht:crs-current (/ idx z)
  (setq idx (bht:meta "crs_idx" "1") z (assoc idx *bht-zones*))
  (if (null z) (setq z (car *bht-zones*)))
  z
)

(defun c:BHTHETOADO (/ *error* v z)
  (setq *error* bht:on-error)
  (bht:msg (strcat "Hệ hiện tại cho ảnh GPS: " (cadr (bht:crs-current))
                   " | trạng thái: " (bht:meta "crs_trang_thai" "CHUA_XAC_NHAN")))
  (foreach z *bht-zones* (princ (strcat "\n   " (car z) " = " (cadr z))))
  (setq v (bht:ask-string "Chọn hệ (số)" (car (bht:crs-current))))
  (if (setq z (assoc v *bht-zones*))
    (progn
      (bht:meta-set "crs_idx" v)
      (bht:meta-set "crs_trang_thai" "NGUOI_DUNG_CHON (chưa kiểm định bằng mốc)")
      (bht:msg (strcat "BHT: đã chọn " (cadr z) "."))
      (if (bht:rec-keys "PHOTO")
        (progn
          (bht:msg "BHT: tính lại vị trí chụp và dời ký hiệu ảnh theo hệ mới (điểm RTK không bị động tới)...")
          (bht:photo-sync-report (bht:photo-sync))
          (bht:msg "  Đề xuất ghép ảnh cũ có thể đã lệch: chạy lại BHTGHEPANH.")))))
  (bht:log-flush)
  (princ)
)

;;; ----------------------------------------------------------------------
;;; Anh TimeMark - dictionary "PHOTO"
;;; Truong: photo_id ten thoi_gian lon lat gps_hop_le duong_dan goc nguon
;;;  antifake dia_chi e n crs de_xuat* kc trang_thai doi_tuong*
;;; trang_thai: CHUA_GHEP / DE_XUAT / MO_HO / KHONG_CO_DIEM_GAN / DA_XAC_NHAN
;;; ----------------------------------------------------------------------

(defun bht:photo-read (id) (bht:rec-read "PHOTO" id))
(defun bht:photo-write (id rec) (bht:rec-write "PHOTO" id rec))

;; Nhap BHT_PHOTO.tsv. draw: T = ve ky hieu vi tri chup (chi anh GPS hop le).
;; Tra ve assoc: added same conflict invalid valid-gps invalid-gps
(defun bht:photo-import-tsv (path draw / lines hdr f id rec old added same conflict bad vgps igps
                                   z cm k0 lon lat en base sync)
  (setq lines (bht:read-lines path) added 0 same 0 conflict 0 bad 0 vgps 0 igps 0
        z (bht:crs-current) cm (caddr z) k0 (cadddr z)
        base (vl-filename-directory path) sync nil)
  (setq hdr (mapcar 'strcase (mapcar 'bht:trim (bht:split (car lines) "\t"))))
  (foreach line (cdr lines)
    (if (/= (bht:trim line) "")
      (progn
        (setq f (bht:split line "\t")
              id (strcase (bht:trim (bht:col hdr f "BHT_ID"))))
        (if (not (bht:valid-id id))
          (setq bad (1+ bad))
          (progn
            (setq rec (list (cons "photo_id" id)
                            (cons "ten" (bht:col hdr f "NAME"))
                            (cons "thoi_gian" (bht:col hdr f "CAPTURED_AT"))
                            (cons "lon" (bht:trim (bht:col hdr f "LONGITUDE")))
                            (cons "lat" (bht:trim (bht:col hdr f "LATITUDE")))
                            (cons "gps_hop_le" (bht:trim (bht:col hdr f "GPS_VALID")))
                            (cons "duong_dan" (bht:col hdr f "PHOTO_PATH"))
                            (cons "goc" base)
                            (cons "nguon" (bht:col hdr f "SOURCE_ENTRY"))
                            (cons "antifake" (bht:col hdr f "ANTIFAKE"))
                            (cons "dia_chi" (bht:col hdr f "ADDRESS"))))
            (setq lon (bht:num (bht:get rec "lon")) lat (bht:num (bht:get rec "lat")))
            ;; GPS hop le: co so va khac 0,0 (khong bo ban ghi 0,0)
            (if (and lon lat (or (> (abs lon) 0.001) (> (abs lat) 0.001)))
              (setq rec (bht:set rec "gps_hop_le" "1"))
              (setq rec (bht:set rec "gps_hop_le" "0")))
            (if (= (bht:get rec "gps_hop_le") "1")
              (setq vgps (1+ vgps))
              (setq igps (1+ igps)))
            (setq old (bht:photo-read id))
            (cond
              ((and old (= (bht:get old "lon") (bht:get rec "lon")) (= (bht:get old "lat") (bht:get rec "lat"))
                    (= (bht:get old "thoi_gian") (bht:get rec "thoi_gian")) (= (bht:get old "nguon") (bht:get rec "nguon")))
               ;; cap nhat thu muc goc (neu du an bi chuyen), giu lien ket
               (if (/= (bht:get old "goc") base) (bht:photo-write id (bht:set old "goc" base)))
               (setq same (1+ same)))
              (old
               (setq conflict (1+ conflict))
               (bht:log (strcat "XUNG ĐỘT ảnh " id ": dữ liệu khác bản đã nhập; không ghi đè.")))
              (T
               (if (= (bht:get rec "gps_hop_le") "1")
                 (setq en (bht:project lon lat cm k0)
                       rec (bht:set rec "e" (bht:fnum (car en) 3))
                       rec (bht:set rec "n" (bht:fnum (cadr en) 3))
                       rec (bht:set rec "crs" (cadr z)))
                 (setq rec (bht:set rec "e" "") rec (bht:set rec "n" "") rec (bht:set rec "crs" "")))
               (setq rec (bht:set rec "trang_thai" "CHUA_GHEP"))
               (bht:photo-write id rec)
               (setq added (1+ added)))))))))
  ;; 0.3.2: ky hieu dong bo tu MOI ban ghi (ca ban ghi da co) - sua loi 0.3.1
  ;; chi ve ky hieu khi nhap moi, nhap lai khong tao ky hieu con thieu.
  (if draw (setq sync (bht:photo-sync)))
  (bht:log (strcat "Nhập chỉ mục ảnh " path ": thêm " (itoa added) ", trùng " (itoa same)
                   ", xung đột " (itoa conflict)))
  (list (cons 'added added) (cons 'same same) (cons 'conflict conflict) (cons 'invalid bad)
        (cons 'validgps vgps) (cons 'invalidgps igps) (cons 'sync sync))
)

(defun bht:photo-report (res)
  (bht:msg (strcat "BHT ảnh: thêm " (itoa (cdr (assoc 'added res)))
                   ", đã có " (itoa (cdr (assoc 'same res)))
                   ", xung đột " (itoa (cdr (assoc 'conflict res)))
                   ", dòng lỗi " (itoa (cdr (assoc 'invalid res)))
                   " | trong file: GPS hợp lệ " (itoa (cdr (assoc 'validgps res)))
                   ", GPS 0,0/không có " (itoa (cdr (assoc 'invalidgps res))) " (vẫn giữ)."))
  (bht:msg (strcat "  Vị trí ảnh tính theo: " (cadr (bht:crs-current)) " - "
                   (bht:meta "crs_trang_thai" "CHUA_XAC_NHAN") ". GPS ảnh là vị trí CHỤP, không thay RTK."))
  (if (cdr (assoc 'sync res)) (bht:photo-sync-report (cdr (assoc 'sync res))))
  (bht:photo-stats-report (bht:photo-stats))
)

(defun c:BHTANHNAP (/ *error* path ans res)
  (setq *error* bht:on-error)
  (if (setq path (getfiled "Chọn chỉ mục ảnh BHT_PHOTO.tsv" (bht:dwg-folder) "tsv;txt" 0))
    (progn
      (setq ans (strcase (bht:ask-string "Vẽ ký hiệu vị trí chụp ảnh (layer BHT_ANH_GPS)? [C/K]" "C")))
      (setq res (bht:photo-import-tsv path (= ans "C")))
      (bht:photo-report res)))
  (bht:log-flush)
  (princ)
)
(defun c:BHTDSANH () (c:BHTANHNAP))

;;; ---- KMZ -> thu muc anh + BHT_PHOTO.tsv -------------------------------

(defun bht:ps-quote (s) (bht:replace s "'" "''"))

(defun bht:run-wait (cmd / wsh rc)
  (setq wsh (vl-catch-all-apply 'vlax-create-object (list "WScript.Shell")))
  (if (or (null wsh) (vl-catch-all-error-p wsh))
    nil
    (progn
      (setq rc (vl-catch-all-apply 'vlax-invoke-method (list wsh 'Run cmd 0 :vlax-true)))
      (vlax-release-object wsh)
      (if (vl-catch-all-error-p rc) nil rc)))
)

;; Giai nen doc.kml + anh JPG tu KMZ (chi doc KMZ goc, khong sua).
(defun bht:kmz-extract (kmz dest / ps1 f lines logf res)
  (vl-mkdir dest)
  (setq ps1 (strcat (bht:slash (getenv "TEMP")) "bht_kmz_" (itoa (getvar "MILLISECS")) ".ps1")
        logf (strcat (bht:slash dest) "_bht_giai_nen.log"))
  (if (vl-file-size logf) (vl-file-delete logf))
  (setq lines
    (list
      "$ErrorActionPreference = 'Stop'"
      "Add-Type -AssemblyName System.IO.Compression.FileSystem"
      (strcat "$zip = '" (bht:ps-quote kmz) "'")
      (strcat "$dest = '" (bht:ps-quote (vl-string-right-trim "\\" dest)) "'")
      "$log = Join-Path $dest '_bht_giai_nen.log'"
      "try {"
      "  $z = [System.IO.Compression.ZipFile]::OpenRead($zip)"
      "  $n = 0"
      "  foreach ($e in $z.Entries) {"
      "    $name = $e.FullName.Replace('\\','/')"
      "    if ($name -like '*..*') { continue }"
      "    $take = ($name -like '*.kml') -or ($name -like '*.jpg') -or ($name -like '*.jpeg')"
      "    if (-not $take) { continue }"
      "    $p = Join-Path $dest ($name.Replace('/','\\'))"
      "    $d = Split-Path -Parent $p"
      "    if (-not (Test-Path -LiteralPath $d)) { [void][System.IO.Directory]::CreateDirectory($d) }"
      "    if ((Test-Path -LiteralPath $p) -and ((Get-Item -LiteralPath $p).Length -eq $e.Length)) { $n++; continue }"
      "    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $p, $true)"
      "    $n++"
      "  }"
      "  $z.Dispose()"
      "  Set-Content -LiteralPath $log -Value ('OK ' + $n) -Encoding UTF8"
      "} catch {"
      "  Set-Content -LiteralPath $log -Value ('LOI ' + $_.Exception.Message) -Encoding UTF8"
      "}"))
  (if (setq f (bht:open-write-bom ps1))
    (progn
      (foreach l lines (write-line l f))
      (close f)
      (bht:run-wait (strcat "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"" ps1 "\""))
      (if (vl-file-size ps1) (vl-file-delete ps1))
      (setq res (if (vl-file-size logf) (car (bht:read-lines logf)) nil))
      (if (and res (bht:starts res "OK")) res
        (progn (bht:msg (strcat "BHT KMZ: giải nén lỗi: " (if res res "không chạy được PowerShell"))) nil)))
    (progn (bht:msg "BHT KMZ: không ghi được script tạm.") nil))
)

(defun bht:xml-decode (s)
  (setq s (bht:replace s "&lt;" "<") s (bht:replace s "&gt;" ">")
        s (bht:replace s "&quot;" "\"") s (bht:replace s "&apos;" "'"))
  (bht:replace s "&amp;" "&")
)

(defun bht:between (s op cl / i j)
  (if (setq i (vl-string-search op s))
    (progn
      (setq i (+ i (strlen op)))
      (if (setq j (vl-string-search cl s i)) (substr s (1+ i) (- j i)) nil))
    nil)
)

;; Cac doan text trong <p ...>...</p>
(defun bht:p-texts (s / out pos i gt j)
  (setq out nil pos 0)
  (while (setq i (vl-string-search "<p" s pos))
    (setq gt (vl-string-search ">" s i))
    (if (and gt (setq j (vl-string-search "</p>" s gt)))
      (setq out (cons (substr s (+ gt 2) (- j gt 1)) out) pos (+ j 4))
      (setq pos (strlen s))))
  (reverse out)
)

;; Doc doc.kml -> danh sach (name time lon lat src antifake address), dung thu tu Placemark.
(defun bht:kml-placemarks (kml / f line buf inpm out desc name addr coord src tm af parts)
  (setq out nil inpm nil buf "")
  (if (setq f (open kml "r"))
    (progn
      (while (setq line (read-line f))
        (cond
          ((and (not inpm) (vl-string-search "<Placemark" line))
           (setq inpm T buf (substr line (1+ (vl-string-search "<Placemark" line))))
           (if (vl-string-search "</Placemark>" buf) (setq inpm 'done)))
          (inpm (setq buf (strcat buf "\n" line))
                (if (vl-string-search "</Placemark>" line) (setq inpm 'done))))
        (if (= inpm 'done)
          (progn
            (setq name (bht:xml-decode (bht:trim (bht:between buf "<name>" "</name>")))
                  addr (bht:between buf "<address>" "</address>")
                  addr (if addr (bht:xml-decode (bht:trim addr)) "")
                  desc (bht:between buf "<description>" "</description>")
                  desc (if desc desc "")
                  src (bht:between desc "src=\"" "\"")
                  coord (bht:between buf "<coordinates>" "</coordinates>")
                  parts (bht:split (bht:trim (if coord coord "")) ",")
                  tm "" af "")
            (foreach tx (bht:p-texts desc)
              (if (wcmatch tx "####-##-## ##:##:##*") (setq tm (substr tx 1 19)))
              (if (bht:starts tx "AntiFakeCode:") (setq af (bht:trim (substr tx 14)))))
            (setq out (cons (list name tm (bht:trim (car parts)) (bht:trim (if (cadr parts) (cadr parts) ""))
                                  (if src src "") af addr) out))
            (setq inpm nil buf ""))))
      (close f)))
  (reverse out)
)

;; Ghi BHT_PHOTO.tsv tu danh sach placemark. Khong ghi de neu da co (tra ve nil).
(defun bht:write-photo-tsv (path pms ds overwrite / f n lon lat valid)
  (if (and (vl-file-size path) (not overwrite))
    nil
    (if (setq f (bht:open-write-utf8 path))
      (progn
        (write-line "BHT_ID\tNAME\tCAPTURED_AT\tLONGITUDE\tLATITUDE\tGPS_VALID\tPHOTO_PATH\tSOURCE_ENTRY\tANTIFAKE\tADDRESS" f)
        (setq n 0)
        (foreach p pms
          (setq n (1+ n) lon (bht:num (nth 2 p)) lat (bht:num (nth 3 p))
                valid (if (and lon lat (or (> (abs lon) 0.001) (> (abs lat) 0.001))) "1" "0"))
          (write-line (bht:join (mapcar 'bht:clean
                                        (list (bht:make-id ds "P" n) (nth 0 p) (nth 1 p) (nth 2 p) (nth 3 p)
                                              valid (nth 4 p) (nth 4 p) (nth 5 p) (nth 6 p)))
                                "\t") f))
        (close f)
        n)
      nil))
)

;; Toan bo quy trinh KMZ -> TSV. Tra ve duong dan TSV hoac nil.
(defun bht:kmz-build (kmz dest ds overwrite / r kml pms tsv n)
  (setq dest (bht:slash dest))
  (bht:msg "BHT KMZ: đang giải nén ảnh (có thể mất vài phút với KMZ lớn)...")
  (if (setq r (bht:kmz-extract kmz dest))
    (progn
      (setq kml (strcat dest "doc.kml"))
      (if (not (vl-file-size kml))
        (progn (bht:msg "BHT KMZ: không thấy doc.kml trong KMZ.") nil)
        (progn
          (setq pms (bht:kml-placemarks kml) tsv (strcat dest "BHT_PHOTO.tsv"))
          (setq n (bht:write-photo-tsv tsv pms ds overwrite))
          (if n
            (bht:msg (strcat "BHT KMZ: " (substr r 4) " tệp giải nén; " (itoa n) " Placemark -> " tsv))
            (bht:msg (strcat "BHT KMZ: đã có " tsv " - giữ nguyên, không ghi đè.")))
          tsv)))
    nil)
)

(defun c:BHTKMZ (/ *error* kmz dest ds ans tsv res ow)
  (setq *error* bht:on-error)
  (if (setq kmz (getfiled "Chọn KMZ TimeMark (chỉ đọc, không sửa)" (bht:dwg-folder) "kmz" 0))
    (progn
      (setq ds (strcase (bht:ask-string "Mã dataset cho ID ảnh (vd BOT19)" (bht:meta "dataset_cuoi" "BOT19"))))
      (setq dest (bht:ask-string "Thư mục xuất ảnh" (strcat (bht:dwg-folder) "BHT_ANH\\" (vl-filename-base kmz))))
      (setq ow nil)
      (if (vl-file-size (strcat (bht:slash dest) "BHT_PHOTO.tsv"))
        (setq ow (= (strcase (bht:ask-string "Đã có BHT_PHOTO.tsv. Ghi đè? [C/K]" "K")) "C")))
      (if (and (bht:valid-id ds) (setq tsv (bht:kmz-build kmz dest ds ow)))
        (progn
          (setq ans (strcase (bht:ask-string "Nạp chỉ mục ảnh vào bản vẽ ngay? [C/K]" "C")))
          (if (= ans "C")
            (bht:photo-report (bht:photo-import-tsv tsv
                                (= (strcase (bht:ask-string "Vẽ ký hiệu vị trí chụp? [C/K]" "C")) "C"))))))))
  (bht:log-flush)
  (princ)
)

;;; ---- Duong dan / mo anh ------------------------------------------------

(defun bht:open-file (path / wsh rc)
  (setq wsh (vl-catch-all-apply 'vlax-create-object (list "WScript.Shell")))
  (if (and wsh (not (vl-catch-all-error-p wsh)))
    (progn
      (setq rc (vl-catch-all-apply 'vlax-invoke-method (list wsh 'Run (strcat "\"" path "\"") 1 :vlax-false)))
      (vlax-release-object wsh)
      (not (vl-catch-all-error-p rc)))
    (progn (startapp "explorer.exe" (strcat "\"" path "\"")) T))
)

;;; ----------------------------------------------------------------------
;;; 0.3.2: Ky hieu anh, nhan ma anh, duong dan JPG, xem anh, raster
;;;  Ky hieu: INSERT block BHT_ANH_GPS, layer BHT_ANH_GPS, XData BHT_ANHPT (photo_id)
;;;  Nhan:    TEXT layer BHT_ANH_TEN, XData BHT_ANHTEN (photo_id)
;;;  Raster:  IMAGE layer BHT_ANH_RASTER, XData BHT_ANHRS (photo_id) -
;;;           CHI chen khi nguoi dung chon anh (BHTCHENANH).
;;;  Ban ghi PHOTO la nguon su that; ky hieu / nhan duoc dong bo lai tu do.
;;;  Anh GPS 0,0 / khong GPS: giu ban ghi, KHONG BAO GIO dat ky hieu (khong
;;;  dat o goc 0,0); chi ghep thu cong.
;;;  AutoCAD DCL khong hien duoc JPG: xem anh bang trinh xem cua Windows
;;;  (lien ket mo tep mac dinh) hoac chen raster IMAGE vao ban ve.
;;; ----------------------------------------------------------------------

(defun bht:photo-block ()
  (bht:layer "BHT_ANH_GPS" 4)
  (bht:regapp "BHT_ANHPT")
  (bht:block "BHT_ANH_GPS" (bht:poly-g '((0.0 1.0 0.0) (-0.866 -0.5 0.0) (0.866 -0.5 0.0))))
)

;; Vi tri chup (E N) theo he dang chon, hoac nil neu GPS khong hop le.
(defun bht:photo-expected (rec z / lon lat)
  (if (= (bht:get rec "gps_hop_le") "1")
    (progn
      (setq lon (bht:num (bht:get rec "lon")) lat (bht:num (bht:get rec "lat")))
      (if (and lon lat (or (> (abs lon) 0.001) (> (abs lat) 0.001)))
        (bht:project lon lat (caddr z) (cadddr z))
        nil))
    nil)
)

(defun bht:photo-scale (/ s)
  (setq s (bht:num (bht:meta "anh_scale" "1")))
  (if (and s (> s 0)) s 1.0)
)

;; Tao 1 ky hieu anh (XData gan ngay khi tao).
(defun bht:photo-marker (id e n / s)
  (setq s (bht:photo-scale))
  (bht:photo-block)
  (entmakex (list '(0 . "INSERT") '(410 . "Model") '(2 . "BHT_ANH_GPS") '(8 . "BHT_ANH_GPS") (list 10 e n 0.0)
                  (cons 41 s) (cons 42 s) (cons 43 s) '(50 . 0.0)
                  (list -3 (list "BHT_ANHPT" (cons 1000 id)))))
)

(defun bht:photo-label-make (id pt h style)
  (entmakex (list '(0 . "TEXT") '(410 . "Model") '(8 . "BHT_ANH_TEN") (cons 10 pt) (cons 40 h) (cons 1 id) '(50 . 0.0)
                  (cons 7 style) '(72 . 0) '(73 . 0)
                  (list -3 (list "BHT_ANHTEN" (cons 1000 id)))))
)

;; Dong bo ky hieu + nhan ma anh tu ban ghi PHOTO. Khong nhan doi.
;;  - anh GPS hop le: tinh lai E/N theo he hien tai; tao ky hieu neu thieu,
;;    doi vi tri/ty le neu lech, xoa ky hieu trung;
;;  - anh GPS 0,0: xoa moi ky hieu/nhan cua anh do (ban ghi giu nguyen);
;;  - ky hieu/nhan khong con ban ghi: xoa (chi thuc the mang XData BHT anh).
;; Tra ve assoc: valid invalid created updated kept duplicates removed labels-created labels-updated
(defun bht:photo-sync (/ z mk lb style h s rec en pt g d nd created updated kept dupdel removed invalid
                         lcreated lupdated valid seen)
  (setq z (bht:crs-current) created 0 updated 0 kept 0 dupdel 0 removed 0 invalid 0 lcreated 0 lupdated 0
        valid 0 seen nil s (bht:photo-scale)
        h (bht:num (bht:meta "anh_nhan_h" "1.0"))
        style (bht:text-style (bht:meta "nhan_kieu_chu" "BHT_ARIAL")))
  (if (or (null h) (<= h 0)) (setq h 1.0))
  (bht:photo-block)
  (bht:layer "BHT_ANH_TEN" 4)
  (bht:regapp "BHT_ANHTEN")
  (setq mk (bht:group-pairs (bht:tagged-pairs "INSERT" "BHT_ANHPT" 1))
        lb (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_ANHTEN" 1)))
  (foreach pid (bht:rec-keys "PHOTO")
    (setq rec (bht:photo-read pid) en (bht:photo-expected rec z) seen (cons pid seen))
    (if en
      (progn
        (setq valid (1+ valid))
        ;; E/N cua ban ghi anh theo he hien tai (KHONG dong vao diem RTK)
        (if (or (/= (bht:get rec "e") (bht:fnum (car en) 3)) (/= (bht:get rec "n") (bht:fnum (cadr en) 3))
                (/= (bht:get rec "crs") (cadr z)))
          (bht:photo-write pid (bht:set (bht:set (bht:set rec "e" (bht:fnum (car en) 3))
                                                 "n" (bht:fnum (cadr en) 3)) "crs" (cadr z))))
        ;; ky hieu
        (setq pt (list (car en) (cadr en) 0.0) g (cdr (assoc pid mk)))
        (foreach e (cdr g) (entdel e) (setq dupdel (1+ dupdel)))
        (if (and (car g) (setq d (entget (car g))))
          (progn
            (setq nd (bht:dxf-put (bht:dxf-put (bht:dxf-put (bht:dxf-put d 10 pt) 41 s) 42 s) 43 s))
            (if (equal nd d)
              (setq kept (1+ kept))
              (progn (entmod nd) (entupd (car g)) (setq updated (1+ updated)))))
          (if (bht:photo-marker pid (car en) (cadr en)) (setq created (1+ created))))
        ;; nhan ma anh
        (setq pt (list (+ (car en) (* 1.2 s)) (+ (cadr en) (* 0.3 s)) 0.0) g (cdr (assoc pid lb)))
        (foreach e (cdr g) (entdel e) (setq dupdel (1+ dupdel)))
        (if (and (car g) (setq d (entget (car g))))
          (progn
            (setq nd (bht:dxf-put (bht:dxf-put (bht:dxf-put (bht:dxf-put d 10 pt) 40 h) 7 style) 1 pid))
            (if (not (equal nd d)) (progn (entmod nd) (entupd (car g)) (setq lupdated (1+ lupdated)))))
          (if (bht:photo-label-make pid pt h style) (setq lcreated (1+ lcreated)))))
      (progn
        (setq invalid (1+ invalid))
        (if (or (/= (bht:get rec "e") "") (/= (bht:get rec "n") ""))
          (bht:photo-write pid (bht:set (bht:set rec "e" "") "n" "")))
        (foreach e (cdr (assoc pid mk)) (entdel e) (setq removed (1+ removed)))
        (foreach e (cdr (assoc pid lb)) (entdel e) (setq removed (1+ removed)))))
    (bht:test-tick))
  (foreach g2 mk (if (not (member (car g2) seen)) (foreach e (cdr g2) (entdel e) (setq removed (1+ removed)))))
  (foreach g2 lb (if (not (member (car g2) seen)) (foreach e (cdr g2) (entdel e) (setq removed (1+ removed)))))
  (bht:leader-sync)
  (bht:layer-on "BHT_ANH_TEN" (/= (bht:meta "anh_nhan_an" "0") "1"))
  (bht:log (strcat "Đồng bộ ký hiệu ảnh: GPS hợp lệ " (itoa valid) ", không GPS " (itoa invalid)
                   ", tạo " (itoa created) ", cập nhật " (itoa updated) ", xóa trùng " (itoa dupdel)
                   ", xóa thừa " (itoa removed)))
  (list (cons 'valid valid) (cons 'invalid invalid) (cons 'created created) (cons 'updated updated)
        (cons 'kept kept) (cons 'duplicates dupdel) (cons 'removed removed)
        (cons 'labels-created lcreated) (cons 'labels-updated lupdated))
)

(defun bht:photo-sync-report (r)
  (bht:msg (strcat "BHT ký hiệu ảnh: tạo " (itoa (cdr (assoc 'created r)))
                   ", dời vị trí/tỷ lệ " (itoa (cdr (assoc 'updated r)))
                   ", giữ nguyên " (itoa (cdr (assoc 'kept r)))
                   ", xóa trùng " (itoa (cdr (assoc 'duplicates r)))
                   ", xóa thừa/ảnh không GPS " (itoa (cdr (assoc 'removed r)))
                   " | nhãn mã ảnh: tạo " (itoa (cdr (assoc 'labels-created r)))
                   ", cập nhật " (itoa (cdr (assoc 'labels-updated r))) "."))
)

;;; ---- Duong dan JPG ------------------------------------------------------

;; Cac duong dan thu theo thu tu: file_tt (da chi lai), goc + tuong doi,
;; thu_muc_anh + tuong doi / ten file / photos\ten file, thu muc DWG + tuong doi.
(defun bht:photo-path-candidates (rec / rel base alt goc tt out)
  (setq rel (vl-string-translate "/" "\\" (bht:get rec "duong_dan"))
        base (if (/= rel "") (strcat (vl-filename-base rel) (if (vl-filename-extension rel) (vl-filename-extension rel) "")) "")
        alt (bht:meta "thu_muc_anh" "") goc (bht:get rec "goc") tt (bht:get rec "file_tt") out nil)
  (if (/= tt "") (setq out (list tt)))
  (if (/= rel "")
    (progn
      (if (/= goc "") (setq out (append out (list (strcat (bht:slash goc) rel)))))
      (if (/= alt "")
        (setq out (append out (list (strcat (bht:slash alt) rel) (strcat (bht:slash alt) base)
                                    (strcat (bht:slash alt) "photos\\" base)))))
      (if (/= (getvar "DWGPREFIX") "")
        (setq out (append out (list (strcat (bht:dwg-folder) rel)))))))
  out
)

(defun bht:photo-path (rec / hit)
  (setq hit nil)
  (foreach p (bht:photo-path-candidates rec) (if (and (null hit) (bht:file-ok p)) (setq hit p)))
  hit
)

;; 0.3.3: tim JPG cua ban ghi trong thu muc nguoi dung chi dinh (uu tien khi chi lai).
(defun bht:photo-path-in (folder rec / rel base hit)
  (setq rel (vl-string-translate "/" "\\" (bht:get rec "duong_dan"))
        base (if (/= rel "") (strcat (vl-filename-base rel) (if (vl-filename-extension rel) (vl-filename-extension rel) "")) "")
        hit nil)
  (if (/= rel "")
    (foreach p (list (strcat (bht:slash folder) rel) (strcat (bht:slash folder) base) (strcat (bht:slash folder) "photos\\" base))
      (if (and (null hit) (bht:file-ok p)) (setq hit p))))
  hit
)

;; Chi lai thu muc anh (sau khi chuyen thu muc du an). Tra ve (tim_thay thieu).
(defun bht:photo-relink (folder / found miss rec p old)
  (setq folder (vl-string-right-trim "\\/" (bht:trim folder)) found 0 miss 0)
  (bht:meta-set "thu_muc_anh" folder)
  (foreach pid (bht:rec-keys "PHOTO")
    (setq rec (bht:photo-read pid) old (bht:get rec "file_tt")
          p (bht:photo-path-in folder rec))
    (if (null p) (setq p (bht:photo-path (bht:set rec "file_tt" ""))))
    (if p (setq found (1+ found)) (setq miss (1+ miss)))
    (if (/= (if p p "") old) (bht:photo-write pid (bht:set rec "file_tt" (if p p "")))))
  (bht:raster-repath)
  (bht:log (strcat "Chỉ lại thư mục ảnh " folder ": tìm thấy " (itoa found) ", thiếu " (itoa miss)))
  (list found miss)
)

;; Thong ke anh: tong, GPS, JPG, ky hieu, ghep.
(defun bht:photo-stats (/ mk total valid inv found miss mkd linked rec)
  (setq total 0 valid 0 inv 0 found 0 miss 0 mkd 0 linked 0
        mk (bht:group-pairs (bht:tagged-pairs "INSERT" "BHT_ANHPT" 1)))
  (foreach pid (bht:rec-keys "PHOTO")
    (setq rec (bht:photo-read pid) total (1+ total))
    (if (= (bht:get rec "gps_hop_le") "1")
      (progn (setq valid (1+ valid)) (if (assoc pid mk) (setq mkd (1+ mkd))))
      (setq inv (1+ inv)))
    (if (bht:photo-path rec) (setq found (1+ found)) (setq miss (1+ miss)))
    (if (bht:get-all rec "doi_tuong") (setq linked (1+ linked))))
  (list (cons 'total total) (cons 'valid valid) (cons 'invalid inv) (cons 'jpg-found found)
        (cons 'jpg-missing miss) (cons 'markers mkd) (cons 'markers-missing (- valid mkd))
        (cons 'linked linked) (cons 'unlinked (- total linked)))
)

(defun bht:photo-stats-report (s)
  (bht:msg (strcat "BHT kiểm tra ảnh: tổng " (itoa (cdr (assoc 'total s)))
                   " bản ghi | GPS hợp lệ " (itoa (cdr (assoc 'valid s)))
                   ", thiếu GPS (0,0) " (itoa (cdr (assoc 'invalid s)))
                   " | JPG tìm thấy " (itoa (cdr (assoc 'jpg-found s)))
                   ", JPG thiếu " (itoa (cdr (assoc 'jpg-missing s)))
                   " | ký hiệu đã có " (itoa (cdr (assoc 'markers s)))
                   ", ký hiệu thiếu " (itoa (cdr (assoc 'markers-missing s)))
                   " | đã ghép " (itoa (cdr (assoc 'linked s)))
                   ", chưa ghép " (itoa (cdr (assoc 'unlinked s))) "."))
  (if (> (cdr (assoc 'invalid s)) 0)
    (bht:msg "  Ảnh thiếu GPS được GIỮ, không đặt ký hiệu (không đặt ở gốc 0,0); ghép thủ công bằng BHTGANANH / BHTXEMANH."))
  (if (> (cdr (assoc 'jpg-missing s)) 0)
    (bht:msg "  Có ảnh không tìm thấy file JPG: dùng BHTTHUMUCANH để chỉ lại thư mục ảnh (thư mục có BHT_PHOTO.tsv hoặc thư mục photos)."))
  (if (> (cdr (assoc 'markers-missing s)) 0)
    (bht:msg "  Có ảnh GPS hợp lệ chưa có ký hiệu: chạy BHTDONGBOANH."))
)

(defun c:BHTDONGBOANH (/ *error* r)
  (setq *error* bht:on-error)
  (if (null (bht:rec-keys "PHOTO"))
    (bht:msg "BHT: chưa có bản ghi ảnh. Dùng BHTKMZ hoặc BHTANHNAP trước.")
    (progn
      (setq r (bht:photo-sync))
      (bht:photo-sync-report r)
      (bht:photo-stats-report (bht:photo-stats))))
  (bht:log-flush)
  (princ)
)
(defun c:BHTSYNCANH () (c:BHTDONGBOANH))

;; Bat/tat nhan ma anh (layer BHT_ANH_TEN; khong xoa).
(defun c:BHTNHANANH (/ *error*)
  (setq *error* bht:on-error)
  (if (= (bht:meta "anh_nhan_an" "0") "1")
    (progn (bht:meta-set "anh_nhan_an" "0") (bht:layer-on "BHT_ANH_TEN" T)
           (bht:msg "BHT: đã HIỆN nhãn mã ảnh (layer BHT_ANH_TEN)."))
    (progn (bht:meta-set "anh_nhan_an" "1") (bht:layer-on "BHT_ANH_TEN" nil)
           (bht:msg "BHT: đã ẨN nhãn mã ảnh (layer BHT_ANH_TEN tắt, không xóa).")))
  (princ)
)

(defun c:BHTTHUMUCANH (/ *error* v f r)
  (setq *error* bht:on-error)
  (bht:msg (strcat "Thư mục ảnh thay thế hiện tại: " (bht:meta "thu_muc_anh" "(chưa đặt)")))
  (setq v (strcase (bht:ask-string "[F=chọn một file JPG/BHT_PHOTO.tsv trong thư mục ảnh mới/G=gõ đường dẫn thư mục]" "F")))
  (cond
    ((= v "F")
     (if (setq f (getfiled "Chọn một ảnh JPG hoặc BHT_PHOTO.tsv trong thư mục ảnh mới" (bht:dwg-folder) "jpg;jpeg;tsv" 0))
       (setq v (vl-filename-directory f))
       (setq v nil)))
    ((= v "G") (setq v (bht:ask-string "Đường dẫn thư mục ảnh" (bht:meta "thu_muc_anh" ""))))
    (T (setq v nil)))
  (if (and v (/= v ""))
    (progn
      (setq r (bht:photo-relink v))
      (bht:msg (strcat "BHT: thư mục ảnh = " v " | tìm thấy " (itoa (car r)) " JPG, thiếu " (itoa (cadr r)) "."))
      (if (> (cadr r) 0)
        (bht:msg "  Ảnh còn thiếu: kiểm tra lại thư mục (chọn thư mục có BHT_PHOTO.tsv hoặc thư mục photos) hoặc chạy lại BHTKMZ."))))
  (bht:log-flush)
  (princ)
)

;;; ---- Xem anh -------------------------------------------------------------

(defun bht:photo-ids-sorted () (acad_strlsort (bht:rec-keys "PHOTO")))

;; Anh ke tiep (step = 1) / truoc (step = -1) theo ma anh; nil neu het.
(defun bht:photo-neighbor (pid step / ids pos)
  (setq ids (bht:photo-ids-sorted) pos (vl-position (strcase pid) ids))
  (cond ((null pos) nil)
        ((< (+ pos step) 0) nil)
        (T (nth (+ pos step) ids)))
)

(defun bht:photo-info-lines (pid / rec p)
  (setq pid (strcase pid) rec (bht:photo-read pid))
  (if (null rec)
    (list (strcat "Không có ảnh " pid "."))
    (progn
      (setq p (bht:photo-path rec))
      (list (strcat "=== Ảnh " pid " ===")
            (strcat "  thời gian chụp: " (bht:get rec "thoi_gian") " | tên: " (bht:get rec "ten"))
            (strcat "  GPS (WGS84): " (bht:get rec "lon") ", " (bht:get rec "lat")
                    (if (= (bht:get rec "gps_hop_le") "1") ""
                      " -> GPS 0,0/không có: KHÔNG đặt ký hiệu, chỉ ghép thủ công"))
            (strcat "  vị trí chụp E,N: " (if (/= (bht:get rec "e") "")
                                            (strcat (bht:get rec "e") ", " (bht:get rec "n") " (" (bht:get rec "crs") ")")
                                            "(không có)"))
            (strcat "  trạng thái ghép: " (bht:get rec "trang_thai")
                    (if (bht:get-all rec "de_xuat") (strcat " | đề xuất: " (bht:join (bht:get-all rec "de_xuat") "; ")) ""))
            (strcat "  đối tượng đã xác nhận: " (if (bht:get-all rec "doi_tuong") (bht:join (bht:get-all rec "doi_tuong") ", ") "(chưa)"))
            (strcat "  địa chỉ: " (bht:get rec "dia_chi"))
            (if p
              (strcat "  file JPG: " p)
              (strcat "  THIẾU FILE JPG: " (bht:get rec "duong_dan") " - đã tìm ở: "
                      (bht:join (bht:photo-path-candidates rec) " ; ") ". Dùng BHTTHUMUCANH.")))))
)

;; Mo JPG bang trinh xem mac dinh cua Windows. Tra ve (T duong_dan) / (nil ly_do).
;; *bht-no-launch* = T: chi giai duong dan, khong mo (dung trong kiem thu).
(defun bht:photo-open (pid / rec p)
  (setq pid (strcase pid) rec (bht:photo-read pid))
  (cond ((null rec) (list nil (strcat "không có ảnh " pid)))
        ((null (setq p (bht:photo-path rec)))
         (list nil (strcat "không tìm thấy file JPG " (bht:get rec "duong_dan") " của " pid " - dùng BHTTHUMUCANH")))
        (*bht-no-launch* (list T p))
        ((bht:open-file p) (list T p))
        (T (list nil (strcat "không mở được trình xem ảnh cho " p))))
)

;; Anh lien quan toi diem RTK: (da_xac_nhan de_xuat gan_diem).
;; gan_diem = anh co vi tri chup trong ban kinh ghep_r (CHI la goi y).
(defun bht:photos-for-point (pid / owners linked sug near r p xyz rec e n d tg)
  (setq pid (strcase pid) owners (cdr (assoc pid (bht:pt-owner-map))) linked nil sug nil near nil
        r (bht:num (bht:meta "ghep_r" "10")) p (bht:pt-find pid (bht:pt-all)))
  (if (null r) (setq r 10.0))
  (foreach o owners
    (foreach a (bht:get-all (bht:obj-read o) "anh")
      (setq linked (bht:unique-add linked (strcase (car (bht:split a "|")))))))
  (setq xyz (if p (bht:pv p 'xyz) nil))
  (foreach ph (bht:rec-keys "PHOTO")
    (setq rec (bht:photo-read ph))
    (foreach s (bht:get-all rec "de_xuat")
      (setq tg (strcase (car (bht:split s "|"))))
      (if (and (not (member ph linked))
               (or (= tg (strcat "P:" pid))
                   (and (bht:starts tg "O:") (member (substr tg 3) owners))))
        (setq sug (bht:unique-add sug ph))))
    (if (and xyz (not (member ph linked)) (not (member ph sug))
             (setq e (bht:num (bht:get rec "e"))) (setq n (bht:num (bht:get rec "n"))))
      (if (<= (setq d (distance (list e n) (list (car xyz) (cadr xyz)))) r)
        (setq near (cons (cons d ph) near)))))
  (setq near (mapcar 'cdr (vl-sort near '(lambda (a b) (< (car a) (car b))))))
  (list linked sug near)
)

;; Anh lien quan toi 1 thuc the: (da_xac_nhan de_xuat gan_diem) hoac nil.
(defun bht:photos-for-ent (ent / x)
  (cond
    ((null ent) nil)
    ((setq x (bht:xget ent "BHT_ANHPT")) (list (list (strcase (car x))) nil nil))
    ((setq x (bht:xget ent "BHT_ANHTEN")) (list (list (strcase (car x))) nil nil))
    ((setq x (bht:xget ent "BHT_ANHRS")) (list (list (strcase (car x))) nil nil))
    ((setq x (bht:xget ent "BHT_NHAN")) (bht:photos-for-point (car x)))
    ((setq x (bht:xget ent "BHT_PT")) (bht:photos-for-point (car x)))
    ((setq x (bht:xget ent "BHT_KH"))
     (list (mapcar '(lambda (a) (strcase (car (bht:split a "|")))) (bht:get-all (bht:obj-read (car x)) "anh")) nil nil))
    (T nil))
)

(defun bht:photo-pick (/ sel ent res all v)
  (initget "Ma")
  (setq sel (entsel "\nChọn ký hiệu ảnh / điểm RTK / nhãn / ảnh raster hoặc [Ma = nhập mã ảnh]: "))
  (cond
    ((= sel "Ma")
     (setq v (strcase (bht:ask-string "Mã ảnh (vd BOT19-P-000001)" "")))
     (cond ((= v "") nil)
           ((bht:photo-read v) v)
           (T (bht:msg (strcat "BHT: không có ảnh " v ".")) nil)))
    ((and sel (setq ent (car sel)))
     (setq res (bht:photos-for-ent ent))
     (if (null res)
       (progn (bht:msg "Đối tượng chọn không mang dữ liệu BHT.") nil)
       (progn
         (setq all (append (car res) (cadr res) (caddr res)))
         (if (car res) (bht:msg (strcat "Ảnh đã xác nhận: " (bht:join (car res) ", "))))
         (if (cadr res) (bht:msg (strcat "Ảnh được đề xuất (CHƯA xác nhận): " (bht:join (cadr res) ", "))))
         (if (caddr res) (bht:msg (strcat "Ảnh chụp gần điểm (chỉ gợi ý theo khoảng cách): " (bht:join (caddr res) ", "))))
         (cond
           ((null all) (bht:msg "Không có ảnh nào đã ghép / đề xuất / chụp gần đối tượng này.") nil)
           ((= (length all) 1) (car all))
           (T (setq v (strcase (bht:ask-string "Mã ảnh cần xem" (car all))))
              (if (bht:photo-read v) v (progn (bht:msg (strcat "BHT: không có ảnh " v ".")) nil)))))))
    (T nil))
)

;; Xem anh: thong tin + mo JPG, anh truoc/sau, gan vao doi tuong (xac nhan thu cong).
(defun bht:photo-browse (pid / v r stop nx oid res sug reopen)
  (setq stop nil reopen T pid (strcase pid))
  (while (and pid (not stop))
    (foreach l (bht:photo-info-lines pid) (bht:msg l))
    (if reopen
      (progn (setq r (bht:photo-open pid))
             (if (not (car r)) (bht:msg (strcat "BHT: " (cadr r))))))
    (setq reopen T)
    (setq v (strcase (bht:ask-string "[S=ảnh sau/T=ảnh trước/G=gắn ảnh này vào đối tượng/M=mở lại/Enter=thoát]" "")))
    (cond
      ((= v "S") (if (setq nx (bht:photo-neighbor pid 1)) (setq pid nx)
                   (progn (bht:msg "Đã ở ảnh cuối.") (setq reopen nil))))
      ((= v "T") (if (setq nx (bht:photo-neighbor pid -1)) (setq pid nx)
                   (progn (bht:msg "Đã ở ảnh đầu.") (setq reopen nil))))
      ((= v "G")
       (setq sug (car (bht:get-all (bht:photo-read pid) "de_xuat"))
             sug (if (and sug (bht:starts sug "O:")) (substr (car (bht:split sug "|")) 3) ""))
       (setq oid (strcase (bht:ask-string "ID đối tượng cần gắn ảnh (xác nhận thủ công)" sug)) reopen nil)
       (if (/= oid "")
         (progn (setq res (bht:photo-link pid oid "THU_CONG"))
                (bht:msg (if (car res) (strcat "BHT: đã gắn " pid " -> " oid ".") (strcat "BHT: " (cadr res)))))))
      ((= v "M") nil)
      (T (setq stop T))))
  (princ)
)

(defun c:BHTXEMANH (/ *error* pid)
  (setq *error* bht:on-error)
  (if (setq pid (bht:photo-pick)) (bht:photo-browse pid))
  (bht:log-flush)
  (princ)
)

;; Tuong thich 0.3.1: BHTANH = mo anh theo ma; them chon tren ban ve.
(defun c:BHTANH (/ *error* v r)
  (setq *error* bht:on-error)
  (setq v (strcase (bht:ask-string "Mã ảnh (vd BOT19-P-000001), [T=đặt thư mục ảnh/Enter=chọn trên bản vẽ]" "")))
  (cond
    ((= v "T")
     (setq v (bht:ask-string "Thư mục chứa ảnh (thư mục có BHT_PHOTO.tsv hoặc photos)" (bht:meta "thu_muc_anh" "")))
     (if (/= v "")
       (progn (setq r (bht:photo-relink v))
              (bht:msg (strcat "BHT: tìm thấy " (itoa (car r)) " JPG, thiếu " (itoa (cadr r)) ".")))))
    ((= v "") (if (setq v (bht:photo-pick)) (bht:photo-browse v)))
    ((bht:photo-read v) (bht:photo-browse v))
    (T (bht:msg (strcat "BHT: không có ảnh " v "."))))
  (bht:log-flush)
  (princ)
)

;;; ---- Raster JPG (chi anh nguoi dung chon) -----------------------------------

(defun bht:raster-pairs () (bht:group-pairs (bht:tagged-pairs "IMAGE" "BHT_ANHRS" 1)))

;; Chen 1 anh lam raster IMAGE. pt nil = dat canh vi tri chup (anh GPS hop le).
;; Tra ve (T ent) / (EXISTS ent) / (nil ly_do). Khong chen trung cung 1 anh.
(defun bht:raster-insert (pid pt width / rec path en ex last ent d px w guard)
  (setq pid (strcase pid) rec (bht:photo-read pid))
  (cond
    ((null rec) (list nil (strcat "không có ảnh " pid)))
    ((setq ex (car (cdr (assoc pid (bht:raster-pairs))))) (list 'EXISTS ex))
    ((null (setq path (bht:photo-path rec)))
     (list nil (strcat "không tìm thấy file JPG của " pid " - dùng BHTTHUMUCANH")))
    ((and (null pt) (null (setq en (bht:photo-expected rec (bht:crs-current)))))
     (list nil (strcat pid " không có GPS hợp lệ - cần chọn điểm chèn")))
    ((not (and width (> width 0))) (list nil "chiều rộng ảnh không hợp lệ"))
    (T
     (if (null pt) (setq pt (list (+ (car en) (* 2.0 (bht:photo-scale))) (+ (cadr en) (* 2.0 (bht:photo-scale))) 0.0)))
     (bht:layer "BHT_ANH_RASTER" 6)
     (bht:regapp "BHT_ANHRS")
     (bht:sv-set "CMDECHO" 0)
     (bht:sv-set "OSMODE" 0)
     (bht:ensure-model)
     (setq last (entlast))
     (vl-catch-all-apply 'vl-cmdf (list "_.-IMAGE" "_Attach" path pt 1.0 0.0))
     (setq guard 0)
     (while (and (= 1 (logand 1 (getvar "CMDACTIVE"))) (< guard 5)) (command "") (setq guard (1+ guard)))
     (bht:sv-restore)
     (setq ent (entlast))
     (if (and ent (not (equal ent last)) (= (cdr (assoc 0 (entget ent))) "IMAGE"))
       (progn
         (setq d (entget ent) px (car (cdr (assoc 13 d))))
         (setq w (if (and px (> px 0)) (/ width px) 1.0))
         (setq d (bht:dxf-put d 8 "BHT_ANH_RASTER")
               d (bht:dxf-put d 11 (list w 0.0 0.0))
               d (bht:dxf-put d 12 (list 0.0 w 0.0)))
         (entmod (append d (list (list -3 (list "BHT_ANHRS" (cons 1000 pid))))))
         (entupd ent)
         (bht:log (strcat "Chèn raster ảnh " pid ": " path))
         (list T ent))
       (list nil "lệnh -IMAGE không tạo được ảnh (xem dòng lệnh)"))))
)

;; Go raster cua 1 anh (chi IMAGE mang BHT_ANHRS) + duong dan cua anh do.
;; Tra ve so raster da xoa.
(defun bht:raster-remove (pid / n)
  (setq n 0)
  (foreach e (cdr (assoc (strcase pid) (bht:raster-pairs))) (entdel e) (setq n (1+ n)))
  (bht:leader-sync)
  n
)

;; ---- 0.3.3: duong dan (LINE) tu ky hieu anh toi raster da chen -------------
;;  LINE layer BHT_ANH_DAN, XData BHT_ANHDAN (photo_id). Tu dong cap nhat khi
;;  ky hieu / raster doi cho; tu xoa khi mat ky hieu hoac raster.

(defun bht:leader-pairs () (bht:group-pairs (bht:tagged-pairs "LINE" "BHT_ANHDAN" 1)))

;; Tao duong dan cho 1 anh (neu chua co). Tra ve ename hoac nil.
(defun bht:leader-make (pid / mk rs a b)
  (setq pid (strcase pid)
        mk (car (cdr (assoc pid (bht:group-pairs (bht:tagged-pairs "INSERT" "BHT_ANHPT" 1)))))
        rs (car (cdr (assoc pid (bht:raster-pairs)))))
  (cond
    ((or (null mk) (null rs)) nil)
    ((cdr (assoc pid (bht:leader-pairs))) (car (cdr (assoc pid (bht:leader-pairs)))))
    (T
     (bht:layer "BHT_ANH_DAN" 4)
     (bht:regapp "BHT_ANHDAN")
     (setq a (cdr (assoc 10 (entget mk))) b (cdr (assoc 10 (entget rs))))
     (entmakex (list '(0 . "LINE") '(410 . "Model") '(8 . "BHT_ANH_DAN") (cons 10 a) (cons 11 b)
                     (list -3 (list "BHT_ANHDAN" (cons 1000 pid)))))))
)

;; Dong bo duong dan: xoa neu mat ky hieu/raster, doi dau mut theo vi tri hien tai.
;; Tra ve (cap_nhat xoa).
(defun bht:leader-sync (/ mk rs up del d a b g)
  (setq up 0 del 0
        mk (bht:group-pairs (bht:tagged-pairs "INSERT" "BHT_ANHPT" 1)) rs (bht:raster-pairs))
  (foreach g (bht:leader-pairs)
    (foreach e (cdr (cdr g)) (entdel e) (setq del (1+ del)))
    (if (and (assoc (car g) mk) (assoc (car g) rs))
      (progn
        (setq d (entget (cadr g))
              a (cdr (assoc 10 (entget (cadr (assoc (car g) mk)))))
              b (cdr (assoc 10 (entget (cadr (assoc (car g) rs))))))
        (if (not (and (equal (cdr (assoc 10 d)) a 1e-9) (equal (cdr (assoc 11 d)) b 1e-9)))
          (progn (entmod (bht:dxf-put (bht:dxf-put d 10 a) 11 b)) (entupd (cadr g)) (setq up (1+ up)))))
      (progn (entdel (cadr g)) (setq del (1+ del)))))
  (list up del)
)

(defun c:BHTCHENANH (/ *error* v ids ss i x w n ex bad res pt ld nl)
  (setq *error* bht:on-error)
  (bht:msg "Chèn ảnh JPG làm raster tham chiếu: CHỈ các ảnh bạn chọn (không chèn hàng loạt).")
  (setq v (bht:trim (bht:ask-string "Mã ảnh (cách nhau dấu cách/phẩy), [C=chọn ký hiệu ảnh/X=gỡ raster theo mã]" "C"))
        ids nil n 0 ex 0 bad 0 nl 0)
  (cond
    ((= (strcase v) "X")
     (foreach pid (vl-remove "" (bht:split (bht:replace (bht:ask-string "Mã ảnh cần gỡ raster" "") "," " ") " "))
       (setq n (+ n (bht:raster-remove pid))))
     (bht:msg (strcat "BHT: đã gỡ " (itoa n) " raster (ảnh gốc và bản ghi giữ nguyên).")))
    (T
     (if (= (strcase v) "C")
       (progn
         (bht:msg "Chọn ký hiệu ảnh (BHT_ANH_GPS) cần chèn raster: ")
         (if (setq ss (ssget '((0 . "INSERT") (-3 ("BHT_ANHPT")))))
           (progn (setq i 0)
                  (while (< i (sslength ss))
                    (if (setq x (bht:xget (ssname ss i) "BHT_ANHPT")) (setq ids (bht:unique-add ids (strcase (car x)))))
                    (setq i (1+ i))))))
       (setq ids (mapcar 'strcase (vl-remove "" (bht:split (bht:replace v "," " ") " ")))))
     (if (and ids (> (length ids) 20)
              (/= (strcase (bht:ask-string (strcat "Sẽ chèn " (itoa (length ids)) " ảnh raster (nặng bản vẽ). Tiếp tục? [C/K]") "K")) "C"))
       (setq ids nil))
     (if ids
       (progn
         (setq w (bht:num (bht:ask-string "Chiều rộng ảnh trên bản vẽ (đơn vị bản vẽ)" (bht:meta "anh_raster_w" "8"))))
         (setq ld (= (strcase (bht:ask-string "Vẽ đường dẫn từ ký hiệu ảnh tới ảnh raster? [C/K]" (bht:meta "anh_duong_dan" "K"))) "C"))
         (bht:meta-set "anh_duong_dan" (if ld "C" "K"))
         (if (and w (> w 0))
           (progn
             (bht:meta-set "anh_raster_w" (bht:fnum w 3))
             (foreach pid ids
               (setq res (bht:raster-insert pid nil w))
               (if (and (not (car res)) (wcmatch (bht:str (cadr res)) "*GPS*"))
                 (if (setq pt (getpoint (strcat "\nChọn điểm chèn cho ảnh " pid " (không có GPS): ")))
                   (setq res (bht:raster-insert pid (trans pt 1 0) w))))
               (cond ((= (car res) T) (setq n (1+ n)))
                     ((= (car res) 'EXISTS) (setq ex (1+ ex)))
                     (T (setq bad (1+ bad)) (bht:msg (strcat "  " pid ": " (bht:str (cadr res))))))
               (if (and ld (member (car res) (list T 'EXISTS)) (bht:leader-make pid)) (setq nl (1+ nl))))
             (bht:msg (strcat "BHT raster: chèn " (itoa n) ", đã có sẵn " (itoa ex) ", lỗi " (itoa bad)
                              " (layer BHT_ANH_RASTER)" (if ld (strcat ", đường dẫn " (itoa nl)) "") "."))
             (bht:msg "  Gõ BHTTHUTUVE để đưa nhãn / ký hiệu lên trên raster."))
           (bht:msg "BHT: chiều rộng không hợp lệ."))))))
  (bht:sv-restore)
  (bht:log-flush)
  (princ)
)

;; Cap nhat duong dan IMAGEDEF cua raster BHT theo duong dan anh hien tai.
(defun bht:raster-repath (/ n rec p def dd)
  (setq n 0)
  (foreach g (bht:raster-pairs)
    (setq rec (bht:photo-read (car g)) p (if rec (bht:photo-path rec) nil))
    (if p
      (foreach e (cdr g)
        (if (and (setq def (cdr (assoc 340 (entget e)))) (setq dd (entget def)) (assoc 1 dd)
                 (/= (strcase (cdr (assoc 1 dd))) (strcase p)))
          (progn (entmod (subst (cons 1 p) (assoc 1 dd) dd)) (setq n (1+ n)))))))
  n
)


;;; ---- Lien ket anh <-> doi tuong ---------------------------------------
;;; Doi tuong: "anh" = "photo_id|trang_thai|nguon" ; Anh: "doi_tuong" = object_id

(defun bht:photo-link (pid oid how / prec orec lst)
  (setq pid (strcase pid) oid (strcase oid)
        prec (bht:photo-read pid) orec (bht:obj-read oid))
  (cond
    ((null prec) (list nil (strcat "không có ảnh " pid)))
    ((null orec) (list nil (strcat "không có đối tượng " oid)))
    (T
     (setq lst (vl-remove-if '(lambda (a) (= (strcase (car (bht:split a "|"))) pid)) (bht:get-all orec "anh")))
     (setq lst (append lst (list (strcat pid "|DA_XAC_NHAN|" how))))
     (bht:obj-write oid (bht:set-all orec "anh" lst))
     (setq prec (bht:set-all prec "doi_tuong" (bht:unique-add (bht:get-all prec "doi_tuong") oid))
           prec (bht:set prec "trang_thai" "DA_XAC_NHAN"))
     (bht:photo-write pid prec)
     (bht:log (strcat "Liên kết ảnh " pid " -> " oid " (" how ")"))
     (list T pid)))
)

(defun bht:photo-unlink-side (pid oid / prec lst)
  (setq prec (bht:photo-read pid))
  (if prec
    (progn
      (setq lst (vl-remove (strcase oid) (mapcar 'strcase (bht:get-all prec "doi_tuong"))))
      (setq prec (bht:set-all prec "doi_tuong" lst))
      (if (null lst) (setq prec (bht:set prec "trang_thai" "CHUA_GHEP")))
      (bht:photo-write pid prec)))
)

(defun bht:photo-unlink (pid oid / orec)
  (setq pid (strcase pid) oid (strcase oid) orec (bht:obj-read oid))
  (if orec
    (bht:obj-write oid (bht:set-all orec "anh"
                          (vl-remove-if '(lambda (a) (= (strcase (car (bht:split a "|"))) pid))
                                        (bht:get-all orec "anh")))))
  (bht:photo-unlink-side pid oid)
  (bht:log (strcat "Bỏ liên kết ảnh " pid " - " oid))
)

;; Doi tuong v0.1: lien ket duong dan file anh tuy y.
(defun bht:obj-add-file (oid path / orec)
  (setq orec (bht:obj-read oid))
  (if (and orec (not (member path (bht:get-all orec "anh_file"))))
    (progn (bht:obj-write oid (bht:set-all orec "anh_file" (append (bht:get-all orec "anh_file") (list path)))) T)
    nil)
)

;;; ---- De xuat ghep anh (KHONG tu lien ket) ------------------------------
;; Ung vien: doi tuong (khoang cach toi diem RTK gan nhat cua doi tuong) va
;; diem RTK chua thuoc doi tuong nao.
(defun bht:match-candidates (index owners / out o d best p)
  (setq out nil)
  (foreach o (bht:rec-all "OBJ")
    (setq best nil)
    (foreach pid (bht:get-all (cdr o) "pt")
      (if (setq p (bht:pt-find pid index))
        (setq best (cons (bht:pv p 'xyz) best))))
    (if best (setq out (cons (list (strcat "O:" (car o)) best) out))))
  (foreach it index
    (if (not (assoc (car it) owners))
      (setq out (cons (list (strcat "P:" (bht:pv (cdr it) 'id)) (list (bht:pv (cdr it) 'xyz))) out))))
  out
)

;; Tinh de xuat cho moi anh GPS hop le chua xac nhan.
;; Tra ve assoc: suggested ambiguous none skipped
(defun bht:photo-suggest (radius margin / index owners cands z cm k0 prec e n d1 d2 t1 t2 d sug amb none skip lon lat en c xyz)
  (setq index (bht:pt-all) owners (bht:pt-owner-map)
        cands (bht:match-candidates index owners)
        z (bht:crs-current) cm (caddr z) k0 (cadddr z)
        sug 0 amb 0 none 0 skip 0)
  (foreach pid (bht:rec-keys "PHOTO")
    (setq prec (bht:photo-read pid))
    (cond
      ((= (bht:get prec "trang_thai") "DA_XAC_NHAN") (setq skip (1+ skip)))
      ((/= (bht:get prec "gps_hop_le") "1")
       (setq prec (bht:set prec "trang_thai" "CHUA_GHEP")
             prec (bht:set-all prec "de_xuat" nil))
       (bht:photo-write pid prec)
       (setq skip (1+ skip)))
      (T
       ;; tinh lai vi tri theo he hien tai
       (setq lon (bht:num (bht:get prec "lon")) lat (bht:num (bht:get prec "lat"))
             en (bht:project lon lat cm k0) e (car en) n (cadr en)
             prec (bht:set prec "e" (bht:fnum e 3)) prec (bht:set prec "n" (bht:fnum n 3))
             prec (bht:set prec "crs" (cadr z)))
       (setq d1 nil d2 nil t1 nil t2 nil)
       (foreach c cands
         (setq d nil)
         (foreach xyz (cadr c)
           (setq d (if d (min d (distance (list e n) (list (car xyz) (cadr xyz))))
                         (distance (list e n) (list (car xyz) (cadr xyz))))))
         (cond ((or (null d1) (< d d1)) (setq d2 d1 t2 t1 d1 d t1 (car c)))
               ((or (null d2) (< d d2)) (setq d2 d t2 (car c)))))
       (cond
         ((or (null d1) (> d1 radius))
          (setq prec (bht:set prec "trang_thai" "KHONG_CO_DIEM_GAN")
                prec (bht:set-all prec "de_xuat" nil)
                prec (bht:set prec "kc" (if d1 (bht:fnum d1 2) "")))
          (setq none (1+ none)))
         ((and d2 (<= d2 radius) (< (- d2 d1) margin))
          (setq prec (bht:set prec "trang_thai" "MO_HO")
                prec (bht:set-all prec "de_xuat" (list (strcat t1 "|" (bht:fnum d1 2)) (strcat t2 "|" (bht:fnum d2 2))))
                prec (bht:set prec "kc" (bht:fnum d1 2)))
          (setq amb (1+ amb)))
         (T
          (setq prec (bht:set prec "trang_thai" "DE_XUAT")
                prec (bht:set-all prec "de_xuat" (list (strcat t1 "|" (bht:fnum d1 2))))
                prec (bht:set prec "kc" (bht:fnum d1 2)))
          (setq sug (1+ sug))))
       (bht:photo-write pid prec))))
  (bht:log (strcat "Đề xuất ghép ảnh R=" (bht:fnum radius 1) "m, ngưỡng mơ hồ " (bht:fnum margin 1)
                   "m: đề xuất " (itoa sug) ", mơ hồ " (itoa amb) ", không có điểm gần " (itoa none)))
  (list (cons 'suggested sug) (cons 'ambiguous amb) (cons 'none none) (cons 'skipped skip))
)

(defun c:BHTGHEPANH (/ *error* r m res)
  (setq *error* bht:on-error)
  (setq r (bht:num (bht:ask-string "Bán kính tìm điểm quanh vị trí chụp (m)" (bht:meta "ghep_r" "10")))
        m (bht:num (bht:ask-string "Chênh lệch tối thiểu để coi là không mơ hồ (m)" (bht:meta "ghep_m" "2"))))
  (if (and r m (> r 0))
    (progn
      (bht:meta-set "ghep_r" (bht:fnum r 2)) (bht:meta-set "ghep_m" (bht:fnum m 2))
      (setq res (bht:photo-suggest r m))
      (bht:msg (strcat "BHT ghép ảnh (CHỈ ĐỀ XUẤT, chưa liên kết): đề xuất " (itoa (cdr (assoc 'suggested res)))
                       ", mơ hồ " (itoa (cdr (assoc 'ambiguous res)))
                       ", không có điểm trong " (bht:fnum r 1) " m: " (itoa (cdr (assoc 'none res)))
                       ", bỏ qua (đã xác nhận / không GPS) " (itoa (cdr (assoc 'skipped res))) "."))
      (bht:msg "  Dùng BHTXACNHANANH để duyệt và xác nhận từng đề xuất.")))
  (bht:log-flush)
  (princ)
)

;; Chap nhan de xuat: dich O: -> doi tuong; P: -> tao doi tuong moi tu diem.
(defun bht:accept-target (pid target / kind id index res oid)
  (setq kind (substr target 1 2) id (substr target 3))
  (cond
    ((= kind "O:") (bht:photo-link pid id "DE_XUAT_DA_DUYET"))
    ((= kind "P:")
     (setq index (bht:pt-all)
           oid (bht:obj-next-id)
           res (bht:obj-create oid (list (cons "nhom" (bht:suggest-group (list id) index))
                                         (cons "ghi_chu" (strcat "Tạo khi duyệt ảnh " pid)))
                               (list id) nil))
     (if (car res) (bht:photo-link pid oid "DE_XUAT_DA_DUYET") res))
    (T (list nil "đích không hợp lệ")))
)

(defun c:BHTXACNHANANH (/ *error* ids prec st sug ans stop n batch res tg i)
  (setq *error* bht:on-error)
  (setq ids nil)
  (foreach pid (bht:rec-keys "PHOTO")
    (setq st (bht:get (bht:photo-read pid) "trang_thai"))
    (if (member st '("DE_XUAT" "MO_HO")) (setq ids (append ids (list pid)))))
  (bht:msg (strcat "BHT: có " (itoa (length ids)) " ảnh đang chờ duyệt (đề xuất hoặc mơ hồ)."))
  (setq batch (strcase (bht:ask-string "Chấp nhận HÀNG LOẠT các đề xuất KHÔNG mơ hồ trỏ tới đối tượng đã có? [C/K]" "K")))
  (setq n 0 stop nil)
  (foreach pid ids
    (if (not stop)
      (progn
        (setq prec (bht:photo-read pid) st (bht:get prec "trang_thai") sug (bht:get-all prec "de_xuat"))
        (if (and (= batch "C") (= st "DE_XUAT") (bht:starts (car sug) "O:"))
          (progn (setq res (bht:accept-target pid (car (bht:split (car sug) "|"))))
                 (if (car res) (setq n (1+ n))))
          (progn
            (bht:msg (strcat pid " | " (bht:get prec "thoi_gian") " | " st))
            (setq i 0)
            (foreach s sug
              (setq i (1+ i))
              (princ (strcat "\n   " (itoa i) ") " (car (bht:split s "|")) " cách " (cadr (bht:split s "|")) " m")))
            (setq ans (strcase (bht:ask-string "[1/2=chấp nhận đề xuất số/O=nhập ID đối tượng/M=mở ảnh/B=bỏ qua/D=dừng]" "B")))
            (if (= ans "M")
              (progn (if (bht:photo-path prec) (bht:open-file (bht:photo-path prec)))
                     (setq ans (strcase (bht:ask-string "[1/2/O/B/D]" "B")))))
            (cond
              ((and (member ans '("1" "2")) (setq tg (nth (1- (atoi ans)) sug)))
               (setq res (bht:accept-target pid (car (bht:split tg "|"))))
               (if (car res) (setq n (1+ n)) (bht:msg (strcat "  Lỗi: " (cadr res)))))
              ((= ans "O")
               (setq res (bht:photo-link pid (bht:ask-string "ID đối tượng" "") "THU_CONG"))
               (if (car res) (setq n (1+ n)) (bht:msg (strcat "  Lỗi: " (cadr res)))))
              ((= ans "D") (setq stop T))))))))
  (bht:msg (strcat "BHT: đã xác nhận " (itoa n) " liên kết ảnh."))
  (bht:log-flush)
  (princ)
)

(defun c:BHTGANANH (/ *error* oid v ids res n path)
  (setq *error* bht:on-error)
  (if (setq oid (bht:pick-object "Chọn đối tượng để gắn ảnh"))
    (progn
      (setq v (bht:ask-string "Nhập mã ảnh (cách nhau dấu cách/phẩy; ảnh GPS 0,0 cũng gắn được) hoặc [F=chọn file ảnh]" ""))
      (if (= (strcase v) "F")
        (if (setq path (getfiled "Chọn file ảnh" (bht:dwg-folder) "jpg;jpeg;png;*" 0))
          (if (bht:obj-add-file oid path) (bht:msg (strcat "BHT: đã gắn file ảnh cho " oid "."))))
        (progn
          (setq ids (vl-remove "" (bht:split (bht:replace (bht:trim v) "," " ") " ")) n 0)
          (foreach pid ids
            (setq res (bht:photo-link pid oid "THU_CONG"))
            (if (car res) (setq n (1+ n)) (bht:msg (strcat "  Lỗi: " (cadr res)))))
          (bht:msg (strcat "BHT: đã gắn " (itoa n) " ảnh cho " oid "."))))))
  (bht:log-flush)
  (princ)
)
(defun c:BHTPHOTO () (c:BHTGANANH))

(defun c:BHTBOANH (/ *error* oid v)
  (setq *error* bht:on-error)
  (if (setq oid (bht:pick-object "Chọn đối tượng cần bỏ ảnh"))
    (progn
      (bht:msg (strcat "Ảnh hiện có: " (bht:join (bht:get-all (bht:obj-read oid) "anh") "; ")))
      (setq v (strcase (bht:ask-string "Mã ảnh cần bỏ" "")))
      (if (/= v "") (progn (bht:photo-unlink v oid) (bht:msg "BHT: đã bỏ liên kết.")))))
  (bht:log-flush)
  (princ)
)

;;; ----------------------------------------------------------------------
;;; Tuyen tham chieu + moc Km - dictionary "ROUTE"
;;; Truong: route_id handle loai (TIM_DUONG/TIM_RANH/KHAC) max_offset
;;;  ngoai_suy_m chieu (1/-1/"" khi co >=2 moc thi tu suy) nguon tao_luc
;;;  moc* = "dist|ly_trinh_sau|ly_trinh_truoc|nguon|ghi_chu"
;;;  (moc thuong: sau = truoc; diem gay Km: sau (back) khac truoc (ahead))
;;; ----------------------------------------------------------------------

(setq *bht-ratio-tol* 0.03)

;; Kiem tra thuc the lam tuyen. Tra ve (T "") hoac (nil "ly do").
(defun bht:route-check-ent (ent / d typ flags obj oname)
  (if (null ent)
    (list nil "không có đối tượng")
    (progn
      (setq d (entget ent) typ (cdr (assoc 0 d)) flags (cdr (assoc 70 d)))
      (setq obj (vl-catch-all-apply 'vlax-ename->vla-object (list ent))
            oname (if (or (null obj) (vl-catch-all-error-p obj)) ""
                    (vl-catch-all-apply 'vla-get-ObjectName (list obj))))
      (if (vl-catch-all-error-p oname) (setq oname ""))
      (cond
        ((or (= typ "ACAD_PROXY_ENTITY") (wcmatch (strcase oname) "*ZOMBIE*,*TDT*,*PROXY*"))
         (list nil (strcat "đối tượng proxy/TDT (" typ (if (/= oname "") (strcat ", " oname) "")
                           ") - KHÔNG dùng để tính lý trình. Hãy xuất/vẽ Polyline tham chiếu thường.")))
        ((= typ "LWPOLYLINE") (list T ""))
        ((and (= typ "POLYLINE") (= 0 (logand (if flags flags 0) (+ 16 64)))) (list T ""))
        (T (list nil (strcat "loại " typ " không được hỗ trợ; chỉ nhận LWPOLYLINE/POLYLINE thường."))))))
)

(defun bht:route-read (id) (bht:rec-read "ROUTE" id))
(defun bht:route-write (id rec) (bht:rec-write "ROUTE" id rec))
(defun bht:route-ids () (bht:rec-keys "ROUTE"))

(defun bht:route-ent (rec / ent)
  (setq ent (handent (bht:get rec "handle")))
  (if (and ent (entget ent)) ent nil)
)

(defun bht:route-create (id ent loai maxoff extrap chieu nguon / chk rec)
  (setq id (strcase id) chk (bht:route-check-ent ent))
  (cond
    ((not (bht:valid-id id)) (list nil "ID tuyến không hợp lệ"))
    ((not (car chk)) chk)
    (T
     (setq rec (list (cons "route_id" id) (cons "handle" (cdr (assoc 5 (entget ent))))
                     (cons "loai" loai) (cons "max_offset" (bht:fnum maxoff 3))
                     (cons "ngoai_suy_m" (bht:fnum extrap 3))
                     (cons "chieu" (if chieu (itoa chieu) ""))
                     (cons "nguon" nguon) (cons "tao_luc" (bht:now))))
     (bht:route-write id rec)
     (bht:log (strcat "Tạo tuyến tham chiếu " id " (" loai ") handle " (bht:get rec "handle")))
     (list T id)))
)

;; Danh sach moc da sap xep: ((dist back ahead nguon ghichu) ...)
(defun bht:route-marks (rec / out f)
  (setq out nil)
  (foreach m (bht:get-all rec "moc")
    (setq f (bht:split m "|"))
    (if (and (bht:num (nth 0 f)) (bht:num (nth 1 f)) (bht:num (nth 2 f)))
      (setq out (cons (list (bht:num (nth 0 f)) (bht:num (nth 1 f)) (bht:num (nth 2 f))
                            (if (nth 3 f) (nth 3 f) "") (if (nth 4 f) (nth 4 f) "")) out))))
  (vl-sort out '(lambda (a b) (< (car a) (car b))))
)

(defun bht:route-add-mark (id dist back ahead nguon note / rec marks)
  (setq rec (bht:route-read id))
  (if rec
    (progn
      (setq marks (bht:get-all rec "moc"))
      ;; khong cho 2 moc cung vi tri
      (if (vl-some '(lambda (m) (< (abs (- (car m) dist)) 0.001)) (bht:route-marks rec))
        (list nil "đã có mốc tại vị trí này (xóa mốc cũ trước)")
        (progn
          (setq marks (append marks (list (bht:join (list (bht:fnum dist 4) (bht:fnum back 4) (bht:fnum ahead 4)
                                                          (bht:replace (bht:clean nguon) "|" "/")
                                                          (bht:replace (bht:clean note) "|" "/")) "|"))))
          (bht:route-write id (bht:set-all rec "moc" marks))
          (bht:log (strcat "Mốc Km tuyến " id ": d=" (bht:fnum dist 3) " sau=" (bht:fmt-km back)
                           " trước=" (bht:fmt-km ahead) " nguồn=" nguon))
          (list T (length marks)))))
    (list nil "không có tuyến"))
)

(defun bht:route-del-mark (id idx / rec marks)
  (setq rec (bht:route-read id) marks (bht:route-marks rec))
  (if (and rec (nth idx marks))
    (progn
      (setq marks (vl-remove (nth idx marks) marks))
      (bht:route-write id (bht:set-all rec "moc"
                            (mapcar '(lambda (m) (bht:join (list (bht:fnum (nth 0 m) 4) (bht:fnum (nth 1 m) 4)
                                                                 (bht:fnum (nth 2 m) 4) (nth 3 m) (nth 4 m)) "|"))
                                    marks)))
      T)
    nil)
)

;; LOI GIAI LY TRINH THUAN TUY (kiem thu duoc):
;; marks: ((dist back ahead ...) ...) da sap xep ; d: khoang cach doc tuyen
;; extrap: so met toi da cho phep ngoai suy ; chieu: 1/-1/nil (khi chi co 1 moc)
;; Tra ve (trang_thai ly_trinh dir he_so ghi_chu)
(defun bht:km-from-dist (marks d extrap chieu / n i a b ratio s dir found mfirst mlast)
  (setq n (length marks))
  (cond
    ((= n 0) (list "CHUA_CO_MOC" nil nil nil "tuyến chưa có mốc Km"))
    ((= n 1)
     (setq a (car marks))
     (cond
       ((null chieu) (list "CHUA_XAC_DINH" nil nil nil "chỉ 1 mốc và chưa khai báo chiều tăng Km"))
       ((> (abs (- d (car a))) extrap)
        (list "CHUA_XAC_DINH" nil chieu nil "ngoài phạm vi cho phép tính từ 1 mốc"))
       (T (list "MOT_MOC" (+ (if (>= d (car a)) (caddr a) (cadr a)) (* chieu (- d (car a))))
                chieu 1.0 (strcat "tính từ 1 mốc " (bht:fmt-km (caddr a)) ", hệ số 1, chưa hiệu chỉnh")))))
    (T
     (setq i 0 found nil)
     (while (and (not found) (< i (1- n)))
       (setq a (nth i marks) b (nth (1+ i) marks))
       (if (and (>= d (car a)) (<= d (car b)))
         (setq found T)
         (setq i (1+ i))))
     (if found
       (progn
         (setq ratio (/ (- (cadr b) (caddr a)) (- (car b) (car a)))
               s (+ (caddr a) (* (- d (car a)) ratio))
               dir (if (< ratio 0.0) -1 1))
         (if (= d (car b)) (setq s (cadr b)))
         (list (if (> (abs (- (abs ratio) 1.0)) *bht-ratio-tol*) "CAN_KIEM_TRA" "NOI_SUY")
               s dir ratio
               (strcat "nội suy giữa mốc " (bht:fmt-km (caddr a)) " và " (bht:fmt-km (cadr b))
                       ", hệ số " (bht:fnum ratio 5))))
       (progn
         (setq mfirst (car marks) mlast (last marks))
         (if (< d (car mfirst))
           (progn
             (setq b (cadr marks)
                   ratio (/ (- (cadr b) (caddr mfirst)) (- (car b) (car mfirst)))
                   dir (if (< ratio 0.0) -1 1))
             (if (<= (- (car mfirst) d) extrap)
               (list "NGOAI_SUY" (+ (cadr mfirst) (* dir (- d (car mfirst)))) dir 1.0
                     (strcat "ngoại suy trước mốc " (bht:fmt-km (cadr mfirst)) " " (bht:fnum (- (car mfirst) d) 2) " m"))
               (list "CHUA_XAC_DINH" nil dir nil "ngoài phạm vi các mốc Km")))
           (progn
             (setq a (nth (- n 2) marks)
                   ratio (/ (- (cadr mlast) (caddr a)) (- (car mlast) (car a)))
                   dir (if (< ratio 0.0) -1 1))
             (if (<= (- d (car mlast)) extrap)
               (list "NGOAI_SUY" (+ (caddr mlast) (* dir (- d (car mlast)))) dir 1.0
                     (strcat "ngoại suy sau mốc " (bht:fmt-km (caddr mlast)) " " (bht:fnum (- d (car mlast)) 2) " m"))
               (list "CHUA_XAC_DINH" nil dir nil "ngoài phạm vi các mốc Km"))))))))
)

;; Diem tren tuyen: (khoang_cach_doc_tuyen offset2d phia_theo_huong_ve diem_chieu)
;; phia: 1 = trai, -1 = phai (theo chieu ve polyline), 0 = tren tuyen
(defun bht:curve-project (ent pt / cp d off par der p1 p2 dx dy cross)
  (setq pt (list (car pt) (cadr pt) (if (caddr pt) (caddr pt) 0.0)))
  (setq cp (vl-catch-all-apply 'vlax-curve-getClosestPointToProjection (list ent pt '(0.0 0.0 1.0))))
  (if (vl-catch-all-error-p cp)
    (setq cp (vl-catch-all-apply 'vlax-curve-getClosestPointTo (list ent pt))))
  (if (or (null cp) (vl-catch-all-error-p cp))
    nil
    (progn
      (setq d (vl-catch-all-apply 'vlax-curve-getDistAtPoint (list ent cp)))
      (if (or (null d) (vl-catch-all-error-p d))
        nil
        (progn
          (setq off (distance (list (car pt) (cadr pt)) (list (car cp) (cadr cp))))
          (setq par (vl-catch-all-apply 'vlax-curve-getParamAtPoint (list ent cp)))
          (setq der (if (and par (not (vl-catch-all-error-p par)))
                      (vl-catch-all-apply 'vlax-curve-getFirstDeriv (list ent par)) nil))
          (if (or (null der) (vl-catch-all-error-p der) (< (+ (abs (car der)) (abs (cadr der))) 1e-12))
            (progn
              (setq p1 (vl-catch-all-apply 'vlax-curve-getPointAtDist (list ent (max 0.0 (- d 0.05))))
                    p2 (vl-catch-all-apply 'vlax-curve-getPointAtDist (list ent (+ d 0.05))))
              (if (vl-catch-all-error-p p2) (setq p2 cp))
              (if (vl-catch-all-error-p p1) (setq p1 cp))
              (setq der (list (- (car p2) (car p1)) (- (cadr p2) (cadr p1)) 0.0))))
          (setq dx (car der) dy (cadr der)
                cross (- (* dx (- (cadr pt) (cadr cp))) (* dy (- (car pt) (car cp)))))
          (list d off (cond ((< off 0.005) 0) ((> cross 0.0) 1) (T -1)) cp)))))
)

;; Ly trinh cua mot diem theo 1 tuyen.
;; Tra ve assoc: status station offset side route dist note ratio
(defun bht:station-route (rec pt / ent pr maxoff km side dir chieu)
  (setq ent (bht:route-ent rec) maxoff (bht:num (bht:get rec "max_offset"))
        chieu (bht:int (bht:get rec "chieu")))
  (cond
    ((null ent) (list (cons 'status "TUYEN_MAT") (cons 'route (bht:get rec "route_id"))
                      (cons 'note "không tìm thấy Polyline tuyến (đã xóa?)")))
    ((not (car (bht:route-check-ent ent)))
     (list (cons 'status "TUYEN_KHONG_HOP_LE") (cons 'route (bht:get rec "route_id"))
           (cons 'note (cadr (bht:route-check-ent ent)))))
    ((null (setq pr (bht:curve-project ent pt)))
     (list (cons 'status "LOI_HINH_HOC") (cons 'route (bht:get rec "route_id")) (cons 'note "không chiếu được lên tuyến")))
    ((and maxoff (> (cadr pr) maxoff))
     (list (cons 'status "XA_TUYEN") (cons 'route (bht:get rec "route_id")) (cons 'offset (cadr pr))
           (cons 'note (strcat "cách tuyến " (bht:fnum (cadr pr) 2) " m > " (bht:fnum maxoff 1) " m"))))
    (T
     (setq km (bht:km-from-dist (bht:route-marks rec) (car pr)
                                (bht:num (bht:get rec "ngoai_suy_m")) chieu)
           dir (caddr km))
     (setq side (cond ((= (caddr pr) 0) "TREN_TUYEN")
                      ((null dir) "CHUA_XAC_DINH")
                      ((= (* (caddr pr) dir) 1) "TRAI")
                      (T "PHAI")))
     (list (cons 'status (car km)) (cons 'station (cadr km)) (cons 'offset (cadr pr))
           (cons 'side side) (cons 'route (bht:get rec "route_id")) (cons 'dist (car pr))
           (cons 'ratio (cadddr km)) (cons 'loai (bht:get rec "loai"))
           (cons 'note (nth 4 km)))))
)

;; Chon tuyen tot nhat (offset nho nhat trong pham vi) trong tat ca tuyen.
(defun bht:station (pt / best r rank)
  (setq best nil)
  (foreach id (bht:route-ids)
    (setq r (bht:station-route (bht:route-read id) pt))
    (if (cdr (assoc 'offset r))
      (if (or (null best)
              (and (= (cdr (assoc 'status best)) "XA_TUYEN") (/= (cdr (assoc 'status r)) "XA_TUYEN"))
              (and (= (= (cdr (assoc 'status best)) "XA_TUYEN") (= (cdr (assoc 'status r)) "XA_TUYEN"))
                   (< (cdr (assoc 'offset r)) (cdr (assoc 'offset best)))))
        (setq best r))
      (if (null best) (setq best r))))
  (if best best (list (cons 'status "CHUA_CO_TUYEN") (cons 'note "chưa khai báo tuyến tham chiếu")))
)

(defun bht:station-determined (st)
  (member st '("NOI_SUY" "CAN_KIEM_TRA" "NGOAI_SUY" "MOT_MOC"))
)

;; Tinh va luu ly trinh cho moi doi tuong. Tra ve (so_da_tinh so_chua_xd)
(defun bht:station-objects (/ index rec pos r ok und st)
  (setq index (bht:pt-all) ok 0 und 0)
  (foreach oid (bht:obj-ids)
    (setq rec (bht:obj-read oid) pos (bht:obj-position rec index))
    (setq r (if pos (bht:station pos) (list (cons 'status "KHONG_CO_VI_TRI") (cons 'note "đối tượng không có điểm RTK"))))
    (setq st (cdr (assoc 'status r)))
    (setq rec (bht:set rec "vi_tri_e" (if pos (bht:fnum (car pos) 3) ""))
          rec (bht:set rec "vi_tri_n" (if pos (bht:fnum (cadr pos) 3) ""))
          rec (bht:set rec "route_id" (bht:str (cdr (assoc 'route r))))
          rec (bht:set rec "trang_thai_km" st)
          rec (bht:set rec "ly_trinh_m" (if (bht:station-determined st) (bht:fnum (cdr (assoc 'station r)) 3) ""))
          rec (bht:set rec "ly_trinh_km" (if (bht:station-determined st) (bht:fmt-km (cdr (assoc 'station r))) ""))
          rec (bht:set rec "offset_m" (if (cdr (assoc 'offset r)) (bht:fnum (cdr (assoc 'offset r)) 3) ""))
          rec (bht:set rec "phia_tuyen" (bht:str (cdr (assoc 'side r))))
          rec (bht:set rec "loai_tuyen" (bht:str (cdr (assoc 'loai r))))
          rec (bht:set rec "nguon_km" (bht:str (cdr (assoc 'note r)))))
    (bht:obj-write oid rec)
    (if (bht:station-determined st) (setq ok (1+ ok)) (setq und (1+ und))))
  (list ok und)
)

(defun c:BHTTUYEN (/ *error* sel ent chk id loai v maxoff extrap res)
  (setq *error* bht:on-error)
  (if (setq sel (entsel "\nChọn Polyline tuyến tham chiếu (KHÔNG chọn tuyến proxy TDT): "))
    (progn
      (setq ent (car sel) chk (bht:route-check-ent ent))
      (if (not (car chk))
        (bht:msg (strcat "BHT: " (cadr chk)))
        (progn
          (setq id (strcase (bht:ask-string "ID tuyến" (strcat "TUYEN" (itoa (1+ (length (bht:route-ids))))))))
          (setq v (strcase (bht:ask-string "Loại tuyến [D=Tim đường/R=Tim rãnh/K=Khác]" "D"))
                loai (cond ((= v "D") "TIM_DUONG") ((= v "R") "TIM_RANH") (T "KHAC")))
          (setq maxoff (bht:num (bht:ask-string "Khoảng cách tối đa từ đối tượng tới tuyến (m)" "100"))
                extrap (bht:num (bht:ask-string "Cho phép ngoại suy ngoài mốc tối đa (m, 0 = không)" "0")))
          (if (and maxoff extrap (> maxoff 0))
            (progn
              (setq res (bht:route-create id ent loai maxoff extrap nil "Polyline người dùng chọn (BHTTUYEN)"))
              (if (car res)
                (bht:msg (strcat "BHT: đã tạo tuyến " id ". Dùng BHTMOCKM để khai báo mốc Km đã xác nhận."))
                (bht:msg (strcat "BHT: " (cadr res))))))))))
  (bht:log-flush)
  (princ)
)

;; Tuong thich v0.1: goc ly trinh tai dau polyline, chieu theo huong ve.
(defun c:BHTROUTE (/ *error* sel ent base maxoff id res)
  (setq *error* bht:on-error)
  (if (setq sel (entsel "\nChọn Polyline tham chiếu: "))
    (progn
      (setq ent (car sel))
      (if (not (car (bht:route-check-ent ent)))
        (bht:msg (strcat "BHT: " (cadr (bht:route-check-ent ent))))
        (progn
          (setq base (bht:parse-km (bht:ask-string "Lý trình tại ĐẦU polyline (vd Km39+000 hoặc 39000)" "")))
          (setq maxoff (bht:num (bht:ask-string "Khoảng cách tối đa tới tuyến (m)" "100")))
          (if (and base maxoff)
            (progn
              (setq id (strcat "TUYEN" (itoa (1+ (length (bht:route-ids))))))
              (setq res (bht:route-create id ent "KHAC" maxoff 1.0e9 1
                          "BHTROUTE (tương thích v0.1): gốc tại đầu polyline, chiều theo hướng vẽ, CHƯA hiệu chỉnh mốc"))
              (if (car res)
                (progn
                  (bht:route-add-mark id 0.0 base base "Gốc nhập tay BHTROUTE" "")
                  (bht:msg (strcat "BHT: đã tạo tuyến " id " (1 mốc gốc). Nên bổ sung mốc Km bằng BHTMOCKM.")))
                (bht:msg (strcat "BHT: " (cadr res))))))))))
  (bht:log-flush)
  (princ)
)

(defun bht:ask-route (/ ids v sel)
  (setq ids (bht:route-ids))
  (cond
    ((null ids) (bht:msg "BHT: chưa có tuyến. Dùng BHTTUYEN trước.") nil)
    ((= (length ids) 1) (car ids))
    (T (setq v (strcase (bht:ask-string (strcat "ID tuyến (" (bht:join ids ", ") ")") (car ids))))
       (if (member v ids) v (progn (bht:msg "Không có tuyến này.") nil))))
)

(defun c:BHTMOCKM (/ *error* id rec ent pt pr v s back ahead src res)
  (setq *error* bht:on-error)
  (if (and (setq id (bht:ask-route)) (setq rec (bht:route-read id)) (setq ent (bht:route-ent rec)))
    (if (setq pt (getpoint "\nChọn vị trí mốc (có thể bắt NODE điểm RTK cột Km, ví dụ cockm45): "))
      (progn
        (setq pt (trans pt 1 0) pr (bht:curve-project ent pt))
        (if (null pr)
          (bht:msg "BHT: không chiếu được điểm lên tuyến.")
          (progn
            (bht:msg (strcat "Vị trí trên tuyến: cách đầu polyline " (bht:fnum (car pr) 3) " m, lệch tuyến "
                             (bht:fnum (cadr pr) 3) " m."))
            (setq v (bht:ask-string "Lý trình tại mốc (vd Km45+000) hoặc G = điểm gãy Km" ""))
            (if (= (strcase v) "G")
              (setq back (bht:parse-km (bht:ask-string "Lý trình phía SAU (theo chiều tăng, trước điểm gãy)" ""))
                    ahead (bht:parse-km (bht:ask-string "Lý trình phía TRƯỚC (sau điểm gãy)" "")))
              (setq back (bht:parse-km v) ahead back))
            (if (and back ahead)
              (progn
                (setq src (bht:ask-string "Nguồn mốc (vd RTK cockm45 / bảng cọc TDT / hồ sơ)" ""))
                (setq res (bht:route-add-mark id (car pr) back ahead src
                                              (strcat "lệch " (bht:fnum (cadr pr) 2) " m")))
                (if (car res)
                  (bht:msg (strcat "BHT: đã thêm mốc " (bht:fmt-km back)
                                   (if (/= back ahead) (strcat " / " (bht:fmt-km ahead) " (gãy)") "")
                                   ". Tuyến " id " có " (itoa (cadr res)) " mốc."))
                  (bht:msg (strcat "BHT: " (cadr res)))))
              (bht:msg "BHT: lý trình không hợp lệ.")))))))
  (bht:log-flush)
  (princ)
)

(defun bht:print-marks (id / rec marks i prev ratio)
  (setq rec (bht:route-read id) marks (bht:route-marks rec) i 0 prev nil)
  (bht:msg (strcat "Tuyến " id " | loại " (bht:get rec "loai") " | handle " (bht:get rec "handle")
                   " | lệch tối đa " (bht:get rec "max_offset") " m | ngoại suy " (bht:get rec "ngoai_suy_m")
                   " m | nguồn: " (bht:get rec "nguon")))
  (foreach m marks
    (setq ratio (if prev (/ (- (nth 1 m) (nth 2 prev)) (- (nth 0 m) (nth 0 prev))) nil))
    (princ (strcat "\n  [" (itoa i) "] d=" (bht:fnum (nth 0 m) 3) "  " (bht:fmt-km (nth 1 m))
                   (if (/= (nth 1 m) (nth 2 m)) (strcat " / " (bht:fmt-km (nth 2 m)) " (GÃY)") "")
                   (if ratio (strcat "  hệ số đoạn trước " (bht:fnum ratio 5)
                                     (if (> (abs (- (abs ratio) 1.0)) *bht-ratio-tol*) " <- CẦN KIỂM TRA" "")) "")
                   "  nguồn: " (nth 3 m)))
    (setq prev m i (1+ i)))
  (if (null marks) (princ "\n  (chưa có mốc - lý trình = chưa xác định)"))
)

(defun c:BHTDSMOC (/ *error* id v)
  (setq *error* bht:on-error)
  (if (setq id (bht:ask-route))
    (progn
      (bht:print-marks id)
      (setq v (bht:ask-string "Nhập số thứ tự mốc cần XÓA (Enter = không xóa)" ""))
      (if (and (/= v "") (bht:int v))
        (if (bht:route-del-mark id (bht:int v))
          (progn (bht:msg "BHT: đã xóa mốc.") (bht:print-marks id))
          (bht:msg "BHT: không có mốc này.")))))
  (princ)
)

(defun c:BHTLYTRINH (/ *error* r)
  (setq *error* bht:on-error)
  (setq r (bht:station-objects))
  (bht:msg (strcat "BHT lý trình: " (itoa (car r)) " đối tượng đã có lý trình, "
                   (itoa (cadr r)) " chưa xác định (xem cột trang_thai_km khi xuất)."))
  (princ)
)

;;; ----------------------------------------------------------------------
;;; Goi thau / doan tuyen - dictionary "SEG" (nap tu BHT_GOI_THAU.tsv,
;;; bang nay sinh tu "Phan chia goi thau.xlsx" cua nguoi dung)
;;; ----------------------------------------------------------------------

(defun bht:seg-load (path replace / lines hdr f id rec n recs)
  (setq lines (bht:read-lines path) n 0)
  (setq hdr (mapcar 'strcase (mapcar 'bht:trim (bht:split (car lines) "\t"))))
  (if (not (and (member "SEGMENT_ID" hdr) (member "KM_START_M" hdr) (member "KM_END_M" hdr)))
    (progn (bht:msg "BHT: file không đúng định dạng BHT_GOI_THAU.tsv.") nil)
    (progn
      ;; 0.3.2: doc het file truoc; chi khi co doan hop le moi ghi, roi moi xoa doan cu
      (setq recs nil)
      (foreach line (cdr lines)
        (if (/= (bht:trim line) "")
          (progn
            (setq f (bht:split line "\t") id (strcase (bht:trim (bht:col hdr f "SEGMENT_ID"))))
            (if (and (bht:valid-id id) (bht:num (bht:col hdr f "KM_START_M")) (bht:num (bht:col hdr f "KM_END_M")))
              (progn
                (setq rec nil)
                (foreach h hdr (setq rec (append rec (list (cons (strcase h T) (bht:col hdr f h))))))
                (setq recs (cons (cons id rec) recs)))))))
      (if (null recs)
        (progn (bht:msg "BHT: file không có đoạn hợp lệ - giữ nguyên bảng gói thầu cũ.") nil)
        (progn
          (foreach r (reverse recs) (if (bht:rec-write "SEG" (car r) (cdr r)) (setq n (1+ n))))
          (if replace
            (foreach k (bht:rec-keys "SEG")
              (if (not (assoc (strcase k) recs)) (bht:rec-delete "SEG" k))))
          (bht:meta-set "goi_thau_nguon" path)
          (bht:log (strcat "Nạp bảng gói thầu/đoạn " path ": " (itoa n) " đoạn"))
          n))))
)

(defun bht:seg-all ()
  (vl-sort (bht:rec-all "SEG")
           '(lambda (a b) (< (bht:num (bht:get (cdr a) "km_start_m")) (bht:num (bht:get (cdr b) "km_start_m")))))
)

;; Ung vien doan theo ly trinh + phia. side: TRAI/PHAI/nil
(defun bht:seg-candidates (station side segs / out s0 s1 ss)
  (setq out nil)
  (foreach s segs
    (setq s0 (bht:num (bht:get (cdr s) "km_start_m")) s1 (bht:num (bht:get (cdr s) "km_end_m"))
          ss (bht:get (cdr s) "side"))
    (if (and station (>= station (- s0 1e-6)) (<= station (+ s1 1e-6))
             (or (null side) (= ss "HAI_BEN") (= ss side)))
      (setq out (cons (car s) out))))
  (acad_strlsort out)
)

;; Phan doan tu dong. Giu nguyen doi tuong gan THU_CONG.
(defun bht:assign-segments (/ segs rec st sta side cands pp auto amb out und manual seg)
  (setq segs (bht:seg-all) auto 0 amb 0 out 0 und 0 manual 0)
  (foreach oid (bht:obj-ids)
    (setq rec (bht:obj-read oid))
    (if (= (bht:get rec "gan_doan_pp") "THU_CONG")
      (setq manual (1+ manual))
      (progn
        (setq st (bht:get rec "trang_thai_km") sta (bht:num (bht:get rec "ly_trinh_m")))
        ;; phia: uu tien khai bao tay; neu tuyen la tim duong thi dung phia so voi tuyen
        (setq side (cond ((member (bht:get rec "phia_duong") '("TRAI" "PHAI")) (bht:get rec "phia_duong"))
                         ((and (= (bht:get rec "loai_tuyen") "TIM_DUONG") (member (bht:get rec "phia_tuyen") '("TRAI" "PHAI")))
                          (bht:get rec "phia_tuyen"))
                         (T nil)))
        (cond
          ((or (not (bht:station-determined st)) (null sta))
           (setq rec (bht:set rec "gan_doan_pp" "CHUA_XAC_DINH_KM") rec (bht:set rec "doan" "")
                 rec (bht:set rec "goi" "") rec (bht:set rec "doan_ung_vien" "") und (1+ und)))
          (T
           (setq cands (bht:seg-candidates sta side segs))
           (cond
             ((null cands)
              (setq rec (bht:set rec "gan_doan_pp" "NGOAI_PHAM_VI") rec (bht:set rec "doan" "")
                    rec (bht:set rec "goi" "") rec (bht:set rec "doan_ung_vien" "") out (1+ out)))
             ((= (length cands) 1)
              (setq seg (bht:rec-read "SEG" (car cands)))
              (setq rec (bht:set rec "gan_doan_pp" (if (= st "NOI_SUY") "TU_DONG" "TU_DONG_CAN_XAC_NHAN"))
                    rec (bht:set rec "doan" (car cands)) rec (bht:set rec "goi" (bht:get seg "package_id"))
                    rec (bht:set rec "doan_ung_vien" (car cands)) auto (1+ auto)))
             (T
              (setq rec (bht:set rec "gan_doan_pp" "NHIEU_DOAN") rec (bht:set rec "doan" "")
                    rec (bht:set rec "goi" "") rec (bht:set rec "doan_ung_vien" (bht:join cands ";"))
                    amb (1+ amb))))))
        (bht:obj-write oid rec))))
  (list (cons 'auto auto) (cons 'ambiguous amb) (cons 'outside out) (cons 'undetermined und) (cons 'manual manual))
)

(defun bht:assign-manual (oid segid / rec seg)
  (setq rec (bht:obj-read oid) seg (bht:rec-read "SEG" segid))
  (cond
    ((null rec) (list nil "không có đối tượng"))
    ((null seg) (list nil "không có đoạn (nạp BHTGOITHAU trước)"))
    (T (bht:obj-write oid (bht:set (bht:set (bht:set rec "doan" (strcase segid)) "goi" (bht:get seg "package_id"))
                                   "gan_doan_pp" "THU_CONG"))
       (bht:log (strcat "Gán tay " oid " -> " segid))
       (list T segid)))
)

(defun c:BHTGOITHAU (/ *error* path def n)
  (setq *error* bht:on-error)
  (setq def (findfile "BHT_GOI_THAU.tsv"))
  (if (setq path (getfiled "Chọn BHT_GOI_THAU.tsv (tạo từ Phan chia goi thau.xlsx)" (if def def (bht:dwg-folder)) "tsv;txt" 0))
    (if (setq n (bht:seg-load path T))
      (progn
        (bht:msg (strcat "BHT: đã nạp " (itoa n) " đoạn tuyến."))
        (foreach s (bht:seg-all)
          (princ (strcat "\n  " (car s) "  " (bht:get (cdr s) "package_id") "  " (bht:get (cdr s) "km_start_text")
                         " - " (bht:get (cdr s) "km_end_text") "  " (bht:get (cdr s) "side")))))))
  (bht:log-flush)
  (princ)
)

(defun c:BHTPHANDOAN (/ *error* r)
  (setq *error* bht:on-error)
  (if (null (bht:rec-keys "SEG"))
    (bht:msg "BHT: chưa nạp bảng gói thầu. Chạy BHTGOITHAU trước.")
    (progn
      (bht:station-objects)
      (setq r (bht:assign-segments))
      (bht:msg (strcat "BHT phân đoạn: tự động " (itoa (cdr (assoc 'auto r)))
                       ", nhiều đoạn (cần BHTGANDOAN) " (itoa (cdr (assoc 'ambiguous r)))
                       ", ngoài phạm vi " (itoa (cdr (assoc 'outside r)))
                       ", chưa xác định Km " (itoa (cdr (assoc 'undetermined r)))
                       ", gán tay giữ nguyên " (itoa (cdr (assoc 'manual r))) "."))))
  (bht:log-flush)
  (princ)
)

(defun c:BHTGANDOAN (/ *error* oid v res)
  (setq *error* bht:on-error)
  (if (setq oid (bht:pick-object "Chọn đối tượng cần gán đoạn"))
    (progn
      (bht:msg (strcat oid ": lý trình " (bht:get (bht:obj-read oid) "ly_trinh_km") " | ứng viên: "
                       (bht:get (bht:obj-read oid) "doan_ung_vien")))
      (setq v (strcase (bht:ask-string "Mã đoạn (vd DOAN02) hoặc X = bỏ gán tay" "")))
      (cond
        ((= v "X")
         (bht:obj-write oid (bht:set (bht:obj-read oid) "gan_doan_pp" "CHUA_PHAN_DOAN"))
         (bht:msg "BHT: đã bỏ gán tay; chạy BHTPHANDOAN để phân lại."))
        ((/= v "")
         (setq res (bht:assign-manual oid v))
         (bht:msg (if (car res) (strcat "BHT: " oid " -> " v) (strcat "BHT: " (cadr res))))))))
  (bht:log-flush)
  (princ)
)

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
(defun bht:bb-block-for (code / k)
  (setq k (bht:bb-code-key code))
  (cond
    ((wcmatch k "*W207*") "BHT_KH_BB_W207_V044")
    ((wcmatch k "*W209*") "BHT_KH_BB_W209_V044")
    ((wcmatch k "*W239*") "BHT_KH_BB_W239A_V044")
    ((wcmatch k "*W245*") "BHT_KH_BB_W245A_V044")
    ((wcmatch k "*W201*") "BHT_KH_BB_W201_V044")
    ((wcmatch k "*W225*") "BHT_KH_BB_W225_V044")
    ((wcmatch k "*R412*") "BHT_KH_BB_R412_V044")
    ((wcmatch k "*I414*") "BHT_KH_BB_I414_V044")
    ((wcmatch k "*I423*") "BHT_KH_BB_I423A_V044")
    ((wcmatch k "*I428*") "BHT_KH_BB_I428A_V044")
    ((wcmatch k "*I434*") "BHT_KH_BB_I434A_V044")
    ((wcmatch k "*P115*") "BHT_KH_BB_P115_V044")
    ((wcmatch k "*P119*") "BHT_KH_BB_P119_V044")
    ((wcmatch k "*P124*") "BHT_KH_BB_P124A_V044")
    ((wcmatch k "*P125*") "BHT_KH_BB_P125_V044")
    ((and (wcmatch k "*P127*") (wcmatch k "*20*")) "BHT_KH_BB_P127_20_V044")
    ((and (wcmatch k "*P127*") (wcmatch k "*40*")) "BHT_KH_BB_P127_40_V044")
    ((wcmatch k "*P127*") "BHT_KH_BB_P127_V044")
    (T "BHT_KH_BIEN_BAO_V044"))
)

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

  ;; 0.4.3: hinh chieu bang cua coc tieu theo mau thuc dia: than trang,
  ;; chan phan quang do, dau phan quang xanh. Diem chen = tam chan coc (0,0).
  (bht:block "BHT_KH_COC_TIEU_V043"
    (list
      (bht:solid-g '(0.0 -0.22 0.0) '(0.30 -0.22 0.0) '(0.0 0.22 0.0) '(0.30 0.22 0.0) 1)
      (bht:line-color-g '(0.0 -0.22 0.0) '(1.72 -0.22 0.0) 7)
      (bht:line-color-g '(1.72 -0.22 0.0) '(1.72 0.22 0.0) 7)
      (bht:line-color-g '(1.72 0.22 0.0) '(0.0 0.22 0.0) 7)
      (bht:line-color-g '(0.0 0.22 0.0) '(0.0 -0.22 0.0) 7)
      (bht:line-color-g '(1.55 -0.34 0.0) '(2.08 -0.34 0.0) 3)
      (bht:line-color-g '(2.08 -0.34 0.0) '(2.08 0.34 0.0) 3)
      (bht:line-color-g '(2.08 0.34 0.0) '(1.55 0.34 0.0) 3)
      (bht:line-color-g '(1.55 0.34 0.0) '(1.55 -0.34 0.0) 3)
      (bht:solid-g '(1.70 -0.18 0.0) '(1.96 -0.18 0.0) '(1.70 0.18 0.0) '(1.96 0.18 0.0) 7)))
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
(defun bht:kh-h (/ s) (setq s (bht:num (bht:meta "kh_h" "1.5"))) (if (and s (> s 0)) s 1.5))

(defun bht:kh-custom-key (group) (strcat "kh_block_" (strcase group T)))
(defun bht:kh-custom-src-key (group) (strcat "kh_block_src_" (strcase group T)))
(defun bht:kh-custom-factor-key (group) (strcat "kh_block_factor_" (strcase group T)))

(defun bht:kh-default-block (group code)
  (cond ((= group "BIEN_BAO") (bht:bb-block-for code))
        ((= group "COC_TIEU") "BHT_KH_COC_TIEU_V043")
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

(defun bht:kh-block (rec / blk custom)
  (bht:symbol-blocks)
  (setq custom (bht:meta (bht:kh-custom-key (bht:get rec "nhom")) "")
        blk (bht:kh-default-block (bht:get rec "nhom") (bht:get rec "ma_hieu")))
  (cond ((and (/= custom "") (tblsearch "BLOCK" custom)) custom)
        ((tblsearch "BLOCK" blk) blk)
        (T "BHT_KH_CHUA_XAC_DINH"))
)

(defun bht:kh-scale-for (rec / custom f)
  (setq custom (bht:meta (bht:kh-custom-key (bht:get rec "nhom")) "")
        f (bht:num (bht:meta (bht:kh-custom-factor-key (bht:get rec "nhom")) "1")))
  (* (bht:kh-scale) (if (and (/= custom "") f (> f 0.0)) f 1.0))
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
  (strcat (bht:group-label group) (if (/= detail "") (strcat " " detail) ""))
)

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
  (setq d (entget e) x (bht:xget e "BHT_KH") pos (cdr (assoc 10 d)))
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
(defun bht:symbol-sync-ex (scope create / s h ins txt index oids rec pos blk g e d nd nx st anchor sc rot lpos
                                       created updated same removed dup manual nopos all lbl ok)
  (setq s (bht:kh-scale) h (bht:kh-h) created 0 updated 0 same 0 removed 0 dup 0 manual 0 nopos 0)
  (bht:layer "BHT_KYHIEU" 1) (bht:layer "BHT_NHAN" 2)
  (bht:regapp "BHT_KH")
  (bht:symbol-blocks)
  (setq ins (bht:group-pairs (bht:tagged-pairs "INSERT" "BHT_KH" 1))
        txt (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_KH" 1))
        all (bht:obj-ids) index (bht:pt-all)
        oids (if scope (mapcar 'strcase scope) all))
  ;; ky hieu cua ho so da xoa
  (foreach gr (append ins txt)
    (if (not (member (car gr) all))
      (foreach e2 (cdr gr) (if (entget e2) (progn (entdel e2) (setq removed (1+ removed)))))))
  (foreach oid oids
    (setq rec (bht:obj-read oid))
    (if rec
      (progn
        (setq pos (bht:obj-position rec index) blk (bht:kh-block rec) sc (bht:kh-scale-for rec)
              g (cdr (assoc oid ins)) anchor nil)
        (foreach e2 (cdr g) (entdel e2) (setq dup (1+ dup)))
        (cond
          ((setq e (car g))
           (setq d (entget e) st (bht:kh-ins-state e pos))
           (cond
             ((and (eq st 'AUTO) pos)
               (setq nd (bht:dxf-put (bht:dxf-put (bht:dxf-put (bht:dxf-put (bht:dxf-put d 10 pos) 41 sc) 42 sc) 43 sc) 50 0.0)
                    nd (bht:dxf-put (bht:dxf-put nd 2 blk) 8 "BHT_KYHIEU")
                    nx (bht:kh-xdata-ins oid "TU_DONG" pos 0.0 sc)))
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
           (setq d (entget e) anchor (list (cdr (assoc 10 d)) (abs (cdr (assoc 41 d))))))
          ((and pos create)
            (setq e (bht:insert blk pos "BHT_KYHIEU" sc))
           (if e
             (progn
                (entmod (append (entget e) (list (bht:kh-xdata-ins oid "TU_DONG" pos 0.0 sc))))
               (entupd e)
                (setq created (1+ created) anchor (list pos sc)))))
          ((null pos) (setq nopos (1+ nopos))))
        ;; nhan ky hieu (theo vi tri ky hieu thuc te)
        (if anchor
          (progn
            (setq lbl (bht:kh-label oid rec) sc (cadr anchor)
                  lpos (list (car (car anchor)) (+ (cadr (car anchor)) (* 2.2 sc)) (caddr (car anchor)))
                  g (cdr (assoc oid txt)))
            (foreach e2 (cdr g) (entdel e2) (setq dup (1+ dup)))
            (if (setq e (car g))
              (progn
                (setq d (entget e)
                      st (bht:kh-txt-state e (if pos (list (+ (car pos) (* 1.5 (bht:kh-scale))) (+ (cadr pos) (* 1.0 (bht:kh-scale)))) nil)))
                (if (eq st 'AUTO)
                  (setq nd (bht:dxf-put (bht:dxf-put (bht:dxf-put (bht:dxf-put d 10 lpos) 1 lbl) 40 h) 8 "BHT_NHAN")
                        nx (bht:kh-xdata-txt oid "TU_DONG" lpos))
                  (setq manual (1+ manual)
                        nd (bht:dxf-put (bht:dxf-put d 1 lbl) 40 h)
                        nx (bht:kh-xdata-txt oid "TAY" (cdr (assoc 10 d)))))
                (if (not (bht:ent-same-p e d nd nx))
                  (progn (entmod (append nd (list nx))) (entupd e))))
              (progn
                (setq e (bht:text lbl lpos h "BHT_NHAN"))
                (if e (progn (entmod (append (entget e) (list (bht:kh-xdata-txt oid "TU_DONG" lpos)))) (entupd e))))))))))
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
(defun bht:symbol-reset (oids / up n d x)
  (setq up (mapcar 'strcase oids) n 0)
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
(defun c:BHTBLOCK (/ *error* gv group action path name oids r)
  (setq *error* bht:on-error)
  (bht:msg "Nhóm block: 1=Biển báo, 2=Cọc tiêu, 3=Cột Km, 4=Bảng chỉ dẫn, 5=Bảng QC, 6=Đèn, 7=Công trình, 8=Khác, 0=Chưa xác định.")
  (setq gv (bht:ask-string "Chọn nhóm (số hoặc mã nhóm)" "1")
        group (bht:group-code gv))
  (if group
    (setq action (strcase (bht:ask-string "[D=Danh mục chuẩn/N=Nạp DWG tùy chọn/M=Dùng block mặc định/X=Xem cấu hình]"
                                          (if (= group "BIEN_BAO") "D" "N")))))
  (cond
    ((null group)
     (bht:msg "BHT: nhóm không hợp lệ."))
    ((= action "D")
     (if (= group "BIEN_BAO")
       (bht:bb-catalog-report)
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
        (bht:msg (strcat "BHT: không nạp được block - " *bht-block-load-error*)))
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
                    (bht:ents-tagged "LINE" '("BHT_ANHDAN")))
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
    (bht:msg (strcat "  " (itoa (cdr (assoc 'outside n))) " thực thể BHT nằm trong Layout - không sắp; chạy BHTVEMODEL để chuyển về Model.")))
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
;;;  BHTVEMODEL chuyen ve Model (giu nguyen toa do + XData; can xac nhan).
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

;; Chuyen 1 thuc the BHT (POINT/TEXT/INSERT/LINE) sang Model: tao ban sao GIONG HET
;; (toa do, layer, XData) trong Model roi xoa ban cu. Khong lam voi IMAGE, thuc the
;; co tu dien mo rong / reactor, INSERT co thuoc tinh. Tra ve ename moi hoac nil.
(defun bht:move-to-model (e / d nd ne)
  (setq d (entget e '("*")))
  (cond
    ((not (member (cdr (assoc 0 d)) '("POINT" "TEXT" "INSERT" "LINE"))) nil)
    ((or (assoc 102 d) (assoc 360 d)) nil)
    ((and (= (cdr (assoc 0 d)) "INSERT") (= 1 (logand 1 (bht:int0 (cdr (assoc 66 d)))))) nil)
    (T
     (setq nd (vl-remove-if '(lambda (g) (member (car g) '(-1 5 330 410 67 100))) d))
     (setq nd (append (list (car nd) '(410 . "Model")) (cdr nd)))
     (if (setq ne (entmakex nd))
       (progn (entdel e) ne)
       nil)))
)
(defun bht:int0 (v) (if (numberp v) (fix v) 0))

;; Tra ve (da_chuyen bo_qua).
(defun bht:move-all-to-model (/ moved skipped)
  (setq moved 0 skipped 0)
  (foreach e (bht:ents-outside-model)
    (if (bht:move-to-model e) (setq moved (1+ moved)) (setq skipped (1+ skipped))))
  (bht:log (strcat "Chuyển thực thể BHT từ Layout về Model: " (itoa moved) ", bỏ qua " (itoa skipped)))
  (list moved skipped)
)

(defun c:BHTVEMODEL (/ *error* lst r img)
  (setq *error* bht:on-error)
  (setq lst (bht:ents-outside-model) img 0)
  (foreach e lst (if (= (cdr (assoc 0 (entget e))) "IMAGE") (setq img (1+ img))))
  (if (null lst)
    (bht:msg "BHT: mọi thực thể BHT đã nằm trong Model. Không cần làm gì.")
    (progn
      (bht:msg (strcat "BHT: có " (itoa (length lst)) " thực thể BHT nằm trong Layout (paper space) - do chạy BHT khi đang ở tab Layout (bản trước 0.3.3)."))
      (bht:msg "  Chuyển về Model: tọa độ, layer, XData giữ NGUYÊN; handle thực thể sẽ đổi. Hồ sơ/ảnh/nhãn không mất.")
      (if (> img 0) (bht:msg (strcat "  " (itoa img) " raster ảnh KHÔNG chuyển được - gỡ và chèn lại bằng BHTCHENANH sau khi chuyển.")))
      (if (= (strcase (bht:ask-string "Chuyển về Model? [C/K]" "K")) "C")
        (progn
          (setq r (bht:move-all-to-model))
          (bht:msg (strcat "BHT: đã chuyển " (itoa (car r)) " thực thể về Model; bỏ qua " (itoa (cadr r)) ".")))
        (bht:msg "BHT: không chuyển gì."))))
  (bht:log-flush)
  (princ)
)

;;; ----------------------------------------------------------------------
;;; Xuat CSV (UTF-8 co BOM, dau phay) cho Excel
;;; ----------------------------------------------------------------------

(defun bht:write-csv (path header rows / f)
  (if (setq f (bht:open-write-bom path))
    (progn
      (write-line (bht:csv-line header) f)
      (foreach r rows (write-line (bht:csv-line r) f))
      (close f)
      (length rows))
    (progn (bht:msg (strcat "BHT: không ghi được " path " (file đang mở trong Excel?)")) nil))
)

(defun bht:num-or-zero (s / v) (setq v (bht:int s)) (if v v 0))

;; Xuat tat ca. Tra ve assoc so dong moi file.
(defun bht:export-all (folder prefix / index owners rows r st p segs seg objs rec photos groups key it
                       cnt sums nobj res pkey)
  (setq folder (bht:slash folder) index (bht:pt-all) owners (bht:pt-owner-map)
        segs (bht:seg-all) res nil)
  (bht:station-objects)
  ;; 1. Diem RTK
  (setq rows nil)
  (foreach it (vl-sort index '(lambda (a b) (< (car a) (car b))))
    (setq p (cdr it) r (bht:station (bht:pv p 'xyz)) st (cdr (assoc 'status r)))
    (setq rows (cons (list (bht:pv p 'id) (bht:pv p 'ds) (bht:pv p 'row) (bht:pv p 'name)
                           (bht:pv p 'n) (bht:pv p 'e) (bht:pv p 'z) (bht:pv p 'desc) (bht:pv p 'cls)
                           (bht:join (cdr (assoc (car it) owners)) ";")
                           (bht:str (cdr (assoc 'route r)))
                           (if (bht:station-determined st) (bht:fnum (cdr (assoc 'station r)) 3) "")
                           (if (bht:station-determined st) (bht:fmt-km (cdr (assoc 'station r))) "")
                           (if (cdr (assoc 'offset r)) (bht:fnum (cdr (assoc 'offset r)) 3) "")
                           (bht:str (cdr (assoc 'side r))) st
                           (if (bht:station-determined st) (bht:join (bht:seg-candidates (cdr (assoc 'station r)) nil segs) ";") "")
                           (bht:pv p 'src))
                     rows)))
  (setq res (cons (cons 'points (bht:write-csv (strcat folder prefix "DIEM_RTK.csv")
    '("ID điểm khảo sát" "Mã bộ dữ liệu" "Dòng nguồn" "Tên điểm" "Tọa độ Bắc gốc" "Tọa độ Đông gốc" "Cao độ gốc" "Mô tả gốc"
      "Phân loại gợi ý" "ID hồ sơ" "ID tuyến" "Lý trình (m)" "Lý trình Km" "Độ lệch (m)" "Phía so với tuyến"
      "Trạng thái lý trình" "Đoạn ứng viên theo Km" "Tệp nguồn")
    (reverse rows))) res))
  ;; 2. Doi tuong
  (setq rows nil objs nil)
  (foreach oid (bht:obj-ids)
    (setq rec (bht:obj-read oid) objs (cons (cons oid rec) objs)
          seg (bht:rec-read "SEG" (bht:get rec "doan")))
    (setq rows (cons (list oid (bht:get rec "nhom") (bht:group-label (bht:get rec "nhom"))
                           (bht:get rec "ma_hieu") (bht:get rec "loai_ma") (bht:get rec "mo_ta")
                           (bht:get rec "so_tru") (bht:get rec "so_mat") (bht:join (bht:get-all rec "mat") ";")
                           (bht:get rec "tinh_trang") (bht:get rec "trang_thai_kt") (bht:get rec "phia_duong")
                           (itoa (length (bht:get-all rec "pt"))) (bht:join (bht:get-all rec "pt") ";")
                           (bht:get rec "vi_tri_e") (bht:get rec "vi_tri_n")
                           (bht:get rec "route_id") (bht:get rec "ly_trinh_m") (bht:get rec "ly_trinh_km")
                           (bht:get rec "offset_m") (bht:get rec "phia_tuyen") (bht:get rec "trang_thai_km")
                           (bht:get rec "nguon_km")
                           (bht:get rec "goi") (if seg (bht:get seg "package_name") "")
                           (bht:get rec "doan") (bht:get rec "gan_doan_pp") (bht:get rec "doan_ung_vien")
                           (itoa (length (bht:get-all rec "anh")))
                           (bht:join (mapcar '(lambda (a) (car (bht:split a "|"))) (bht:get-all rec "anh")) ";")
                           (bht:join (bht:get-all rec "anh_file") ";")
                           (bht:get rec "ghi_chu") (bht:get rec "tao_luc") (bht:get rec "sua_luc"))
                     rows)))
  (setq res (cons (cons 'objects (bht:write-csv (strcat folder prefix "DOI_TUONG.csv")
    '("ID hồ sơ" "Mã nhóm" "Tên nhóm" "Mã hiệu" "Loại mã" "Mô tả" "Số trụ/chân" "Số mặt biển" "Mã các mặt"
      "Tình trạng" "Trạng thái kiểm tra" "Phía đường" "Số điểm RTK" "ID điểm khảo sát" "Vị trí Đông trung bình" "Vị trí Bắc trung bình"
      "ID tuyến" "Lý trình (m)" "Lý trình Km" "Độ lệch (m)" "Phía so với tuyến" "Trạng thái lý trình" "Nguồn lý trình"
      "ID gói thầu" "Tên gói thầu" "ID đoạn" "Phương pháp gán đoạn" "Đoạn ứng viên"
      "Số ảnh xác nhận" "ID ảnh" "Tệp ảnh khác" "Ghi chú" "Tạo lúc" "Sửa lúc")
    (reverse rows))) res))
  ;; 3. Anh
  (setq rows nil)
  (foreach pid (bht:rec-keys "PHOTO")
    (setq rec (bht:photo-read pid))
    (setq rows (cons (list pid (bht:get rec "ten") (bht:get rec "thoi_gian") (bht:get rec "lon") (bht:get rec "lat")
                           (bht:get rec "gps_hop_le") (bht:get rec "e") (bht:get rec "n") (bht:get rec "crs")
                           (bht:get rec "trang_thai") (bht:join (bht:get-all rec "de_xuat") ";") (bht:get rec "kc")
                           (bht:join (bht:get-all rec "doi_tuong") ";") (bht:get rec "duong_dan")
                           (bht:get rec "antifake") (bht:get rec "dia_chi"))
                     rows)))
  (setq res (cons (cons 'photos (bht:write-csv (strcat folder prefix "ANH.csv")
    '("ID ảnh" "Tên điểm ảnh" "Thời gian chụp" "Kinh độ" "Vĩ độ" "GPS hợp lệ" "Tọa độ Đông vị trí chụp" "Tọa độ Bắc vị trí chụp"
      "Hệ tọa độ tính" "Trạng thái ghép" "Đề xuất" "Khoảng cách gần nhất (m)" "ID hồ sơ xác nhận" "Đường dẫn" "Chống giả mạo" "Địa chỉ")
    (reverse rows))) res))
  ;; 4. Tong hop theo goi / doan / nhom - moi doi tuong dem DUNG MOT lan
  (setq groups nil)
  (foreach o objs
    (setq rec (cdr o)
          key (list (if (/= (bht:get rec "goi") "") (bht:get rec "goi") "(CHUA_GAN)")
                    (if (/= (bht:get rec "doan") "") (bht:get rec "doan") (bht:get rec "gan_doan_pp"))
                    (bht:get rec "nhom")))
    (setq it (assoc key groups)
          cnt (if it (cdr it) (list 0 0 0 0 0 0 0 0)))
    ;; cnt: so_dt so_tru so_mat dt_thieu_tru dt_thieu_mat so_diem so_anh can_xac_nhan
    (setq cnt (list (1+ (nth 0 cnt))
                    (+ (nth 1 cnt) (bht:num-or-zero (bht:get rec "so_tru")))
                    (+ (nth 2 cnt) (bht:num-or-zero (bht:get rec "so_mat")))
                    (+ (nth 3 cnt) (if (bht:int (bht:get rec "so_tru")) 0 1))
                    (+ (nth 4 cnt) (if (bht:int (bht:get rec "so_mat")) 0 1))
                    (+ (nth 5 cnt) (length (bht:get-all rec "pt")))
                    (+ (nth 6 cnt) (length (bht:get-all rec "anh")))
                    (+ (nth 7 cnt) (if (or (/= (bht:get rec "gan_doan_pp") "TU_DONG")
                                           (/= (bht:get rec "trang_thai_kt") "DA_KIEM_TRA")) 1 0))))
    (if it (setq groups (subst (cons key cnt) it groups)) (setq groups (cons (cons key cnt) groups))))
  (setq groups (vl-sort groups '(lambda (a b) (< (bht:join (car a) "|") (bht:join (car b) "|")))))
  (setq rows nil sums (list 0 0 0 0 0 0 0 0))
  (foreach g groups
    (setq seg (bht:rec-read "SEG" (cadr (car g))))
    (setq rows (cons (append (list (car (car g)) (if seg (bht:get seg "package_name") "")
                                   (cadr (car g))
                                   (if seg (strcat (bht:get seg "km_start_text") " - " (bht:get seg "km_end_text")) "")
                                   (if seg (bht:get seg "side") "")
                                   (caddr (car g)) (bht:group-label (caddr (car g))))
                             (mapcar 'itoa (cdr g)))
                     rows)
          sums (mapcar '+ sums (cdr g))))
  (setq rows (cons (append (list "TONG" "" "" "" "" "" "Tất cả đối tượng") (mapcar 'itoa sums)) rows))
  (setq res (cons (cons 'summary (bht:write-csv (strcat folder prefix "TONG_HOP.csv")
    '("ID gói thầu" "Tên gói thầu" "ID đoạn hoặc trạng thái" "Phạm vi Km" "Phía" "Mã nhóm" "Tên nhóm"
      "Số đối tượng" "Số trụ/chân" "Số mặt biển" "Số đối tượng chưa rõ số trụ" "Số đối tượng chưa rõ số mặt"
      "Số điểm RTK" "Số ảnh xác nhận" "Số đối tượng chưa chốt")
    (reverse rows))) res))
  (setq res (cons (cons 'total-objects (car sums)) res))
  (bht:log (strcat "Xuất CSV vào " folder))
  res
)

(defun c:BHTXUAT (/ *error* path folder pre res)
  (setq *error* bht:on-error)
  (if (setq path (getfiled "Chọn thư mục + tiền tố file xuất (vd BHT_.csv)" (strcat (bht:dwg-folder) "BHT_.csv") "csv" 1))
    (progn
      (setq folder (vl-filename-directory path)
            pre (vl-filename-base path))
      (setq res (bht:export-all folder pre))
      (bht:msg (strcat "BHT xuất: " (bht:str (cdr (assoc 'points res))) " điểm RTK, "
                       (bht:str (cdr (assoc 'objects res))) " đối tượng, "
                       (bht:str (cdr (assoc 'photos res))) " ảnh, tổng hợp "
                       (bht:str (cdr (assoc 'summary res))) " dòng -> " (bht:slash folder) pre "*.csv"))))
  (bht:log-flush)
  (princ)
)
(defun c:BHTEXPORT () (c:BHTXUAT))
(defun c:BHTSUMMARY () (c:BHTXUAT))

;;; ----------------------------------------------------------------------
;;; Kiem tra toan ven (BHTKT)
;;; ----------------------------------------------------------------------

;; Tra ve (so_loi so_canh_bao danh_sach_dong)
;; Ghi 1 dong ket qua kiem tra. Dung bien errs/warns/lines cua bht:check (pham vi dong).
(defun bht:ck-add (lvl s)
  (if (= lvl 2) (setq errs (1+ errs)) (if (= lvl 1) (setq warns (1+ warns))))
  (setq lines (cons (strcat (cond ((= lvl 2) "LỖI: ") ((= lvl 1) "CẢNH BÁO: ") (T "")) s) lines))
)

(defun bht:check (/ ss n i ent x ids dup legacy moved index loc errs warns lines objs owners rec pids
                    missing multi pc v0 v1 pend rid rrec ent2 marks segs nsym orph
                    lg ldup lorph lbad p mk mdup morig minv morph mpos mmiss jmiss one)
  (setq errs 0 warns 0 lines nil)
  ;; diem
  (setq ss (ssget "_X" (list '(0 . "POINT") '(-3 ("BHT_PT")))) n (if ss (sslength ss) 0) i 0 ids nil dup nil moved 0)
  (while (< i n)
    (setq ent (ssname ss i) x (bht:xget ent "BHT_PT") loc (cdr (assoc 10 (entget ent))))
    (if (member (strcase (car x)) ids) (setq dup (cons (car x) dup)) (setq ids (cons (strcase (car x)) ids)))
    (if (or (> (abs (- (car loc) (bht:num (nth 5 x)))) 1e-6) (> (abs (- (cadr loc) (bht:num (nth 4 x)))) 1e-6)
            (> (abs (- (caddr loc) (bht:num (nth 6 x)))) 1e-6))
      (progn (setq moved (1+ moved)) (bht:ck-add 2 (strcat "điểm " (car x) " bị dịch khỏi tọa độ gốc (X=E, Y=N, Z)"))))
    (setq i (1+ i)))
  (bht:ck-add 0 (strcat "Điểm RTK v0.2: " (itoa n) " | ID duy nhất: " (itoa (length ids)) " | trùng ID: " (itoa (length dup))
                        " | bị dịch: " (itoa moved)))
  (foreach d dup (bht:ck-add 2 (strcat "trùng survey_point_id " d)))
  (setq ss (ssget "_X" (list '(0 . "POINT") (cons 8 *bht-pt-layer*))) legacy 0 i 0)
  (if ss (while (< i (sslength ss))
           (if (and (bht:xget (ssname ss i) "BHT_RTK") (not (bht:xget (ssname ss i) "BHT_PT"))) (setq legacy (1+ legacy)))
           (setq i (1+ i))))
  (if (> legacy 0) (bht:ck-add 1 (strcat (itoa legacy) " điểm v0.1 chưa có ID v0.2 (chạy BHTNANGCAP hoặc nhập lại CSV)")))
  (bht:ck-add 0 (strcat "Dataset: " (bht:join (bht:rec-keys "DATASET") ", ")))
  ;; doi tuong
  (setq objs (bht:rec-all "OBJ") owners (bht:pt-owner-map) missing 0 multi 0 pend 0)
  (foreach o objs
    (setq rec (cdr o) pids (bht:get-all rec "pt"))
    (if (null pids) (bht:ck-add 1 (strcat "đối tượng " (car o) " không có điểm RTK")))
    (foreach p pids (if (not (member (strcase p) ids))
                      (progn (setq missing (1+ missing)) (bht:ck-add 2 (strcat (car o) " tham chiếu điểm không tồn tại " p)))))
    (foreach a (bht:get-all rec "anh")
      (setq pc (bht:photo-read (car (bht:split a "|"))))
      (if (or (null pc) (not (member (strcase (car o)) (mapcar 'strcase (bht:get-all pc "doi_tuong")))))
        (bht:ck-add 2 (strcat "liên kết ảnh không đồng bộ: " (car o) " - " (car (bht:split a "|")))))))
  (foreach w owners (if (> (length (cdr w)) 1)
                      (progn (setq multi (1+ multi))
                             (bht:ck-add 1 (strcat "điểm " (car w) " thuộc nhiều đối tượng: " (bht:join (cdr w) ", "))))))
  (bht:ck-add 0 (strcat "Đối tượng: " (itoa (length objs)) " | điểm dùng chung: " (itoa multi)
                        " | điểm thiếu: " (itoa missing)))
  ;; anh
  (setq v0 0 v1 0 pc 0)
  (foreach pid (bht:rec-keys "PHOTO")
    (setq rec (bht:photo-read pid))
    (if (= (bht:get rec "gps_hop_le") "1") (setq v1 (1+ v1)) (setq v0 (1+ v0)))
    (if (member (bht:get rec "trang_thai") '("DE_XUAT" "MO_HO")) (setq pend (1+ pend)))
    (if (= (bht:get rec "trang_thai") "DA_XAC_NHAN") (setq pc (1+ pc)))
    (foreach o (bht:get-all rec "doi_tuong")
      (cond
        ((not (bht:obj-read o)) (bht:ck-add 2 (strcat "ảnh " pid " trỏ tới đối tượng không tồn tại " o)))
        ((not (member (strcase pid) (mapcar '(lambda (a) (strcase (car (bht:split a "|")))) (bht:get-all (bht:obj-read o) "anh"))))
         (bht:ck-add 2 (strcat "liên kết ảnh một chiều: ảnh " pid " ghi đối tượng " o " nhưng hồ sơ " o " không có ảnh này"))))))
  (bht:ck-add 0 (strcat "Ảnh: " (itoa (+ v0 v1)) " | GPS hợp lệ: " (itoa v1) " | GPS 0,0/không có: " (itoa v0)
                        " | đã xác nhận: " (itoa pc) " | chờ duyệt: " (itoa pend)))
  (if (> pend 0) (bht:ck-add 1 (strcat (itoa pend) " ảnh có đề xuất chưa duyệt (BHTXACNHANANH)")))
  ;; tuyen
  (foreach rid (bht:route-ids)
    (setq rrec (bht:route-read rid) ent2 (bht:route-ent rrec) marks (bht:route-marks rrec))
    (cond ((null ent2) (bht:ck-add 2 (strcat "tuyến " rid ": không còn Polyline (handle " (bht:get rrec "handle") ")")))
          ((not (car (bht:route-check-ent ent2))) (bht:ck-add 2 (strcat "tuyến " rid ": " (cadr (bht:route-check-ent ent2))))))
    (if (null marks) (bht:ck-add 1 (strcat "tuyến " rid " chưa có mốc Km -> lý trình chưa xác định")))
    (setq i 0)
    (while (< i (1- (length marks)))
      (setq v0 (/ (- (nth 1 (nth (1+ i) marks)) (nth 2 (nth i marks))) (- (nth 0 (nth (1+ i) marks)) (nth 0 (nth i marks)))))
      (if (> (abs (- (abs v0) 1.0)) *bht-ratio-tol*)
        (bht:ck-add 1 (strcat "tuyến " rid ": hệ số đoạn mốc " (itoa i) "-" (itoa (1+ i)) " = " (bht:fnum v0 4) " (kiểm tra mốc/tuyến)")))
      (if (and (> i 0) (/= (minusp v0) (minusp v1)))
        (bht:ck-add 2 (strcat "tuyến " rid ": chiều tăng Km đổi dấu giữa các mốc - kiểm tra lại mốc")))
      (setq v1 v0 i (1+ i)))
    (bht:ck-add 0 (strcat "Tuyến " rid " (" (bht:get rrec "loai") "): " (itoa (length marks)) " mốc")))
  ;; goi thau
  (setq segs (bht:rec-keys "SEG"))
  (bht:ck-add 0 (strcat "Đoạn tuyến đã nạp: " (itoa (length segs))))
  (setq i 0)
  (foreach o objs (if (= (bht:get (cdr o) "gan_doan_pp") "NHIEU_DOAN") (setq i (1+ i))))
  (if (> i 0) (bht:ck-add 1 (strcat (itoa i) " đối tượng thuộc nhiều đoạn chồng lấn - cần BHTGANDOAN")))
  ;; ky hieu
  (setq ss (ssget "_X" (list '(0 . "INSERT") '(-3 ("BHT_KH")))) nsym (if ss (sslength ss) 0) orph 0 i 0)
  (while (< i nsym)
    (if (not (bht:obj-read (car (bht:xget (ssname ss i) "BHT_KH")))) (setq orph (1+ orph)))
    (setq i (1+ i)))
  (bht:ck-add 0 (strcat "Ký hiệu: " (itoa nsym) " | mồ côi: " (itoa orph)))
  (if (> orph 0) (bht:ck-add 1 "có ký hiệu không còn hồ sơ - chạy BHTKYHIEU để cập nhật (chỉ xóa ký hiệu của hồ sơ đã xóa)"))
  ;; 0.3.3: ky hieu / nhan dat tay
  (setq i 0)
  (foreach pr (bht:tagged-pairs "INSERT" "BHT_KH" 1)
    (if (and (>= (length (bht:xget (cdr pr) "BHT_KH")) 6) (= (nth 1 (bht:xget (cdr pr) "BHT_KH")) "TAY")) (setq i (1+ i))))
  (setq n 0)
  (foreach pr (bht:tagged-pairs "TEXT" "BHT_NHAN" 2) (if (= (bht:lbl-state (cdr pr)) 'TAY) (setq n (1+ n))))
  (bht:ck-add 0 (strcat "Ký hiệu đặt tay (giữ khi cập nhật): " (itoa i) " | nhãn điểm dời tay: " (itoa n)))
  (setq i 0)
  (foreach o objs (if (null (bht:symbol-exists (car o))) (setq i (1+ i))))
  (if (and (> i 0) (> nsym 0)) (bht:ck-add 1 (strcat (itoa i) " hồ sơ chưa có ký hiệu - chạy BHTKYHIEU")))
  ;; 0.3.3: thuc the BHT nam ngoai Model
  (setq i (length (bht:ents-outside-model)))
  (if (> i 0) (bht:ck-add 1 (strcat (itoa i) " thực thể BHT nằm trong Layout (paper space) - chạy BHTVEMODEL để chuyển về Model")))
  ;; nhan diem RTK (0.3.2)
  (setq lg (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_NHAN" 2)) ldup 0 lorph 0 lbad 0 index (bht:pt-all))
  (foreach g lg
    (if (> (length (cdr g)) 1) (setq ldup (1+ ldup)))
    (setq p (bht:pt-find (car (bht:split (car g) "|")) index))
    (cond ((null p) (setq lorph (1+ lorph)))
          ((/= (cdr (assoc 1 (entget (cadr g)))) (bht:lbl-text p (cadr (bht:split (car g) "|")))) (setq lbad (1+ lbad)))))
  (bht:ck-add 0 (strcat "Nhãn điểm RTK: " (itoa (length lg)) " | trùng: " (itoa ldup) " | mồ côi: " (itoa lorph)
                        " | lệch nội dung: " (itoa lbad)))
  (if (> ldup 0) (bht:ck-add 2 (strcat (itoa ldup) " nhãn điểm bị nhân đôi - chạy BHTNHANDIEM để dọn")))
  (if (> lorph 0) (bht:ck-add 1 (strcat (itoa lorph) " nhãn không còn điểm RTK - chạy BHTNHANDIEM để dọn")))
  (if (> lbad 0) (bht:ck-add 1 (strcat (itoa lbad) " nhãn khác dữ liệu gốc (bị sửa tay?) - chạy BHTNHANDIEM để cập nhật")))
  ;; ky hieu anh (0.3.2)
  (setq mk (bht:group-pairs (bht:tagged-pairs "INSERT" "BHT_ANHPT" 1)) mdup 0 morig 0 minv 0 morph 0 mpos 0 mmiss 0 jmiss 0)
  (foreach g mk
    (setq rec (bht:photo-read (car g)))
    (if (> (length (cdr g)) 1) (setq mdup (1+ mdup)))
    (foreach e (cdr g)
      (setq loc (cdr (assoc 10 (entget e))))
      (if (and (< (abs (car loc)) 0.001) (< (abs (cadr loc)) 0.001)) (setq morig (1+ morig))))
    (setq loc (cdr (assoc 10 (entget (cadr g)))))
    (cond ((null rec) (setq morph (1+ morph)))
          ((/= (bht:get rec "gps_hop_le") "1") (setq minv (1+ minv)))
          ((or (null (bht:num (bht:get rec "e"))) (null (bht:num (bht:get rec "n")))
               (> (abs (- (car loc) (bht:num (bht:get rec "e")))) 0.01)
               (> (abs (- (cadr loc) (bht:num (bht:get rec "n")))) 0.01))
           (setq mpos (1+ mpos)))))
  (foreach pid (bht:rec-keys "PHOTO")
    (setq rec (bht:photo-read pid))
    (if (and (= (bht:get rec "gps_hop_le") "1") (not (assoc pid mk))) (setq mmiss (1+ mmiss)))
    (if (null (bht:photo-path rec)) (setq jmiss (1+ jmiss))))
  (bht:ck-add 0 (strcat "Ký hiệu ảnh: " (itoa (length mk)) " ảnh có ký hiệu | trùng: " (itoa mdup)
                        " | ở gốc 0,0: " (itoa morig) " | ảnh không GPS có ký hiệu: " (itoa minv)
                        " | mồ côi: " (itoa morph) " | lệch vị trí: " (itoa mpos) " | ảnh GPS thiếu ký hiệu: " (itoa mmiss)
                        " | thiếu JPG: " (itoa jmiss)))
  (if (> mdup 0) (bht:ck-add 2 (strcat (itoa mdup) " ảnh có ký hiệu bị nhân đôi - chạy BHTDONGBOANH")))
  (if (> morig 0) (bht:ck-add 2 (strcat (itoa morig) " ký hiệu ảnh nằm ở gốc 0,0 - chạy BHTDONGBOANH")))
  (if (> minv 0) (bht:ck-add 2 (strcat (itoa minv) " ảnh GPS 0,0 lại có ký hiệu - chạy BHTDONGBOANH")))
  (if (> morph 0) (bht:ck-add 1 (strcat (itoa morph) " ký hiệu ảnh không còn bản ghi - chạy BHTDONGBOANH")))
  (if (> mpos 0) (bht:ck-add 1 (strcat (itoa mpos) " ký hiệu ảnh lệch vị trí (đổi hệ tọa độ?) - chạy BHTDONGBOANH")))
  (if (> mmiss 0) (bht:ck-add 1 (strcat (itoa mmiss) " ảnh GPS hợp lệ chưa có ký hiệu - chạy BHTDONGBOANH")))
  (if (> jmiss 0) (bht:ck-add 1 (strcat (itoa jmiss) " ảnh không tìm thấy file JPG - BHTTHUMUCANH")))
  (list errs warns (reverse lines))
)

(defun c:BHTKT (/ *error* r)
  (setq *error* bht:on-error)
  (setq r (bht:check))
  (foreach l (caddr r) (bht:msg (strcat "  " l)) (bht:log l))
  (bht:msg (strcat "BHTKT: " (itoa (car r)) " lỗi, " (itoa (cadr r)) " cảnh báo."))
  (bht:log-flush)
  (princ)
)
(defun c:BHTCHECK () (c:BHTKT))

;;; ----------------------------------------------------------------------
;;; Thong tin / chan doan
;;; ----------------------------------------------------------------------

(defun bht:obj-info-lines (oid / rec out)
  (setq rec (bht:obj-read oid) out (list (strcat "=== Đối tượng " (bht:str oid) " ===")))
  (if (null rec) (setq out (append out (list "  (không có hồ sơ)"))))
  (foreach p rec (setq out (append out (list (strcat "  " (car p) " = " (cdr p))))))
  out
)

(defun bht:obj-info (oid)
  (foreach l (bht:obj-info-lines oid) (bht:msg l))
)

;; Thong tin 1 diem RTK: du lieu goc, nhan, doi tuong, anh lien quan.
(defun bht:point-info-lines (p / id owners out lg kinds ph xyz)
  (setq id (strcase (bht:pv p 'id)) xyz (bht:pv p 'xyz)
        out (list (strcat "=== Điểm " (bht:pv p 'id) " ===")
                  (strcat "  dataset " (bht:pv p 'ds) ", dòng " (bht:pv p 'row))
                  (strcat "  tên: " (bht:pv p 'name))
                  (strcat "  N (Bắc) gốc: " (bht:pv p 'n) "  E (Đông) gốc: " (bht:pv p 'e) "  Z gốc: " (bht:pv p 'z))
                  (strcat "  mô tả gốc: [" (bht:pv p 'desc) "]")
                  (strcat "  phân loại gợi ý: " (bht:pv p 'cls) " | file nguồn: " (bht:pv p 'src))
                  (strcat "  CAD X,Y,Z: " (bht:fnum (car xyz) 3) ", " (bht:fnum (cadr xyz) 3) ", " (bht:fnum (caddr xyz) 3))))
  (setq lg (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_NHAN" 2)) kinds nil)
  (foreach k *bht-lbl-kinds*
    (if (assoc (strcat id "|" (car k)) lg)
      (setq kinds (append kinds (list (strcat (car k) (if (eq (bht:lbl-state (cadr (assoc (strcat id "|" (car k)) lg))) 'TAY)
                                                       " (dời tay)" " (tự động)")))))))
  (setq out (append out (list (strcat "  nhãn trên bản vẽ: " (if kinds (bht:join kinds ", ") "(chưa có - BHTNHANDIEM)")))))
  (setq owners (cdr (assoc id (bht:pt-owner-map))))
  (setq out (append out (list (strcat "  thuộc đối tượng: " (if owners (bht:join owners ", ") "(chưa)")))))
  (setq ph (bht:photos-for-point id))
  (setq out (append out (list (strcat "  ảnh đã xác nhận: " (if (car ph) (bht:join (car ph) ", ") "(không)"))
                              (strcat "  ảnh đề xuất (chưa xác nhận): " (if (cadr ph) (bht:join (cadr ph) ", ") "(không)"))
                              (strcat "  ảnh chụp gần (chỉ gợi ý): " (if (caddr ph) (bht:join (caddr ph) ", ") "(không)")))))
  (foreach o owners (setq out (append out (bht:obj-info-lines o))))
  out
)

;; Thong tin cua 1 thuc the bat ky (ham khong tuong tac, dung cho BHTINFO va kiem thu).
(defun bht:info-lines (ent / p x)
  (cond
    ((or (null ent) (null (entget ent))) (list "Không có đối tượng."))
    ((setq p (bht:pt-from-ent ent)) (bht:point-info-lines p))
    ((setq x (bht:xget ent "BHT_NHAN"))
     (cons (strcat "Nhãn " (bht:str (cadr x)) " của điểm " (car x))
           (if (setq p (bht:pt-find (car x) (bht:pt-all)))
             (bht:point-info-lines p)
             (list "  (điểm RTK không còn - nhãn mồ côi; chạy BHTNHANDIEM để dọn)"))))
    ((setq x (bht:xget ent "BHT_KH")) (bht:obj-info-lines (car x)))
    ((or (setq x (bht:xget ent "BHT_ANHPT")) (setq x (bht:xget ent "BHT_ANHTEN")) (setq x (bht:xget ent "BHT_ANHRS")))
     (bht:photo-info-lines (car x)))
    ((setq x (bht:xget ent "BHT_RTK")) (list (strcat "Điểm v0.1: " (bht:join x " | ") " (chưa có ID v0.2)")))
    (T (list "Không có dữ liệu BHT trên đối tượng này.")))
)

(defun c:BHTINFO (/ *error* sel ent x)
  (setq *error* bht:on-error)
  (if (setq sel (entsel "\nChọn điểm RTK / nhãn / ký hiệu BHT / ký hiệu ảnh: "))
    (progn
      (setq ent (car sel))
      (foreach l (bht:info-lines ent) (bht:msg l))
      (if (or (setq x (bht:xget ent "BHT_ANHPT")) (setq x (bht:xget ent "BHT_ANHTEN")) (setq x (bht:xget ent "BHT_ANHRS")))
        (if (= (strcase (bht:ask-string "Mở ảnh này? [C/K]" "C")) "C") (bht:photo-browse (car x))))))
  (princ)
)

;; Thong ke proxy theo layer (khong goi vlax-curve tren proxy).
(defun bht:proxy-stats (/ ss i ent lay out it)
  (setq out nil i 0 ss (ssget "_X" '((0 . "ACAD_PROXY_ENTITY"))))
  (if ss
    (while (< i (sslength ss))
      (setq lay (cdr (assoc 8 (entget (ssname ss i)))))
      (if (setq it (assoc lay out))
        (setq out (subst (cons lay (1+ (cdr it))) it out))
        (setq out (cons (cons lay 1) out)))
      (setq i (1+ i))))
  out
)

(defun c:BHTDIAG (/ *error* sel ent data obj on chk st)
  (setq *error* bht:on-error)
  (initget "Tatca")
  (setq sel (entsel "\nChọn đối tượng cần chẩn đoán hoặc [Tatca = thống kê proxy]: "))
  (cond
    ((= sel "Tatca")
     (setq st (bht:proxy-stats))
     (bht:msg (strcat "ACAD_PROXY_ENTITY trong bản vẽ: " (itoa (apply '+ (cons 0 (mapcar 'cdr st))))))
     (foreach s st (princ (strcat "\n  layer " (car s) ": " (itoa (cdr s)))))
     (bht:msg (strcat "Layer Tuyen: " (itoa (if (ssget "_X" '((8 . "Tuyen"))) (sslength (ssget "_X" '((8 . "Tuyen")))) 0)) " đối tượng.")))
    (sel
     (setq ent (car sel) data (entget ent)
           obj (vl-catch-all-apply 'vlax-ename->vla-object (list ent))
           on (if (vl-catch-all-error-p obj) "không lấy được" (vl-catch-all-apply 'vla-get-ObjectName (list obj))))
     (if (vl-catch-all-error-p on) (setq on "không lấy được"))
     (setq chk (bht:route-check-ent ent))
     (bht:msg (strcat "DXF: " (cdr (assoc 0 data)) " | Layer: " (cdr (assoc 8 data)) " | Handle: " (cdr (assoc 5 data))
                      " | ObjectName: " on))
     (bht:msg (strcat "Dùng làm tuyến tham chiếu: " (if (car chk) "ĐƯỢC" (strcat "KHÔNG - " (cadr chk)))))))
  (princ)
)

;;; ----------------------------------------------------------------------
;;; Nang cap du lieu v0.1 (BHT_ASSET / BHT_PHOTO tren POINT)
;;; ----------------------------------------------------------------------

(defun bht:migrate-v01 (/ ss i ent x loc id h assets a res n np)
  (setq ss (ssget "_X" (list '(0 . "POINT") (cons 8 *bht-pt-layer*) '(-3 ("BHT_RTK")))) i 0 n 0 np 0 assets nil)
  (if ss
    (while (< i (sslength ss))
      (setq ent (ssname ss i))
      (if (not (bht:xget ent "BHT_PT"))
        (progn
          (setq x (bht:xget ent "BHT_RTK") loc (cdr (assoc 10 (entget ent))) h (cdr (assoc 5 (entget ent))))
          (bht:pt-write-xdata ent (strcat "V01-H" h) "V01" "" (car x) (bht:fnum (cadr loc) 3) (bht:fnum (car loc) 3)
                              (bht:fnum (caddr loc) 3) (bht:classify (if (cadr x) (cadr x) "")) "BHT 0.1 (không rõ file)"
                              (if (cadr x) (cadr x) "") (bht:now))
          (setq np (1+ np))))
      (if (setq a (bht:xget ent "BHT_ASSET"))
        (progn
          (setq id (strcase (car (bht:xget ent "BHT_PT"))))
          (if (setq x (assoc (strcase (car a)) assets))
            (setq assets (subst (append x (list (list id (bht:xget ent "BHT_PHOTO")))) x assets))
            (setq assets (cons (list (strcase (car a)) a (list id (bht:xget ent "BHT_PHOTO"))) assets)))))
      (setq i (1+ i))))
  (foreach as assets
    (if (not (bht:obj-read (car as)))
      (progn
        (setq a (cadr as))
        (setq res (bht:obj-create (if (bht:valid-id (car as)) (car as) (bht:obj-next-id))
                                  (list (cons "ma_hieu" (if (nth 2 a) (nth 2 a) ""))
                                        (cons "ghi_chu" (strcat "Nâng cấp từ v0.1: loại=" (if (nth 1 a) (nth 1 a) "")
                                                                " gói=" (if (nth 3 a) (nth 3 a) "") " đoạn=" (if (nth 4 a) (nth 4 a) ""))))
                                  (mapcar 'car (cddr as)) T))
        (if (car res)
          (progn
            (setq n (1+ n))
            (foreach pp (cddr as) (foreach f (cadr pp) (bht:obj-add-file (cadr res) f))))))))
  (list np n)
)

(defun c:BHTNANGCAP (/ *error* r)
  (setq *error* bht:on-error)
  (setq r (bht:migrate-v01))
  (bht:msg (strcat "BHT nâng cấp v0.1: gán ID cho " (itoa (car r)) " điểm, tạo " (itoa (cadr r)) " hồ sơ đối tượng. "
                   "Gói/đoạn v0.1 được giữ trong ghi chú; hãy nạp BHTGOITHAU và chạy BHTPHANDOAN."))
  (bht:log-flush)
  (princ)
)

;;; ----------------------------------------------------------------------
;;; Tu kiem tra ham thuan (khong sua ban ve) - BHTTEST
;;; ----------------------------------------------------------------------

;; Ghi 1 ket qua tu kiem tra (dung bien pass/fail cua bht:selftest, pham vi dong).
(defun bht:st-chk (name ok)
  (if ok (setq pass (1+ pass))
    (progn (setq fail (1+ fail)) (bht:msg (strcat "  FAIL " name))))
)

(defun bht:selftest (/ pass fail marks r en segs fp rec)
  (setq pass 0 fail 0)
  (bht:st-chk "csv ngoặc kép" (equal (bht:csv-fields "P1,1,2,3,\"207,e\"") '("P1" "1" "2" "3" "207,e")))
  (bht:st-chk "csv escape" (= (bht:csv-cell "a\"b,c") "\"a\"\"b,c\""))
  (bht:st-chk "csv tiếng Việt" (equal (bht:csv-fields "Đ1,1,2,3,biển cấm") '("Đ1" "1" "2" "3" "biển cấm")))
  (bht:st-chk "số hợp lệ" (equal (bht:num "1187855.825") 1187855.825 1e-9))
  (bht:st-chk "số sai" (null (bht:num "12a")))
  (bht:st-chk "fnum" (and (= (bht:fnum 0.5 3) "0.500") (= (bht:fnum -2.25 1) "-2.3") (= (bht:fnum 1187855.825 3) "1187855.825")))
  (bht:st-chk "parse km" (and (equal (bht:parse-km "Km39+050.5") 39050.5 1e-9) (equal (bht:parse-km "40+127") 40127.0 1e-9)
                       (equal (bht:parse-km "39000") 39000.0 1e-9) (null (bht:parse-km "abc"))))
  (bht:st-chk "format km" (and (= (bht:fmt-km 39050.5) "Km39+050.50") (= (bht:fmt-km 40000.0) "Km40+000.00")))
  (bht:st-chk "id hợp lệ" (and (bht:valid-id "BOT19-R-000001") (not (bht:valid-id "a b")) (not (bht:valid-id ""))))
  (bht:st-chk "make id" (= (bht:make-id "BOT19" "R" 7) "BOT19-R-000007"))
  (bht:st-chk "phân loại" (and (= (bht:classify "bbtron1m25 gioihan80") "BIEN_BAO") (= (bht:classify "coctiu.h5-48") "COC_TIEU")
                        (= (bht:classify "cockm45") "COT_KM") (= (bht:classify "bbqcphan  1.2x2.35") "BANG_QC")
                        (= (bht:classify "hoga") "CHUA_XAC_DINH")))
  (bht:st-chk "record mã hóa" (equal (bht:rec-decode (mapcar '(lambda (s) (cons 1 s))
                                               (mapcar 'cdr (bht:rec-encode (list (cons "a" "x=1") (cons "pt" "P1") (cons "pt" "P2"))))))
                              (list (cons "a" "x=1") (cons "pt" "P1") (cons "pt" "P2"))))
  ;; ly trinh: moc 0 -> 39000, gay tai 500 (39500/39600), 1000 -> 40100
  (setq marks '((0.0 39000.0 39000.0) (500.0 39500.0 39600.0) (1000.0 40100.0 40100.0)))
  (setq r (bht:km-from-dist marks 250.0 0.0 nil))
  (bht:st-chk "nội suy" (and (= (car r) "NOI_SUY") (equal (cadr r) 39250.0 1e-9)))
  (setq r (bht:km-from-dist marks 750.0 0.0 nil))
  (bht:st-chk "không nội suy qua điểm gãy" (equal (cadr r) 39850.0 1e-9))
  (bht:st-chk "ngoài mốc = chưa xác định" (= (car (bht:km-from-dist marks 1200.0 0.0 nil)) "CHUA_XAC_DINH"))
  (bht:st-chk "ngoại suy cho phép" (equal (cadr (bht:km-from-dist marks 1010.0 20.0 nil)) 40110.0 1e-9))
  (bht:st-chk "không mốc" (= (car (bht:km-from-dist nil 10.0 0.0 nil)) "CHUA_CO_MOC"))
  (bht:st-chk "1 mốc thiếu chiều" (= (car (bht:km-from-dist '((0.0 39000.0 39000.0)) 10.0 1e9 nil)) "CHUA_XAC_DINH"))
  (bht:st-chk "1 mốc có chiều" (equal (cadr (bht:km-from-dist '((0.0 39000.0 39000.0)) 10.0 1e9 1)) 39010.0 1e-9))
  (bht:st-chk "chiều giảm" (equal (cadr (bht:km-from-dist '((0.0 40000.0 40000.0) (1000.0 39000.0 39000.0)) 250.0 0.0 nil)) 39750.0 1e-9))
  (bht:st-chk "hệ số lệch -> cần kiểm tra" (= (car (bht:km-from-dist '((0.0 39000.0 39000.0) (1000.0 39100.0 39100.0)) 5.0 0.0 nil)) "CAN_KIEM_TRA"))
  ;; ung vien doan
  (setq segs (list (cons "DOAN02" (list (cons "km_start_m" "39000") (cons "km_end_m" "40127") (cons "side" "TRAI")))
                   (cons "DOAN12" (list (cons "km_start_m" "38723") (cons "km_end_m" "40127") (cons "side" "PHAI")))
                   (cons "DOAN01" (list (cons "km_start_m" "38622") (cons "km_end_m" "38697") (cons "side" "HAI_BEN")))))
  (bht:st-chk "đoạn theo phía trái" (equal (bht:seg-candidates 39250.0 "TRAI" segs) '("DOAN02")))
  (bht:st-chk "đoạn chưa rõ phía" (equal (bht:seg-candidates 39250.0 nil segs) '("DOAN02" "DOAN12")))
  (bht:st-chk "đoạn hai bên" (equal (bht:seg-candidates 38650.0 "PHAI" segs) '("DOAN01")))
  (bht:st-chk "ngoài đoạn" (null (bht:seg-candidates 45000.0 nil segs)))
  ;; chuyen doi toa do (so sanh voi cung cong thuc tinh doc lap bang Python)
  (setq en (bht:project 106.43828833333333 10.753013333333334 105.75 0.9999))
  (bht:st-chk "WGS84->VN2000 KTT 105°45'" (and (equal (car en) 575081.764 0.002) (equal (cadr en) 1189223.379 0.002)))
  (bht:st-chk "bỏ dấu nhãn DCL" (and (= (bht:fold-vi "Nhập điểm ĐƯỜNG") "Nhap diem DUONG")
                               (= (bht:fold-vi "từ — ảnh") "tu - anh")))
  (bht:st-chk "điền nhãn DCL" (and (= (bht:ui-fill-line "label = \"@nhap@\";" '(("nhap" . "Nhập")) nil)
                               "label = \"Nhap\";")
                            (= (bht:ui-fill-line "label = \"@nhap@\";" '(("nhap" . "Nhập")) T)
                               "label = \"Nhập\";")))
  ;; 0.3.2: nhan diem / anh
  (bht:st-chk "chế độ nhãn" (and (equal (bht:lbl-kinds-for "T" nil) '("TEN"))
                                  (equal (bht:lbl-kinds-for "tmc" T) '("TEN" "MOTA" "CAODO" "ID"))))
  (setq fp (list (cons 'id "BOT19-R-000384") (cons 'name "384") (cons 'desc "dgbtxuogthur") (cons 'z "2.909")
                 (cons 'xyz '(10.0 20.0 2.909))))
  (bht:st-chk "nội dung nhãn nguyên văn" (and (= (bht:lbl-text fp "TEN") "384") (= (bht:lbl-text fp "MOTA") "dgbtxuogthur")
                                               (= (bht:lbl-text fp "CAODO") "H = 2.909")
                                               (= (bht:lbl-text (subst (cons 'z "2.90") (assoc 'z fp) fp) "CAODO") "H = 2.90")))
  (setq r (bht:lbl-wanted (subst (cons 'desc "") (assoc 'desc fp) fp) '("TEN" "MOTA" "CAODO") 1.0 0.5))
  (bht:st-chk "bỏ nhãn mô tả rỗng" (and (= (length r) 2) (= (car (nth 1 r)) "CAODO")
                                        (equal (caddr (nth 1 r)) '(10.5 19.0 2.909) 1e-9)))
  (setq r (bht:group-pairs (list (cons "A" 1) (cons "B" 2) (cons "A" 3))))
  (bht:st-chk "gom nhãn trùng" (and (= (length r) 2) (= (length (assoc "A" r)) 3)))
  (setq rec (list (cons "duong_dan" "photos/origin_photo_0.jpg") (cons "goc" "C:\\BHT_ANH")))
  (bht:st-chk "đường dẫn ảnh tương đối" (= (car (bht:photo-path-candidates rec)) "C:\\BHT_ANH\\photos\\origin_photo_0.jpg"))
  (bht:st-chk "file không tồn tại" (and (not (bht:file-ok nil)) (not (bht:file-ok "Z:\\khong\\co.jpg"))))
  (bht:st-chk "dxf-put" (equal (bht:dxf-put '((1 . "a") (8 . "0")) 8 "L") '((1 . "a") (8 . "L"))))
  ;; 0.3.3: bo tri nhan, trang thai nhan, uu tien ho so, mau IRT
  (bht:st-chk "giao hộp" (and (equal (bht:box-ov '(0.0 0.0 2.0 2.0) '(1.0 1.0 3.0 3.0)) 1.0 1e-9)
                              (= (bht:box-ov '(0.0 0.0 1.0 1.0) '(1.0 0.0 2.0 1.0)) 0.0)))
  (setq r (bht:lbl-cands 10.0 20.0 4.0 1.0 0.5 1.0))
  (bht:st-chk "64 vị trí ứng viên, đầu tiên Đông-Bắc" (and (= (length r) 64) (equal (car r) '(10.5 20.5) 1e-9)))
  (setq r (bht:lbl-layout (list (list "A" 0.0 0.0 4.0 1.25) (list "B" 0.0 0.0 4.0 1.25)) nil 0.5 1.0))
  (bht:st-chk "hai nhãn cùng vị trí không chồng nhau"
              (and (= (length r) 2)
                   (= (bht:box-ov (list (cadr (car r)) (caddr (car r)) (+ (cadr (car r)) 4.0) (+ (caddr (car r)) 1.25))
                                  (list (cadr (cadr r)) (caddr (cadr r)) (+ (cadr (cadr r)) 4.0) (+ (caddr (cadr r)) 1.25)))
                      0.0)))
  (setq r (bht:lbl-layout (list (list "A" 0.0 0.0 4.0 1.25)) (list '(0.0 0.0 10.0 10.0)) 0.5 1.0))
  (bht:st-chk "nhãn tránh vật cản" (and (= (cadddr (car r)) 0.0)
                                        (= (bht:box-ov (list (cadr (car r)) (caddr (car r)) (+ (cadr (car r)) 4.0) (+ (caddr (car r)) 1.25))
                                                       '(0.0 0.0 10.0 10.0)) 0.0)))
  (setq fp (list (cons 'id "X-R-1") (cons 'xyz '(10.0 20.0 0.0))))
  (bht:st-chk "vị trí mặc định nhãn 0.3.2" (and (equal (bht:lbl-legacy-pos fp "CAODO" '("TEN" "MOTA" "CAODO") 1.0 0.5) '(10.5 17.5) 1e-9)
                                              (equal (bht:lbl-legacy-pos fp "CAODO" '("TEN" "CAODO") 1.0 0.5) '(10.5 19.0) 1e-9)))
  (bht:st-chk "ưu tiên hồ sơ ẩn nhãn phụ" (and (equal (bht:lbl-kinds-point '("TEN" "MOTA" "CAODO") "P1" '(("P1" "OBJ-000001")) T) '("TEN"))
                                             (equal (bht:lbl-kinds-point '("TEN" "MOTA") "P2" '(("P1" "OBJ-000001")) T) '("TEN" "MOTA"))
                                             (equal (bht:lbl-kinds-point '("TEN" "MOTA") "P1" '(("P1" "OBJ-000001")) nil) '("TEN" "MOTA"))))
  (bht:st-chk "mẫu thư mục tile IRT (IRT\\ / IRT.cache), không nhầm thư mục ảnh BHT"
              (and (wcmatch (bht:path-norm "D:/Data/IRT/sat/18/x.jpg") *bht-irt-dir-pat*)
                   (wcmatch (bht:path-norm "C:\\u\\IRT.cache\\t.jpg") *bht-irt-dir-pat*)
                   (not (wcmatch (bht:path-norm "D:/anh/IRTX/a.jpg") *bht-irt-dir-pat*))
                   (not (wcmatch (bht:path-norm "D:/BHT/photos/origin_photo_0.jpg") *bht-irt-dir-pat*))))
  (bht:st-chk "mẫu nhận diện ảnh nền IRT" (and (wcmatch "IRT_GOOGLE" *bht-irt-layer-pat*) (not (wcmatch "BHT_ANH_RASTER" *bht-irt-layer-pat*))
                                              (wcmatch "GOOGLE_SAT_18_1" *bht-irt-file-pat*) (not (wcmatch "ORIGIN_PHOTO_0" *bht-irt-file-pat*))))
  ;; 0.4.0: API cho plugin .NET
  (bht:st-chk "API phiên bản" (equal (bht:api-version) (list "OK" *bht-version* *bht-api-level* *bht-build*)))
  (bht:st-chk "API tách danh sách ID" (equal (bht:api-ids "OBJ-1, OBJ-2;OBJ-3") '("OBJ-1" "OBJ-2" "OBJ-3")))
  (bht:st-chk "API bắt lỗi" (= (car (bht:api-run '(lambda () (/ 1 0)) nil)) "LOI"))
  (bht:msg (strcat "BHTTEST: " (itoa pass) " PASS, " (itoa fail) " FAIL (chỉ kiểm tra hàm thuần; không thay nghiệm thu CAD)."))
  (list pass fail)
)

(defun c:BHTTEST (/ *error*)
  (setq *error* bht:on-error)
  (bht:selftest)
  (princ)
)

;;; ----------------------------------------------------------------------
;;; Huong dan
;;; ----------------------------------------------------------------------

(defun bht:help-text ()
  (bht:msg (strcat "BHT " *bht-version* " (" *bht-build* ") - danh sách lệnh:"))
  (foreach l
    '("  Quy trình: 1 Nhập điểm RTK -> 2 Nhãn điểm -> 3 Nhập TimeMark -> 4 Kiểm tra/xem ảnh -> 5 Ghép ảnh"
      "             -> 6 Hồ sơ đối tượng -> 7 Ký hiệu -> 8 Tuyến + Km -> 9 Xuất thống kê (gõ BHT để mở bảng)"
      "  BHTNHAP      Nhập CSV RTK (MẶC ĐỊNH; tên, Bắc, Đông, Z, mô tả) -> POINT layer BHT_RTK, ID <dataset>-R-<dòng> (BHTIMPORT, BHTCSV)"
      "  BHTNHAPTSV   Nhập BHT_RTK.tsv (định dạng trao đổi/chuẩn hóa; KHÔNG cần nhập lại dữ liệu đã nhập bằng CSV) (BHTNK)"
      "  BHTNHANDIEM  Nhãn điểm RTK: tên / +mô tả / +cao độ, ưu tiên hồ sơ, ID nội bộ, sắp xếp, ẩn/hiện, cài đặt (BHTLABEL)"
      "  BHTSAPNHAN   Sắp xếp nhãn tránh chồng lấn theo vùng chọn / danh sách ID / tất cả (POINT không bị di chuyển)"
      "  BHTKIEUDIEM  Đặt POINT thành dấu X đúng tâm, mặc định 1 unit; tùy chọn sắp lại toàn bộ nhãn"
      "  BHTNHANTUDONG Trả nhãn đã dời tay về vị trí tự động   BHTANNHAN  Ẩn / hiện nhãn điểm RTK"
      "  BHTDOITUONG  Tạo hồ sơ đối tượng từ nhiều điểm RTK (điểm đã thuộc hồ sơ khác: xem / sửa / thêm điểm / tạo mới có xác nhận) (BHTTAG)"
      "  BHTSUADT     Sửa hồ sơ (BHTEDIT)      BHTXOADT   Xóa hồ sơ, giữ điểm (BHTDELETE)"
      "  BHTTHEMDIEM  Thêm điểm vào đối tượng  BHTBOTDIEM Gỡ điểm khỏi đối tượng (BHTUNTAG)"
      "  BHTKMZ       Giải nén KMZ TimeMark -> ảnh + BHT_PHOTO.tsv (giữ cả ảnh GPS 0,0)"
      "  BHTANHNAP    Nạp BHT_PHOTO.tsv vào bản vẽ (BHTDSANH)   BHTHETOADO  Chọn hệ VN-2000 cho ảnh GPS"
      "  BHTGHEPANH   Đề xuất ghép ảnh - điểm/đối tượng (CHỈ đề xuất)"
      "  BHTXACNHANANH Duyệt/xác nhận đề xuất   BHTGANANH  Gắn ảnh thủ công (BHTPHOTO)   BHTBOANH  Bỏ ảnh"
      "  BHTXEMANH    Xem ảnh: chọn ký hiệu ảnh / điểm RTK / nhập mã -> thông tin + mở JPG, ảnh trước/sau, gắn đối tượng"
      "  BHTANH       Mở ảnh theo mã (T = đặt thư mục ảnh)   BHTTHUMUCANH  Chỉ lại thư mục ảnh khi mất đường dẫn"
      "  BHTDONGBOANH Đồng bộ ký hiệu + nhãn mã ảnh + đường dẫn từ bản ghi (không trùng; ảnh GPS 0,0 không có ký hiệu) (BHTSYNCANH)"
      "  BHTNHANANH   Ẩn / hiện nhãn mã ảnh   BHTCHENANH  Chèn ảnh JPG đã chọn làm raster (+ đường dẫn tùy chọn; không chèn hàng loạt)"
      "  BHTTUYEN     Khai báo Polyline tuyến tham chiếu (từ chối proxy TDT)   BHTROUTE  Kiểu v0.1 (gốc đầu polyline)"
      "  BHTMOCKM     Thêm mốc Km đã xác nhận / điểm gãy Km   BHTDSMOC  Xem/xóa mốc"
      "  BHTLYTRINH   Tính lý trình/offset cho đối tượng (không mốc = chưa xác định)"
      "  BHTGOITHAU   Nạp BHT_GOI_THAU.tsv   BHTPHANDOAN  Gán đoạn/gói tự động   BHTGANDOAN  Gán tay"
      "  BHTKYHIEU    Chèn / cập nhật ký hiệu theo object_id (giữ vị trí người dùng đặt; R = trả về tự động)"
      "  BHTBLOCK     Danh mục block chuẩn / nạp DWG tùy chọn / trở lại mặc định"
      "  BHTBBDANHMUC Danh mục biển báo từ ảnh KMZ DT830, đối chiếu QCVN 41:2024"
      "  BHTTHUTUVE   Thứ tự hiển thị: nhãn > ký hiệu/điểm > raster BHT > ảnh nền IRT"
      "  BHTXUAT      Xuất CSV: DIEM_RTK, DOI_TUONG, ANH, TONG_HOP (BHTEXPORT, BHTSUMMARY)"
      "  BHTKT        Kiểm tra toàn vẹn (BHTCHECK)   BHTINFO  Xem dữ liệu   BHTDIAG  Chẩn đoán đối tượng/proxy"
      "  BHTTRANGTHAI Trạng thái bản vẽ (điểm, nhãn, hồ sơ, ảnh, JPG, ghép, tuyến, lý trình)"
      "  BHTTEST      Tự kiểm tra hàm   BTH/BHT  Mở Palette   BHTHELP  Danh sách này"
      "  BHTDCL       Bảng DCL dự phòng   BHTLOAD  Kiểm tra / nạp lại Palette"
      "  Bảo trì dữ liệu cũ: BHTNANGCAP  Nâng cấp dữ liệu BHT 0.1 (chỉ dùng cho bản vẽ làm bằng BHT 0.1)"
      "                     BHTVEMODEL  Chuyển thực thể BHT lỡ tạo trong Layout (bản trước 0.3.3) về Model")
    (princ (strcat "\n" l)))
  (princ)
)
(defun c:BHTHELP () (bht:help-text))

;;; ----------------------------------------------------------------------
;;; Bang dieu khien DCL du phong - tao tam khi go BHTDCL
;;;
;;; load_dialog doc file DCL theo code page ANSI cua Windows, khong doc UTF-8.
;;; Ghi "utf8" bien "từ" thanh "tá»«". set_tile di duong Unicode (LISPSYS=1).
;;; ----------------------------------------------------------------------

(defun bht:ansi-roundtrip (s / p f back ok)
  (setq p (vl-filename-mktemp "BHT_ENC_" (getvar "TEMPPREFIX") ".txt")
        ok nil)
  (if (and p (setq f (open p "w")))
    (progn
      (write-line s f)
      (close f)
      (if (setq f (open p "r"))
        (progn
          (setq back (read-line f))
          (close f)
          (setq ok (equal back s))))))
  (if p (vl-file-delete p))
  ok
)

(defun bht:dcl-unicode-file-p ()
  (bht:ansi-roundtrip "ĂƠƯĐăơưđ")
)

(defun bht:dcl-escape (s)
  (bht:replace (bht:replace (bht:str s) "\\" "\\\\") "\"" "\\\"")
)

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

;;; ----------------------------------------------------------------------
;;; 0.3.2: Trang thai ban ve (bang dieu khien + BHTTRANGTHAI)
;;; ----------------------------------------------------------------------

(defun bht:status-data (/ idx lg labeled objs chain)
  (setq idx (bht:pt-all) lg (bht:group-pairs (bht:tagged-pairs "TEXT" "BHT_NHAN" 2)) labeled 0 chain 0)
  (foreach it idx (if (assoc (strcat (car it) "|TEN") lg) (setq labeled (1+ labeled))))
  (setq objs (bht:obj-ids))
  (foreach o objs (if (/= (bht:get (bht:obj-read o) "ly_trinh_m") "") (setq chain (1+ chain))))
  (append (list (cons 'points (length idx)) (cons 'labeled labeled) (cons 'objects (length objs))
                (cons 'routes (length (bht:route-ids))) (cons 'chainage chain)
                (cons 'segments (length (bht:rec-keys "SEG"))))
          (bht:photo-stats))
)

(defun bht:stv (s k) (bht:str (cdr (assoc k s))))

;; Cac ghi chu giai thich trang thai (tieng Viet).
(defun bht:status-notes (s / out)
  (setq out nil)
  (if (and (= (cdr (assoc 'objects s)) 0) (> (cdr (assoc 'points s)) 0))
    (setq out (append out (list (strcat "Đã nhập " (bht:stv s 'points) " điểm RTK nhưng CHƯA nhóm thành hồ sơ đối tượng"
                                        " (dữ liệu không mất) - làm bước 6 \"Tạo hồ sơ đối tượng\".")))))
  (if (and (> (cdr (assoc 'points s)) 0) (< (cdr (assoc 'labeled s)) (cdr (assoc 'points s))))
    (setq out (append out (list (strcat (itoa (- (cdr (assoc 'points s)) (cdr (assoc 'labeled s))))
                                        " điểm chưa có nhãn - bước 2 \"Nhãn điểm RTK\" (BHTNHANDIEM).")))))
  (if (> (cdr (assoc 'jpg-missing s)) 0)
    (setq out (append out (list (strcat (bht:stv s 'jpg-missing) " ảnh không tìm thấy file JPG - \"Thư mục ảnh\" (BHTTHUMUCANH).")))))
  (if (> (cdr (assoc 'markers-missing s)) 0)
    (setq out (append out (list (strcat (bht:stv s 'markers-missing) " ảnh GPS chưa có ký hiệu - \"Đồng bộ ký hiệu ảnh\" (BHTDONGBOANH).")))))
  out
)

(defun bht:status-lines (/ s notes)
  (setq s (bht:status-data) notes (bht:status-notes s))
  (list
    (strcat "Điểm RTK đã nhập: " (bht:stv s 'points) "   |   Điểm đã có nhãn: " (bht:stv s 'labeled)
            "   |   Hồ sơ đối tượng: " (bht:stv s 'objects))
    (strcat "Ảnh đã nhập: " (bht:stv s 'total) "   |   Có file JPG: " (bht:stv s 'jpg-found)
            "   |   Đã ghép: " (bht:stv s 'linked) "   |   Chưa ghép: " (bht:stv s 'unlinked))
    (strcat "Tuyến đã khai báo: " (bht:stv s 'routes) "   |   Đối tượng có lý trình: " (bht:stv s 'chainage)
            "   |   Đoạn gói thầu: " (bht:stv s 'segments))
    (if notes (car notes) "Không có cảnh báo trạng thái."))
)

;; Chuoi 1 dong (tuong thich 0.3.1).
(defun bht:ui-status ()
  (bht:join (bht:status-lines) " | ")
)

(defun c:BHTTRANGTHAI (/ *error* s)
  (setq *error* bht:on-error)
  (setq s (bht:status-data))
  (bht:msg (strcat "BHT " *bht-version* " - trạng thái bản vẽ:"))
  (foreach l (list
               (strcat "  Điểm RTK đã nhập: " (bht:stv s 'points))
               (strcat "  Điểm đã có nhãn: " (bht:stv s 'labeled))
               (strcat "  Hồ sơ đối tượng: " (bht:stv s 'objects))
               (strcat "  Ảnh đã nhập: " (bht:stv s 'total) " (GPS hợp lệ " (bht:stv s 'valid) ", thiếu GPS " (bht:stv s 'invalid) ")")
               (strcat "  Ảnh có file JPG: " (bht:stv s 'jpg-found) " (thiếu " (bht:stv s 'jpg-missing) ")")
               (strcat "  Ký hiệu ảnh: " (bht:stv s 'markers) " (thiếu " (bht:stv s 'markers-missing) ")")
               (strcat "  Ảnh đã ghép: " (bht:stv s 'linked) " | chưa ghép: " (bht:stv s 'unlinked))
               (strcat "  Tuyến đã khai báo: " (bht:stv s 'routes))
               (strcat "  Đối tượng có lý trình: " (bht:stv s 'chainage)))
    (princ (strcat "\n" l)))
  (foreach l (bht:status-notes s) (princ (strcat "\n  Lưu ý: " l)))
  (princ)
)

;; Nut bam: (khoa nhan lenh). Thu tu = quy trinh lam viec.
(setq *bht-ui-buttons*
  '(("nhap" "Nhập CSV RTK (mặc định)" "BHTNHAP")
    ("nhaptsv" "Nhập TSV (trao đổi)" "BHTNHAPTSV")
    ("nangcap" "Nâng cấp dữ liệu V0.1" "BHTNANGCAP")
    ("vemodel" "Chuyển BHT từ Layout về Model" "BHTVEMODEL")
    ("nhandiem" "Nhãn điểm RTK" "BHTNHANDIEM")
    ("annhan" "Ẩn / hiện nhãn" "BHTANNHAN")
    ("sapnhan" "Sắp xếp nhãn" "BHTSAPNHAN")
    ("nhantudong" "Trả nhãn về tự động" "BHTNHANTUDONG")
    ("kmz" "Giải nén KMZ" "BHTKMZ")
    ("anhnap" "Nạp TSV ảnh" "BHTANHNAP")
    ("hetoa" "Hệ tọa độ ảnh" "BHTHETOADO")
    ("dongbo" "Đồng bộ ký hiệu ảnh" "BHTDONGBOANH")
    ("xemanh" "Xem ảnh" "BHTXEMANH")
    ("thumuc" "Thư mục ảnh" "BHTTHUMUCANH")
    ("chenanh" "Chèn ảnh raster" "BHTCHENANH")
    ("nhananh" "Ẩn / hiện mã ảnh" "BHTNHANANH")
    ("ghepanh" "Đề xuất ghép" "BHTGHEPANH")
    ("xacnhan" "Duyệt đề xuất" "BHTXACNHANANH")
    ("gananh" "Gắn ảnh" "BHTGANANH")
    ("boanh" "Bỏ ảnh" "BHTBOANH")
    ("taodt" "Tạo hồ sơ" "BHTDOITUONG")
    ("suadt" "Sửa hồ sơ" "BHTSUADT")
    ("xoadt" "Xóa hồ sơ" "BHTXOADT")
    ("themdiem" "Thêm điểm" "BHTTHEMDIEM")
    ("botdiem" "Gỡ điểm" "BHTBOTDIEM")
    ("info" "Xem thông tin" "BHTINFO")
    ("kyhieu" "Chèn / cập nhật ký hiệu" "BHTKYHIEU")
    ("thutuve" "Sắp thứ tự hiển thị" "BHTTHUTUVE")
    ("tuyen" "Khai báo tuyến" "BHTTUYEN")
    ("mockm" "Thêm mốc Km" "BHTMOCKM")
    ("dsmoc" "Danh sách mốc" "BHTDSMOC")
    ("lytrinh" "Tính lý trình" "BHTLYTRINH")
    ("goithau" "Nạp gói thầu" "BHTGOITHAU")
    ("phandoan" "Phân đoạn tự động" "BHTPHANDOAN")
    ("gandoan" "Gán đoạn tay" "BHTGANDOAN")
    ("xuat" "Xuất CSV cho Excel" "BHTXUAT")
    ("kiemtra" "Kiểm tra dữ liệu" "BHTKT")
    ("trangthai" "Trạng thái chi tiết" "BHTTRANGTHAI")
    ("chandoan" "Chẩn đoán" "BHTDIAG")
    ("test" "Tự kiểm tra" "BHTTEST")
    ("help" "Danh sách lệnh" "BHTHELP")
    ("refresh" "Làm mới" "BHTUIREFRESH")))

(defun bht:ui-captions (/ out)
  (setq out (list (cons "bht_main" "BHT — QUẢN LÝ HIỆN TRẠNG TUYẾN")
                  (cons "g0" "TRẠNG THÁI BẢN VẼ")
                  (cons "gq" "QUY TRÌNH LÀM VIỆC (theo thứ tự 1 → 9)")
                  (cons "s1" "1. Nhập điểm RTK (CSV)")
                  (cons "s2" "2. Hiển thị nhãn điểm")
                  (cons "s3" "3. Nhập TimeMark")
                  (cons "s4" "4. Kiểm tra và xem ảnh")
                  (cons "s5" "5. Ghép ảnh với điểm")
                  (cons "s6" "6. Tạo hồ sơ đối tượng")
                  (cons "s7" "7. Chèn ký hiệu")
                  (cons "s8" "8. Khai báo tuyến và tính Km")
                  (cons "s9" "9. Xuất thống kê")
                  (cons "gk" "Khác")
                  (cons "gb" "Bảo trì dữ liệu cũ")
                  (cons "hint" "Chọn chức năng; bảng mở lại sau khi lệnh kết thúc. CSV là cách nhập mặc định; TSV chỉ để trao đổi.")
                  (cons "cancel" "Đóng")))
  (foreach b *bht-ui-buttons* (setq out (append out (list (cons (car b) (cadr b))))))
  out
)

(defun bht:ui-fill-line (line captions unicode-file / s)
  (foreach c captions
    (setq s (cdr c))
    (if (not unicode-file) (setq s (bht:fold-vi s)))
    (setq line (bht:replace line (strcat "@" (car c) "@") (bht:dcl-escape s))))
  line
)

;; Dong DCL cho 1 buoc: nhan buoc + cac nut.
(defun bht:ui-step-row (step keys / out)
  (setq out (list "    : row {"
                  (if step (strcat "      : text { key = \"" step "\"; label = \"@" step "@\"; width = 30; }")
                           "      : text { label = \"\"; width = 30; }")))
  (foreach k keys
    (setq out (append out (list (strcat "      : button { key = \"" k "\"; label = \"@" k "@\"; width = 24; }")))))
  (append out (list "    }"))
)

(defun bht:ui-dcl-template ()
  (append
    (list "bht_main : dialog {"
          "  label = \"@bht_main@\";"
          "  : text { key = \"version\"; alignment = centered; width = 110; }"
          "  : boxed_column {"
          "    : text { key = \"g0\"; label = \"@g0@\"; width = 110; }"
          "    : text { key = \"st1\"; width = 110; }"
          "    : text { key = \"st2\"; width = 110; }"
          "    : text { key = \"st3\"; width = 110; }"
          "    : text { key = \"st4\"; width = 110; }"
          "  }"
          "  : boxed_column {"
          "    : text { key = \"gq\"; label = \"@gq@\"; width = 110; }")
    (bht:ui-step-row "s1" '("nhap" "nhaptsv"))
    (bht:ui-step-row "s2" '("nhandiem" "annhan" "sapnhan"))
    (bht:ui-step-row nil '("nhantudong"))
    (bht:ui-step-row "s3" '("kmz" "anhnap" "hetoa"))
    (bht:ui-step-row "s4" '("dongbo" "xemanh" "thumuc"))
    (bht:ui-step-row nil '("chenanh" "nhananh"))
    (bht:ui-step-row "s5" '("ghepanh" "xacnhan" "gananh"))
    (bht:ui-step-row nil '("boanh"))
    (bht:ui-step-row "s6" '("taodt" "suadt" "xoadt"))
    (bht:ui-step-row nil '("themdiem" "botdiem" "info"))
    (bht:ui-step-row "s7" '("kyhieu" "thutuve"))
    (bht:ui-step-row "s8" '("tuyen" "mockm" "dsmoc"))
    (bht:ui-step-row nil '("lytrinh" "goithau" "phandoan"))
    (bht:ui-step-row nil '("gandoan"))
    (bht:ui-step-row "s9" '("xuat" "kiemtra" "trangthai"))
    (list "  }"
          "  : boxed_column {")
    (bht:ui-step-row "gk" '("chandoan" "test" "help"))
    (bht:ui-step-row "gb" '("nangcap" "vemodel"))
    (list "  }"
          "  spacer;"
          "  : row {"
          "    : text { key = \"hint\"; label = \"@hint@\"; width = 80; }"
          "    : button { key = \"refresh\"; label = \"@refresh@\"; width = 14; }"
          "    : button { key = \"cancel\"; label = \"@cancel@\"; is_cancel = true; width = 14; }"
          "  }"
          "}"))
)

(defun bht:ui-write-dcl (/ path file lines vi)
  (setq vi T
        path (vl-filename-mktemp "BHT_UI_" (getvar "TEMPPREFIX") ".dcl")
        lines (mapcar '(lambda (line) (bht:ui-fill-line line (bht:ui-captions) vi))
                      (bht:ui-dcl-template)))
  (if (setq file (open path "w" "utf8-bom"))
    (progn
      (foreach line lines (write-line line file))
      (close file)
      path)
    nil)
)

(defun bht:ui-apply-captions (/ st i)
  (foreach c (bht:ui-captions)
    (vl-catch-all-apply 'set_tile (list (car c) (cdr c))))
  (vl-catch-all-apply 'set_tile
    (list "version" (strcat "Phiên bản " *bht-version* "  •  Build " *bht-build*)))
  (setq st (vl-catch-all-apply 'bht:status-lines nil) i 0)
  (if (vl-catch-all-error-p st)
    (setq st (list (strcat "Không đọc được trạng thái: " (vl-catch-all-error-message st)) "" "" "")))
  (foreach k '("st1" "st2" "st3" "st4")
    (vl-catch-all-apply 'set_tile (list k (bht:str (nth i st))))
    (setq i (1+ i)))
)

(defun bht:ui-bind (key command)
  (action_tile key
    (strcat "(setq *bht-ui-action* \"" command "\")(done_dialog 1)"))
)

(defun bht:ui-dialog (/ path dcl-id result)
  (setq path (bht:ui-write-dcl))
  (if (null path)
    (progn (bht:msg "BHT: không tạo được tệp giao diện tạm.") nil)
    (progn
      (setq dcl-id (load_dialog path))
      (if (or (null dcl-id) (< dcl-id 0) (not (new_dialog "bht_main" dcl-id)))
        (progn
          (if (and dcl-id (>= dcl-id 0)) (unload_dialog dcl-id))
          (vl-file-delete path)
          (bht:msg "BHT: không mở được bảng điều khiển DCL.")
          nil)
        (progn
          (setq *bht-ui-action* nil)
          (bht:ui-apply-captions)
          (foreach b *bht-ui-buttons* (bht:ui-bind (car b) (caddr b)))
          (setq result (start_dialog))
          (unload_dialog dcl-id)
          (vl-file-delete path)
          (if (= result 1) *bht-ui-action* nil))))))

(defun bht:ui-call (command / symbol result)
  (if (and command (/= command "BHTUIREFRESH"))
    (progn
      (setq symbol (read (strcat "C:" command)))
      (setq result (vl-catch-all-apply symbol nil))
      (if (vl-catch-all-error-p result)
        (bht:msg (strcat "BHT: lệnh " command " gặp lỗi: "
                         (vl-catch-all-error-message result))))))
)

(defun c:BHTDCL (/ *error* action keep-open)
  (setq *error* bht:on-error keep-open T)
  (while keep-open
    (setq action (bht:ui-dialog))
    (if action
      (bht:ui-call action)
      (setq keep-open nil)))
  (princ)
)

;; Dung trong kiem thu: tao va nap DCL, khong hien hop thoai.
(defun bht:ui-validate (/ path dcl-id ok)
  (setq path (bht:ui-write-dcl)
        dcl-id (if path (load_dialog path) -1)
        ok (and dcl-id (>= dcl-id 0)))
  (if ok (unload_dialog dcl-id))
  (if path (vl-file-delete path))
  ok
)

(defun c:BHTUITEST ()
  (bht:msg (strcat "BHTUITEST: " (if (bht:ui-validate) "PASS" "FAIL")))
  (princ)
)

;;; ----------------------------------------------------------------------
;;; 0.4.3: API cho plugin .NET (BHT.Bridge / BHT.Palette)
;;;  - Lisp la noi DUY NHAT chua thuat toan nhan / ky hieu / ky hieu anh /
;;;    kiem tra / thu tu hien thi; plugin goi cac ham duoi day, KHONG viet lai.
;;;  - Moi ham tra ve DANH SACH CHUOI: ("OK" ...) hoac ("LOI" "ly do").
;;;  - Khong hoi nguoi dung, khong mo DCL, khong phu thuoc palette.
;;;  - Duoc dang ky bang vl-acad-defun de .NET goi qua Application.Invoke
;;;    (acedInvoke) trong ngu canh lenh; cung goi duoc tu dong lenh:
;;;    (bht:api-version)
;;; ----------------------------------------------------------------------

(setq *bht-api-level* "1")

(defun bht:api-alist (r)
  (mapcar '(lambda (p) (strcat (strcase (bht:str (car p)) T) "=" (bht:str (cdr p)))) r)
)

(defun bht:api-ids (s)
  (vl-remove "" (bht:split (bht:replace (bht:replace (bht:str s) "," " ") ";" " ") " "))
)

;; Chay fn an toan; ket qua (danh sach) -> ("OK" chuoi...).
(defun bht:api-run (fn args / r)
  (setq r (vl-catch-all-apply fn args))
  (bht:log-flush)
  (cond
    ((vl-catch-all-error-p r) (list "LOI" (vl-catch-all-error-message r)))
    ((and (listp r) (= (car r) 'LOI)) (list "LOI" (bht:str (cadr r))))
    (T (cons "OK" (mapcar 'bht:str (if (listp r) r (list r))))))
)

(defun bht:api-version ()
  (list "OK" *bht-version* *bht-api-level* *bht-build*)
)

;; Lay cac thong bao cua lenh tuong tac de hien ngay trong Palette.
;; DRAIN/CLEAR: tra ve theo dung thu tu roi xoa bo dem; PEEK: chi doc.
(defun bht:api-messages (mode / out)
  (setq out (reverse *bht-screen-messages*))
  (if (member (strcase (bht:str mode)) '("DRAIN" "CLEAR"))
    (setq *bht-screen-messages* nil))
  (cons "OK" out)
)

;; Thong tin giong BHTINFO (theo handle thuc the / ID diem / ID ho so / ma anh).
(defun bht:api-info-handle (h)
  (bht:api-run '(lambda (h / e)
                  (if (and (setq e (handent (bht:str h))) (entget e))
                    (bht:info-lines e)
                    (list 'LOI (strcat "không có thực thể handle " (bht:str h)))))
               (list h))
)

(defun bht:api-info-point (pid)
  (bht:api-run '(lambda (pid / p)
                  (if (setq p (bht:pt-find (bht:str pid) (bht:pt-all)))
                    (bht:point-info-lines p)
                    (list 'LOI (strcat "không có điểm " (bht:str pid)))))
               (list pid))
)

(defun bht:api-info-object (oid)
  (bht:api-run '(lambda (oid) (bht:obj-info-lines (strcase (bht:str oid)))) (list oid))
)

(defun bht:api-info-photo (pid)
  (bht:api-run '(lambda (pid) (bht:photo-info-lines (bht:str pid))) (list pid))
)

;; Duong dan JPG ma Lisp tim thay ("" = khong thay) - dung doi chieu voi C#.
(defun bht:api-photo-path (pid)
  (bht:api-run '(lambda (pid / rec p)
                  (setq rec (bht:photo-read (strcase (bht:str pid))))
                  (if (null rec) (list 'LOI (strcat "không có ảnh " (bht:str pid)))
                    (list (if (setq p (bht:photo-path rec)) p ""))))
               (list pid))
)

;; Ky hieu theo object_id: ids "" = moi ho so; "OBJ-1,OBJ-2" = chi cac ho so do.
(defun bht:api-symbol-sync (ids)
  (bht:api-run '(lambda (ids / sc)
                  (setq sc (bht:api-ids ids))
                  (bht:ensure-model)
                  (bht:api-alist (bht:symbol-sync (if sc sc nil))))
               (list ids))
)

;; Nhan diem: "" = chi diem moi / doi noi dung; "ALL" = bo tri lai tat ca;
;; danh sach ID = bo tri lai cac diem do (nhan doi tay van giu).
(defun bht:api-label-sync (ids)
  (bht:api-run '(lambda (ids / sc r ov)
                  (setq sc (cond ((= (strcase (bht:str ids)) "ALL") 'ALL)
                                 ((bht:api-ids ids) (mapcar 'strcase (bht:api-ids ids)))
                                 (T nil)))
                  (setq r (bht:lbl-sync-scope sc)
                        ov (bht:lbl-overlaps (if (listp sc) sc nil)))
                  (append (bht:api-alist r) (list (strcat "overlap=" (bht:lbl-overlap-text ov)))))
               (list ids))
)

;; Dinh dang POINT thanh dau X dung tam va sap lai nhan toan ban ve.
(defun bht:api-point-style (size)
  (bht:api-run '(lambda (size / s)
                  (setq s (bht:num (bht:str size)))
                  (if (not (and s (> s 0.0)))
                    (list 'LOI "kích thước dấu X phải lớn hơn 0")
                    (bht:api-alist (bht:point-style-apply s T))))
               (list size))
)

(defun bht:api-photo-sync ()
  (bht:api-run '(lambda () (bht:api-alist (bht:photo-sync))) nil)
)

(defun bht:api-photo-stats ()
  (bht:api-run '(lambda () (bht:api-alist (bht:photo-stats))) nil)
)

;; Kiem tra toan ven (giong BHTKT): ("OK" "loi=n" "canh_bao=n" dong...)
(defun bht:api-check ()
  (bht:api-run '(lambda (/ r)
                  (setq r (bht:check))
                  (append (list (strcat "loi=" (itoa (car r))) (strcat "canh_bao=" (itoa (cadr r)))) (caddr r)))
               nil)
)

;; Thu tu hien thi (dung lenh DRAWORDER). Chi chay duoc khi goi tu dong lenh / Lisp o cap cao nhat.
;; Goi qua Application.Invoke (acedInvoke), AutoCAD TU CHOI lenh (kiem chung Core Console 0.4.0):
;; tra ve LOI ro rang - plugin dung duong lenh BHTTHUTUVE (SendStringToExecute) thay the.
(defun bht:api-draworder (/ r)
  (setq r (bht:api-run '(lambda () (bht:api-alist (bht:draworder-sync))) nil))
  (if (= (car r) "LOI") (bht:sv-restore))
  (if (and (= (car r) "LOI") (vl-string-search "COMMAND" (strcase (bht:str (cadr r)))))
    (list "LOI" (strcat "DRAWORDER không chạy được trong ngữ cảnh gọi API (" (bht:str (cadr r))
                        ") - dùng lệnh BHTTHUTUVE"))
    r)
)

(setq *bht-api-functions*
  '(bht:api-version bht:api-messages bht:api-info-handle bht:api-info-point bht:api-info-object bht:api-info-photo
    bht:api-photo-path bht:api-symbol-sync bht:api-label-sync bht:api-point-style bht:api-photo-sync bht:api-photo-stats
    bht:api-check bht:api-draworder))

(defun bht:api-register (/ n)
  (setq n 0)
  (if vl-acad-defun
    (foreach f *bht-api-functions*
      (if (not (vl-catch-all-error-p (vl-catch-all-apply 'vl-acad-defun (list f)))) (setq n (1+ n)))))
  n
)
(setq *bht-api-registered* (bht:api-register))

;; Tu nap Palette theo cung co che APPLOAD cua GKIN. BTH va BHT la command
;; .NET, nen Lisp khong dinh nghia c:BTH / c:BHT de tranh hai lenh trung ten.
(defun bht:command-available-p (name / value)
  (setq value (vl-catch-all-apply 'getcname (list name)))
  (and (not (vl-catch-all-error-p value)) value)
)

(defun bht:palette-load (/ result)
  (cond
    ((bht:command-available-p "BTH") T)
    ((or (null *bht-palette-dll*) (not (findfile *bht-palette-dll*))) nil)
    (T
      (setq result (vl-catch-all-apply 'vl-cmdf (list "_.NETLOAD" *bht-palette-dll*)))
      (and (not (vl-catch-all-error-p result)) (bht:command-available-p "BTH"))))
)

(defun c:BHTLOAD ()
  (if (bht:palette-load)
    (bht:msg "BHT: Palette đã sẵn sàng. Gõ BTH hoặc BHT để mở bảng.")
    (progn
      (bht:msg "BHT: không nạp được Palette.")
      (bht:msg "  Kiểm tra BHT.Palette.dll, BHT.Bridge.dll và BHT.Core.dll nằm cạnh BHT-0.4.4.lsp.")
      (bht:msg "  Có thể dùng bảng dự phòng bằng lệnh BHTDCL.")))
  (princ)
)

;;; ----------------------------------------------------------------------
(if (and (getvar "LISPSYS") (= (getvar "LISPSYS") 0))
  (princ "\nBHT CANH BAO: LISPSYS=0 - tieng Viet co dau co the hien sai. Dat LISPSYS=1, khoi dong lai AutoCAD roi nap lai."))
(bht:point-style-apply nil nil)
(setq *bht-palette-loaded* (bht:palette-load))
(defun bht:load-message () (strcat "BHT " *bht-version* " đã nạp thành công."))
(princ (strcat "\n" (bht:load-message)))
(if *bht-palette-loaded*
  (princ "\nGõ BTH hoặc BHT để mở Palette bên trái; BHTHELP để xem danh sách lệnh.")
  (princ "\nCHƯA nạp được Palette. Gõ BHTLOAD để thử lại hoặc BHTDCL để mở bảng dự phòng."))
(princ)
