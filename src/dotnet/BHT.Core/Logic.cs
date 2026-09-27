using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;

namespace BHT.Core
{
    /// <summary>
    /// Thuat toan du lieu thuan (khong AutoCAD) - ban C# cua cac ham Lisp tuong ung.
    /// Chi viet lai phan DOC/GHI du lieu ho so (khong viet lai nhan / ky hieu / kiem tra).
    /// Moi ham deu duoc doi chieu voi Lisp trong kiem thu tich hop (xem docs/DATA_CONTRACT.md).
    /// </summary>
    public static class ObjectLogic
    {
        /// <summary>bht:valid-id (sau strcase): 1-60 ky tu A-Z 0-9 _ - .</summary>
        public static bool ValidId(string s)
        {
            if (string.IsNullOrEmpty(s) || s.Length > 60) return false;
            foreach (char c in s)
                if (!((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '-' || c == '.')) return false;
            return true;
        }

        /// <summary>bht:obj-seq-num: "OBJ-######" -> so; khac -> -1.</summary>
        public static int SeqNum(string id)
        {
            if (id == null || id.Length != 10 || !id.StartsWith("OBJ-", StringComparison.Ordinal)) return -1;
            for (int i = 4; i < 10; i++) if (id[i] < '0' || id[i] > '9') return -1;
            return int.Parse(id.Substring(4), CultureInfo.InvariantCulture);
        }

        /// <summary>bht:obj-next-id: khong dung lai so cua ho so da xoa (moc cao nhat META obj_seq).</summary>
        public static string NextId(IEnumerable<string> keys, string metaObjSeq)
        {
            var ks = new HashSet<string>(keys ?? new string[0], StringComparer.Ordinal);
            int n = ParseIntLikeLisp(metaObjSeq);
            foreach (var k in ks) { int v = SeqNum(k); if (v > n) n = v; }
            n++;
            string id = "OBJ-" + n.ToString("D6", CultureInfo.InvariantCulture);
            while (ks.Contains(id)) { n++; id = "OBJ-" + n.ToString("D6", CultureInfo.InvariantCulture); }
            return id;
        }

        /// <summary>bht:int (fix cua so thuc), khong hop le -> 0.</summary>
        public static int ParseIntLikeLisp(string s)
        {
            double d;
            if (double.TryParse((s ?? "").Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out d)) return (int)Math.Truncate(d);
            return 0;
        }

        /// <summary>bht:pt-owner-map: survey_point_id (HOA) -> danh sach object_id theo thu tu ho so.</summary>
        public static Dictionary<string, List<string>> OwnerMap(IEnumerable<KeyValuePair<string, BhtRecord>> objects)
        {
            var map = new Dictionary<string, List<string>>(StringComparer.Ordinal);
            foreach (var o in objects)
                foreach (var pid in o.Value.GetAll(ObjFields.Point))
                {
                    string u = pid.ToUpperInvariant();
                    List<string> l;
                    if (!map.TryGetValue(u, out l)) { l = new List<string>(); map[u] = l; }
                    l.Add(o.Key);
                }
            return map;
        }

        /// <summary>bht:obj-overlap: (ho so co diem chung, ho so co DUNG bo diem da chon).</summary>
        public static void Overlap(IList<string> pids, IDictionary<string, BhtRecord> objects,
                                   out List<string> hits, out List<string> same)
        {
            var up = pids.Select(p => p.ToUpperInvariant()).ToList();
            var owners = OwnerMap(objects);
            hits = new List<string>(); same = new List<string>();
            foreach (var p in up)
            {
                List<string> l;
                if (owners.TryGetValue(p, out l)) foreach (var o in l) if (!hits.Contains(o)) hits.Add(o);
            }
            foreach (var o in hits)
            {
                var s = objects[o].GetAll(ObjFields.Point).Select(x => x.ToUpperInvariant()).ToList();
                if (s.Count == up.Count && s.All(x => up.Contains(x))) same.Add(o);
            }
        }

        /// <summary>
        /// Kiem tra + dung ban ghi moi giong bht:obj-create. Tra ve null neu hop le (rec co gia tri),
        /// nguoc lai la ly do tu choi (tieng Viet, giong Lisp).
        /// </summary>
        public static string BuildNew(string id, BhtRecord fields, IList<string> pids, bool allowShared,
                                      ISet<string> existingPointIdsUpper, IDictionary<string, BhtRecord> objects,
                                      string now, out BhtRecord rec)
        {
            rec = null;
            id = (id ?? "").Trim().ToUpperInvariant();
            var owners = OwnerMap(objects);
            var bad = new List<string>(); var shared = new List<string>();
            foreach (var pid in pids ?? new List<string>())
            {
                if (!existingPointIdsUpper.Contains(pid.ToUpperInvariant())) bad.Insert(0, pid);
                if (owners.ContainsKey(pid.ToUpperInvariant())) shared.Insert(0, pid);
            }
            string grp = Groups.Code(fields.Get(ObjFields.Group));
            if (!ValidId(id)) return "ID không hợp lệ (A-Z 0-9 _ - .)";
            if (objects.ContainsKey(id)) return "ID " + id + " đã tồn tại";
            if (pids == null || pids.Count == 0) return "chưa chọn điểm RTK nào";
            if (bad.Count > 0) return "không tìm thấy điểm: " + string.Join(", ", bad);
            if (shared.Count > 0 && !allowShared) return "điểm đã thuộc đối tượng khác: " + string.Join(", ", shared);
            Func<string, string, string> def = (k, d) => fields.Get(k) != "" ? fields.Get(k) : d;
            rec = new BhtRecord()
                .Add(ObjFields.Id, id)
                .Add(ObjFields.Group, grp ?? "CHUA_XAC_DINH")
                .Add(ObjFields.Code, fields.Get(ObjFields.Code))
                .Add(ObjFields.CodeType, def(ObjFields.CodeType, "CHUA_XAC_DINH"))
                .Add(ObjFields.Desc, fields.Get(ObjFields.Desc))
                .Add(ObjFields.PoleCount, fields.Get(ObjFields.PoleCount))
                .Add(ObjFields.FaceCount, fields.Get(ObjFields.FaceCount))
                .Add(ObjFields.Condition, fields.Get(ObjFields.Condition))
                .Add(ObjFields.CheckState, def(ObjFields.CheckState, "CHUA_KIEM_TRA"))
                .Add(ObjFields.Note, fields.Get(ObjFields.Note))
                .Add(ObjFields.RoadSide, def(ObjFields.RoadSide, "CHUA_XAC_DINH"))
                .Add(ObjFields.Segment, "").Add(ObjFields.Package, "").Add(ObjFields.SegMethod, "CHUA_PHAN_DOAN")
                .Add(ObjFields.KmState, "CHUA_TINH")
                .Add(ObjFields.CreatedAt, now);
            rec.SetAll(ObjFields.Face, fields.GetAll(ObjFields.Face));
            rec.SetAll(ObjFields.Point, pids.Select(p => p.ToUpperInvariant()));
            rec.Set(ObjFields.ModifiedAt, now); // bht:obj-write luon dong dau sua_luc
            return null;
        }

        /// <summary>
        /// Sua cac truong nguoi dung (giong bht:obj-edit-interactive): khi sua ca bo truong (co "so_mat" hoac "mat")
        /// thi cac "mat" cu bi thay toan bo (them cuoi); truong khac dung bht:set. Dong dau sua_luc.
        /// </summary>
        public static BhtRecord ApplyEdit(BhtRecord rec, BhtRecord fields, string now)
        {
            var r = rec.Clone();
            if (fields.Has(ObjFields.Face) || fields.Has(ObjFields.FaceCount)) r.SetAll(ObjFields.Face, null);
            foreach (var p in fields.Pairs)
            {
                if (p.Key == ObjFields.Face) r.Add(p.Key, p.Value);
                else if (p.Key == ObjFields.Group) r.Set(p.Key, Groups.Code(p.Value) ?? p.Value);
                else r.Set(p.Key, p.Value);
            }
            r.Set(ObjFields.ModifiedAt, now);
            return r;
        }

        /// <summary>bht:obj-add-points.</summary>
        public static BhtRecord AddPoints(BhtRecord rec, IEnumerable<string> pids, string now)
        {
            var cur = rec.GetAll(ObjFields.Point);
            foreach (var p in pids) { var u = p.ToUpperInvariant(); if (!cur.Contains(u)) cur.Add(u); }
            return rec.Clone().SetAll(ObjFields.Point, cur).Set(ObjFields.ModifiedAt, now);
        }

        /// <summary>bht:obj-remove-points.</summary>
        public static BhtRecord RemovePoints(BhtRecord rec, IEnumerable<string> pids, string now)
        {
            var up = new HashSet<string>(pids.Select(p => p.ToUpperInvariant()));
            var cur = rec.GetAll(ObjFields.Point).Where(p => !up.Contains(p.ToUpperInvariant())).ToList();
            return rec.Clone().SetAll(ObjFields.Point, cur).Set(ObjFields.ModifiedAt, now);
        }

        /// <summary>Ma anh cua 1 muc "anh" ("PHOTO|DA_XAC_NHAN|cach").</summary>
        public static string PhotoIdOfLink(string a) { int i = (a ?? "").IndexOf('|'); return (i < 0 ? a : a.Substring(0, i)).ToUpperInvariant(); }

        /// <summary>bht:photo-link: tra ve (ho so moi, ban ghi anh moi). how = "THU_CONG" / "XAC_NHAN_DE_XUAT" ...</summary>
        public static void LinkPhoto(string pid, string oid, string how, BhtRecord obj, BhtRecord photo, string now,
                                     out BhtRecord newObj, out BhtRecord newPhoto)
        {
            pid = pid.ToUpperInvariant(); oid = oid.ToUpperInvariant();
            var lst = obj.GetAll(ObjFields.Photo).Where(a => PhotoIdOfLink(a) != pid).ToList();
            lst.Add(pid + "|DA_XAC_NHAN|" + how);
            newObj = obj.Clone().SetAll(ObjFields.Photo, lst).Set(ObjFields.ModifiedAt, now);
            var dt = photo.GetAll(PhotoFields.Objects);
            if (!dt.Contains(oid)) dt.Add(oid);
            newPhoto = photo.Clone().SetAll(PhotoFields.Objects, dt).Set(PhotoFields.State, "DA_XAC_NHAN");
        }

        /// <summary>bht:photo-unlink (+ photo-unlink-side).</summary>
        public static void UnlinkPhoto(string pid, string oid, BhtRecord obj, BhtRecord photo, string now,
                                       out BhtRecord newObj, out BhtRecord newPhoto)
        {
            pid = pid.ToUpperInvariant(); oid = oid.ToUpperInvariant();
            newObj = obj == null ? null : obj.Clone().SetAll(ObjFields.Photo, obj.GetAll(ObjFields.Photo).Where(a => PhotoIdOfLink(a) != pid)).Set(ObjFields.ModifiedAt, now);
            newPhoto = null;
            if (photo != null)
            {
                var lst = photo.GetAll(PhotoFields.Objects).Select(x => x.ToUpperInvariant()).Where(x => x != oid).ToList();
                newPhoto = photo.Clone().SetAll(PhotoFields.Objects, lst);
                if (lst.Count == 0) newPhoto.Set(PhotoFields.State, "CHUA_GHEP");
            }
        }

        /// <summary>bht:obj-position: trung binh toa do cac diem RTK cua ho so (khong dich diem).</summary>
        public static bool Position(BhtRecord rec, IDictionary<string, SurveyPoint> index, out double x, out double y, out double z)
        {
            x = y = z = 0; int n = 0;
            foreach (var pid in rec.GetAll(ObjFields.Point))
            {
                SurveyPoint p;
                if (index.TryGetValue(pid.ToUpperInvariant(), out p)) { x += p.X; y += p.Y; z += p.Z; n++; }
            }
            if (n == 0) return false;
            x /= n; y /= n; z /= n; return true;
        }
    }

