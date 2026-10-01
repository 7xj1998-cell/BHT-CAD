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
        private readonly ComboBox groups = new ComboBox { Width = 190, DropDownStyle = ComboBoxStyle.DropDownList };
        private readonly FlowLayoutPanel grid = new FlowLayoutPanel { Dock = DockStyle.Fill, AutoScroll = true, Padding = new Padding(8) };
        private readonly List<Panel> cards = new List<Panel>();
        private readonly List<Image> images = new List<Image>();
        private readonly Label count = new Label { AutoSize = true };
        private readonly PictureBox preview = new PictureBox { Dock = DockStyle.Top, Height = 180, SizeMode = PictureBoxSizeMode.Zoom, BackColor = Color.White };
        private readonly Label details = new Label { Dock = DockStyle.Top, Height = 78, Padding = new Padding(4) };
        private readonly ComboBox speed = new ComboBox { Width = 100, DropDownStyle = ComboBoxStyle.DropDown };
        private readonly CheckBox multi = new CheckBox { Text = "Chọn nhiều mặt trên cùng trụ", AutoSize = true };
        private readonly ListBox faces = new ListBox { Dock = DockStyle.Fill, IntegralHeight = false };
        private readonly Dictionary<string, TdtSignEntry> entries = new Dictionary<string, TdtSignEntry>(StringComparer.OrdinalIgnoreCase);
        private readonly string initialCode, sourceDescription;
        private readonly Panel speedPanel = new Panel { Dock = DockStyle.Top, Height = 60 };
        private readonly Label validation = new Label { Dock = DockStyle.Top, Height = 42, ForeColor = Color.Firebrick };
        public TdtSignEntry SelectedSign { get; private set; }
        public string SelectedCode { get; private set; }
        public List<string> SelectedFaces { get; private set; }

        public SignPickerForm() : this("", "", "") { }
        public SignPickerForm(string currentCode, string description, string faceCodes)

        {
            initialCode = currentCode ?? ""; sourceDescription = description ?? "";
            Text = "Thư viện hình ảnh biển báo";
            Font = new Font("Segoe UI", 9f);
            Size = new Size(1120, 740); MinimumSize = new Size(900, 630);
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
            var hint = new Label { Dock = DockStyle.Bottom, Height = 48, Text = "Ảnh từ thư viện TDT. Tốc độ chèn lấy theo ô nhập. Mặt đầu tiên là mã biển chính.", ForeColor = Color.DimGray };
            sidebar.Controls.Add(faces); sidebar.Controls.Add(actions); sidebar.Controls.Add(hint);
            sidebar.Controls.Add(validation); sidebar.Controls.Add(multiPanel); sidebar.Controls.Add(speedPanel); sidebar.Controls.Add(details); sidebar.Controls.Add(preview);
            foreach (string code in SignSearch.SplitCodes(faceCodes)) faces.Items.Add(code);
            multi.Checked = faces.Items.Count > 0;
            multi.CheckedChanged += (s, e) => { faces.Enabled = actions.Enabled = multi.Checked; };
            faces.Enabled = actions.Enabled = multi.Checked;
            Controls.Add(grid); Controls.Add(sidebar); Controls.Add(toolbar); Controls.Add(footer);
            var paths = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            string folder = Path.Combine(TdtSignLibrary.InstalledRoot, "Data", "Bien bao");
            if (Directory.Exists(folder))
                foreach (string path in Directory.GetFiles(folder, "*.bmp", SearchOption.AllDirectories))
                    paths[SignSearch.CodeKey(Path.GetFileNameWithoutExtension(path))] = path;
            grid.SuspendLayout();
            foreach (var sign in TdtSignLibrary.GetCatalog())
            {
                var card = new Panel { Width = 160, Height = 175, BorderStyle = BorderStyle.FixedSingle, Margin = new Padding(5), Tag = sign };
                var picture = new PictureBox { Dock = DockStyle.Top, Height = 108, SizeMode = PictureBoxSizeMode.Zoom, BackColor = Color.White };
                string path;
                if (paths.TryGetValue(SignSearch.CodeKey(sign.Code), out path))
                {
                    try { using (var original = Image.FromFile(path)) picture.Image = new Bitmap(original); images.Add(picture.Image); }
                    catch (ArgumentException) { } catch (IOException) { }
                }
                if (picture.Image == null)
                    picture.Controls.Add(new Label { Dock = DockStyle.Fill, Text = "Chưa có ảnh TDT", TextAlign = ContentAlignment.MiddleCenter, ForeColor = Color.Gray });
                var label = new Label { Dock = DockStyle.Fill, TextAlign = ContentAlignment.TopCenter,
                    Text = sign.Code + "\r\n" + (string.IsNullOrWhiteSpace(sign.Description) ? "Chưa có tên trong TDT" : sign.Description), Padding = new Padding(3) };
                card.Controls.Add(label); card.Controls.Add(picture);
                entries[sign.Code] = sign;
                EventHandler choose = (s, e) => Choose(card);
                EventHandler confirm = (s, e) => { Choose(card); if (multi.Checked) AddFace(); else if (!IsSpeedSign(sign)) AcceptSign(); else speed.Focus(); };
                foreach (Control control in new Control[] { card, picture, label }.Concat(picture.Controls.Cast<Control>())) { control.Click += choose; control.DoubleClick += confirm; }
                cards.Add(card); grid.Controls.Add(card);
            }
            grid.ResumeLayout();
            search.TextChanged += (s, e) => Filter(); groups.SelectedIndexChanged += (s, e) => Filter();
            Filter();
            string baseCode = SignPresentation.Speed(initialCode, sourceDescription).HasValue ? "P.127" : initialCode;
            var initial = cards.FirstOrDefault(x => string.Equals(((TdtSignEntry)x.Tag).Code, baseCode, StringComparison.OrdinalIgnoreCase));
            if (initial != null) { Choose(initial); grid.ScrollControlIntoView(initial); }
        }
        private static int GroupIndex(TdtSignEntry sign)
        {
            string name = TextSearch.Fold(sign.SourceDrawing);
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
            speed.Enabled = IsSpeedSign(sign); validation.Text = "";
            if (changed)
            {
                var value = SignPresentation.Speed(initialCode, sourceDescription) ?? SignPresentation.Speed("P.127", sourceDescription);
                speed.Text = speed.Enabled && value.HasValue ? value.Value.ToString() : "";
            }
            foreach (var c in cards) c.BackColor = c == card ? Color.LightCyan : SystemColors.Control;
        }
        private string CurrentCode()
        {
            if (SelectedSign == null) return null;
            if (!IsSpeedSign(SelectedSign) || string.IsNullOrWhiteSpace(speed.Text)) return SelectedSign.Code;
            string candidate = "P.127-" + speed.Text.Trim();
            var value = SignPresentation.Speed(candidate, "");
            if (!value.HasValue) { validation.Text = "Nhập tốc độ nguyên từ 5 đến 130 km/h."; speed.Focus(); return null; }
            return "P.127-" + value.Value;
        }
        private void AddFace()
        {
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
            if (multi.Checked)
            {
                if (faces.Items.Count == 0) { AddFace(); if (faces.Items.Count == 0) return; }
                SelectedFaces = faces.Items.Cast<string>().ToList(); SelectedCode = SelectedFaces[0];
                string baseCode = SignPresentation.Speed(SelectedCode, "").HasValue ? "P.127" : SelectedCode;
                TdtSignEntry entry; entries.TryGetValue(baseCode, out entry);
                SelectedSign = entry ?? new TdtSignEntry { Code = SelectedCode };
            }
            else { SelectedCode = CurrentCode(); if (SelectedCode == null) return; SelectedFaces = null; }
            DialogResult = DialogResult.OK; Close();
        }
        protected override void Dispose(bool disposing)
        {
            if (disposing) { preview.Image = null; foreach (var image in images) image.Dispose(); }
            base.Dispose(disposing);
        }
    }
}
