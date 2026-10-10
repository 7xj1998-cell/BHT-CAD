using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using BHT.Core;
using BHT.Bridge;
using App = Autodesk.AutoCAD.ApplicationServices.Core.Application;
public class SignLibraryProbe
{
    [LispFunction("BHTTESTVISIBLEFILLS")]
    public static int VisibleFills(ResultBuffer args)
    {
        return FillCount(App.DocumentManager.MdiActiveDocument.Database, Convert.ToString(args.AsArray()[0].Value));
    }
    [CommandMethod("BHTUPGRADEPROBE")]
    public static void Upgrade()
    {
        var doc=App.DocumentManager.MdiActiveDocument;
        var lines=new List<string>();
        lines.Add((SymbolUpgradeStartup.NeedsUpgrade(doc.Database)?"PASS ":"FAIL ")+"old-drawing-needs-upgrade");
        int changed=0;
        Autodesk.AutoCAD.DatabaseServices.ObjectEventHandler onChange=(sender,e)=>{changed++;};
        doc.Database.ObjectModified+=onChange;
        doc.Database.ObjectAppended+=onChange;
        var startup=new SymbolUpgradeStartup();
        startup.Initialize();
        int scheduled=SymbolUpgradeStartup.Ready(null);
        startup.Terminate();
        doc.Database.ObjectModified-=onChange;
        doc.Database.ObjectAppended-=onChange;
        lines.Add((scheduled==0 && changed==0 && SymbolUpgradeStartup.NeedsUpgrade(doc.Database) ? "PASS " : "FAIL ")+"startup-does-not-modify-old-drawing");
        var reply=SymbolUpgradeStartup.RunNow(doc);
        lines.Add((reply.Ok?"PASS ":"FAIL ")+"explicit-acedInvoke-upgrade "+reply.Error);
        lines.Add((!SymbolUpgradeStartup.NeedsUpgrade(doc.Database)?"PASS ":"FAIL ")+"current-drawing-no-repeat-upgrade");
        using(var tr=doc.Database.TransactionManager.StartTransaction()) {BhtStore.MetaSet(tr,doc.Database,"symbol_build","99.0.0");tr.Commit();}
        lines.Add((!SymbolUpgradeStartup.NeedsUpgrade(doc.Database)?"PASS ":"FAIL ")+"future-drawing-not-downgraded");
        using(var tr=doc.Database.TransactionManager.StartTransaction()) {BhtStore.MetaSet(tr,doc.Database,"symbol_build",BhtVersion.Version);tr.Commit();}
        File.WriteAllLines(Path.Combine(Path.GetDirectoryName(typeof(SignLibraryProbe).Assembly.Location),"upgrade-api.txt"),lines);
        foreach(var line in lines)doc.Editor.WriteMessage("\n"+line);
    }
    static void ProbeToll(Database db,List<string> lines)
    {
        foreach(var code in new[] {"IE.472a","IE.472a@500.5","IE.472b"})
        {
            var result=TdtSignLibrary.EnsureBlock(db,code);
            lines.Add((result.Ok && result.BlockName.StartsWith("BHT_TDT_V0629_") ? "PASS " : "FAIL ")+code+" native-block");
            if(!result.Ok) continue;
            using(var tr=db.TransactionManager.StartTransaction())
            {
                var bt=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);
                var block=(BlockTableRecord)tr.GetObject(bt[result.BlockName],OpenMode.ForRead);
                var es=block.Cast<ObjectId>().Select(id=>tr.GetObject(id,OpenMode.ForRead)).OfType<Entity>().ToList();
                var text=es.OfType<DBText>().ToList();
                string value=SignPresentation.MetreValue(code);if(value=="")value=SignPresentation.MetreDefault(code);
                lines.Add((text.Any(t=>t.TextString=="TRẠM THU PHÍ") && text.Any(t=>t.TextString=="TOLL PLAZA") && text.All(t=>t.Color.ColorMethod==Autodesk.AutoCAD.Colors.ColorMethod.ByColor && t.Color.Red==255 && t.Color.Green==255 && t.Color.Blue==255) ? "PASS " : "FAIL ")+code+" white-Unicode-legends");
                lines.Add((value=="" ? text.Count==2 : text.Count==3 && text.Any(t=>t.TextString==value+" m")) ? "PASS "+code+" distance-layout" : "FAIL "+code+" distance-layout");
                lines.Add((es.OfType<Hatch>().Any(h=>h.Color.ColorMethod==Autodesk.AutoCAD.Colors.ColorMethod.ByColor && h.Color.Red==0 && h.Color.Green==152 && h.Color.Blue==65) && es.OfType<Polyline>().Count(p=>p.NumberOfVertices==8 && p.Closed && p.GetBulgeAt(1)>0)==(value==""?1:2) ? "PASS " : "FAIL ")+code+" green-hatch-rounded-frames");
                tr.Commit();
            }
            string support=SignSupports.Ensure(db,result.BlockName,2);
            string assembly=SignAssembly.Ensure(db,new[] {result.BlockName,result.BlockName});
            using(var tr=db.TransactionManager.StartTransaction())
            {
                var bt=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);
                var supports=((BlockTableRecord)tr.GetObject(bt[support],OpenMode.ForRead)).Cast<ObjectId>().Select(id=>tr.GetObject(id,OpenMode.ForRead)).OfType<Entity>().ToList();
                lines.Add((supports.OfType<Line>().Count()==2 && supports.OfType<Line>().All(l=>Math.Abs(l.EndPoint.Y-.6)<1e-8) && supports.OfType<Circle>().Count()==2 ? "PASS " : "FAIL ")+code+" two-supports-no-old-center-post");
                var combined=(BlockTableRecord)tr.GetObject(bt[assembly],OpenMode.ForRead);
                var faces=combined.Cast<ObjectId>().Select(id=>tr.GetObject(id,OpenMode.ForRead)).OfType<BlockReference>().ToList();
                bool clean=faces.Count==2 && faces.All(face=>((BlockTableRecord)tr.GetObject(face.BlockTableRecord,OpenMode.ForRead)).Cast<ObjectId>().All(id=>!(tr.GetObject(id,OpenMode.ForRead) is Line) && !(tr.GetObject(id,OpenMode.ForRead) is Circle)));
                lines.Add((clean ? "PASS " : "FAIL ")+code+" stacked-faces-without-extra-posts");
                tr.Commit();
            }
            string outline=TdtSignLibrary.EnsureOutlineBlock(db,result.BlockName);
            lines.Add((BackgroundCount(db,outline)==0 && FillCount(db,result.BlockName)>0 ? "PASS " : "FAIL ")+code+" independent-outline");
            lines.Add((TdtSignLibrary.Find(code)!=null && TdtSignLibrary.Find(code).HasVector ? "PASS " : "FAIL ")+code+" catalog-vector-available");
        }
    }
    static void ProbeCorrections26(Database db, List<string> report)
    {
        foreach (string code in new[] { "DP.134-40", "DP.134-80", "R.306-30", "R.306-60" })
        {
            var result=TdtSignLibrary.EnsureBlock(db,code); report.Add((result.Ok && TdtSignLibrary.Find(code) != null ? "PASS " : "FAIL ") + "speed26-native-import-" + code);
            using(var tr=db.TransactionManager.StartTransaction())
            {
                var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);
                var block=(BlockTableRecord)tr.GetObject(table[result.BlockName],OpenMode.ForRead);
                var parts=block.Cast<ObjectId>().Select(id => tr.GetObject(id,OpenMode.ForRead) as Entity).ToList();
                var text=parts.OfType<DBText>().Single();bool minimum=code.StartsWith("R.");
                report.Add((text.TextString == code.Split('-')[1] && text.Color.Red == (minimum ? 255 : 0) ? "PASS " : "FAIL ") + "speed26-number-and-ink-" + code);
                report.Add((parts.OfType<Polyline>().Count() == (minimum ? 0 : 5) ? "PASS " : "FAIL ") + "speed26-cancellation-lines-" + code);
                report.Add((text.GeometricExtents.MinPoint.X >= -.65 && text.GeometricExtents.MaxPoint.X <= .65 ? "PASS " : "FAIL ") + "speed26-text-within-circle-" + code);
            }
            report.Add((BackgroundCount(db,TdtSignLibrary.EnsureOutlineBlock(db,result.BlockName)) == 0 ? "PASS " : "FAIL ") + "speed26-outline-" + code);
        }
        var warning=TdtSignLibrary.EnsureBlock(db,"W.207a");
        using(var tr=db.TransactionManager.StartTransaction())
        {
            var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);var block=(BlockTableRecord)tr.GetObject(table[warning.BlockName],OpenMode.ForRead);
            var symbol=block.Cast<ObjectId>().Select(id => tr.GetObject(id,OpenMode.ForRead)).OfType<Polyline>().Single(p => p.Color.ColorMethod == Autodesk.AutoCAD.Colors.ColorMethod.ByColor && p.Color.Red==0 && p.Color.Green==0 && p.Color.Blue==0);
            var pts=Enumerable.Range(0,symbol.NumberOfVertices).Select(symbol.GetPoint2dAt).ToList();
            report.Add((pts.Any(p => p.X < -.35 && p.Y == 1.28) && pts.Any(p => p.X > .35 && p.Y == 1.28) && symbol.NumberOfVertices == 14 ? "PASS " : "FAIL ") + "W207a-two-opposite-branches");
        }
        report.Add((warning.BlockName.Contains("V0626") && TdtSignLibrary.WrapperName("R.415").Contains("V0631") ? "PASS " : "FAIL ") + "corrected26-does-not-reuse-old-block-cache");
    }
    static void ProbeTruckWeight(Database db, List<string> report)
    {
        string original = TdtSignLibrary.EnsureBlock(db, "S.505a").BlockName;
        int originalFills = FillCount(db, original);
        foreach (string code in new[] { "S.505a@8", "S.505a@12", "S.505a@8.5", "S.505a@100000" })
        {
            var result = TdtSignLibrary.EnsureBlock(db, code);
            report.Add((result.Ok ? "PASS " : "FAIL ") + code + " truck-weight-import " + result.Error);
            if (!result.Ok)
            {
                try { SignCorrections.TruckWeight(db, code); }
                catch (System.Exception ex) { report.Add(ex.ToString()); }
                continue;
            }
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                var block = (BlockTableRecord)tr.GetObject(table[result.BlockName], OpenMode.ForRead);
                var parts = block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead) as Entity).ToList();
                var text = parts.OfType<DBText>().Single();
                var bounds = text.GeometricExtents;
                report.Add(text.TextString == SignPresentation.WeightValue(code) + "T" && bounds.MinPoint.X >= -.82 && bounds.MaxPoint.X <= .82 && bounds.MaxPoint.Y < 1.08 && text.AlignmentPoint.X == 0 ? "PASS weight-centered-under-truck-within-frame" : "FAIL weight-centered-under-truck-within-frame");
                report.Add(parts.OfType<Hatch>().Count() > 2 && parts.OfType<Hatch>().Any(h => h.Color.Red == 255 && h.Color.Green == 255 && h.Color.Blue == 255) ? "PASS weight-original-truck-black-on-white-fill" : "FAIL weight-original-truck-black-on-white-fill");
            }
            string outline = TdtSignLibrary.EnsureOutlineBlock(db, result.BlockName);
            report.Add(BackgroundCount(db, outline) == 0 && FillCount(db, result.BlockName) > 0 ? "PASS weight-independent-outline" : "FAIL weight-independent-outline");
        }
        report.Add(TdtSignLibrary.EnsureBlock(db, "S.505a@8").BlockName == TdtSignLibrary.EnsureBlock(db, "S.505a@8,000").BlockName ? "PASS weight-canonical-cache" : "FAIL weight-canonical-cache");
        string provider = Environment.GetEnvironmentVariable("BHT_SIGN_PROVIDER");
        try
        {
            Environment.SetEnvironmentVariable("BHT_SIGN_PROVIDER", "BUILTIN"); TdtSignLibrary.ReloadCatalog();
            report.Add(TdtSignLibrary.EnsureBlock(db, "S.505a@8").Ok && TdtSignLibrary.EnsureBlock(db, "S.505a@7").Ok ? "PASS weight-cached-truck-usable-without-TDT" : "FAIL weight-cached-truck-usable-without-TDT");
        }
        finally { Environment.SetEnvironmentVariable("BHT_SIGN_PROVIDER", provider); TdtSignLibrary.ReloadCatalog(); }
        report.Add(!TdtSignLibrary.EnsureBlock(db, "S.505a@0").Ok ? "PASS weight-invalid-rejected" : "FAIL weight-invalid-rejected");
        report.Add(FillCount(db, original) == originalFills ? "PASS weight-keeps-original-truck" : "FAIL weight-keeps-original-truck");
        try { SignAssembly.Ensure(db, new[] { TdtSignLibrary.EnsureBlock(db, "P.124a").BlockName, TdtSignLibrary.EnsureBlock(db, "S.505a@8").BlockName }); report.Add("PASS weight-two-face-assembly"); }
        catch (System.Exception ex) { report.Add("FAIL weight-two-face-assembly " + ex.Message); }
    }
    static bool OutlineInk(Transaction tr, ObjectId bid, HashSet<ObjectId> seen)
    {
        if (!seen.Add(bid)) return true;
        foreach (ObjectId id in (BlockTableRecord)tr.GetObject(bid, OpenMode.ForRead))
        {
            var entity = tr.GetObject(id, OpenMode.ForRead) as Entity;
            if (entity != null && entity.Visible && entity.ColorIndex != 0 && SignPrintPresentation.Role(entity)!=SignPrintPresentation.Void && SignPrintPresentation.Role(entity)!=SignPrintPresentation.Paper && SignPrintPresentation.Role(entity)!=SignPrintPresentation.Backing) return false;
            var stroke=entity as Polyline;
            if(stroke!=null && stroke.Closed && (stroke.ConstantWidth!=0 || Enumerable.Range(0,stroke.NumberOfVertices).Any(v=>stroke.GetStartWidthAt(v)!=0 || stroke.GetEndWidthAt(v)!=0))) return false;
            var text=entity as MText;
            if(text!=null && text.BackgroundFill) return false;
            var reference = entity as BlockReference;
            if (reference == null) continue;
            foreach (ObjectId attr in reference.AttributeCollection)
                if (((AttributeReference)tr.GetObject(attr, OpenMode.ForRead)).ColorIndex != 0) return false;
            if (!OutlineInk(tr, reference.BlockTableRecord, seen)) return false;
        }
        return true;
    }
    static void ProbeOutlineGeometry(Database db, List<string> lines)
    {
        foreach (string code in new[] { "P.127-80", "P.127-40", "R.415a", "R.415b", "W.239a" })
        {
            var source = TdtSignLibrary.EnsureBlock(db, code);
            string name = TdtSignLibrary.EnsureOutlineBlock(db, source.BlockName); using (var tr = db.TransactionManager.StartTransaction())
            {
                var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                lines.Add(OutlineInk(tr, bt[name], new HashSet<ObjectId>()) ? "PASS outline-text-and-attributes-inherit-white " + code : "FAIL outline-text-and-attributes-inherit-white " + code);
                if (code.StartsWith("R.") || code == "W.239a")
                {
                    var filled = (BlockTableRecord)tr.GetObject(bt[source.BlockName], OpenMode.ForRead);
                    var outline = (BlockTableRecord)tr.GetObject(bt[name], OpenMode.ForRead);
                    int before = filled.Cast<ObjectId>().Count(id => tr.GetObject(id, OpenMode.ForRead) is Polyline || tr.GetObject(id, OpenMode.ForRead) is Circle);
                    int after = outline.Cast<ObjectId>().Count(id => tr.GetObject(id, OpenMode.ForRead) is Polyline || tr.GetObject(id, OpenMode.ForRead) is Circle);
                    lines.Add(before == after ? "PASS outline-no-duplicate-boundaries " + code : "FAIL outline-no-duplicate-boundaries " + code + " " + before + "/" + after);
                    if (code.StartsWith("R."))
                    {
                        lines.Add(filled.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead)).OfType<Polyline>().Any(p => Enumerable.Range(0, p.NumberOfVertices).Any(i => Math.Abs(p.GetBulgeAt(i)) > .4)) ? "PASS lane-plate-native-circular-contours " + code : "FAIL lane-plate-native-circular-contours " + code);
                        lines.Add(!filled.Cast<ObjectId>().Select(id => tr.GetObject(id,OpenMode.ForRead)).OfType<Curve>().Any(c => c.Color.ColorMethod == Autodesk.AutoCAD.Colors.ColorMethod.ByColor && c.Color.Red == 255 && c.GeometricExtents.MinPoint.X > 1.4) ? "PASS lane-plate-no-isolated-frame-fragments " + code : "FAIL lane-plate-no-isolated-frame-fragments " + code);
                    }
                    else
                        lines.Add(filled.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead)).OfType<Polyline>().All(p => p.NumberOfVertices <= 6) ? "PASS electrical-sign-straight-edges" : "FAIL electrical-sign-straight-edges");
                }
                tr.Commit();
            }
        }
    }
    static void ProbeNamedBoards(Database db, List<string> report)
    {
        string unicodeStyle = "BHT_BOARD_TEST", legacyStyle = "BHT_BOARD_TEST_OLD";
        using (var tr = db.TransactionManager.StartTransaction())
        {
            var styles = (TextStyleTable)tr.GetObject(db.TextStyleTableId, OpenMode.ForWrite);
            foreach (string name in new[] { unicodeStyle, legacyStyle })
            {
                if (styles.Has(name)) continue;
                var style = new TextStyleTableRecord { Name = name, FileName = name == unicodeStyle ? "VNRomancUpdate.shx" : "vnromanc.shx" };
                styles.Add(style); tr.AddNewlyCreatedDBObject(style, true);
            }
            tr.Commit();
        }
        foreach (string title in new[] { "Chưa xác định", "Cửa hàng", "Bảng quảng cáo cửa hàng vật liệu xây dựng ven tuyến", "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" })
        {
            string name = SignCorrections.NamedBoard(db, title, unicodeStyle);
            report.Add(name == SignCorrections.NamedBoard(db, title, unicodeStyle) ? "PASS board-repeat-cache" : "FAIL board-repeat-cache");
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                var block = (BlockTableRecord)tr.GetObject(table[name], OpenMode.ForRead);
                var entities = block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead) as Entity).ToList();
                var hatch = entities.OfType<Hatch>().Single();
                var text = entities.OfType<DBText>().ToList();
                report.Add(hatch.PatternName == "SOLID" && hatch.Color.Blue == 190 && hatch.Color.Red == 0 ? "PASS board-blue-solid-hatch" : "FAIL board-blue-solid-hatch");
                report.Add(string.Join(" ", text.Select(t => t.TextString)) == title && text.All(t => t.Color.Red == 255 && t.Color.Green == 255 && t.Color.Blue == 255) ? "PASS board-white-Unicode-title" : "FAIL board-white-Unicode-title");
                var bounds = hatch.GeometricExtents;
                report.Add(text.All(t => t.HorizontalMode == TextHorizontalMode.TextCenter && t.GeometricExtents.MinPoint.X >= bounds.MinPoint.X + .05 && t.GeometricExtents.MaxPoint.X <= bounds.MaxPoint.X - .05 && t.GeometricExtents.MinPoint.Y >= bounds.MinPoint.Y && t.GeometricExtents.MaxPoint.Y <= bounds.MaxPoint.Y) ? "PASS board-text-centered-inside-frame" : "FAIL board-text-centered-inside-frame");
                var order = ((DrawOrderTable)tr.GetObject(block.DrawOrderTableId, OpenMode.ForRead)).GetFullDrawOrder(0).Cast<ObjectId>().ToList();
                report.Add(text.All(t => order.IndexOf(hatch.ObjectId) < order.IndexOf(t.ObjectId)) ? "PASS board-hatch-behind-text" : "FAIL board-hatch-behind-text");
            }
        }
        string oldBoard = SignCorrections.NamedBoard(db, "Cửa hàng", legacyStyle);
        try
        {
            string two = SignSupports.Ensure(db, SignCorrections.NamedBoard(db, "Bảng hai chân", unicodeStyle), 2);
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                var block = (BlockTableRecord)tr.GetObject(table[two], OpenMode.ForRead);
                var entities = block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead) as Entity).ToList();
                report.Add(entities.OfType<Line>().Count() == 2 && entities.OfType<Circle>().Count() == 2 ? "PASS support-native-two-poles-two-feet" : "FAIL support-native-two-poles-two-feet");
                report.Add(entities.OfType<Hatch>().Count() == 1 && entities.OfType<DBText>().Any() ? "PASS support-keeps-board-hatch-text" : "FAIL support-keeps-board-hatch-text");
            }
        }
        catch (System.Exception ex) { report.Add("FAIL support-native " + ex); }
        using (var tr = db.TransactionManager.StartTransaction())
        {
            var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
            var block = (BlockTableRecord)tr.GetObject(table[oldBoard], OpenMode.ForRead);
            report.Add(block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead)).OfType<DBText>().Single().TextString == Tcvn3.Encode("Cửa hàng") ? "PASS board-legacy-display-encoding" : "FAIL board-legacy-display-encoding");
        }
    }
    [CommandMethod("BHTASSEMBLYAPIPROBE")]
    public void AssemblyApiProbe()
    {
        var reply = new LispApi().Call("bht:api-symbol-sync", "OBJ-MULTI");
        if (!reply.Ok) throw new InvalidOperationException("Palette API assembly failed: " + reply.Error);
        File.WriteAllText(Path.Combine(Path.GetDirectoryName(typeof(SignLibraryProbe).Assembly.Location), "assembly-api.txt"), "PASS palette-acedInvoke-two-plates-seven-metres");
    }
    [CommandMethod("BHTOFFLINEPROBE")]
    public static void Offline()
    {
        var doc = App.DocumentManager.MdiActiveDocument;
        string provider = Environment.GetEnvironmentVariable("BHT_SIGN_PROVIDER"), root = Environment.GetEnvironmentVariable("BHT_TDT_ROOT");
        string fixture = Path.Combine(Path.GetDirectoryName(typeof(SignLibraryProbe).Assembly.Location), "synthetic-tdt");
        var lines = new List<string>();
        try
        {
            Environment.SetEnvironmentVariable("BHT_SIGN_PROVIDER", "BUILTIN"); TdtSignLibrary.ReloadCatalog();
            var items = TdtSignLibrary.GetCatalog();
            ProbeToll(doc.Database,lines);
            lines.Add(items.Count >= 16 && TdtSignLibrary.Find("P.127") != null && TdtSignLibrary.InstalledRoot == "" ? "PASS builtin-catalog-without-TDT" : "FAIL builtin-catalog-without-TDT");
            var r = TdtSignLibrary.EnsureBlock(doc.Database, "P.127-80");
            lines.Add(!r.Ok && r.Error.Length > 0 ? "PASS missing-vector-graceful" : "FAIL missing-vector-graceful");
            Environment.SetEnvironmentVariable("BHT_SIGN_PROVIDER", ""); Environment.SetEnvironmentVariable("BHT_TDT_ROOT", fixture);
            Directory.CreateDirectory(Path.Combine(fixture, "Data", "Bien bao"));
            string xml = Path.Combine(fixture, "Data", "Bien bao", "Bienbao.xml");
            File.WriteAllText(xml, "<UnknownSchema />"); TdtSignLibrary.ReloadCatalog();
            lines.Add(TdtSignLibrary.Find("P.127") != null ? "PASS unknown-XML-fallback" : "FAIL unknown-XML-fallback");
            File.WriteAllText(xml, "<!DOCTYPE a [<!ENTITY x SYSTEM 'file:///untrusted'>]><a>&x;</a>"); TdtSignLibrary.ReloadCatalog();
            lines.Add(TdtSignLibrary.Find("P.127") != null ? "PASS XML-external-entity-rejected" : "FAIL XML-external-entity-rejected");
            File.WriteAllText(xml, "<root><group dataSource='Bien bao cam.dwg' tên='Biển cấm'><sign hìnhdạng='T' môtả='Tốc độ' tên='P.127'/></group></root>"); TdtSignLibrary.ReloadCatalog();
            lines.Add(TdtSignLibrary.Find("P.127").Description == "Tốc độ" ? "PASS XML-attribute-order-independent" : "FAIL XML-attribute-order-independent");
            File.WriteAllBytes(Path.Combine(fixture,"Data","Bien bao","bienbao.set"), new byte[] {0,0,0,0,1,0,0,0,0,0,0,0});
            r = TdtSignLibrary.EnsureBlock(doc.Database, "P.127-70");
            lines.Add(!r.Ok && r.Error.Length > 0 ? "PASS changed-container-graceful" : "FAIL changed-container-graceful");
        }
        finally { Environment.SetEnvironmentVariable("BHT_SIGN_PROVIDER", provider); Environment.SetEnvironmentVariable("BHT_TDT_ROOT", root); TdtSignLibrary.ReloadCatalog(); }
        File.WriteAllLines(Path.Combine(Path.GetDirectoryName(typeof(SignLibraryProbe).Assembly.Location),"offline-probe.txt"), lines);
        foreach (string line in lines) doc.Editor.WriteMessage("\n" + line);
    }
    [CommandMethod("BHTSIGNPROBE")]
    public static void Run()
    {
        var lines = new List<string>();
        var db = App.DocumentManager.MdiActiveDocument.Database;
        ProbeNamedBoards(db, lines);
        ProbeOutlineGeometry(db, lines);
        ProbeTruckWeight(db, lines);
        ProbeCorrections26(db, lines);
        ProbeToll(db,lines);
        lines.Add(TdtSignLibrary.Find("P.12") == null && TdtSignLibrary.Find("W.207zz") == null && TdtSignLibrary.Find("P.127-800") == null ? "PASS no-wrong-prefix-sign" : "FAIL no-wrong-prefix-sign");
        var invalidSpeed = TdtSignLibrary.EnsureBlock(db, "P.127-800");
        lines.Add(!invalidSpeed.Ok && invalidSpeed.Error.Contains("130") ? "PASS invalid-speed-block-rejected" : "FAIL invalid-speed-block-rejected");
        using (var tr = db.TransactionManager.StartTransaction())
        {
            var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForWrite);
            var invalid = new BlockTableRecord { Name = TdtSignLibrary.WrapperName("W.207zz") };
            table.Add(invalid); tr.AddNewlyCreatedDBObject(invalid, true); tr.Commit();
        }
        lines.Add(!TdtSignLibrary.EnsureBlock(db, "W.207zz").Ok ? "PASS old-invalid-cached-sign-rejected" : "FAIL old-invalid-cached-sign-rejected");
        try { SignAssembly.Ensure(db, new[] { "P.127-missing-block" }); lines.Add("FAIL missing-single-plate"); }
        catch (InvalidOperationException) { lines.Add("PASS missing-single-plate-rejected"); }
        try { SignAssembly.Ensure(db, new string[0]); lines.Add("FAIL empty-assembly"); }
        catch (ArgumentException) { lines.Add("PASS empty-assembly-rejected"); }
        foreach (string code in new[] { "P.127-80", "P.127-40", "P.127", "I.434a", "R.415", "W.207c", "S.501@350", "S.502@150", "S.509a@4.5", "P.117@3.8", "P.118@2.8", "P.119@8", "P.120@9" })
        {
            var result = TdtSignLibrary.EnsureBlock(db, code);
            lines.Add((result.Ok ? "PASS " : "FAIL ") + code + " import " + result.Error + " scale=" + result.FaceScale);
            if (!result.Ok) continue;
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                var wrapper = (BlockTableRecord)tr.GetObject(table[result.BlockName], OpenMode.ForRead);
                string metres = SignPresentation.MetreValue(code);
                if (metres != "")
                {
                    var texts = new List<string>(); VisibleText(tr, wrapper.ObjectId, texts, new HashSet<ObjectId>());
                    var numbers = texts.Where(t => System.Text.RegularExpressions.Regex.IsMatch(t, @"^\d+(?:[.,]\d+)?\s*(m)?$"));
                    lines.Add((numbers.Any() && numbers.All(t => t.Replace(" m", "").Trim() == metres) && !texts.Any(t => System.Text.RegularExpressions.Regex.IsMatch(t, @"^\d+[.,]$")) ? "PASS " : "FAIL ") + code + " visible-metre-number-no-old-fragments");
                }
                foreach (ObjectId id in wrapper)
                {
                    var face = tr.GetObject(id, OpenMode.ForRead) as BlockReference;
                    if (face == null) continue;
                    var bounds = face.GeometricExtents;
                    double height = bounds.MaxPoint.Y - bounds.MinPoint.Y;
                    double size = SignPresentation.BaseCode(code).StartsWith("S.", StringComparison.OrdinalIgnoreCase)
                        ? Math.Max(height, bounds.MaxPoint.X - bounds.MinPoint.X) : height;
                    lines.Add((Math.Abs(size - 1.8) < 1e-5 ? "PASS " : "FAIL ") + code + " face-size=" + size);
                    Walk(tr, face.BlockTableRecord, lines, code, new HashSet<ObjectId>());
                    foreach (ObjectId aid in face.AttributeCollection) lines.Add("ATTR " + code + " " + ((AttributeReference)tr.GetObject(aid, OpenMode.ForRead)).TextString);
                }
            }
        }
        foreach (string code in new[] { "P.127-80", "I.434a", "R.415" })
        {
            string filled = TdtSignLibrary.WrapperName(code);
            int before = FillCount(db, filled);
            string outline = TdtSignLibrary.EnsureOutlineBlock(db, filled);
            lines.Add((before > 0 && BackgroundCount(db, outline) == 0 && FillCount(db, filled) == before ? "PASS " : "FAIL ") + code + " independent-outline");
            lines.Add((TdtSignLibrary.EnsureOutlineBlock(db, filled) == outline ? "PASS " : "FAIL ") + code + " outline-cache");
        }
        var speed80 = TdtSignLibrary.EnsureBlock(db, SignPresentation.ResolveCode("P.127", "bbtron1m25 gioihan80"));
        var main = TdtSignLibrary.EnsureBlock(db, "W.239");
        var extra = TdtSignLibrary.EnsureBlock(db, "S.509a@4.5");
        string assembly = SignAssembly.Ensure(db, new[] { main.BlockName, extra.BlockName });
        using (var tr = db.TransactionManager.StartTransaction())
        {
            var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
            var definition = (BlockTableRecord)tr.GetObject(bt[assembly], OpenMode.ForRead);
            var entities = definition.Cast<ObjectId>().Select(id => (Entity)tr.GetObject(id, OpenMode.ForRead)).ToList();
            lines.Add((entities.OfType<BlockReference>().Count() == 2 && entities.OfType<Line>().Count() == 1 ? "PASS " : "FAIL ") + "one-post-two-plates");
            lines.Add((Math.Abs(entities.OfType<Line>().Single().EndPoint.Y - 0.6) < 1e-6 ? "PASS " : "FAIL ") + "outline-pole-does-not-cross-plates");
            var bottom = entities.OfType<BlockReference>().First(); var top = entities.OfType<BlockReference>().Last();
            lines.Add((bottom.GeometricExtents.MaxPoint.Y < top.GeometricExtents.MinPoint.Y ? "PASS " : "FAIL ") + "primary-above-supplementary");
            var values = new List<string>(); VisibleText(tr, bottom.BlockTableRecord, values, new HashSet<ObjectId>());
            lines.Add((values.Contains("4.5 m") ? "PASS " : "FAIL ") + "assembly-retains-metre-value");
        }
        lines.Add((assembly == SignAssembly.Ensure(db, new[] { main.BlockName, extra.BlockName }) ? "PASS " : "FAIL ") + "assembly-cache");
        string repeated = SignAssembly.Ensure(db, new[] { main.BlockName, main.BlockName });
        lines.Add((repeated != assembly ? "PASS " : "FAIL ") + "repeated-plates-not-collapsed");
        string assemblyOutline = TdtSignLibrary.EnsureOutlineBlock(db, assembly);
        lines.Add((BackgroundCount(db, assemblyOutline) == 0 && FillCount(db, assembly) > 0 ? "PASS " : "FAIL ") + "assembly-outline-independent");
        lines.Add((speed80.Ok && speed80.BlockName == TdtSignLibrary.WrapperName("P.127-80") ? "PASS " : "FAIL ") + "description-speed80-reuse");
        File.WriteAllLines(Path.Combine(Path.GetDirectoryName(typeof(SignLibraryProbe).Assembly.Location), "probe.txt"), lines);
        foreach (string line in lines) App.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\n" + line);
    }
    [LispFunction("BHTTESTVISIBLEBACKGROUNDS")]
    public static int VisibleBackgrounds(ResultBuffer args) { return BackgroundCount(App.DocumentManager.MdiActiveDocument.Database,Convert.ToString(args.AsArray()[0].Value)); }
    private static int BackgroundCount(Database db,string name) { using(var tr=db.TransactionManager.StartOpenCloseTransaction()) {var table=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);return Count(tr,table[name],new HashSet<ObjectId>(),true);} }
    private static int FillCount(Database db, string name)
    {
        using (var tr = db.TransactionManager.StartTransaction())
        {
            var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
            return Count(tr, table[name], new HashSet<ObjectId>());
        }
    }
    private static void VisibleText(Transaction tr, ObjectId id, List<string> values, HashSet<ObjectId> seen)
    {
        if (!seen.Add(id)) return;
        foreach (ObjectId child in (BlockTableRecord)tr.GetObject(id, OpenMode.ForRead))
        {
            var e = (Entity)tr.GetObject(child, OpenMode.ForRead);
            var text = e as DBText;
            if (text != null && text.Visible && (!(text is AttributeDefinition) || !((AttributeDefinition)text).Invisible)) values.Add(text.TextString);
            var block = e as BlockReference;
            if (block != null) { VisibleText(tr, block.BlockTableRecord, values, seen); foreach (ObjectId a in block.AttributeCollection) { var t = (AttributeReference)tr.GetObject(a, OpenMode.ForRead); if (t.Visible && !t.Invisible) values.Add(t.TextString); } }
        }
    }
    private static int Count(Transaction tr, ObjectId bid, HashSet<ObjectId> seen, bool backgroundOnly=false)
    {
        if (!seen.Add(bid)) return 0;
        int n = 0;
        foreach (ObjectId id in (BlockTableRecord)tr.GetObject(bid, OpenMode.ForRead))
        {
            var e = tr.GetObject(id, OpenMode.ForRead) as Entity;
            if (e != null && e.Visible && (e is Hatch || e is Solid) && (!backgroundOnly || SignPrintPresentation.Role(e)==SignPrintPresentation.Background)) n++;
            var nested = e as BlockReference;
            if (nested != null) n += Count(tr, nested.BlockTableRecord, seen, backgroundOnly);
        }
        return n;
    }
    private static void Walk(Transaction tr, ObjectId bid, List<string> lines, string code, HashSet<ObjectId> seen)
    {
        if (!seen.Add(bid)) return;
        var b = (BlockTableRecord)tr.GetObject(bid, OpenMode.ForRead);
        var draw = (DrawOrderTable)tr.GetObject(b.DrawOrderTableId, OpenMode.ForRead);
        bool foreground = false, valid = true; int hatches = 0;
        foreach (ObjectId id in draw.GetFullDrawOrder(0))
        {
            var e = tr.GetObject(id, OpenMode.ForRead) as Entity;
            if (e is Hatch)
            {
                hatches++;
                bool red = e.ColorIndex == 1 || (e.Color.Red >= 200 && e.Color.Green <= 80 && e.Color.Blue <= 80);
                if (foreground && !red) valid = false;
            }
            else foreground = true;
            var nested = e as BlockReference;
            if (nested != null) Walk(tr, nested.BlockTableRecord, lines, code, seen);
            var text = e as DBText; var mt = e as MText;
            if (text != null)
            {
                lines.Add("TEXT " + code + " " + text.TextString);
                int numeric;
                if (code.Contains("-") && int.TryParse(text.TextString, out numeric))
                    lines.Add((numeric.ToString() == code.Split('-')[1] ? "PASS " : "FAIL ") + code + " speed-text");
            }
            if (mt != null) lines.Add("MTEXT " + code + " " + mt.Text);
        }
        if (hatches > 0) lines.Add((valid ? "PASS " : "FAIL ") + code + " background-fill-order=" + hatches);
    }
}
