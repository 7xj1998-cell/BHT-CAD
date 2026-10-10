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
    // Native corrections leave the original TDT resources untouched.
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
            string key = SignSearch.CodeKey(SignPresentation.BaseCode(code)).ToUpperInvariant();
            string speedBase = SignPresentation.SpeedBase(code);
            if (speedBase == "DP.134" || speedBase == "R.306") return SpeedPlate(db, code, speedBase);
            if (key == "I401" || key == "I402" || key == "IE473") return StandardPlate(db, code, key);
            if (key == "IE472A" || key == "IE472B") return TollPlate(db, code, key == "IE472A");
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
                    if (sign.GetAttribute("frame") != "source")
                    {
                        var frame = new Polyline { Closed = true, ConstantWidth = .012, Color = Ink(7) };
                        foreach (var point in new[] { new Point2d(-half+.025,.625), new Point2d(half-.025,.625), new Point2d(half-.025,2.375), new Point2d(-half+.025,2.375) }) frame.AddVertexAt(frame.NumberOfVertices, point, 0, 0, 0);
                        block.AppendEntity(frame); tr.AddNewlyCreatedDBObject(frame, true);
                    }
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
                            var xy = point.Split(','); line.AddVertexAt(line.NumberOfVertices, new Point2d(double.Parse(xy[0], CultureInfo.InvariantCulture), double.Parse(xy[1], CultureInfo.InvariantCulture)), xy.Length > 2 ? double.Parse(xy[2], CultureInfo.InvariantCulture) : 0, 0, 0);
                        }
                        block.AppendEntity(line); tr.AddNewlyCreatedDBObject(line, true); loops.Add(line.ObjectId);
                    }
                    if (loops.Count == 0) continue;
                    var hatch = new Hatch { Color = Ink(color), HatchStyle = HatchStyle.Normal };
                    block.AppendEntity(hatch); tr.AddNewlyCreatedDBObject(hatch, true); hatch.SetHatchPattern(HatchPatternType.PreDefined, "SOLID");
                    var boundaries = shape.SelectNodes("loop").Cast<XmlElement>().ToArray();
                    for (int i = 0; i < loops.Count; i++)
                    {
                        string role = boundaries[i].GetAttribute("role");
                        bool outer = role == "outer" || (role == "" && i == 0);
                        hatch.AppendLoop(outer ? HatchLoopTypes.External : HatchLoopTypes.Default, new ObjectIdCollection(new[] { loops[i] }));
                    }
                    hatch.EvaluateHatch(true);
                    var drawOrder=(DrawOrderTable)tr.GetObject(block.DrawOrderTableId,OpenMode.ForWrite);
                    drawOrder.MoveToTop(new ObjectIdCollection(new[] {hatch.ObjectId}));
                    drawOrder.MoveToTop(new ObjectIdCollection(loops.ToArray()));
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
        public static bool Supports(string code)
        {
            string key = SignSearch.CodeKey(SignPresentation.BaseCode(code)).ToUpperInvariant();
            return SignPresentation.SpeedBase(code) == "DP.134" || SignPresentation.SpeedBase(code) == "R.306" || key == "I401" || key == "I402" || key == "IE473" || key == "IE472A" || key == "IE472B" || Vectors.ContainsKey(Canonical(code));
        }
        private static void CircleFill(Transaction tr, BlockTableRecord block, double radius, short color)
        {
            var circle = new Circle(new Point3d(0,1.5,0), Vector3d.ZAxis, radius) { Color = Ink(color) };
            block.AppendEntity(circle); tr.AddNewlyCreatedDBObject(circle,true);
            var hatch = new Hatch { Color = Ink(color) }; block.AppendEntity(hatch); tr.AddNewlyCreatedDBObject(hatch,true);
            hatch.SetHatchPattern(HatchPatternType.PreDefined,"SOLID"); hatch.AppendLoop(HatchLoopTypes.External,new ObjectIdCollection(new[] {circle.ObjectId})); hatch.EvaluateHatch(true);
        }
        private static string SpeedPlate(Database db, string code, string baseCode)
        {
            string name = TdtSignLibrary.WrapperName(code);
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead); if(table.Has(name)) return name;
                table.UpgradeOpen(); var block = new BlockTableRecord { Name=name }; table.Add(block); tr.AddNewlyCreatedDBObject(block,true);
                bool end = baseCode == "DP.134";
                CircleFill(tr,block,.9,5); if(end) CircleFill(tr,block,.79,7);
                var styles = (TextStyleTable)tr.GetObject(db.TextStyleTableId,OpenMode.ForRead);
                ObjectId style;
                if(styles.Has("BHT_GT2")) style=styles["BHT_GT2"];
                else { styles.UpgradeOpen(); var font=new TextStyleTableRecord {Name="BHT_GT2",FileName="Giaothong2.ttf"};style=styles.Add(font);tr.AddNewlyCreatedDBObject(font,true); }
                int value = SignPresentation.Speed(code,"") ?? (end ? 50 : 30);
                AddText(tr,block,value.ToString(CultureInfo.InvariantCulture),0,1.5,.79,1.2,end ? (short)250 : (short)7,style,!end);
                if(end)
                    for(int i=-2;i<=2;i++)
                    {
                        double offset=i*.048, reach=Math.Sqrt(.79*.79-offset*offset), q=Math.Sqrt(.5);
                        var start = new Point2d((-reach-offset)*q,1.5+(-reach+offset)*q);
                        var finish = new Point2d((reach-offset)*q,1.5+(reach+offset)*q);
                        var stripe = new Polyline { ConstantWidth=.018, Color=Ink(250) };
                        stripe.AddVertexAt(0,start,0,0,0); stripe.AddVertexAt(1,finish,0,0,0);block.AppendEntity(stripe);tr.AddNewlyCreatedDBObject(stripe,true);
                    }
                var pole=new Line(Point3d.Origin,new Point3d(0,.6,0)) {ColorIndex=7};block.AppendEntity(pole);tr.AddNewlyCreatedDBObject(pole,true);
                var foot=new Circle(Point3d.Origin,Vector3d.ZAxis,.06) {ColorIndex=7};block.AppendEntity(foot);tr.AddNewlyCreatedDBObject(foot,true);
                tr.Commit(); return name;
            }
        }
        private static void RoundedFrame(Transaction tr, BlockTableRecord block, double bottom, double top)
        {
            const double left = -1.29, right = 1.29, radius = .05;
            double arc = Math.Tan(Math.PI / 8);
            var line = new Polyline { Closed = true, ConstantWidth = .025, Color = Ink(7) };
            var points = new[] { new Point2d(left+radius,bottom),new Point2d(right-radius,bottom),new Point2d(right,bottom+radius),new Point2d(right,top-radius),new Point2d(right-radius,top),new Point2d(left+radius,top),new Point2d(left,top-radius),new Point2d(left,bottom+radius) };
            for(int i=0;i<points.Length;i++) line.AddVertexAt(i,points[i],i%2==1 ? arc : 0,0,0);
            block.AppendEntity(line);tr.AddNewlyCreatedDBObject(line,true);
        }
        private static string TollPlate(Database db, string code, bool distance)
        {
            string name = TdtSignLibrary.WrapperName(code);
            using(var tr=db.TransactionManager.StartTransaction())
            {
                var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead); if(table.Has(name)) return name;
                table.UpgradeOpen();var block=new BlockTableRecord {Name=name};table.Add(block);tr.AddNewlyCreatedDBObject(block,true);
                double bottom=.6, offset=distance ? 0 : .62;
                FillPlate(tr,block,new[] {new Point2d(-1.33,bottom),new Point2d(1.33,bottom),new Point2d(1.33,2.4-offset),new Point2d(-1.33,2.4-offset)},3);
                RoundedFrame(tr,block,1.26-offset,2.36-offset);
                if(distance) RoundedFrame(tr,block,.64,1.23);
                var styles=(TextStyleTable)tr.GetObject(db.TextStyleTableId,OpenMode.ForRead);
                ObjectId style;
                if(styles.Has("BHT_GT2")) style=styles["BHT_GT2"];
                else { styles.UpgradeOpen();var font=new TextStyleTableRecord {Name="BHT_GT2",FileName="Giaothong2.ttf"};style=styles.Add(font);tr.AddNewlyCreatedDBObject(font,true); }
                AddText(tr,block,"TRẠM THU PHÍ",0,1.97-offset,.33,2.35,7,style,true);
                AddText(tr,block,"TOLL PLAZA",0,1.54-offset,.25,2.15,7,style,true);
                if(distance) { string value=SignPresentation.MetreValue(code); if(value=="") value=SignPresentation.MetreDefault(code);AddText(tr,block,value+" m",0,.925,.32,2.2,7,style,true); }
                var pole=new Line(Point3d.Origin,new Point3d(0,bottom,0)) {ColorIndex=7};block.AppendEntity(pole);tr.AddNewlyCreatedDBObject(pole,true);
                var foot=new Circle(Point3d.Origin,Vector3d.ZAxis,.06) {ColorIndex=7};block.AppendEntity(foot);tr.AddNewlyCreatedDBObject(foot,true);
                tr.Commit();return name;
            }
        }
        private static Point2d[] Diamond(double half)
        {
            return new[] { new Point2d(-half,1.5), new Point2d(0,1.5-half), new Point2d(half,1.5), new Point2d(0,1.5+half) };
        }
        private static string StandardPlate(Database db, string code, string key)
        {
            string name = TdtSignLibrary.WrapperName(code);
            using(var tr=db.TransactionManager.StartTransaction())
            {
                var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead); if(table.Has(name)) return name;
                table.UpgradeOpen(); var block=new BlockTableRecord {Name=name}; table.Add(block); tr.AddNewlyCreatedDBObject(block,true);
                if(key == "IE473")
                {
                    FillPlate(tr,block,new[] {new Point2d(-1.86,.6),new Point2d(1.86,.6),new Point2d(1.86,2.4),new Point2d(-1.86,2.4)},250);
                    FillPlate(tr,block,new[] {new Point2d(-1.83,.63),new Point2d(1.83,.63),new Point2d(1.83,2.37),new Point2d(-1.83,2.37)},2);
                    var styles=(TextStyleTable)tr.GetObject(db.TextStyleTableId,OpenMode.ForRead);
                    ObjectId style;
                    if(styles.Has("BHT_GT2")) style=styles["BHT_GT2"];
                    else { styles.UpgradeOpen(); var font=new TextStyleTableRecord {Name="BHT_GT2",FileName="Giaothong2.ttf"}; style=styles.Add(font); tr.AddNewlyCreatedDBObject(font,true); }
                    AddText(tr,block,"GIẢM TỐC ĐỘ",0,1.87,.46,3.35,250,style);
                    AddText(tr,block,"SLOW DOWN",0,1.12,.40,3.35,250,style);
                }
                else
                {
                    FillPlate(tr,block,Diamond(.9),250);
                    FillPlate(tr,block,Diamond(.86),7);
                    FillPlate(tr,block,Diamond(.59),250);
                    FillPlate(tr,block,Diamond(.55),2);
                    if(key == "I402") FillPlate(tr,block,new[] {new Point2d(-.65,.92),new Point2d(-.58,.85),new Point2d(.65,2.08),new Point2d(.58,2.15)},250);
                }
                var pole=new Line(Point3d.Origin,new Point3d(0,.6,0)) {ColorIndex=7};block.AppendEntity(pole);tr.AddNewlyCreatedDBObject(pole,true);
                var foot=new Circle(Point3d.Origin,Vector3d.ZAxis,.06) {ColorIndex=7};block.AppendEntity(foot);tr.AddNewlyCreatedDBObject(foot,true);
                tr.Commit();return name;
            }
        }
        private static Color Ink(short color)
        {
            if (color == 7) return Color.FromRgb(255,255,255);
            if (color == 250) return Color.FromRgb(0,0,0);
            if (color == 5) return Color.FromRgb(0,118,190);
            if (color == 3) return Color.FromRgb(0,152,65);
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
        public static string TruckWeight(Database db, string code)
        {
            string value = SignPresentation.WeightValue(code);
            if (value == "") throw new ArgumentException(SignPresentation.ValidationError(code));
            string name = TdtSignLibrary.WrapperName("S.505a@" + value);
            using (var check = db.TransactionManager.StartOpenCloseTransaction())
                if (((BlockTable)check.GetObject(db.BlockTableId, OpenMode.ForRead)).Has(name)) return name;
            var template = TdtSignLibrary.EnsureBlock(db, "S.505a");
            if (!template.Ok) throw new InvalidOperationException(template.Error);
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                var source = (BlockTableRecord)tr.GetObject(table[template.BlockName], OpenMode.ForRead);
                var face = source.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead) as BlockReference).First(e => e != null);
                var bounds = face.GeometricExtents;
                double width = bounds.MaxPoint.X - bounds.MinPoint.X, height = bounds.MaxPoint.Y - bounds.MinPoint.Y;
                var parts = new System.Collections.Generic.List<Entity>();
                FlattenTruck(face, parts);
                try
                {
                    // Remove the source plate/frame; preserve the original truck vector.
                    var truck = parts.Where(e => !(e is DBText) && e.Visible &&
                        e.GeometricExtents.MaxPoint.X - e.GeometricExtents.MinPoint.X < width * .85 &&
                        e.GeometricExtents.MaxPoint.Y - e.GeometricExtents.MinPoint.Y < height * .85 &&
                        e.GeometricExtents.MinPoint.X > bounds.MinPoint.X + width * .08 &&
                        e.GeometricExtents.MaxPoint.X < bounds.MaxPoint.X - width * .08).ToList();
                    if (truck.Count == 0) throw new InvalidOperationException("Mẫu S.505a không có hình xe hợp lệ.");
                    var truckBounds = truck[0].GeometricExtents;
                    foreach (var e in truck.Skip(1)) truckBounds.AddExtents(e.GeometricExtents);
                    double scale = Math.Min(1.18 / (truckBounds.MaxPoint.X - truckBounds.MinPoint.X), .52 / (truckBounds.MaxPoint.Y - truckBounds.MinPoint.Y));
                    var transform = Matrix3d.Displacement(new Vector3d(0, 1.34, 0)) * Matrix3d.Scaling(scale, Point3d.Origin) *
                        Matrix3d.Displacement(new Vector3d(-(truckBounds.MinPoint.X + truckBounds.MaxPoint.X) / 2,
                            -(truckBounds.MinPoint.Y + truckBounds.MaxPoint.Y) / 2, -truckBounds.MinPoint.Z));
                    table.UpgradeOpen(); var block = new BlockTableRecord { Name = name }; table.Add(block); tr.AddNewlyCreatedDBObject(block, true);
                    FillPlate(tr, block, new[] { new Point2d(-.9,.6), new Point2d(.9,.6), new Point2d(.9,1.86), new Point2d(-.9,1.86) }, 250);
                    FillPlate(tr, block, new[] { new Point2d(-.865,.635), new Point2d(.865,.635), new Point2d(.865,1.825), new Point2d(-.865,1.825) }, 7);
                    foreach (var e in truck)
                    {
                        var copy = (Entity)e.Clone(); copy.TransformBy(transform); copy.Color = Ink(250); copy.LayerId = db.LayerZero;
                        block.AppendEntity(copy); tr.AddNewlyCreatedDBObject(copy, true);
                    }
                    var styles = (TextStyleTable)tr.GetObject(db.TextStyleTableId, OpenMode.ForRead);
                    const string weightStyle = "BHT_WEIGHT_BOLD";
                    if (!styles.Has(weightStyle))
                    {
                        styles.UpgradeOpen(); var style = new TextStyleTableRecord { Name = weightStyle, FileName = "arialbd.ttf" };
                        styles.Add(style); tr.AddNewlyCreatedDBObject(style, true);
                    }
                    AddText(tr, block, value + "T", 0, .84, .24, 1.55, 250, styles[weightStyle]);
                    var pole = new Line(Point3d.Origin, new Point3d(0,.6,0)) { ColorIndex = 7 };
                    block.AppendEntity(pole); tr.AddNewlyCreatedDBObject(pole, true);
                    tr.Commit(); return name;
                }
                finally { foreach (var e in parts) e.Dispose(); }
            }
        }
        private static void FlattenTruck(Entity entity, System.Collections.Generic.List<Entity> parts)
        {
            var nested = entity as BlockReference;
            if (nested == null) { parts.Add((Entity)entity.Clone()); return; }
            var exploded = new DBObjectCollection(); nested.Explode(exploded);
            foreach (DBObject item in exploded)
                using (item) { var e = item as Entity; if (e != null) FlattenTruck(e, parts); }
        }
        public static string StreetName(Database db,string source,string value)
        {
            value=(value??"").Normalize(NormalizationForm.FormC).Trim();
            string name=TextKey("BHT_STREET_V0642_",source+"|"+value);
            using(var tr=db.TransactionManager.StartTransaction()) {
                var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);
                if(table.Has(name))return name;
                var wrapper=(BlockTableRecord)tr.GetObject(table[source],OpenMode.ForRead);
                var face=wrapper.Cast<ObjectId>().Select(id=>tr.GetObject(id,OpenMode.ForRead) as BlockReference).FirstOrDefault(r=>r!=null);
                if(face==null)throw new InvalidOperationException("Mẫu I.449 thiếu mặt biển.");
                var native=(BlockTableRecord)tr.GetObject(face.BlockTableRecord,OpenMode.ForRead);
                var def=native.Cast<ObjectId>().Select(id=>tr.GetObject(id,OpenMode.ForRead) as AttributeDefinition).FirstOrDefault(d=>d!=null && d.Tag=="NAME");
                if(def==null)throw new InvalidOperationException("Mẫu I.449 thiếu trường NAME.");
                table.UpgradeOpen();var block=new BlockTableRecord {Name=name};table.Add(block);tr.AddNewlyCreatedDBObject(block,true);
                var text=new DBText {TextString=value,Height=.3,WidthFactor=1,TextStyleId=def.TextStyleId,ColorIndex=7,
                    HorizontalMode=TextHorizontalMode.TextCenter,VerticalMode=TextVerticalMode.TextVerticalMid,
                    Position=new Point3d(0,.925,0),AlignmentPoint=new Point3d(0,.925,0)};
                block.AppendEntity(text);tr.AddNewlyCreatedDBObject(text,true);text.AdjustAlignment(db);
                double measured=value.Length==0 ? 0 : text.GeometricExtents.MaxPoint.X-text.GeometricExtents.MinPoint.X;
                double width=Math.Max(1.2,Math.Min(3.2,measured+.16));
                if(measured>width-.16){text.Height*= (width-.16)/measured;text.AdjustAlignment(db);}
                var nativeBounds=face.GeometricExtents;double originalWidth=nativeBounds.MaxPoint.X-nativeBounds.MinPoint.X;
                double ratio=width/originalWidth;
                var frameBlock=new BlockTableRecord {Name=name+"_FRAME"};table.Add(frameBlock);tr.AddNewlyCreatedDBObject(frameBlock,true);
                var shapes=new ObjectIdCollection();
                foreach(ObjectId id in ((DrawOrderTable)tr.GetObject(native.DrawOrderTableId,OpenMode.ForRead)).GetFullDrawOrder(0)) {
                    var e=tr.GetObject(id,OpenMode.ForRead) as Entity;if(e==null || e is AttributeDefinition)continue;
                    var copy=(Entity)e.Clone();copy.TransformBy(face.BlockTransform);
                    frameBlock.AppendEntity(copy);tr.AddNewlyCreatedDBObject(copy,true);shapes.Add(copy.ObjectId);
                }
                foreach(ObjectId id in wrapper) {var e=tr.GetObject(id,OpenMode.ForRead) as Entity;if(e==null || e is BlockReference)continue;
                    var copy=(Entity)e.Clone();block.AppendEntity(copy);tr.AddNewlyCreatedDBObject(copy,true);}
                ((DrawOrderTable)tr.GetObject(frameBlock.DrawOrderTableId,OpenMode.ForWrite)).SetRelativeDrawOrder(shapes);
                var frame=new BlockReference(Point3d.Origin,frameBlock.ObjectId) {ScaleFactors=new Scale3d(ratio,1,1)};
                block.AppendEntity(frame);tr.AddNewlyCreatedDBObject(frame,true);
                ((DrawOrderTable)tr.GetObject(block.DrawOrderTableId,OpenMode.ForWrite)).MoveToBottom(new ObjectIdCollection(new[] {frame.ObjectId}));
                tr.Commit();return name;
            }
        }

        public static string NamedBoard(Database db, string title, string styleName)
        {
            title = (title ?? "").Normalize(NormalizationForm.FormC).Trim();
            if (title.Length == 0) throw new ArgumentException("Nhập tên hiển thị trên bảng.");
            string name = TextKey("BHT_BOARD_V0625_", title + "\n" + styleName);
            var lines = new System.Collections.Generic.List<string>();
            string line = "";
            foreach (string word in title.Split((char[])null, StringSplitOptions.RemoveEmptyEntries))
            {
                if (line.Length > 0 && line.Length + word.Length + 1 > 24) { lines.Add(line); line = ""; }
                line += (line.Length > 0 ? " " : "") + word;
            }
            if (line.Length > 0) lines.Add(line);
            double height = Math.Max(1.8, lines.Count * .44 + .5), top = .62 + height;
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                if (table.Has(name)) return name;
                var styles = (TextStyleTable)tr.GetObject(db.TextStyleTableId, OpenMode.ForRead);
                ObjectId style = styles.Has(styleName) ? styles[styleName] : db.Textstyle;
                table.UpgradeOpen();
                var block = new BlockTableRecord { Name = name }; table.Add(block); tr.AddNewlyCreatedDBObject(block, true);
                FillPlate(tr, block, new[] { new Point2d(-2, .62), new Point2d(2, .62), new Point2d(2, top), new Point2d(-2, top) }, 5);
                var fills = new ObjectIdCollection(block.Cast<ObjectId>().Where(id => tr.GetObject(id, OpenMode.ForRead) is Hatch).ToArray());
                var frame = new Polyline { Closed = true, ConstantWidth = .025, Color = Ink(7) };
                foreach (var point in new[] { new Point2d(-1.94, .68), new Point2d(1.94, .68), new Point2d(1.94, top - .06), new Point2d(-1.94, top - .06) })
                    frame.AddVertexAt(frame.NumberOfVertices, point, 0, 0, 0);
                block.AppendEntity(frame); tr.AddNewlyCreatedDBObject(frame, true);
                bool legacy = string.Equals(System.IO.Path.GetFileName(((TextStyleTableRecord)tr.GetObject(style, OpenMode.ForRead)).FileName), "vnromanc.shx", StringComparison.OrdinalIgnoreCase);
                for (int i = 0; i < lines.Count; i++)
                    AddText(tr, block, legacy ? Tcvn3.Encode(lines[i]) : lines[i], 0,
                        .62 + height / 2 + ((lines.Count - 1) / 2.0 - i) * .44, .32, 3.65, 7, style, true);
                var pole = new Line(Point3d.Origin, new Point3d(0, .62, 0)) { Color = Ink(7) };
                block.AppendEntity(pole); tr.AddNewlyCreatedDBObject(pole, true);
                var foot = new Circle(Point3d.Origin, Vector3d.ZAxis, .06) { Color = Ink(7) };
                block.AppendEntity(foot); tr.AddNewlyCreatedDBObject(foot, true);
                ((DrawOrderTable)tr.GetObject(block.DrawOrderTableId, OpenMode.ForWrite)).MoveToBottom(fills);
                tr.Commit(); return name;
            }
        }
        public static string Bridge(Database db, string bridge, string station, string road, string styleName)
        {
            // Reuse the original TDT face, including its three frame contours,
            // background fills, proportions and Giaothong1 lettering.
            string name = TextKey(BhtSignLibrary.Root != "" ? "BHT_I439_ADS_V0631_" : "BHT_I439_V0611_", bridge + "\n" + station + "\n" + road);
            string line = SignPresentation.BridgeLine(station, road);
            var template = TdtSignLibrary.EnsureBlock(db, "I.439");
            if (!template.Ok) throw new InvalidOperationException(template.Error);
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead); if (table.Has(name)) return name;
                var source = (BlockTableRecord)tr.GetObject(table[template.BlockName], OpenMode.ForRead);
                table.UpgradeOpen(); var block = new BlockTableRecord { Name = name }; table.Add(block); tr.AddNewlyCreatedDBObject(block, true);
                foreach (ObjectId id in source)
                {
                    var entity = tr.GetObject(id, OpenMode.ForRead) as Entity; if (entity == null) continue;
                    var originalFace = entity as BlockReference;
                    if (originalFace == null) { var copy = (Entity)entity.Clone(); block.AppendEntity(copy); tr.AddNewlyCreatedDBObject(copy, true); continue; }
                    var faceSource = (BlockTableRecord)tr.GetObject(originalFace.BlockTableRecord, OpenMode.ForRead);
                    var definitions = faceSource.Cast<ObjectId>().Select(x => tr.GetObject(x, OpenMode.ForRead) as AttributeDefinition).Where(x => x != null).OrderByDescending(x => x.Position.Y).ToList();
                    if (definitions.Count != 2) throw new InvalidOperationException("Mẫu I.439 phải có hai dòng nội dung.");
                    // Flatten the original face into the new definition. Text remains
                    // Unicode and uses the source sign font rather than label SHX.
                    foreach (ObjectId item in ((DrawOrderTable)tr.GetObject(faceSource.DrawOrderTableId, OpenMode.ForRead)).GetFullDrawOrder(0))
                    {
                        var original = tr.GetObject(item, OpenMode.ForRead) as Entity;
                        if (original == null || original is AttributeDefinition) continue;
                        var copy = (Entity)original.Clone(); copy.TransformBy(originalFace.BlockTransform);
                        if (copy is Polyline || copy.Color.ColorMethod == ColorMethod.ByLayer || copy.Color.ColorMethod == ColorMethod.ByBlock) copy.Color = Ink(7);
                        block.AppendEntity(copy); tr.AddNewlyCreatedDBObject(copy, true);
                    }
                    for (int i = 0; i < definitions.Count; i++)
                    {
                        var def = definitions[i]; var text = new DBText();
                        text.SetDatabaseDefaults(db); text.TextStyleId = def.TextStyleId;
                        text.Height = def.Height * originalFace.ScaleFactors.Y; text.WidthFactor = def.WidthFactor;
                        text.Color = Ink(7); text.TextString = i == 0 ? bridge : line;
                        var center = (def.HorizontalMode == TextHorizontalMode.TextLeft ? def.Position : def.AlignmentPoint).TransformBy(originalFace.BlockTransform);
                        text.HorizontalMode = TextHorizontalMode.TextCenter; text.VerticalMode = TextVerticalMode.TextVerticalMid;
                        text.AlignmentPoint = new Point3d(0, center.Y + text.Height * .35, center.Z);
                        block.AppendEntity(text); tr.AddNewlyCreatedDBObject(text, true); text.AdjustAlignment(db);
                        var bounds = text.GeometricExtents; double width = bounds.MaxPoint.X - bounds.MinPoint.X;
                        if (width > 3.7) { text.WidthFactor *= 3.7 / width; text.AdjustAlignment(db); }
                    }
                }
                tr.Commit(); return name;
            }
        }
        public static string Milestone(Database db, string km)
        {
            int number;
            if (!int.TryParse(km, out number) || number < 0 || number > 99999) throw new ArgumentException("Số Km phải là số nguyên từ 0 đến 99999.");
            string name = "BHT_KH_COT_KM_V0611_" + number;
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
                    var copy = (Entity)entity.Clone(); copy.TransformBy(Matrix3d.Displacement(new Vector3d(-1.75, 0, 0))); block.AppendEntity(copy); tr.AddNewlyCreatedDBObject(copy, true);
                }
                AddText(tr, block, "KM", -.93, .34, .28, 1.3, 7, style);
                AddText(tr, block, number.ToString(CultureInfo.InvariantCulture), -.93, -.24, .48, 1.3, 7, style);
                tr.Commit(); return name;
            }
        }
    }
    public static class SignCorrectionFunctions
    {
        [LispFunction("BHTNAMEDBOARD")]
        public static string NamedBoard(ResultBuffer args)
        {
            var a = args.AsArray();
            return SignCorrections.NamedBoard(AcApp.DocumentManager.MdiActiveDocument.Database, Convert.ToString(a[0].Value), Convert.ToString(a[1].Value));
        }
        [LispFunction("BHTBRIDGESIGN")]
        public static string Bridge(ResultBuffer args)
        {
            var a = args.AsArray(); return SignCorrections.Bridge(AcApp.DocumentManager.MdiActiveDocument.Database, Convert.ToString(a[0].Value), Convert.ToString(a[1].Value), Convert.ToString(a[2].Value), Convert.ToString(a[3].Value));
        }
        [LispFunction("BHTMILESTONE")]
        public static string Milestone(ResultBuffer args) { return SignCorrections.Milestone(AcApp.DocumentManager.MdiActiveDocument.Database, Convert.ToString(args.AsArray()[0].Value)); }
    }
}
