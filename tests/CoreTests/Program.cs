using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
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
        static void TcvnT()
        {
            Check("TC1", "mixed Vietnamese", Tcvn3.Encode("Cọc tiêu") == "C\u00e4c ti\u00aau");
            Check("TC2", "survey description", Tcvn3.Encode("Đường giới hạn 80") == "\u00a7\u00ad\u00eang gi\u00edi h\u00b9n 80");
            Check("TC3", "NFD equivalent", Tcvn3.Encode("Cọc tiêu".Normalize(System.Text.NormalizationForm.FormD)) == Tcvn3.Encode("Cọc tiêu"));
            Check("TC4", "ASCII unchanged", Tcvn3.Encode("P.127-80 Km1+200.00") == "P.127-80 Km1+200.00");
            Check("TC5", "all Vietnamese accents", Tcvn3.Encode("àáảãạ ăâđêôơư") == "\u00b5\u00b8\u00b6\u00b7\u00b9 \u00a8\u00a9\u00ae\u00aa\u00ab\u00ac\u00ad");
            Check("TC6", "null safe", Tcvn3.Encode(null) == "");
            var record = new BhtRecord().Add(ObjFields.Desc, "Cọc tiêu");
            Tcvn3.Encode(record.Get(ObjFields.Desc));
            Check("TC7", "records remain Unicode", record.Get(ObjFields.Desc) == "Cọc tiêu");
        }

        static void SignVariantsT()
        {
            Check("SV1", "explicit speed wins", SignPresentation.ResolveCode("P.127-60", "gioihan80") == "P.127-60");
            Check("SV2", "survey speed", SignPresentation.ResolveCode("P.127", "bbtron1m25 gioihan80") == "P.127-80");
            Check("SV3", "Vietnamese accents", SignPresentation.ResolveCode("P.127", "Giới hạn tốc độ: 100 km/h") == "P.127-100");
            Check("SV4", "do not parse dimensions", !SignPresentation.Speed("P.127", "bbtron1m25").HasValue);
            Check("SV5", "other sign", SignPresentation.ResolveCode("R.415", "gioihan80") == "R.415");
            Check("SV6", "no supplied speed", SignPresentation.ResolveCode("P.127", "") == "P.127");
            Check("SV7", "reject overlong number", !SignPresentation.Speed("P.127", "gioihan8000").HasValue);
            Check("SV10", "reject invalid explicit speed instead of defaulting", SignPresentation.ValidationError("P.127-800") != "" && SignPresentation.ValidationError("P.127-abc") != "" && SignPresentation.ValidationError("P.127-") != "");
            Check("SV11", "accept speed boundaries and surrounding spaces", SignPresentation.ValidationError(" P.127-5 ") == "" && SignPresentation.Speed(" P.127-130 ", "").Value == 130);
            Check("SV12", "explicit invalid speed cannot use description", SignPresentation.Speed("P.127-800", "gioihan80") == null && SignPresentation.ValidationError("P.127-0") != "");
            Check("SV13", "legacy separators resolve without default speed", SignPresentation.ResolveCode("P.127 - 20", "") == "P.127-20" && SignPresentation.ResolveCode("P.127/40", "") == "P.127-40" && SignPresentation.ResolveCode("P12780", "") == "P.127-80");
            Check("MV6", "reject unsupported and duplicate metre suffix", SignPresentation.ValidationError("R.415@5") != "" && SignPresentation.ValidationError("S.502@5@6") != "" && SignPresentation.ValidationError("S.509a@4,5") == "");
            Check("MV8", "W239b supports real clearance", SignPresentation.MetreValue("W.239b@5,2") == "5.2" && SignPresentation.ValidationError("W.239a@5.2") != "");
            BhtRecord presentationRecord;
            var presentationFields = new BhtRecord().Add(ObjFields.Group, "BIEN_BAO").Add(ObjFields.BridgeName, "CẦU YÊN CHÂU").Add(ObjFields.SignChainage, "Km252+831").Add(ObjFields.RoadName, "QL.6").Add(ObjFields.MarkerKm, "39").Add(ObjFields.MarkerH, "9");
            string presentationError = ObjectLogic.BuildNew("OBJ-PRESENTATION", presentationFields, new[] { "P1" }, false, new HashSet<string> { "P1" }, new Dictionary<string,BhtRecord>(), "now", out presentationRecord);
            Check("PRES1", "new object retains bridge and marker parameters", presentationError == null && presentationRecord.Get(ObjFields.BridgeName) == "CẦU YÊN CHÂU" && presentationRecord.Get(ObjFields.RoadName) == "QL.6" && presentationRecord.Get(ObjFields.MarkerKm) == "39" && presentationRecord.Get(ObjFields.MarkerH) == "9");
            presentationRecord.Add(ObjFields.Photo, "PHOTO1");
            var presentationEdit = ObjectLogic.ApplyEdit(presentationRecord, new BhtRecord().Add(ObjFields.MarkerKm, "40").Add(ObjFields.RoadName, "ĐT.1"), "later");
            Check("PRES2", "edit preserves Unicode and linked photos", presentationEdit.Get(ObjFields.MarkerKm) == "40" && presentationEdit.Get(ObjFields.RoadName) == "ĐT.1" && presentationEdit.Get(ObjFields.BridgeName) == "CẦU YÊN CHÂU" && presentationEdit.Get(ObjFields.Photo) == "PHOTO1");
            Check("PRES3", "marker number can be disabled without losing station", ObjectLogic.ApplyEdit(presentationEdit, new BhtRecord().Add(ObjFields.MarkerKm, ""), "later").Get(ObjFields.MarkerKm) == "" && presentationEdit.Get(ObjFields.SignChainage) == "Km252+831");
            double markerMetres;
            Check("MK1", "Km46 H1 derives 46100", MarkerStation.TryMetres("COC_TIEU", "46", "1", out markerMetres) && markerMetres == 46100);
            Check("MK2", "milestone ignores unused H", MarkerStation.TryMetres("COT_KM", "39", "", out markerMetres) && markerMetres == 39000);
            Check("MK3", "reject fractional negative or out-of-range markers", !MarkerStation.TryMetres("COC_TIEU", "46", "10", out markerMetres) && !MarkerStation.TryMetres("COC_TIEU", "46.1", "1", out markerMetres) && !MarkerStation.TryMetres("COT_KM", "-1", "", out markerMetres));
            var marker = new BhtRecord().Add(ObjFields.Group, "COC_TIEU").Add(ObjFields.MarkerKm, "46").Add(ObjFields.MarkerH, "1").Add(ObjFields.RouteId, "ROUTE1").Add(ObjFields.Point, "P1").Add(ObjFields.Photo, "PHOTO1");
            marker = ObjectLogic.ApplyEdit(marker, new BhtRecord().Add(ObjFields.Note, "unchanged links"), "now");
            Check("MK4", "save derives station and preserves route RTK photo links", marker.Get(ObjFields.ChainageKm) == "Km46+100.00" && marker.Get(ObjFields.KmSource) == MarkerStation.Source && marker.Get(ObjFields.RouteId) == "ROUTE1" && marker.Get(ObjFields.Point) == "P1" && marker.Get(ObjFields.Photo) == "PHOTO1");
            var moved = ObjectLogic.ApplyEdit(marker, new BhtRecord().Add(ObjFields.MarkerH, "9"), "now");
            Check("MK5", "editing H updates station", moved.Get(ObjFields.ChainageM) == "46900.000");
            Check("MK6", "disabling marker clears only its derived station", ObjectLogic.ApplyEdit(moved, new BhtRecord().Add(ObjFields.MarkerKm, ""), "now").Get(ObjFields.ChainageKm) == "");
            var independent = new BhtRecord().Add(ObjFields.Group, "COC_TIEU").Add(ObjFields.ChainageKm, "Km2+345.00").Add(ObjFields.KmSource, "Nhập thủ công từ Palette");
            Check("MK7", "unrelated manual station preserved", ObjectLogic.ApplyEdit(independent, new BhtRecord().Add(ObjFields.MarkerKm, ""), "now").Get(ObjFields.ChainageKm) == "Km2+345.00");
            BhtRecord newMarker;
            var markerError = ObjectLogic.BuildNew("OBJ-MARKER", new BhtRecord().Add(ObjFields.Group, "COC_TIEU").Add(ObjFields.MarkerKm, "46").Add(ObjFields.MarkerH, "1"), new[] { "P1" }, false, new HashSet<string> { "P1" }, new Dictionary<string,BhtRecord>(), "now", out newMarker);
            Check("MK8", "new marker derives station without manual entry", markerError == null && newMarker.Get(ObjFields.ChainageKm) == "Km46+100.00");
            Check("BR1", "bridge bottom line matches original sign", SignPresentation.BridgeLine("Km38+723.00", "ĐT.830") == "KM38+723-ĐT.830");
            Check("BR2", "partial bridge inputs remain usable", SignPresentation.BridgeLine("", "QL.6") == "QL.6" && SignPresentation.BridgeLine("Km0+008.47", "") == "KM0+008.47");
            Check("BR3", "fractional metres preserved", SignPresentation.BridgeLine("12.125", "QL.1") == "KM0+012.125-QL.1");
            Check("MV7", "metres never silently round to zero or another value", SignPresentation.MetreValue("S.502@0.0001") == "" && SignPresentation.MetreValue("S.509a@4.5678") == "" && SignPresentation.MetreValue("S.509a@0.001") == "0.001");
            Check("MV1", "metres decimal comma", SignPresentation.MetreValue("S.509a@4,5") == "4.5");
            Check("MV2", "whole distance text", SignPresentation.ReplaceMetres("S.502@150", "200m") == "150 m");
            Check("MV3", "dimension number", SignPresentation.ReplaceMetres("P.117@3.8", "4.2") == "3.8");
            Check("MV4", "preserve words and identifiers", SignPresentation.ReplaceMetres("S.509a@4.5", "CHIỀU CAO") == "CHIỀU CAO" && SignPresentation.ReplaceMetres("S.509a@4.5", "S.509a") == "S.509a");
            Check("MV5", "reject nonpositive and malformed", SignPresentation.MetreValue("S.502@0") == "" && SignPresentation.MetreValue("S.502@-5") == "" && SignPresentation.MetreValue("S.502@abc") == "");
            BhtRecord created;
            string error = ObjectLogic.BuildNew("OBJ-009999", new BhtRecord().Add(ObjFields.Group, "BIEN_BAO").Add(ObjFields.CustomBlock, "BIEN_RIENG"),
                new List<string> { "P1" }, false, new HashSet<string> { "P1" }, new Dictionary<string, BhtRecord>(), "now", out created);
            Check("SV9", "new object keeps custom block", error == null && created.Get(ObjFields.CustomBlock) == "BIEN_RIENG");
            var old = new BhtRecord().Add(ObjFields.CustomBlock, "BIEN_RIENG").Add(ObjFields.Photo, "PHOTO1");
            var edited = ObjectLogic.ApplyEdit(old, new BhtRecord().Add(ObjFields.CustomBlock, ""), "now");
            Check("SV8", "clear custom without losing photo", edited.Get(ObjFields.CustomBlock) == "" && edited.Get(ObjFields.Photo) == "PHOTO1");
        }

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
            Safe("C16", "xlsx sign report", SignReportT);
            Safe("C17", "sign search", SignSearchT);
            Safe("C18", "duplicate check", DuplicateT);
            Safe("C19", "condition list", ConditionT);
            Safe("C20", "fonts / text style", FontT);
            Safe("C21", "Route Model V5 A-O", RouteModelT);
            Safe("C22", "sign variants", SignVariantsT);
            Safe("C23", "TCVN3 display", TcvnT);
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
            int dispatchCallbacks = 0;
            var gate = new CommandCompletionGate(() => dispatchCallbacks++);
            Check("DSP1", "chưa gọi thao tác nối tiếp khi EXECUTEFUNCTION chạy", !gate.TryFinish("EXECUTEFUNCTION") && dispatchCallbacks == 0);
            Check("DSP2", "tiếp tục chờ nếu lệnh CAD khác đang chạy", !gate.TryFinish("LINE") && dispatchCallbacks == 0);
            Check("DSP3", "kết thúc đúng một lần khi CAD rảnh", gate.TryFinish("") && gate.TryFinish("") && dispatchCallbacks == 1);
            BhtRecord fillRec;
            string fillError = ObjectLogic.BuildNew("OBJ-009998", new BhtRecord().Add(ObjFields.Group, "BIEN_BAO").Add("kh_label_h", "0.25").Add(ObjFields.SignFill, "0"), new List<string> { "D-R-000004" }, false, pts, Objs(), "t", out fillRec);
            Check("FILL1", "tạo hồ sơ lưu lựa chọn không tô màu", fillError == null && fillRec.Get(ObjFields.SignFill) == "0" && fillRec.Get("kh_label_h") == "0.25");
            fillRec = ObjectLogic.ApplyEdit(fillRec, new BhtRecord().Add(ObjFields.SignFill, "1"), "t");
            Check("FILL2", "sửa hồ sơ bật lại tô màu", fillRec.Get(ObjFields.SignFill) == "1");
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
            Check("C11a", "hằng phiên bản", BhtVersion.Version == "0.6.11" && BhtVersion.AssemblyVersion == BhtVersion.Version + ".0" && BhtVersion.FileVersion == BhtVersion.AssemblyVersion);
            Check("C11b", "Lisp phải cùng phiên bản", BhtVersion.LispCompatible(BhtVersion.Version, "1") && BhtVersion.LispCompatible(" " + BhtVersion.Version + " ", "1")
                && !BhtVersion.LispCompatible("5.0", "1") && !BhtVersion.LispCompatible("0.4.6-fix3", "1") && !BhtVersion.LispCompatible(BhtVersion.Version, "") && !BhtVersion.LispCompatible(BhtVersion.Version, "0"));
            var asm = typeof(BhtRecord).Assembly.GetName().Version.ToString();
            Check("C11c", "AssemblyVersion khớp BhtVersion", asm == BhtVersion.AssemblyVersion, asm);
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
            Check("C13d", "lỗi Lisp rỗng có hướng dẫn", !string.IsNullOrWhiteSpace(LispReply.FromStrings(new[] { "LOI", "" }).Error));
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

        // ================================================================ 5.0
        static void SignSearchT()
        {
            Check("C17a", "bỏ dấu cả đ/Đ, chữ thường", TextSearch.Fold("Đi CHẬM") == "di cham" && TextSearch.Fold("đường Đèo") == "duong deo");
            var items = new List<SignItem>
            {
                new SignItem("W.245a", "Đi chậm"), new SignItem("W.201a", "Chỗ ngoặt nguy hiểm vòng bên trái"),
                new SignItem("P.127", "Tốc độ tối đa cho phép"), new SignItem("W.245b", "Đi chậm"),
                new SignItem("R.E,9a", "Cấm đỗ xe trong khu vực"), new SignItem("Biển số E,9a", ""),
                new SignItem("I.434a", "Bến xe buýt"), new SignItem("Biển số F,9", "")
            };
            var a = SignSearch.Filter(items, "di cham", 0).Select(x => x.Code).ToList();
            var b = SignSearch.Filter(items, "ĐI CHẬM", 0).Select(x => x.Code).ToList();
            Check("C17b", "'di cham' = 'ĐI CHẬM' (không dấu, không phân biệt hoa) khớp W.245a/W.245b",
                a.SequenceEqual(new[] { "W.245a", "W.245b" }) && b.SequenceEqual(a), string.Join(",", a.ToArray()));
            var c = SignSearch.Filter(items, "w245a", 0).Select(x => x.Code).ToList();
            var d = SignSearch.Filter(items, "245", 0).Select(x => x.Code).ToList();
            Check("C17c", "mã bỏ dấu chấm 'w245a' khớp đúng; '245' khớp chuỗi con mã", c.Count >= 1 && c[0] == "W.245a" && d.Contains("W.245a") && d.Contains("W.245b") && !d.Contains("P.127"),
                string.Join(",", c.ToArray()) + " / " + string.Join(",", d.ToArray()));
            var e = SignSearch.Filter(items, "toc do", 0).Select(x => x.Code).ToList();
            var f = SignSearch.Filter(items, "xe buyt", 0).Select(x => x.Code).ToList();
            var g = SignSearch.Filter(items, "cham nguy", 0);
            Check("C17d", "khớp theo tên nhiều từ, mọi từ phải có", e.SequenceEqual(new[] { "P.127" }) && f.SequenceEqual(new[] { "I.434a" }) && g.Count == 0);
            Check("C17e", "truy vấn rỗng = tất cả, giữ thứ tự; giới hạn max", SignSearch.Filter(items, "", 0).Count == items.Count && SignSearch.Filter(items, " ", 3).Count == 3);
            Check("C17f", "mã khớp chính xác xếp trước khớp tên", SignSearch.Score("P.127", "P.127", "x") == 0 && SignSearch.Score("toc", "P.127", "Tốc độ") > 0 && SignSearch.Score("zzz", "P.127", "Tốc độ") < 0);
            // bo sung ten theo ma cung thu vien (khong tu dat ten)
            var copy = items.Select(x => new SignItem(x.Code, x.Name)).ToList();
            Dictionary<SignItem, string> aliasOf;
            int n = SignSearch.FillMissingNames(copy, out aliasOf);
            var e9 = copy.First(x => x.Code == "Biển số E,9a"); var f9 = copy.First(x => x.Code == "Biển số F,9");
            Check("C17g", "tên thiếu lấy từ mã cùng thư viện (Biển số E,9a <- R.E,9a); không có nguồn -> để trống",
                n == 1 && e9.Name == "Cấm đỗ xe trong khu vực" && aliasOf[e9] == "R.E,9a" && f9.Name == "", n + " " + e9.Name);
            Check("C17h", "AliasKey", SignSearch.AliasKey("Biển số E,9a") == "E,9A" && SignSearch.AliasKey("R.E,9a") == "E,9A" && SignSearch.AliasKey("I.435") == "435" && SignSearch.AliasKey("Biển số 435") == "435");
            Check("C17i", "tìm 'cam do' khớp tên đã bổ sung", SignSearch.Filter(copy, "cam do xe", 0).Select(x => x.Code).Contains("Biển số E,9a"));
            var rank = SignSearch.Filter(new List<SignItem> { new SignItem("R.E,10a", "Hết cấm đỗ xe trong khu vực"), new SignItem("R.E,9a", "Cấm đỗ xe trong khu vực") }, "cam do xe trong khu vuc", 0);
            Check("C17n", "tên trùng khớp hoàn toàn xếp trước tên chỉ chứa cụm từ", rank.Count == 2 && rank[0].Code == "R.E,9a", rank.Count > 0 ? rank[0].Code : "");
            // nhieu ma (Ma cac mat) + so mat tu dong
            Check("C17j", "tách Mã các mặt theo ';' (giữ ',' của mã E,9a)", SignSearch.SplitCodes("W.245a; E,9a ;; S.509a").SequenceEqual(new[] { "W.245a", "E,9a", "S.509a" }));
            string head;
            Check("C17k", "từ đang gõ sau ';' và thay bằng mã chọn", SignSearch.LastToken("W.245a; di ch", out head) == "di ch" && head == "W.245a;"
                && SignSearch.ReplaceLastToken("W.245a; di ch", "W.245b") == "W.245a; W.245b; " && SignSearch.ReplaceLastToken("", "P.127") == "P.127; ");
            Check("C17l", "Số mặt tự động = số mã (ô trống / đang là giá trị tự động); nhập tay thì giữ",
                SignSearch.AutoFaceCount("", null, "W.245a; S.509a") == "2" && SignSearch.AutoFaceCount("2", "2", "W.245a; S.509a; P.127") == "3"
                && SignSearch.AutoFaceCount("5", "2", "W.245a") == "5" && SignSearch.AutoFaceCount("", null, "") == "");
            Check("C17m", "Cọc tiêu / Cột Km không có mã biển", !GroupRules.HasSignCode("COC_TIEU") && !GroupRules.HasSignCode("3") && GroupRules.HasSignCode("BIEN_BAO") && GroupRules.HasSignCode("CHUA_XAC_DINH"));
        }

        static SurveyPoint Pt(string id, double x, double y) { return new SurveyPoint { Id = id, Name = id, X = x, Y = y }; }

        static void DuplicateT()
        {
            var idx = new Dictionary<string, SurveyPoint>(StringComparer.OrdinalIgnoreCase)
            {
                { "P1", Pt("P1", 100, 100) }, { "P2", Pt("P2", 100.3, 100) }, { "P3", Pt("P3", 101, 100) },
                { "P4", Pt("P4", 200, 200) }, { "P5", Pt("P5", 100.2, 100.1) }
            };
            var objs = new Dictionary<string, BhtRecord>(StringComparer.OrdinalIgnoreCase)
            {
                { "OBJ-000001", new BhtRecord().Add("nhom", "COC_TIEU").Add("pt", "P1") },
                { "OBJ-000002", new BhtRecord().Add("nhom", "BIEN_BAO").Add("pt", "P5") },
                { "OBJ-000003", new BhtRecord().Add("nhom", "COT_KM").Add("pt", "P4").Add("ly_trinh_km", "Km12+345.00") },
                { "OBJ-000004", new BhtRecord().Add("nhom", "COC_TIEU").Add("pt", "P3") }
            };
            double before1 = idx["P1"].X, before2 = idx["P2"].Y;
            var h1 = DuplicateCheck.Find("", "COC_TIEU", new[] { "P2" }, "", objs, idx, 0.5);
            Check("C18a", "cọc tiêu cách 0.30 m cọc tiêu khác -> trùng (không so với biển báo)", h1.Count == 1 && h1[0].Id == "OBJ-000001" && h1[0].Reason.Contains("0.30"),
                string.Join(" | ", h1.Select(x => x.ToString()).ToArray()));
            var h2 = DuplicateCheck.Find("", "COC_TIEU", new[] { "P1" }, "", objs, idx, 0.5);
            Check("C18b", "cùng điểm RTK -> trùng, nêu ID điểm", h2.Count == 1 && h2[0].Id == "OBJ-000001" && h2[0].Reason.Contains("cùng điểm RTK P1"));
            Check("C18c", "đã xác nhận dùng chung điểm -> không hỏi lại lý do này", DuplicateCheck.Find("", "COC_TIEU", new[] { "P1" }, "", objs, idx, 0.5, true).Count == 0);
            Check("C18d", "ngoài ngưỡng / chính nó -> không trùng", DuplicateCheck.Find("", "COC_TIEU", new[] { "P4" }, "", objs, idx, 0.5).Count == 0
                && DuplicateCheck.Find("OBJ-000001", "COC_TIEU", new[] { "P1" }, "", objs, idx, 0.5).Count == 0);
            Check("C18e", "ngưỡng cấu hình được (1.5 m bắt được cọc cách 1.0 m)", DuplicateCheck.Find("", "COC_TIEU", new[] { "P3" }, "", objs, idx, 1.5).Any(x => x.Id == "OBJ-000001")
                && DuplicateCheck.ParseTolerance("1,5") == 1.5 && DuplicateCheck.ParseTolerance("abc") == 0.5 && DuplicateCheck.ParseTolerance("-1") == 0.5 && DuplicateCheck.ParseTolerance("") == 0.5);
            var h3 = DuplicateCheck.Find("NEW", "COT_KM", new[] { "P3" }, "12+345", objs, idx, 0.5);
            Check("C18f", "cột Km trùng giá trị Km (khác vị trí)", h3.Count == 1 && h3[0].Id == "OBJ-000003" && h3[0].Reason.Contains("trùng Km"));
            Check("C18g", "nhóm khác (biển báo) không kiểm tra", DuplicateCheck.Find("", "BIEN_BAO", new[] { "P1" }, "", objs, idx, 0.5).Count == 0 && !DuplicateCheck.Applies("BIEN_BAO") && DuplicateCheck.Applies("2"));
            Check("C18h", "không di chuyển / sửa điểm RTK", idx["P1"].X == before1 && idx["P2"].Y == before2 && idx.Count == 5);
        }

        static void ConditionT()
        {
            Check("C19a", "danh sách Tình trạng", ConditionOptions.All.SequenceEqual(new[] { "Tốt", "Bình thường", "Hư hỏng" }));
            Check("C19b", "giá trị cũ tự do hiển thị nguyên văn; khớp không dấu -> mục chuẩn",
                ConditionOptions.Display("tốt, nghiêng nhẹ") == "tốt, nghiêng nhẹ" && ConditionOptions.Display("hu hong") == "Hư hỏng"
                && ConditionOptions.Display("") == "" && ConditionOptions.Display(null) == "" && ConditionOptions.IsStandard("Bình thường") && !ConditionOptions.IsStandard("gãy"));
        }

        static void FontT()
        {
            Check("C20a", "kiểu chữ nhãn biển BHT_BIENBAO = VNRomancUpdate.shx", BhtFonts.SignLabelStyle == "BHT_BIENBAO" && BhtFonts.SignLabelFont == "VNRomancUpdate.shx");
            Check("C20b", "nhãn ASCII/có dấu dùng Unicode SHX; thiếu phông dùng Arial",
                BhtFonts.LabelStyleFor("W.245a", true) == "BHT_BIENBAO" && BhtFonts.LabelStyleFor("P.127  Km1+200.00", true) == "BHT_BIENBAO"
                && BhtFonts.LabelStyleFor("Cọc tiêu", true) == "BHT_BIENBAO" && BhtFonts.LabelStyleFor("W.245a", false) == "BHT_ARIAL");
            Check("C20c", "thư mục Fonts của bundle từ thư mục DLL", string.Equals(BhtFonts.BundleFontsDir(@"C:\A\BHT.bundle\Contents\Windows"), @"C:\A\BHT.bundle\Contents\Fonts", StringComparison.OrdinalIgnoreCase),
                BhtFonts.BundleFontsDir(@"C:\A\BHT.bundle\Contents\Windows"));
            bool ch1, ch2, ch3;
            string p1 = BhtFonts.AppendPath(@"C:\X;D:\AutoCAD 2024\Fonts", @"C:\A\Fonts", out ch1);
            string p2 = BhtFonts.AppendPath(p1, @"c:\a\fonts\", out ch2);
            string p3 = BhtFonts.AppendPath("", @"C:\A\Fonts", out ch3);
            Check("C20d", "thêm Support Path chỉ khi chưa có (không phân biệt hoa, bỏ '\\' cuối)",
                ch1 && p1 == @"C:\X;D:\AutoCAD 2024\Fonts;C:\A\Fonts" && !ch2 && p2 == p1 && ch3 && p3 == @"C:\A\Fonts", p1);
            Check("C20e", "phông TrueType TDT cần cài", BhtFonts.TdtTrueType.SequenceEqual(new[] { "giaothong1.ttf", "giaothong2.ttf" }));
        }

        static void SignReportT()
        {
            string path = Path.Combine(Path.GetTempPath(), "BHT-sign-report-" + Guid.NewGuid().ToString("N") + ".xlsx");
            try
            {
                var rows = new List<SignReportRow>
                {
                    new SignReportRow { Number = 1, Project = "Tuyến thử", SignGroup = "Biển báo nguy hiểm", Code = "W.225",
                        Description = "Trẻ em", Side = "Phải", Chainage = "Km48+500", Route = "TUYEN1", Offset = "2.350",
                        StationSource = "TDT_STAKES", StationStatus = "VALID", RouteRevision = "3",
                        Condition = "Hư hỏng nhẹ", Checked = "Đã kiểm tra", ObjectId = "OBJ-000001" }
                };
                SignReportWorkbook.Write(path, "Công trình tiếng Việt", rows);
                bool parts, unicode, xmlOk = true;
                using (var file = File.OpenRead(path))
                using (var zip = new ZipArchive(file, ZipArchiveMode.Read))
                {
                    var names = new HashSet<string>(zip.Entries.Select(x => x.FullName), StringComparer.Ordinal);
                    parts = names.Contains("[Content_Types].xml") && names.Contains("xl/workbook.xml")
                        && names.Contains("xl/styles.xml") && names.Contains("xl/worksheets/sheet1.xml") && names.Contains("xl/worksheets/sheet2.xml");
                    var detail = zip.GetEntry("xl/worksheets/sheet2.xml");
                    string text;
                    using (var reader = new StreamReader(detail.Open(), System.Text.Encoding.UTF8)) text = reader.ReadToEnd();
                    unicode = text.Contains("Công trình tiếng Việt") && text.Contains("Trẻ em") && text.Contains("Km48+500")
                        && text.Contains("Nguồn lý trình") && text.Contains("TDT_STAKES") && text.Contains("Route revision");
                    foreach (var entry in zip.Entries.Where(x => x.FullName.EndsWith(".xml", StringComparison.Ordinal)))
                    {
                        try { using (var stream = entry.Open()) System.Xml.Linq.XDocument.Load(stream); }
                        catch { xmlOk = false; }
                    }
                }
                Check("C16a", "xlsx có đủ thành phần", parts);
                Check("C16b", "xlsx giữ tiếng Việt có dấu", unicode);
                Check("C16c", "mọi phần XML hợp lệ", xmlOk);
            }
            finally { if (File.Exists(path)) File.Delete(path); }
        }

        static void RouteModelT()
        {
            var open = new List<RoutePoint> { new RoutePoint(0, 0), new RoutePoint(100, 0) };
            var square = new List<RoutePoint> { new RoutePoint(0, 0), new RoutePoint(10, 0), new RoutePoint(10, 10), new RoutePoint(0, 10) };

            var a = RouteModelLogic.Project(open, false, 0, 1, 25, 3);
            Check("C21A", "A. Polyline mở", a.Valid && Near(a.RouteDistance, 25) && Near(a.Offset, 3), a.Status);

            var b = RouteModelLogic.Project(square, true, 0, 1, 0, 5);
            Check("C21B", "B. Polyline kín", b.Valid && Near(RouteModelLogic.Length(square, true), 40) && Near(b.RawDistance, 35), b.RawDistance.ToString());

            var c = RouteModelLogic.Project(open, false, 0, 1, 0, 0);
            Check("C21C", "C. StartPoint tại vertex", c.Valid && Near(c.RouteDistance, 0));

            var d = RouteModelLogic.Project(open, false, 25, 1, 50, 0);
            Check("C21D", "D. StartPoint giữa segment", d.Valid && Near(d.RouteDistance, 25));

            var e = RouteModelLogic.Project(open, false, 20, 1, 70, 0);
            Check("C21E", "E. Chiều forward", e.Valid && Near(e.RouteDistance, 50));

            var f = RouteModelLogic.Project(open, false, 80, -1, 30, 0);
            Check("C21F", "F. Chiều reverse", f.Valid && Near(f.RouteDistance, 50));

            var g = RouteModelLogic.Project(square, true, 10, 1, 0, 0);
            Check("C21G", "G. Closed polyline wrap trước điểm đầu", g.Valid && Near(g.RouteDistance, 30), g.RouteDistance.ToString());

            var regular = new List<RouteControlPoint> { new RouteControlPoint(0, 39000), new RouteControlPoint(20, 39020), new RouteControlPoint(40, 39040) };
            Check("C21H", "H. Cọc đều 20 m", RouteModelLogic.DiagnoseControls(regular, 20, 0.1, 0.5).Count == 0);

            var bad = new List<RouteControlPoint> { new RouteControlPoint(0, 39000), new RouteControlPoint(20, 39020), new RouteControlPoint(40, 39300) };
            var badIssues = RouteModelLogic.DiagnoseControls(bad, 20, 0.1, 0.5);
            Check("C21I", "I. Phát hiện một station sai", badIssues.Any(x => x.Code == "STATION_JUMP"), string.Join(",", badIssues.Select(x => x.Code).ToArray()));

            var breaks = new List<RouteControlPoint> { new RouteControlPoint(0, 39000), new RouteControlPoint(1000, 40000, 40020), new RouteControlPoint(1100, 40120) };
            var j0 = RouteModelLogic.Station(breaks, 1000, 0); var j1 = RouteModelLogic.Station(breaks, 1050, 0);
            Check("C21J", "J. Station break không nội suy xuyên gãy", j0.Station.HasValue && Near(j0.Station.Value, 40000) && j1.Station.HasValue && Near(j1.Station.Value, 40070));

            string hash1 = RouteModelLogic.GeometryHash(open, false);
            string hash2 = RouteModelLogic.GeometryHash(new List<RoutePoint> { new RoutePoint(0, 0), new RoutePoint(101, 0) }, false);
            Check("C21K", "K. Cập nhật Polyline nguồn tăng revision", hash1 != hash2 && RouteModelLogic.NextRevision(3, hash1, hash2) == 4);

            Check("C21L", "L. Đổi chiều tuyến tăng revision", RouteModelLogic.NextRevision(1, "start=0;dir=1", "start=0;dir=-1") == 2);

            var ml = RouteModelLogic.Project(open, false, 0, 1, 50, 5);
            var mr = RouteModelLogic.Project(open, false, 100, -1, 50, 5);
            Check("C21M", "M. Left/right theo chiều tăng lý trình", ml.Side == "LEFT" && mr.Side == "RIGHT", ml.Side + "/" + mr.Side);

            var n = RouteModelLogic.Project(open, false, 0, 1, 60, -12.5);
            Check("C21N", "N. Offset", Near(n.Offset, 12.5) && n.Side == "RIGHT", n.Offset.ToString());

            Check("C21O", "O. Route cũ tự migrate mặc định an toàn", RouteModelLogic.LegacyDirection("") == 1 && RouteModelLogic.LegacyRevision("") == 1
                && RouteModelLogic.LegacyDirection("-1") == -1 && RouteModelLogic.LegacyRevision("4") == 4);
        }

        static bool Near(double a, double b) { return Math.Abs(a - b) < 1e-8; }
    }
}

