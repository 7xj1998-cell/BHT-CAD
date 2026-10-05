;;; ======================================================================
;;; BHT-0.6.13.lsp - BHT 0.6.13 (build 2026-10-01)
;;; Quan ly khao sat bao hieu / coc tieu / cot Km / bang va cong trinh ven
;;; tuyen: diem RTK, ho so doi tuong, anh TimeMark (KMZ), tuyen tham chieu,
;;; ly trinh, goi thau / doan tuyen, xuat CSV cho Excel.
;;;
;;; Tiep noi truc tiep BHT 0.3.2 (release\BHT-0.3.2\BHT-0.3.2.lsp, giu nguyen
;;; khong sua) va BHT 0.1 / 0.2.0 / 0.3.x:
;;;  - giu POINT tren layer BHT_RTK + XData "BHT_RTK" (ten, ma) nhu v0.1;
;;;  - ID on dinh, ho so doi tuong, anh, tuyen/moc Km, goi thau (v0.2);
;;;  - giao dien .NET Palette; DCL du phong bo tu v0.5.5.
;;; Muc tieu: AutoCAD 2021-2024, Civil 3D 2023 (Windows). File luu UTF-8,
;;; can LISPSYS = 1 (mac dinh tu AutoCAD 2021) de hien tieng Viet co dau.
;;;
;;; NHAT KY THAY DOI 5.0 (chi tiet: CHANGELOG.md; tiep noi 0.4.6-fix3)
;;;  + Tim bien khi go (khong dau, ca d/đ): BHTBLOCK -> D hoi tu khoa, tim tren
;;;    ma + ten danh muc bien TDT (BHTSIGNSEARCH cua BHT.Bridge) hoac danh muc
;;;    noi bo khi chua co Bridge. Palette: o Mã hiệu / Mã các mặt tim khi go.
;;;  + Coc tieu / Cot Km khong co ma bien: Ma hieu de trong, khong bat buoc.
;;;    Canh bao TRUNG khi tao ho so coc tieu / cot Km: cung diem RTK, cach
;;;    <= nguong (meta trung_kc_m, mac dinh 0.5 m), cot Km trung gia tri Km.
;;;    Chi doc - khong dich / sua diem RTK.
;;;  + Tinh trang: 1=Tốt / 2=Bình thường / 3=Hư hỏng (van nhan chu tu do).
;;;  + Nhan CAD mac dinh VNRomancUpdate.shx Unicode; doc kieu TCVN3 cu.
;;;    Ho so, XData, Palette va bao cao giu Unicode.
;;;
;;; NHAT KY THAY DOI 0.4.6-fix3 (chi tiet: CHANGELOG.md)
;;;  + Loi / canh bao can nguoi dung xu ly hien cua so thong bao (tieu de "BHT",
;;;    bieu tuong loi / canh bao) VA van in ra dong lenh: bht:err / bht:warn,
;;;    *error* cua cac lenh BHT ("BHT lỗi: ..."). Huy lenh (*Cancel*) chi in
;;;    dong lenh. Tat bang (setq *bht-popup* nil). Khong hien cua so khi chay
;;;    script (.scr, CMDACTIVE bit 4) hoac trong AutoCAD Core Console.
;;;  + Palette: the doc ben phai co ten (truoc la o trong); loi phia Palette hien
;;;    MessageBox; trang thai lenh bao that bai khi lenh bao loi (bht:api-problems).
;;;  * Thong bao tim TDT dang la proxy giai thich ro: phien AutoCAD chua nap
;;;    TDTSolution 9.1 -> mo AutoCAD bang bieu tuong/profile TDT 9.1 roi chay lai.
;;;
;;; NHAT KY THAY DOI 0.4.6-fix2 (chi tiet: CHANGELOG.md)
;;;  * SUA LOI BHTTUYENTDT: loi "no function definition" do 0.4.6 goi mot ham
;;;    Common Lisp khong co trong AutoLISP de kiem tra BHTTDT91ROUTE. Thay
;;;    bang bht:fn-defined-p (type = SUBR/USUBR/
;;;    EXRXSUBR). Neu ham BHTTDT91ROUTE chua co, Lisp tu NETLOAD BHT.Bridge.dll
;;;    nam canh file Lisp roi moi bao loi. Bao ro khi ID/khoang cach khong hop le.
;;;  * bht:tdt-import-block khong con loi "bad function: BHTTDTBLOCK" khi Bridge
;;;    chua dang ky ham (vl-catch-all-apply khong bat loi nay): dung block noi bo.
;;;  * Bridge: tim TDT bi Explode thanh nhieu doan Line/Arc noi tiep duoc noi
;;;    thanh mot Polyline tham chieu (truoc day chi lay doan dai nhat).
;;;  + Palette doi sang bang mau xanh la (#065F46 / #D1FAE5 / nen #047857).
;;;  + Nut "Dau X 1u + sap nhan" doi ten thanh "Dat dau X (co 1) + sap lai nhan".
;;;  * Tieu de Palette luon theo phien ban dang chay (khong con hien 0.4.4 do
;;;    AutoCAD khoi phuc ten cu tu Profile.aws).
;;;  = Du lieu, POINT RTK, thuat toan nhan/ly trinh giu nguyen nhu 0.4.6.
;;;
;;; NHAT KY THAY DOI 0.4.6 (chi tiet: CHANGELOG.md)
;;;  + Palette toi mau than-xanh, chu hanh dong vang, thong tin cyan; thanh
;;;    chon 5 the dat doc sat mep phai de tiet kiem chieu ngang.
;;;  + Kieu diem moi BHT_RTK dung Arial Unicode width factor 0.85 cho ban ve
;;;    moi; ten/mo ta/cao do la mot cum nhan. Ban ve legacy giu BHT_ARIAL va
;;;    khong bi doi font hay doi vi tri nhan o lan cap nhat dau.
;;;  + Doi chieu cau hinh scale 1:1 cua TDT 9.1 va mo hinh point style cua
;;;    DPSurvey; van giu dau X 1 unit, khong di chuyen/lam tron POINT RTK.
;;;
;;; NHAT KY THAY DOI 0.4.5
;;;  + BHTTUYENTDT goi Tdt91Interop de doc tim TDTSolution 9.1 ban thuong
;;;    dang hoat dong: mo ForRead, Entity.Explode, tao/cap nhat Polyline rieng
;;;    tren layer BHT_TUYEN_TDT; khong dung vlax-curve tren TDTDBALIGNMENT.
;;;  + TdtSignLibrary doc 412 ma tu TDT Solution 2022, goi y ten bien va clone
;;;    block vector duoc chon vao DWG; khong sua/khong dong goi tai san TDT.
;;;  + Bien TDT scale mat 0.2, cot 0.6 unit; tu day ra ngoai tim, ve leader ve
;;;    diem RTK. POINT RTK khong bi di chuyen hay lam tron toa do.
;;;  + Palette xuat bao cao Excel .xlsx Unicode (tong hop + danh sach bien),
;;;    mo bao cao dai trong hop thoai lon va rut gon nhom lenh thuong dung.
;;;  + Van giu block tich hop/BHTBLOCK lam du phong khi TDT chua san sang.
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

(setq *bht-version* "0.6.13")
(setq *bht-build* "2026-10-01")

;; Luu duong dan ngay khi APPLOAD / Application Bundle nap Lisp. DLL dat canh
;; file Lisp de nguoi dung chi can APPLOAD mot lan, khong phai tu NETLOAD.
(setq *bht-lsp-file* (findfile "BHT-0.6.13.lsp"))
(setq *bht-lsp-dir*
  (if *bht-lsp-file* (vl-filename-directory *bht-lsp-file*) *bht-module-root*))
(setq *bht-palette-dll*
  (if *bht-lsp-dir* (strcat *bht-lsp-dir* "\\BHT.Palette.dll") nil))
(setq *bht-bridge-dll*
  (if *bht-lsp-dir* (strcat *bht-lsp-dir* "\\BHT.Bridge.dll") nil))

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

;;; 0.4.6-fix3: loi / canh bao can nguoi dung xu ly -> in dong lenh (bht:msg) VA hien cua so.
;;; *bht-popup* = nil de tat han cua so. Cua so KHONG hien khi:
;;;  - dang chay script .scr (CMDACTIVE bit 4) - kiem thu / chay lo khong bi treo;
;;;  - AutoCAD Core Console: (vlax-get-acad-object) tra nil (PROGRAM van la "acad" nen khong dung duoc);
;;;  - Palette dang goi bht:api-* (BHTPOPUP tra "SKIP"; Palette tu bao loi bang MessageBox cua no).
(setq *bht-popup* T)
(setq *bht-screen-problems* nil)
(setq *bht-core-console* nil *bht-core-console-checked* nil)

(defun bht:core-console-p (/ o)
  (if (not *bht-core-console-checked*)
    (setq *bht-core-console-checked* T
          *bht-core-console*
            (progn
              (vl-catch-all-apply 'vl-load-com nil)
              (setq o (if (member (type vlax-get-acad-object) '(SUBR USUBR EXRXSUBR))
                        (vl-catch-all-apply 'vlax-get-acad-object nil)
                        nil))
              (not (= (type o) 'VLA-OBJECT)))))
  *bht-core-console*
)

(defun bht:popup-enabled-p (/ ca)
  (setq ca (getvar "CMDACTIVE"))
  (and *bht-popup*
       (not (and ca (= 4 (logand ca 4))))
       (not (bht:core-console-p)))
)

;; kind: "ERROR" hoac "WARN". Uu tien MessageBox cua BHT.Palette (BHTPOPUP: tieu de "BHT",
;; bieu tuong loi/canh bao); khi Palette chua nap -> alert cua AutoLISP.
(defun bht:popup (kind s / r)
  (if (bht:popup-enabled-p)
    (progn
      (setq r (if (member (type BHTPOPUP) '(SUBR USUBR EXRXSUBR))
                (vl-catch-all-apply 'BHTPOPUP (list kind (bht:str s)))
                'KHONG_CO))
      (if (or (= r 'KHONG_CO) (vl-catch-all-error-p r))
        (vl-catch-all-apply 'alert
          (list (strcat (if (= kind "ERROR") "BHT - LỖI" "BHT - CẢNH BÁO") "\n\n" (bht:str s)))))))
  nil
)

;; Ghi nho loi / canh bao de Palette biet lenh vua chay that bai (bht:api-problems).
(defun bht:problem-add (kind s)
  (setq *bht-screen-problems* (cons (strcat kind "|" (bht:str s)) *bht-screen-problems*))
  (if (> (length *bht-screen-problems*) 20)
    (setq *bht-screen-problems* (reverse (cdr (reverse *bht-screen-problems*)))))
  s
)

(defun bht:err (s / r)
  (setq r (bht:msg s))
  (bht:problem-add "ERROR" s)
  (bht:popup "ERROR" s)
  r
)

(defun bht:warn (s / r)
  (setq r (bht:msg s))
  (bht:problem-add "WARN" s)
  (bht:popup "WARN" s)
  r
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
    (bht:err (strcat "BHT lỗi: " msg))
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
(defun bht:text-color-g (s p h color / style)
  (setq style (bht:text-style "BHT_TCVN"))
  (list '(0 . "TEXT") '(8 . "0") (cons 62 color) (cons 10 p) (cons 40 h) (cons 1 (bht:cad-text s style)) (cons 7 style) '(50 . 0.0)))

;; TEXT can giua theo ca hai truc. Dung cho noi dung ngan ben trong mat bien.
(defun bht:text-center-color-g (s p h color / style)
  (setq style (bht:text-style "BHT_TCVN"))
  (list '(0 . "TEXT") '(8 . "0") (cons 62 color) (cons 10 p) (cons 11 p)
        (cons 40 h) (cons 1 (bht:cad-text s style)) (cons 7 style) '(50 . 0.0) '(72 . 1) '(73 . 2)))

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

(defun bht:text (str pt h layer / style)
  (setq style (bht:text-style "BHT_TCVN"))
  (entmakex (list '(0 . "TEXT") '(410 . "Model") (cons 8 layer) (cons 10 pt) (cons 40 h)
                  (cons 1 (bht:cad-text str style)) (cons 7 style) '(50 . 0.0)))
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
  (if (or (null name) (= name "")) (setq name "BHT_TCVN"))
  (if (and (member (strcase name) '("BHT_ARIAL" "BHT_RTK")) (not (tblsearch "STYLE" name)))
    (entmake (list '(0 . "STYLE") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbTextStyleTableRecord")
                   (cons 2 name) '(70 . 0) '(40 . 0.0) (cons 41 (if (= (strcase name) "BHT_RTK") 0.85 1.0))
                   '(50 . 0.0) '(71 . 0)
                   '(42 . 1.0) '(3 . "arial.ttf") '(4 . ""))))
  (if (= (strcase name) "BHT_TCVN") (bht:tcvn-style name) (if (tblsearch "STYLE" name) name "Standard"))
)

(setq *bht-sign-style* "BHT_BIENBAO" *bht-sign-font* "VNRomancUpdate.shx")
;; 0.5.2: Unicode SHX default; retain TCVN3 only for legacy vnromanc styles.
;; Legacy TCVN3 map: one code sequence, two case sequences, seven uppercase exceptions.
;; NFC and NFD are equivalent inputs; do not collapse the glyphs for Ê/ê, Đ/đ, etc.
(defun bht:font-case-map (chars codes overrides / out i pair code)
  (setq out nil i 1)
  (foreach code codes
    (setq pair (assoc (substr chars i 1) overrides)
          out (cons (cons (substr chars i 1) (if pair (cdr pair) code)) out) i (1+ i)))
  (reverse out))
(setq *bht-tcvn-codes* '(
  181 184 182 183 185 168 187 190 188 189 198 169 199 202 200 201 203
  174 204 208 206 207 209 170 210 213 211 212 214 215 221 216 220 222
  223 227 225 226 228 171 229 232 230 231 233 172 234 237 235 236 238
  239 243 241 242 244 173 245 248 246 247 249 250 253 251 252 254
))
(setq *bht-tcvn-map* (append
  (bht:font-case-map "àáảãạăằắẳẵặâầấẩẫậđèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵ" *bht-tcvn-codes* nil)
  (bht:font-case-map "ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬĐÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴ" *bht-tcvn-codes* '(("Ă" . 161) ("Â" . 162) ("Đ" . 167) ("Ê" . 163) ("Ô" . 164) ("Ơ" . 165) ("Ư" . 166)))))
(defun bht:legacy-tcvn-encode (s / out c hit)
  (setq out "")
  (foreach c (vl-string->list (bht:unicode-nfc s))
    (setq hit (assoc (chr c) *bht-tcvn-map*) out (strcat out (chr (if hit (cdr hit) c)))))
  out)

;; Unicode font requires NFC; compose Vietnamese accents from decomposed input.
;; Pack compositions by initial character, preserving every 0.5.3 mapping (including Latin).
;; Generate partial compositions too: ê + acute -> ế, â + dot below -> ậ.
(defun bht:font-compositions (rows / out row i key target extra base)
  (setq out nil)
  (foreach row rows
    (setq i 1)
    (foreach key (cadr row)
      (setq target (substr (car row) i 1) out (cons (cons key target) out) i (1+ i))
      (if (= (strlen key) 3)
        (progn
          (setq extra (if (= (substr key 2 1) (chr 803)) (substr key 2 1) (substr key 3 1))
                base (if (= (substr key 2 1) (chr 803)) (strcat (substr key 1 1) (substr key 3 1)) (substr key 1 2)))
          ;; Base compositions may occur later in the generated map; resolve in a second pass.
          (setq out (cons (cons (strcat base extra) target) out))))))
  (setq rows out)
  (foreach row rows
    (if (= (strlen (car row)) 3)
      (progn
        (setq key (car row) base (assoc (substr key 1 2) out))
        (if base (setq out (cons (cons (strcat (cdr base) (substr key 3 1)) (cdr row)) out))))))
  out)
(setq *bht-nfc-map* (bht:font-compositions '(
  ("ẤẦẨẪẬẮẰẲẴẶÀÁÂÃĂẠẢ" ("Ấ" "Ầ" "Ẩ" "Ẫ" "Ậ" "Ắ" "Ằ" "Ẳ" "Ẵ" "Ặ" "À" "Á" "Â" "Ã" "Ă" "Ạ" "Ả"))
  ("ấầẩẫậắằẳẵặàáâãăạả" ("ấ" "ầ" "ẩ" "ẫ" "ậ" "ắ" "ằ" "ẳ" "ẵ" "ặ" "à" "á" "â" "ã" "ă" "ạ" "ả"))
  ("ẾỀỂỄỆÈÉÊĔẸẺẼ" ("Ế" "Ề" "Ể" "Ễ" "Ệ" "È" "É" "Ê" "Ĕ" "Ẹ" "Ẻ" "Ẽ"))
  ("ếềểễệèéêĕẹẻẽ" ("ế" "ề" "ể" "ễ" "ệ" "è" "é" "ê" "ĕ" "ẹ" "ẻ" "ẽ"))
  ("ỐỒỔỖỘỚỜỞỠỢÒÓÔÕŎƠỌỎ" ("Ố" "Ồ" "Ổ" "Ỗ" "Ộ" "Ớ" "Ờ" "Ở" "Ỡ" "Ợ" "Ò" "Ó" "Ô" "Õ" "Ŏ" "Ơ" "Ọ" "Ỏ"))
  ("ốồổỗộớờởỡợòóôõŏơọỏ" ("ố" "ồ" "ổ" "ỗ" "ộ" "ớ" "ờ" "ở" "ỡ" "ợ" "ò" "ó" "ô" "õ" "ŏ" "ơ" "ọ" "ỏ"))
  ("ỨỪỬỮỰÙÚÛŨŬƯỤỦ" ("Ứ" "Ừ" "Ử" "Ữ" "Ự" "Ù" "Ú" "Û" "Ũ" "Ŭ" "Ư" "Ụ" "Ủ"))
  ("ứừửữựùúûũŭưụủ" ("ứ" "ừ" "ử" "ữ" "ự" "ù" "ú" "û" "ũ" "ŭ" "ư" "ụ" "ủ"))
  ("ÌÍÎĨĬỈỊ" ("Ì" "Í" "Î" "Ĩ" "Ĭ" "Ỉ" "Ị"))
  ("ÑŃǸ" ("Ñ" "Ń" "Ǹ"))
  ("ÝŶỲỴỶỸ" ("Ý" "Ŷ" "Ỳ" "Ỵ" "Ỷ" "Ỹ"))
  ("ìíîĩĭỉị" ("ì" "í" "î" "ĩ" "ĭ" "ỉ" "ị"))
  ("ñńǹ" ("ñ" "ń" "ǹ"))
  ("ýŷỳỵỷỹ" ("ý" "ŷ" "ỳ" "ỵ" "ỷ" "ỹ"))
  ("ĆĈ" ("Ć" "Ĉ"))
  ("ćĉ" ("ć" "ĉ"))
  ("ĜĞǴ" ("Ĝ" "Ğ" "Ǵ"))
  ("ĝğǵ" ("ĝ" "ğ" "ǵ"))
  ("Ĥ" ("Ĥ"))
  ("ĥ" ("ĥ"))
  ("Ĵ" ("Ĵ"))
  ("ĵ" ("ĵ"))
  ("Ĺ" ("Ĺ"))
  ("ĺ" ("ĺ"))
  ("Ŕ" ("Ŕ"))
  ("ŕ" ("ŕ"))
  ("ŚŜ" ("Ś" "Ŝ"))
  ("śŝ" ("ś" "ŝ"))
  ("Ŵ" ("Ŵ"))
  ("ŵ" ("ŵ"))
  ("Ź" ("Ź"))
  ("ź" ("ź"))
)))
(defun bht:legacy-unicode-nfc (s / i n hit out)
  (setq s (bht:str s) i 1 n (strlen s) out "")
  (while (<= i n)
    (setq hit (assoc (substr s i (min 3 (1+ (- n i)))) *bht-nfc-map*))
    (if (null hit) (setq hit (assoc (substr s i (min 2 (1+ (- n i)))) *bht-nfc-map*)))
    (if hit (setq out (strcat out (cdr hit)) i (+ i (strlen (car hit))))
      (setq out (strcat out (substr s i 1)) i (1+ i))))
  out)
(defun bht:legacy-tcvn-decode (s / map pair out c)
  (setq map nil out "")
  (foreach pair *bht-tcvn-map*
    (if (and (= (strlen (car pair)) 1) (null (assoc (cdr pair) map)))
      (setq map (cons (cons (cdr pair) (car pair)) map))))
  (foreach c (vl-string->list (bht:str s))
    (setq pair (assoc c map) out (strcat out (if pair (cdr pair) (chr c)))))
  out)
;; Native .NET text engine when Bridge is loaded; standalone Lisp remains supported.
(defun bht:native-text (operation value / result)
  (if (and (not *bht-force-lisp-text*) (bht:fn-defined-p 'BHTNATIVETEXT))
    (progn
      (setq result (vl-catch-all-apply 'BHTNATIVETEXT (list operation (bht:str value))))
      (if (= (type result) 'STR) (progn (setq *bht-text-backend* "NET") result)))))
(defun bht:unicode-nfc (s / result)
  (if (setq result (bht:native-text "NFC" s)) result (progn (setq *bht-text-backend* "LISP") (bht:legacy-unicode-nfc s))))
(defun bht:tcvn-encode (s / result)
  (if (setq result (bht:native-text "ENCODE" s)) result (progn (setq *bht-text-backend* "LISP") (bht:legacy-tcvn-encode s))))
(defun bht:tcvn-decode (s / result)
  (if (setq result (bht:native-text "DECODE" s)) result (progn (setq *bht-text-backend* "LISP") (bht:legacy-tcvn-decode s))))
;; Only migrate BHT-owned TEXT styles. RTK data/XData and custom styles stay untouched.
(defun bht:migrate-font-text (name / ss i e d)
  (if (setq ss (ssget "_X" (list '(0 . "TEXT") (cons 7 name))))
    (progn (setq i 0)
      (repeat (sslength ss)
        (setq e (ssname ss i) d (entget e) i (1+ i))
        (if (entmod (bht:dxf-put d 1 (bht:tcvn-decode (cdr (assoc 1 d))))) (entupd e))))))

(defun bht:sign-font-file (/ p)
  (cond
    ((setq p (findfile *bht-sign-font*)) p)
    ((and *bht-lsp-dir* (setq p (findfile (strcat *bht-lsp-dir* "/" *bht-sign-font*)))) p)
    ((and *bht-lsp-dir* (setq p (findfile (strcat *bht-lsp-dir* "/../Fonts/" *bht-sign-font*)))) p)
    ((setq p (findfile (strcat "C:/Program Files (x86)/TDT Solution 2022/" *bht-sign-font*))) p)))

(defun bht:tcvn-style (name / font e d)
  (if (setq font (bht:sign-font-file))
    (progn
      (if (setq e (tblobjname "STYLE" name))
        (progn (setq d (entget e))
               (if (/= (strcase (vl-filename-base (cdr (assoc 3 d)))) (strcase (vl-filename-base *bht-sign-font*)))
                 (progn
                   (if (and (= (strcase (vl-filename-base (cdr (assoc 3 d)))) "VNROMANC")
                            (member name '("BHT_TCVN" "BHT_BIENBAO")))
                     (bht:migrate-font-text name))
                   (entmod (bht:dxf-put d 3 *bht-sign-font*)))))
        (entmake (list '(0 . "STYLE") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbTextStyleTableRecord")
                       (cons 2 name) '(70 . 0) '(40 . 0.0) '(41 . 1.0) '(50 . 0.0) '(71 . 0)
                       '(42 . 1.0) (cons 3 *bht-sign-font*) '(4 . ""))))
      (if (tblsearch "STYLE" name) name (bht:text-style "BHT_ARIAL")))
    (bht:text-style "BHT_ARIAL")))

(defun bht:cad-text (s style / record font)
  (setq record (tblsearch "STYLE" style) font (if record (cdr (assoc 3 record)) ""))
  (if (= (strcase (vl-filename-base (if font font ""))) "VNROMANC")
    (bht:tcvn-encode s) (bht:unicode-nfc s)))

(defun bht:default-label-style (/ chosen)
  (setq chosen (bht:meta "nhan_kieu_chu" "BHT_TCVN"))
  (if (member (strcase chosen) '("" "BHT_ARIAL" "BHT_RTK")) "BHT_TCVN" chosen))

(defun bht:sign-label-style () (bht:tcvn-style *bht-sign-style*))
(defun bht:ascii-p (s) (vl-every '(lambda (c) (and (>= c 32) (<= c 126))) (vl-string->list (bht:str s))))
(defun bht:kh-label-style (lbl) (bht:sign-label-style))

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

