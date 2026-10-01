using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;
using BHT.Core;
using CoreApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

[assembly: CommandClass(typeof(BHT.Bridge.BridgeCommands))]
[assembly: CommandClass(typeof(BHT.Bridge.TdtSignLispFunctions))]
[assembly: CommandClass(typeof(BHT.Bridge.Tdt91LispFunctions))]

namespace BHT.Bridge
{
    /// <summary>
    /// Lenh dong lenh cua BHT.Bridge (khong can giao dien) - dung cho kiem thu tich hop
    /// trong AutoCAD Core Console va cho nguoi dung chan doan. Chi doc/ghi dung dinh dang Lisp.
    /// </summary>
    public class BridgeCommands
    {
        private static Editor Ed { get { return CoreApp.DocumentManager.MdiActiveDocument.Editor; } }
        private static void Msg(string s) { Ed.WriteMessage("\n" + s); }

        private static BhtDataService Service()
        {
            var doc = CoreApp.DocumentManager.MdiActiveDocument;
            return new BhtDataService(doc.Database, () => DwgPrefix(), false);
        }

        public static string DwgPrefix()
        {
            try { return Convert.ToString(CoreApp.GetSystemVariable("DWGPREFIX")); } catch { return ""; }
        }

        private static string Ask(string prompt, string def)
        {
            var o = new PromptStringOptions("\n" + prompt + (def != "" ? " <" + def + ">" : "") + ": ");
            o.AllowSpaces = true;
            var r = Ed.GetString(o);
            if (r.Status != PromptStatus.OK) return null;
            return r.StringResult == "" ? def : r.StringResult;
        }

        private static List<string> Ids(string s)
        {
            return (s ?? "").Split(new[] { ',', ';', ' ' }, StringSplitOptions.RemoveEmptyEntries).ToList();
        }

        [CommandMethod("BHTNETINFO")]
        public void Info()
        {
            using (var s = Service())
            {
                var ov = s.GetOverview();
                Msg("BHT.Bridge " + BhtVersion.FileVersion + " | điểm RTK " + ov.RtkPoints + " (v0.1 chưa ID " + ov.LegacyV01Points + ")"
                    + " | hồ sơ đối tượng " + ov.ObjectRecords + " | ảnh " + ov.Photos + " (GPS hợp lệ " + ov.PhotosGpsValid
                    + ", đã gắn " + ov.PhotosLinked + ") | ký hiệu ảnh " + ov.PhotoMarkers + " | ký hiệu " + ov.Symbols
                    + " | nhãn " + ov.Labels + " | tuyến " + ov.Routes + " | đoạn " + ov.Segments);
                foreach (var w in ov.Warnings) Msg("  CẢNH BÁO: " + w);
            }
        }

        /// <summary>Ghi dump chuan (diem, moi ban ghi, duong dan JPG) - so sanh tung byte voi dump cua Lisp.</summary>
        [CommandMethod("BHTNETDUMP")]
        public void Dump()
        {
            string path = Ask("Tệp dump", "");
            if (string.IsNullOrEmpty(path)) return;
            using (var s = Service())
            {
                File.WriteAllText(path, BuildDump(s), new UTF8Encoding(false));
                Msg("BHTNETDUMP: đã ghi " + path);
            }
        }

        public static string BuildDump(BhtDataService s)
        {
            var sb = new StringBuilder();
            sb.Append("#BHT-DUMP 1\n");
            foreach (var p in s.GetPoints().OrderBy(p => p.IdUpper, StringComparer.Ordinal))
            {
                sb.Append("P|").Append(p.Id).Append('|').Append(p.Dataset).Append('|').Append(p.Row).Append('|').Append(p.Name)
                  .Append('|').Append(p.NRaw).Append('|').Append(p.ERaw).Append('|').Append(p.ZRaw).Append('|').Append(p.Class)
                  .Append('|').Append(p.SourceFile).Append('|').Append(p.ImportedAt).Append('|').Append(p.Description)
                  .Append('|').Append(LispFormat.Fnum(p.X, 4)).Append('|').Append(LispFormat.Fnum(p.Y, 4)).Append('|').Append(LispFormat.Fnum(p.Z, 4))
                  .Append('\n');
            }
            foreach (var sub in new[] { "OBJ", "PHOTO", "DATASET", "META", "ROUTE", "SEG" })
            {
                foreach (var kv in s.Ordered(sub))
                {
                    sb.Append("R|").Append(sub).Append('|').Append(kv.Key).Append('\n');
                    foreach (var pr in kv.Value.Pairs) sb.Append("  ").Append(pr.Key).Append('=').Append(pr.Value).Append('\n');
                }
            }
            string alt = s.Meta("thu_muc_anh", ""), pre = DwgPrefix();
            foreach (var kv in s.Ordered("PHOTO"))
            {
                var p = PhotoLogic.Resolve(kv.Value, alt, pre, PhotoLogic.FileOk);
                sb.Append("J|").Append(kv.Key).Append('|').Append(p ?? "").Append('\n');
            }
            return sb.ToString();
        }

