using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.PlottingServices;
using BHT.Bridge;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;
public class Sign0611Probe
{
    [CommandMethod("BHTPLOT0611")]
    public static void Plot()
    {
        var doc = AcApp.DocumentManager.MdiActiveDocument;
        using (var tr = doc.Database.TransactionManager.StartTransaction())
        {
            var manager = LayoutManager.Current;
            var layout = (Layout)tr.GetObject(manager.GetLayoutId(manager.CurrentLayout), OpenMode.ForRead);
            using (var settings = new PlotSettings(layout.ModelType))
            {
                settings.CopyFrom(layout);
                var validator = PlotSettingsValidator.Current;
                validator.SetPlotConfigurationName(settings, "DWG To PDF.pc3", "ISO_full_bleed_A4_(297.00_x_210.00_MM)");
                validator.RefreshLists(settings);
                validator.SetPlotWindowArea(settings, new Extents2d(99997,99993,100020,100009));
                validator.SetPlotType(settings, Autodesk.AutoCAD.DatabaseServices.PlotType.Window);
                validator.SetUseStandardScale(settings, true); validator.SetStdScaleType(settings, StdScaleType.ScaleToFit);
                validator.SetPlotCentered(settings, true); settings.PlotPlotStyles = false;
                var info = new PlotInfo { Layout = layout.ObjectId, OverrideSettings = settings };
                var infoValidator = new PlotInfoValidator { MediaMatchingPolicy = MatchingPolicy.MatchEnabled }; infoValidator.Validate(info);
                using (var engine = PlotFactory.CreatePublishEngine())
                {
                    string pdf = Environment.GetEnvironmentVariable("BHT_QA_PDF") ?? Path.Combine(Path.GetTempPath(), "BHT-sign0610.pdf");
                    engine.BeginPlot(null, null); engine.BeginDocument(info, doc.Name, null, 1, true, pdf);
                    var page = new PlotPageInfo(); engine.BeginPage(page, info, true, null); engine.BeginGenerateGraphics(null); engine.EndGenerateGraphics(null); engine.EndPage(null); engine.EndDocument(null); engine.EndPlot(null);
                }
            }
            tr.Commit();
        }
    }
    static readonly List<string> Lines = new List<string>();
    static void Check(string name, bool ok) { Lines.Add((ok ? "PASS " : "FAIL ") + name); }
    [CommandMethod("BHTSIGN0611PROBE")]
    public static void Run()
    {
        var db = AcApp.DocumentManager.MdiActiveDocument.Database;
        try
        {
            var catalog = TdtSignLibrary.GetCatalog();
            Check("catalog-explicit-variants", new[] { "R.415a", "R.415b", "W.239a", "W.239b" }.All(c => catalog.Any(x => x.Code == c)) && !catalog.Any(x => x.Code == "R.415" || x.Code == "W.239"));
            Check("legacy-aliases-resolve-a", TdtSignLibrary.Find("W.239").Code == "W.239a" && TdtSignLibrary.Find("R.415").Code == "R.415a");
            int index = 0;
            foreach (string code in new[] { "W.205c", "W.207a", "W.239a", "W.239b@5.2", "R.415a", "R.415b" })
            {
                var result = TdtSignLibrary.EnsureBlock(db, code); Check(code + "-import", result.Ok);
                using (var tr = db.TransactionManager.StartTransaction())
                {
                    var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                    var block = (BlockTableRecord)tr.GetObject(table[result.BlockName], OpenMode.ForRead);
                    var entities = block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead) as Entity).Where(e => e != null).ToList();
                    Check(code + "-filled-foreground", entities.OfType<Hatch>().Any(h => h.Color.ColorMethod == Autodesk.AutoCAD.Colors.ColorMethod.ByColor && (code.StartsWith("R.") ? h.Color.Red == 255 && h.Color.Green == 255 && h.Color.Blue == 255 : h.Color.Red == 0 && h.Color.Green == 0 && h.Color.Blue == 0)));
                    if (code.Contains("@")) Check("clearance-custom-metres", entities.OfType<DBText>().Any(t => t.TextString == "5.2 m"));
                    var model = (BlockTableRecord)tr.GetObject(table[BlockTableRecord.ModelSpace], OpenMode.ForWrite);
                    var reference = new BlockReference(new Point3d(100000 + (index % 3) * 7, 100000 + (index / 3) * 4, 0), block.ObjectId);
                    model.AppendEntity(reference); tr.AddNewlyCreatedDBObject(reference, true); tr.Commit();
                }
                Check(code + "-outline", !HasHatch(db, TdtSignLibrary.EnsureOutlineBlock(db, result.BlockName), new HashSet<ObjectId>())); index++;
            }
            // Regression for legacy source order: small black foreground created before a large yellow background.
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForWrite);
                var block = new BlockTableRecord { Name = "BHT_QA_BAD_FILL_ORDER" }; table.Add(block); tr.AddNewlyCreatedDBObject(block, true);
                ObjectId black = Fill(tr, block, 0, 0, 1, 1, 250), yellow = Fill(tr, block, -1, -1, 2, 2, 2);
                typeof(TdtSignLibrary).GetMethod("PrepareFace", BindingFlags.Static | BindingFlags.NonPublic).Invoke(null, new object[] { tr, block.ObjectId, new HashSet<ObjectId>(), "W.207c" });
                var draw = (DrawOrderTable)tr.GetObject(block.DrawOrderTableId, OpenMode.ForRead);
                var order = draw.GetFullDrawOrder(0).Cast<ObjectId>().ToList(); Check("yellow-background-before-black-symbol", order.IndexOf(yellow) < order.IndexOf(black)); tr.Commit();
            }
            string bridge = SignCorrections.Bridge(db, "CẦU YÊN CHÂU", "Km252+831", "QL.6", "BHT_BIENBAO");
            Check("bridge-cache-reuse", bridge == SignCorrections.Bridge(db, "CẦU YÊN CHÂU", "Km252+831", "QL.6", "BHT_BIENBAO"));
            Check("bridge-values-in-block", Texts(db, bridge).Contains("CẦU YÊN CHÂU") && Texts(db, bridge).Contains("KM252+831-QL.6"));
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                var block = (BlockTableRecord)tr.GetObject(table[bridge], OpenMode.ForRead);
                var texts = block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead) as DBText).Where(t => t != null).ToList();
                Check("bridge-text-fits-frame", texts.All(t => t.GeometricExtents.MinPoint.X >= -1.9 && t.GeometricExtents.MaxPoint.X <= 1.9));
                Check("bridge-white-frames-survive-print", block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead)).OfType<Polyline>().All(x => x.Color.ColorMethod == Autodesk.AutoCAD.Colors.ColorMethod.ByColor && x.Color.Red == 255 && x.Color.Green == 255 && x.Color.Blue == 255));
                Check("bridge-original-frames", block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead)).OfType<Polyline>().Count() == 3);
                Check("bridge-original-sign-font", texts.All(t => ((TextStyleTableRecord)tr.GetObject(t.TextStyleId, OpenMode.ForRead)).FileName.Equals("giaothong1.ttf", StringComparison.OrdinalIgnoreCase)));
                Check("bridge-original-foot-circle", block.Cast<ObjectId>().Any(id => tr.GetObject(id, OpenMode.ForRead) is Circle));
                Check("bridge-white-ink-survives-print", texts.All(t => t.Color.ColorMethod == Autodesk.AutoCAD.Colors.ColorMethod.ByColor && t.Color.Red == 255 && t.Color.Green == 255 && t.Color.Blue == 255));
            }
            Check("bridge-change-isolated", bridge != SignCorrections.Bridge(db, "CẦU KHÁC", "Km39+900", "ĐT.1", "BHT_BIENBAO") && Texts(db, bridge).Contains("CẦU YÊN CHÂU"));
            string milestone = SignCorrections.Milestone(db, "39"); Check("km-number-in-block", Texts(db, milestone).Contains("39") && Texts(db, milestone).Contains("KM"));
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                var b = (BlockTableRecord)tr.GetObject(bt[milestone], OpenMode.ForRead);
                var bar = b.Cast<ObjectId>().Select(x => tr.GetObject(x, OpenMode.ForRead)).OfType<Solid>().First(x => x.ColorIndex == 7);
                var bounds = bar.GeometricExtents;
                Check("km-origin-at-bar-center", Math.Abs(bounds.MinPoint.X + bounds.MaxPoint.X) < 1e-8 && Math.Abs(bounds.MinPoint.Y + bounds.MaxPoint.Y) < 1e-8);
                foreach (double angle in new[] { 0.0, Math.PI / 2, Math.PI, -Math.PI / 2 })
                using (var reference = new BlockReference(new Point3d(125,231,0), bt[milestone]) { Rotation = angle, ScaleFactors = new Scale3d(2.5) })
                Check("km-anchor-rotation-" + angle, Point3d.Origin.TransformBy(reference.BlockTransform).DistanceTo(reference.Position) < 1e-8);
            }
            Check("km-update-isolated", milestone != SignCorrections.Milestone(db, "40") && Texts(db, milestone).Contains("39"));
            try { SignCorrections.Milestone(db, "-1"); Check("invalid-km-rejected", false); } catch (ArgumentException) { Check("invalid-km-rejected", true); }
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead); var model = (BlockTableRecord)tr.GetObject(table[BlockTableRecord.ModelSpace], OpenMode.ForWrite);
                foreach (var item in new[] { new { Name = bridge, X = 100007.0 }, new { Name = milestone, X = 100015.0 } })
                { var reference = new BlockReference(new Point3d(item.X, 99996, 0), table[item.Name]); model.AppendEntity(reference); tr.AddNewlyCreatedDBObject(reference, true); }
                tr.Commit();
            }
        }
        catch (System.Exception ex) { Lines.Add("FAIL exception " + ex); }
        string output = Environment.GetEnvironmentVariable("BHT_QA_OUTPUT") ?? Path.Combine(Path.GetTempPath(), "BHT-sign0610.txt");
        File.WriteAllLines(output, Lines); foreach (string line in Lines) AcApp.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\n" + line);
    }
    static ObjectId Fill(Transaction tr, BlockTableRecord block, double x0, double y0, double x1, double y1, short color)
    {
        var line = new Polyline { Closed = true }; line.AddVertexAt(0, new Point2d(x0,y0),0,0,0); line.AddVertexAt(1,new Point2d(x1,y0),0,0,0); line.AddVertexAt(2,new Point2d(x1,y1),0,0,0); line.AddVertexAt(3,new Point2d(x0,y1),0,0,0);
        block.AppendEntity(line); tr.AddNewlyCreatedDBObject(line,true); var hatch = new Hatch { ColorIndex = color }; block.AppendEntity(hatch); tr.AddNewlyCreatedDBObject(hatch,true); hatch.SetHatchPattern(HatchPatternType.PreDefined,"SOLID"); hatch.AppendLoop(HatchLoopTypes.External,new ObjectIdCollection(new[] { line.ObjectId })); hatch.EvaluateHatch(true);return hatch.ObjectId;
    }
    static List<string> Texts(Database db, string name)
    {
        using(var tr=db.TransactionManager.StartTransaction()) { var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);var block=(BlockTableRecord)tr.GetObject(table[name],OpenMode.ForRead);return block.Cast<ObjectId>().Select(id=>tr.GetObject(id,OpenMode.ForRead) as DBText).Where(t=>t!=null).Select(t=>t.TextString).ToList(); }
    }
    static bool HasHatch(Database db, string name, HashSet<ObjectId> seen)
    {
        using(var tr=db.TransactionManager.StartTransaction())
        {
            var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);var block=(BlockTableRecord)tr.GetObject(table[name],OpenMode.ForRead); if(!seen.Add(block.ObjectId))return false;
            foreach(ObjectId id in block) { var entity=tr.GetObject(id,OpenMode.ForRead);var visible=entity as Entity;if(visible!=null && !visible.Visible)continue;if(entity is Hatch)return true;var reference=entity as BlockReference;if(reference!=null && HasHatch(db,((BlockTableRecord)tr.GetObject(reference.BlockTableRecord,OpenMode.ForRead)).Name,seen))return true; } return false;
        }
    }
}
