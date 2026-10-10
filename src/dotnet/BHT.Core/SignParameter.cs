using System;
using System.Globalization;
using System.Text.RegularExpressions;
namespace BHT.Core
{
    // CAD text and attributes share the same input rules and unit preservation.
    public sealed class SignParameter
    {
        public string Kind="text", Unit="", Label="Nội dung";
        public bool Integer; public double Minimum=0,Maximum=1000000000;
        private static readonly Regex Quantity=new Regex(@"^\s*(\d+(?:[.,]\d+)?)\s*(km/h|km|m|t|%|MHz)?\s*$",RegexOptions.IgnoreCase);
        public static bool IsQuantity(string sample) { return Quantity.IsMatch(sample ?? ""); }
        public static SignParameter Describe(string code,string tag,string sample)
        {
            var p=new SignParameter();string t=TextSearch.Fold(tag).Replace("_","").Replace("-","");
            var q=Quantity.Match(sample ?? "");
            if(t.Contains("hotline") || t=="sos") {p.Label="Số điện thoại";return p;}
            if(t.Contains("station")) {p.Label="Lý trình";return p;}
            if(t.Contains("time") || t.Contains("thoigian") || Regex.IsMatch(sample ?? "",@"\d{1,2}:\d{2}")) {p.Kind="time";p.Label="Giờ áp dụng (HH:mm hoặc HH:mm-HH:mm)";return p;}
            if(q.Success) p.Unit=q.Groups[2].Value;
            bool speed=Regex.IsMatch(t,@"^v\d*$") || t=="vmin" || t=="vmax" || t.Contains("tocdo") || (code.StartsWith("P.127",StringComparison.OrdinalIgnoreCase) && q.Success);
            bool distance=t.Contains("dist") || t.Contains("khoangcach") || t.Contains("chieudai") || p.Unit.Equals("m",StringComparison.OrdinalIgnoreCase) || p.Unit.Equals("km",StringComparison.OrdinalIgnoreCase);
            bool weight=t=="w" || t.Contains("weight") || p.Unit.Equals("t",StringComparison.OrdinalIgnoreCase);
            if(q.Success || speed || distance || weight || t=="sl" || t=="h" || t=="wi" || t=="l" || t.Contains("hang")) {
                p.Kind="number";
                if(speed){p.Integer=true;p.Minimum=5;p.Maximum=130;}
                else if(t.Contains("hang")){p.Integer=true;p.Maximum=9;}
                p.Label=speed ? "Tốc độ (km/h)" : weight ? "Tải trọng (tấn)" : t=="sl" ? "Độ dốc (%)" : t.Contains("hang") ? "Chữ số lý trình" : t=="h" ? "Chiều cao (m)" : t=="wi" ? "Chiều rộng (m)" : distance ? "Khoảng cách" : "Giá trị số";
                if(distance && p.Unit=="")p.Label+=" (đơn vị theo mặt biển)";else if(p.Unit!="" && !speed && !weight && t!="sl")p.Label+=" ("+p.Unit+")";
            }
            else if(t.Contains("dest") || t.Contains("name") || t.Contains("dia") || t.Contains("location") || t=="start" || t=="end")p.Label="Địa danh / tên";
            return p;
        }
        public string Normalize(string value)
        {
            value=(value ?? "").Trim();if(value=="" || Kind=="text")return value;
            if(Kind=="time") {
                var match=Regex.Match(value,@"^(\d{1,2}):([0-5]\d)(?:\s*[-–]\s*(\d{1,2}):([0-5]\d))?$");
                if(!match.Success || int.Parse(match.Groups[1].Value)>23 || (match.Groups[3].Success && int.Parse(match.Groups[3].Value)>23))throw new ArgumentException("Giờ phải từ 00:00 đến 23:59; nhập HH:mm hoặc HH:mm-HH:mm.");
                string first=int.Parse(match.Groups[1].Value).ToString("00")+":"+match.Groups[2].Value;
                return first+(match.Groups[3].Success ? "-"+int.Parse(match.Groups[3].Value).ToString("00")+":"+match.Groups[4].Value : "");
            }
            var q=Quantity.Match(value);decimal number;
            if(!q.Success || !decimal.TryParse(q.Groups[1].Value.Replace(',','.'),NumberStyles.AllowDecimalPoint,CultureInfo.InvariantCulture,out number) || number>1000000000)throw new ArgumentException("Nhập số không âm, tối đa 1000000000; giữ đơn vị của chữ mẫu.");
            string numeric=q.Groups[1].Value.Replace(',','.');
            if(numeric.Contains(".") && numeric.Split('.')[1].TrimEnd('0').Length>8)throw new ArgumentException("Giá trị có tối đa 8 chữ số thập phân; rút gọn rồi nhập lại.");
            if(number<(decimal)Minimum || number>(decimal)Maximum || (Integer && number!=decimal.Floor(number)))throw new ArgumentException("Nhập "+(Integer ? "số nguyên" : "số")+" từ "+Minimum+" đến "+Maximum+".");
            string unit=q.Groups[2].Value;
            if(unit!="" && !unit.Equals(Unit,StringComparison.OrdinalIgnoreCase))throw new ArgumentException("Đơn vị phải là "+(Unit=="" ? "đơn vị đã thể hiện trên mặt biển" : Unit)+".");
            return number.ToString("0.########",CultureInfo.InvariantCulture)+(Unit=="" ? "" : " "+Unit);
        }
    }
}