        /// <summary>Tao ho so tu dong lenh (kiem thu): ID ("" = tu dong), ds diem, nhom, ma, so tru, tinh trang, ghi chu, dung chung.</summary>
        [CommandMethod("BHTNETTAO")]
        public void Create()
        {
            string id = Ask("ID đối tượng (.=tự động)", "."); if (id == null) return;
            string pts = Ask("Các ID điểm RTK (phẩy)", ""); if (pts == null) return;
            string grp = Ask("Nhóm (số hoặc mã)", "0"); if (grp == null) return;
            string code = Ask("Mã hiệu (.=trống)", "."); if (code == null) return;
            string poles = Ask("Số trụ (.=trống)", "."); if (poles == null) return;
            string cond = Ask("Tình trạng (.=trống)", "."); if (cond == null) return;
            string note = Ask("Ghi chú (.=trống)", "."); if (note == null) return;
            string share = Ask("Cho dùng chung điểm đã thuộc hồ sơ khác? [C/K]", "K"); if (share == null) return;
            Func<string, string> dot = v => v == "." ? "" : v;
            var f = new BhtRecord().Add(ObjFields.Group, grp).Add(ObjFields.Code, dot(code)).Add(ObjFields.PoleCount, dot(poles))
                                   .Add(ObjFields.Condition, dot(cond)).Add(ObjFields.Note, dot(note));
            using (var s = Service())
            {
                var r = s.CreateObject(dot(id), f, Ids(pts), share.ToUpperInvariant() == "C");
                Msg("BHTNETTAO: " + r);
            }
        }

        [CommandMethod("BHTNETSUA")]
        public void Edit()
        {
            string id = Ask("ID đối tượng", ""); if (string.IsNullOrEmpty(id)) return;
            string key = Ask("Trường", ""); if (string.IsNullOrEmpty(key)) return;
            string val = Ask("Giá trị (.=trống)", "."); if (val == null) return;
            using (var s = Service()) Msg("BHTNETSUA: " + s.UpdateObject(id, new BhtRecord().Add(key, val == "." ? "" : val)));
        }

        [CommandMethod("BHTNETTHEMDIEM")]
        public void AddPts()
        {
            string id = Ask("ID đối tượng", ""); if (string.IsNullOrEmpty(id)) return;
            string pts = Ask("Các ID điểm RTK (phẩy)", ""); if (pts == null) return;
            using (var s = Service()) Msg("BHTNETTHEMDIEM: " + s.AddPoints(id, Ids(pts)));
        }

        [CommandMethod("BHTNETGANANH")]
        public void Link()
        {
            string pid = Ask("Mã ảnh", ""); if (string.IsNullOrEmpty(pid)) return;
            string oid = Ask("ID đối tượng", ""); if (string.IsNullOrEmpty(oid)) return;
            using (var s = Service()) Msg("BHTNETGANANH: " + s.LinkPhoto(pid, oid, "THU_CONG"));
        }

        [CommandMethod("BHTNETBOANH")]
        public void Unlink()
        {
            string pid = Ask("Mã ảnh", ""); if (string.IsNullOrEmpty(pid)) return;
            string oid = Ask("ID đối tượng", ""); if (string.IsNullOrEmpty(oid)) return;
            using (var s = Service()) Msg("BHTNETBOANH: " + s.UnlinkPhoto(pid, oid));
        }

        /// <summary>Goi 1 ham bht:api-* qua Application.Invoke va in ket qua (+ ghi tep neu co).</summary>
        [CommandMethod("BHTNETLISP")]
        public void Lisp()
        {
            string fn = Ask("Hàm Lisp", "bht:api-version"); if (string.IsNullOrEmpty(fn)) return;
            string arg = Ask("Đối số (.=không có)", "."); if (arg == null) return;
            string outp = Ask("Tệp kết quả (.=không ghi)", "."); if (outp == null) return;
            if (arg.StartsWith("@")) arg = Convert.ToString(CoreApp.GetSystemVariable(arg.Substring(1))); // vd @USERS1 (kiem thu tu script)
            var r = arg == "." ? new LispApi().Call(fn) : new LispApi().Call(fn, arg);
            var sb = new StringBuilder();
            sb.Append(r.Ok ? "OK" : "LOI").Append('\n');
            if (!r.Ok) sb.Append(r.Error).Append('\n');
            foreach (var v in r.Values) sb.Append(v).Append('\n');
            Msg("BHTNETLISP " + fn + ": " + (r.Ok ? "OK, " + r.Values.Count + " giá trị" : "LỖI " + r.Error));
            foreach (var v in r.Values.Take(12)) Msg("  " + v);
            if (outp != ".") File.WriteAllText(outp, sb.ToString(), new UTF8Encoding(false));
        }

