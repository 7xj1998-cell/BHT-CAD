using System;
using System.Globalization;
using System.Text.RegularExpressions;
namespace BHT.Core
{
    public static class SignPresentation
    {
        public static int? Speed(string code, string description)
        {
            var match = Regex.Match(code ?? "", @"^P\.?127(?:[-_ ](\d{1,3}))?$", RegexOptions.IgnoreCase);
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
        public static string ResolveCode(string code, string description)
        {
            var speed = Speed(code, description);
            return speed.HasValue ? "P.127-" + speed.Value.ToString(CultureInfo.InvariantCulture) : code;
        }
    }
}
