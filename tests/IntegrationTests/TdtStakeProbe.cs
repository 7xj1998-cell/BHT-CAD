using System;
using System.IO;
using System.Linq;
using System.Text;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using BHT.Bridge;

// Run in AutoCAD/Core Console after NETLOAD; fixture stays in a separate memory database.
public class TdtStakeProbe
{
    [CommandMethod("BHTSTAKEREGRESSION")]
    public void Run()
    {
        var log = new StringBuilder();
        int failures = 0;
        Action<string, bool> check = (name, ok) =>
        {
            log.AppendLine((ok ? "PASS " : "FAIL ") + name);
            if (!ok) failures++;
        };
        double station;
        check("station-overlong-rejected", !Tdt91Stakes.TryStation("Km1+1000", out station));
        check("station-malformed-decimal-rejected", !Tdt91Stakes.TryStation("Km1+020.5.2", out station));
        check("station-comma", Tdt91Stakes.TryStation("Km1+020,50", out station) && Math.Abs(station - 1020.5) < 1e-9);
        using (var db = new Database(true, true))
        {
            string routeHandle;
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForWrite);
                var model = (BlockTableRecord)tr.GetObject(table[BlockTableRecord.ModelSpace], OpenMode.ForWrite);
                var route = new Polyline();
                route.AddVertexAt(0, Point2d.Origin, 0, 0, 0);
                route.AddVertexAt(1, new Point2d(1000, 0), 0, 0, 0);
                model.AppendEntity(route); tr.AddNewlyCreatedDBObject(route, true);
                routeHandle = route.Handle.ToString();
                var leaf = new BlockTableRecord { Name = "STAKE_LEAF" };
                table.Add(leaf); tr.AddNewlyCreatedDBObject(leaf, true);
                var text = new DBText { TextString = "Km1+020", Position = new Point3d(10, 0, 0), Height = 1 };
                leaf.AppendEntity(text); tr.AddNewlyCreatedDBObject(text, true);
                var parent = new BlockTableRecord { Name = "STAKE_PARENT" };
                table.Add(parent); tr.AddNewlyCreatedDBObject(parent, true);
                var inner = new BlockReference(new Point3d(5, 0, 0), leaf.ObjectId) { ScaleFactors = new Scale3d(2) };
                parent.AppendEntity(inner); tr.AddNewlyCreatedDBObject(inner, true);
                var outer = new BlockReference(new Point3d(100, 0, 0), parent.ObjectId) { Rotation = Math.PI / 2 };
                model.AppendEntity(outer); tr.AddNewlyCreatedDBObject(outer, true);
                // Same station/location as nested block: one candidate after deduplication.
                var duplicate = new DBText { TextString = "Km1+020", Position = new Point3d(100, 25, 0), Height = 1 };
                model.AppendEntity(duplicate); tr.AddNewlyCreatedDBObject(duplicate, true);
                var attrs = new BlockReference(Point3d.Origin, leaf.ObjectId);
                model.AppendEntity(attrs); tr.AddNewlyCreatedDBObject(attrs, true);
                foreach (var spec in new[] { new { Text = "Km1+005", X = 5.0 }, new { Text = "Km1+015", X = 15.0 } })
                {
                    var attribute = new AttributeReference { TextString = spec.Text, Tag = spec.Text, Height = 1, Position = new Point3d(spec.X, 2, 0) };
                    attrs.AttributeCollection.AppendAttribute(attribute); tr.AddNewlyCreatedDBObject(attribute, true);
                }
                var mtext = new MText { Contents = "{\\C1;Km1+040,50}", Location = new Point3d(40.5, 2, 0), TextHeight = 1 };
                model.AppendEntity(mtext); tr.AddNewlyCreatedDBObject(mtext, true);
                foreach (var spec in new[] { new { Text = "Km1+1000", Y = 2.0 }, new { Text = "Km1+999", Y = 300.0 } })
                {
                    var invalid = new DBText { TextString = spec.Text, Position = new Point3d(50, spec.Y, 0), Height = 1 };
                    model.AppendEntity(invalid); tr.AddNewlyCreatedDBObject(invalid, true);
                }
                tr.Commit();
            }
            var candidates = Tdt91Stakes.Scan(db, routeHandle, 30);
            check("nested-block-transform", candidates.Any(c => c.Station == 1020 && Math.Abs(c.RawDistance - 100) < 1e-8 && Math.Abs(c.Offset - 25) < 1e-8));
            check("nested-duplicate-removed", candidates.Count(c => c.Station == 1020 && Math.Abs(c.RawDistance - 100) < 1e-8) == 1);
            check("each-attribute-read", candidates.Any(c => c.Station == 1005) && candidates.Any(c => c.Station == 1015));
            check("formatted-mtext", candidates.Any(c => c.Station == 1040.5));
            check("offset-filter", !candidates.Any(c => c.Station == 1999));
            check("no-truncated-station", !candidates.Any(c => c.Station == 1100));
            var again = Tdt91Stakes.Scan(db, routeHandle, 30);
            check("repeat-scan-stable", candidates.Count == again.Count && candidates.Zip(again, (a, b) => a.Handle == b.Handle && a.RawDistance == b.RawDistance).All(x => x));
        }
        log.AppendLine("FAILURES=" + failures);
        string path = Environment.GetEnvironmentVariable("BHT_QA_OUTPUT");
        if (string.IsNullOrEmpty(path)) throw new InvalidOperationException("Set BHT_QA_OUTPUT to the test report path.");
        File.WriteAllText(path, log.ToString(), new UTF8Encoding(false));
    }
}
