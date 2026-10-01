using System;
using System.Drawing;
using System.Globalization;
using System.Windows.Forms;

namespace BHT.Palette
{
    public sealed class PlacementOptionsForm : Form
    {
        private readonly ComboBox mode = new NoWheelComboBox { Dock = DockStyle.Fill, DropDownStyle = ComboBoxStyle.DropDownList };
        private readonly ComboBox direction = new NoWheelComboBox { Dock = DockStyle.Fill, DropDownStyle = ComboBoxStyle.DropDownList };
        private readonly TextBox angle = new TextBox { Dock = DockStyle.Fill };
        private readonly Label error = new Label { AutoSize = true, ForeColor = Color.Firebrick };
        private string chosenDegrees;
        public int ModeIndex { get { return mode.SelectedIndex; } }
        public int DirectionIndex { get { return direction.SelectedIndex; } }
        public string Degrees { get { return chosenDegrees ?? angle.Text.Trim().Replace(',', '.'); } }
        public string Mode { get { return new[] { "DIRECT", "ELBOW", "WAYPOINT" }[ModeIndex]; } }
        public string Direction { get { return new[] { "HORIZONTAL", "ROUTE", "PICK", "ANGLE" }[DirectionIndex]; } }

        public PlacementOptionsForm(string title, int lastMode, int lastDirection, string degrees)
        {
            Text = "Đặt tự do — " + title;
            Font = new Font("Segoe UI", 9f);
            AutoScaleMode = AutoScaleMode.Dpi;
            ClientSize = new Size(450, 275);
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = MinimizeBox = false;
            StartPosition = FormStartPosition.CenterParent;
            var form = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, Padding = new Padding(12) };
            form.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 100));
            form.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            mode.Items.AddRange(new object[] { "Đường dẫn thẳng", "Gấp khúc tự động", "Chọn điểm trung gian" });
            direction.Items.AddRange(new object[] { "Ngang (0°)", "Theo tuyến", "Chọn hướng trên CAD", "Nhập góc" });
            mode.SelectedIndex = Math.Max(0, Math.Min(2, lastMode));
            direction.SelectedIndex = Math.Max(0, Math.Min(3, lastDirection));
            angle.Text = degrees;
            direction.SelectedIndexChanged += (s, e) => angle.Enabled = DirectionIndex == 3;
            angle.Enabled = DirectionIndex == 3;
            Action<string, Control> row = (label, control) => { form.Controls.Add(new Label { Text = label, AutoSize = true }); form.Controls.Add(control); };
            row("Đường dẫn", mode); row("Hướng ký hiệu", direction); row("Góc WCS (°)", angle);
            var help = new Label { AutoSize = true, MaximumSize = new Size(405, 0), Text = "Bấm Đặt trên CAD, rồi chọn vị trí. Với điểm trung gian: chọn các điểm → Enter → vị trí cuối. Esc hủy; điểm RTK giữ nguyên." };
            form.Controls.Add(help); form.SetColumnSpan(help, 2);
            form.Controls.Add(error); form.SetColumnSpan(error, 2);
            var buttons = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.RightToLeft, Dock = DockStyle.Fill };
            var cancel = new Button { Text = "Hủy", DialogResult = DialogResult.Cancel, AutoSize = true };
            var place = new Button { Text = "Đặt trên CAD", AutoSize = true };
            place.Click += (s, e) => {
                double value;
                if (DirectionIndex == 3 && (!double.TryParse(Degrees, NumberStyles.Float, CultureInfo.InvariantCulture, out value) || double.IsNaN(value) || double.IsInfinity(value)))
                { error.Text = "Nhập góc hợp lệ, ví dụ 90 hoặc -45."; angle.Focus(); return; }
                chosenDegrees = Degrees;
                DialogResult = DialogResult.OK; Close();
            };
            buttons.Controls.Add(cancel); buttons.Controls.Add(place);
            form.Controls.Add(buttons); form.SetColumnSpan(buttons, 2);
            AcceptButton = place; CancelButton = cancel; Controls.Add(form);
        }
    }
}
