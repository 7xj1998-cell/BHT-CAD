using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace BHT.Bridge
{
    /// <summary>
    /// Phat hien TDTSolution 9.1 ban thuong. Ban cai tren may co the dung ten thu muc
    /// "TDT Solution 2022", nhung tai lieu kem theo xac nhan day la TDTSolution 9.1
    /// va cac module lien ket AutoCAD R24 (2021-2024). Khong bao gio chon TDT9.1 Pro.
    /// </summary>
    public static class Tdt91Installation
    {
        public static string FindRoot()
        {
            var candidates = new List<string>();
            foreach (string baseDir in new[]
            {
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                Environment.GetEnvironmentVariable("ProgramFiles(x86)"),
                Environment.GetEnvironmentVariable("ProgramFiles"),
                @"C:\Program Files (x86)",
                @"C:\Program Files"
            })
            {
                if (string.IsNullOrEmpty(baseDir)) continue;
                AddCandidate(candidates, Path.Combine(baseDir, "TDT Solution 9.1"));
                AddCandidate(candidates, Path.Combine(baseDir, "TDT Solution 2022"));
            }
            return candidates.FirstOrDefault(IsRegular91Root) ?? "";
        }

        private static void AddCandidate(List<string> values, string path)
        {
            if (!values.Any(x => string.Equals(x, path, StringComparison.OrdinalIgnoreCase))) values.Add(path);
        }

        private static bool IsRegular91Root(string root)
        {
            string folder = string.IsNullOrEmpty(root) ? "" : Path.GetFileName(root.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
            if (folder.IndexOf("Pro", StringComparison.OrdinalIgnoreCase) >= 0) return false;
            return File.Exists(Path.Combine(root, "AlignmentDb.dbx"))
                && File.Exists(Path.Combine(root, "RoadSignsUI.arx"))
                && File.Exists(Path.Combine(root, "Data", "Bien bao", "bienbao.set"))
                && File.Exists(Path.Combine(root, "Data", "Bien bao", "Bienbao.xml"));
        }

        public static string DisplayName
        {
            get { return string.IsNullOrEmpty(FindRoot()) ? "Chưa tìm thấy TDTSolution 9.1" : "TDTSolution 9.1"; }
        }

        public static string AlignmentModule
        {
            get { string root = FindRoot(); return root == "" ? "" : Path.Combine(root, "AlignmentDb.dbx"); }
        }

        public static string RoadSignsModule
        {
            get { string root = FindRoot(); return root == "" ? "" : Path.Combine(root, "RoadSignsUI.arx"); }
        }
    }

    public sealed class Tdt91RouteResult
    {
        public bool Ok;
        public string Error = "";
        public string ReferenceHandle = "";
        public string SourceClass = "";
        public double Length;
        public int Vertices;
        public bool Updated;
    }

    /// <summary>
    /// Tao polyline tham chieu tu TdtDbAlignment bang Entity.Explode. Doi tuong TDT
    /// chi duoc mo ForRead; BHT chi ghi polyline rieng tren layer BHT_TUYEN_TDT.
    /// </summary>
    public static class Tdt91Alignment
    {
        public const string AppName = "BHT_TDT_ROUTE";
        public const string LayerName = "BHT_TUYEN_TDT";

        public static Tdt91RouteResult Snapshot(Database db, string sourceHandle, string existingReferenceHandle)
        {
            var result = new Tdt91RouteResult();
            if (db == null) { result.Error = "không có bản vẽ"; return result; }
            ObjectId sourceId = IdFromHandle(db, sourceHandle);
            if (sourceId.IsNull) { result.Error = "không tìm thấy tim TDT handle " + sourceHandle; return result; }

            var exploded = new DBObjectCollection();
            try
            {
                using (var tr = db.TransactionManager.StartTransaction())
                {
                    var source = tr.GetObject(sourceId, OpenMode.ForRead, false) as Entity;
                    if (source == null) { result.Error = "đối tượng được chọn không phải Entity"; return result; }
                    string rxName = SafeRxName(source);
                    result.SourceClass = rxName;
                    if (source is ProxyEntity || rxName.IndexOf("PROXY", StringComparison.OrdinalIgnoreCase) >= 0)
                    {
                        result.Error = "tim tuyến đang là proxy; hãy mở AutoCAD bằng profile TDTSolution 9.1 rồi thử lại";
                        return result;
                    }
                    if (rxName.IndexOf("TDTDBALIGNMENT", StringComparison.OrdinalIgnoreCase) < 0
                        && rxName.IndexOf("TDTDBPOLYLINE", StringComparison.OrdinalIgnoreCase) < 0
                        && rxName.IndexOf("ALIGNMENT", StringComparison.OrdinalIgnoreCase) < 0)
                    {
                        result.Error = "đối tượng " + rxName + " không phải tim tuyến TDTSolution 9.1";
                        return result;
                    }

                    source.Explode(exploded);
                    Curve best = null;
                    double bestLength = -1.0;
                    foreach (DBObject item in exploded)
                    {
                        var curve = item as Curve;
                        if (curve == null) continue;
                        double length = CurveLength(curve);
                        if (length > bestLength) { best = curve; bestLength = length; }
                    }
                    if (best == null || bestLength <= 0.0)
                    {
                        result.Error = "TDT không trả về hình học tim khi tạo bản sao tham chiếu";
                        return result;
                    }

                    Polyline geometry = ToPolyline(best, bestLength);
                    if (geometry == null || geometry.NumberOfVertices < 2)
                    {
                        if (geometry != null) geometry.Dispose();
                        result.Error = "không chuyển được hình học tim TDT thành polyline";
                        return result;
                    }

                    EnsureLayer(tr, db);
                    EnsureRegApp(tr, db);
                    Polyline target = ExistingReference(tr, db, existingReferenceHandle);
                    if (target != null)
                    {
                        CopyGeometry(geometry, target);
                        geometry.Dispose();
                        result.Updated = true;
                    }
                    else
                    {
                        var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                        var ms = (BlockTableRecord)tr.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite);
                        target = geometry;
                        ms.AppendEntity(target);
                        tr.AddNewlyCreatedDBObject(target, true);
                    }
                    target.Layer = LayerName;
                    target.ColorIndex = 3;
                    target.XData = new ResultBuffer(
                        new TypedValue((int)DxfCode.ExtendedDataRegAppName, AppName),
                        new TypedValue((int)DxfCode.ExtendedDataAsciiString, source.Handle.ToString()),
                        new TypedValue((int)DxfCode.ExtendedDataAsciiString, rxName),
                        new TypedValue((int)DxfCode.ExtendedDataReal, bestLength));
                    result.ReferenceHandle = target.Handle.ToString();
                    result.Length = bestLength;
                    result.Vertices = target.NumberOfVertices;
                    result.Ok = true;
                    tr.Commit();
                }
            }
            catch (System.Exception ex)
            {
                result.Error = "không lấy được tim TDT 9.1: " + ex.Message;
            }
            finally
            {
                foreach (DBObject item in exploded) item.Dispose();
            }
            return result;
        }

        private static string SafeRxName(Entity entity)
        {
            try
            {
                var rx = entity.GetRXClass();
                string name = rx == null ? "" : rx.Name;
                string dxf = rx == null ? "" : rx.DxfName;
                return string.IsNullOrEmpty(dxf) ? name : dxf + "/" + name;
            }
            catch { return entity.GetType().Name; }
        }

        private static ObjectId IdFromHandle(Database db, string value)
        {
            long raw;
            if (!long.TryParse((value ?? "").Trim(), NumberStyles.HexNumber, CultureInfo.InvariantCulture, out raw)) return ObjectId.Null;
            ObjectId id;
            try { return db.TryGetObjectId(new Handle(raw), out id) && !id.IsErased ? id : ObjectId.Null; }
            catch { return ObjectId.Null; }
        }

        private static double CurveLength(Curve curve)
        {
            try { return Math.Abs(curve.GetDistanceAtParameter(curve.EndParam) - curve.GetDistanceAtParameter(curve.StartParam)); }
            catch { return -1.0; }
        }

        private static Polyline ToPolyline(Curve curve, double length)
        {
            var lw = curve as Polyline;
            if (lw != null) return (Polyline)lw.Clone();
            int segments = Math.Max(2, Math.Min(3000, (int)Math.Ceiling(length / Math.Max(0.5, length / 1500.0))));
            var result = new Polyline(segments + 1);
            for (int i = 0; i <= segments; i++)
            {
                double distance = length * i / segments;
                Point3d point = curve.GetPointAtDist(distance);
                result.AddVertexAt(i, new Point2d(point.X, point.Y), 0.0, 0.0, 0.0);
            }
            return result;
        }

        private static Polyline ExistingReference(Transaction tr, Database db, string handle)
        {
            ObjectId id = IdFromHandle(db, handle);
            if (id.IsNull) return null;
            var target = tr.GetObject(id, OpenMode.ForWrite, false) as Polyline;
            if (target == null) return null;
            ResultBuffer x = target.GetXDataForApplication(AppName);
            bool owned = x != null || string.Equals(target.Layer, LayerName, StringComparison.OrdinalIgnoreCase);
            if (x != null) x.Dispose();
            return owned ? target : null;
        }

        private static void CopyGeometry(Polyline source, Polyline target)
        {
            while (target.NumberOfVertices > 0) target.RemoveVertexAt(target.NumberOfVertices - 1);
            for (int i = 0; i < source.NumberOfVertices; i++)
                target.AddVertexAt(i, source.GetPoint2dAt(i), source.GetBulgeAt(i), source.GetStartWidthAt(i), source.GetEndWidthAt(i));
            target.Closed = source.Closed;
            target.Elevation = source.Elevation;
            target.Normal = source.Normal;
        }

        private static void EnsureLayer(Transaction tr, Database db)
        {
            var table = (LayerTable)tr.GetObject(db.LayerTableId, OpenMode.ForRead);
            if (table.Has(LayerName)) return;
            table.UpgradeOpen();
            var layer = new LayerTableRecord { Name = LayerName, Color = Autodesk.AutoCAD.Colors.Color.FromColorIndex(Autodesk.AutoCAD.Colors.ColorMethod.ByAci, 3) };
            table.Add(layer); tr.AddNewlyCreatedDBObject(layer, true);
        }

        private static void EnsureRegApp(Transaction tr, Database db)
        {
            var table = (RegAppTable)tr.GetObject(db.RegAppTableId, OpenMode.ForRead);
            if (table.Has(AppName)) return;
            table.UpgradeOpen();
            var record = new RegAppTableRecord { Name = AppName };
            table.Add(record); tr.AddNewlyCreatedDBObject(record, true);
        }
    }

    public static class Tdt91LispFunctions
    {
        [LispFunction("BHTTDT91STATUS")]
        public static ResultBuffer Status(ResultBuffer args)
        {
            string root = Tdt91Installation.FindRoot();
            return Reply(root == "" ? "LOI" : "OK", Tdt91Installation.DisplayName, root,
                TdtSignLibrary.GetCatalog().Count.ToString(CultureInfo.InvariantCulture));
        }

        [LispFunction("BHTTDT91ROUTE")]
        public static ResultBuffer Route(ResultBuffer args)
        {
            string source = "", existing = "";
            int index = 0;
            if (args != null)
                foreach (TypedValue value in args)
                {
                    if (index == 0) source = Convert.ToString(value.Value, CultureInfo.InvariantCulture);
                    else if (index == 1) existing = Convert.ToString(value.Value, CultureInfo.InvariantCulture);
                    index++;
                }
            Document doc = AcApp.DocumentManager.MdiActiveDocument;
            if (doc == null) return Reply("LOI", "không có bản vẽ đang mở");
            Tdt91RouteResult r = Tdt91Alignment.Snapshot(doc.Database, source, existing);
            return r.Ok
                ? Reply("OK", r.ReferenceHandle, r.SourceClass, r.Length.ToString("0.###", CultureInfo.InvariantCulture),
                    r.Vertices.ToString(CultureInfo.InvariantCulture), r.Updated ? "CAP_NHAT" : "TAO_MOI")
                : Reply("LOI", r.Error);
        }

        private static ResultBuffer Reply(params string[] values)
        {
            var rb = new ResultBuffer();
            foreach (string value in values) rb.Add(new TypedValue((int)LispDataType.Text, value ?? ""));
            return rb;
        }
    }
}
