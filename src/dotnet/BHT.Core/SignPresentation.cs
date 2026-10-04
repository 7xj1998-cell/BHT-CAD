using System;
using System.Globalization;
using System.Text.RegularExpressions;
namespace BHT.Core
{
    public static class SignPresentation
    {
        public static string BaseCode(string code)
        {
            return (code ?? "").Split('@')[0].Trim();
        }
        public static string MetreDefault(string code)
        {
            switch (BaseCode(code).ToUpperInvariant())
            {
                case "W.239B": return "4.5";
                case "S.501": return "800";
                case "S.502": return "200";
                case "S.509A": return "5";
                case "P.117": return "4.2";
                case "P.118": return "2.5";
                case "P.119": return "10";
                case "P.120": return "12";
                default: return "";
            }
        }
        public static string MetreValue(string code)
        {
            if (MetreDefault(code) == "" || !(code ?? "").Contains("@")) return "";
            double value;
            string text = code.Substring(code.IndexOf('@') + 1).Trim().Replace(',', '.');
            return double.TryParse(text, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out value) && value > 0 && value <= 100000 && value == Math.Round(value, 3)
                ? value.ToString("0.###", CultureInfo.InvariantCulture) : "";
        }
        public static string ReplaceMetres(string code, string text)
        {
            string value = MetreValue(code);
            if (value == "") return text;
            // Whole numeric labels or a number with the metre suffix only.
            // Never rewrite code identifiers, legends, other dimensions or words.
            var match = Regex.Match(text ?? "", @"^\s*\d+(?:[.,]\d+)?\s*(m)?\s*$", RegexOptions.IgnoreCase);
            return match.Success ? value + (match.Groups[1].Success ? " m" : "") : text;
        }
        public static int? Speed(string code, string description)
        {
            var match = Regex.Match((code ?? "").Trim(), @"^P\.?127(?:\s*[-_/]?\s*(\d{1,3}))?$", RegexOptions.IgnoreCase);
            if (!match.Success) return null;
            string value = match.Groups[1].Value;
            if (value == "")
            {
                string folded = TextSearch.Fold(description ?? "");
                var fromDescription = Regex.Match(folded, @"(?:gioi\s*han|toc\s*do)\s*[:=]?\s*(\d{1,3})(?!\d)");
                value = fromDescription.Groups[1].Value;
            }
            int speed;
            return int.TryParse(value, out speed) && speed >= 5 && speed <= 130 ? (int?)speed : null;
        }
        public static string ValidationError(string code)
        {
            code = (code ?? "").Trim();
            if (code.Contains("@") && MetreValue(code) == "")
                return "Giá trị mét phải lớn hơn 0, tối đa 100000 và có tối đa 3 chữ số thập phân; mã biển phải hỗ trợ giá trị mét.";
            if (Regex.IsMatch(code, @"^P\.?127", RegexOptions.IgnoreCase)
                && !Regex.IsMatch(code, @"^P\.?127$", RegexOptions.IgnoreCase) && !Speed(code, "").HasValue)
                return "Nhập tốc độ nguyên từ 5 đến 130 km/h; ví dụ P.127-80.";
            return "";
        }
        public static string ResolveCode(string code, string description)
        {
            var speed = Speed(code, description);
            return speed.HasValue ? "P.127-" + speed.Value.ToString(CultureInfo.InvariantCulture) : code;
        }
    }
}
