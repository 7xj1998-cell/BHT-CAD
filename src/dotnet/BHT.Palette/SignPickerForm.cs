using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using BHT.Bridge;
using BHT.Core;
namespace BHT.Palette
{
    public sealed class SignPickerForm : Form
    {
        private readonly TextBox search = new TextBox { Width = 310 };
        private readonly ComboBox groups = new NoWheelComboBox { Width = 190, DropDownStyle = ComboBoxStyle.DropDownList };
        private readonly FlowLayoutPanel grid = new FlowLayoutPanel { Dock = DockStyle.Fill, AutoScroll = true, Padding = new Padding(8) };
        private readonly List<Panel> cards = new List<Panel>();
        private readonly List<Image> images = new List<Image>();
        private readonly Label count = new Label { AutoSize = true };
        private readonly PictureBox preview = new PictureBox { Dock = DockStyle.Top, Height = 180, SizeMode = PictureBoxSizeMode.Zoom, BackColor = Color.White };
        private readonly Label details = new Label { Dock = DockStyle.Top, Height = 55, Padding = new Padding(4) };
        private readonly ComboBox speed = new NoWheelComboBox { Width = 100, DropDownStyle = ComboBoxStyle.DropDown };
        private readonly CheckBox multi = new CheckBox { Text = "Chọn nhiều mặt trên cùng trụ", AutoSize = true };
        private readonly ListBox faces = new ListBox { Dock = DockStyle.Fill, IntegralHeight = false };
        private readonly Dictionary<string, TdtSignEntry> entries = new Dictionary<string, TdtSignEntry>(StringComparer.OrdinalIgnoreCase);
        private readonly string initialCode, sourceDescription;
        private readonly TextBox metres = new TextBox { Width = 100 };
        private readonly Panel metresPanel = new Panel { Dock = DockStyle.Top, Height = 60 };
        private readonly Panel speedPanel = new Panel { Dock = DockStyle.Top, Height = 60 };
        private readonly Label validation = new Label { Dock = DockStyle.Top, Height = 42, ForeColor = Color.Firebrick };
        private readonly TextBox bridgeName = new TextBox { Width = 238, MaxLength = 80 };
        private readonly TextBox bridgeStation = new TextBox { Width = 238, MaxLength = 80 };
        private readonly TextBox bridgeRoad = new TextBox { Width = 238, MaxLength = 80 };
        private readonly Panel bridgePanel = new Panel { Dock = DockStyle.Top, Height = 155 };
        public string SelectedBridgeName { get; private set; }
        public string SelectedBridgeStation { get; private set; }
        public string SelectedBridgeRoad { get; private set; }
        public TdtSignEntry SelectedSign { get; private set; }
        public string SelectedCode { get; private set; }
        public List<string> SelectedFaces { get; private set; }

        private readonly CheckBox fill = new CheckBox { Text = "Tô màu báo hiệu (Hatch)", AutoSize = true };
        public bool SelectedFill { get { return fill.Checked; } }

        public SignPickerForm() : this("", "", "") { }
        public SignPickerForm(string currentCode, string description, string faceCodes) : this(currentCode, description, faceCodes, true) { }
        public SignPickerForm(string currentCode, string description, string faceCodes, bool filled)

