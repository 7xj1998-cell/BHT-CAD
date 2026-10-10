using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace BHT.Core
{
    /// <summary>
    /// Diem RTK (nguon du lieu goc). Doc tu POINT layer BHT_RTK + XData "BHT_PT":
    /// id, dataset, dong, ten, N goc, E goc, Z goc, phan loai goi y, file nguon,
    /// thoi diem nhap, cac doan mo ta goc (&lt;= 80 ky tu / doan).
    /// Chuoi N/E/Z goc giu NGUYEN VAN; X/Y/Z la toa do POINT tren ban ve (X = E, Y = N).
    /// </summary>
    public sealed class SurveyPoint
    {
        public string Id;          // vd BOT19-R-000001
        public string Dataset;
        public string Row;
        public string Name;
        public string NRaw, ERaw, ZRaw;
        public string Class;       // phan loai GOI Y tu mo ta (khong phai ma QCVN)
        public string SourceFile;
        public string ImportedAt;
        public string Description; // mo ta goc (noi cac doan)
        public double X, Y, Z;     // toa do POINT tren ban ve
        public string Handle;      // handle thuc the POINT (hex)
        public string Space;       // "Model" hoac ten layout

        public string IdUpper { get { return (Id ?? "").ToUpperInvariant(); } }

        /// <summary>Giong bht:pt-from-ent: can &gt;= 10 chuoi XData, mo ta = noi phan con lai.</summary>
        public static SurveyPoint FromXData(IList<string> x, double px, double py, double pz)
        {
            if (x == null || x.Count < 10) return null;
            var sb = new StringBuilder();
            for (int i = 10; i < x.Count; i++) sb.Append(x[i]);
            return new SurveyPoint
            {
                Id = x[0], Dataset = x[1], Row = x[2], Name = x[3], NRaw = x[4], ERaw = x[5], ZRaw = x[6],
                Class = x[7], SourceFile = x[8], ImportedAt = x[9], Description = sb.ToString(),
                X = px, Y = py, Z = pz
            };
        }
    }

    /// <summary>Truy cap theo ten truong cho ho so doi tuong (dictionary OBJ).</summary>
    public static class ObjFields
    {
        public const string Id = "object_id", Group = "nhom", Code = "ma_hieu", CodeType = "loai_ma", Desc = "mo_ta",
            SignContent = "sign_content", SignLayout = "sign_layout", SignGap = "sign_gap", SignClearance = "sign_clearance", BridgeName = "bridge_name", SignChainage = "sign_chainage", RoadName = "road_name", MarkerKm = "marker_km", MarkerH = "marker_h", SignFill = "sign_fill", CustomBlock = "custom_block", PoleCount = "so_tru", FaceCount = "so_mat", Face = "mat", Condition = "tinh_trang", CheckState = "trang_thai_kt",
            Note = "ghi_chu", RoadSide = "phia_duong", Point = "pt", Photo = "anh", PhotoFile = "anh_file",
            RouteId = "route_id", ChainageM = "ly_trinh_m", ChainageKm = "ly_trinh_km", OffsetM = "offset_m",
            RouteSide = "phia_tuyen", KmState = "trang_thai_km", KmSource = "nguon_km",
            StationRouteRevision = "station_route_revision", StationStatus = "station_status", Segment = "doan", Package = "goi",
            SegMethod = "gan_doan_pp", SegCandidates = "doan_ung_vien", CreatedAt = "tao_luc", ModifiedAt = "sua_luc";

        /// <summary>Cac truong nguoi dung duoc sua tu palette (giong bht:ask-fields).</summary>
        public static readonly string[] Editable = { SignContent, SignLayout, SignGap, SignClearance, BridgeName, SignChainage, RoadName, MarkerKm, MarkerH, SignFill, CustomBlock, Group, Code, CodeType, Desc, PoleCount, FaceCount, Condition, CheckState, Note, RoadSide,
            RouteId, ChainageM, ChainageKm, OffsetM, RouteSide, KmState, KmSource, StationRouteRevision, StationStatus };
    }

    public static class PhotoFields
    {
        public const string Id = "photo_id", Name = "ten", Time = "thoi_gian", Lon = "lon", Lat = "lat", GpsValid = "gps_hop_le",
            RelPath = "duong_dan", Root = "goc", Source = "nguon", Address = "dia_chi", E = "e", N = "n", Crs = "crs",
            State = "trang_thai", Suggest = "de_xuat", Objects = "doi_tuong", Distance = "kc", RelinkedFile = "file_tt";
    }

    /// <summary>Nhom doi tuong (giong *bht-groups* trong Lisp). KHONG phai ma QCVN.</summary>
    public static class Groups
    {
        public static readonly string[][] All =
        {
            new[] { "1", "BIEN_BAO", "Biển báo" },
            new[] { "2", "COC_TIEU", "Cọc tiêu" },
            new[] { "3", "COT_KM", "Cột Km" },
            new[] { "4", "BANG_CHI_DAN", "Bảng chỉ dẫn" },
            new[] { "5", "BANG_QC", "Bảng quảng cáo" },
            new[] { "6", "DEN", "Đèn (hồ sơ cũ, chưa phân loại)" },
            new[] { "9", "DEN_CS", "Đèn chiếu sáng" },
            new[] { "10", "DEN_TH", "Đèn tín hiệu" },
            new[] { "7", "CONG_TRINH", "Công trình ven tuyến" },
            new[] { "8", "KHAC", "Khác" },
            new[] { "0", "CHUA_XAC_DINH", "Chưa xác định" }
        };

        /// <summary>bht:group-code: "2" hoac "COC_TIEU" -> "COC_TIEU"; khong khop -> null.</summary>
        public static string Code(string s)
        {
            string u = (s ?? "").Trim().ToUpperInvariant();
            string hit = null;
            foreach (var g in All) if (u == g[0] || u == g[1]) hit = g[1];
            return hit;
        }

        public static string Label(string code)
        {
            foreach (var g in All) if (g[1] == code) return g[2];
            return code;
        }

        /// <summary>
        /// Goi y nhom khi tao ho so (giong bht:suggest-group): lay phan loai goi y DA LUU
        /// trong XData cua diem dau tien khac CHUA_XAC_DINH. Tra ve ma nhom va can cu.
        /// </summary>
        public static string Suggest(IEnumerable<SurveyPoint> pts, out string basis)
        {
            basis = "không có mô tả khớp quy tắc phân loại -> Chưa xác định";
            foreach (var p in pts)
            {
                if (p != null && !string.IsNullOrEmpty(p.Class) && p.Class != "CHUA_XAC_DINH")
                {
                    basis = "mô tả gốc của điểm " + p.Name + " [" + p.Description + "] -> phân loại gợi ý " + p.Class + " (chỉ là gợi ý, cần xác nhận)";
                    return p.Class;
                }
            }
            return "CHUA_XAC_DINH";
        }
    }

    /// <summary>Thoi gian dang "YYYY-MM-DD HH:MM:SS" (giong bht:now).</summary>
    public static class BhtTime
    {
        public static string Format(DateTime t) { return t.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture); }
        public static string Now() { return Format(DateTime.Now); }
    }

    public static class LispFormat
    {
        /// <summary>Ban C# cua bht:fnum (dinh dang so thap phan khong phu thuoc DIMZIN/LUNITS).</summary>
        public static string Fnum(double x, int dec)
        {
            bool neg = x < 0.0; x = Math.Abs(x);
            double scale = Math.Pow(10.0, dec);
            long ip = (long)Math.Truncate(x);
            long fp = (long)Math.Truncate((x - ip) * scale + 0.5);
            if (fp >= (long)Math.Truncate(scale)) { ip = ip + 1; fp = 0; }
            string fs = dec > 0 ? "." + fp.ToString(CultureInfo.InvariantCulture).PadLeft(dec, '0') : "";
            if (neg && (ip > 0 || fp > 0)) return "-" + ip.ToString(CultureInfo.InvariantCulture) + fs;
            return ip.ToString(CultureInfo.InvariantCulture) + fs;
        }
    }

    public static class BhtVersion
    {
        public const string Version = "0.6.53";
        public const string AssemblyVersion = "0.6.53.0";
        public const string FileVersion = "0.6.53.0";
        public const string LispApiLevel = "1";
        public const string DictName = "BHT_V02";

        /// <summary>Ban Lisp co tuong thich API voi plugin khong (can ham bht:api-*, muc API &gt;= 1).</summary>
        public static bool LispCompatible(string lispVersion, string apiLevel)
        {
            int lvl;
            if (!int.TryParse(apiLevel ?? "", NumberStyles.Integer, CultureInfo.InvariantCulture, out lvl)) return false;
            if (lvl < 1) return false;
            // Palette va Lisp phai cung phien ban. AutoCAD khong the go DLL .NET
            // da nap trong mot phien lam viec, nen cho phep "moi hon" se che mat
            // tinh trang DLL cu dang chay cung Lisp moi.
            // So khop NGUYEN VAN (vd "0.4.6-fix3"): Compare() bo phan khong phai so nen
            // "0.4.6-fix3" se bi coi nhu "0.4.0" va khong phan biet duoc voi 0.4.6.
            return string.Equals((lispVersion ?? "").Trim(), Version, StringComparison.OrdinalIgnoreCase);
        }

        /// <summary>So sanh "a.b.c" theo so; phan khong phai so = 0.</summary>
        public static int Compare(string a, string b)
        {
            var pa = (a ?? "").Split('.'); var pb = (b ?? "").Split('.');
            int n = Math.Max(pa.Length, pb.Length);
            for (int i = 0; i < n; i++)
            {
                int x = 0, y = 0;
                if (i < pa.Length) int.TryParse(pa[i], out x);
                if (i < pb.Length) int.TryParse(pb[i], out y);
                if (x != y) return x < y ? -1 : 1;
            }
            return 0;
        }
    }
}
