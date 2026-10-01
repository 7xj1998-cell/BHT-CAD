using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;

namespace BHT.Core
{
    public sealed class SignReportRow
    {
        public int Number;
        public string Project = "";
        public string Segment = "";
        public string Package = "";
        public string SignGroup = "";
        public string Code = "";
        public string Description = "";
        public string Side = "";
        public string Chainage = "";
        public string Route = "";
        public string Offset = "";
        public string StationSource = "";
        public string StationStatus = "";
        public string RouteRevision = "";
        public string Condition = "";
        public string PoleCount = "";
        public string FaceCount = "";
        public string Checked = "";
        public string Note = "";
        public string ObjectId = "";
    }

    /// <summary>Ghi workbook XLSX tối giản, không cần cài Excel hoặc thư viện ngoài.</summary>
    public static class SignReportWorkbook
    {
        private static readonly Encoding Utf8 = new UTF8Encoding(false);

        public static void Write(string path, string project, IList<SignReportRow> source)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentException("Thiếu đường dẫn tệp Excel.", "path");
            var rows = (source ?? new List<SignReportRow>()).ToList();
            string folder = Path.GetDirectoryName(Path.GetFullPath(path));
            if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
            using (var file = new FileStream(path, FileMode.Create, FileAccess.ReadWrite, FileShare.None))
            using (var zip = new ZipArchive(file, ZipArchiveMode.Create, false, Utf8))
            {
                Add(zip, "[Content_Types].xml", ContentTypes());
                Add(zip, "_rels/.rels", RootRelationships());
                Add(zip, "docProps/app.xml", AppProperties());
                Add(zip, "docProps/core.xml", CoreProperties());
                Add(zip, "xl/workbook.xml", Workbook());
                Add(zip, "xl/_rels/workbook.xml.rels", WorkbookRelationships());
                Add(zip, "xl/styles.xml", Styles());
                Add(zip, "xl/worksheets/sheet1.xml", SummarySheet(project, rows));
                Add(zip, "xl/worksheets/sheet2.xml", DetailSheet(project, rows));
            }
        }

        private static void Add(ZipArchive zip, string name, string content)
        {
            var entry = zip.CreateEntry(name, CompressionLevel.Optimal);
            using (var stream = entry.Open())
            using (var writer = new StreamWriter(stream, Utf8)) writer.Write(content);
        }

        private static string ContentTypes()
        {
            return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                + "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
                + "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>"
                + "<Default Extension=\"xml\" ContentType=\"application/xml\"/>"
                + "<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>"
                + "<Override PartName=\"/xl/worksheets/sheet1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
                + "<Override PartName=\"/xl/worksheets/sheet2.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
                + "<Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>"
                + "<Override PartName=\"/docProps/core.xml\" ContentType=\"application/vnd.openxmlformats-package.core-properties+xml\"/>"
                + "<Override PartName=\"/docProps/app.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.extended-properties+xml\"/>"
                + "</Types>";
        }

        private static string RootRelationships()
        {
            return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                + "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
                + "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/>"
                + "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties\" Target=\"docProps/core.xml\"/>"
                + "<Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties\" Target=\"docProps/app.xml\"/>"
                + "</Relationships>";
        }

        private static string Workbook()
        {
            return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                + "<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">"
                + "<sheets><sheet name=\"Tổng hợp\" sheetId=\"1\" r:id=\"rId1\"/><sheet name=\"Danh sách biển\" sheetId=\"2\" r:id=\"rId2\"/></sheets>"
                + "</workbook>";
        }

        private static string WorkbookRelationships()
        {
            return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                + "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
                + "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/>"
                + "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet2.xml\"/>"
                + "<Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>"
                + "</Relationships>";
        }

        private static string AppProperties()
        {
            return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                + "<Properties xmlns=\"http://schemas.openxmlformats.org/officeDocument/2006/extended-properties\" xmlns:vt=\"http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes\">"
                + "<Application>BHT</Application><AppVersion>" + Xml(BhtVersion.Version) + "</AppVersion></Properties>";
        }

