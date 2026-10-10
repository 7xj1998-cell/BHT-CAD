using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using BHT.Bridge;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

public sealed class OriginProbe
{
    [CommandMethod("BHTORIGINPROBE")]
    public void Run()
    {
        var report = new List<string>();
        Action<string,bool> check = (name, ok) => report.Add((ok ? "PASS " : "FAIL ") + name);
        var db = AcApp.DocumentManager.MdiActiveDocument.Database;
        string folder = Path.GetDirectoryName(typeof(OriginProbe).Assembly.Location);
        try
        {
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                var model = (BlockTableRecord)tr.GetObject(table[BlockTableRecord.ModelSpace], OpenMode.ForRead);
                var markers = model.Cast<ObjectId>().Where(id => BhtStore.XGet(tr.GetObject(id, OpenMode.ForRead), "BHT_SIGN_ORIGIN") != null).ToList();
                check("two-marker-inserts", markers.Count == 2);
                foreach (var id in markers)
                {
                    var reference = (BlockReference)tr.GetObject(id, OpenMode.ForRead);
                    var tag = BhtStore.XGet(reference, "BHT_SIGN_ORIGIN");
                    var classification = CadView.Classify(tr, id);
                    check(tag[0] + " palette-object-selection", classification.HasValue && classification.Value.Key == "KH" && classification.Value.Value == tag[0]);
                    var layer = (LayerTableRecord)tr.GetObject(reference.LayerId, OpenMode.ForRead);
                    check(tag[0] + " symbol-layer-visible", layer.Name == "BHT_KYHIEU" && !layer.IsOff && !layer.IsFrozen);
                    var block = (BlockTableRecord)tr.GetObject(reference.BlockTableRecord, OpenMode.ForRead);
                    var disk = (Polyline)tr.GetObject(block.Cast<ObjectId>().Single(), OpenMode.ForRead);
                    check(tag[0] + " circular-disk-no-inner-hole", disk.Closed && disk.NumberOfVertices == 2 && Math.Abs(disk.ConstantWidth-.07)<1e-9 && disk.GetPoint2dAt(0).GetDistanceTo(disk.GetPoint2dAt(1)) == disk.ConstantWidth && disk.GetBulgeAt(0) == 1 && disk.GetBulgeAt(1) == 1);
                }
                var layers = (LayerTable)tr.GetObject(db.LayerTableId, OpenMode.ForRead);
                check("survey-point-layer-hidden", ((LayerTableRecord)tr.GetObject(layers["ORIGIN_QA_POINTS"],OpenMode.ForRead)).IsOff);
                tr.Commit();
            }
            db.DxfOut(Path.Combine(folder,"origin-0.6.34.dxf"),16,DwgVersion.AC1032);
        }
        catch (System.Exception ex) { check("exception "+ex, false); }
        File.WriteAllLines(Path.Combine(folder,"origin-probe.txt"),report,Encoding.UTF8);
        AcApp.DocumentManager.MdiActiveDocument.Editor.WriteMessage("\nORIGIN-PROBE-COMPLETED");
    }
}
