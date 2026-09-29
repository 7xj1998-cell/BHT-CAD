using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace BHT.Palette
{
    internal static class PaletteTheme
    {
        // Bang mau toi gon theo palette CAD: nen than, dieu khien xanh den,
        // chu hanh dong vang chanh va thong tin phu xanh lam.
        private static readonly Color Canvas = Color.FromArgb(31, 37, 48);
        private static readonly Color Surface = Color.FromArgb(39, 47, 61);
        private static readonly Color SurfaceRaised = Color.FromArgb(47, 57, 73);
        private static readonly Color Accent = Color.FromArgb(65, 126, 191);
        private static readonly Color Action = Color.FromArgb(220, 232, 55);
        private static readonly Color Cyan = Color.FromArgb(68, 202, 218);
        private static readonly Color Border = Color.FromArgb(72, 96, 126);
        private static readonly Color Ink = Color.FromArgb(236, 240, 244);
        private static readonly Color Muted = Color.FromArgb(174, 188, 202);

        public static void Apply(Control root, TabControl tabs, Label document, Label status)
        {
            root.BackColor = Canvas;
            document.BackColor = Color.FromArgb(24, 29, 38);
            document.ForeColor = Cyan;
            document.Font = new Font("Segoe UI Semibold", 9f);
            status.BackColor = Surface;
            status.ForeColor = Ink;
            tabs.Alignment = TabAlignment.Right;
            tabs.Multiline = true;
            tabs.DrawMode = TabDrawMode.OwnerDrawFixed;
            tabs.ItemSize = new Size(34, 86);
            tabs.SizeMode = TabSizeMode.Fixed;
            tabs.Padding = new Point(0, 0);
            tabs.DrawItem += DrawTab;
            StyleChildren(root);
        }

        public static void ApplyDialog(Form dialog)
        {
            dialog.BackColor = Canvas;
            dialog.ForeColor = Ink;
            dialog.Font = new Font("Segoe UI", 9f);
            StyleChildren(dialog);
        }

        public static Color StatusBack(string text)
        {
            string value = (text ?? "").ToUpperInvariant();
            if (value.Contains("LỖI") || value.Contains("KHÔNG CÙNG PHIÊN BẢN")) return Color.FromArgb(91, 42, 48);
            if (value.Contains("CẢNH BÁO") || value.Contains("ĐÃ BỊ HỦY")) return Color.FromArgb(92, 78, 34);
            return Surface;
        }

        public static Color StatusFore(string text)
        {
            string value = (text ?? "").ToUpperInvariant();
            if (value.Contains("LỖI") || value.Contains("KHÔNG CÙNG PHIÊN BẢN")) return Color.FromArgb(255, 196, 196);
            if (value.Contains("CẢNH BÁO") || value.Contains("ĐÃ BỊ HỦY")) return Color.FromArgb(255, 226, 126);
            return Ink;
        }

        private static void StyleChildren(Control parent)
        {
            foreach (Control c in parent.Controls)
            {
                if (c is TabPage)
                {
                    c.BackColor = Canvas;
                    c.ForeColor = Ink;
                }
                else if (c is Button)
                {
                    var b = (Button)c;
                    b.FlatStyle = FlatStyle.Flat;
                    b.FlatAppearance.BorderColor = Border;
                    b.FlatAppearance.MouseOverBackColor = Color.FromArgb(57, 71, 91);
                    b.FlatAppearance.MouseDownBackColor = Accent;
                    b.BackColor = Surface;
                    b.ForeColor = Action;
                    b.UseVisualStyleBackColor = false;
                }
                else if (c is ListView)
                {
                    c.BackColor = Surface;
                    c.ForeColor = Ink;
                    ((ListView)c).BorderStyle = BorderStyle.FixedSingle;
                }
                else if (c is TextBox && c != parent)
                {
                    c.BackColor = ((TextBox)c).ReadOnly ? Color.FromArgb(34, 41, 53) : SurfaceRaised;
                    c.ForeColor = ((TextBox)c).ReadOnly ? Muted : Ink;
                }
                else if (c is ComboBox || c is ListBox)
                {
                    c.BackColor = SurfaceRaised;
                    c.ForeColor = Ink;
                }
                else if (c is Label)
                {
                    if (c.ForeColor == Color.DarkBlue || c.ForeColor == Color.Black || c.ForeColor == Control.DefaultForeColor)
                        c.ForeColor = Muted;
                }
                else if (c is CheckBox || c is RadioButton)
                {
                    c.ForeColor = Ink;
                    c.BackColor = Canvas;
                }
                else if (c is FlowLayoutPanel || c is TableLayoutPanel || c is Panel)
                {
                    c.BackColor = Canvas;
                    c.ForeColor = Ink;
                }
                StyleChildren(c);
            }
        }

        private static void DrawTab(object sender, DrawItemEventArgs e)
        {
            var tabs = (TabControl)sender;
            bool active = e.Index == tabs.SelectedIndex;
            Rectangle r = e.Bounds;
            using (var back = new SolidBrush(active ? Accent : Color.FromArgb(25, 31, 41))) e.Graphics.FillRectangle(back, r);
            using (var edge = new Pen(active ? Action : Border, active ? 2f : 1f))
                e.Graphics.DrawLine(edge, r.Left, r.Top + 2, r.Left, r.Bottom - 2);

            GraphicsState state = e.Graphics.Save();
            try
            {
                e.Graphics.TranslateTransform(r.Left, r.Bottom);
                e.Graphics.RotateTransform(-90f);
                Rectangle textRect = new Rectangle(0, 0, r.Height, r.Width);
                using (var font = new Font("Segoe UI Semibold", 8.5f))
                    TextRenderer.DrawText(e.Graphics, tabs.TabPages[e.Index].Text, font, textRect,
                        active ? Action : Muted,
                        TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
            }
            finally { e.Graphics.Restore(state); }
        }
    }
}
