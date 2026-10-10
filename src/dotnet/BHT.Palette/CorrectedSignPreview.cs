using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Globalization;
using System.Linq;
using System.Xml;
using BHT.Bridge;
using BHT.Core;

namespace BHT.Palette
{
    internal static class CorrectedSignPreview
    {
        internal static Image Create(string code)
        {
            string canonical = SignCorrections.Canonical(code);
            var toll = Toll(canonical, SignPresentation.MetreDefault(code)); if(toll != null) return toll;
            if (canonical != "W.207a" && canonical != "R.415a" && canonical != "R.415b") return null;
            var xml = new XmlDocument(); xml.XmlResolver = null;
            using (var stream = typeof(SignCorrections).Assembly.GetManifestResourceStream("BHT.SignVectors.xml")) xml.Load(stream);
            var sign = xml.SelectNodes("/signs/sign").Cast<XmlElement>().First(s => s.GetAttribute("code") == canonical);
            var bitmap = new Bitmap(640,400);
            using (var g = Graphics.FromImage(bitmap))
            {
                g.Clear(Color.White); g.SmoothingMode = SmoothingMode.AntiAlias;
                double width = canonical.StartsWith("W.") ? 2.08 : double.Parse(sign.GetAttribute("width"),CultureInfo.InvariantCulture);
                float scale = (float)Math.Min(610 / width,370 / 1.8);
                Func<double,double,PointF> point = (x,y) => new PointF(320 + (float)x * scale,200 - (float)(y-1.5)*scale);
                if (canonical.StartsWith("W."))
                {
                    g.FillPolygon(Brushes.Red,new[] { point(-1.04,.6),point(1.04,.6),point(0,2.4) });
                    g.FillPolygon(Brushes.Yellow,new[] { point(-.84,.72),point(.84,.72),point(0,2.18) });
                }
                else
                {
                    using(var blue = new SolidBrush(Color.FromArgb(0,118,190))) g.FillRectangle(blue,point(-width/2,2.4).X,point(0,2.4).Y,(float)width*scale,1.8f*scale);
                    if (sign.GetAttribute("frame") != "source")
                        using(var white = new Pen(Color.White,2)) g.DrawRectangle(white,point(-width/2+.025,2.375).X,point(0,2.375).Y,(float)(width-.05)*scale,1.75f*scale);
                }
                foreach(XmlElement shape in sign.SelectNodes("shape"))
                    using(var path = new GraphicsPath(FillMode.Alternate))
                    {
                        foreach(XmlElement loop in shape.SelectNodes("loop"))
                        {
                            var vertices = loop.InnerText.Split(';').Select(p => p.Split(',').Select(v => double.Parse(v,CultureInfo.InvariantCulture)).ToArray()).ToArray();
                            var points = new System.Collections.Generic.List<PointF>();
                            for(int i=0;i<vertices.Length;i++)
                            {
                                var a=vertices[i]; var b=vertices[(i+1)%vertices.Length]; points.Add(point(a[0],a[1]));
                                if(a.Length<3 || Math.Abs(a[2])<1e-9) continue;
                                double bulge=a[2], dx=b[0]-a[0],dy=b[1]-a[1], cx=(a[0]+b[0])/2-dy*(1-bulge*bulge)/(4*bulge),cy=(a[1]+b[1])/2+dx*(1-bulge*bulge)/(4*bulge);
                                double angle=Math.Atan2(a[1]-cy,a[0]-cx), radius=Math.Sqrt((a[0]-cx)*(a[0]-cx)+(a[1]-cy)*(a[1]-cy));
                                double sweep=4*Math.Atan(bulge);
                                int segments=Math.Max(12,(int)Math.Ceiling(Math.Abs(sweep)/(Math.PI/36)));
                                for(int n=1;n<segments;n++) { double t=angle+sweep*n/segments; points.Add(point(cx+radius*Math.Cos(t),cy+radius*Math.Sin(t))); }
                            }
                            path.AddPolygon(points.ToArray());
                        }
                        g.FillPath(shape.GetAttribute("color") == "7" ? Brushes.White : shape.GetAttribute("color") == "1" ? Brushes.Red : Brushes.Black,path);
                    }
            }
            return bitmap;
        }
        internal static Image Toll(string code, string value)
        {
            bool distance=code.Equals("IE.472a",StringComparison.OrdinalIgnoreCase);
            if (!distance && !code.Equals("IE.472b",StringComparison.OrdinalIgnoreCase)) return null;
            var bitmap=new Bitmap(532,distance ? 360 : 236);
            using(var g=Graphics.FromImage(bitmap))
            using(var green=new SolidBrush(Color.FromArgb(0,152,65)))
            using(var white=new Pen(Color.White,5))
            using(var big=new Font("Arial Narrow",40,FontStyle.Bold))
            using(var small=new Font("Arial Narrow",30,FontStyle.Bold))
            using(var format=new StringFormat {Alignment=StringAlignment.Center,LineAlignment=StringAlignment.Center})
            {
                g.Clear(Color.White);g.SmoothingMode=SmoothingMode.AntiAlias;
                g.FillRectangle(green,0,0,532,bitmap.Height);
                Action<float,float> frame=(y,h) => {
                    using(var path=new GraphicsPath()) {path.AddArc(8,y,20,20,180,90);path.AddArc(504,y,20,20,270,90);path.AddArc(504,y+h-20,20,20,0,90);path.AddArc(8,y+h-20,20,20,90,90);path.CloseFigure();g.DrawPath(white,path);}
                };
                frame(8,220);
                g.DrawString("TRẠM THU PHÍ",big,Brushes.White,new RectangleF(25,30,482,95),format);
                g.DrawString("TOLL PLAZA",small,Brushes.White,new RectangleF(25,130,482,65),format);
                if(distance) {frame(234,118);g.DrawString(value+" m",big,Brushes.White,new RectangleF(25,246,482,94),format);}
            }
            return bitmap;
        }
        internal static Image Speed(string code, string value)
        {
            if (code != "DP.134" && code != "R.306") return null;
            var bitmap = new Bitmap(400,400);
            using(var g = Graphics.FromImage(bitmap))
            using(var blue = new SolidBrush(Color.FromArgb(0,118,190)))
            using(var font = new Font("Arial Narrow",100,FontStyle.Bold))
            using(var format = new StringFormat { Alignment=StringAlignment.Center,LineAlignment=StringAlignment.Center })
            {
                g.Clear(Color.White);g.SmoothingMode=SmoothingMode.AntiAlias;
                g.FillEllipse(blue,10,10,380,380);
                bool end=code=="DP.134"; if(end) g.FillEllipse(Brushes.White,33,33,334,334);
                g.DrawString(value,font,end ? Brushes.Black : Brushes.White,new RectangleF(45,50,310,300),format);
                if(end)
                    using(var clip = new GraphicsPath())
                    using(var pen = new Pen(Color.Black,3.8f))
                    {
                        clip.AddEllipse(33,33,334,334);g.SetClip(clip);
                        for(int i=-2;i<=2;i++) g.DrawLine(pen,0,400+i*14,400,i*14);
                    }
            }
            return bitmap;
        }
    }
}
