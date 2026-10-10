using System;
using System.Collections.Generic;
using System.Linq;
namespace BHT.Core
{
    public sealed class SignLayoutSpec
    {
        public string Code, Name;
        public int Faces, Posts;
        public SignLayoutSpec(string code, string name, int faces, int posts) { Code = code; Name = name; Faces = faces; Posts = posts; }
        public override string ToString() { return Name; }
        public static readonly SignLayoutSpec[] All = {
            new SignLayoutSpec("LEGACY", "Bố trí hiện tại", 0, 0),
            new SignLayoutSpec("CAP1_1", "1. Một biển / một trụ", 1, 1), new SignLayoutSpec("CAP1_2", "2. Một biển / hai trụ", 1, 2),
            new SignLayoutSpec("CAP1_3", "3. Hai biển ngang", 2, 1), new SignLayoutSpec("CAP1_4", "4. Hai biển dọc", 2, 1),
            new SignLayoutSpec("CAP1_5", "5. Ba biển ngang", 3, 1), new SignLayoutSpec("CAP1_6", "6. Ba biển dọc", 3, 1),
            new SignLayoutSpec("CAP1_7", "7. Ba biển tam giác", 3, 1), new SignLayoutSpec("CAP1_8", "8. Ba biển tam giác ngược", 3, 1),
            new SignLayoutSpec("CAP1_9", "9. Khung cổng 2D", 0, 2), new SignLayoutSpec("CAP1_10", "10. Cần vươn 2D", 0, 1)
        };
        public static SignLayoutSpec Find(string code) { return All.FirstOrDefault(x => x.Code == code) ?? All[0]; }
        public static string Validate(string code, int count, double gap, double clearance)
        {
            var spec = All.FirstOrDefault(x => x.Code == code);
            if (spec == null) return "Bố trí trụ/khung không hợp lệ.";
            if (count < 1 || count > 20) return "Một cụm cần từ 1 đến 20 mặt biển.";
            if (spec.Faces > 0 && spec.Faces != count) return "Bố trí này cần đúng " + spec.Faces + " mặt biển; hiện có " + count + ".";
            if (double.IsNaN(gap) || double.IsInfinity(gap) || gap < .02 || gap > 10) return "Khoảng cách mặt biển từ 0,02 đến 10 đơn vị CAD.";
            if (double.IsNaN(clearance) || double.IsInfinity(clearance) || clearance < .1 || clearance > 100) return "Chiều cao đến đáy biển từ 0,1 đến 100 đơn vị CAD.";
            return "";
        }
        public static List<SignPlateBox> Arrange(string code, IList<SignPlateBox> sizes, double gap, double clearance)
        {
            string error = Validate(code, sizes.Count, gap, clearance); if (error != "") throw new ArgumentException(error);
            var boxes = sizes.Select(x => new SignPlateBox(0, clearance, x.Width, x.Height)).ToList();
            if (boxes.Any(x => x.Width <= 0 || x.Height <= 0 || double.IsNaN(x.Width) || double.IsNaN(x.Height) || double.IsInfinity(x.Width) || double.IsInfinity(x.Height))) throw new ArgumentException("Mặt biển không có kích thước hợp lệ.");
            if (code == "CAP1_4" || code == "CAP1_6" || code == "LEGACY")
            { double y = clearance; for (int i = boxes.Count - 1; i >= 0; i--) { boxes[i].Y = y; y += boxes[i].Height + gap; } }
            else if (code == "CAP1_7")
            { Row(boxes, new[] { 1, 2 }, gap, clearance); boxes[0].Y = clearance + Math.Max(boxes[1].Height, boxes[2].Height) + gap; }
            else if (code == "CAP1_8")
            { Row(boxes, new[] { 0, 1 }, gap, clearance + boxes[2].Height + gap); }
            else Row(boxes, Enumerable.Range(0, boxes.Count).ToArray(), gap, clearance);
            // The insertion origin is the single foot of the cantilever.
            if (code == "CAP1_10") { double shift = -boxes.Min(x => x.Left) + .4; foreach (var box in boxes) box.X += shift; }
            return boxes;
        }
        private static void Row(List<SignPlateBox> boxes, int[] indexes, double gap, double y)
        {
            double total = indexes.Sum(i => boxes[i].Width) + gap * (indexes.Length - 1), x = -total / 2;
            foreach (int i in indexes) { boxes[i].X = x + boxes[i].Width / 2; boxes[i].Y = y; x += boxes[i].Width + gap; }
        }
    }
    public sealed class SignPlateBox
    {
        public double X, Y, Width, Height;
        public double Left { get { return X - Width / 2; } }
        public double Right { get { return X + Width / 2; } }
        public double Top { get { return Y + Height; } }
        public SignPlateBox(double x, double y, double width, double height) { X = x; Y = y; Width = width; Height = height; }
    }
}
