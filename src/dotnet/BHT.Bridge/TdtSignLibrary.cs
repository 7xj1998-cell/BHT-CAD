using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using BHT.Core;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace BHT.Bridge
{
    public sealed class TdtSignEntry
    {
        public string Code { get; set; }
        public string Description { get; set; }
        public string Group { get; set; }
        public string SourceDrawing { get; set; }
        public string Shape { get; set; }
        public bool HasVector { get; set; }

        public TdtSignEntry()
        {
            Code = ""; Description = ""; Group = ""; SourceDrawing = ""; Shape = "";
        }

        public override string ToString()
        {
            return string.IsNullOrWhiteSpace(Description) ? Code : Code + " — " + Description;
        }
    }

    public sealed class TdtSignImportResult
    {
        public bool Ok;
        public string Error = "";
        public string BlockName = "";
        public string SourceBlock = "";
        public string Description = "";
        public string SourceDrawing = "";
        public double FaceScale = 0.2;
    }

    /// <summary>
    /// Doc thu vien bien bao TDT da cai tren may. BHT chi tao cache trong LocalAppData
    /// va clone block duoc chon vao DWG; khong sua thu muc cai dat TDT.
    /// Block nguon TDT co mat bien tieu chuan cao 7 don vi, goc chen o day mat bien.
    /// BHT dat mat bien cao 1.4 unit (scale 0.2) tren cot cao 0.6 unit.
    /// </summary>
    public static class TdtSignLibrary
    {
        private static readonly object Gate = new object();
        private static List<TdtSignEntry> _catalog;
        private static string _root;
        private static string _cache;
        private static readonly string[] DrawingNames =
        {
            "Bien bao cam.dwg",
            "Bien bao nguy hiem.dwg",
            "Bien hieu lenh.dwg",
            "Bien chi dan.dwg",
            "Bien phu.dwg"
        };

        public const double DefaultFaceScale = 0.2;
        public const double DefaultPostHeight = 0.6;

        public static string InstalledRoot
        {
            get { lock (Gate) { if (_root == null) _root = FindRoot(); return _root ?? ""; } }
        }

        public static List<TdtSignEntry> GetCatalog()
        {
            lock (Gate)
            {
                if (_catalog != null) return new List<TdtSignEntry>(_catalog);
                _catalog = LoadCatalog(InstalledRoot);
                return new List<TdtSignEntry>(_catalog);
            }
        }

        public static TdtSignEntry Find(string code)
        {
            string key = Normalize(code);
            if (key == "") return null;
            var all = GetCatalog();
            var exact = all.FirstOrDefault(x => Normalize(x.Code) == key);
            if (exact != null) return exact;
            var prefix = all.Where(x => key.StartsWith(Normalize(x.Code), StringComparison.Ordinal))
                .OrderByDescending(x => Normalize(x.Code).Length).FirstOrDefault();
            if (prefix != null) return prefix;
            return all.Where(x => Normalize(x.Code).StartsWith(key, StringComparison.Ordinal))
                .OrderBy(x => Normalize(x.Code).Length).FirstOrDefault();
        }

        public static string SuggestedDescription(string code)
        {
            var e = Find(code);
            return e == null ? "" : e.Description;
        }

        public static string WrapperName(string code)
        {
            var sb = new StringBuilder("BHT_TDT_");
            bool underscore = false;
            foreach (char c0 in (code ?? "").Trim().ToUpperInvariant())
            {
                char c = c0;
                if ((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9'))
                {
                    sb.Append(c); underscore = false;
                }
                else if (!underscore)
                {
                    sb.Append('_'); underscore = true;
                }
            }
            string value = sb.ToString().TrimEnd('_');
            return value == "BHT_TDT" ? "BHT_TDT_CHUA_XAC_DINH" : value;
        }

        public static TdtSignImportResult EnsureBlock(Database destination, string code)
        {
            var result = new TdtSignImportResult { BlockName = WrapperName(code), FaceScale = DefaultFaceScale };
            if (destination == null) { result.Error = "không có bản vẽ đích"; return result; }
            if (HasBlock(destination, result.BlockName)) { result.Ok = true; return result; }

            var entry = Find(code);
            if (entry == null) { result.Error = "mã " + code + " không có trong danh mục TDT"; return result; }
            result.Description = entry.Description;
            result.SourceDrawing = entry.SourceDrawing;

            string cache;
            try { cache = EnsureCache(); }
            catch (System.Exception ex) { result.Error = ex.Message; return result; }
            string sourcePath = ResolveDrawing(cache, entry.SourceDrawing);
            if (sourcePath == null)
            {
                result.Error = "TDT có tên " + entry.Code + " trong danh mục nhưng không có DWG nguồn " + entry.SourceDrawing;
                return result;
            }

            try
            {
                using (var source = new Database(false, true))
                {
                    source.ReadDwgFile(sourcePath, FileOpenMode.OpenForReadAndAllShare, false, "");
                    source.CloseInput(true);
                    ObjectId sourceId;
                    string sourceName;
                    using (var tr = source.TransactionManager.StartTransaction())
                    {
                        var bt = (BlockTable)tr.GetObject(source.BlockTableId, OpenMode.ForRead);
                        sourceName = ResolveSourceBlock(bt, tr, entry.Code, code);
                        if (sourceName == null)
                        {
                            result.Error = "không tìm thấy hình block cho " + entry.Code + " trong " + entry.SourceDrawing;
                            return result;
                        }
                        sourceId = bt[sourceName];
                        result.SourceBlock = sourceName;

                        var map = new IdMapping();
                        source.WblockCloneObjects(new ObjectIdCollection(new[] { sourceId }), destination.BlockTableId,
                            map, DuplicateRecordCloning.MangleName, false);
                        var mapped = map[sourceId];
                        if (!mapped.IsCloned || mapped.Value.IsNull)
                        {
                            result.Error = "AutoCAD không clone được block TDT " + sourceName;
                            return result;
                        }
                        CreateWrapper(destination, mapped.Value, result.BlockName, code, sourceName);
                        tr.Commit();
                    }
                }
                result.Ok = HasBlock(destination, result.BlockName);
                if (!result.Ok) result.Error = "đã clone nhưng không tạo được block " + result.BlockName;
            }
            catch (System.Exception ex)
            {
                result.Error = "không nạp được block TDT: " + ex.Message;
            }
            return result;
        }

        private static bool HasBlock(Database db, string name)
        {
            using (var tr = db.TransactionManager.StartOpenCloseTransaction())
            {
                var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                bool value = bt.Has(name);
                tr.Commit();
                return value;
            }
        }

        private static void CreateWrapper(Database db, ObjectId clonedId, string wrapperName, string code, string sourceName)
        {
            using (var tr = db.TransactionManager.StartTransaction())
            {
                var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
                if (bt.Has(wrapperName)) { tr.Commit(); return; }

                var cloned = (BlockTableRecord)tr.GetObject(clonedId, OpenMode.ForWrite);
                string sourceAlias = "BHT_TDT_SRC_" + SafeToken(sourceName);
                int suffix = 1;
                string candidate = sourceAlias;
                while (bt.Has(candidate)) candidate = sourceAlias + "_" + (suffix++).ToString(CultureInfo.InvariantCulture);
                cloned.Name = candidate;

                bt.UpgradeOpen();
                var wrapper = new BlockTableRecord { Name = wrapperName, Origin = Point3d.Origin };
                bt.Add(wrapper);
                tr.AddNewlyCreatedDBObject(wrapper, true);

                var post = new Line(Point3d.Origin, new Point3d(0.0, DefaultPostHeight, 0.0));
                post.ColorIndex = 7;
                wrapper.AppendEntity(post); tr.AddNewlyCreatedDBObject(post, true);
                var foot = new Circle(Point3d.Origin, Vector3d.ZAxis, 0.06);
                foot.ColorIndex = 7;
                wrapper.AppendEntity(foot); tr.AddNewlyCreatedDBObject(foot, true);

                var face = new BlockReference(new Point3d(0.0, DefaultPostHeight, 0.0), clonedId)
                {
                    ScaleFactors = new Scale3d(DefaultFaceScale)
                };
                wrapper.AppendEntity(face); tr.AddNewlyCreatedDBObject(face, true);

                foreach (ObjectId id in cloned)
                {
                    var def = tr.GetObject(id, OpenMode.ForRead) as AttributeDefinition;
                    if (def == null || def.Constant) continue;
                    var attr = new AttributeReference();
                    attr.SetAttributeFromBlock(def, face.BlockTransform);
                    attr.TextString = AttributeValue(code, def.TextString, def.Tag);
                    face.AttributeCollection.AppendAttribute(attr);
                    tr.AddNewlyCreatedDBObject(attr, true);
                }
                tr.Commit();
            }
        }

        private static string AttributeValue(string code, string defaultValue, string tag)
        {
            string source = code ?? "";
            var digits = new string(source.Where(c => char.IsDigit(c)).ToArray());
            string norm = Normalize(source);
            if (norm.StartsWith("P127", StringComparison.Ordinal) && digits.Length > 3)
                return digits.Substring(3);
            return string.IsNullOrWhiteSpace(defaultValue) ? (string.IsNullOrWhiteSpace(tag) ? "" : tag) : defaultValue;
        }

        private static string ResolveSourceBlock(BlockTable bt, Transaction tr, string catalogCode, string enteredCode)
        {
            var names = new List<string>();
            foreach (ObjectId id in bt)
            {
                var btr = (BlockTableRecord)tr.GetObject(id, OpenMode.ForRead);
                if (!btr.IsLayout && !btr.IsAnonymous && !btr.IsFromExternalReference) names.Add(btr.Name);
            }
            string catalog = Normalize(catalogCode);
            string entered = Normalize(enteredCode);
            Func<string, string> n = Normalize;
            var exact = names.FirstOrDefault(x => n(x) == catalog) ?? names.FirstOrDefault(x => n(x) == entered);
            if (exact != null) return exact;
            return names.Where(x => n(x).StartsWith(catalog, StringComparison.Ordinal) || catalog.StartsWith(n(x), StringComparison.Ordinal)
                                 || entered.StartsWith(n(x), StringComparison.Ordinal))
                        .OrderBy(x => Math.Abs(n(x).Length - catalog.Length)).ThenBy(x => x, StringComparer.OrdinalIgnoreCase)
                        .FirstOrDefault();
        }

        private static string EnsureCache()
        {
            lock (Gate)
            {
                string root = InstalledRoot;
                if (root == "") throw new InvalidOperationException("không tìm thấy thư viện biển báo trong TDT 9.1/2022 đã cài");
                string setPath = Path.Combine(root, "Data", "Bien bao", "bienbao.set");
                var info = new FileInfo(setPath);
                string cacheRoot = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "BHT", "TDT-Signs", info.Length.ToString(CultureInfo.InvariantCulture) + "-" + info.LastWriteTimeUtc.Ticks.ToString(CultureInfo.InvariantCulture));
                bool ready = DrawingNames.All(x => File.Exists(Path.Combine(cacheRoot, x)));
                if (!ready)
                {
                    Directory.CreateDirectory(cacheRoot);
                    ExtractContainer(setPath, cacheRoot);
                }
                _cache = cacheRoot;
                return _cache;
            }
        }

        private static void ExtractContainer(string setPath, string folder)
        {
            byte[] bytes = File.ReadAllBytes(setPath);
            if (bytes.Length < 12) throw new InvalidDataException("bienbao.set không hợp lệ");
            int count = BitConverter.ToInt32(bytes, 4);
            int offset = 8;
            for (int i = 0; i < count; i++)
            {
                if (offset + 4 > bytes.Length) throw new InvalidDataException("bienbao.set bị thiếu dữ liệu");
                int size = BitConverter.ToInt32(bytes, offset);
                int start = offset + 4;
                int end = start + size;
                if (size < 0 || end > bytes.Length) throw new InvalidDataException("kích thước mục trong bienbao.set không hợp lệ");
                if (size > 0 && i < DrawingNames.Length)
                {
                    string signature = Encoding.ASCII.GetString(bytes, start, Math.Min(6, size));
                    if (!signature.StartsWith("AC10", StringComparison.Ordinal)) throw new InvalidDataException("mục TDT không phải DWG");
                    using (var f = new FileStream(Path.Combine(folder, DrawingNames[i]), FileMode.Create, FileAccess.Write, FileShare.Read))
                        f.Write(bytes, start, size);
                }
                offset = end;
            }
            if (offset != bytes.Length) throw new InvalidDataException("bienbao.set còn dữ liệu chưa đọc");
        }

        private static string ResolveDrawing(string cache, string sourceDrawing)
        {
            string wanted = NormalizeFile(sourceDrawing);
            foreach (string name in DrawingNames)
                if (NormalizeFile(name) == wanted) return Path.Combine(cache, name);
            return null;
        }

        private static List<TdtSignEntry> LoadCatalog(string root)
        {
            var list = new List<TdtSignEntry>();
            if (string.IsNullOrEmpty(root)) return BuiltInFallback();
            string path = Path.Combine(root, "Data", "Bien bao", "Bienbao.xml");
            try
            {
                var doc = new XmlDocument();
                doc.Load(path);
                foreach (XmlElement group in doc.SelectNodes("//*[@dataSource]"))
                {
                    string groupName = group.Attributes.Count > 1 ? group.Attributes[1].Value : "";
                    string source = group.GetAttribute("dataSource");
                    foreach (XmlNode node in group.ChildNodes)
                    {
                        var sign = node as XmlElement;
                        if (sign == null || sign.Attributes.Count == 0) continue;
                        list.Add(new TdtSignEntry
                        {
                            Code = sign.Attributes[0].Value,
                            Description = sign.Attributes.Count > 1 ? sign.Attributes[1].Value : "",
                            Shape = sign.Attributes.Count > 2 ? sign.Attributes[2].Value : "",
                            Group = groupName,
                            SourceDrawing = source,
                            HasVector = DrawingNames.Any(x => NormalizeFile(x) == NormalizeFile(source))
                        });
                    }
                }
            }
            catch { return BuiltInFallback(); }
            return list.OrderBy(x => SignSortKey(x.Code), StringComparer.OrdinalIgnoreCase).ToList();
        }

        private static List<TdtSignEntry> BuiltInFallback()
        {
            string[][] data =
            {
                new[] { "W.207a", "Giao nhau với đường không ưu tiên" }, new[] { "W.209", "Giao nhau có tín hiệu đèn" },
                new[] { "W.239a", "Đường cáp điện phía trên" }, new[] { "W.245a", "Đi chậm" },
                new[] { "W.201", "Chỗ ngoặt nguy hiểm" }, new[] { "W.225", "Trẻ em" },
                new[] { "R.412a", "Làn đường dành riêng cho từng loại xe" }, new[] { "I.414a", "Chỉ hướng đường" },
                new[] { "I.423a", "Đường người đi bộ sang ngang" }, new[] { "I.428", "Trạm cung cấp xăng dầu" },
                new[] { "I.434a", "Bến xe buýt" }, new[] { "P.115", "Hạn chế trọng tải toàn bộ xe" },
                new[] { "P.119", "Hạn chế chiều dài xe" }, new[] { "P.124a", "Cấm quay đầu xe" },
                new[] { "P.125", "Cấm vượt" }, new[] { "P.127", "Tốc độ tối đa cho phép" }
            };
            return data.Select(x => new TdtSignEntry { Code = x[0], Description = x[1] }).ToList();
        }

        private static string FindRoot()
        {
            return Tdt91Installation.FindRoot();
        }

        private static string Normalize(string value)
        {
            var sb = new StringBuilder();
            foreach (char c in (value ?? "").ToUpperInvariant()) if (char.IsLetterOrDigit(c)) sb.Append(c);
            return sb.ToString();
        }

        private static string NormalizeFile(string value)
        {
            return Normalize(Path.GetFileNameWithoutExtension(value ?? ""));
        }

        private static string SafeToken(string value)
        {
            string v = WrapperName(value);
            return v.StartsWith("BHT_TDT_", StringComparison.Ordinal) ? v.Substring(8) : v;
        }

        private static string SignSortKey(string code)
        {
            string c = (code ?? "").ToUpperInvariant();
            return c.PadRight(24, ' ');
        }
    }

    public static class TdtSignLispFunctions
    {
        [LispFunction("BHTTDTBLOCK")]
        public static ResultBuffer ImportSign(ResultBuffer args)
        {
            string code = "";
            if (args != null)
                foreach (TypedValue value in args) { code = Convert.ToString(value.Value, CultureInfo.InvariantCulture); break; }
            var doc = AcApp.DocumentManager.MdiActiveDocument;
            if (doc == null) return Reply("LOI", "không có bản vẽ đang mở");
            var r = TdtSignLibrary.EnsureBlock(doc.Database, code);
            return r.Ok
                ? Reply("OK", r.BlockName, r.Description, r.SourceBlock, r.FaceScale.ToString("0.######", CultureInfo.InvariantCulture))
                : Reply("LOI", r.Error);
        }

        private static ResultBuffer Reply(params string[] values)
        {
            var rb = new ResultBuffer();
            foreach (string value in values) rb.Add(new TypedValue((int)LispDataType.Text, value ?? ""));
            return rb;
        }
    }
}
