using System;
using System.Drawing;
using System.Globalization;
using System.Windows.Forms;

namespace BHT.Palette
{
    public sealed class RtkScaleForm : Form
    {
        private readonly ComboBox symbol = new NoWheelComboBox { Dock = DockStyle.Fill };
        private readonly ComboBox label = new NoWheelComboBox { Dock = DockStyle.Fill };
        private readonly Label preview = new Label { AutoSize = true, Dock = DockStyle.Fill };
        private readonly Label error = new Label { AutoSize = true, ForeColor = Color.Firebrick };
        public string SymbolScale { get; private set; }
        public string LabelScale { get; private set; }

        public RtkScaleForm(string symbolScale, string labelScale)
        {
            Text = "Tỷ lệ ký hiệu và nhãn RTK";
            Font = new Font("Segoe UI", 9f); AutoScaleMode = AutoScaleMode.Dpi;
            ClientSize = new Size(470, 315); FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = MinimizeBox = false; StartPosition = FormStartPosition.CenterParent;
            var form = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, Padding = new Padding(12) };
            form.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 130)); form.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            foreach (var combo in new[] { symbol, label })
            {
                combo.Items.AddRange(new object[] { "0.5", "0.75", "1", "1.5", "2", "3", "5", "10" });
                combo.TextChanged += (s, e) => UpdatePreview();
            }
            symbol.Text = symbolScale; label.Text = labelScale;
            form.Controls.Add(new Label { Text = "Tỷ lệ dấu X", AutoSize = true }); form.Controls.Add(symbol);
            form.Controls.Add(new Label { Text = "Tỷ lệ nhãn RTK", AutoSize = true }); form.Controls.Add(label);
            form.Controls.Add(preview); form.SetColumnSpan(preview, 2);
            var help = new Label { AutoSize = true, MaximumSize = new Size(425, 0), Text = "Mức 1: dấu X cỡ 1 đơn vị, chữ cao 0,5 đơn vị. Chọn mức có sẵn hoặc nhập từ 0,01 đến 100, tối đa 3 số lẻ.\r\n\r\nCỡ dấu X dùng chung cho các điểm POINT trong bản vẽ. Cỡ chữ chỉ đổi nhãn RTK của BHT. Tọa độ và vị trí nhãn được giữ.\r\n\r\nDùng nút Cập nhật nhãn RTK riêng để tạo nhãn thiếu và sắp lại nhãn tự động." };
            form.Controls.Add(help); form.SetColumnSpan(help, 2); form.Controls.Add(error); form.SetColumnSpan(error, 2);
            var actions = new FlowLayoutPanel { AutoSize = true, Dock = DockStyle.Fill, FlowDirection = FlowDirection.RightToLeft };
            var cancel = new Button { Text = "Hủy", AutoSize = true, DialogResult = DialogResult.Cancel };
            var apply = new Button { Text = "Áp dụng tỷ lệ", AutoSize = true };
            var reset = new Button { Text = "Về chuẩn 1:1", AutoSize = true };
            reset.Click += (s, e) => { symbol.Text = label.Text = "1"; error.Text = ""; };
            apply.Click += (s, e) => AcceptScale();
            actions.Controls.Add(cancel); actions.Controls.Add(apply); actions.Controls.Add(reset);
            form.Controls.Add(actions); form.SetColumnSpan(actions, 2); Controls.Add(form);
            AcceptButton = apply; CancelButton = cancel; UpdatePreview();
        }

        private void UpdatePreview()
        {
            double x, h;
            preview.Text = SignScaleForm.TryScale(symbol.Text, out x) && SignScaleForm.TryScale(label.Text, out h)
                ? "Dấu X: " + x.ToString("0.###", CultureInfo.InvariantCulture) + " đơn vị    |    Cao chữ: " + (h * 0.5).ToString("0.####", CultureInfo.InvariantCulture) + " đơn vị"
                : "Nhập hai tỷ lệ hợp lệ.";
        }

        private void AcceptScale()
        {
            double x, h;
            if (!SignScaleForm.TryScale(symbol.Text, out x)) { error.Text = "Tỷ lệ dấu X: từ 0,01 đến 100, tối đa 3 số lẻ."; symbol.Focus(); return; }
            if (!SignScaleForm.TryScale(label.Text, out h)) { error.Text = "Tỷ lệ nhãn: từ 0,01 đến 100, tối đa 3 số lẻ."; label.Focus(); return; }
            SymbolScale = x.ToString("0.###", CultureInfo.InvariantCulture); LabelScale = h.ToString("0.###", CultureInfo.InvariantCulture);
            DialogResult = DialogResult.OK; Close();
        }
    }
}
