using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using BHT.Core;

namespace BHT.CoreTests
{
    /// <summary>
    /// Bo chay kiem thu don vi toi gian (khong can NuGet): moi kiem thu in PASS/FAIL,
    /// ma thoat = so FAIL. Chay: BHT.CoreTests.exe [thu_muc_ket_qua]
    /// </summary>
    public static class Program
    {
        static int pass, fail;
        static readonly List<string> log = new List<string>();

        static void Check(string id, string name, bool ok, string detail)
        {
            if (ok) pass++; else fail++;
            string l = (ok ? "PASS " : "FAIL ") + id + " " + name + (string.IsNullOrEmpty(detail) ? "" : " | " + detail);
            log.Add(l); Console.WriteLine(l);
        }
        static void Check(string id, string name, bool ok) { Check(id, name, ok, null); }

        static void Safe(string id, string name, Action a)
        {
            try { a(); } catch (Exception ex) { Check(id, name, false, "ngoại lệ: " + ex.GetType().Name + " " + ex.Message); }
        }

        public static int Main(string[] args)
        {
            Console.OutputEncoding = System.Text.Encoding.UTF8;
            Safe("C01", "codec", Codec);
            Safe("C02", "record set/get", RecordOps);
            Safe("C03", "fnum", Fnum);
            Safe("C04", "ids", Ids);
            Safe("C05", "object create", CreateObj);
            Safe("C06", "overlap", Overlap);
            Safe("C07", "photo link", Links);
            Safe("C08", "photo paths", Paths);
            Safe("C09", "search", Search);
            Safe("C10", "nearby", Near);
            Safe("C11", "version", Versions);
            Safe("C12", "point xdata", PointX);
            Safe("C13", "lisp reply", Reply);
            Safe("C14", "groups", GroupsT);
            Safe("C15", "manual chainage", ChainageT);
            string summary = "TONG BHT.CoreTests: " + pass + " PASS, " + fail + " FAIL";
            log.Add(summary); Console.WriteLine(summary);
            if (args.Length > 0) File.WriteAllLines(Path.Combine(args[0], "coretests_result.txt"), log.ToArray(), new System.Text.UTF8Encoding(false));
            return fail;
        }

        static void Codec()
        {
            // Giong kiem thu Lisp "record mã hóa": gia tri co "=" giu nguyen, khoa lap giu thu tu
            var r = new BhtRecord().Add("a", "x=1").Add("pt", "P1").Add("pt", "P2");
            var enc = RecordCodec.Encode(r);
            Check("C01a", "mã hóa ngắn", string.Join("\u0001", enc) == "a=x=1\u0001pt=P1\u0001pt=P2");
            var dec = RecordCodec.Decode(enc);
            Check("C01b", "giải mã khứ hồi", dec.ToCanonical() == r.ToCanonical());
            string lng = new string('ă', 450);
            var e2 = RecordCodec.Encode(new BhtRecord().Add("mo_ta", lng).Add("z", ""));
            Check("C01c", "chia đoạn 200 ký tự (k= / k+=)", e2.Count == 4 && e2[0] == "mo_ta=" + new string('ă', 200)
                  && e2[1] == "mo_ta+=" + new string('ă', 200) && e2[2] == "mo_ta+=" + new string('ă', 50) && e2[3] == "z=", string.Join(" | ", e2.Select(x => x.Length.ToString()).ToArray()));
            Check("C01d", "giải mã đoạn dài", RecordCodec.Decode(e2).Get("mo_ta") == lng && RecordCodec.Decode(e2).Has("z"));
            Check("C01e", "chuỗi không có '=' bị bỏ qua", RecordCodec.Decode(new[] { "rac", "k=v" }).Count == 1);
            Check("C01f", "'+=' ghép vào cặp CUỐI (như Lisp)", RecordCodec.Decode(new[] { "a=1", "b=2", "a+=X" }).Get("b") == "2X");
            Check("C01g", "khóa '+' đơn không phải nối", RecordCodec.Decode(new[] { "a=1", "+=2" }).Count == 2);
            var exact = RecordCodec.Encode(new BhtRecord().Add("k", new string('x', 200)));
            Check("C01h", "đúng 200 ký tự = 1 đoạn", exact.Count == 1);
        }

