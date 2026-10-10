using System;
using System.Globalization;
using System.Text.RegularExpressions;
namespace BHT.Core
{
    public static class SignPresentation
    {
        public static string BridgeLine(string station, string road)
        {
            double metres; string value = (station ?? "").Trim();
            if (Chainage.TryParse(value, out metres))
                value = "KM" + Math.Floor(metres / 1000).ToString(CultureInfo.InvariantCulture) + "+" + (metres % 1000).ToString("000.###", CultureInfo.InvariantCulture);
            return value + (value != "" && !string.IsNullOrWhiteSpace(road) ? "-" : "") + (road ?? "").Trim();
        }
        public static string BaseCode(string code)
        {
            return (code ?? "").Split('@')[0].Trim();
        }
        public static bool HasZoneTime(string code)
        {
            string key = SignSearch.CodeKey(BaseCode(code)).ToUpperInvariant();
            return key == "RE9B" || key == "RE10B";
        }
        public static string ZoneTime(string code)
        {
            if (!HasZoneTime(code)) return "";
            if (!(code ?? "").Contains("@")) return "06:00-18:00";
            string value = code.Substring(code.IndexOf('@') + 1).Trim();
            var match = Regex.Match(value, @"^(\d{1,2}):([0-5]\d)\s*[-–]\s*(\d{1,2}):([0-5]\d)$");
            if (!match.Success || int.Parse(match.Groups[1].Value) > 23 || int.Parse(match.Groups[3].Value) > 23) return "";
            string start = int.Parse(match.Groups[1].Value).ToString("00") + ":" + match.Groups[2].Value;
            string end = int.Parse(match.Groups[3].Value).ToString("00") + ":" + match.Groups[4].Value;
            return start == end ? "" : start + "-" + end;
        }
        public static string ReplaceZoneTime(string code, string text)
        {
            string value = ZoneTime(code);
            return value != "" && Regex.IsMatch(text ?? "", @"^\s*\d{1,2}:\d{2}\s*[-–]\s*\d{1,2}:\d{2}\s*$") ? value.Replace("-", " - ") : text;
        }
        public static string MetreDefault(string code)
        {
            switch (BaseCode(code).ToUpperInvariant())
            {
                case "IE.472A": return "750";
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
        public static bool HasWeight(string code)
        {
            return BaseCode(code).Equals("S.505a", StringComparison.OrdinalIgnoreCase);
        }
        public static string WeightValue(string code)
        {
            if (!HasWeight(code) || !(code ?? "").Contains("@")) return "";
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
            var match = Regex.Match((code ?? "").Trim(), @"^(?:P\.?127|DP\.?134|R\.?306)(?:\s*[-_/]?\s*(\d{1,3}))?$", RegexOptions.IgnoreCase);
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
        public static string SpeedBase(string code)
        {
            var match = Regex.Match((code ?? "").Trim(), @"^(P\.?127|DP\.?134|R\.?306)(?:\s*[-_/]?\s*\d{1,3})?$", RegexOptions.IgnoreCase);
            if (!match.Success) return "";
            string key = SignSearch.CodeKey(match.Groups[1].Value).ToUpperInvariant();
            return key == "DP134" ? "DP.134" : key == "R306" ? "R.306" : "P.127";
        }
        public static string ValidationError(string code)
        {
            code = (code ?? "").Trim();
            // P.127a/b/c/d and ADS's D-1/D-2 are separate lane-speed signs, not numeric input.
            if (Regex.IsMatch(code, @"^P\.?127(?:[a-d]|-D|D-[12])$", RegexOptions.IgnoreCase)) return "";
            if (HasZoneTime(code)) return ZoneTime(code) == "" ? "Nhập giờ HH:mm-HH:mm từ 00:00 đến 23:59; hai giờ phải khác nhau." : "";
            if (HasWeight(code)) return !code.Contains("@") || WeightValue(code) != "" ? "" : "Trọng lượng phải lớn hơn 0, tối đa 100000 tấn và có tối đa 3 chữ số thập phân.";
            if (code.Contains("@") && MetreValue(code) == "")
                return "Giá trị mét phải lớn hơn 0, tối đa 100000 và có tối đa 3 chữ số thập phân; mã biển phải hỗ trợ giá trị mét.";
            if (Regex.IsMatch(code, @"^(?:P\.?127|DP\.?134|R\.?306)", RegexOptions.IgnoreCase)
                && !Regex.IsMatch(code, @"^(?:P\.?127|DP\.?134|R\.?306)$", RegexOptions.IgnoreCase) && !Speed(code, "").HasValue)
                return "Nhập tốc độ nguyên từ 5 đến 130 km/h; ví dụ DP.134-50 hoặc R.306-30.";
            return "";
        }
        public static string ResolveCode(string code, string description)
        {
            var speed = Speed(code, description);
            return speed.HasValue ? SpeedBase(code) + "-" + speed.Value.ToString(CultureInfo.InvariantCulture) : code;
        }
    }
}
