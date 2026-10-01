using System;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Windows.Forms;
class PickerProbe
{
    [STAThread] static void Main(string[] args)
    {
        AppDomain.CurrentDomain.AssemblyResolve += (s, e) => {
            string name = new AssemblyName(e.Name).Name + ".dll";
            string path = Path.Combine(args.Length > 0 ? args[0] : @"D:\AutoCAD 2024", name);
            return File.Exists(path) ? Assembly.LoadFrom(path) : null;
        };
        Test();
    }
    static void Test()
    {
        Application.EnableVisualStyles();
        using (var form = new BHT.Palette.SignPickerForm())
        {
            form.ShowInTaskbar = false; form.Opacity = 0; form.Show(); Application.DoEvents(); form.PerformLayout();
            var grid = form.Controls.OfType<FlowLayoutPanel>().First(x => x.Dock == DockStyle.Fill);
            var toolbar = form.Controls.OfType<FlowLayoutPanel>().First(x => x.Dock == DockStyle.Top);
            var search = toolbar.Controls.OfType<TextBox>().First();
            var groups = toolbar.Controls.OfType<ComboBox>().First();
            int total = grid.Controls.Count;
            int thumbnails = grid.Controls.Cast<Control>().SelectMany(x => x.Controls.OfType<PictureBox>()).Count(x => x.Image != null);
            Console.WriteLine("CARDS=" + total + " THUMBNAILS=" + thumbnails);
            if (total < 100 || thumbnails < 100) throw new Exception("Library cards missing");
            using (var bitmap = new Bitmap(form.Width, form.Height))
            {
                form.DrawToBitmap(bitmap, new Rectangle(0,0,form.Width,form.Height));
                bitmap.Save(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "picker.png"));
            }
            search.Text = "toc do";
            int found = grid.Controls.Cast<Control>().Count(x => ((BHT.Bridge.TdtSignEntry)x.Tag).Code == "P.127" && BHT.Core.SignSearch.Score(search.Text, ((BHT.Bridge.TdtSignEntry)x.Tag).Code, ((BHT.Bridge.TdtSignEntry)x.Tag).Description) >= 0);
            if (found != 1) throw new Exception("Speed search failed");
            groups.SelectedIndex = 3; search.Text = "";
            int visible = grid.Controls.Cast<Control>().Count(x => x.Visible);
            if (visible == 0 || grid.Controls.Cast<Control>().Any(x => x.Visible && !BHT.Core.TextSearch.Fold(((BHT.Bridge.TdtSignEntry)x.Tag).SourceDrawing).Contains("hieu lenh")))
                throw new Exception("Group filter failed");
            Console.WriteLine("PASS picker-construction, thumbnails, speed-search, group-filter");
        }

        using (var form = new BHT.Palette.SignPickerForm("P.127", "bbtron1m25 gioihan80", ""))
        {
            ShowHidden(form);
            using (var bitmap = new Bitmap(form.Width, form.Height))
            {
                form.DrawToBitmap(bitmap, new Rectangle(0, 0, form.Width, form.Height));
                bitmap.Save(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "picker-selected.png"));
            }
            var speed = Field<ComboBox>(form, "speed");
            if (speed.Text != "80" || Field<PictureBox>(form, "preview").Image == null) throw new Exception("Initial speed/preview missing");
            speed.Text = "800"; Invoke(form, "AcceptSign");
            if (form.DialogResult == DialogResult.OK || form.SelectedCode != null) throw new Exception("Invalid speed accepted");
            speed.Text = "60"; Invoke(form, "AcceptSign");
            if (form.SelectedCode != "P.127-60" || form.SelectedFaces != null) throw new Exception("Explicit speed not returned");
            Console.WriteLine("PASS selected-preview, survey-speed80, invalid-speed-rejected, explicit-speed60");
        }
        using (var form = new BHT.Palette.SignPickerForm("P.127-80", "gioihan40", "W.245a; S.509a"))
        {
            ShowHidden(form);
            if (Field<ComboBox>(form, "speed").Text != "80") throw new Exception("Explicit speed precedence failed");
            Invoke(form, "AddFace"); Invoke(form, "AddFace");
            var list = Field<ListBox>(form, "faces");
            if (list.Items.Count != 4) throw new Exception("Duplicate physical faces collapsed");
            for (int i = 0; i < 3; i++) Invoke(form, "MoveFace", -1);
            Invoke(form, "AcceptSign");
            if (form.SelectedCode != "P.127-80" || form.SelectedSign.Code != "P.127" || form.SelectedFaces.Count != 4 || form.SelectedFaces[1] != "W.245a")
                throw new Exception("Reordered faces not committed");
            Console.WriteLine("PASS multi-face-initialization, repeated-faces, reorder, main-code-from-first-face");
        }
        using (var form = new BHT.Palette.SignPickerForm("", "gioihan80", ""))
        {
            ShowHidden(form);
            var card = Field<FlowLayoutPanel>(form, "grid").Controls.Cast<Panel>().First(x => ((BHT.Bridge.TdtSignEntry)x.Tag).Code == "P.127");
            Invoke(form, "Choose", card);
            if (Field<ComboBox>(form, "speed").Text != "80") throw new Exception("New-record speed inference failed");
            Invoke(form, "AddFace"); ((Button)form.CancelButton).PerformClick();
            if (form.SelectedCode != null || form.SelectedFaces != null || form.DialogResult != DialogResult.Cancel) throw new Exception("Cancel committed staged faces");
            Console.WriteLine("PASS new-record-speed-inference, cancel-does-not-commit");
        }
    }
    static void ShowHidden(Form form) { form.ShowInTaskbar = false; form.Opacity = 0; form.Show(); Application.DoEvents(); }
    static T Field<T>(object form, string name) { return (T)form.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic).GetValue(form); }
    static void Invoke(object form, string name, params object[] args) { form.GetType().GetMethod(name, BindingFlags.Instance | BindingFlags.NonPublic).Invoke(form, args); }
}