            : this(currentCode, description, faceCodes, filled, "", "", "") { }
        public SignPickerForm(string currentCode, string description, string faceCodes, bool filled, string name, string station, string road)
        {
            bridgeName.Text = name; bridgeStation.Text = station; bridgeRoad.Text = road;
            CaptureBridgeText();
            fill.Checked = filled;
            initialCode = currentCode ?? ""; sourceDescription = description ?? "";
            Text = "Thư viện hình ảnh biển báo";
            Font = new Font("Segoe UI", 9f);
            Size = new Size(1120, 820); MinimumSize = new Size(900, 760);
            StartPosition = FormStartPosition.CenterParent;
            var toolbar = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 42, Padding = new Padding(8) };
            toolbar.Controls.Add(new Label { Text = "Tìm mã / tên:", AutoSize = true, Padding = new Padding(0, 4, 0, 0) });
            toolbar.Controls.Add(search); toolbar.Controls.Add(groups);
            groups.Items.AddRange(new object[] { "Tất cả", "Biển cấm", "Biển nguy hiểm", "Biển hiệu lệnh", "Biển chỉ dẫn", "Biển phụ" });
            groups.SelectedIndex = 0;
            var footer = new FlowLayoutPanel { Dock = DockStyle.Bottom, Height = 45, Padding = new Padding(8) };
            var accept = new Button { Text = "Chọn biển", AutoSize = true };
            var cancel = new Button { Text = "Đóng", DialogResult = DialogResult.Cancel };
            accept.Click += (s, e) => AcceptSign(); footer.Controls.Add(accept); footer.Controls.Add(cancel); footer.Controls.Add(count);
            CancelButton = cancel; AcceptButton = accept;
            var sidebar = new Panel { Dock = DockStyle.Right, Width = 270, Padding = new Padding(8) };
            var actions = new FlowLayoutPanel { Dock = DockStyle.Bottom, Height = 76 };
            var add = new Button { Text = "Thêm mặt", AutoSize = true };
            var remove = new Button { Text = "Bỏ mặt", AutoSize = true };
            var up = new Button { Text = "Lên", AutoSize = true };
            var down = new Button { Text = "Xuống", AutoSize = true };
            actions.Controls.AddRange(new Control[] { add, remove, up, down });
            add.Click += (s, e) => AddFace();
            remove.Click += (s, e) => { if (faces.SelectedIndex >= 0) faces.Items.RemoveAt(faces.SelectedIndex); };
            up.Click += (s, e) => MoveFace(-1); down.Click += (s, e) => MoveFace(1);
            var multiPanel = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 32 };
            multiPanel.Controls.Add(multi);
            speed.Items.AddRange(new object[] { "", "40", "50", "60", "70", "80", "90", "100", "120" });
            speedPanel.Controls.Add(new Label { Text = "Tốc độ P.127 (km/h):", AutoSize = true, Location = new Point(0, 0) });
            speed.Location = new Point(0, 23); speedPanel.Controls.Add(speed);
            metresPanel.Controls.Add(new Label { Text = "Giá trị thực tế (m):", AutoSize = true });
            metres.Location = new Point(0, 23); metresPanel.Controls.Add(metres); metresPanel.Visible = false;
            foreach (var item in new[] { new { Label = "Tên cầu (I.439):", Box = bridgeName, Y = 0 }, new { Label = "Lý trình trên biển:", Box = bridgeStation, Y = 50 }, new { Label = "Tên đường:", Box = bridgeRoad, Y = 100 } })
            {
                bridgePanel.Controls.Add(new Label { Text = item.Label, AutoSize = true, Location = new Point(0, item.Y) });
                item.Box.Location = new Point(0, item.Y + 21); bridgePanel.Controls.Add(item.Box);
                item.Box.TextChanged += (s, e) => UpdateBridgePreview();
            }
            bridgePanel.Visible = false;
            var hint = new Label { Dock = DockStyle.Bottom, Height = 65, Text = "Ảnh là mẫu; CAD dùng giá trị thực tế bạn nhập. Tô màu áp dụng khi chèn CAD. Mặt đầu tiên là biển chính, nằm trên cùng.", ForeColor = Color.DimGray };
            sidebar.Controls.Add(faces); sidebar.Controls.Add(actions); sidebar.Controls.Add(hint);
            // Fill is controlled for the whole drawing in the Palette toolbar.
            sidebar.Controls.Add(validation); sidebar.Controls.Add(multiPanel); sidebar.Controls.Add(bridgePanel); sidebar.Controls.Add(metresPanel); sidebar.Controls.Add(speedPanel); sidebar.Controls.Add(details); sidebar.Controls.Add(preview);
            foreach (string code in SignSearch.SplitCodes(faceCodes)) faces.Items.Add(code);
            multi.Checked = faces.Items.Count > 0;
            multi.CheckedChanged += (s, e) => { faces.Enabled = actions.Enabled = multi.Checked; };
            faces.Enabled = actions.Enabled = multi.Checked;
            Controls.Add(grid); Controls.Add(sidebar); Controls.Add(toolbar); Controls.Add(footer);
            var paths = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            string folder = Path.Combine(TdtSignLibrary.InstalledRoot, "Data", "Bien bao");
            if (TdtSignLibrary.InstalledRoot != "" && Directory.Exists(folder))
                foreach (string path in Directory.GetFiles(folder, "*.bmp", SearchOption.AllDirectories))
                    paths[SignSearch.CodeKey(Path.GetFileNameWithoutExtension(path))] = path;
            // Bundled, verified images also work on machines without TDT.
            var location = new DirectoryInfo(Path.GetDirectoryName(typeof(SignPickerForm).Assembly.Location));
            for (var directory = location; directory != null; directory = directory.Parent)
                foreach (string candidate in new[] { Path.Combine(directory.FullName, "Images"), Path.Combine(directory.FullName, "assets", "sign-previews") })
                    if (Directory.Exists(candidate))
                        foreach (string path in Directory.GetFiles(candidate, "*.png"))
                            paths[SignSearch.CodeKey(Path.GetFileNameWithoutExtension(path))] = path;
            grid.SuspendLayout();
            foreach (var sign in TdtSignLibrary.GetCatalog())
            {
                // These are old XML headings/duplicates, not selectable sign codes.
                if (sign.Code.StartsWith("Biển số ", StringComparison.OrdinalIgnoreCase)) continue;
                var card = new Panel { Width = 160, Height = 175, BorderStyle = BorderStyle.FixedSingle, Margin = new Padding(5), Tag = sign };
                var picture = new PictureBox { Dock = DockStyle.Top, Height = 108, SizeMode = PictureBoxSizeMode.Zoom, BackColor = Color.White };
                picture.Image = BundledPreview(sign.Code) ?? BundledPreview(sign.NameFrom);
                if (picture.Image != null) images.Add(picture.Image);
                string path;
                if (picture.Image == null && (paths.TryGetValue(SignSearch.CodeKey(sign.Code), out path) ||
                    (!string.IsNullOrEmpty(sign.NameFrom) && paths.TryGetValue(SignSearch.CodeKey(sign.NameFrom), out path))))
                {
                    try { using (var original = Image.FromFile(path)) picture.Image = new Bitmap(original); images.Add(picture.Image); }
                    catch (ArgumentException) { } catch (IOException) { }
                }
                if (picture.Image == null)
                { picture.Tag = "UNAVAILABLE"; picture.Image = CodePreview(sign); images.Add(picture.Image); }
                var label = new Label { Dock = DockStyle.Fill, TextAlign = ContentAlignment.TopCenter,
                    Text = sign.Code + "\r\n" + (string.IsNullOrWhiteSpace(sign.Description) ? "Chưa có tên biển" : sign.Description), Padding = new Padding(3) };
                card.Controls.Add(label); card.Controls.Add(picture);
                entries[sign.Code] = sign;
                EventHandler choose = (s, e) => Choose(card);
                EventHandler confirm = (s, e) => { Choose(card); if (multi.Checked) AddFace(); else if (metresPanel.Visible) { metres.Focus(); metres.SelectAll(); } else if (bridgePanel.Visible) bridgeName.Focus(); else if (!IsSpeedSign(sign)) AcceptSign(); else speed.Focus(); };
                foreach (Control control in new Control[] { card, picture, label }.Concat(picture.Controls.Cast<Control>())) { control.Click += choose; control.DoubleClick += confirm; }
                cards.Add(card); grid.Controls.Add(card);
            }
            grid.ResumeLayout();
            search.TextChanged += (s, e) => Filter(); groups.SelectedIndexChanged += (s, e) => Filter();
            Filter();
            string baseCode = SignPresentation.Speed(initialCode, sourceDescription).HasValue ? "P.127" : SignCorrections.Canonical(initialCode);
            var initial = cards.FirstOrDefault(x => string.Equals(((TdtSignEntry)x.Tag).Code, baseCode, StringComparison.OrdinalIgnoreCase));
            if (initial != null) { Choose(initial); grid.ScrollControlIntoView(initial); }
        }
        // Identifiable code card only: never imply an exact regulatory icon when no bitmap is available.
        private static Image BundledPreview(string code)
        {
            if (string.IsNullOrWhiteSpace(code)) return null;
            var assembly = typeof(SignPickerForm).Assembly;
            string key = SignSearch.CodeKey(code);
            string resource = assembly.GetManifestResourceNames().FirstOrDefault(name =>
                name.StartsWith("BHT.SignPreviews.", StringComparison.Ordinal) &&
                SignSearch.CodeKey(name.Substring("BHT.SignPreviews.".Length).Replace(".png", "")) == key);
            if (resource == null) return null;
            using (var stream = assembly.GetManifestResourceStream(resource))
            using (var original = Image.FromStream(stream)) return new Bitmap(original);
        }

        private static Image CodePreview(TdtSignEntry sign)
        {
            var bitmap = new Bitmap(160,108);
            using(var g = Graphics.FromImage(bitmap))
            using(var pen = new Pen(sign.Code.StartsWith("P.") ? Color.Red : Color.RoyalBlue, 3))
            using(var font = new Font(FontFamily.GenericSansSerif,19,FontStyle.Bold))
            using(var small = new Font(FontFamily.GenericSansSerif,9))
            {
                g.Clear(Color.White); g.DrawRectangle(pen,5,5,149,96);
                g.DrawString(sign.Code,font,Brushes.Black,8,30);
                g.DrawString("Mã biển / chưa có ảnh",small,Brushes.Gray,8,78);
            }
            return bitmap;
        }
        private static int GroupIndex(TdtSignEntry sign)
        {
            string name = TextSearch.Fold(sign.Group + " " + sign.SourceDrawing);
            if (name.Contains("nguy hiem")) return 2;
            if (name.Contains("hieu lenh")) return 3;
            if (name.Contains("chi dan")) return 4;
            if (name.Contains("phu")) return 5;
            if (name.Contains("cam")) return 1;
            return 0;
        }
        private void Filter()
        {
            grid.SuspendLayout(); int visible = 0; bool selectedVisible = false;
            foreach (var card in cards)
            {
                var sign = (TdtSignEntry)card.Tag;
                bool show = (groups.SelectedIndex == 0 || GroupIndex(sign) == groups.SelectedIndex)
                    && SignSearch.Score(search.Text, sign.Code, sign.Description) >= 0;
                card.Visible = show; if (show) visible++;
                if (show && sign == SelectedSign) selectedVisible = true;
            }
            if (!selectedVisible) { SelectedSign = null; preview.Image = null; details.Text = "Chọn biển để xem trước"; speed.Enabled = false; foreach (var card in cards) card.BackColor = SystemColors.Control; }
            count.Text = visible + " biển — nhấp đúp chọn / thêm mặt";
            grid.ResumeLayout();
        }
        private static bool IsSpeedSign(TdtSignEntry sign)
        {
            return sign != null && string.Equals(SignSearch.CodeKey(sign.Code), "P127", StringComparison.OrdinalIgnoreCase);
        }
        private void Choose(Panel card)
        {
            var sign = (TdtSignEntry)card.Tag;
            bool changed = SelectedSign != sign;
            SelectedSign = sign;
            preview.Image = card.Controls.OfType<PictureBox>().First().Image;
            details.Text = sign.Code + " — " + sign.Description + "\r\n" + sign.Group;
            speed.Enabled = IsSpeedSign(sign); speedPanel.Visible = speed.Enabled;
            bridgePanel.Visible = sign.Code.Equals("I.439", StringComparison.OrdinalIgnoreCase);
            metresPanel.Visible = SignPresentation.MetreDefault(sign.Code) != ""; validation.Text = "";
            if (changed)
            {
                metres.Text = SignPresentation.BaseCode(initialCode).Equals(sign.Code, StringComparison.OrdinalIgnoreCase) && SignPresentation.MetreValue(initialCode) != "" ? SignPresentation.MetreValue(initialCode) : SignPresentation.MetreDefault(sign.Code);
                var value = SignPresentation.Speed(initialCode, sourceDescription) ?? SignPresentation.Speed("P.127", sourceDescription);
                speed.Text = speed.Enabled && value.HasValue ? value.Value.ToString() : "";
            }
            UpdateBridgePreview();
            foreach (var c in cards) c.BackColor = c == card ? Color.LightCyan : SystemColors.Control;
        }
        private void UpdateBridgePreview()
        {
            CaptureBridgeText();
            if (!bridgePanel.Visible || SelectedSign == null || SelectedSign.Code != "I.439" || bridgeName.Text.Trim() == "") return;
            var bitmap = new Bitmap(480, 240);
            using (var g = Graphics.FromImage(bitmap))
            using (var big = new Font("Arial Narrow", 30, FontStyle.Bold))
            using (var small = new Font("Arial Narrow", 25, FontStyle.Bold))
            using (var format = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center })
            {
                g.Clear(Color.FromArgb(0, 127, 255)); g.DrawRectangle(Pens.White, 4, 4, 471, 231); g.DrawRectangle(Pens.White, 9, 9, 461, 221);
                g.DrawString(SelectedBridgeName, big, Brushes.White, new RectangleF(12, 15, 456, 115), format);
                g.DrawString(SignPresentation.BridgeLine(SelectedBridgeStation, SelectedBridgeRoad), small, Brushes.White, new RectangleF(12, 132, 456, 88), format);
            }
            var previous = preview.Image;
            preview.Image = bitmap;
            // Only dispose generated previews; catalog card images remain shared.
            if (previous != null && !cards.Any(c => c.Controls.OfType<PictureBox>().First().Image == previous)) { images.Remove(previous); previous.Dispose(); }
            images.Add(bitmap);
        }
        private string CurrentCode()
        {
            if (SelectedSign == null) return null;
            if (metresPanel.Visible)
            {
                string candidateMetres = SelectedSign.Code + "@" + metres.Text.Trim();
                string parsed = SignPresentation.MetreValue(candidateMetres);
                if (parsed == "") { validation.Text = "Nhập m lớn hơn 0, tối đa 100000, tối đa 3 số thập phân."; metres.Focus(); return null; }
                return SelectedSign.Code + "@" + parsed;
            }
            if (!IsSpeedSign(SelectedSign) || string.IsNullOrWhiteSpace(speed.Text)) return SelectedSign.Code;
            string candidate = "P.127-" + speed.Text.Trim();
            var value = SignPresentation.Speed(candidate, "");
            if (!value.HasValue) { validation.Text = "Nhập tốc độ nguyên từ 5 đến 130 km/h."; speed.Focus(); return null; }
            return "P.127-" + value.Value;
        }
        private void AddFace()
        {
            if (faces.Items.Count >= 20) { validation.Text = "Một trụ hỗ trợ tối đa 20 mặt biển."; return; }
            string code = CurrentCode();
            if (code == null) return;
            if (!multi.Checked) multi.Checked = true;
            // Do not collapse duplicate codes: two identical plates are still two faces.
            faces.Items.Add(code); faces.SelectedIndex = faces.Items.Count - 1;
        }
        private void MoveFace(int delta)
        {
            int i = faces.SelectedIndex, target = i + delta;
            if (i < 0 || target < 0 || target >= faces.Items.Count) return;
            object item = faces.Items[i]; faces.Items.RemoveAt(i); faces.Items.Insert(target, item); faces.SelectedIndex = target;
        }
        private void AcceptSign()
        {
            CaptureBridgeText();
            if (multi.Checked)
            {
                if (faces.Items.Count == 0) { AddFace(); if (faces.Items.Count == 0) return; }
                if (faces.Items.Count > 20) { validation.Text = "Một trụ hỗ trợ tối đa 20 mặt biển."; return; }
                foreach (string code in faces.Items)
                {
                    string error = SignPresentation.ValidationError(code);
                    if (error != "") { validation.Text = error; return; }
                    if (TdtSignLibrary.Find(code) == null) { validation.Text = "Mã biển không có trong danh mục: " + code; return; }
                }
                SelectedFaces = faces.Items.Cast<string>().ToList(); SelectedCode = SelectedFaces[0];
                string baseCode = SignPresentation.Speed(SelectedCode, "").HasValue ? "P.127" : SignPresentation.BaseCode(SelectedCode);
                TdtSignEntry entry; entries.TryGetValue(baseCode, out entry);
                SelectedSign = entry ?? new TdtSignEntry { Code = SelectedCode };
            }
            else { SelectedCode = CurrentCode(); if (SelectedCode == null) return; SelectedFaces = null; }
            if ((SelectedCode == "I.439" || (SelectedFaces != null && SelectedFaces.Contains("I.439"))) && SelectedBridgeStation != "")
            {
                double number;
                if (!Chainage.TryParse(SelectedBridgeStation, out number)) { validation.Text = "Lý trình không hợp lệ; ví dụ Km252+831."; bridgeStation.Focus(); return; }
            }
            DialogResult = DialogResult.OK; Close();
        }
        protected override void Dispose(bool disposing)
        {
            if (disposing) { preview.Image = null; foreach (var image in images) image.Dispose(); }
            base.Dispose(disposing);
        }
        private void CaptureBridgeText()
        {
            SelectedBridgeName = bridgeName.Text.Trim().Normalize();
            SelectedBridgeStation = bridgeStation.Text.Trim().Normalize();
            SelectedBridgeRoad = bridgeRoad.Text.Trim().Normalize();
        }
    }
}
