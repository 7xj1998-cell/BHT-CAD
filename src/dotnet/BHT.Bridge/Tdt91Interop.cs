using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
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

    public sealed class Tdt91StakeCandidate
    {
        public double Station;
        public double RawDistance;
        public double Offset;
        public double X, Y;
        public string EntityType = "";
        public string Handle = "";
        public string Text = "";
        public string Layer = "";
        public int Confidence;
    }

    /// <summary>
    /// Bo quet cọc TDT chi doc: TEXT/MTEXT va Attribute cua INSERT co chuoi KmN+M.
    /// Chi project len Polyline tham chieu BHT thuong; khong goi vlax-curve tren proxy,
    /// khong sua cọc TDT va khong tu chap nhan cọc bat thuong.
    /// </summary>
    public static class Tdt91Stakes
    {
        private static readonly Regex KmPattern = new Regex(@"(?i)(?:^|[^a-z0-9])km\s*(\d{1,5})\s*\+\s*(\d{1,3}(?:[\.,]\d+)?)", RegexOptions.Compiled);

        public static List<Tdt91StakeCandidate> Scan(Database db, string routeHandle, double maxOffset)
        {
            var result = new List<Tdt91StakeCandidate>();
            if (db == null) return result;
            ObjectId routeId = IdFromHandle(db, routeHandle);
            if (routeId.IsNull) return result;
            using (var tr = db.TransactionManager.StartOpenCloseTransaction())
            {
                var route = tr.GetObject(routeId, OpenMode.ForRead, false) as Curve;
                if (route == null) return result;
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                var model = (BlockTableRecord)tr.GetObject(table[BlockTableRecord.ModelSpace], OpenMode.ForRead);
                foreach (ObjectId id in model)
                {
                    if (id == routeId) continue;
                    Entity entity;
                    try { entity = tr.GetObject(id, OpenMode.ForRead, false) as Entity; }
                    catch { continue; }
                    if (entity == null) continue;
                    string text = "", type = "", blockName = "";
                    Point3d position;
                    if (!ReadText(tr, entity, out text, out position, out type, out blockName)) continue;
                    double station;
                    if (!TryStation(text, out station)) continue;
                    Point3d closest;
                    try { closest = route.GetClosestPointTo(position, false); }
                    catch { continue; }
                    double offset = new Point2d(position.X, position.Y).GetDistanceTo(new Point2d(closest.X, closest.Y));
                    if (maxOffset > 0.0 && offset > maxOffset) continue;
                    double raw;
                    try { raw = route.GetDistAtPoint(closest); }
                    catch { continue; }
                    int confidence = type == "INSERT" ? 90 : 85;
                    string clue = (blockName + " " + entity.Layer).ToUpperInvariant();
                    if (clue.Contains("COC") || clue.Contains("STAKE") || clue.Contains("KM")) confidence += 10;
                    result.Add(new Tdt91StakeCandidate
                    {
                        Station = station, RawDistance = raw, Offset = offset, X = position.X, Y = position.Y,
                        EntityType = type, Handle = entity.Handle.ToString(), Text = Clean(text), Layer = entity.Layer ?? "",
                        Confidence = Math.Min(100, confidence)
                    });
                }
                tr.Commit();
            }
            return result.OrderBy(x => x.RawDistance).ThenBy(x => x.Station).ToList();
        }

        private static bool ReadText(Transaction tr, Entity entity, out string text, out Point3d position, out string type, out string blockName)
        {
            text = ""; position = Point3d.Origin; type = ""; blockName = "";
            var dbText = entity as DBText;
            if (dbText != null) { text = dbText.TextString ?? ""; position = dbText.Position; type = "TEXT"; return text != ""; }
            var mText = entity as MText;
            if (mText != null) { text = mText.Contents ?? ""; position = mText.Location; type = "MTEXT"; return text != ""; }
            var block = entity as BlockReference;
            if (block == null) return false;
            position = block.Position; type = "INSERT";
            try
            {
                var record = tr.GetObject(block.BlockTableRecord, OpenMode.ForRead, false) as BlockTableRecord;
                if (record != null) blockName = record.Name ?? "";
            }
            catch { }
            var values = new List<string>();
            foreach (ObjectId aid in block.AttributeCollection)
            {
                try
                {
                    var attribute = tr.GetObject(aid, OpenMode.ForRead, false) as AttributeReference;
                    if (attribute != null && !string.IsNullOrWhiteSpace(attribute.TextString)) values.Add(attribute.TextString);
                }
                catch { }
            }
            text = string.Join(" ", values.ToArray());
            return text != "";
        }

        public static bool TryStation(string value, out double station)
        {
            station = 0.0;
            Match match = KmPattern.Match(Clean(value));
            if (!match.Success) return false;
            double km, metres;
            if (!double.TryParse(match.Groups[1].Value, NumberStyles.Integer, CultureInfo.InvariantCulture, out km)) return false;
            if (!double.TryParse(match.Groups[2].Value.Replace(',', '.'), NumberStyles.Float, CultureInfo.InvariantCulture, out metres)) return false;
            if (metres < 0.0 || metres >= 1000.0) return false;
            station = km * 1000.0 + metres;
            return true;
        }

        private static string Clean(string value)
        {
            return (value ?? "").Replace("\\P", " ").Replace("\r", " ").Replace("\n", " ").Replace("|", "/").Trim();
        }

        private static ObjectId IdFromHandle(Database db, string value)
        {
            long raw;
            if (!long.TryParse((value ?? "").Trim(), NumberStyles.HexNumber, CultureInfo.InvariantCulture, out raw)) return ObjectId.Null;
            ObjectId id;
            try { return db.TryGetObjectId(new Handle(raw), out id) && !id.IsErased ? id : ObjectId.Null; }
            catch { return ObjectId.Null; }
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
        public int Pieces = 1;
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
                        // 0.4.6-fix3: giai thich ro nguyen nhan va cach xu ly (truoc chi bao "dang la proxy").
                        result.Error = "không nhận ra tim tuyến TDT (đối tượng đang hiển thị dạng proxy "
                            + (string.IsNullOrEmpty(rxName) ? "" : "- " + rxName + " ")
                            + "vì phiên AutoCAD này chưa nạp TDTSolution 9.1). Cách xử lý: lưu và đóng AutoCAD, "
                            + "mở lại bằng biểu tượng / profile TDTSolution 9.1 (cắm khóa USB TDT nếu phần mềm yêu cầu), "
                            + "mở bản vẽ rồi chạy lại \"1. Lấy hoặc cập nhật tim từ TDT 9.1\" (lệnh BHTTUYENTDT). "
                            + "BHT không sửa tim TDT gốc.";
                        return result;
                    }
                    if (rxName.IndexOf("TDTDBALIGNMENT", StringComparison.OrdinalIgnoreCase) < 0
                        && rxName.IndexOf("TDTDBPOLYLINE", StringComparison.OrdinalIgnoreCase) < 0
                        && rxName.IndexOf("ALIGNMENT", StringComparison.OrdinalIgnoreCase) < 0)
                    {
                        result.Error = "đối tượng " + rxName + " không phải tim tuyến TDTSolution 9.1";
                        return result;
                    }

                    // Explode chi tao doi tuong tam trong bo nho; doi tuong TDT goc van mo ForRead.
                    source.Explode(exploded);
                    Curve best = null;
                    double bestLength = -1.0;
                    var curves = new List<Curve>();
                    foreach (DBObject item in exploded)
                    {
                        var curve = item as Curve;
                        if (curve == null) continue;
                        double length = CurveLength(curve);
                        if (length <= 0.0) continue;
                        curves.Add(curve);
                        if (length > bestLength) { best = curve; bestLength = length; }
                    }
                    if (best == null || bestLength <= 0.0)
                    {
                        result.Error = "TDT không trả về hình học tim khi tạo bản sao tham chiếu";
                        return result;
                    }

                    // 0.4.6-fix2: neu TDT tach tim thanh nhieu doan Line/Arc noi tiep nhau,
                    // noi cac doan chung dau mut thanh MOT polyline thay vi chi lay doan dai nhat.
                    int pieces;
                    double chainLength;
                    Polyline geometry = ChainFrom(best, curves, out pieces, out chainLength);
                    if (geometry != null && pieces > 1) { bestLength = chainLength; result.Pieces = pieces; }
                    else { if (geometry != null) geometry.Dispose(); geometry = ToPolyline(best, bestLength); }
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

        // ------------------------------------------------------------ noi doan tim

        private sealed class Piece
        {
            public List<Point2d> Points = new List<Point2d>();
            public List<double> Bulges = new List<double>(); // Bulges[i] cho doan Points[i] -> Points[i+1]
            public Point2d Start { get { return Points[0]; } }
            public Point2d End { get { return Points[Points.Count - 1]; } }

            public Piece Reversed()
            {
                var r = new Piece();
                for (int i = Points.Count - 1; i >= 0; i--) r.Points.Add(Points[i]);
                for (int i = Bulges.Count - 1; i >= 0; i--) r.Bulges.Add(-Bulges[i]);
                return r;
            }
        }

        private const double JoinTolerance = 1e-4;

        private static Piece ToPiece(Curve curve)
        {
            try
            {
                var p = new Piece();
                var line = curve as Line;
                if (line != null)
                {
                    p.Points.Add(new Point2d(line.StartPoint.X, line.StartPoint.Y));
                    p.Points.Add(new Point2d(line.EndPoint.X, line.EndPoint.Y));
                    p.Bulges.Add(0.0);
                    return p;
                }
                var arc = curve as Arc;
                if (arc != null)
                {
                    double sweep = arc.EndAngle - arc.StartAngle;
                    while (sweep <= 0.0) sweep += 2.0 * Math.PI;
                    double bulge = Math.Tan(sweep / 4.0);
                    if (arc.Normal.Z < 0.0) bulge = -bulge;
                    p.Points.Add(new Point2d(arc.StartPoint.X, arc.StartPoint.Y));
                    p.Points.Add(new Point2d(arc.EndPoint.X, arc.EndPoint.Y));
                    p.Bulges.Add(bulge);
                    return p;
                }
                var lw = curve as Polyline;
                if (lw != null)
                {
                    if (lw.Closed || lw.NumberOfVertices < 2) return null;
                    double sign = lw.Normal.Z < 0.0 ? -1.0 : 1.0;
                    for (int i = 0; i < lw.NumberOfVertices; i++)
                    {
                        Point3d v = lw.GetPoint3dAt(i);
                        p.Points.Add(new Point2d(v.X, v.Y));
                        if (i < lw.NumberOfVertices - 1) p.Bulges.Add(sign * lw.GetBulgeAt(i));
                    }
                    return p;
                }
                if (curve.Closed) return null;
                double length = CurveLength(curve);
                if (length <= 0.0) return null;
                int segments = Math.Max(2, Math.Min(3000, (int)Math.Ceiling(length / Math.Max(0.5, length / 1500.0))));
                for (int i = 0; i <= segments; i++)
                {
                    Point3d q = curve.GetPointAtDist(length * i / segments);
                    p.Points.Add(new Point2d(q.X, q.Y));
                    if (i < segments) p.Bulges.Add(0.0);
                }
                return p;
            }
            catch { return null; }
        }

        private static Polyline ChainFrom(Curve best, List<Curve> curves, out int pieces, out double totalLength)
        {
            pieces = 0; totalLength = 0.0;
            Piece chain = ToPiece(best);
            if (chain == null) return null;
            pieces = 1;
            totalLength = CurveLength(best);
            string layer = "";
            try { layer = best.Layer ?? ""; } catch { }
            var used = new HashSet<Curve> { best };
            bool extended = true;
            while (extended)
            {
                extended = false;
                if (chain.Start.GetDistanceTo(chain.End) <= JoinTolerance) break; // tim da khep kin
                foreach (bool atEnd in new[] { true, false })
                {
                    Point2d tip = atEnd ? chain.End : chain.Start;
                    Curve pick = null; Piece pickPiece = null; double pickLen = -1.0; bool pickSameLayer = false;
                    foreach (Curve c in curves)
                    {
                        if (used.Contains(c)) continue;
                        Piece pc = ToPiece(c);
                        if (pc == null) continue;
                        Piece oriented = null;
                        if (atEnd)
                        {
                            if (pc.Start.GetDistanceTo(tip) <= JoinTolerance) oriented = pc;
                            else if (pc.End.GetDistanceTo(tip) <= JoinTolerance) oriented = pc.Reversed();
                        }
                        else
                        {
                            if (pc.End.GetDistanceTo(tip) <= JoinTolerance) oriented = pc;
                            else if (pc.Start.GetDistanceTo(tip) <= JoinTolerance) oriented = pc.Reversed();
                        }
                        if (oriented == null) continue;
                        bool same = false;
                        try { same = string.Equals(c.Layer ?? "", layer, StringComparison.OrdinalIgnoreCase); } catch { }
                        double len = CurveLength(c);
                        // Uu tien doan cung layer voi doan tim dai nhat, sau do doan dai hon.
                        if (pick == null || (same && !pickSameLayer) || (same == pickSameLayer && len > pickLen))
                        { pick = c; pickPiece = oriented; pickLen = len; pickSameLayer = same; }
                    }
                    if (pick == null) continue;
                    used.Add(pick);
                    if (atEnd)
                    {
                        for (int i = 1; i < pickPiece.Points.Count; i++) chain.Points.Add(pickPiece.Points[i]);
                        chain.Bulges.AddRange(pickPiece.Bulges);
                    }
                    else
                    {
                        var pts = new List<Point2d>(pickPiece.Points);
                        pts.RemoveAt(pts.Count - 1);
                        chain.Points.InsertRange(0, pts);
                        chain.Bulges.InsertRange(0, pickPiece.Bulges);
                    }
                    pieces++;
                    totalLength += pickLen;
                    extended = true;
                }
            }
            if (pieces < 2) return null;
            var result = new Polyline(chain.Points.Count);
            for (int i = 0; i < chain.Points.Count; i++)
                result.AddVertexAt(i, chain.Points[i], i < chain.Bulges.Count ? chain.Bulges[i] : 0.0, 0.0, 0.0);
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
                    r.Vertices.ToString(CultureInfo.InvariantCulture), r.Updated ? "CAP_NHAT" : "TAO_MOI",
                    r.Pieces.ToString(CultureInfo.InvariantCulture))
                : Reply("LOI", r.Error);
        }

        /// <summary>
        /// (BHTTDT91STAKES route-handle max-offset) ->
        /// ("OK" "station|rawdist|offset|x|y|type|handle|text|layer|confidence" ...).
        /// </summary>
        [LispFunction("BHTTDT91STAKES")]
        public static ResultBuffer Stakes(ResultBuffer args)
        {
            string route = ""; double maxOffset = 100.0; int index = 0;
            if (args != null)
                foreach (TypedValue value in args)
                {
                    if (index == 0) route = Convert.ToString(value.Value, CultureInfo.InvariantCulture);
                    else if (index == 1) double.TryParse(Convert.ToString(value.Value, CultureInfo.InvariantCulture), NumberStyles.Float, CultureInfo.InvariantCulture, out maxOffset);
                    index++;
                }
            Document doc = AcApp.DocumentManager.MdiActiveDocument;
            if (doc == null) return Reply("LOI", "không có bản vẽ đang mở");
            try
            {
                var candidates = Tdt91Stakes.Scan(doc.Database, route, maxOffset);
                var values = new List<string> { "OK" };
                foreach (var c in candidates)
                    values.Add(string.Join("|", new[]
                    {
                        c.Station.ToString("0.###", CultureInfo.InvariantCulture), c.RawDistance.ToString("0.####", CultureInfo.InvariantCulture),
                        c.Offset.ToString("0.###", CultureInfo.InvariantCulture), c.X.ToString("0.####", CultureInfo.InvariantCulture),
                        c.Y.ToString("0.####", CultureInfo.InvariantCulture), c.EntityType, c.Handle, c.Text, c.Layer,
                        c.Confidence.ToString(CultureInfo.InvariantCulture)
                    }));
                return Reply(values.ToArray());
            }
            catch (System.Exception ex) { return Reply("LOI", "không đọc được cọc TDT: " + ex.Message); }
        }

        private static ResultBuffer Reply(params string[] values)
        {
            var rb = new ResultBuffer();
            foreach (string value in values) rb.Add(new TypedValue((int)LispDataType.Text, value ?? ""));
            return rb;
        }
    }
}