    /// <summary>Đọc và định dạng lý trình nhập tay theo cùng quy ước với Lisp BHT.</summary>
    public static class Chainage
    {
        /// <summary>
        /// Chấp nhận Km39+050.5, 39+050.5 hoặc số mét 39050.5. Dấu phẩy thập phân
        /// cũng được chấp nhận để thuận tiện khi nhập theo thiết lập vùng Việt Nam.
        /// </summary>
        public static bool TryParse(string text, out double metres)
        {
            metres = 0.0;
            string s = (text ?? "").Trim().Replace(" ", "").Replace(',', '.').ToUpperInvariant();
            if (s.StartsWith("KM", StringComparison.Ordinal)) s = s.Substring(2);
            if (s.Length == 0) return false;

            int plus = s.IndexOf('+');
            if (plus >= 0)
            {
                if (plus == 0 || plus != s.LastIndexOf('+') || plus == s.Length - 1) return false;
                double km, remainder;
                if (!double.TryParse(s.Substring(0, plus), NumberStyles.Float, CultureInfo.InvariantCulture, out km)
                    || !double.TryParse(s.Substring(plus + 1), NumberStyles.Float, CultureInfo.InvariantCulture, out remainder)) return false;
                if (km < 0.0 || km != Math.Truncate(km) || remainder < 0.0 || remainder >= 1000.0) return false;
                metres = km * 1000.0 + remainder;
                return !double.IsNaN(metres) && !double.IsInfinity(metres);
            }

            if (!double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out metres)) return false;
            return metres >= 0.0 && !double.IsNaN(metres) && !double.IsInfinity(metres);
        }

