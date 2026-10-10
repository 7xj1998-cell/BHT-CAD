using System;
using System.Collections.Generic;
using System.Linq;
using Autodesk.AutoCAD.Colors;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
namespace BHT.Bridge
{
    // Roles are assigned on a private import, never written to the source DWG.
    public static class SignPrintPresentation
    {
        private const string App = "BHT_SIGN_PRINT";
        public const string Background = "BACKGROUND", Ink = "INK", Void = "VOID", Paper = "PAPER", Backing = "BACKING", DerivedInk = "DERIVED_INK", Frame = "FRAME";
        private sealed class Part
        {
            public ObjectId Id; public Extents3d Bounds; public double Area; public bool Convex, Rect, White, Black, Red, Fill;
            public string Color; public int Order;
            public List<Point2d> Outline; public int Loops;
            public double Width { get { return Bounds.MaxPoint.X-Bounds.MinPoint.X; } }
            public double Height { get { return Bounds.MaxPoint.Y-Bounds.MinPoint.Y; } }
        }
        public static string Role(Entity entity)
        {
            using(var data=entity.GetXDataForApplication(App))
                return data==null ? "" : data.AsArray().Where(v=>v.TypeCode==1000).Select(v=>Convert.ToString(v.Value)).FirstOrDefault() ?? "";
        }
        private static void Register(Transaction tr, Database db)
        {
            var table=(RegAppTable)tr.GetObject(db.RegAppTableId,OpenMode.ForRead); if(table.Has(App)) return;
            table.UpgradeOpen(); var app=new RegAppTableRecord {Name=App};table.Add(app);tr.AddNewlyCreatedDBObject(app,true);
        }
        private static void Set(Transaction tr, ObjectId id, string role)
        {
            var e=(Entity)tr.GetObject(id,OpenMode.ForWrite);
            bool holes=role=="BACKGROUND_INNER_INK";
            using(var data=new ResultBuffer(new TypedValue(1001,App),new TypedValue(1000,holes ? Background : role),new TypedValue(1000,holes ? "FILL_INNER_LOOPS" : ""))) e.XData=data;
        }
        internal static void MarkPaper(Transaction tr,ObjectId id) {Register(tr,id.Database);Set(tr,id,Paper);}
        internal static void MarkDerivedInk(Transaction tr,ObjectId id) {Register(tr,id.Database);Set(tr,id,DerivedInk);}
        internal static void MarkFrame(Transaction tr,ObjectId id) {Register(tr,id.Database);Set(tr,id,Frame);}
        internal static List<Tuple<ObjectId,ObjectId>> BorderPairs(Transaction tr,ObjectId block) {
            var parts=new List<Part>();Collect(tr,block,Matrix3d.Identity,new HashSet<ObjectId>(),parts);
            var panels=parts.Where(p=>p.Fill && p.Convex && tr.GetObject(p.Id,OpenMode.ForRead).OwnerId==block && Role((Entity)tr.GetObject(p.Id,OpenMode.ForRead))==Background).ToList();
            var pairs=new List<Tuple<ObjectId,ObjectId>>();
            foreach(var outer in panels) {
                if(outer.Loops!=1)continue;
                var inner=panels.Where(p=>p.Id!=outer.Id && Contains(outer,p) && ContainsOutline(outer,p)
                    && p.Width>=outer.Width*.65 && p.Height>=outer.Height*.65
                    && Math.Abs(p.Width/outer.Width-p.Height/outer.Height)<.10
                    && p.Width<outer.Width*(1-1e-6) && p.Height<outer.Height*(1-1e-6))
                    .OrderByDescending(p=>p.Width*p.Height).FirstOrDefault();
                if(inner!=null)pairs.Add(Tuple.Create(outer.Id,inner.Id));
            }
            return pairs;
        }
        internal static List<Point2d> HullOutline(Hatch hatch) {
            var points=Enumerable.Range(0,hatch.NumberOfLoops).SelectMany(n=>Polygon(hatch.GetLoopAt(n))).OrderBy(p=>p.X).ThenBy(p=>p.Y).ToList();
            var hull=new List<Point2d>();
            foreach(var p in points){while(hull.Count>=2 && Cross(hull[hull.Count-2],hull.Last(),p)<=1e-12)hull.RemoveAt(hull.Count-1);hull.Add(p);}
            int lower=hull.Count;
            for(int i=points.Count-2;i>=0;i--){var p=points[i];while(hull.Count>lower && Cross(hull[hull.Count-2],hull.Last(),p)<=1e-12)hull.RemoveAt(hull.Count-1);hull.Add(p);}
            if(hull.Count>1)hull.RemoveAt(hull.Count-1);return hull;
        }
        private static double Cross(Point2d a,Point2d b,Point2d c){return (b.X-a.X)*(c.Y-a.Y)-(b.Y-a.Y)*(c.X-a.X);}
        internal static bool HasInkHoles(Entity entity) {
            using(var data=entity.GetXDataForApplication(App))return data!=null && data.AsArray().Any(v=>v.TypeCode==1000 && Convert.ToString(v.Value)=="FILL_INNER_LOOPS");
        }
        internal static bool NeedsPaper(Entity entity)
        {
            var h=entity as Hatch;if(h==null || h.NumberOfLoops<8 || Role(entity)!=Ink)return false;
            var color=entity.Color;int red=color.Red,green=color.Green,blue=color.Blue;
            if(color.ColorMethod==ColorMethod.ByAci){int rgb=EntityColor.LookUpRgb((byte)color.ColorIndex);red=(rgb>>16)&255;green=(rgb>>8)&255;blue=rgb&255;}
            // Checkered red panels can share the white hatch of an adjacent arrow.
            // A private paper mask keeps the checker holes white after that arrow turns black.
            return red>200 && green<80 && blue<80;
        }
        public static void TagImport(Transaction source, Transaction target, Database db, ObjectId model, IdMapping map, string code)
        {
            var roles=Classify(source,model);
            ApplyAuditedRoles(source,model,code,roles);
            Register(target,db); foreach(var pair in roles) if(map.Contains(pair.Key)) Set(target,map[pair.Key].Value,pair.Value);
        }
        // Native handles refer to the packaged snapshot, not destination drawing handles.
        // These cases were checked against all 467 colored/monochrome faces. Multi-loop
        // pictograms and oversized SHX text extents cannot be classified by bounds alone.
        private static readonly string[] AuditedRoles = {
            "IE.457a|BACKGROUND|87,88", "IE.461a|BACKGROUND|8C,8D",
            "IE.463b|BACKGROUND|8C", "IE.474|BACKGROUND|C0",
            "IE.464A-1|BACKGROUND|20,21,22", "IE.464A-2|BACKGROUND|20,21,22",
            "I.402|PAPER|51B", "I.437|INK|555", "I.442|INK|5C4", "I.443|INK|5D1",
            "IE.453c|INK|85", "IE.452a|INK|C2", "IE.452b|INK|AE", "IE.452c|INK|AE",
            "I.445a|INK|9B3", "I.445f|INK|2CE",
            "I.418|INK|142D", "I.418|VOID|1433",
            "R.310|BACKGROUND|1CB", "R.310|INK|1CA", "R.310b|BACKGROUND_INNER_INK|CB2",
            "W.243a|INK|B04", "W.243b|INK|B04,B28",
            "P.131a|BACKGROUND|7D7", "P.131b|BACKGROUND|7D7", "P.131c|BACKGROUND|7D7",
            "R.E9a|BACKGROUND|14CF", "R.E9b|BACKGROUND|14CF",
            "R.E,9A|BACKGROUND|17E8", "R.E,9B|BACKGROUND|180E",
            "R.E10a|BACKGROUND|14CF", "R.E10b|BACKGROUND|14CF",
            "R.E,10A|BACKGROUND|1867", "R.E,10B|BACKGROUND|1896",
            "R.E9d|VOID|14FC", "R.E,9D|VOID|183E",
            "P.127a|VOID|4E7", "P.127a|INK|528,611",
            "IE.467a|PAPER|C8", "IE.467a|INK|C7,D4,CA,C9,D3,D2,D1,D0,CF,CE,CD,CC,CB",
            "IE.467b|PAPER|CF", "IE.467b|INK|CE,DB,D1,D0,DA,D9,D8,D7,D6,D5,D4,D3,D2",
            "DP.127b|BACKING|5BE,5BD,5BC", "DP.127b|INK|59B,5A4,5A5,5AC,5AD,5B3",
            "P.127D-2|VOID|144,18F,191", "P.127D-2|INK|194,197,19A,19D"
        };
        private static void ApplyAuditedRoles(Transaction tr,ObjectId model,string code,Dictionary<ObjectId,string> roles)
        {
            var rules=new Dictionary<string,string>(StringComparer.OrdinalIgnoreCase);
            foreach(string row in AuditedRoles) {
                var cells=row.Split('|');if(!cells[0].Equals(code,StringComparison.OrdinalIgnoreCase))continue;
                foreach(string handle in cells[2].Split(','))rules[handle]=cells[1];
            }
            if(rules.Count==0)return;
            var parts=new List<Part>();Collect(tr,model,Matrix3d.Identity,new HashSet<ObjectId>(),parts);
            foreach(var part in parts) {
                string role;if(rules.TryGetValue(part.Id.Handle.ToString(),out role))roles[part.Id]=role;
            }
        }
        // Fallback/custom definitions may predate the import metadata. Work on their clone only.
        public static void TagMissing(Transaction tr, ObjectId block, HashSet<ObjectId> seen)
        {
            if(!seen.Add(block)) return;
            var b=(BlockTableRecord)tr.GetObject(block,OpenMode.ForRead);
            bool direct=b.Cast<ObjectId>().Select(id=>tr.GetObject(id,OpenMode.ForRead)).Any(o=>o is Hatch || o is Solid);
            if(direct)
            {
                Register(tr,block.Database);
                foreach(var p in Classify(tr,block)) {var e=(Entity)tr.GetObject(p.Key,OpenMode.ForRead);if(Role(e)=="") Set(tr,p.Key,p.Value);}
            }
            foreach(ObjectId id in b) {var r=tr.GetObject(id,OpenMode.ForRead) as BlockReference;if(r!=null)TagMissing(tr,r.BlockTableRecord,seen);}
        }
        public static Dictionary<ObjectId,string> Classify(Transaction tr, ObjectId block)
        {
            var parts=new List<Part>();Collect(tr,block,Matrix3d.Identity,new HashSet<ObjectId>(),parts);
            var fills=parts.Where(p=>p.Fill && p.Width>1e-9 && p.Height>1e-9).ToList();
            var roles=new Dictionary<ObjectId,string>(); if(fills.Count==0) return roles;
            double left=fills.Min(p=>p.Bounds.MinPoint.X),right=fills.Max(p=>p.Bounds.MaxPoint.X),bottom=fills.Min(p=>p.Bounds.MinPoint.Y),top=fills.Max(p=>p.Bounds.MaxPoint.Y);
            foreach(var p in fills)
            {
                double density=p.Area/(p.Width*p.Height);
                bool large=p.Width>=(right-left)*.49 && p.Height>=(top-bottom)*.49;
                bool behind=parts.Any(q=>q.Order>p.Order && q.Id!=p.Id && Contains(p,q) && (q.Fill || q.Area<0));
                bool text=parts.Any(q=>q.Area<0 && q.Order>p.Order && Contains(p,q));
                bool bg=p.Convex && density>.33 && !p.Black && ((large && (p.Loops<=1 || p.Rect || p.White)) || text);
                if(p.Black) bg=p.Convex && density>.90 && ((p.Width>=(right-left)*.85 && p.Height>=(top-bottom)*.85 && behind) || text);
                if(p.Red && !p.Rect && p.Loops>1)bg=false; // Native prohibition rim and slash are foreground.
                roles[p.Id]=bg ? Background : Ink;
            }
            foreach(var p in fills)
            {
                if(roles[p.Id]==Background || !p.Rect || p.Area/(p.Width*p.Height)<.90) continue;
                var parent=Parent(fills,p);
                bool content=parts.Any(q=>q.Order>p.Order && q.Id!=p.Id && Contains(p,q) && (q.Area<0 || (q.Fill && q.Width<p.Width*.95 && q.Height<p.Height*.95)));
                bool frame=fills.Any(q=>q.Order>p.Order && q.Color!=p.Color && q.Rect && Contains(p,q) && q.Width>p.Width*.85 && q.Height>p.Height*.85);
                bool text=parts.Any(q=>q.Area<0 && q.Order>p.Order && Contains(p,q));
                if(content && ((parent!=null && roles[parent.Id]==Background) || frame || text)) roles[p.Id]=Background;
            }
            foreach(var p in fills)
            {
                if(roles[p.Id]==Background) continue;
                var parent=Parent(fills,p);
                if(parent==null || roles[parent.Id]==Background) continue;
                if(p.White && !parent.White) roles[p.Id]=Void;
                else if(parent.White && fills.Any(q=>q.Order<p.Order && roles[q.Id]==Background && q.Color==p.Color && Contains(q,p))) roles[p.Id]=Void;
            }
            return roles;
        }
        private static Part Parent(List<Part> fills, Part p)
        { return fills.Where(q=>q.Order<p.Order && q.Id!=p.Id && Contains(q,p) && (ContainsOutline(q,p) || (q.Red && q.Loops>=8 && p.White))).OrderBy(q=>q.Width*q.Height).ThenByDescending(q=>q.Order).FirstOrDefault(); }
        private static bool ContainsOutline(Part a,Part b)
        {
            if(a.Outline==null || b.Outline==null)return true;
            return b.Outline.All(point=>Inside(a.Outline,point,Math.Max(a.Width,a.Height)*1e-6));
        }
        private static bool Inside(List<Point2d> polygon,Point2d point,double eps)
        {
            bool inside=false;
            for(int i=0,j=polygon.Count-1;i<polygon.Count;j=i++) {
                var a=polygon[j];var b=polygon[i];var edge=b-a;double length=edge.LengthSqrd;
                double t=length<1e-20 ? 0 : Math.Max(0,Math.Min(1,(point-a).DotProduct(edge)/length));
                if(point.GetDistanceTo(a+edge*t)<=eps)return true;
                if((a.Y>point.Y)!=(b.Y>point.Y) && point.X<(b.X-a.X)*(point.Y-a.Y)/(b.Y-a.Y)+a.X)inside=!inside;
            }
            return inside;
        }
        private static bool Contains(Part a,Part b)
        { double eps=Math.Max(a.Width,a.Height)*1e-6; return b.Bounds.MinPoint.X>=a.Bounds.MinPoint.X-eps && b.Bounds.MinPoint.Y>=a.Bounds.MinPoint.Y-eps && b.Bounds.MaxPoint.X<=a.Bounds.MaxPoint.X+eps && b.Bounds.MaxPoint.Y<=a.Bounds.MaxPoint.Y+eps; }
        private static void Collect(Transaction tr,ObjectId id,Matrix3d transform,HashSet<ObjectId> path,List<Part> result)
        {
            if(!path.Add(id)) throw new InvalidOperationException("Block có tham chiếu vòng.");
            var block=(BlockTableRecord)tr.GetObject(id,OpenMode.ForRead);
            var draw=(DrawOrderTable)tr.GetObject(block.DrawOrderTableId,OpenMode.ForRead);
            foreach(ObjectId child in draw.GetFullDrawOrder(0))
            {
                var e=tr.GetObject(child,OpenMode.ForRead) as Entity;if(e==null || !e.Visible)continue;
                var reference=e as BlockReference;
                if(reference!=null) {
                    Collect(tr,reference.BlockTableRecord,transform*reference.BlockTransform,path,result);
                    foreach(ObjectId aid in reference.AttributeCollection) {
                        var a=(AttributeReference)tr.GetObject(aid,OpenMode.ForRead);if(a.Invisible || !a.Visible)continue;
                        try {var attributeBounds=a.GeometricExtents;attributeBounds.TransformBy(transform);result.Add(new Part {Id=aid,Bounds=attributeBounds,Area=-1,Order=result.Count});}catch(Autodesk.AutoCAD.Runtime.Exception){}
                    }
                    continue;
                }
                bool fill=e is Hatch || e is Solid;
                if(!fill && !(e is DBText) && !(e is MText))continue;
                var attribute=e as AttributeDefinition;if(attribute!=null && attribute.Invisible)continue;
                Extents3d bounds;try{bounds=e.GeometricExtents;bounds.TransformBy(transform);}catch(Autodesk.AutoCAD.Runtime.Exception){continue;}
                var color=e.Color;if(color.IsByLayer)color=((LayerTableRecord)tr.GetObject(e.LayerId,OpenMode.ForRead)).Color;
                // Red/Green/Blue are zero for several indexed colors in older DWGs.
                int red=color.Red,green=color.Green,blue=color.Blue;
                if(color.ColorMethod==ColorMethod.ByAci) {int rgb=EntityColor.LookUpRgb((byte)color.ColorIndex);red=(rgb>>16)&255;green=(rgb>>8)&255;blue=rgb&255;}
                var p=new Part {Id=child,Bounds=bounds,Fill=fill,Order=result.Count,White=red>240 && green>240 && blue>240,Black=red<40 && green<40 && blue<40,Red=red>200 && green<80 && blue<80,Color=red+","+green+","+blue,Area=-1};
                if(fill)
                {
                    List<Point2d> outer=null;double area=0;
                    var hatch=e as Hatch;
                    if(hatch!=null)
                    {
                        for(int n=0;n<hatch.NumberOfLoops;n++) {var polygon=Polygon(hatch.GetLoopAt(n));double size=Math.Abs(Area(polygon));if(size>area){area=size;outer=polygon;}}
                        try{p.Area=hatch.Area*Math.Abs(transform.CoordinateSystem3d.Xaxis.CrossProduct(transform.CoordinateSystem3d.Yaxis).Length);}catch(Autodesk.AutoCAD.Runtime.Exception){p.Area=area;}
                    }
                    else {var solid=(Solid)e;outer=new[]{0,1,3,2}.Select(v=>solid.GetPointAt((short)v).Convert2d(new Plane(Point3d.Origin,solid.Normal))).ToList();area=Math.Abs(Area(outer));p.Area=area*Math.Abs(transform.CoordinateSystem3d.Xaxis.CrossProduct(transform.CoordinateSystem3d.Yaxis).Length);}
                    p.Convex=IsConvex(outer);p.Loops=hatch==null ? 1 : hatch.NumberOfLoops;
                    double transformedArea=area*Math.Abs(transform.CoordinateSystem3d.Xaxis.CrossProduct(transform.CoordinateSystem3d.Yaxis).Length);
                    p.Rect=p.Convex && transformedArea/(p.Width*p.Height)>.90;
                    p.Outline=outer==null ? null : outer.Select(v=>new Point3d(v.X,v.Y,0).TransformBy(transform)).Select(v=>new Point2d(v.X,v.Y)).ToList();
                }
                result.Add(p);
            }
            path.Remove(id);
        }
        private static List<Point2d> Polygon(HatchLoop loop)
        {
            var points=new List<Point2d>();
            if(loop.IsPolyline)
            {
                // Sample bulges mathematically: transient native polylines can reject
                // the degenerate/duplicated vertices present in older hatch loops.
                for(int i=0;i<loop.Polyline.Count;i++) {
                    var v=loop.Polyline[i];var end=loop.Polyline[(i+1)%loop.Polyline.Count].Vertex;
                    double dx=end.X-v.Vertex.X,dy=end.Y-v.Vertex.Y,b=v.Bulge;
                    points.Add(v.Vertex);
                    if(Math.Abs(b)<1e-8 || dx*dx+dy*dy<1e-18)continue;
                    double factor=(1-b*b)/(4*b),cx=(v.Vertex.X+end.X)/2-dy*factor,cy=(v.Vertex.Y+end.Y)/2+dx*factor;
                    double angle=Math.Atan2(v.Vertex.Y-cy,v.Vertex.X-cx),sweep=4*Math.Atan(b),radius=Math.Sqrt((v.Vertex.X-cx)*(v.Vertex.X-cx)+(v.Vertex.Y-cy)*(v.Vertex.Y-cy));
                    for(int j=1;j<24;j++)points.Add(new Point2d(cx+radius*Math.Cos(angle+sweep*j/24),cy+radius*Math.Sin(angle+sweep*j/24)));
                }
            }
            else foreach(Curve2d curve in loop.Curves)
            {
                var sample=curve.GetSamplePoints(curve is LineSegment2d ? 2 : 25).ToList();
                if(points.Count>0 && points.Last().GetDistanceTo(sample.Last())<points.Last().GetDistanceTo(sample.First())) sample.Reverse();
                foreach(var p in sample) if(points.Count==0 || points.Last().GetDistanceTo(p)>1e-9)points.Add(p);
            }
            if(points.Count>1 && points.First().GetDistanceTo(points.Last())<1e-9)points.RemoveAt(points.Count-1);
            return points;
        }
        private static double Area(IList<Point2d> p)
        { double sum=0;for(int i=0;i<p.Count;i++){var a=p[i];var b=p[(i+1)%p.Count];sum+=a.X*b.Y-b.X*a.Y;}return sum/2; }
        private static bool IsConvex(IList<Point2d> p)
        {
            if(p==null || p.Count<3)return false;int sign=0;double eps=Math.Abs(Area(p))*1e-7;
            for(int i=0;i<p.Count;i++){var a=p[(i+1)%p.Count]-p[i];var b=p[(i+2)%p.Count]-p[(i+1)%p.Count];double cross=a.X*b.Y-a.Y*b.X;if(Math.Abs(cross)<=eps)continue;int next=cross>0 ? 1 : -1;if(sign!=0 && sign!=next)return false;sign=next;}
            return sign!=0;
        }
    }
}
