using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using BHT.Core;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;
namespace BHT.Bridge
{
    public static class SignLayout
    {
        internal static string Hash(string value)
        { using (var hash = SHA256.Create()) return BitConverter.ToString(hash.ComputeHash(Encoding.UTF8.GetBytes(value))).Replace("-", "").Substring(0, 24); }
        public static string Ensure(Database db, string[] names, string layout, double gap, double clearance)
        {
            if (names == null) throw new ArgumentNullException("names");
            string error = SignLayoutSpec.Validate(layout, names.Length, gap, clearance);
            if (error != "") throw new ArgumentException(error);
            if (layout == "LEGACY") return SignAssembly.Ensure(db, names);
            string name = "BHT_SIGN_LAYOUT_V0641_" + Hash(string.Join(";", names) + "|" + layout + "|" + gap.ToString("R", CultureInfo.InvariantCulture) + "|" + clearance.ToString("R", CultureInfo.InvariantCulture));
            using (var check = db.TransactionManager.StartOpenCloseTransaction())
                if (((BlockTable)check.GetObject(db.BlockTableId, OpenMode.ForRead)).Has(name)) return name;
            // Face-only clones retain native hatch associations and nested attributes.
            string[] faces = names.Select(n => SignSupports.Ensure(db, n, 0)).ToArray();
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var table = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForWrite);
                var bounds = new List<Extents3d>();
                foreach (string face in faces) using (var probe = new BlockReference(Point3d.Origin, table[face])) bounds.Add(probe.GeometricExtents);
                var boxes = SignLayoutSpec.Arrange(layout, bounds.Select(b => new SignPlateBox(0, 0, b.MaxPoint.X - b.MinPoint.X, b.MaxPoint.Y - b.MinPoint.Y)).ToList(), gap, clearance);
                var block = new BlockTableRecord { Name = name }; table.Add(block); tr.AddNewlyCreatedDBObject(block, true);
                double left = boxes.Min(b => b.Left), right = boxes.Max(b => b.Right), top = boxes.Max(b => b.Top);
                double[] posts = layout == "CAP1_2" ? new[] { left + (right-left)*.2, right-(right-left)*.2 } : layout == "CAP1_9" ? new[] { left-.25, right+.25 } : new[] { 0.0 };
                bool frame = layout == "CAP1_9" || layout == "CAP1_10";
                double beamY = top + .15;
                var supports = new ObjectIdCollection();
                Action<Entity> add = e => { e.ColorIndex = 7; block.AppendEntity(e); tr.AddNewlyCreatedDBObject(e, true); supports.Add(e.ObjectId); };
                foreach (double x in posts)
                {
                    add(new Line(new Point3d(x,0,0), new Point3d(x,frame ? beamY : clearance,0)));
                    add(new Circle(new Point3d(x,0,0), Vector3d.ZAxis,.06));
                    add(SignSupports.FilledFoot(x));
                }
                if (frame)
                {
                    double start = posts.Min(), end = layout == "CAP1_10" ? right+.15 : posts.Max();
                    add(new Line(new Point3d(start,beamY,0),new Point3d(end,beamY,0)));
                    add(new Line(new Point3d(start,beamY+.08,0),new Point3d(end,beamY+.08,0)));
                    foreach (var box in boxes) add(new Line(new Point3d(box.X,box.Top,0),new Point3d(box.X,beamY,0)));
                }
                else if (boxes.Count > 1 && right-left > boxes.Max(b => b.Width)+.01)
                    add(new Line(new Point3d(left,clearance-.04,0),new Point3d(right,clearance-.04,0)));
                for (int i=0;i<faces.Length;i++)
                {
                    var b = bounds[i]; var box = boxes[i];
                    var reference = new BlockReference(new Point3d(box.X-(b.MinPoint.X+b.MaxPoint.X)/2,box.Y-b.MinPoint.Y,-b.MinPoint.Z),table[faces[i]]);
                    block.AppendEntity(reference); tr.AddNewlyCreatedDBObject(reference,true);
                }
                ((DrawOrderTable)tr.GetObject(block.DrawOrderTableId,OpenMode.ForWrite)).MoveToBottom(supports);
                tr.Commit(); return name;
            }
        }
    }
    public sealed class SignLayoutFunctions
    {
        [LispFunction("BHTSIGNLAYOUT")]
        public static string Build(ResultBuffer args)
        {
            if (args == null || args.AsArray().Length != 4) throw new ArgumentException("Cần block, bố trí, khoảng cách và chiều cao đáy biển.");
            var v=args.AsArray();
            return SignLayout.Ensure(AcApp.DocumentManager.MdiActiveDocument.Database,Convert.ToString(v[0].Value).Split(';'),Convert.ToString(v[1].Value),Convert.ToDouble(v[2].Value,CultureInfo.InvariantCulture),Convert.ToDouble(v[3].Value,CultureInfo.InvariantCulture));
        }
    }
}