        /// <summary>Định dạng mét thành Km39+050.50, làm tròn nửa lên ở 0,01 m.</summary>
        public static string Format(double metres)
        {
            if (double.IsNaN(metres) || double.IsInfinity(metres) || metres < 0.0) return "";
            decimal rounded = decimal.Round((decimal)metres, 2, MidpointRounding.AwayFromZero);
            long km = (long)decimal.Floor(rounded / 1000m);
            decimal remainder = rounded - km * 1000m;
            if (remainder >= 1000m) { km++; remainder = 0m; }
            return "Km" + km.ToString(CultureInfo.InvariantCulture) + "+"
                + remainder.ToString("000.00", CultureInfo.InvariantCulture);
        }
    }

    public static class PhotoLogic
    {
        private static string Slash(string dir)
        {
            if (dir == "" || dir.EndsWith("\\") || dir.EndsWith("/")) return dir;
            return dir + "\\";
        }

        /// <summary>
        /// bht:photo-path-candidates: file_tt, goc+tuong doi, thu_muc_anh + (tuong doi | ten | photos\ten),
        /// thu muc DWG + tuong doi. dwgPrefix = DWGPREFIX ("" neu ban ve chua luu).
        /// </summary>
        public static List<string> Candidates(BhtRecord rec, string metaPhotoFolder, string dwgPrefix)
        {
            string rel = rec.Get(PhotoFields.RelPath).Replace('/', '\\');
            string baseName = "";
            if (rel != "")
            {
                string fn = rel;
                int k = fn.LastIndexOf('\\'); if (k >= 0) fn = fn.Substring(k + 1);
                baseName = fn; // vl-filename-base + vl-filename-extension = ten file day du
            }
            string alt = metaPhotoFolder ?? "", goc = rec.Get(PhotoFields.Root), tt = rec.Get(PhotoFields.RelinkedFile);
            var o = new List<string>();
            if (tt != "") o.Add(tt);
            if (rel != "")
            {
                if (goc != "") o.Add(Slash(goc) + rel);
                if (alt != "") { o.Add(Slash(alt) + rel); o.Add(Slash(alt) + baseName); o.Add(Slash(alt) + "photos\\" + baseName); }
                if (!string.IsNullOrEmpty(dwgPrefix)) o.Add(Slash(dwgPrefix) + rel);
            }
            return o;
        }

