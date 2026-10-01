using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace BHT.Palette
{
    internal static class PaletteTheme
    {
        // 0.4.6-fix2: bang mau xanh la theo yeu cau nguoi dung.
        //  - Chu sang #D1FAE5 tren nen xanh dam (#065F46 nut/tieu de, #047857 nen chung).
        //  - Chu dam #065F46 tren nen xanh nhat #D1FAE5 (o nhap, danh sach, trang thai).
        // Moi cap mau chu/nen dat tuong phan >= 4.5:1 (WCAG AA).
        internal static readonly Color GreenDark = Color.FromArgb(0x06, 0x5F, 0x46);   // #065F46
        internal static readonly Color GreenLight = Color.FromArgb(0xD1, 0xFA, 0xE5);  // #D1FAE5
        private static readonly Color Canvas = Color.FromArgb(0x04, 0x78, 0x57);       // #047857 nen chung
        private static readonly Color GreenDeep = Color.FromArgb(0x06, 0x4E, 0x3B);    // #064E3B hover / vien
        private static readonly Color GreenPressed = Color.FromArgb(0x02, 0x2C, 0x22); // #022C22 nhan nut
        private static readonly Color InputBack = Color.FromArgb(0xEC, 0xFD, 0xF5);    // #ECFDF5 o nhap sua duoc
        private static readonly Color ErrorBack = Color.FromArgb(0xFE, 0xE2, 0xE2);
        private static readonly Color ErrorFore = Color.FromArgb(0x99, 0x1B, 0x1B);
        private static readonly Color WarnBack = Color.FromArgb(0xFE, 0xF3, 0xC7);
        private static readonly Color WarnFore = Color.FromArgb(0x92, 0x40, 0x0E);
        private static readonly Color ErrorOnGreen = Color.FromArgb(0xFE, 0xCA, 0xCA);

        public static void Apply(Control root, TabControl tabs, Label document, Label status)
        {
            root.BackColor = Canvas;
            root.ForeColor = GreenLight;
            StyleChildren(root);
            // Dat sau StyleChildren de tieu de va vung trang thai khong bi to lai nhu nhan thuong.
            document.BackColor = GreenDark;
            document.ForeColor = GreenLight;
            document.Font = new Font("Segoe UI Semibold", 9f);
            status.BackColor = GreenLight;
            status.ForeColor = GreenDark;
            tabs.Alignment = TabAlignment.Right;
            tabs.Multiline = true;
            tabs.DrawMode = TabDrawMode.OwnerDrawFixed;
            // 0.4.6-fix3: voi the doc (Alignment = Right) WinForms hieu ItemSize.Width la CHIEU CAO the,
            // ItemSize.Height la BE RONG dai the -> moi the rong 86 px, cao 38 px (dai the giu nguyen 86 px).
            tabs.ItemSize = new Size(TabHeight, TabStripWidth);
            tabs.SizeMode = TabSizeMode.Fixed;
            tabs.Padding = new Point(0, 0);
            tabs.ShowToolTips = true;
            tabs.DrawItem += DrawTab;
        }

        public static void ApplyDialog(Form dialog)
        {
            dialog.BackColor = Canvas;
            dialog.ForeColor = GreenLight;
            dialog.Font = new Font("Segoe UI", 9f);
            StyleChildren(dialog);
        }

        internal const int TabStripWidth = 86;
        internal const int TabHeight = 38;

        internal static Color ErrorBackColor { get { return ErrorBack; } }
        internal static Color ErrorForeColor { get { return ErrorFore; } }
        internal static Color WarnBackColor { get { return WarnBack; } }
        internal static Color WarnForeColor { get { return WarnFore; } }

        public static Color StatusBack(string text)
        {
            string value = (text ?? "").ToUpperInvariant();
            if (value.Contains("LỖI") || value.Contains("KHÔNG CÙNG PHIÊN BẢN")) return ErrorBack;
            if (value.Contains("CẢNH BÁO") || value.Contains("ĐÃ BỊ HỦY")) return WarnBack;
            return GreenLight;
        }

        public static Color StatusFore(string text)
        {
            string value = (text ?? "").ToUpperInvariant();
            if (value.Contains("LỖI") || value.Contains("KHÔNG CÙNG PHIÊN BẢN")) return ErrorFore;
            if (value.Contains("CẢNH BÁO") || value.Contains("ĐÃ BỊ HỦY")) return WarnFore;
            return GreenDark;
        }

        private static void StyleChildren(Control parent)
        {
            foreach (Control c in parent.Controls)
            {
                if (c is TabPage)
                {
                    c.BackColor = Canvas;
                    c.ForeColor = GreenLight;
                }
                else if (c is Button)
                {
                    var b = (Button)c;
                    b.FlatStyle = FlatStyle.Flat;
                    b.FlatAppearance.BorderColor = GreenLight;
                    b.FlatAppearance.BorderSize = 1;
                    b.FlatAppearance.MouseOverBackColor = GreenDeep;
                    b.FlatAppearance.MouseDownBackColor = GreenPressed;
                    b.BackColor = GreenDark;
                    b.ForeColor = GreenLight;
                    b.UseVisualStyleBackColor = false;
                }
                else if (c is ListView)
                {
                    c.BackColor = GreenLight;
                    c.ForeColor = GreenDark;
                    ((ListView)c).BorderStyle = BorderStyle.FixedSingle;
                    StyleListView((ListView)c);
                }
                else if (c is TextBoxBase && c != parent)
                {
                    var t = (TextBoxBase)c;
                    t.BackColor = t.ReadOnly ? GreenLight : InputBack;
                    t.ForeColor = GreenDark;
                }
                else if (c is ComboBox)
                {
                    var cb = (ComboBox)c;
                    cb.FlatStyle = FlatStyle.Flat;
                    cb.BackColor = InputBack;
                    cb.ForeColor = GreenDark;
                }
                else if (c is ListBox)
                {
                    c.BackColor = GreenLight;
                    c.ForeColor = GreenDark;
                    StyleListBox((ListBox)c);
                }
                else if (c is Label)
                {
                    // Nhan tren nen xanh: chu sang; nhan canh bao (do) doi sang do nhat de van doc duoc.
                    if (c.ForeColor == Color.DarkRed || c.ForeColor == Color.Red) c.ForeColor = ErrorOnGreen;
                    else c.ForeColor = GreenLight;
                }
                else if (c is CheckBox || c is RadioButton)
                {
                    c.ForeColor = GreenLight;
                    c.BackColor = Canvas;
                }
                else if (c is PictureBox)
                {
                    c.BackColor = GreenDark;
                }
                else if (c is FlowLayoutPanel || c is TableLayoutPanel || c is Panel)
                {
                    c.BackColor = Canvas;
                    c.ForeColor = GreenLight;
                }
                StyleChildren(c);
            }
        }

        // Tieu de cot va dong dang chon cua ListView (Details) ve bang mau xanh thay cho xam/xanh duong he thong.
        private static void StyleListView(ListView lv)
        {
            if (lv.OwnerDraw || lv.View != View.Details) return;
            lv.OwnerDraw = true;
            lv.DrawColumnHeader += (s, e) =>
            {
                using (var back = new SolidBrush(GreenDark)) e.Graphics.FillRectangle(back, e.Bounds);
                using (var edge = new Pen(Canvas))
                    e.Graphics.DrawLine(edge, e.Bounds.Right - 1, e.Bounds.Top + 2, e.Bounds.Right - 1, e.Bounds.Bottom - 3);
                var r = new Rectangle(e.Bounds.X + 4, e.Bounds.Y, Math.Max(0, e.Bounds.Width - 6), e.Bounds.Height);
                TextRenderer.DrawText(e.Graphics, e.Header == null ? "" : e.Header.Text, lv.Font, r, GreenLight,
                    TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis | TextFormatFlags.SingleLine | TextFormatFlags.NoPrefix);
            };
            lv.DrawItem += (s, e) => { e.DrawDefault = false; };
            lv.DrawSubItem += (s, e) =>
            {
                if (e.Item == null || !e.Item.Selected) { e.DrawDefault = true; return; }
                using (var back = new SolidBrush(GreenDark)) e.Graphics.FillRectangle(back, e.Bounds);
                var r = new Rectangle(e.Bounds.X + 4, e.Bounds.Y, Math.Max(0, e.Bounds.Width - 6), e.Bounds.Height);
                TextRenderer.DrawText(e.Graphics, e.SubItem == null ? "" : e.SubItem.Text, lv.Font, r, GreenLight,
                    TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis | TextFormatFlags.SingleLine | TextFormatFlags.NoPrefix);
            };
            // ListView OwnerDraw + FullRowSelect co the chi ve lai cot dau khi doi lua chon: ve lai ca dong.
            lv.ItemSelectionChanged += (s, e) => { try { if (e.Item != null) lv.Invalidate(e.Item.Bounds); } catch { } };
        }

        // Dong dang chon cua ListBox: nen #065F46, chu #D1FAE5.
        private static void StyleListBox(ListBox lb)
        {
            if (lb.DrawMode != DrawMode.Normal) return;
            lb.DrawMode = DrawMode.OwnerDrawFixed;
            lb.ItemHeight = Math.Max(lb.Font.Height + 2, 15);
            lb.DrawItem += (s, e) =>
            {
                if (e.Index < 0 || e.Index >= lb.Items.Count)
                {
                    using (var bg = new SolidBrush(GreenLight)) e.Graphics.FillRectangle(bg, e.Bounds);
                    return;
                }
                bool selected = (e.State & DrawItemState.Selected) == DrawItemState.Selected;
                using (var back = new SolidBrush(selected ? GreenDark : GreenLight)) e.Graphics.FillRectangle(back, e.Bounds);
                var r = new Rectangle(e.Bounds.X + 2, e.Bounds.Y, Math.Max(0, e.Bounds.Width - 3), e.Bounds.Height);
                TextRenderer.DrawText(e.Graphics, lb.GetItemText(lb.Items[e.Index]), lb.Font, r, selected ? GreenLight : GreenDark,
                    TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis | TextFormatFlags.SingleLine | TextFormatFlags.NoPrefix);
            };
        }

        private static void DrawTab(object sender, DrawItemEventArgs e)
        {
            var tabs = (TabControl)sender;
            PaintTab(e.Graphics, e.Bounds, e.Index == tabs.SelectedIndex, tabs.TabPages[e.Index].Text);
        }

        /// <summary>
        /// The ben phai: the thuong nen #065F46 chu #D1FAE5; the dang chon nen #D1FAE5 chu #065F46 + vach dam ben trai.
        /// 0.4.6-fix3: chu NGANG trong o 86 x 38 px. Ban fix2 xoay chu -90 do bang TextRenderer (GDI) - GDI bo qua
        /// phep xoay cua Graphics va o chu sau khi xoay chi dai 34 px, nen chu bi ve lech/cat mat -> the trong.
        /// </summary>
        internal static void PaintTab(Graphics g, Rectangle r, bool active, string text)
        {
            using (var back = new SolidBrush(active ? GreenLight : GreenDark)) g.FillRectangle(back, r);
            if (active)
                using (var bar = new SolidBrush(GreenDark)) g.FillRectangle(bar, r.Left, r.Top, 4, r.Height);
            using (var sep = new Pen(Canvas, 1f))
                g.DrawLine(sep, r.Left, r.Bottom - 1, r.Right, r.Bottom - 1);

            Rectangle textRect = new Rectangle(r.Left + (active ? 6 : 3), r.Top + 1, Math.Max(0, r.Width - (active ? 8 : 5)), Math.Max(0, r.Height - 2));
            using (var font = new Font("Segoe UI Semibold", 9f))
                TextRenderer.DrawText(g, BalanceLines(g, text ?? "", font, textRect.Width), font, textRect,
                    active ? GreenDark : GreenLight,
                    TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.WordBreak
                    | TextFormatFlags.NoPrefix | TextFormatFlags.EndEllipsis);
        }

        /// <summary>Ten the dai hon o chu: ngat thanh 2 dong can bang tai dau cach thuong (dau cach cung U+00A0 giu cac tu di lien,
        /// vd "Hồ\u00A0sơ đối\u00A0tượng" -> "Hồ sơ" / "đối tượng").</summary>
        private static string BalanceLines(Graphics g, string text, Font font, int width)
        {
            if (text.IndexOf(' ') < 0 || TextRenderer.MeasureText(g, text, font, Size.Empty, TextFormatFlags.NoPrefix).Width <= width) return text;
            string best = text;
            int bestWidth = int.MaxValue;
            for (int i = text.IndexOf(' '); i >= 0; i = text.IndexOf(' ', i + 1))
            {
                string a = text.Substring(0, i), b = text.Substring(i + 1);
                int w = Math.Max(TextRenderer.MeasureText(g, a, font, Size.Empty, TextFormatFlags.NoPrefix).Width,
                                 TextRenderer.MeasureText(g, b, font, Size.Empty, TextFormatFlags.NoPrefix).Width);
                if (w < bestWidth) { bestWidth = w; best = a + "\n" + b; }
            }
            return best;
        }

        /// <summary>
        /// TabControl tu ve toan bo (UserPaint): to nen dai the ben phai va vien trang the bang mau xanh,
        /// thay cho cac o den / vien xam he thong. Kich thuoc the va vung noi dung giu nguyen.
        /// </summary>
        internal sealed class ThemedTabControl : TabControl
        {
            public ThemedTabControl()
            {
                SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer
                         | ControlStyles.ResizeRedraw, true);
            }

            protected override void OnSelectedIndexChanged(EventArgs e)
            {
                base.OnSelectedIndexChanged(e);
                Invalidate();
            }

            protected override void OnPaint(PaintEventArgs e)
            {
                e.Graphics.Clear(Canvas);
                for (int i = 0; i < TabCount; i++)
                {
                    Rectangle r;
                    try { r = GetTabRect(i); } catch { continue; }
                    if (!e.ClipRectangle.IntersectsWith(r)) continue;
                    PaintTab(e.Graphics, r, i == SelectedIndex, TabPages[i].Text);
                }
                Rectangle page = DisplayRectangle;
                page.Inflate(1, 1);
                using (var pen = new Pen(GreenDark)) e.Graphics.DrawRectangle(pen, page.X, page.Y, page.Width - 1, page.Height - 1);
            }
        }
    }
}
