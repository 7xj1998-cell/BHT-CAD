using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace BHT.Bridge
{
    public static class SignAssembly
    {
        public static string Ensure(Database db, string[] names)
        {
            if (names.Length < 2) return names.FirstOrDefault() ?? "";
            if (names.Length > 20) throw new InvalidOperationException("Một trụ hỗ trợ tối đa 20 mặt biển.");
            string key;
            using (var hash = SHA256.Create()) key = BitConverter.ToString(hash.ComputeHash(Encoding.UTF8.GetBytes(string.Join(";", names)))).Replace("-", "").Substring(0, 24);
            string result = "BHT_ASSEMBLY_" + key;
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                if (table.Has(result)) return result;
                foreach (var name in names) if (!table.Has(name)) throw new InvalidOperationException("Thiếu mặt biển: " + name);
                table.UpgradeOpen();
                var assembly = new BlockTableRecord { Name = result };
                table.Add(assembly); tr.AddNewlyCreatedDBObject(assembly, true);
                double bottom = 0.6;
                // First item is the upper/main plate; supplementary plates follow below it.
                foreach (string name in names.Reverse())
                {
                    string faceName = "BHT_FACE_" + name;
                    ObjectId faceId;
                    if (table.Has(faceName)) faceId = table[faceName];
                    else
                    {
                        var face = new BlockTableRecord { Name = faceName };
                        faceId = table.Add(face); tr.AddNewlyCreatedDBObject(face, true);
                        var source = (BlockTableRecord)tr.GetObject(table[name], OpenMode.ForRead);
                        var sourceOrder = (DrawOrderTable)tr.GetObject(source.DrawOrderTableId, OpenMode.ForRead);
                        foreach (ObjectId id in sourceOrder.GetFullDrawOrder(0))
                        {
                            var entity = tr.GetObject(id, OpenMode.ForRead) as Entity;
                            if (entity == null) continue;
                            var line = entity as Line; var circle = entity as Circle;
                            bool post = line != null && line.StartPoint.DistanceTo(Point3d.Origin) < 1e-6 && Math.Abs(line.EndPoint.X) < 1e-6 && line.EndPoint.Y > 0 && line.EndPoint.Y <= 0.65;
                            bool foot = circle != null && circle.Center.DistanceTo(Point3d.Origin) < 1e-6 && circle.Radius <= 0.1;
                            if (post || foot) continue;
                            var copy = (Entity)entity.Clone(); face.AppendEntity(copy); tr.AddNewlyCreatedDBObject(copy, true);
                        }
                    }
                    using (var probe = new BlockReference(Point3d.Origin, faceId))
                    {
                        var bounds = probe.GeometricExtents;
                        double height = bounds.MaxPoint.Y - bounds.MinPoint.Y;
                        if (height < 1e-8) throw new InvalidOperationException("Mặt biển không có chiều cao: " + name);
                        var plate = new BlockReference(new Point3d(-(bounds.MinPoint.X + bounds.MaxPoint.X) / 2, bottom - bounds.MinPoint.Y, -bounds.MinPoint.Z), faceId);
                        assembly.AppendEntity(plate); tr.AddNewlyCreatedDBObject(plate, true);
                        bottom += height + 0.20;
                    }
                }
                // Stop at the lowest plate so outline mode never draws a pole through the icons.
                var pole = new Line(Point3d.Origin, new Point3d(0, 0.6, 0)) { ColorIndex = 7 };
                assembly.AppendEntity(pole); tr.AddNewlyCreatedDBObject(pole, true);
                var baseCircle = new Circle(Point3d.Origin, Vector3d.ZAxis, 0.06) { ColorIndex = 7 };
                assembly.AppendEntity(baseCircle); tr.AddNewlyCreatedDBObject(baseCircle, true);
                var draw = (DrawOrderTable)tr.GetObject(assembly.DrawOrderTableId, OpenMode.ForWrite);
                draw.MoveToBottom(new ObjectIdCollection(new[] { pole.ObjectId, baseCircle.ObjectId }));
                tr.Commit(); return result;
            }
        }
    }
    public sealed class SignAssemblyFunctions
    {
        [LispFunction("BHTSIGNASSEMBLY")]
        public static string Build(ResultBuffer args)
        {
            var names = Convert.ToString(args.AsArray()[0].Value, CultureInfo.InvariantCulture).Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries);
            return SignAssembly.Ensure(AcApp.DocumentManager.MdiActiveDocument.Database, names);
        }
    }
}
