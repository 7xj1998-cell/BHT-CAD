using System;
using System.Collections.Generic;
using System.IO;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using BHT.Core;
using BHT.Bridge;
using App = Autodesk.AutoCAD.ApplicationServices.Core.Application;
public class SignLibraryProbe
{
    [CommandMethod("BHTSIGNPROBE")]
    public static void Run()
    {
        var lines = new List<string>();
        var db = App.DocumentManager.MdiActiveDocument.Database;
        foreach (string code in new[] { "P.127-80", "P.127-40", "P.127", "I.434a", "R.415", "W.207c" })
        {
            var result = TdtSignLibrary.EnsureBlock(db, code);
            lines.Add((result.Ok ? "PASS " : "FAIL ") + code + " import " + result.Error + " scale=" + result.FaceScale);
            if (!result.Ok) continue;
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                var wrapper = (BlockTableRecord)tr.GetObject(table[result.BlockName], OpenMode.ForRead);
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
        var speed80 = TdtSignLibrary.EnsureBlock(db, SignPresentation.ResolveCode("P.127", "bbtron1m25 gioihan80"));
        lines.Add((speed80.Ok && speed80.BlockName == TdtSignLibrary.WrapperName("P.127-80") ? "PASS " : "FAIL ") + "description-speed80-reuse");
        File.WriteAllLines(Path.Combine(Path.GetDirectoryName(typeof(SignLibraryProbe).Assembly.Location), "probe.txt"), lines);
        foreach (string line in lines) App.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\n" + line);
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
