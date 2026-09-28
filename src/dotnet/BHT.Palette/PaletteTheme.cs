using System;
using System.Drawing;
using System.Windows.Forms;

namespace BHT.Palette
{
    internal static class PaletteTheme
    {
        private static readonly Color Navy = Color.FromArgb(28, 55, 82);
        private static readonly Color Accent = Color.FromArgb(0, 126, 167);
        private static readonly Color Canvas = Color.FromArgb(242, 246, 249);
        private static readonly Color ButtonBack = Color.FromArgb(226, 238, 246);
        private static readonly Color Border = Color.FromArgb(154, 181, 199);
        private static readonly Color Ink = Color.FromArgb(31, 48, 61);

        public static void Apply(Control root, TabControl tabs, Label document, Label status)
        {
            root.BackColor = Canvas;
            document.BackColor = Navy;
            document.ForeColor = Color.White;
            document.Font = new Font("Segoe UI Semibold", 9f);
            status.BackColor = Color.FromArgb(231, 244, 250);
            status.ForeColor = Ink;
            tabs.DrawMode = TabDrawMode.OwnerDrawFixed;
            tabs.ItemSize = new Size(74, 27);
            tabs.SizeMode = TabSizeMode.Fixed;
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
            if (value.Contains("LỖI") || value.Contains("KHÔNG CÙNG PHIÊN BẢN")) return Color.FromArgb(255, 232, 232);
            if (value.Contains("CẢNH BÁO") || value.Contains("ĐÃ BỊ HỦY")) return Color.FromArgb(255, 246, 218);
            return Color.FromArgb(231, 244, 250);
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
                    b.FlatAppearance.MouseOverBackColor = Color.FromArgb(207, 231, 242);
                    b.FlatAppearance.MouseDownBackColor = Color.FromArgb(180, 216, 232);
                    b.BackColor = ButtonBack;
                    b.ForeColor = Navy;
                    b.UseVisualStyleBackColor = false;
                }
                else if (c is ListView)
                {
                    c.BackColor = Color.White;
                    c.ForeColor = Ink;
                    ((ListView)c).BorderStyle = BorderStyle.FixedSingle;
                }
                else if (c is TextBox && c != parent)
                {
                    c.BackColor = ((TextBox)c).ReadOnly ? Color.FromArgb(247, 249, 251) : Color.White;
                    c.ForeColor = Ink;
                }
                else if (c is ComboBox || c is ListBox)
                {
                    c.BackColor = Color.White;
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
            using (var back = new SolidBrush(active ? Accent : Color.FromArgb(218, 228, 235))) e.Graphics.FillRectangle(back, r);
            using (var font = new Font("Segoe UI Semibold", 9f))
                TextRenderer.DrawText(e.Graphics, tabs.TabPages[e.Index].Text, font, r,
                    active ? Color.White : Navy, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
        }
    }
}
