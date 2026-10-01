using System;
using System.Collections.Generic;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;

namespace BHT.Bridge
{
    /// <summary>Thu phong / chon trong CAD. Goi khi da khoa tai lieu (hoac trong lenh).</summary>
    public static class CadView
    {
        /// <summary>Thu phong quanh (x, y) WCS voi chieu cao khung nhin h (don vi ban ve).</summary>
        public static void ZoomTo(Editor ed, double x, double y, double h)
        {
            using (ViewTableRecord view = ed.GetCurrentView())
            {
                Matrix3d wcs2dcs = Matrix3d.PlaneToWorld(view.ViewDirection);
                wcs2dcs = Matrix3d.Displacement(view.Target - Point3d.Origin) * wcs2dcs;
                wcs2dcs = Matrix3d.Rotation(-view.ViewTwist, view.ViewDirection, view.Target) * wcs2dcs;
                wcs2dcs = wcs2dcs.Inverse();
                Point3d c = new Point3d(x, y, 0).TransformBy(wcs2dcs);
                double ratio = view.Width / Math.Max(view.Height, 1e-9);
                view.CenterPoint = new Point2d(c.X, c.Y);
                view.Height = h;
                view.Width = h * ratio;
                ed.SetCurrentView(view);
            }
        }

        public static ObjectId IdFromHandle(Database db, string handle)
        {
            try
            {
                long v = Convert.ToInt64(handle, 16);
                ObjectId id;
                if (db.TryGetObjectId(new Handle(v), out id) && !id.IsErased) return id;
            }
            catch { }
            return ObjectId.Null;
        }

        /// <summary>Loai thuc the BHT va khoa: ("PT", survey_id) / ("NHAN", survey_id) / ("KH", object_id) / ("ANH", photo_id) / null.</summary>
        public static KeyValuePair<string, string>? Classify(Transaction tr, ObjectId id)
        {
            var o = tr.GetObject(id, OpenMode.ForRead);
            List<string> x;
            if ((x = BhtStore.XGet(o, "BHT_PT")) != null && x.Count > 0) return new KeyValuePair<string, string>("PT", x[0]);
            if ((x = BhtStore.XGet(o, "BHT_NHAN")) != null && x.Count > 0) return new KeyValuePair<string, string>("NHAN", x[0]);
            if ((x = BhtStore.XGet(o, "BHT_KH")) != null && x.Count > 0) return new KeyValuePair<string, string>("KH", x[0]);
            foreach (var app in new[] { "BHT_ANHPT", "BHT_ANHTEN", "BHT_ANHRS", "BHT_ANHDAN" })
                if ((x = BhtStore.XGet(o, app)) != null && x.Count > 0) return new KeyValuePair<string, string>("ANH", x[0]);
            return null;
        }
    }
}