        /// <summary>bht:photo-path: ung vien dau tien ton tai va co kich thuoc &gt; 0.</summary>
        public static string Resolve(BhtRecord rec, string metaPhotoFolder, string dwgPrefix, Func<string, bool> fileOk)
        {
            foreach (var p in Candidates(rec, metaPhotoFolder, dwgPrefix)) if (fileOk(p)) return p;
            return null;
        }

        public static bool FileOk(string p)
        {
            try { if (string.IsNullOrEmpty(p)) return false; var fi = new FileInfo(p); return fi.Exists && fi.Length > 0; }
            catch { return false; }
        }

        public static bool GpsValid(BhtRecord rec) { return rec.Get(PhotoFields.GpsValid) == "1"; }

        /// <summary>Vi tri chup E/N DA TINH (Lisp luu khi dong bo / de xuat). Khong tu chieu lai toa do.</summary>
        public static bool ShotEN(BhtRecord rec, out double e, out double n)
        {
            e = n = 0;
            return GpsValid(rec)
                && double.TryParse(rec.Get(PhotoFields.E), NumberStyles.Float, CultureInfo.InvariantCulture, out e)
                && double.TryParse(rec.Get(PhotoFields.N), NumberStyles.Float, CultureInfo.InvariantCulture, out n);
        }
    }

