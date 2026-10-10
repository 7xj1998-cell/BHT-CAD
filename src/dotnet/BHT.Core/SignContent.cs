using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;
namespace BHT.Core
{
    public sealed class SignContentFace
    {
        public int Index;
        public string Code;
        public readonly Dictionary<string, string> Values = new Dictionary<string, string>(StringComparer.Ordinal);
    }
    public static class SignContent
    {
        public static List<SignContentFace> Read(string value)
        {
            var result = new List<SignContentFace>(); if (string.IsNullOrWhiteSpace(value)) return result;
            var xml = new XmlDocument { XmlResolver = null };
            using (var reader = XmlReader.Create(new StringReader(value), new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null, MaxCharactersInDocument = 200000 })) xml.Load(reader);
            if (xml.DocumentElement == null || xml.DocumentElement.Name != "sign-content") throw new ArgumentException("Nội dung biển không đúng định dạng BHT.");
            foreach (XmlElement node in xml.SelectNodes("/sign-content/face"))
            {
                int index; if (!int.TryParse(node.GetAttribute("index"), out index) || index < 0 || index > 19) throw new ArgumentException("Chỉ số mặt biển không hợp lệ.");
                if (string.IsNullOrWhiteSpace(node.GetAttribute("code"))) throw new ArgumentException("Thiếu mã mặt biển.");
                var face = new SignContentFace { Index = index, Code = node.GetAttribute("code") };
                if (result.Any(x => x.Index == index)) throw new ArgumentException("Nội dung bị lặp chỉ số mặt biển.");
                foreach (XmlElement field in node.SelectNodes("field"))
                {
                    string key = field.GetAttribute("key"), text = field.InnerText.Trim().Normalize(NormalizationForm.FormC);
                    if (key.Length == 0 || text.Length > 160 || face.Values.ContainsKey(key)) throw new ArgumentException("Trường nội dung biển không hợp lệ hoặc dài quá 160 ký tự.");
                    face.Values.Add(key, text);
                }
                result.Add(face);
            }
            return result;
        }
        public static string Write(IEnumerable<SignContentFace> faces)
        {
            var xml = new XmlDocument(); var root = xml.CreateElement("sign-content"); root.SetAttribute("version", "1"); xml.AppendChild(root);
            foreach (var face in faces.OrderBy(x => x.Index))
            {
                var node = xml.CreateElement("face"); node.SetAttribute("index", face.Index.ToString(CultureInfo.InvariantCulture)); node.SetAttribute("code", face.Code); root.AppendChild(node);
                foreach (var pair in face.Values.OrderBy(x => x.Key, StringComparer.Ordinal)) { var field = xml.CreateElement("field"); field.SetAttribute("key", pair.Key); field.InnerText = pair.Value.Trim().Normalize(NormalizationForm.FormC); node.AppendChild(field); }
            }
            string value = root.ChildNodes.Count == 0 ? "" : xml.OuterXml; Read(value); return value;
        }
        public static Dictionary<string, string> ForFace(string value, int index, string code)
        {
            var all = Read(value); var face = all.FirstOrDefault(x => x.Index == index && x.Code.Equals(code, StringComparison.OrdinalIgnoreCase));
            return face == null ? new Dictionary<string, string>() : face.Values;
        }
    }
}
