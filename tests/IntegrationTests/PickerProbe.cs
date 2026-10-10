using System;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Windows.Forms;
public class PickerProbe
{
    [Autodesk.AutoCAD.Runtime.CommandMethod("BHTPICKERPROBE")]
    public static void RunNative() {
        string result=Path.Combine(Path.GetDirectoryName(typeof(PickerProbe).Assembly.Location),"picker-probe.txt");
        try {Test();File.WriteAllText(result,"PASS native picker workflow");} catch(Exception ex) {File.WriteAllText(result,"FAIL "+ex);}
    }
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
        var loadPreview = typeof(BHT.Palette.SignPickerForm).GetMethod("BundledPreview", BindingFlags.Static | BindingFlags.NonPublic);
        foreach (string code in new[] { "R.122", "P.131c", "S.508a", "S.508b" })
            using (var image = (Image)loadPreview.Invoke(null, new object[] { code }))
            {
                if (image == null || image.Width < 10 || image.Height < 10) throw new Exception("Missing embedded preview " + code);
            }
        Console.WriteLine("PASS embedded-R122-P131c-S508ab-without-image-folder");
        using(var form=new BHT.Palette.SignPickerForm("IE.472a@500.5","",""))
        {
            ShowHidden(form);
            if(!Field<Panel>(form,"metresPanel").Visible || Field<TextBox>(form,"metres").Text != "500.5" || !form.SelectedSign.HasVector || Field<Label>(form,"validation").Text != "") throw new Exception("Toll distance not available");
            Field<TextBox>(form,"metres").Text="0";Invoke(form,"AcceptSign");
            if(form.DialogResult==DialogResult.OK) throw new Exception("Invalid toll distance accepted");
            Field<TextBox>(form,"metres").Text="750,5";Invoke(form,"AddFace");Invoke(form,"AcceptSign");
            if(form.SelectedCode != "IE.472a@750.5" || form.SelectedFaces[0] != "IE.472a@750.5") throw new Exception("Toll face distance lost");
            Console.WriteLine("PASS toll-distance-load-validation-per-face");
        }
        using(var form=new BHT.Palette.SignPickerForm("IE.472b","",""))
        {
            ShowHidden(form);
            if(Field<Panel>(form,"metresPanel").Visible || !form.SelectedSign.HasVector) throw new Exception("Toll location plate incorrect");
            ((Button)form.CancelButton).PerformClick();Application.DoEvents();
            if(form.Visible || form.DialogResult != DialogResult.Cancel) throw new Exception("Modeless cancel did not close");
            Console.WriteLine("PASS toll-location-plate-modeless-cancel-closes");
        }
        foreach (string family in new[] { "DP.134", "R.306" })
            using (var form = new BHT.Palette.SignPickerForm(family + "-60", "gioihan80", ""))
            {
                ShowHidden(form); var value = Field<ComboBox>(form,"speed");
                if (value.Text != "60" || !Field<Panel>(form,"speedPanel").Visible || form.SelectedSign.Code != family) throw new Exception("Speed family load failed " + family);
                value.Text = "800"; Invoke(form,"AcceptSign");
                if (form.DialogResult == DialogResult.OK) throw new Exception("Invalid speed accepted " + family);
                value.Text = "40"; Invoke(form,"AddFace"); Invoke(form,"AddFace"); Invoke(form,"AcceptSign");
                if (form.SelectedCode != family + "-40" || form.SelectedFaces.Count != 2 || form.SelectedFaces[1] != family + "-40") throw new Exception("Per-face speed lost " + family);
                Console.WriteLine("PASS " + family + " explicit-speed-load-validation-multiple-faces");
            }
        using (var combo = new BHT.Palette.NoWheelComboBox())
        {
            combo.Items.AddRange(new object[] { "QCVN", "NOI_BO", "CHUA_XAC_DINH" }); combo.SelectedIndex = 0;
            var method = typeof(BHT.Palette.NoWheelComboBox).GetMethod("WndProc", BindingFlags.Instance | BindingFlags.NonPublic);
            var msg = Message.Create(combo.Handle, 0x020A, new IntPtr(-120 << 16), IntPtr.Zero);
            method.Invoke(combo, new object[] { msg });
            if (combo.SelectedIndex != 0) throw new Exception("Wheel changed selection");
            combo.SelectedIndex = 1;
            if (combo.SelectedIndex != 1) throw new Exception("Explicit selection blocked");
            Console.WriteLine("PASS wheel-does-not-change-combo-explicit-selection-works");
        }
        using (var form = new BHT.Palette.SignPickerForm())
        {
            form.ShowInTaskbar = false; form.Opacity = 0; form.Show(); Application.DoEvents(); form.PerformLayout();
            var grid = form.Controls.OfType<FlowLayoutPanel>().First(x => x.Dock == DockStyle.Fill);
            var toolbar = form.Controls.OfType<FlowLayoutPanel>().First(x => x.Dock == DockStyle.Top);
            var search = toolbar.Controls.OfType<TextBox>().First();
            var groups = toolbar.Controls.OfType<ComboBox>().First();
            int total = grid.Controls.Count;
            int thumbnails = grid.Controls.Cast<Control>().SelectMany(x => x.Controls.OfType<PictureBox>()).Count(x => x.Image != null);
            int missing = grid.Controls.Cast<Control>().SelectMany(x => x.Controls.OfType<PictureBox>()).Count(x => (string)x.Tag == "UNAVAILABLE");
            Console.WriteLine("REAL-PREVIEWS=" + (thumbnails - missing) + " MISSING=" + missing);
            if (missing > 0) throw new Exception("Missing actual sign previews (code cards do not count)");
            Console.WriteLine("CARDS=" + total + " THUMBNAILS=" + thumbnails);
            int catalogCount=Field<System.Collections.Generic.List<Panel>>(form,"cards").Count;
            if (catalogCount < (Environment.GetEnvironmentVariable("BHT_SIGN_PROVIDER") == "BUILTIN" ? 16 : 100) || total>60 || thumbnails==0 || thumbnails!=total) throw new Exception("Library pagination or lazy images failed");
            using (var bitmap = new Bitmap(form.Width, form.Height))
            {
                form.DrawToBitmap(bitmap, new Rectangle(0,0,form.Width,form.Height));
                bitmap.Save(Path.Combine(Path.GetDirectoryName(typeof(PickerProbe).Assembly.Location), "picker.png"));
            }
            search.Text = "toc do"; Invoke(form,"Filter");
            int found = grid.Controls.Cast<Control>().Count(x => ((BHT.Bridge.TdtSignEntry)x.Tag).Code == "P.127" && BHT.Core.SignSearch.Score(search.Text, ((BHT.Bridge.TdtSignEntry)x.Tag).Code, ((BHT.Bridge.TdtSignEntry)x.Tag).Description) >= 0);
            if (found != 1) throw new Exception("Speed search failed");
            search.Text = ""; groups.SelectedIndex = 3; Invoke(form,"Filter");
            int visible = grid.Controls.Cast<Control>().Count(x => x.Visible);
            if (visible == 0 || grid.Controls.Cast<Control>().Any(x => x.Visible && !BHT.Core.TextSearch.Fold(((BHT.Bridge.TdtSignEntry)x.Tag).Group + " " + ((BHT.Bridge.TdtSignEntry)x.Tag).SourceDrawing).Contains("hieu lenh")))
                throw new Exception("Group filter failed");
            Console.WriteLine("PASS picker-construction, thumbnails, speed-search, group-filter");
        }