        /// <summary>
        /// Kiem thu bo dieu phoi (khong can giao dien): trong luc lenh nay dang chay,
        /// IsBusy phai bao ban, RunWrite phai TU CHOI; RunInCommandContext (da o ngu canh lenh) chay ngay.
        /// </summary>
        [CommandMethod("BHTNETDIEUPHOI")]
        public void DispatcherTest()
        {
            string outp = Ask("Tệp kết quả", ""); if (string.IsNullOrEmpty(outp)) return;
            var doc = CoreApp.DocumentManager.MdiActiveDocument;
            var sb = new StringBuilder();
            string why;
            bool busy = AcadDispatcher.IsBusy(doc, out why);
            sb.Append("busy=").Append(busy ? "1" : "0").Append('|').Append(AcadDispatcher.ActiveCommands(doc)).Append('\n');
            var w = AcadDispatcher.RunWrite(doc, "thử ghi", db => OpResult.Success("KHÔNG ĐƯỢC CHẠY"));
            sb.Append("runwrite_ok=").Append(w.Ok ? "1" : "0").Append('|').Append(w.Message).Append('\n');
            sb.Append("appctx=").Append(CoreApp.DocumentManager.IsApplicationContext ? "1" : "0").Append('\n');
            // RunInCommandContext tu choi khi dang co lenh (dung cho palette); goi truc tiep LispApi o day.
            OpResult rc = null;
            AcadDispatcher.RunInCommandContext("thử ngữ cảnh lệnh", () => OpResult.Success("x"), r => rc = r);
            sb.Append("runctx_ok=").Append(rc != null && rc.Ok ? "1" : "0").Append('|').Append(rc == null ? "(chưa gọi)" : rc.Message).Append('\n');
            var lr = new LispApi().Call("bht:api-version");
            sb.Append("lisp_ok=").Append(lr.Ok ? "1" : "0").Append('|').Append(string.Join(",", lr.Values.ToArray())).Append('\n');
            File.WriteAllText(outp, sb.ToString(), new UTF8Encoding(false));
            Msg("BHTNETDIEUPHOI: đã ghi " + outp);
        }

        /// <summary>
        /// Kiem thu bo nho dem: them 1 POINT tam (BHT_PT gia) -> GetPoints phai thay doi (ObjectAppended),
        /// xoa -> tro ve. Chi dung tren BAN SAO ban ve kiem thu. Khong dong vao POINT that.
        /// </summary>
        [CommandMethod("BHTNETCACHE")]
        public void CacheTest()
        {
            string outp = Ask("Tệp kết quả", ""); if (string.IsNullOrEmpty(outp)) return;
            var doc = CoreApp.DocumentManager.MdiActiveDocument;
            var db = doc.Database;
            var sb = new StringBuilder();
            using (var svc = new BhtDataService(db, () => DwgPrefix(), true))
            {
                int n1 = svc.GetPoints().Count;
                int n1b = svc.GetPoints().Count;
                ObjectId tmp;
                using (var tr = db.TransactionManager.StartTransaction())
                {
                    var rat = (RegAppTable)tr.GetObject(db.RegAppTableId, OpenMode.ForRead);
                    if (!rat.Has("BHT_PT"))
                    {
                        rat.UpgradeOpen(); var ra = new RegAppTableRecord(); ra.Name = "BHT_PT"; rat.Add(ra); tr.AddNewlyCreatedDBObject(ra, true);
                    }
                    var ms = (BlockTableRecord)tr.GetObject(SymbolUtilityServices.GetBlockModelSpaceId(db), OpenMode.ForWrite);
                    var pt = new DBPoint(new Autodesk.AutoCAD.Geometry.Point3d(-999999.0, -999999.0, 0));
                    tmp = ms.AppendEntity(pt); tr.AddNewlyCreatedDBObject(pt, true);
                    var rb = new ResultBuffer(new TypedValue(1001, "BHT_PT"));
                    foreach (var v in new[] { "ZZTMP-R-000001", "ZZTMP", "1", "TMP", "0", "0", "0", "CHUA_XAC_DINH", "tmp", "tmp", "tmp" }) rb.Add(new TypedValue(1000, v));
                    pt.XData = rb;
                    tr.Commit();
                }
                int n2 = svc.GetPoints().Count;
                using (var tr = db.TransactionManager.StartTransaction())
                {
                    tr.GetObject(tmp, OpenMode.ForWrite).Erase();
                    tr.Commit();
                }
                int n3 = svc.GetPoints().Count;
                sb.Append(n1).Append('|').Append(n1b).Append('|').Append(n2).Append('|').Append(n3).Append('\n');
            }
            File.WriteAllText(outp, sb.ToString(), new UTF8Encoding(false));
            Msg("BHTNETCACHE: " + sb.ToString().Trim());
        }

        /// <summary>Dung de kiem tra: lenh .NET cung ten voi ham c: Lisp thi ban nao duoc goi.</summary>
        [CommandMethod("BHTNETPING")]
        public void Ping() { Msg("BHTNETPING: lệnh .NET được gọi."); CoreApp.SetSystemVariable("USERS5", "NET"); }
    }
}