        static void RecordOps()
        {
            var r = new BhtRecord().Add("a", "1").Add("b", "2").Add("a", "3");
            r.Set("a", "9");
            Check("C02a", "set thay cặp đầu, bỏ cặp trùng", r.ToCanonical() == "a=9\nb=2\n");
            r.Set("c", "x");
            Check("C02b", "set thêm cuối", r.ToCanonical() == "a=9\nb=2\nc=x\n");
            r.SetAll("pt", new[] { "P1", "P2" }).SetAll("b", new[] { "7" });
            Check("C02c", "set-all bỏ cũ thêm cuối", r.ToCanonical() == "a=9\nc=x\npt=P1\npt=P2\nb=7\n");
            Check("C02d", "get khóa thiếu = \"\"", r.Get("zz") == "" && r.GetAll("pt").Count == 2);
        }

        static void Fnum()
        {
            Check("C03a", "fnum giống bht:fnum", LispFormat.Fnum(0.5, 3) == "0.500" && LispFormat.Fnum(-2.25, 1) == "-2.3"
                  && LispFormat.Fnum(1187855.825, 3) == "1187855.825" && LispFormat.Fnum(-0.0001, 2) == "0.00" && LispFormat.Fnum(9.9996, 3) == "10.000");
        }

        static void Ids()
        {
            Check("C04a", "valid-id", ObjectLogic.ValidId("BOT19-R-000001") && !ObjectLogic.ValidId("a b") && !ObjectLogic.ValidId("") && !ObjectLogic.ValidId("obj-1") && !ObjectLogic.ValidId(new string('A', 61)));
            Check("C04b", "next id không dùng lại số đã xóa (obj_seq)", ObjectLogic.NextId(new[] { "OBJ-000001" }, "5") == "OBJ-000006");
            Check("C04c", "next id theo khóa lớn nhất", ObjectLogic.NextId(new[] { "OBJ-000001", "OBJ-000009", "CT-1" }, "0") == "OBJ-000010");
            Check("C04d", "next id rỗng", ObjectLogic.NextId(new string[0], "") == "OBJ-000001");
            Check("C04e", "seq", ObjectLogic.SeqNum("OBJ-000123") == 123 && ObjectLogic.SeqNum("OBJ-12") == -1 && ObjectLogic.SeqNum("XBJ-000001") == -1);
        }

        static Dictionary<string, BhtRecord> Objs()
        {
            var d = new Dictionary<string, BhtRecord>(StringComparer.OrdinalIgnoreCase);
            d["OBJ-000001"] = new BhtRecord().Add("object_id", "OBJ-000001").Add("pt", "D-R-000001").Add("pt", "D-R-000002");
            d["OBJ-000002"] = new BhtRecord().Add("object_id", "OBJ-000002").Add("pt", "D-R-000003");
            return d;
        }