        private static string CoreProperties()
        {
            string now = DateTime.UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", CultureInfo.InvariantCulture);
            return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                + "<cp:coreProperties xmlns:cp=\"http://schemas.openxmlformats.org/package/2006/metadata/core-properties\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">"
                + "<dc:title>Báo cáo biển báo BHT</dc:title><dc:creator>BHT " + Xml(BhtVersion.Version) + "</dc:creator>"
                + "<dcterms:created xsi:type=\"dcterms:W3CDTF\">" + now + "</dcterms:created></cp:coreProperties>";
        }

        private static string Styles()
        {
            return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                + "<styleSheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">"
                + "<fonts count=\"3\"><font><sz val=\"10\"/><name val=\"Arial\"/></font><font><b/><sz val=\"15\"/><color rgb=\"FF173B57\"/><name val=\"Arial\"/></font><font><b/><sz val=\"10\"/><color rgb=\"FFFFFFFF\"/><name val=\"Arial\"/></font></fonts>"
                + "<fills count=\"3\"><fill><patternFill patternType=\"none\"/></fill><fill><patternFill patternType=\"gray125\"/></fill><fill><patternFill patternType=\"solid\"><fgColor rgb=\"FF007EA7\"/><bgColor indexed=\"64\"/></patternFill></fill></fills>"
                + "<borders count=\"2\"><border/><border><left style=\"thin\"><color rgb=\"FFB7C9D3\"/></left><right style=\"thin\"><color rgb=\"FFB7C9D3\"/></right><top style=\"thin\"><color rgb=\"FFB7C9D3\"/></top><bottom style=\"thin\"><color rgb=\"FFB7C9D3\"/></bottom></border></borders>"
                + "<cellStyleXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\"/></cellStyleXfs>"
                + "<cellXfs count=\"4\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\"/><xf numFmtId=\"0\" fontId=\"1\" fillId=\"0\" borderId=\"0\" xfId=\"0\"/><xf numFmtId=\"0\" fontId=\"2\" fillId=\"2\" borderId=\"1\" xfId=\"0\" applyAlignment=\"1\"><alignment horizontal=\"center\" vertical=\"center\" wrapText=\"1\"/></xf><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"1\" xfId=\"0\" applyAlignment=\"1\"><alignment vertical=\"top\" wrapText=\"1\"/></xf></cellXfs>"
                + "<cellStyles count=\"1\"><cellStyle name=\"Normal\" xfId=\"0\" builtinId=\"0\"/></cellStyles></styleSheet>";
        }

        private static string SummarySheet(string project, IList<SignReportRow> rows)
        {
            var grouped = rows.GroupBy(x => (x.Code ?? "") + "\u001f" + (x.Description ?? "") + "\u001f" + (x.Condition ?? ""))
                .Select(g => new { Row = g.First(), Count = g.Count() })
                .OrderBy(x => x.Row.Code, StringComparer.OrdinalIgnoreCase).ThenBy(x => x.Row.Condition, StringComparer.OrdinalIgnoreCase).ToList();
            var sb = SheetStart(new[] { 7.0, 14.0, 42.0, 24.0, 12.0 }, 5);
            Row(sb, 1, new[] { TextCell("A1", "BÁO CÁO TỔNG HỢP BIỂN BÁO", 1) });
            Row(sb, 2, new[] { TextCell("A2", "Công trình: " + Safe(project), 0), TextCell("D2", "Tổng số biển", 0), NumberCell("E2", rows.Count, 0) });
            Row(sb, 3, new[] { TextCell("A3", "Xuất lúc: " + DateTime.Now.ToString("dd/MM/yyyy HH:mm", CultureInfo.CurrentCulture) + " — BHT " + BhtVersion.Version, 0) });
            Row(sb, 5, Cells(5, new[] { "STT", "Mã hiệu", "Loại biển", "Tình trạng", "Số lượng" }, 2));
            int index = 1;
            foreach (var item in grouped)
            {
                int r = index + 5;
                Row(sb, r, new[] { NumberCell("A" + r, index, 3), TextCell("B" + r, item.Row.Code, 3), TextCell("C" + r, item.Row.Description, 3), TextCell("D" + r, item.Row.Condition, 3), NumberCell("E" + r, item.Count, 3) });
                index++;
            }
            int last = Math.Max(5, grouped.Count + 5);
            sb.Append("</sheetData><autoFilter ref=\"A5:E").Append(last).Append("\"/><mergeCells count=\"2\"><mergeCell ref=\"A1:E1\"/><mergeCell ref=\"A3:E3\"/></mergeCells></worksheet>");
            return sb.ToString();
        }

