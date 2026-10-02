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
        (progn (bht:err (strcat "BHT KMZ: giải nén lỗi: " (if res res "không chạy được PowerShell"))) nil)))
    (progn (bht:err "BHT KMZ: không ghi được script tạm.") nil))
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
        (progn (bht:err "BHT KMZ: không thấy doc.kml trong KMZ.") nil)
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
  (entmakex (list '(0 . "TEXT") '(410 . "Model") '(8 . "BHT_ANH_TEN") (cons 10 pt) (cons 40 h) (cons 1 (bht:cad-text id style)) '(50 . 0.0)
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
        h (bht:num (bht:meta "anh_nhan_h" "0.45"))
        style (bht:text-style (bht:default-label-style)))
  (if (or (null h) (<= h 0)) (setq h 0.45))
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
    (bht:warn "BHT: chưa có bản ghi ảnh. Dùng BHTKMZ hoặc BHTANHNAP trước.")
    (progn
      (setq r (bht:photo-sync))
      (bht:photo-sync-report r)
      (bht:photo-stats-report (bht:photo-stats))))
  (bht:log-flush)
  (princ)
)
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
           (T (bht:warn (strcat "BHT: không có ảnh " v ".")) nil)))
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
              (if (bht:photo-read v) v (progn (bht:warn (strcat "BHT: không có ảnh " v ".")) nil)))))))
    (T nil))
)

;; Xem anh: thong tin + mo JPG, anh truoc/sau, gan vao doi tuong (xac nhan thu cong).
(defun bht:photo-browse (pid / v r stop nx oid res sug reopen)
  (setq stop nil reopen T pid (strcase pid))
  (while (and pid (not stop))
    (foreach l (bht:photo-info-lines pid) (bht:msg l))
    (if reopen
      (progn (setq r (bht:photo-open pid))
             (if (not (car r)) (bht:err (strcat "BHT: " (cadr r))))))
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
                (if (car res) (bht:msg (strcat "BHT: đã gắn " pid " -> " oid ".")) (bht:err (strcat "BHT: " (cadr res)))))))
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
    (T (bht:warn (strcat "BHT: không có ảnh " v "."))))
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
           (bht:warn "BHT: chiều rộng không hợp lệ."))))))
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