        static void CreateObj()
        {
            var pts = new HashSet<string>(new[] { "D-R-000001", "D-R-000002", "D-R-000003", "D-R-000004" });
            var f = new BhtRecord().Add("nhom", "2").Add("so_tru", "3").Add("tinh_trang", "tốt").Add("mat", "M1");
            BhtRecord rec;
            string why = ObjectLogic.BuildNew("obj-000003", f, new List<string> { "d-r-000004" }, false, pts, Objs(), "2026-09-27 10:00:00", out rec);
            Check("C05a", "tạo hợp lệ", why == null && rec != null, why);
            string exp = "object_id=OBJ-000003\nnhom=COC_TIEU\nma_hieu=\nloai_ma=CHUA_XAC_DINH\nmo_ta=\nso_tru=3\nso_mat=\ntinh_trang=tốt\n" +
                         "trang_thai_kt=CHUA_KIEM_TRA\nghi_chu=\nphia_duong=CHUA_XAC_DINH\ndoan=\ngoi=\ngan_doan_pp=CHUA_PHAN_DOAN\ntrang_thai_km=CHUA_TINH\n" +
                         "tao_luc=2026-09-27 10:00:00\nmat=M1\npt=D-R-000004\nsua_luc=2026-09-27 10:00:00\n";
            Check("C05b", "thứ tự trường giống bht:obj-create + obj-write", rec != null && rec.ToCanonical() == exp);
            why = ObjectLogic.BuildNew("OBJ-000009", f, new List<string> { "D-R-000001" }, false, pts, Objs(), "t", out rec);
            Check("C05c", "mặc định TỪ CHỐI điểm đã thuộc hồ sơ khác", why != null && why.StartsWith("điểm đã thuộc đối tượng khác"), why);
            why = ObjectLogic.BuildNew("OBJ-000009", f, new List<string> { "D-R-000001" }, true, pts, Objs(), "t", out rec);
            Check("C05d", "dùng chung chỉ khi xác nhận rõ", why == null);
            why = ObjectLogic.BuildNew("OBJ-000001", f, new List<string> { "D-R-000004" }, false, pts, Objs(), "t", out rec);
            Check("C05e", "ID đã tồn tại", why == "ID OBJ-000001 đã tồn tại", why);
            why = ObjectLogic.BuildNew("OBJ-000009", f, new List<string> { "X1", "X2" }, false, pts, Objs(), "t", out rec);
            Check("C05f", "điểm không tồn tại (thứ tự như Lisp)", why == "không tìm thấy điểm: X2, X1", why);
            why = ObjectLogic.BuildNew("A B", f, new List<string> { "D-R-000004" }, false, pts, Objs(), "t", out rec);
            Check("C05g", "ID không hợp lệ", why == "ID không hợp lệ (A-Z 0-9 _ - .)");
            var ed = ObjectLogic.ApplyEdit(Objs()["OBJ-000001"].Clone().Add("mat", "A").Add("mat", "B"), new BhtRecord().Add("so_tru", "2").Add("mat", "C"), "t2");
            Check("C05h", "sửa: mặt thay toàn bộ, sua_luc", ed.GetAll("mat").SequenceEqual(new[] { "C" }) && ed.Get("so_tru") == "2" && ed.Get("sua_luc") == "t2");
            var ap = ObjectLogic.AddPoints(Objs()["OBJ-000002"], new[] { "d-r-000003", "D-R-000004" }, "t3");
            Check("C05i", "thêm điểm không trùng", ap.GetAll("pt").SequenceEqual(new[] { "D-R-000003", "D-R-000004" }));
            var rp = ObjectLogic.RemovePoints(Objs()["OBJ-000001"], new[] { "d-r-000001" }, "t4");
            Check("C05j", "gỡ điểm", rp.GetAll("pt").SequenceEqual(new[] { "D-R-000002" }));
        }

        static void Overlap()
        {
            List<string> hits, same;
            ObjectLogic.Overlap(new List<string> { "d-r-000002", "D-R-000001" }, Objs(), out hits, out same);
            Check("C06a", "phát hiện bộ điểm trùng khớp hồ sơ", hits.SequenceEqual(new[] { "OBJ-000001" }) && same.SequenceEqual(new[] { "OBJ-000001" }));
            ObjectLogic.Overlap(new List<string> { "D-R-000001", "D-R-000003" }, Objs(), out hits, out same);
            Check("C06b", "điểm chung 2 hồ sơ, không trùng khớp", hits.Count == 2 && same.Count == 0);
            var om = ObjectLogic.OwnerMap(Objs());
            Check("C06c", "owner map", om["D-R-000001"][0] == "OBJ-000001" && !om.ContainsKey("D-R-000004"));
        }

        static void Links()
        {
            var o = new BhtRecord().Add("object_id", "OBJ-000001").Add("anh", "P2|DA_XAC_NHAN|THU_CONG");
            var p = new BhtRecord().Add("photo_id", "P1").Add("trang_thai", "DE_XUAT");
            BhtRecord no, np;
            ObjectLogic.LinkPhoto("p1", "obj-000001", "THU_CONG", o, p, "t", out no, out np);
            Check("C07a", "gắn ảnh 2 chiều", no.GetAll("anh").SequenceEqual(new[] { "P2|DA_XAC_NHAN|THU_CONG", "P1|DA_XAC_NHAN|THU_CONG" })
                  && np.GetAll("doi_tuong").SequenceEqual(new[] { "OBJ-000001" }) && np.Get("trang_thai") == "DA_XAC_NHAN");
            ObjectLogic.LinkPhoto("P1", "OBJ-000001", "THU_CONG", no, np, "t", out no, out np);
            Check("C07b", "gắn lại không nhân đôi", no.GetAll("anh").Count == 2 && np.GetAll("doi_tuong").Count == 1);
            ObjectLogic.UnlinkPhoto("P1", "OBJ-000001", no, np, "t", out no, out np);
            Check("C07c", "bỏ gắn -> CHUA_GHEP", no.GetAll("anh").Count == 1 && np.GetAll("doi_tuong").Count == 0 && np.Get("trang_thai") == "CHUA_GHEP");
        }