        using (var form = new BHT.Palette.SignPickerForm("P.127", "bbtron1m25 gioihan80", ""))
        {
            ShowHidden(form);
            using (var bitmap = new Bitmap(form.Width, form.Height))
            {
                form.DrawToBitmap(bitmap, new Rectangle(0, 0, form.Width, form.Height));
                bitmap.Save(Path.Combine(Path.GetDirectoryName(typeof(PickerProbe).Assembly.Location), "picker-selected.png"));
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
            var card = Field<System.Collections.Generic.List<Panel>>(form,"cards").First(x => ((BHT.Bridge.TdtSignEntry)x.Tag).Code == "P.127");
            Invoke(form, "Choose", card);
            if (Field<ComboBox>(form, "speed").Text != "80") throw new Exception("New-record speed inference failed");
            Invoke(form, "AddFace"); ((Button)form.CancelButton).PerformClick();
            if (form.SelectedCode != null || form.SelectedFaces != null || form.DialogResult != DialogResult.Cancel) throw new Exception("Cancel committed staged faces");
            Console.WriteLine("PASS new-record-speed-inference, cancel-does-not-commit");
        }
        if (BHT.Bridge.TdtSignLibrary.Find("S.505a") != null)
        {
        using (var form = new BHT.Palette.SignPickerForm("S.505a@8", "", ""))
        {
            ShowHidden(form); var value = Field<TextBox>(form, "weight");
            if (value.Text != "8" || !Field<Panel>(form, "weightPanel").Visible || Field<Panel>(form, "metresPanel").Visible) throw new Exception("Truck weight load/unit failed");
            value.Text = "0"; Invoke(form, "AcceptSign");
            if (form.DialogResult == DialogResult.OK) throw new Exception("Invalid weight accepted");
            value.Text = "8,5"; Invoke(form, "AcceptSign");
            if (form.SelectedCode != "S.505a@8.5") throw new Exception("Edited weight lost");
            Console.WriteLine("PASS picker-weight-load-validate-edit");
        }
        using (var form = new BHT.Palette.SignPickerForm("S.505a", "", "P.124a"))
        {
            ShowHidden(form); var value = Field<TextBox>(form, "weight");
            if (value.Text != "") throw new Exception("Legacy truck gained unrequested weight");
            value.Text = "8"; Invoke(form, "AddFace"); value.Text = "12"; Invoke(form, "AddFace"); Invoke(form, "AcceptSign");
            if (form.SelectedFaces.Count != 3 || form.SelectedFaces[1] != "S.505a@8" || form.SelectedFaces[2] != "S.505a@12") throw new Exception("Per-face weights lost");
            Console.WriteLine("PASS picker-independent-multi-face-weights");
        }
        using (var form = new BHT.Palette.SignPickerForm("S.505a@8", "", ""))
        {
            ShowHidden(form); Field<TextBox>(form, "weight").Text = ""; Invoke(form, "AcceptSign");
            if (form.SelectedCode != "S.505a") throw new Exception("Cannot remove optional weight");
            Console.WriteLine("PASS picker-optional-weight-removal");
        }
        }
        else Console.WriteLine("SKIP truck-weight-picker: sign unavailable in builtin catalog; full TDT fixture covers this family");
        using (var form = new BHT.Palette.SignPickerForm("S.509a@4.5", "", ""))
        {
            ShowHidden(form); var value = Field<TextBox>(form, "metres");
            if (value.Text != "4.5") throw new Exception("Existing metre value lost");
            value.Text = "abc"; Invoke(form, "AcceptSign");
            if (form.DialogResult == DialogResult.OK) throw new Exception("Invalid metres accepted");
            value.Text = "3,8"; Invoke(form, "AcceptSign");
            if (form.SelectedCode != "S.509a@3.8") throw new Exception("Edited metres not returned");
            Console.WriteLine("PASS picker-metres-load-validate-edit");
        }
        using (var form = new BHT.Palette.SignPickerForm("P.127-80", "", "P.127-800"))
        {
            ShowHidden(form); Invoke(form, "AcceptSign");
            if (form.DialogResult == DialogResult.OK || form.SelectedCode != null) throw new Exception("Invalid staged face accepted");
            Console.WriteLine("PASS invalid-staged-face-rejected");
        }
        using (var form = new BHT.Palette.SignPickerForm("P.127-80", "", ""))
        {
            ShowHidden(form);
            for (int i = 0; i < 21; i++) Invoke(form, "AddFace");
            if (Field<ListBox>(form, "faces").Items.Count != 20) throw new Exception("More than 20 faces allowed");
            Invoke(form, "AcceptSign");
            if (form.SelectedFaces.Count != 20) throw new Exception("Valid 20-face assembly rejected");
            Console.WriteLine("PASS picker-twenty-face-limit");
        }
        using (var form = new BHT.Palette.PlacementOptionsForm("Cọc tiêu", 2, 3, "90"))
        {
            ShowHidden(form); form.PerformLayout();
            if (form.Mode != "WAYPOINT" || form.Direction != "ANGLE") throw new Exception("Placement option mapping");
            var value = Field<TextBox>(form, "angle"); value.Text = "NaN";
            ((Button)form.AcceptButton).PerformClick();
            if (form.DialogResult == DialogResult.OK) throw new Exception("Invalid angle accepted");
            using (var image = new Bitmap(form.Width, form.Height)) { form.DrawToBitmap(image,new Rectangle(0,0,form.Width,form.Height)); image.Save(Path.Combine(Path.GetDirectoryName(typeof(PickerProbe).Assembly.Location),"placement.png")); }
            value.Text = "-45,5"; ((Button)form.AcceptButton).PerformClick();
            if (form.DialogResult != DialogResult.OK || form.Degrees != "-45.5") throw new Exception("Valid angle rejected: " + form.DialogResult + "/" + form.Degrees);
            Console.WriteLine("PASS native-placement-options-waypoints-validation-decimal-angle");
        }
        foreach (string legacy in new[] { "R.415", "W.239" })
        using (var parameterForm = new BHT.Palette.SignPickerForm(legacy, "", ""))
        {
            if (parameterForm.SelectedSign == null || !parameterForm.SelectedSign.Code.EndsWith("a")) throw new Exception("Legacy variant selection " + legacy);
        }
        using (var parameterForm = new BHT.Palette.SignPickerForm("I.439", "", "", true, "CẦU YÊN CHÂU", "Km252+831", "QL.6"))
        {
            ShowHidden(parameterForm);
            if (!Field<Panel>(parameterForm, "bridgePanel").Visible) throw new Exception("Bridge fields hidden");
            Field<TextBox>(parameterForm, "bridgeStation").Text = "bad"; Invoke(parameterForm, "AcceptSign");
            if (parameterForm.DialogResult == DialogResult.OK) throw new Exception("Invalid bridge station accepted");
            Field<TextBox>(parameterForm, "bridgeStation").Text = "Km39+900"; Invoke(parameterForm, "AcceptSign");
            if (parameterForm.SelectedCode != "I.439" || parameterForm.SelectedBridgeName != "CẦU YÊN CHÂU" || parameterForm.SelectedBridgeStation != "Km39+900" || parameterForm.SelectedBridgeRoad != "QL.6") throw new Exception("Bridge parameters missing: " + parameterForm.SelectedCode + "|" + parameterForm.SelectedBridgeName + "|" + parameterForm.SelectedBridgeStation + "|" + parameterForm.SelectedBridgeRoad);
        }
        Console.WriteLine("PASS legacy-variants-bridge-input-validation-preview-and-selection");
    }
    static void ShowHidden(Form parameterForm) { parameterForm.ShowInTaskbar = false; parameterForm.Opacity = 0; parameterForm.Show(); Application.DoEvents(); }
    static T Field<T>(object parameterForm, string name) { return (T)parameterForm.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic).GetValue(parameterForm); }
    static void Invoke(object parameterForm, string name, params object[] args) { parameterForm.GetType().GetMethod(name, BindingFlags.Instance | BindingFlags.NonPublic).Invoke(parameterForm, args); }
}

