using System;
using System.Globalization;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Xml;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Colors;
using Autodesk.AutoCAD.Runtime;
using BHT.Core;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace BHT.Bridge
{
    // These six vectors are traced from the labelled QCVN figures, independent of legacy TDT aliases.
    public static class SignCorrections
    {
        private static readonly System.Collections.Generic.Dictionary<string, XmlElement> Vectors = LoadVectors();
        private static System.Collections.Generic.Dictionary<string, XmlElement> LoadVectors()
        {
            var xml = new XmlDocument(); xml.XmlResolver = null;
            using (var stream = typeof(SignCorrections).Assembly.GetManifestResourceStream("BHT.SignVectors.xml")) xml.Load(stream);
            return xml.SelectNodes("/signs/sign").Cast<XmlElement>().ToDictionary(x => x.GetAttribute("code"), StringComparer.OrdinalIgnoreCase);
        }
        public static string Canonical(string code)
        {
            string value = SignPresentation.BaseCode(code).ToUpperInvariant();
            if (value == "W.239") return "W.239a";
            if (value == "R.415") return "R.415a";
            return SignPresentation.BaseCode(code);
        }
        public static string Ensure(Database db, string code)
        {
            XmlElement sign;
            if (!Vectors.TryGetValue(Canonical(code), out sign)) return null;
            string name = TdtSignLibrary.WrapperName(code);
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                if (table.Has(name)) return name;
                table.UpgradeOpen();
                var block = new BlockTableRecord { Name = name }; table.Add(block); tr.AddNewlyCreatedDBObject(block, true);
                if (Canonical(code).StartsWith("W.", StringComparison.OrdinalIgnoreCase))
                {
                    FillPlate(tr, block, new[] { new Point2d(-1.04,.6), new Point2d(1.04,.6), new Point2d(0,2.4) }, 1);
                    FillPlate(tr, block, new[] { new Point2d(-.84,.72), new Point2d(.84,.72), new Point2d(0,2.18) }, 2);
                }
                else
                {
                    double half = double.Parse(sign.GetAttribute("width"), CultureInfo.InvariantCulture) / 2;
                    FillPlate(tr, block, new[] { new Point2d(-half,.6), new Point2d(half,.6), new Point2d(half,2.4), new Point2d(-half,2.4) }, 5);
                    var frame = new Polyline { Closed = true, ConstantWidth = .012, Color = Ink(7) };
                    foreach (var point in new[] { new Point2d(-half+.025,.625), new Point2d(half-.025,.625), new Point2d(half-.025,2.375), new Point2d(-half+.025,2.375) }) frame.AddVertexAt(frame.NumberOfVertices, point, 0, 0, 0);
                    block.AppendEntity(frame); tr.AddNewlyCreatedDBObject(frame, true);
                }
                foreach (XmlElement shape in sign.SelectNodes("shape"))
                {
                    short color = short.Parse(shape.GetAttribute("color"), CultureInfo.InvariantCulture);
                    var loops = new System.Collections.Generic.List<ObjectId>();
                    foreach (XmlElement loop in shape.SelectNodes("loop"))
                    {
                        var line = new Polyline { Closed = true, Color = Ink(color) };
                        foreach (string point in loop.InnerText.Split(';'))
                        {
                            var xy = point.Split(','); line.AddVertexAt(line.NumberOfVertices, new Point2d(double.Parse(xy[0], CultureInfo.InvariantCulture), double.Parse(xy[1], CultureInfo.InvariantCulture)), 0, 0, 0);
                        }
                        block.AppendEntity(line); tr.AddNewlyCreatedDBObject(line, true); loops.Add(line.ObjectId);
                    }
                    if (loops.Count == 0) continue;
                    var hatch = new Hatch { Color = Ink(color), HatchStyle = HatchStyle.Normal };
                    block.AppendEntity(hatch); tr.AddNewlyCreatedDBObject(hatch, true); hatch.SetHatchPattern(HatchPatternType.PreDefined, "SOLID");
                    for (int i = 0; i < loops.Count; i++) hatch.AppendLoop(i == 0 ? HatchLoopTypes.External : HatchLoopTypes.Default, new ObjectIdCollection(new[] { loops[i] }));
                    hatch.EvaluateHatch(true);
                }
                if (Canonical(code).Equals("W.239b", StringComparison.OrdinalIgnoreCase))
                {
                    string value = SignPresentation.MetreValue(code); if (value == "") value = "4.5";
                    AddText(tr, block, value + " m", 0, 1.30, .25, 1.1, 250, db.Textstyle);
                }
                var pole = new Line(Point3d.Origin, new Point3d(0, .6, 0)) { ColorIndex = 7 }; block.AppendEntity(pole); tr.AddNewlyCreatedDBObject(pole, true);
                var foot = new Circle(Point3d.Origin, Vector3d.ZAxis, .06) { ColorIndex = 7 }; block.AppendEntity(foot); tr.AddNewlyCreatedDBObject(foot, true);
                tr.Commit(); return name;
            }
        }
        private static Color Ink(short color)
        {
            if (color == 7) return Color.FromRgb(255,255,255);
            if (color == 250) return Color.FromRgb(0,0,0);
            if (color == 5) return Color.FromRgb(0,118,190);
            return Color.FromColorIndex(ColorMethod.ByAci, color);
        }
        private static void FillPlate(Transaction tr, BlockTableRecord block, Point2d[] points, short color)
        {
            var border = new Polyline { Closed = true, Color = Ink(color) };
            for (int i = 0; i < points.Length; i++) border.AddVertexAt(i, points[i], 0, 0, 0);
            block.AppendEntity(border); tr.AddNewlyCreatedDBObject(border, true);
            var hatch = new Hatch { Color = Ink(color) }; block.AppendEntity(hatch); tr.AddNewlyCreatedDBObject(hatch, true);
            hatch.SetHatchPattern(HatchPatternType.PreDefined,"SOLID"); hatch.AppendLoop(HatchLoopTypes.External,new ObjectIdCollection(new[] { border.ObjectId })); hatch.EvaluateHatch(true);
        }
        private static void AddText(Transaction tr, BlockTableRecord block, string value, double x, double y, double height, double width, short color, ObjectId style, bool white = false)
        {
            // Font selection/conversion is supplied by the Lisp display layer for user-entered Unicode.
            var text = new DBText { TextString = value, Height = height, WidthFactor = Math.Min(1, width / Math.Max(.01, value.Length * height * .7)), ColorIndex = color, TextStyleId = style,
                HorizontalMode = TextHorizontalMode.TextCenter, VerticalMode = TextVerticalMode.TextVerticalMid, AlignmentPoint = new Point3d(x, y, 0) };
            block.AppendEntity(text); tr.AddNewlyCreatedDBObject(text, true); text.AdjustAlignment(block.Database);
            if (white || color == 250) text.Color = Ink(white ? (short)7 : color);
            if (value.Length > 0)
            {
                var bounds = text.GeometricExtents; double actual = bounds.MaxPoint.X - bounds.MinPoint.X;
                if (actual > width) { text.WidthFactor *= width / actual; text.AdjustAlignment(block.Database); }
            }
        }
        private static string TextKey(string prefix, string value)
        {
            using (var hash = SHA256.Create()) return prefix + BitConverter.ToString(hash.ComputeHash(Encoding.UTF8.GetBytes(value))).Replace("-", "").Substring(0, 24);
        }
        public static string Bridge(Database db, string bridge, string station, string road, string styleName)
        {
            string name = TextKey("BHT_I439_V0610_", bridge + "\n" + station + "\n" + road + "\n" + styleName);
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead); if (table.Has(name)) return name;
                var styles = (TextStyleTable)tr.GetObject(db.TextStyleTableId, OpenMode.ForRead);
                ObjectId style = styles.Has(styleName) ? styles[styleName] : db.Textstyle;
                table.UpgradeOpen(); var block = new BlockTableRecord { Name = name }; table.Add(block); tr.AddNewlyCreatedDBObject(block, true);
                var frame = new Polyline { Closed = true, Color = Ink(7) };
                frame.AddVertexAt(0, new Point2d(-1.8, .6), 0, 0, 0); frame.AddVertexAt(1, new Point2d(1.8, .6), 0, 0, 0); frame.AddVertexAt(2, new Point2d(1.8, 2.4), 0, 0, 0); frame.AddVertexAt(3, new Point2d(-1.8, 2.4), 0, 0, 0);
                block.AppendEntity(frame); tr.AddNewlyCreatedDBObject(frame, true);
                var hatch = new Hatch { Color = Ink(5) }; block.AppendEntity(hatch); tr.AddNewlyCreatedDBObject(hatch, true); hatch.SetHatchPattern(HatchPatternType.PreDefined, "SOLID"); hatch.AppendLoop(HatchLoopTypes.External, new ObjectIdCollection(new[] { frame.ObjectId })); hatch.EvaluateHatch(true);
                AddText(tr, block, bridge, 0, 1.83, .38, 3.3, 7, style, true);
                AddText(tr, block, string.Join("   ", new[] { station, road }.Where(x => !string.IsNullOrWhiteSpace(x))), 0, 1.11, .25, 3.3, 7, style, true);
                var pole = new Line(Point3d.Origin, new Point3d(0, .6, 0)) { ColorIndex = 7 }; block.AppendEntity(pole); tr.AddNewlyCreatedDBObject(pole, true);
                tr.Commit(); return name;
            }
        }
        public static string Milestone(Database db, string km)
        {
            int number;
            if (!int.TryParse(km, out number) || number < 0 || number > 99999) throw new ArgumentException("Số Km phải là số nguyên từ 0 đến 99999.");
            string name = "BHT_KH_COT_KM_V0610_" + number;
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead); if (table.Has(name)) return name;
                var source = (BlockTableRecord)tr.GetObject(table["BHT_KH_COT_KM_V043"], OpenMode.ForRead);
                table.UpgradeOpen(); var block = new BlockTableRecord { Name = name }; table.Add(block); tr.AddNewlyCreatedDBObject(block, true);
                ObjectId style = db.Textstyle;
                foreach (ObjectId id in source)
                {
                    var entity = tr.GetObject(id, OpenMode.ForRead) as Entity; if (entity == null) continue;
                    var text = entity as DBText; if (text != null && text.TextString == "KM") { style = text.TextStyleId; continue; }
                    var copy = (Entity)entity.Clone(); block.AppendEntity(copy); tr.AddNewlyCreatedDBObject(copy, true);
                }
                AddText(tr, block, "KM", .82, .34, .28, 1.3, 7, style);
                AddText(tr, block, number.ToString(CultureInfo.InvariantCulture), .82, -.24, .48, 1.3, 7, style);
                tr.Commit(); return name;
            }
        }
    }
    public static class SignCorrectionFunctions
    {
        [LispFunction("BHTBRIDGESIGN")]
        public static string Bridge(ResultBuffer args)
        {
            var a = args.AsArray(); return SignCorrections.Bridge(AcApp.DocumentManager.MdiActiveDocument.Database, Convert.ToString(a[0].Value), Convert.ToString(a[1].Value), Convert.ToString(a[2].Value), Convert.ToString(a[3].Value));
        }
        [LispFunction("BHTMILESTONE")]
        public static string Milestone(ResultBuffer args) { return SignCorrections.Milestone(AcApp.DocumentManager.MdiActiveDocument.Database, Convert.ToString(args.AsArray()[0].Value)); }
    }
}
