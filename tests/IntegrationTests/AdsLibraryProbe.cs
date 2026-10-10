using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using BHT.Bridge;
using BHT.Core;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

public class AdsLibraryProbe
{
    static List<string> report = new List<string>();
    static void Check(bool pass, string message) { report.Add((pass ? "PASS " : "FAIL ") + message); }
    [CommandMethod("BHTADSOFFLINEPROBE")]
    public static void Offline()
    {
        report.Clear();
        BhtSignLibrary.Reload();
        Check(BhtSignLibrary.Root.Replace('\\', '/').Contains("SignLibrary/BHT"), "bundled ADS library selected " + BhtSignLibrary.Root);
        Check(TdtSignLibrary.GetCatalog().Count == 467, "full offline catalog");
        foreach (string code in new[] { "R.415a", "R.415b", "DP.134-80", "P.127-80", "P.122", "R.E,9b@07:30-19:00", "S.505a@3.5", "S.501@350", "IE.472a@850" })
        {
            var result = TdtSignLibrary.EnsureBlock(AcApp.DocumentManager.MdiActiveDocument.Database, code);
            Check(result.Ok && result.BlockName.StartsWith("BHT_SIGN_V0633_"), "offline import " + code + " " + result.Error);
        }
        File.WriteAllLines(Path.Combine(Path.GetDirectoryName(typeof(AdsLibraryProbe).Assembly.Location), "ads-offline-probe.txt"), report, Encoding.UTF8);
        AcApp.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\nADS-OFFLINE-COMPLETE: " + report.Count(x => x.StartsWith("FAIL ")) + " FAIL");
    }
    [CommandMethod("BHTADSLIBRARYPROBE")]
    public static void Run()
    {
        string output = Environment.GetEnvironmentVariable("BHT_ADS_QA_OUTPUT") ?? Path.Combine(Path.GetTempPath(), "bht-ads-probe.txt");
        report.Clear();
        try
        {
            Check(BhtSignLibrary.Root != "", "ADSCivil provider available");
            var catalog = TdtSignLibrary.GetCatalog();
            Check(catalog.Count(e => e.Provider == "BHT") >= 460, "full ADSCivil catalog " + catalog.Count);
            Check(catalog.Where(e => e.Provider == "BHT").All(e => File.Exists(e.SourceDrawing)), "all catalog drawings exist");
            Check(catalog.Any(e => e.Code.Equals("IE.456A-1", StringComparison.OrdinalIgnoreCase)) && catalog.Any(e => e.Code.Equals("IE.456a1", StringComparison.OrdinalIgnoreCase)), "distinct numbered ADS variants retained");
            foreach (var entry in catalog.Where(e => e.Provider == "BHT"))
            {
                try
                {
                    using (var db = new Database(true, true))
                    {
                        var imported = TdtSignLibrary.EnsureBlock(db, entry.Code);
                        if (!imported.Ok) { Check(false, entry.Code + " " + imported.Error); continue; }
                        using (var source = new Database(false, true))
                        {
                            source.ReadDwgFile(entry.SourceDrawing, FileOpenMode.OpenForReadAndAllShare, false, ""); source.CloseInput(true);
                            using (var native = source.TransactionManager.StartOpenCloseTransaction())
                            using (var tr = db.TransactionManager.StartOpenCloseTransaction())
                            {
                                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                                var wrapper = (BlockTableRecord)tr.GetObject(table[imported.BlockName], OpenMode.ForRead);
                                var face = wrapper.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead)).OfType<BlockReference>().Single();
                                var definition = (BlockTableRecord)tr.GetObject(face.BlockTableRecord, OpenMode.ForRead);
                                var nativeTable = (BlockTable)native.GetObject(source.BlockTableId, OpenMode.ForRead);
                                var model = (BlockTableRecord)native.GetObject(nativeTable[BlockTableRecord.ModelSpace], OpenMode.ForRead);
                                // Import must retain native topology, rather than synthesize substitute icons.
                                Check(definition.Cast<ObjectId>().Count() == model.Cast<ObjectId>().Count(), entry.Code + " native entities retained");
                                int loops = definition.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead)).OfType<Hatch>().Sum(h => h.NumberOfLoops);
                                int nativeLoops = model.Cast<ObjectId>().Select(id => native.GetObject(id, OpenMode.ForRead)).OfType<Hatch>().Sum(h => h.NumberOfLoops);
                                Check(loops == nativeLoops, entry.Code + " native hatch loops retained");
                                Check(DrawOrder(native, model).SequenceEqual(DrawOrder(tr, definition)), entry.Code + " native draw order retained");
                                var extent = face.GeometricExtents;
                                double dimension = entry.Code.StartsWith("S.") ? Math.Max(extent.MaxPoint.X-extent.MinPoint.X, extent.MaxPoint.Y-extent.MinPoint.Y) : extent.MaxPoint.Y-extent.MinPoint.Y;
                                Check(Math.Abs(dimension - (entry.Code == "I.449" ? .65 : 1.8)) < 1e-6 && Math.Abs(extent.MinPoint.Y - .6) < 1e-6, entry.Code + " normalized face and post " + dimension.ToString("R") + "/" + extent.MinPoint.Y.ToString("R"));
                            }
                        }
                        string outline = TdtSignLibrary.EnsureOutlineBlock(db, imported.BlockName);
                        using (var tr = db.TransactionManager.StartOpenCloseTransaction())
                        {
                            var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                            Check(NoFill(tr, table[outline], new HashSet<ObjectId>()), entry.Code + " print mode removes only background");
                        }
                        Check(TdtSignLibrary.EnsureBlock(db, entry.Code).BlockName == imported.BlockName, entry.Code + " repeated import reuses block");
                    }
                }
                catch (System.Exception e) { Check(false, entry.Code + " exception " + e.Message); }
                File.WriteAllLines(output, report, Encoding.UTF8);
            }
            var document = AcApp.DocumentManager.MdiActiveDocument;
            var gallery = new[] { "R.415a", "R.415b", "P.127-80", "R.306-35", "DP.134-80", "W.207a", "W.239b@5.2", "S.501@350", "S.509a@4.5", "P.117@3.8", "IE.472a@850", "S.505a@3.5", "R.E,9b@07:30-19:00", "I.439", "IE.473" };
            for (int i = 0; i < gallery.Length; i++)
            {
                var result = TdtSignLibrary.EnsureBlock(document.Database, gallery[i]);
                Check(result.Ok, "gallery " + gallery[i] + " " + result.Error);
                if (!result.Ok) continue;
                var labels = new List<string>();
                using (var tr = document.Database.TransactionManager.StartTransaction())
                {
                    var table = (BlockTable)tr.GetObject(document.Database.BlockTableId, OpenMode.ForRead);
                    var model = (BlockTableRecord)tr.GetObject(table[BlockTableRecord.ModelSpace], OpenMode.ForWrite);
                    var placed = new BlockReference(new Point3d((i % 5)*8, -(i / 5)*4, 0), table[result.BlockName]);
                    model.AppendEntity(placed); tr.AddNewlyCreatedDBObject(placed, true);
                    Texts(tr, table[result.BlockName], labels, new HashSet<ObjectId>());
                    tr.Commit();
                }
                string value = SignPresentation.MetreValue(gallery[i]);
                if (value != "") Check(labels.Any(t => t == value || t == value + " m"), gallery[i] + " requested metres " + string.Join("|", labels));
                int? speed = SignPresentation.Speed(gallery[i], "");
                if (speed.HasValue) Check(labels.Contains(speed.Value.ToString()), gallery[i] + " requested speed " + string.Join("|", labels));
                if (gallery[i].Contains("07:30")) Check(labels.Contains("07:30") && labels.Contains("19:00") && !labels.Contains("6:00") && !labels.Contains("18:00"), "separate ADS time attributes updated " + string.Join("|", labels));
            }
            string bridge = SignCorrections.Bridge(document.Database, "CẦU BHT MỚI", "Km46+125", "ĐT.836", "BHT_BIENBAO");
            Check(bridge.StartsWith("BHT_I439_ADS_"), "custom bridge uses ADS face and new cache");
            var clear = TdtSignLibrary.EnsureBlock(document.Database, "P.102");
            Check(SignSupports.Ensure(document.Database, clear.BlockName, 2).StartsWith("BHT_SUPPORT"), "ADS face accepts two feet");
            document.Database.SaveAs(Path.Combine(Path.GetDirectoryName(output), "ADSCivil-gallery.dwg"), DwgVersion.Current);
        }
        catch (System.Exception e) { Check(false, "exception " + e); }
        File.WriteAllLines(output, report, Encoding.UTF8);
        AcApp.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\nADS-PROBE-COMPLETE: " + report.Count(x=>x.StartsWith("PASS ")) + " PASS / " + report.Count(x=>x.StartsWith("FAIL ")) + " FAIL");
    }
    static bool NoFill(Transaction tr, ObjectId id, HashSet<ObjectId> seen)
    {
        if (!seen.Add(id)) return true;
        foreach (ObjectId part in (BlockTableRecord)tr.GetObject(id, OpenMode.ForRead))
        {
            var e = tr.GetObject(part, OpenMode.ForRead) as Entity;
            if (e == null || !e.Visible) continue;
            if ((e is Hatch || e is Solid) && SignPrintPresentation.Role(e)==SignPrintPresentation.Background) return false;
            var m = e as MText; if (m != null && m.BackgroundFill) return false;
            var p = e as Polyline; if (p != null && p.Closed && (p.ConstantWidth != 0 || Enumerable.Range(0,p.NumberOfVertices).Any(i=>p.GetStartWidthAt(i)!=0 || p.GetEndWidthAt(i)!=0))) return false;
            var block = e as BlockReference; if (block != null && !NoFill(tr,block.BlockTableRecord,seen)) return false;
        }
        return true;
    }
    static IEnumerable<string> DrawOrder(Transaction tr, BlockTableRecord block)
    {
        var draw = (DrawOrderTable)tr.GetObject(block.DrawOrderTableId, OpenMode.ForRead);
        foreach (ObjectId id in draw.GetFullDrawOrder(0))
        {
            var entity = tr.GetObject(id, OpenMode.ForRead) as Entity;
            var hatch = entity as Hatch;
            double area = 0;
            if (hatch != null) { try { area = hatch.Area; } catch (Autodesk.AutoCAD.Runtime.Exception) { } }
            yield return entity.GetType().Name + (hatch == null ? "" : ":" + hatch.NumberOfLoops + ":" + Math.Round(area, 7).ToString(System.Globalization.CultureInfo.InvariantCulture));
            var nested = entity as BlockReference;
            if (nested != null) foreach (string item in DrawOrder(tr, (BlockTableRecord)tr.GetObject(nested.BlockTableRecord, OpenMode.ForRead))) yield return "nested:" + item;
        }
    }
    static void Texts(Transaction tr, ObjectId id, List<string> labels, HashSet<ObjectId> seen)
    {
        if (!seen.Add(id)) return;
        foreach (ObjectId part in (BlockTableRecord)tr.GetObject(id, OpenMode.ForRead))
        {
            var e = tr.GetObject(part, OpenMode.ForRead) as Entity; if (e == null || !e.Visible) continue;
            var t = e as DBText; if(t != null && (!(t is AttributeDefinition) || ((AttributeDefinition)t).Constant)) labels.Add(t.TextString);
            var m = e as MText; if(m != null) labels.Add(m.Text);
            var reference=e as BlockReference;
            if(reference!=null) { Texts(tr,reference.BlockTableRecord,labels,seen); foreach(ObjectId a in reference.AttributeCollection) { var attr=(AttributeReference)tr.GetObject(a,OpenMode.ForRead); if(!attr.Invisible)labels.Add(attr.TextString); } }
        }
    }
}