        static void Paths()
        {
            var rec = new BhtRecord().Add("duong_dan", "photos/origin_photo_0.jpg").Add("goc", "C:\\BHT_ANH");
            var c = PhotoLogic.Candidates(rec, "", "");
            Check("C08a", "đường dẫn tương đối (giống BHTTEST)", c.Count == 1 && c[0] == "C:\\BHT_ANH\\photos\\origin_photo_0.jpg");
            rec.Add("file_tt", "D:\\moi\\a.jpg");
            c = PhotoLogic.Candidates(rec, "E:\\anh\\", "F:\\dwg\\");
            Check("C08b", "thứ tự ứng viên", c.SequenceEqual(new[] { "D:\\moi\\a.jpg", "C:\\BHT_ANH\\photos\\origin_photo_0.jpg", "E:\\anh\\photos\\origin_photo_0.jpg",
                   "E:\\anh\\origin_photo_0.jpg", "E:\\anh\\photos\\origin_photo_0.jpg", "F:\\dwg\\photos\\origin_photo_0.jpg" }), string.Join(" ; ", c));
            Check("C08c", "resolve chọn ứng viên đầu tiên tồn tại", PhotoLogic.Resolve(rec, "E:\\anh", "", p => p.StartsWith("E:")) == "E:\\anh\\photos\\origin_photo_0.jpg");
            Check("C08d", "không có đường dẫn -> không ứng viên", PhotoLogic.Candidates(new BhtRecord(), "E:\\x", "F:\\").Count == 0);
            double e, n;
            Check("C08e", "GPS 0,0 / không hợp lệ: không có vị trí chụp", !PhotoLogic.ShotEN(new BhtRecord().Add("gps_hop_le", "0").Add("e", "1").Add("n", "2"), out e, out n));
        }

        static void Search()
        {
            var pts = new List<SurveyPoint>
            {
                new SurveyPoint { Id = "D-R-000001", Name = "Đ12", Description = "coctiu.h5-48", Class = "COC_TIEU" },
                new SurveyPoint { Id = "D-R-000002", Name = "B7", Description = "biển cấm 207a", Class = "BIEN_BAO" },
                new SurveyPoint { Id = "D-R-000003", Name = "K1", Description = "cockm45", Class = "COT_KM" }
            };
            Check("C09a", "tìm không dấu", TextSearch.Filter(pts, "bien cam", null).Count == 1);
            Check("C09b", "tìm đ -> d", TextSearch.Filter(pts, "d12", null).Count == 1);
            Check("C09c", "lọc theo loại", TextSearch.Filter(pts, "", "COT_KM").Single().Id == "D-R-000003");
            Check("C09d", "nhiều từ AND", TextSearch.Filter(pts, "coctiu 48", null).Count == 1 && TextSearch.Filter(pts, "coctiu 207", null).Count == 0);
            Check("C09e", "rỗng = tất cả", TextSearch.Filter(pts, " ", null).Count == 3);
        }

        static void Near()
        {
            var pts = new List<SurveyPoint> { new SurveyPoint { Id = "A", X = 3, Y = 4 }, new SurveyPoint { Id = "B", X = 1, Y = 0 }, new SurveyPoint { Id = "C", X = 30, Y = 0 } };
            var l = Geo.PointsNear(0, 0, pts, 10, 0);
            Check("C10a", "điểm gần sắp theo khoảng cách", l.Count == 2 && l[0].Item.Id == "B" && Math.Abs(l[1].Distance - 5.0) < 1e-12);
            var ph = new Dictionary<string, BhtRecord>
            {
                { "P1", new BhtRecord().Add("gps_hop_le", "1").Add("e", "10.0").Add("n", "0.0") },
                { "P2", new BhtRecord().Add("gps_hop_le", "0").Add("e", "0").Add("n", "0") },
                { "P3", new BhtRecord().Add("gps_hop_le", "1").Add("e", "2.0").Add("n", "0.0") }
            };
            var pn = Geo.PhotosNear(0, 0, ph, 10);
            Check("C10b", "ảnh gần: bỏ GPS không hợp lệ, gần trước", pn.Count == 2 && pn[0].Item == "P3" && pn[1].Item == "P1");
        }