        private static string DetailSheet(string project, IList<SignReportRow> rows)
        {
            double[] widths = { 7, 24, 18, 15, 18, 13, 38, 13, 16, 15, 12, 18, 18, 12, 20, 10, 10, 16, 34, 16 };
            string[] headers = { "STT", "Công trình", "Đoạn tuyến", "Gói", "Loại biển", "Mã hiệu", "Tên biển", "Phía", "Lý trình", "Tuyến", "Offset (m)", "Nguồn lý trình", "Trạng thái lý trình", "Route revision", "Tình trạng", "Số trụ", "Số mặt", "Kiểm tra", "Ghi chú", "ID hồ sơ" };
            var sb = SheetStart(widths, 4);
            Row(sb, 1, new[] { TextCell("A1", "DANH SÁCH BIỂN BÁO HIỆN TRẠNG", 1) });
            Row(sb, 2, new[] { TextCell("A2", "Công trình: " + Safe(project) + " — Tổng số: " + rows.Count, 0) });
            Row(sb, 4, Cells(4, headers, 2));
            int r = 5;
            foreach (var item in rows)
            {
                string[] values = { item.Number.ToString(CultureInfo.InvariantCulture), item.Project, item.Segment, item.Package, item.SignGroup, item.Code,
                    item.Description, item.Side, item.Chainage, item.Route, item.Offset, item.StationSource, item.StationStatus, item.RouteRevision,
                    item.Condition, item.PoleCount, item.FaceCount, item.Checked, item.Note, item.ObjectId };
                var cells = new List<string>();
                for (int c = 0; c < values.Length; c++) cells.Add(TextCell(Column(c + 1) + r, values[c], 3));
                Row(sb, r, cells);
                r++;
            }
            int last = Math.Max(4, r - 1);
            sb.Append("</sheetData><autoFilter ref=\"A4:T").Append(last).Append("\"/><mergeCells count=\"2\"><mergeCell ref=\"A1:T1\"/><mergeCell ref=\"A2:T2\"/></mergeCells></worksheet>");
            return sb.ToString();
        }

        private static StringBuilder SheetStart(double[] widths, int headerRow)
        {
            var sb = new StringBuilder("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\"><sheetViews><sheetView workbookViewId=\"0\"><pane ySplit=\"");
            sb.Append(headerRow).Append("\" topLeftCell=\"A").Append(headerRow + 1).Append("\" activePane=\"bottomLeft\" state=\"frozen\"/></sheetView></sheetViews><cols>");
            for (int i = 0; i < widths.Length; i++) sb.Append("<col min=\"").Append(i + 1).Append("\" max=\"").Append(i + 1).Append("\" width=\"").Append(widths[i].ToString("0.##", CultureInfo.InvariantCulture)).Append("\" customWidth=\"1\"/>");
            sb.Append("</cols><sheetData>");
            return sb;
        }

        private static IEnumerable<string> Cells(int row, string[] values, int style)
        {
            for (int i = 0; i < values.Length; i++) yield return TextCell(Column(i + 1) + row, values[i], style);
        }

        private static void Row(StringBuilder sb, int row, IEnumerable<string> cells)
        {
            sb.Append("<row r=\"").Append(row).Append("\">");
            foreach (string cell in cells) sb.Append(cell);
            sb.Append("</row>");
        }

        private static string TextCell(string reference, string value, int style)
        {
            return "<c r=\"" + reference + "\" s=\"" + style + "\" t=\"inlineStr\"><is><t xml:space=\"preserve\">" + Xml(Safe(value)) + "</t></is></c>";
        }

        private static string NumberCell(string reference, int value, int style)
        {
            return "<c r=\"" + reference + "\" s=\"" + style + "\" t=\"n\"><v>" + value.ToString(CultureInfo.InvariantCulture) + "</v></c>";
        }

        private static string Column(int number)
        {
            string result = "";
            while (number > 0) { number--; result = (char)('A' + number % 26) + result; number /= 26; }
            return result;
        }

        private static string Safe(string value) { return value ?? ""; }
        private static string Xml(string value)
        {
            return Safe(value).Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("\"", "&quot;").Replace("'", "&apos;");
        }
    }
}
