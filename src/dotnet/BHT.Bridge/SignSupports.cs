using System;
using System.Globalization;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace BHT.Bridge
{
    public static class SignSupports
    {
        internal static Polyline FilledFoot(double x)
        {
            var dot = new Polyline(2) { Closed=true, ColorIndex=7 };
            dot.AddVertexAt(0,new Point2d(x-.03,0),1,.06,.06);
            dot.AddVertexAt(1,new Point2d(x+.03,0),1,.06,.06);
            return dot;
        }
        public static string Ensure(Database db, string sourceName, int count)
        {
            if (count < 0 || count > 100) throw new ArgumentException("Số trụ/chân ký hiệu phải từ 0 đến 100.");
            if (count == 1) return sourceName;
            string key;
            using (var hash = SHA256.Create()) key = BitConverter.ToString(hash.ComputeHash(Encoding.UTF8.GetBytes(sourceName))).Replace("-", "").Substring(0, 24);
            string name = "BHT_SUPPORT_V0645_" + count.ToString(CultureInfo.InvariantCulture) + "_" + key;
            ObjectId sourceId;
            using (var tr = db.TransactionManager.StartOpenCloseTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                if (table.Has(name)) return name;
                if (!table.Has(sourceName)) throw new ArgumentException("Không tìm thấy block ký hiệu: " + sourceName);
                sourceId = table[sourceName];
            }
            // Clone the definition and its dependencies to keep hatch associations and attributes intact.
            using (var scratch = new Database(true, true))
            {
                var map = new IdMapping();
                db.WblockCloneObjects(new ObjectIdCollection(new[] { sourceId }), scratch.BlockTableId, map, DuplicateRecordCloning.MangleName, false);
                ObjectId privateId = map[sourceId].Value;
                using (var native = db.TransactionManager.StartOpenCloseTransaction())
                using (var tr = scratch.TransactionManager.StartTransaction())
                {
                    BhtSignLibrary.RestoreDrawOrder(native, tr, sourceId, privateId, map, new HashSet<ObjectId>());
                    var block = (BlockTableRecord)tr.GetObject(privateId, OpenMode.ForWrite);
                    block.Name = name;
                    double height = 0.62;
                    var entities = block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead) as Entity).Where(e => e != null).ToList();
                    foreach (var entity in entities)
                    {
                        var line = entity as Line;
                        var circle = entity as Circle;
                        bool pole = line != null && line.StartPoint.DistanceTo(Point3d.Origin) < 1e-6 && Math.Abs(line.EndPoint.X) < 1e-6 && Math.Abs(line.EndPoint.Z) < 1e-6 && line.EndPoint.Y > 0 && line.EndPoint.Y <= 0.65;
                        bool foot = circle != null && circle.Center.DistanceTo(Point3d.Origin) < 1e-6 && circle.Radius <= 0.1;
                        if (!pole && !foot) continue;
                        if (pole) height = line.EndPoint.Y;
                        entity.UpgradeOpen(); entity.Erase();
                    }
                    if (count > 0)
                    {
                        Extents3d bounds;
                        using (var probe = new BlockReference(Point3d.Origin, privateId)) bounds = probe.GeometricExtents;
                        double width = bounds.MaxPoint.X - bounds.MinPoint.X;
                        if (double.IsNaN(width) || double.IsInfinity(width) || width <= 1e-8) throw new InvalidOperationException("Mặt biển không có chiều rộng hợp lệ.");
                        double center = (bounds.MinPoint.X + bounds.MaxPoint.X) / 2;
                        var supports = new ObjectIdCollection();
                        for (int i = 0; i < count; i++)
                        {
                            double x = center + width * 0.6 * (i / (double)(count - 1) - 0.5);
                            var pole = new Line(new Point3d(x, 0, 0), new Point3d(x, height, 0)) { ColorIndex = 7 };
                            var foot = new Circle(new Point3d(x, 0, 0), Vector3d.ZAxis, 0.06) { ColorIndex = 7, Visible = count != 2 };
                            block.AppendEntity(pole); tr.AddNewlyCreatedDBObject(pole, true); supports.Add(pole.ObjectId);
                            block.AppendEntity(foot); tr.AddNewlyCreatedDBObject(foot, true); supports.Add(foot.ObjectId);
                            if(count!=2) {var dot=FilledFoot(x);block.AppendEntity(dot);tr.AddNewlyCreatedDBObject(dot,true);supports.Add(dot.ObjectId);}
                        }
                        ((DrawOrderTable)tr.GetObject(block.DrawOrderTableId, OpenMode.ForWrite)).MoveToBottom(supports);
                    }
                    tr.Commit();
                }
                map = new IdMapping();
                scratch.WblockCloneObjects(new ObjectIdCollection(new[] { privateId }), db.BlockTableId, map, DuplicateRecordCloning.MangleName, false);
                using (var native = scratch.TransactionManager.StartOpenCloseTransaction())
                using (var tr = db.TransactionManager.StartTransaction())
                {
                    BhtSignLibrary.RestoreDrawOrder(native, tr, privateId, map[privateId].Value, map, new HashSet<ObjectId>());
                    ((BlockTableRecord)tr.GetObject(map[privateId].Value, OpenMode.ForWrite)).Name = name;
                    tr.Commit();
                }
            }
            return name;
        }
    }

    public sealed class SignSupportFunctions
    {
        [LispFunction("BHTSIGNFEET")]
        public static ResultBuffer Feet(ResultBuffer args)
        {
            string name = Convert.ToString(args.AsArray()[0].Value);
            var db = AcApp.DocumentManager.MdiActiveDocument.Database;
            using (var tr = db.TransactionManager.StartOpenCloseTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                var block = (BlockTableRecord)tr.GetObject(table[name], OpenMode.ForRead);
                var points = block.Cast<ObjectId>().Select(id => tr.GetObject(id, OpenMode.ForRead) as Circle)
                    .Where(c => c != null && Math.Abs(c.Center.Y) < 1e-6 && Math.Abs(c.Center.Z) < 1e-6 && c.Radius <= 0.1)
                    .OrderBy(c => c.Center.X).Select(c => c.Center).ToList();
                var result = new ResultBuffer();
                foreach (var p in points)
                    foreach (double coordinate in new[] { p.X, p.Y, p.Z }) result.Add(new TypedValue((int)LispDataType.Double, coordinate));
                return result;
            }
        }

        [LispFunction("BHTSIGNPOSTS")]
        public static string Build(ResultBuffer args)
        {
            if (args == null || args.AsArray().Length != 2) throw new ArgumentException("Cần tên block và số trụ/chân.");
            var values = args.AsArray();
            return SignSupports.Ensure(AcApp.DocumentManager.MdiActiveDocument.Database, Convert.ToString(values[0].Value), Convert.ToInt32(values[1].Value, CultureInfo.InvariantCulture));
        }
    }
}
