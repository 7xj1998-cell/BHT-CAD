using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using BHT.Core;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace BHT.Bridge
{
    public sealed class TdtSignEntry
    {
        public string Code { get; set; }
        public string Description { get; set; }
        public string Group { get; set; }
        public string SourceDrawing { get; set; }
        public string Shape { get; set; }
        public bool HasVector { get; set; }
        public string Provider { get; set; }
        public string PreviewPath { get; set; }
        /// <summary>5.0: ten lay tu muc khac cung ma trong Bienbao.xml (vd "R.E,9a"); rong = ten goc cua muc.</summary>
        public string NameFrom { get; set; }

        public TdtSignEntry()
        {
            Code = ""; Description = ""; Group = ""; SourceDrawing = ""; Shape = ""; NameFrom = "";
        }

        public override string ToString()
        {
            if (string.IsNullOrWhiteSpace(Description)) return Code + " — (chưa có tên trong thư viện)";
            return Code + " — " + Description + (string.IsNullOrEmpty(NameFrom) ? "" : " (tên theo " + NameFrom + ")");
        }
    }

    public sealed class TdtSignImportResult
    {
        public bool Ok;
        public string Error = "";
        public string BlockName = "";
        public string SourceBlock = "";
        public string Description = "";
        public string SourceDrawing = "";
        public double FaceScale = 1.0;
    }

    /// <summary>
    /// Doc thu vien bien bao TDT da cai tren may. BHT chi tao cache trong LocalAppData
    /// va clone block duoc chon vao DWG; khong sua thu muc cai dat TDT.
    /// Mat bien cao 1.8 don vi CAD; bien phu chuan hoa theo chieu lon nhat.
    /// Hatch giu thu tu tuong doi trong nguon va nam duoi cac net/text.
    /// </summary>
    public static class TdtSignLibrary
    {
        private static readonly object Gate = new object();
        private static List<TdtSignEntry> _catalog;
        private static string _root;
        private static string _cache;
        private static readonly string[] DrawingNames =
        {
            "Bien bao cam.dwg",
            "Bien bao nguy hiem.dwg",
            "Bien hieu lenh.dwg",
            "Bien chi dan.dwg",
            "Bien phu.dwg"
        };

        public const double StandardFaceHeight = 1.8;
        public const double DefaultPostHeight = 0.6;

        public static string InstalledRoot
        {
            get { lock (Gate) { if (string.Equals(Environment.GetEnvironmentVariable("BHT_SIGN_PROVIDER"), "BUILTIN", StringComparison.OrdinalIgnoreCase)) return ""; if (_root == null) _root = Environment.GetEnvironmentVariable("BHT_TDT_ROOT") ?? FindRoot(); return _root ?? ""; } }
        }

        public static void ReloadCatalog() { lock (Gate) { _root = null; _catalog = null; _cache = null; BhtSignLibrary.Reload(); } }

        public static List<TdtSignEntry> GetCatalog()
        {
            if (BhtSignLibrary.Root != "")
            {
                var ads = BhtSignLibrary.GetCatalog();
                // Keep BHT's parameterized clearance sign when no corresponding ADS DWG exists.
                if (!ads.Any(e => e.Code.Equals("W.239b", StringComparison.OrdinalIgnoreCase)))
                    ads.Add(new TdtSignEntry { Code = "W.239b", Description = "Chiều cao tĩnh không thực tế", Group = "Biển nguy hiểm", HasVector = true, Provider = "BHT" });
                return ads;
            }
            lock (Gate)
            {
                if (InstalledRoot == "") return BuiltInFallback(); if (_catalog != null) return new List<TdtSignEntry>(_catalog);
                _catalog = LoadCatalog(InstalledRoot);
                return new List<TdtSignEntry>(_catalog);
            }
        }

        /// <summary>5.0: tim khi go - khong dau, khong phan biet hoa, tren ma + ten (BHT.Core.SignSearch).</summary>
        public static List<TdtSignEntry> Search(string query, int max)
        {
            var items = GetCatalog().Select(x => new SignItem(x.Code, x.Description) { Tag = x }).ToList();
            return SignSearch.Filter(items, query, max).Select(x => (TdtSignEntry)x.Tag).ToList();
        }

        /// <summary>Thong ke ten: tong, co ten goc, ten bo sung theo ma cung thu vien, con thieu.</summary>
        public static int[] NameCoverage()
        {
            var all = GetCatalog();
            int alias = all.Count(x => !string.IsNullOrEmpty(x.NameFrom));
            int missing = all.Count(x => string.IsNullOrWhiteSpace(x.Description));
            return new[] { all.Count, all.Count - alias - missing, alias, missing };
        }

        public static TdtSignEntry Find(string code)
        {
            if (SignPresentation.ValidationError(code) != "") return null;
            if (BhtSignLibrary.Root != "")
            {
                var ads = BhtSignLibrary.Find(code);
                if (ads != null) return ads;
                // Ambiguous old IE.456a/b/c names have no one-to-one ADS numbered equivalent.
                // Use the original TDT face when installed, rather than pick another variant.
                if (InstalledRoot != "")
                {
                    string legacyKey = Normalize(SignPresentation.BaseCode(code));
                    var legacy = LoadCatalog(InstalledRoot).FirstOrDefault(e => Normalize(e.Code) == legacyKey);
                    if (legacy != null) return legacy;
                }
            }
            if (SignPresentation.Speed(code, "").HasValue) code = SignPresentation.SpeedBase(code);
            string key = Normalize(SignPresentation.BaseCode(code));
            if (key == "") return null;
            key = Normalize(SignCorrections.Canonical(code));
            var all = GetCatalog();
            var exact = all.FirstOrDefault(x => Normalize(x.Code) == key);
            if (exact != null) return exact;
            // An omitted letter may select the first variant; extra suffixes never select another sign.
            return all.Where(x => Normalize(x.Code).StartsWith(key, StringComparison.Ordinal)
                    && System.Text.RegularExpressions.Regex.IsMatch(Normalize(x.Code).Substring(key.Length), @"^[A-Z]+$"))
                .OrderBy(x => Normalize(x.Code).Length).FirstOrDefault();
        }

        public static string SuggestedDescription(string code)
        {
            var e = Find(code);
            return e == null ? "" : e.Description;
        }

        public static string WrapperName(string code)
        {
            string key = SignSearch.CodeKey(SignCorrections.Canonical(code)).ToUpperInvariant();
            var sb = new StringBuilder(key == "IE472A" || key == "IE472B" ? "BHT_TDT_V0629_" : key == "R415A" || key == "R415B" ? "BHT_TDT_V0631_" : key == "W207A" || key.StartsWith("DP134") || key.StartsWith("R306") ? "BHT_TDT_V0626_" : key == "W239A" ? "BHT_TDT_V0620_" : SignPresentation.WeightValue(code) != "" ? "BHT_TDT_V0619_" : "BHT_TDT_V0613_");
            if (BhtSignLibrary.Root != "") sb = new StringBuilder(key == "I449" ? "BHT_SIGN_V0642_" : "BHT_SIGN_V0633_");
            bool underscore = false;
            foreach (char c0 in (code ?? "").Trim().ToUpperInvariant())
            {
                char c = c0;
                if ((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9'))
                {
                    sb.Append(c); underscore = false;
                }
                else if (!underscore)
                {
                    sb.Append('_'); underscore = true;
                }
            }
            string value = sb.ToString().TrimEnd('_');
            return value == "BHT_TDT" ? "BHT_TDT_CHUA_XAC_DINH" : value;
        }

        public static TdtSignImportResult EnsureBlock(Database destination, string code)
        {
            var result = new TdtSignImportResult { BlockName = WrapperName(code), FaceScale = 1.0 };
            if (destination == null) { result.Error = "không có bản vẽ đích"; return result; }
            result.Error = SignPresentation.ValidationError(code);
            if (result.Error != "") return result;
            if (SignPresentation.WeightValue(code) != "")
            {
                try { result.BlockName = SignCorrections.TruckWeight(destination, code); result.Ok = true; result.Description = SuggestedDescription(code); }
                catch (System.Exception ex) { result.Error = "Không tạo được biển trọng lượng: " + ex.Message; }
                return result;
            }
            if (BhtSignLibrary.Root != "")
            {
                var ads = BhtSignLibrary.Import(destination, code);
                if (ads != null) return ads;
            }
            string corrected = SignCorrections.Ensure(destination, code);
            if (corrected != null) { result.Ok = true; result.BlockName = corrected; result.Description = SuggestedDescription(code); result.SourceBlock = "QCVN 41:2024 " + SignCorrections.Canonical(code); return result; }
            var entry = Find(code);
            if (entry == null)
            {
                // A saved vector remains usable on a machine without the complete TDT catalog.
                if (InstalledRoot == "" && HasBlock(destination, result.BlockName)) { result.Ok = true; return result; }
                result.Error = "mã " + code + " không có trong danh mục TDT"; return result;
            }
            result.Description = entry.Description;
            result.SourceDrawing = entry.SourceDrawing;
            if (HasBlock(destination, result.BlockName)) { result.Ok = true; return result; }

            string cache;
            try { cache = EnsureCache(); }
            catch (System.Exception ex) { result.Error = ex.Message; return result; }
            string sourcePath = ResolveDrawing(cache, entry.SourceDrawing);
            if (sourcePath == null)
            {
                result.Error = "TDT có tên " + entry.Code + " trong danh mục nhưng không có DWG nguồn " + entry.SourceDrawing;
                return result;
            }

            try
            {
                using (var source = new Database(false, true))
                {
                    source.ReadDwgFile(sourcePath, FileOpenMode.OpenForReadAndAllShare, false, "");
                    source.CloseInput(true);
                    ObjectId sourceId;
                    string sourceName;
                    using (var tr = source.TransactionManager.StartTransaction())
                    {
                        var bt = (BlockTable)tr.GetObject(source.BlockTableId, OpenMode.ForRead);
                        sourceName = ResolveSourceBlock(bt, tr, entry.Code, code);
                        if (sourceName == null)
                        {
                            result.Error = "không tìm thấy hình block cho " + entry.Code + " trong " + entry.SourceDrawing;
                            return result;
                        }
                        sourceId = bt[sourceName];
                        result.SourceBlock = sourceName;

                        var map = new IdMapping();
                        source.WblockCloneObjects(new ObjectIdCollection(new[] { sourceId }), destination.BlockTableId,
                            map, DuplicateRecordCloning.MangleName, false);
                        var mapped = map[sourceId];
                        if (!mapped.IsCloned || mapped.Value.IsNull)
                        {
                            result.Error = "AutoCAD không clone được block TDT " + sourceName;
                            return result;
                        }
                        result.FaceScale = CreateWrapper(destination, mapped.Value, result.BlockName, code, sourceName);
                        tr.Commit();
                    }
                }
                result.Ok = HasBlock(destination, result.BlockName);
                if (!result.Ok) result.Error = "đã clone nhưng không tạo được block " + result.BlockName;
            }
            catch (System.Exception ex)
            {
                result.Error = "không nạp được block TDT: " + ex.Message;
            }
            return result;
        }

        // Clone through a private database so nested definitions are never shared with filled signs.
        public static string EnsureOutlineBlock(Database db, string sourceName)
        {
            string name = sourceName + "_NOFILL_V0633";
            if (HasBlock(db, name)) return name;
            using (var scratch = new Database(true, true))
            {
                ObjectId sourceId;
                using (var tr = db.TransactionManager.StartTransaction())
                {
                    var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                    sourceId = bt[sourceName];
                    tr.Commit();
                }
                var map = new IdMapping();
                db.WblockCloneObjects(new ObjectIdCollection(new[] { sourceId }), scratch.BlockTableId, map, DuplicateRecordCloning.MangleName, false);
                ObjectId privateId = map[sourceId].Value;
                using (var native = db.TransactionManager.StartOpenCloseTransaction())
                using (var tr = scratch.TransactionManager.StartTransaction())
                {
                    var block = (BlockTableRecord)tr.GetObject(privateId, OpenMode.ForWrite);
                    block.Name = name;
                    BhtSignLibrary.RestoreDrawOrder(native, tr, sourceId, privateId, map, new HashSet<ObjectId>());
                    SignPrintPresentation.TagMissing(tr, privateId, new HashSet<ObjectId>());
                    RemoveFill(tr, privateId, new HashSet<ObjectId>());
                    tr.Commit();
                }
                map = new IdMapping();
                scratch.WblockCloneObjects(new ObjectIdCollection(new[] { privateId }), db.BlockTableId, map, DuplicateRecordCloning.MangleName, false);
                using (var native = scratch.TransactionManager.StartOpenCloseTransaction())
                using (var tr = db.TransactionManager.StartTransaction())
                {
                    BhtSignLibrary.RestoreDrawOrder(native, tr, privateId, map[privateId].Value, map, new HashSet<ObjectId>());
                    var block = (BlockTableRecord)tr.GetObject(map[privateId].Value, OpenMode.ForWrite);
                    block.Name = name; tr.Commit();
                }
            }
            return name;
        }

        private static void RemoveFill(Transaction tr, ObjectId bid, HashSet<ObjectId> seen)
        {
            if (!seen.Add(bid)) return;
            var block = (BlockTableRecord)tr.GetObject(bid, OpenMode.ForWrite);
            var outlines = new List<Entity>();
            var cutoutInk = new List<Hatch>();
            var frames = new List<Hatch>();
            foreach(var pair in SignPrintPresentation.BorderPairs(tr,bid)) {
                var outer=tr.GetObject(pair.Item1,OpenMode.ForRead) as Hatch;
                var inner=tr.GetObject(pair.Item2,OpenMode.ForRead) as Hatch;
                if(outer==null || inner==null || !outer.Normal.IsEqualTo(inner.Normal) || Math.Abs(outer.Elevation-inner.Elevation)>1e-8)continue;
                var frame=(Hatch)outer.Clone();frame.ColorIndex=0;frame.LayerId=block.Database.LayerZero;frame.HatchStyle=HatchStyle.Normal;
                var loop=inner.GetLoopAt(0);
                if(inner.NumberOfLoops>1) {
                    // Multi-loop white disks/panels are split by the native pictogram.
                    // The border follows their complete hull, not one half of the disk.
                    var hull=SignPrintPresentation.HullOutline(inner);var bounds=inner.GeometricExtents;
                    var center=new Point2d((bounds.MinPoint.X+bounds.MaxPoint.X)/2,(bounds.MinPoint.Y+bounds.MaxPoint.Y)/2);
                    double radius=(bounds.MaxPoint.X-bounds.MinPoint.X)/2;
                    if(Math.Abs(bounds.MaxPoint.Y-bounds.MinPoint.Y-radius*2)<radius*1e-5 && hull.Count>12 && hull.All(p=>Math.Abs(p.GetDistanceTo(center)-radius)<radius*.02)) {
                        var curves=new Curve2dCollection();curves.Add(new CircularArc2d(center,radius));var types=new IntegerCollection();types.Add((int)HatchEdgeType.CircularArc);
                        frame.AppendLoop(HatchLoopTypes.Default,curves,types);
                    } else {
                        var vertices=new Point2dCollection();var bulges=new DoubleCollection();foreach(var point in hull){vertices.Add(point);bulges.Add(0);}
                        frame.AppendLoop(HatchLoopTypes.Default,vertices,bulges);
                    }
                } else if(loop.IsPolyline) {
                    var vertices=new Point2dCollection();var bulges=new DoubleCollection();
                    foreach(BulgeVertex vertex in loop.Polyline){vertices.Add(vertex.Vertex);bulges.Add(vertex.Bulge);}
                    frame.AppendLoop(HatchLoopTypes.Default,vertices,bulges);
                } else {
                    var types=new IntegerCollection();
                    foreach(Curve2d curve in loop.Curves)types.Add((int)(curve is LineSegment2d ? HatchEdgeType.Line : curve is CircularArc2d ? HatchEdgeType.CircularArc : curve is EllipticalArc2d ? HatchEdgeType.EllipticalArc : HatchEdgeType.Spline));
                    frame.AppendLoop(HatchLoopTypes.Default,loop.Curves,types);
                }
                frames.Add(frame);
            }
            var paper = new List<Tuple<Entity,ObjectId>>();
            var boundaries = block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead) as Curve).Where(e => e != null && e.Visible).ToList();
            foreach (ObjectId id in block)
            {
                var e = tr.GetObject(id, OpenMode.ForRead) as Entity;
                if(SignPrintPresentation.NeedsPaper(e)) {
                    var b=e.GeometricExtents;var mask=new Solid(new Point3d(b.MinPoint.X,b.MinPoint.Y,b.MinPoint.Z),new Point3d(b.MaxPoint.X,b.MinPoint.Y,b.MinPoint.Z),new Point3d(b.MinPoint.X,b.MaxPoint.Y,b.MinPoint.Z),new Point3d(b.MaxPoint.X,b.MaxPoint.Y,b.MinPoint.Z));
                    mask.Color=Autodesk.AutoCAD.Colors.Color.FromRgb(255,255,255);paper.Add(Tuple.Create((Entity)mask,id));
                }
                e.UpgradeOpen(); e.ColorIndex = 0; e.LayerId = block.Database.LayerZero;
                if ((e is Hatch || e is Solid) && SignPrintPresentation.Role(e) != SignPrintPresentation.Background)
                {
                    if (SignPrintPresentation.Role(e) == SignPrintPresentation.Void || SignPrintPresentation.Role(e) == SignPrintPresentation.Paper || SignPrintPresentation.Role(e) == SignPrintPresentation.Backing) e.Color = Autodesk.AutoCAD.Colors.Color.FromRgb(255,255,255);
                    continue;
                }
                var stroke = e as Polyline;
                if(stroke != null && stroke.Closed) { stroke.ConstantWidth=0; for(int vertex=0;vertex<stroke.NumberOfVertices;vertex++) {stroke.SetStartWidthAt(vertex,0);stroke.SetEndWidthAt(vertex,0);} }
                var note = e as MText; if(note != null) { note.BackgroundFill=false; note.Contents=System.Text.RegularExpressions.Regex.Replace(note.Contents,@"\[Cc]\d+;", ""); }
                var nested = e as BlockReference;
                if (nested != null)
                {
                    foreach (ObjectId aid in nested.AttributeCollection)
                    {
                        var attribute = (AttributeReference)tr.GetObject(aid, OpenMode.ForWrite);
                        attribute.ColorIndex = 0; attribute.LayerId = block.Database.LayerZero;
                    }
                    RemoveFill(tr, nested.BlockTableRecord, seen);
                }
                var hatch = e as Hatch;
                var solid = e as Solid;
                if (hatch == null && solid == null) continue;
                if (hatch != null)
                {
                    if(SignPrintPresentation.HasInkHoles(hatch)) {
                        // The native blue disk uses an inner hatch loop as its white arrow.
                        // Keep that exact geometry as filled ink when the disk is hidden.
                        for(int inner=1;inner<hatch.NumberOfLoops;inner++) {
                            var hole=hatch.GetLoopAt(inner);if(!hole.IsPolyline)throw new InvalidOperationException("Không đọc được đường bao biểu tượng rỗng.");
                            var ink=new Hatch { Normal=hatch.Normal,Elevation=hatch.Elevation,ColorIndex=0,LayerId=block.Database.LayerZero };
                            ink.SetHatchPattern(HatchPatternType.PreDefined,"SOLID");
                            var vertices=new Point2dCollection();var bulges=new DoubleCollection();
                            foreach(BulgeVertex vertex in hole.Polyline){vertices.Add(vertex.Vertex);bulges.Add(vertex.Bulge);}
                            ink.AppendLoop(HatchLoopTypes.External,vertices,bulges);cutoutInk.Add(ink);
                        }
                    }
                    for (int n = 0; n < hatch.NumberOfLoops; n++)
                    {
                        var loop = hatch.GetLoopAt(n);
                        if (!loop.IsPolyline)
                        {
                            var edge = new Polyline { Closed = true, Normal = hatch.Normal, Elevation = hatch.Elevation, ColorIndex = 0, LayerId = hatch.LayerId };
                            foreach (Curve2d curve in loop.Curves)
                            {
                                var arc = curve as CircularArc2d;
                                if (arc != null && (arc.StartPoint - arc.EndPoint).Length < 1e-8)
                                {
                                    var center = new Point3d(arc.Center.X, arc.Center.Y, hatch.Elevation);
                                    var existing=boundaries.FirstOrDefault(c => SameCircle(c, center, arc.Radius));
                                    if (existing==null)outlines.Add(new Circle(center, hatch.Normal, arc.Radius) { ColorIndex = 0, LayerId = hatch.LayerId, LineWeight=LineWeight.LineWeight025 });
                                    else {existing.UpgradeOpen();existing.LineWeight=LineWeight.LineWeight025;}
                                    continue;
                                }
                                var points = curve.GetSamplePoints(curve is LineSegment2d ? 2 : arc != null ? 9 : 129);
                                int step = arc != null ? 2 : 1;
                                for (int v = 0; v < points.Length - 1; v += step)
                                {
                                    double bulge = 0;
                                    if (arc != null)
                                    {
                                        var chord = points[v + 2] - points[v]; var mid = points[v + 1] - points[v];
                                        bulge = -2 * (chord.X * mid.Y - chord.Y * mid.X) / chord.LengthSqrd;
                                    }
                                    edge.AddVertexAt(edge.NumberOfVertices, points[v], bulge, 0, 0);
                                }
                            }
                            var existingEdge=boundaries.OfType<Polyline>().FirstOrDefault(p=>SameBoundary(p,edge));
                            if(edge.NumberOfVertices>1 && existingEdge==null){edge.LineWeight=LineWeight.LineWeight025;outlines.Add(edge);}
                            else {if(existingEdge!=null){existingEdge.UpgradeOpen();existingEdge.LineWeight=LineWeight.LineWeight025;}edge.Dispose();}
                            continue;
                        }
                        var line = new Polyline { Closed = true, Normal = hatch.Normal, Elevation = hatch.Elevation, ColorIndex = hatch.ColorIndex, LayerId = hatch.LayerId };
                        for (int v = 0; v < loop.Polyline.Count; v++)
                        { var point = loop.Polyline[v]; line.AddVertexAt(v, point.Vertex, point.Bulge, 0, 0); }
                        var existingLine=boundaries.OfType<Polyline>().FirstOrDefault(p=>SameBoundary(p,line));
                        if(existingLine==null){line.LineWeight=LineWeight.LineWeight025;outlines.Add(line);}
                        else {existingLine.UpgradeOpen();existingLine.LineWeight=LineWeight.LineWeight025;line.Dispose();}
                    }
                }
                if (solid != null)
                {
                    var line = new Polyline { Closed = true, Normal = solid.Normal, ColorIndex = solid.ColorIndex, LayerId = solid.LayerId };
                    int[] order = { 0, 1, 3, 2 };
                    foreach (int v in order)
                    { var point = solid.GetPointAt((short)v).Convert2d(new Plane(Point3d.Origin, solid.Normal)); line.AddVertexAt(line.NumberOfVertices, point, 0, 0, 0); }
                    line.Elevation = solid.GetPointAt(0).GetAsVector().DotProduct(solid.Normal);
                    var existingLine=boundaries.OfType<Polyline>().FirstOrDefault(p=>SameBoundary(p,line));
                    if(existingLine==null){line.LineWeight=LineWeight.LineWeight025;outlines.Add(line);}
                    else {existingLine.UpgradeOpen();existingLine.LineWeight=LineWeight.LineWeight025;line.Dispose();}
                }
                e.UpgradeOpen(); e.Visible = false;
            }
            foreach (var line in outlines) { block.AppendEntity(line); tr.AddNewlyCreatedDBObject(line, true); }
            foreach(var ink in cutoutInk){block.AppendEntity(ink);tr.AddNewlyCreatedDBObject(ink,true);ink.EvaluateHatch(true);SignPrintPresentation.MarkDerivedInk(tr,ink.ObjectId);}
            foreach(var frame in frames){block.AppendEntity(frame);tr.AddNewlyCreatedDBObject(frame,true);frame.EvaluateHatch(true);SignPrintPresentation.MarkFrame(tr,frame.ObjectId);}
            foreach(var mask in paper) {
                block.AppendEntity(mask.Item1);tr.AddNewlyCreatedDBObject(mask.Item1,true);SignPrintPresentation.MarkPaper(tr,mask.Item1.ObjectId);
                var draw=(DrawOrderTable)tr.GetObject(block.DrawOrderTableId,OpenMode.ForWrite);draw.MoveBelow(new ObjectIdCollection(new[]{mask.Item1.ObjectId}),mask.Item2);
            }
            // Some native white speed disks precede the equally white lane arrows.
            // In monochrome the disks must cover those arrows, below rings and values.
            var printOrder=(DrawOrderTable)tr.GetObject(block.DrawOrderTableId,OpenMode.ForWrite);
            var entities=printOrder.GetFullDrawOrder(0).Cast<ObjectId>().Select(id=>(Entity)tr.GetObject(id,OpenMode.ForRead)).ToList();
            foreach(var disk in entities.Where(e=>SignPrintPresentation.Role(e)==SignPrintPresentation.Backing)) {
                var b=disk.GeometricExtents;double height=b.MaxPoint.Y-b.MinPoint.Y;
                var arrow=entities.LastOrDefault(e=>e is Hatch && SignPrintPresentation.Role(e)==SignPrintPresentation.Ink
                    && e.GeometricExtents.MaxPoint.Y-e.GeometricExtents.MinPoint.Y>height*1.5
                    && e.GeometricExtents.MaxPoint.X>b.MinPoint.X && e.GeometricExtents.MinPoint.X<b.MaxPoint.X);
                if(arrow!=null)printOrder.MoveAbove(new ObjectIdCollection(new[]{disk.ObjectId}),arrow.ObjectId);
            }
        }

        private static bool SameCircle(Curve curve, Point3d center, double radius)
        {
            if (!curve.Closed) return false;
            try
            {
                for (int i = 0; i < 8; i++)
                {
                    double angle = i * Math.PI / 4;
                    var point = center + new Vector3d(radius * Math.Cos(angle), radius * Math.Sin(angle), 0);
                    if (point.DistanceTo(curve.GetClosestPointTo(point, false)) > 1e-7) return false;
                }
                return true;
            }
            catch (Autodesk.AutoCAD.Runtime.Exception) { return false; }
        }

        private static bool SameBoundary(Polyline first, Polyline second)
        {
            if (!first.Closed || !second.Closed || Math.Abs(first.Elevation - second.Elevation) > 1e-7) return false;
            try
            {
                var a = first.GeometricExtents; var b = second.GeometricExtents;
                if (a.MinPoint.DistanceTo(b.MinPoint) > 1e-7 || a.MaxPoint.DistanceTo(b.MaxPoint) > 1e-7) return false;
                // Hatch can reverse a loop or split a circular edge into several arcs.
                foreach (var pair in new[] { new[] { first, second }, new[] { second, first } })
                    for (int i = 0; i < pair[0].NumberOfVertices * 2; i++)
                    {
                        var point = pair[0].GetPointAtParameter(i * .5);
                        if (point.DistanceTo(pair[1].GetClosestPointTo(point, false)) > 1e-7) return false;
                    }
                return true;
            }
            catch (Autodesk.AutoCAD.Runtime.Exception) { return false; }
        }

        private static bool HasBlock(Database db, string name)
        {
            using (var tr = db.TransactionManager.StartOpenCloseTransaction())
            {
                var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                bool value = bt.Has(name);
                tr.Commit();
                return value;
            }
        }

        internal static double CreateWrapper(Database db, ObjectId clonedId, string wrapperName, string code, string sourceName, bool preserveSourceOrder = false)
        {
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                if (bt.Has(wrapperName)) { tr.Commit(); return 1.0; }

                var cloned = (BlockTableRecord)tr.GetObject(clonedId, OpenMode.ForWrite);
                PrepareFace(tr, clonedId, new HashSet<ObjectId>(), code, preserveSourceOrder);
                Extents3d bounds;
                using (var probe = new BlockReference(Point3d.Origin, clonedId)) bounds = probe.GeometricExtents;
                double height = bounds.MaxPoint.Y - bounds.MinPoint.Y;
                if (double.IsNaN(height) || double.IsInfinity(height) || height <= 1e-8)
                    throw new InvalidOperationException("mặt biển không có kích thước bao hợp lệ");
                double width = bounds.MaxPoint.X - bounds.MinPoint.X;
                double targetHeight = SignPresentation.BaseCode(code).Equals("I.449",StringComparison.OrdinalIgnoreCase) ? .65 : StandardFaceHeight;
                double scale = targetHeight / (SignPresentation.BaseCode(code).StartsWith("S.", StringComparison.OrdinalIgnoreCase) ? Math.Max(width, height) : height);
                string sourceAlias = (preserveSourceOrder ? "BHT_ADS_SRC_" : "BHT_TDT_SRC_") + SafeToken(sourceName);
                int suffix = 1;
                string candidate = sourceAlias;
                while (bt.Has(candidate)) candidate = sourceAlias + "_" + (suffix++).ToString(CultureInfo.InvariantCulture);
                cloned.Name = candidate;

                bt.UpgradeOpen();
                var wrapper = new BlockTableRecord { Name = wrapperName, Origin = Point3d.Origin };
                bt.Add(wrapper);
                tr.AddNewlyCreatedDBObject(wrapper, true);

                var post = new Line(Point3d.Origin, new Point3d(0.0, DefaultPostHeight, 0.0));
                post.ColorIndex = 7;
                wrapper.AppendEntity(post); tr.AddNewlyCreatedDBObject(post, true);
                var foot = new Circle(Point3d.Origin, Vector3d.ZAxis, 0.06);
                foot.ColorIndex = 7;
                wrapper.AppendEntity(foot); tr.AddNewlyCreatedDBObject(foot, true);

                var face = new BlockReference(new Point3d(
                    -(bounds.MinPoint.X + bounds.MaxPoint.X) * 0.5 * scale,
                    DefaultPostHeight - bounds.MinPoint.Y * scale, -bounds.MinPoint.Z * scale), clonedId)
                {
                    ScaleFactors = new Scale3d(scale)
                };
                wrapper.AppendEntity(face); tr.AddNewlyCreatedDBObject(face, true);

                var attributes = new List<KeyValuePair<AttributeDefinition, AttributeReference>>();
                foreach (ObjectId id in cloned)
                {
                    var def = tr.GetObject(id, OpenMode.ForRead) as AttributeDefinition;
                    if (def == null || def.Constant || def.Invisible) continue;
                    var attr = new AttributeReference();
                    attr.SetAttributeFromBlock(def, face.BlockTransform);
                    attr.TextString = AttributeValue(code, def.TextString, def.Tag, preserveSourceOrder);
                    face.AttributeCollection.AppendAttribute(attr);
                    tr.AddNewlyCreatedDBObject(attr, true);
                    if (preserveSourceOrder) attr.AdjustAlignment(db);
                    attributes.Add(new KeyValuePair<AttributeDefinition, AttributeReference>(def, attr));
                }
                // A few ADS templates recompute their nested text extents only after insertion.
                // Normalize the completed face, including its attribute references.
                if (preserveSourceOrder)
                {
                    for (int attempt = 0; attempt < 3; attempt++)
                    {
                        var completed = face.GeometricExtents;
                        double faceWidth = completed.MaxPoint.X - completed.MinPoint.X;
                        double faceHeight = completed.MaxPoint.Y - completed.MinPoint.Y;
                        double largest = SignPresentation.BaseCode(code).StartsWith("S.", StringComparison.OrdinalIgnoreCase) ? Math.Max(faceWidth, faceHeight) : faceHeight;
                        double ratio = targetHeight / largest;
                        if (Math.Abs(ratio - 1) < 1e-8 && Math.Abs(completed.MinPoint.Y - DefaultPostHeight) < 1e-8) break;
                        scale *= ratio;
                        face.ScaleFactors = new Scale3d(scale);
                        face.Position = new Point3d((face.Position.X - (completed.MinPoint.X + completed.MaxPoint.X) / 2) * ratio,
                            DefaultPostHeight + (face.Position.Y - completed.MinPoint.Y) * ratio, face.Position.Z * ratio);
                        foreach (var pair in attributes)
                        {
                            pair.Value.SetAttributeFromBlock(pair.Key, face.BlockTransform);
                            pair.Value.TextString = AttributeValue(code, pair.Key.TextString, pair.Key.Tag, true);
                            pair.Value.AdjustAlignment(db);
                        }
                    }
                }
                tr.Commit();
                return scale;
            }
        }

        // Traverse nested definitions too; preserve hatch-to-hatch order from the source.
        private static void PrepareFace(Transaction tr, ObjectId blockId, HashSet<ObjectId> seen, string code, bool preserveSourceOrder = false)
        {
            if (!seen.Add(blockId)) return;
            var block = (BlockTableRecord)tr.GetObject(blockId, OpenMode.ForRead);
            // TDT stores some dimensions as two texts, e.g. "3." and "5".
            var metrePrefix = block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead) as DBText)
                .FirstOrDefault(text => text != null && System.Text.RegularExpressions.Regex.IsMatch(text.TextString.Trim(), @"^\d+[.,]$"));
            var zoneParts = block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead) as DBText)
                .Where(text => text != null && System.Text.RegularExpressions.Regex.IsMatch(text.TextString.Trim(), @"^\d{1,2}:\d{2}$"))
                .OrderBy(text => text.Position.X).ThenByDescending(text => text.Position.Y).ToList();
            var draw = (DrawOrderTable)tr.GetObject(block.DrawOrderTableId, OpenMode.ForWrite);
            var hatches = new ObjectIdCollection();
            foreach (ObjectId id in draw.GetFullDrawOrder(0))
            {
                var entity = tr.GetObject(id, OpenMode.ForRead) as Entity;
                if (entity is Hatch) hatches.Add(id);
                var nested = entity as BlockReference;
                if (nested != null) PrepareFace(tr, nested.BlockTableRecord, seen, code, preserveSourceOrder);
                var definition = entity as AttributeDefinition;
                if (preserveSourceOrder && definition != null)
                {
                    string content = AttributeValue(code, definition.TextString, definition.Tag, true);
                    string zone = SignPresentation.ZoneTime(code);
                    if (zone != "" && zoneParts.Count == 2 && zoneParts.Contains(definition)) content = zone.Split('-')[zoneParts.IndexOf(definition)];
                    if (content != definition.TextString)
                    {
                        definition.UpgradeOpen();
                        if (zoneParts.Contains(definition) && content.Length > definition.TextString.Length)
                            definition.WidthFactor *= (double)definition.TextString.Length / content.Length;
                        definition.TextString = content; definition.AdjustAlignment(block.Database);
                    }
                }
                bool whiteLayerFill = entity is Hatch && entity.ColorIndex == 256 && ((LayerTableRecord)tr.GetObject(entity.LayerId, OpenMode.ForRead)).Color.ColorIndex == 7;
                if (entity.ColorIndex == 7 || whiteLayerFill) { entity.UpgradeOpen(); entity.Color = Autodesk.AutoCAD.Colors.Color.FromRgb(255,255,255); }
                else if (entity.ColorIndex == 250) { entity.UpgradeOpen(); entity.Color = Autodesk.AutoCAD.Colors.Color.FromRgb(0,0,0); }
                var zoneDash = entity as MText;
                if (preserveSourceOrder && SignPresentation.HasZoneTime(code) && zoneDash != null && zoneDash.Text.Trim() == "-")
                { zoneDash.UpgradeOpen(); zoneDash.Color = Autodesk.AutoCAD.Colors.Color.FromRgb(0,0,0); }
                var speed = SignPresentation.Speed(code, "");
                bool metres = SignPresentation.MetreValue(code) != "";
                if (!speed.HasValue && !metres && !SignPresentation.HasZoneTime(code)) continue;
                var text = entity as DBText;
                var mtext = entity as MText;
                int number;
                string value = text != null ? text.TextString : (mtext != null ? mtext.Text : "");
                string hours = SignPresentation.ReplaceZoneTime(code, value);
                if (hours != value) { entity.UpgradeOpen(); if (text != null) text.TextString = hours; else if (mtext != null) mtext.Contents = hours; }
                // Only numeric labels, never code/name/dimensional annotations.
                if (speed.HasValue && int.TryParse(value.Trim(), out number) && number >= 5 && number <= 130)
                {
                    entity.UpgradeOpen();
                    if (text != null) text.TextString = speed.Value.ToString(CultureInfo.InvariantCulture);
                    else if (mtext != null) mtext.Contents = speed.Value.ToString(CultureInfo.InvariantCulture);
                }
                if (metres)
                {
                    if (text != null && text == metrePrefix)
                    {
                        text.UpgradeOpen(); text.Visible = false;
                        var prefixDefinition = text as AttributeDefinition;
                        if (prefixDefinition != null) prefixDefinition.Invisible = true;
                        continue;
                    }
                    string changed = SignPresentation.ReplaceMetres(code, value);
                    if (changed != value)
                    {
                        entity.UpgradeOpen();
                        if (text != null)
                        {
                            text.TextString = changed;
                            if (metrePrefix != null)
                            {
                                text.Position = metrePrefix.Position;
                                if (text.HorizontalMode != TextHorizontalMode.TextLeft) text.AlignmentPoint = metrePrefix.AlignmentPoint;
                            }
                        }
                        else if (mtext != null) mtext.Contents = changed;
                    }
                }            }
            // Larger background fills must precede smaller foreground symbols.
            // Moving all hatches together preserves the defective legacy TDT order.
            if (!preserveSourceOrder)
            {
                foreach (ObjectId id in hatches.Cast<ObjectId>().OrderBy(x => FillArea((Entity)tr.GetObject(x, OpenMode.ForRead))))
                    draw.MoveToBottom(new ObjectIdCollection(new[] { id }));
                foreach (ObjectId id in hatches) if (RedForeground((Entity)tr.GetObject(id, OpenMode.ForRead))) draw.MoveToTop(new ObjectIdCollection(new[] { id }));
            }
        }

        private static bool RedForeground(Entity entity)
        {
            var ink = entity.Color; if (entity.ColorIndex != 1 && (ink.Red < 200 || ink.Green > 80 || ink.Blue > 80)) return false;
            try { var b = entity.GeometricExtents; double a = (b.MaxPoint.X-b.MinPoint.X)*(b.MaxPoint.Y-b.MinPoint.Y); return a > 1e-8 && FillArea(entity)/a < .6; } catch { return false; }
        }
        private static double FillArea(Entity entity)
        {
            try { var h = entity as Hatch; if (h != null) return Math.Abs(h.Area); var b = entity.GeometricExtents; return (b.MaxPoint.X - b.MinPoint.X) * (b.MaxPoint.Y - b.MinPoint.Y); }
            catch (Autodesk.AutoCAD.Runtime.Exception) { return 0; }
        }

        internal static string AttributeValue(string code, string defaultValue, string tag, bool ads = false)
        {
            var speed = SignPresentation.Speed(code, "");
            if (ads)
            {
                string key = (tag ?? "").ToUpperInvariant();
                if (key == "V" && SignPresentation.SpeedBase(code) != "")
                    return (speed ?? (SignPresentation.SpeedBase(code) == "R.306" ? 30 : 50)).ToString(CultureInfo.InvariantCulture);
                string metres = SignPresentation.MetreValue(code); if (metres == "") metres = SignPresentation.MetreDefault(code);
                if (key == "DISTANCE" && metres != "") return metres + " m";
                if (SignPresentation.BaseCode(code).Equals("W.239b", StringComparison.OrdinalIgnoreCase) && key == "H") return metres + " m";
                if (SignPresentation.BaseCode(code).Equals("S.509a", StringComparison.OrdinalIgnoreCase))
                {
                    if (key == "DESC_1") return "CHIỀU CAO";
                    if (key == "DESC_2") return "AN TOÀN";
                    if (key == "DESC_3") return metres + " m";
                }
            }
            int number;
            if (speed.HasValue && int.TryParse((defaultValue ?? "").Trim(), out number))
                return speed.Value.ToString(CultureInfo.InvariantCulture);
            defaultValue = SignPresentation.ReplaceZoneTime(code, SignPresentation.ReplaceMetres(code, defaultValue));
            return string.IsNullOrWhiteSpace(defaultValue) ? (ads || string.IsNullOrWhiteSpace(tag) ? "" : tag) : defaultValue;
        }

        private static string ResolveSourceBlock(BlockTable bt, Transaction tr, string catalogCode, string enteredCode)
        {
            var names = new List<string>();
            foreach (ObjectId id in bt)
            {
                var btr = (BlockTableRecord)tr.GetObject(id, OpenMode.ForRead);
                if (!btr.IsLayout && !btr.IsAnonymous && !btr.IsFromExternalReference) names.Add(btr.Name);
            }
            string catalog = Normalize(catalogCode);
            string entered = Normalize(enteredCode);
            Func<string, string> n = Normalize;
            var exact = names.FirstOrDefault(x => n(x) == catalog) ?? names.FirstOrDefault(x => n(x) == entered);
            if (exact != null) return exact;
            return names.Where(x => n(x).StartsWith(catalog, StringComparison.Ordinal) || catalog.StartsWith(n(x), StringComparison.Ordinal)
                                 || entered.StartsWith(n(x), StringComparison.Ordinal))
                        .OrderBy(x => Math.Abs(n(x).Length - catalog.Length)).ThenBy(x => x, StringComparer.OrdinalIgnoreCase)
                        .FirstOrDefault();
        }

        private static string EnsureCache()
        {
            lock (Gate)
            {
                string root = InstalledRoot;
                if (root == "") throw new InvalidOperationException("không tìm thấy thư viện biển báo trong TDT 9.1/2022 đã cài");
                string setPath = Path.Combine(root, "Data", "Bien bao", "bienbao.set");
                var info = new FileInfo(setPath);
                string cacheRoot = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "BHT", "TDT-Signs", info.Length.ToString(CultureInfo.InvariantCulture) + "-" + info.LastWriteTimeUtc.Ticks.ToString(CultureInfo.InvariantCulture));
                bool ready = DrawingNames.All(x => File.Exists(Path.Combine(cacheRoot, x)));
                if (!ready)
                {
                    Directory.CreateDirectory(cacheRoot);
                    ExtractContainer(setPath, cacheRoot);
                }
                _cache = cacheRoot;
                return _cache;
            }
        }

        private static void ExtractContainer(string setPath, string folder)
        {
            byte[] bytes = File.ReadAllBytes(setPath);
            if (bytes.Length < 12) throw new InvalidDataException("bienbao.set không hợp lệ");
            int count = BitConverter.ToInt32(bytes, 4);
            if (count != DrawingNames.Length) throw new InvalidDataException("cấu trúc bienbao.set chưa được hỗ trợ; dùng thư viện BHT tích hợp");
            int offset = 8;
            for (int i = 0; i < count; i++)
            {
                if (offset + 4 > bytes.Length) throw new InvalidDataException("bienbao.set bị thiếu dữ liệu");
                int size = BitConverter.ToInt32(bytes, offset);
                int start = offset + 4;
                int end = start + size;
                if (size < 0 || size > bytes.Length - start) throw new InvalidDataException("kích thước mục trong bienbao.set không hợp lệ");
                if (size > 0 && i < DrawingNames.Length)
                {
                    string signature = Encoding.ASCII.GetString(bytes, start, Math.Min(6, size));
                    if (!signature.StartsWith("AC10", StringComparison.Ordinal)) throw new InvalidDataException("mục TDT không phải DWG");
                    using (var f = new FileStream(Path.Combine(folder, DrawingNames[i]), FileMode.Create, FileAccess.Write, FileShare.Read))
                        f.Write(bytes, start, size);
                }
                offset = end;
            }
            if (offset != bytes.Length) throw new InvalidDataException("bienbao.set còn dữ liệu chưa đọc");
        }

        private static string ResolveDrawing(string cache, string sourceDrawing)
        {
            string wanted = NormalizeFile(sourceDrawing);
            foreach (string name in DrawingNames)
                if (NormalizeFile(name) == wanted) return Path.Combine(cache, name);
            return null;
        }

        private static List<TdtSignEntry> LoadCatalog(string root)
        {
            var list = new List<TdtSignEntry>();
            if (string.IsNullOrEmpty(root)) return BuiltInFallback();
            string path = Path.Combine(root, "Data", "Bien bao", "Bienbao.xml");
            try
            {
                var doc = new XmlDocument();
                doc.XmlResolver = null;
                var settings = new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null };
                using (var reader = XmlReader.Create(path, settings)) doc.Load(reader);
                foreach (XmlElement group in doc.SelectNodes("//*[@dataSource]"))
                {
                    string groupName = group.GetAttribute("tên"); if (groupName == "") groupName = group.GetAttribute("name");
                    string source = group.GetAttribute("dataSource");
                    foreach (XmlNode node in group.ChildNodes)
                    {
                        var sign = node as XmlElement;
                        if (sign == null || string.IsNullOrWhiteSpace(sign.GetAttribute("tên"))) continue;
                        list.Add(new TdtSignEntry
                        {
                            Code = sign.GetAttribute("tên"),
                            Description = sign.GetAttribute("môtả"),
                            Shape = sign.GetAttribute("hìnhdạng"),
                            Group = groupName,
                            SourceDrawing = source,
                            HasVector = SignCorrections.Supports(sign.GetAttribute("tên")) || DrawingNames.Any(x => NormalizeFile(x) == NormalizeFile(source))
                        });
                    }
                }
            }
            catch { return BuiltInFallback(); }
            // 5.0: muc nhom "theo thong le quoc te" ("Biển số E,9a") khong co ten -> lay ten cua muc
            // cung ma trong chinh Bienbao.xml (vd "R.E,9a"). Khong tu dat ten; muc khong doi chieu duoc de trong.
            try
            {
                var items = list.Select(x => new SignItem(x.Code, x.Description) { Tag = x }).ToList();
                Dictionary<SignItem, string> aliasOf;
                SignSearch.FillMissingNames(items, out aliasOf);
                foreach (var kv in aliasOf) { var e = (TdtSignEntry)kv.Key.Tag; e.Description = kv.Key.Name; e.NameFrom = kv.Value; }
            }
            catch { }
            if (list.Count == 0) return BuiltInFallback();
            list.RemoveAll(x => x.Code == "W.239" || x.Code == "R.415");
            foreach (var item in new[] { new[] { "IE.472a", "Trạm thu phí" }, new[] { "IE.472b", "Trạm thu phí" }, new[] { "W.239a", "Đường cáp điện ở phía trên" }, new[] { "W.239b", "Chiều cao tĩnh không thực tế" }, new[] { "R.415a", "Biển gộp làn đường theo phương tiện" }, new[] { "R.415b", "Kết thúc làn đường theo phương tiện" } })
                if (!list.Any(x => x.Code.Equals(item[0], StringComparison.OrdinalIgnoreCase))) list.Add(new TdtSignEntry { Code = item[0], Description = item[1], Group = item[0].StartsWith("W.") ? "Biển nguy hiểm" : item[0].StartsWith("IE.") ? "Biển chỉ dẫn trên đường cao tốc" : "Biển hiệu lệnh", HasVector = true });
            return list.OrderBy(x => SignSortKey(x.Code), StringComparer.OrdinalIgnoreCase).ToList();
        }

        private static List<TdtSignEntry> BuiltInFallback()
        {
            string[][] data =
            {
                new[] { "IE.472a", "Trạm thu phí" }, new[] { "IE.472b", "Trạm thu phí" }, new[] { "DP.134", "Hết hạn chế tốc độ tối đa" }, new[] { "R.306", "Tốc độ tối thiểu cho phép" }, new[] { "R.415a", "Biển gộp làn đường theo phương tiện" }, new[] { "R.415b", "Kết thúc làn đường theo phương tiện" }, new[] { "W.239b", "Chiều cao tĩnh không thực tế" }, new[] { "I.439", "Tên cầu" }, new[] { "W.207a", "Giao nhau với đường không ưu tiên" }, new[] { "W.209", "Giao nhau có tín hiệu đèn" },
                new[] { "W.239a", "Đường cáp điện phía trên" }, new[] { "W.245a", "Đi chậm" },
                new[] { "W.201", "Chỗ ngoặt nguy hiểm" }, new[] { "W.225", "Trẻ em" },
                new[] { "R.412a", "Làn đường dành riêng cho từng loại xe" }, new[] { "I.414a", "Chỉ hướng đường" },
                new[] { "I.423a", "Đường người đi bộ sang ngang" }, new[] { "I.428", "Trạm cung cấp xăng dầu" },
                new[] { "I.434a", "Bến xe buýt" }, new[] { "P.115", "Hạn chế trọng tải toàn bộ xe" },
                new[] { "P.119", "Hạn chế chiều dài xe" }, new[] { "P.124a", "Cấm quay đầu xe" },
                new[] { "P.125", "Cấm vượt" }, new[] { "P.127", "Tốc độ tối đa cho phép" }
                , new[] { "S.501", "Phạm vi tác dụng của biển" }, new[] { "S.502", "Khoảng cách tới đối tượng báo hiệu" }, new[] { "S.509a", "Chiều cao an toàn" }
            };
            return data.Select(x => new TdtSignEntry { Code = x[0], Description = x[1], HasVector = SignCorrections.Supports(x[0]), Group = x[0].StartsWith("S.") ? "Biển phụ" : x[0].StartsWith("W.") ? "Biển nguy hiểm" : x[0].StartsWith("P.") ? "Biển cấm" : x[0].StartsWith("R.") ? "Biển hiệu lệnh" : "Biển chỉ dẫn" }).ToList();
        }

        private static string FindRoot()
        {
            return Tdt91Installation.FindRoot();
        }

        private static string Normalize(string value)
        {
            var sb = new StringBuilder();
            foreach (char c in (value ?? "").ToUpperInvariant()) if (char.IsLetterOrDigit(c)) sb.Append(c);
            return sb.ToString();
        }

        private static string NormalizeFile(string value)
        {
            return Normalize(Path.GetFileNameWithoutExtension(value ?? ""));
        }

        private static string SafeToken(string value)
        {
            string v = WrapperName(value);
            return v.StartsWith("BHT_TDT_", StringComparison.Ordinal) ? v.Substring(8) : v;
        }

        private static string SignSortKey(string code)
        {
            string c = (code ?? "").ToUpperInvariant();
            // 5.0: nhom quoc te "Biển số ..." xep sau cac ma QCVN (truoc day dung dau danh sach)
            if (TextSearch.Fold(c).StartsWith("bien so", StringComparison.Ordinal)) c = "~" + c;
            return c.PadRight(24, ' ');
        }
    }

    public static class TdtSignLispFunctions
    {
        [LispFunction("BHTSIGNBOUNDS")]
        public static ResultBuffer Bounds(ResultBuffer args)
        {
            string name = Convert.ToString(args.AsArray()[0].Value);
            var db = AcApp.DocumentManager.MdiActiveDocument.Database;
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                using (var probe = new BlockReference(Point3d.Origin, table[name]))
                {
                    var b = probe.GeometricExtents;
                    return new ResultBuffer(new TypedValue((int)LispDataType.Double, b.MinPoint.X), new TypedValue((int)LispDataType.Double, b.MinPoint.Y), new TypedValue((int)LispDataType.Double, b.MaxPoint.X), new TypedValue((int)LispDataType.Double, b.MaxPoint.Y));
                }
            }
        }

        [LispFunction("BHTSIGNOUTLINE")]
        public static string Outline(ResultBuffer args)
        {
            if (args == null || args.AsArray().Length != 1) throw new ArgumentException("Cần tên block biển báo");
            return TdtSignLibrary.EnsureOutlineBlock(AcApp.DocumentManager.MdiActiveDocument.Database, Convert.ToString(args.AsArray()[0].Value));
        }

        [LispFunction("BHTTDTBLOCK")]
        public static ResultBuffer ImportSign(ResultBuffer args)
        {
            string code = "", description = ""; int index = 0;
            if (args != null)
                foreach (TypedValue value in args)
                {
                    if (index++ == 0) code = Convert.ToString(value.Value, CultureInfo.InvariantCulture);
                    else description = Convert.ToString(value.Value, CultureInfo.InvariantCulture);
                }
            code = SignPresentation.ResolveCode(code, description);
            var doc = AcApp.DocumentManager.MdiActiveDocument;
            if (doc == null) return Reply("LOI", "không có bản vẽ đang mở");
            var r = TdtSignLibrary.EnsureBlock(doc.Database, code);
            return r.Ok
                ? Reply("OK", r.BlockName, r.Description, r.SourceBlock, r.FaceScale.ToString("0.######", CultureInfo.InvariantCulture))
                : Reply("LOI", r.Error);
        }
        [LispFunction("BHTADSBLOCK")]
        public static ResultBuffer ImportAdsSign(ResultBuffer args) { return ImportSign(args); }
        [LispFunction("BHTMETRETEXT")]
        public static string MetreText(ResultBuffer args)
        {
            var values = args.AsArray();
            return SignPresentation.ReplaceMetres(Convert.ToString(values[0].Value), Convert.ToString(values[1].Value));
        }

        /// <summary>
        /// 5.0: (BHTSIGNSEARCH "di cham" [max]) -> ("OK" "W.245a|Đi chậm" ...). Tim khong dau tren ma + ten
        /// cua danh muc bien TDT (dung cho BHTBLOCK / BHTBBDANHMUC). Khong co TDT -> danh muc noi bo.
        /// </summary>
        [LispFunction("BHTSIGNSEARCH")]
        public static ResultBuffer SearchSigns(ResultBuffer args)
        {
            string q = ""; int max = 30, i = 0;
            if (args != null)
                foreach (TypedValue value in args)
                {
                    if (i == 0) q = Convert.ToString(value.Value, CultureInfo.InvariantCulture);
                    else if (i == 1) { try { max = Convert.ToInt32(value.Value, CultureInfo.InvariantCulture); } catch { } }
                    i++;
                }
            var l = new List<string> { "OK" };
            try { foreach (var e in TdtSignLibrary.Search(q, max)) l.Add(e.Code + "|" + e.Description); }
            catch (System.Exception ex) { return Reply("LOI", ex.Message); }
            return Reply(l.ToArray());
        }

        private static ResultBuffer Reply(params string[] values)
        {
            var rb = new ResultBuffer();
            foreach (string value in values) rb.Add(new TypedValue((int)LispDataType.Text, value ?? ""));
            return rb;
        }
    }
}

