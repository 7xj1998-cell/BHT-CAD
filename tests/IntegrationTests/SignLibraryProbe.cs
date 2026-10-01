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
                    lines.Add((Math.Abs(height - 1.8) < 1e-5 ? "PASS " : "FAIL ") + code + " face-height=" + height);
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
            lines.Add((before > 0 && FillCount(db, outline) == 0 && FillCount(db, filled) == before ? "PASS " : "FAIL ") + code + " independent-outline");
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
        lines.Add((FillCount(db, assemblyOutline) == 0 && FillCount(db, assembly) > 0 ? "PASS " : "FAIL ") + "assembly-outline-independent");
        lines.Add((speed80.Ok && speed80.BlockName == TdtSignLibrary.WrapperName("P.127-80") ? "PASS " : "FAIL ") + "description-speed80-reuse");
        File.WriteAllLines(Path.Combine(Path.GetDirectoryName(typeof(SignLibraryProbe).Assembly.Location), "probe.txt"), lines);
        foreach (string line in lines) App.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\n" + line);
    }
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
    private static int Count(Transaction tr, ObjectId bid, HashSet<ObjectId> seen)
    {
        if (!seen.Add(bid)) return 0;
        int n = 0;
        foreach (ObjectId id in (BlockTableRecord)tr.GetObject(bid, OpenMode.ForRead))
        {
            var e = tr.GetObject(id, OpenMode.ForRead) as Entity;
            if (e != null && e.Visible && (e is Hatch || e is Solid)) n++;
            var nested = e as BlockReference;
            if (nested != null) n += Count(tr, nested.BlockTableRecord, seen);
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
            if (e is Hatch) { hatches++; if (foreground) valid = false; } else foreground = true;
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
        if (hatches > 0) lines.Add((valid ? "PASS " : "FAIL ") + code + " hatch-bottom=" + hatches);
    }
}
