using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using Autodesk.AutoCAD.DatabaseServices;
using BHT.Core;

namespace BHT.Bridge
{
    // Read the packaged BHT sign faces and six text catalogs.
    public static class BhtSignLibrary
    {
        private static string root;
        private static List<TdtSignEntry> catalog;
        private static readonly object Gate = new object();
        public static string Root
        {
            get
            {
                string provider = Environment.GetEnvironmentVariable("BHT_SIGN_PROVIDER") ?? "";
                if (provider.Equals("BUILTIN", StringComparison.OrdinalIgnoreCase) || provider.Equals("TDT", StringComparison.OrdinalIgnoreCase)) return "";
                lock (Gate) { if (root == null) root = Locate(); return root; }
            }
        }
        public static void Reload() { lock (Gate) { root = null; catalog = null; } }
        private static string Locate()
        {
            string configured = Environment.GetEnvironmentVariable("BHT_SIGN_ROOT") ?? Environment.GetEnvironmentVariable("BHT_ADS_ROOT");
            if (!string.IsNullOrWhiteSpace(configured)) return Folder(configured);
            // A packaged snapshot is preferred so an ADS update cannot change an existing cache key.
            for (var folder = new DirectoryInfo(Path.GetDirectoryName(typeof(BhtSignLibrary).Assembly.Location)); folder != null; folder = folder.Parent)
            {
                string bundled = Path.Combine(folder.FullName, "SignLibrary", "BHT");
                if (Directory.Exists(bundled) && File.Exists(Path.Combine(bundled, "BIEN_CAM.txt"))) return bundled;
                string development = Path.Combine(folder.FullName, "ads_library_local", "TrafficSignal");
                if (File.Exists(Path.Combine(development, "BIEN_CAM.txt"))) return development;
            }
            return "";
        }
        private static string Folder(string value)
        {
            string folder = File.Exists(Path.Combine(value, "BIEN_CAM.txt")) ? value : Path.Combine(value, "TrafficSignal");
            return Directory.Exists(folder) && File.Exists(Path.Combine(folder, "BIEN_CAM.txt")) ? folder : "";
        }
        public static List<TdtSignEntry> GetCatalog()
        {
            lock (Gate)
            {
                if (Root == "") return new List<TdtSignEntry>();
                if (catalog != null) return new List<TdtSignEntry>(catalog);
                var names = new Dictionary<string, TdtSignEntry>(StringComparer.OrdinalIgnoreCase);
                string[][] groups = {
                    new[] { "BIEN_CAM.txt", "Biển cấm" }, new[] { "BIEN_CANH_BAO.txt", "Biển nguy hiểm" },
                    new[] { "BIEN_CHI_DAN.txt", "Biển chỉ dẫn" }, new[] { "BIEN_DU_AN.txt", "Biển chỉ dẫn trên đường cao tốc" },
                    new[] { "BIEN_HIEU_LENH.txt", "Biển hiệu lệnh" }, new[] { "BIEN_PHU.txt", "Biển phụ" }
                };
                foreach (var group in groups)
                {
                    string path = Path.Combine(Root, group[0]);
                    if (!File.Exists(path)) continue;
                    foreach (string line in File.ReadAllLines(path, Encoding.UTF8))
                    {
                        // Some codes contain commas; split at the first repeated code, or the first separator for IE.
                        var match = Regex.Match(line, @"^(?<code>.+?),(?:\k<code>-)?(?<name>.*),\d+,\d+$");
                        if (!match.Success) continue;
                        string code = match.Groups["code"].Value.Trim();
                        // Prefer the repeated-code grammar when a code itself contains a comma.
                        var repeated = Regex.Match(line, @"^(?<code>.+?),\k<code>-(?<name>.*),\d+,\d+$");
                        if (repeated.Success) { match = repeated; code = match.Groups["code"].Value.Trim(); }
                        names[code] = new TdtSignEntry { Code = code, Description = match.Groups["name"].Value.Trim().Normalize(NormalizationForm.FormC), Group = group[1], Provider = "BHT" };
                    }
                }
                var result = new List<TdtSignEntry>();
                foreach (string path in Directory.GetFiles(Root, "*.dwg").OrderBy(p => p, StringComparer.OrdinalIgnoreCase))
                {
                    string code = Path.GetFileNameWithoutExtension(path);
                    if (!Regex.IsMatch(code, @"^(P|DP|W|R|I|IE|S)\.", RegexOptions.IgnoreCase)) continue;
                    TdtSignEntry named;
                    if (!names.TryGetValue(code, out named))
                    {
                        string parent = Regex.Replace(code, @"[-']\d*$", "");
                        names.TryGetValue(parent, out named);
                    }
                    result.Add(new TdtSignEntry { Code = code, Description = named == null ? "" : named.Description,
                        Group = code.StartsWith("S.", StringComparison.OrdinalIgnoreCase) || named == null ? GroupOf(code) : named.Group, SourceDrawing = path, HasVector = true,
                        Provider = "BHT", PreviewPath = Preview(code) });
                }
                // R.415 is the old alias for R.415a; expose the explicit a/b pair in the picker.
                result.RemoveAll(e => e.Code.Equals("R.415", StringComparison.OrdinalIgnoreCase) || e.Code.Equals("W.239", StringComparison.OrdinalIgnoreCase));
                catalog = result;
                return new List<TdtSignEntry>(catalog);
            }
        }
        private static string GroupOf(string code)
        {
            if (code.StartsWith("S.", StringComparison.OrdinalIgnoreCase)) return "Biển phụ";
            if (code.StartsWith("W.", StringComparison.OrdinalIgnoreCase)) return "Biển nguy hiểm";
            if (code.StartsWith("R.", StringComparison.OrdinalIgnoreCase)) return "Biển hiệu lệnh";
            if (code.StartsWith("P.", StringComparison.OrdinalIgnoreCase) || code.StartsWith("DP.", StringComparison.OrdinalIgnoreCase)) return "Biển cấm";
            return code.StartsWith("IE.", StringComparison.OrdinalIgnoreCase) ? "Biển chỉ dẫn trên đường cao tốc" : "Biển chỉ dẫn";
        }
        public static string Preview(string code)
        {
            if (Root == "" || string.IsNullOrWhiteSpace(code)) return "";
            string canonical = SignCorrections.Canonical(code);
            foreach (string extension in new[] { ".png", ".jpg" })
            {
                string path = Path.Combine(Root, canonical + extension);
                if (File.Exists(path)) return path;
            }
            return "";
        }
        public static TdtSignEntry Find(string code)
        {
            string baseCode = SignPresentation.SpeedBase(code);
            string canonical = SignCorrections.Canonical(code);
            var all = GetCatalog();
            var exact = all.FirstOrDefault(e => e.Code.Equals(canonical, StringComparison.OrdinalIgnoreCase));
            if (exact != null) return exact;
            if (baseCode != "") return all.FirstOrDefault(e => e.Code.Equals(baseCode, StringComparison.OrdinalIgnoreCase));
            if (canonical.Equals("P.122", StringComparison.OrdinalIgnoreCase)) return all.FirstOrDefault(e => e.Code.Equals("R.122", StringComparison.OrdinalIgnoreCase));
            // Keep the legacy gas-station variants usable when ADS supplies one I.428 face.
            if (Regex.IsMatch(canonical, @"^I\.428[abc]$", RegexOptions.IgnoreCase)) return all.FirstOrDefault(e => e.Code.Equals("I.428", StringComparison.OrdinalIgnoreCase));
            string key = SignSearch.CodeKey(canonical);
            return all.Where(e => SignSearch.CodeKey(e.Code).StartsWith(key, StringComparison.OrdinalIgnoreCase)
                    && Regex.IsMatch(SignSearch.CodeKey(e.Code).Substring(key.Length), @"^[A-Za-z]+$"))
                .OrderBy(e => e.Code.Length).FirstOrDefault();
        }
        internal static TdtSignImportResult Import(Database destination, string code)
        {
            var entry = Find(code);
            if (entry == null) return null;
            var result = new TdtSignImportResult { BlockName = TdtSignLibrary.WrapperName(code), Description = entry.Description,
                SourceDrawing = entry.SourceDrawing, SourceBlock = "BHT " + entry.Code, FaceScale = 1 };
            var working = HostApplicationServices.WorkingDatabase;
            try
            {
                HostApplicationServices.WorkingDatabase = destination;
                using (var check = destination.TransactionManager.StartOpenCloseTransaction())
                    if (((BlockTable)check.GetObject(destination.BlockTableId, OpenMode.ForRead)).Has(result.BlockName)) { result.Ok = true; return result; }
                using (var source = new Database(false, true))
                {
                    source.ReadDwgFile(entry.SourceDrawing, FileOpenMode.OpenForReadAndAllShare, false, ""); source.CloseInput(true);
                    ObjectId faceId;
                    using (var tr = destination.TransactionManager.StartTransaction())
                    {
                        var table = (BlockTable)tr.GetObject(destination.BlockTableId, OpenMode.ForWrite);
                        var face = new BlockTableRecord { Name = "BHT_ADS_IMPORT_" + Guid.NewGuid().ToString("N"), Origin = source.Insbase };
                        faceId = table.Add(face); tr.AddNewlyCreatedDBObject(face, true); tr.Commit();
                    }
                    // Database.Insert loses the model-space SORTENTSTABLE. Clone directly and
                    // explicitly restore the native order for both the face and nested blocks.
                    using (var native = source.TransactionManager.StartOpenCloseTransaction())
                    {
                        var table = (BlockTable)native.GetObject(source.BlockTableId, OpenMode.ForRead);
                        var model = (BlockTableRecord)native.GetObject(table[BlockTableRecord.ModelSpace], OpenMode.ForRead);
                        var map = new IdMapping();
                        source.WblockCloneObjects(new ObjectIdCollection(model.Cast<ObjectId>().ToArray()), faceId, map, DuplicateRecordCloning.MangleName, false);
                        using (var tr = destination.TransactionManager.StartTransaction())
                        {
                            RestoreDrawOrder(native, tr, model.ObjectId, faceId, map, new HashSet<ObjectId>());
                            SignPrintPresentation.TagImport(native, tr, destination, model.ObjectId, map, entry.Code);
                            tr.Commit();
                        }
                    }
                    result.FaceScale = TdtSignLibrary.CreateWrapper(destination, faceId, result.BlockName, code, entry.Code, true);
                }
                result.Ok = true;
            }
            catch (System.Exception error) { result.Error = "Không nạp được biển BHT " + entry.Code + ": " + error.Message; }
            finally { HostApplicationServices.WorkingDatabase = working; }
            return result;
        }
        internal static void RestoreDrawOrder(Transaction native, Transaction target, ObjectId sourceId, ObjectId targetId, IdMapping map, HashSet<ObjectId> seen)
        {
            if (!seen.Add(sourceId)) return;
            var block = (BlockTableRecord)native.GetObject(sourceId, OpenMode.ForRead);
            var order = (DrawOrderTable)native.GetObject(block.DrawOrderTableId, OpenMode.ForRead);
            var clone = (BlockTableRecord)target.GetObject(targetId, OpenMode.ForRead);
            var draw = (DrawOrderTable)target.GetObject(clone.DrawOrderTableId, OpenMode.ForWrite);
            var ordered = new ObjectIdCollection();
            foreach (ObjectId id in order.GetFullDrawOrder(0))
            {
                if (map.Contains(id)) ordered.Add(map[id].Value);
                var nested = native.GetObject(id, OpenMode.ForRead) as BlockReference;
                if (nested != null && map.Contains(nested.BlockTableRecord))
                    RestoreDrawOrder(native, target, nested.BlockTableRecord, map[nested.BlockTableRecord].Value, map, seen);
            }
            if (ordered.Count > 0) draw.SetRelativeDrawOrder(ordered);
        }
    }
}