    public sealed class Nearby<T>
    {
        public T Item; public double Distance;
        public Nearby(T item, double d) { Item = item; Distance = d; }
    }

    public static class Geo
    {
        public static double Dist2D(double x1, double y1, double x2, double y2)
        {
            double dx = x1 - x2, dy = y1 - y2; return Math.Sqrt(dx * dx + dy * dy);
        }

        /// <summary>Diem RTK trong ban kinh r quanh vi tri chup (CHI de goi y; khong bao gio lay GPS anh lam toa do doi tuong).</summary>
        public static List<Nearby<SurveyPoint>> PointsNear(double e, double n, IEnumerable<SurveyPoint> pts, double r, int max)
        {
            var l = new List<Nearby<SurveyPoint>>();
            foreach (var p in pts) { double d = Dist2D(e, n, p.X, p.Y); if (d <= r) l.Add(new Nearby<SurveyPoint>(p, d)); }
            l.Sort((a, b) => a.Distance.CompareTo(b.Distance));
            if (max > 0 && l.Count > max) l.RemoveRange(max, l.Count - max);
            return l;
        }

        /// <summary>Anh (co vi tri chup) trong ban kinh r quanh 1 diem, gan nhat truoc.</summary>
        public static List<Nearby<string>> PhotosNear(double x, double y, IDictionary<string, BhtRecord> photos, double r)
        {
            var l = new List<Nearby<string>>();
            foreach (var kv in photos)
            {
                double e, n;
                if (PhotoLogic.ShotEN(kv.Value, out e, out n))
                {
                    double d = Dist2D(x, y, e, n);
                    if (d <= r) l.Add(new Nearby<string>(kv.Key, d));
                }
            }
            l.Sort((a, b) => { int c = a.Distance.CompareTo(b.Distance); return c != 0 ? c : string.CompareOrdinal(a.Item, b.Item); });
            return l;
        }
    }

    public static class TextSearch
    {
        /// <summary>Bo dau tieng Viet + chu thuong de tim kiem (đ -> d).</summary>
        public static string Fold(string s)
        {
            if (string.IsNullOrEmpty(s)) return "";
            var norm = s.Normalize(NormalizationForm.FormD);
            var sb = new StringBuilder(norm.Length);
            foreach (char c in norm)
            {
                var cat = CharUnicodeInfo.GetUnicodeCategory(c);
                if (cat == UnicodeCategory.NonSpacingMark) continue;
                if (c == 'đ' || c == 'Đ') sb.Append('d'); else sb.Append(char.ToLowerInvariant(c));
            }
            return sb.ToString();
        }

        /// <summary>Moi tu trong truy van phai xuat hien (khong dau, khong phan biet hoa) trong ten / ID / mo ta / phan loai.</summary>
        public static bool Match(SurveyPoint p, string query)
        {
            if (string.IsNullOrWhiteSpace(query)) return true;
            string hay = Fold(p.Name + " " + p.Id + " " + p.Description + " " + p.Class);
            foreach (var w in Fold(query).Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries))
                if (hay.IndexOf(w, StringComparison.Ordinal) < 0) return false;
            return true;
        }

        public static List<SurveyPoint> Filter(IEnumerable<SurveyPoint> pts, string query, string classFilter)
        {
            return pts.Where(p => Match(p, query) && (string.IsNullOrEmpty(classFilter) || p.Class == classFilter)).ToList();
        }
    }
}