        static void Versions()
        {
            Check("C11a", "hằng phiên bản", BhtVersion.Version == "0.4.2" && BhtVersion.AssemblyVersion.StartsWith("0.4.2.") && BhtVersion.FileVersion.StartsWith("0.4.2."));
            Check("C11b", "tương thích Lisp", BhtVersion.LispCompatible("0.4.2", "1") && !BhtVersion.LispCompatible("0.4.0", "1") && !BhtVersion.LispCompatible("0.4.2", "") && BhtVersion.LispCompatible("0.10.0", "2"));
            var asm = typeof(BhtRecord).Assembly.GetName().Version.ToString();
            Check("C11c", "AssemblyVersion BHT.Core = 0.4.2.x", asm.StartsWith("0.4.2."), asm);
        }

        static void PointX()
        {
            var x = new List<string> { "BOT19-R-000001", "BOT19", "1", "Đ1", "1187855.825", "575123.456", "12.300", "COC_TIEU", "survey.csv", "2026-09-20 08:00:00", "mô tả phần 1 ", "phần 2" };
            var p = SurveyPoint.FromXData(x, 575123.456, 1187855.825, 12.3);
            Check("C12a", "đọc XData BHT_PT (nối mô tả, giữ chuỗi gốc)", p != null && p.Description == "mô tả phần 1 phần 2" && p.NRaw == "1187855.825" && p.X == 575123.456 && p.Y == 1187855.825);
            Check("C12b", "XData < 10 phần tử bị bỏ", SurveyPoint.FromXData(x.Take(9).ToList(), 0, 0, 0) == null);
        }

        static void Reply()
        {
            var r = LispReply.FromStrings(new[] { "OK", "created=1", "updated=0" });
            Check("C13a", "đọc trả lời Lisp OK", r.Ok && r.AsPairs()["created"] == "1");
            var e = LispReply.FromStrings(new[] { "LOI", "không có ảnh X" });
            Check("C13b", "đọc trả lời Lisp LOI", !e.Ok && e.Error == "không có ảnh X");
            Check("C13c", "không trả lời = lỗi (không coi là thành công)", !LispReply.FromStrings(new string[0]).Ok);
        }

        static void GroupsT()
        {
            string basis;
            var g = Groups.Suggest(new[] { new SurveyPoint { Name = "A", Class = "CHUA_XAC_DINH" }, new SurveyPoint { Name = "B", Class = "COC_TIEU", Description = "coctiu.h5" } }, out basis);
            Check("C14a", "gợi ý nhóm từ phân loại đã lưu + căn cứ", g == "COC_TIEU" && basis.Contains("coctiu.h5"));
            Check("C14b", "group code", Groups.Code("2") == "COC_TIEU" && Groups.Code("coc_tieu") == "COC_TIEU" && Groups.Code("x") == null);
        }

        static void ChainageT()
        {
            double m;
            Check("C15a", "đọc Km và mét", Chainage.TryParse("Km39+050.5", out m) && Math.Abs(m - 39050.5) < 1e-9
                && Chainage.TryParse("39+050,5", out m) && Math.Abs(m - 39050.5) < 1e-9
                && Chainage.TryParse("39050.5", out m) && Math.Abs(m - 39050.5) < 1e-9);
            Check("C15b", "từ chối lý trình sai", !Chainage.TryParse("", out m) && !Chainage.TryParse("1+1000", out m)
                && !Chainage.TryParse("KmA+010", out m) && !Chainage.TryParse("-1", out m));
            Check("C15c", "định dạng giống Lisp", Chainage.Format(39050.505) == "Km39+050.51"
                && Chainage.Format(999.999) == "Km1+000.00" && Chainage.Format(-1) == "");
        }
    }
}
