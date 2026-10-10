using System;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Windows.Forms;
using BHT.Palette;
using BHT.Bridge;
using BHT.Core;

using Autodesk.AutoCAD.Runtime;

public class PaletteLayoutProbe
{
    static int checks;
    static System.Exception uiError;
    static readonly BindingFlags Hidden = BindingFlags.Instance | BindingFlags.NonPublic;
    static object Field(object target, string name) { return target.GetType().GetField(name, Hidden).GetValue(target); }
    static void Set(object target, string name, object value) { target.GetType().GetField(name, Hidden).SetValue(target, value); }
    static object Call(object target, string name, params object[] args) { return target.GetType().GetMethods(Hidden).Single(m => m.Name == name && m.GetParameters().Length == args.Length).Invoke(target, args); }
    static void Check(string name, bool valid) { if (!valid) throw new System.Exception(name); checks++; Console.WriteLine("PASS " + name); }
    static System.Collections.Generic.IEnumerable<Control> Children(Control root)
    {
        foreach (Control child in root.Controls) { yield return child; foreach (var nested in Children(child)) yield return nested; }
    }

    [CommandMethod("BHTPALETTELAYOUTPROBE")] public static void Run()
    {
        Application.EnableVisualStyles();
        Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
        Application.ThreadException+=(s,e)=>{uiError=e.Exception;foreach(var form in Application.OpenForms.Cast<Form>().ToArray())form.Close();};
        string output = Path.Combine(Path.GetDirectoryName(typeof(PaletteLayoutProbe).Assembly.Location), "ui-preview");
        checks = 0;
        try { Test(output); if(uiError!=null)throw uiError; File.WriteAllText(Path.Combine(output, "result.txt"), "PASS palette layout and editor workflow (" + checks + " checks)"); }
        catch (System.Exception ex) { Directory.CreateDirectory(output); File.WriteAllText(Path.Combine(output, "result.txt"), "FAIL " + (uiError ?? ex)); }
    }

    static void Test(string output)
    {
        Directory.CreateDirectory(output);
        using(var placement=new PlacementOptionsForm("QA",0,1,"0")) {
            Check("placement-route-option-uses-perpendicular-mode",placement.Direction=="ROUTE_PERP");
            Check("placement-route-label-is-explicit",((ComboBox)Field(placement,"direction")).Text=="Vuông góc với tuyến");
        }
        using(var picker=new SignPickerForm("R.415a","","R.415a; R.415b")) {
            picker.StartPosition=FormStartPosition.Manual;picker.Location=new Point(-3000,-3000);picker.Show(); Application.DoEvents();
            Check("library-BHT-title",picker.Text=="Thư viện biển báo BHT");
            var allCards=(System.Collections.Generic.List<Panel>)Field(picker,"cards");
            Check("picker-retains-complete-catalog-with-bounded-page",allCards.Count>=467 && ((FlowLayoutPanel)Field(picker,"grid")).Controls.Count<=60);
            Check("picker-keeps-only-current-page-images",((System.Collections.Generic.List<Image>)Field(picker,"images")).Count<=61);
            Call(picker,"Filter");
            var reached=new System.Collections.Generic.HashSet<string>();
            int pages=(allCards.Count+59)/60;
            for(int page=0;page<pages;page++) {
                Set(picker,"pageIndex",page);Call(picker,"ShowPage");
                foreach(var card in ((FlowLayoutPanel)Field(picker,"grid")).Controls.Cast<Control>()) {
                    reached.Add(((TdtSignEntry)card.Tag).Code);
                    Check("every-page-card-has-image-before-click",card.Controls.OfType<PictureBox>().Single().Image!=null);
                }
            }
            Check("all-pages-reach-all-catalog-codes-without-loss",reached.Count==allCards.Count);
            Check("browsing-pages-keeps-images-bounded",((System.Collections.Generic.List<Image>)Field(picker,"images")).Count<=61);
            var place=typeof(SignPickerForm).GetMethod("IsPlace",BindingFlags.Static|BindingFlags.NonPublic);
            Check("place-fields-across-sign-groups",new[] {"DESTN_L","DESTINATION1","START","END","LOCATION","PAGODA_Vi","NAMEPART1","ĐỊAĐIỂM1"}.All(tag=>(bool)place.Invoke(null,new object[]{tag})));
            var groups=(ComboBox)Field(picker,"groups"); Check("supplementary-filter-present",groups.Items.Count==7 && groups.Items.Cast<string>().Contains("Biển phụ"));
            groups.SelectedIndex=6; Application.DoEvents();
            var supplementaryGrid=(FlowLayoutPanel)Field(picker,"grid");
            var supplementaryCards=supplementaryGrid.Controls.Cast<Control>().Where(c=>c.Visible && c.Tag is TdtSignEntry).Select(c=>(TdtSignEntry)c.Tag).ToList();
            Check("supplementary-filter-has-all-S-codes",supplementaryCards.Count>0 && supplementaryCards.All(s=>s.Code.StartsWith("S.",StringComparison.OrdinalIgnoreCase)) && supplementaryCards.Count==TdtSignLibrary.GetCatalog().Count(s=>s.Code.StartsWith("S.",StringComparison.OrdinalIgnoreCase)));
            Check("supplementary-filter-opens-at-first-row",supplementaryGrid.AutoScrollPosition.Y==0);
            using(var bitmap=new Bitmap(picker.Width,picker.Height)) {picker.DrawToBitmap(bitmap,picker.ClientRectangle);bitmap.Save(Path.Combine(output,"library-supplementary.png"));}
            groups.SelectedIndex=5; Application.DoEvents();
            var grid=(FlowLayoutPanel)Field(picker,"grid");
            var visible=grid.Controls.Cast<Control>().Where(c=>c.Visible).Select(c=>(TdtSignEntry)c.Tag).ToList();
            Check("highway-filter-shows-highway",visible.Count>0 && visible.All(e=>TextSearch.Fold(e.Group).Contains("cao toc")) && visible.All(e=>!e.Code.StartsWith("S.")));
            groups.SelectedIndex=0;
            var content=new SignContentFace {Index=0,Code="R.415a"}; content.Values["demo"]="Mặt đầu";
            picker.ConfigurePresentation(SignContent.Write(new[] {content}),"CAP1_3","0.3","0.8");
            ((ListBox)Field(picker,"faces")).SelectedIndex=0;Call(picker,"MoveFace",1);
            Check("moving-face-retains-content-index",SignContent.Read(picker.SelectedContent).Single().Index==1);
            Call(picker,"ReindexContent",0,-1,true);
            Check("removing-face-renumbers-content",SignContent.Read(picker.SelectedContent).Single().Index==0);
            picker.ConfigurePresentation("","CAP1_3","0.3","0.8");
            using(var finish=new Timer {Interval=80}) {
                finish.Tick+=(sender,args)=> {
                    var dialog=Application.OpenForms.Cast<Form>().FirstOrDefault(d=>d.Text=="Nội dung biển"); if(dialog==null) return; finish.Stop();
                    Check("saved-CAP1-opens-advanced-layout",Children(dialog).OfType<CheckBox>().Single(c=>c.Text.Contains("khung/trụ")).Checked);
                    using(var bitmap=new Bitmap(dialog.Width,dialog.Height)) {dialog.DrawToBitmap(bitmap,dialog.ClientRectangle);bitmap.Save(Path.Combine(output,"cap1-editor.png"));}
                    Children(dialog).OfType<Button>().Single(b=>b.Text=="Áp dụng").PerformClick();
                };
                finish.Start();Call(picker,"EditPresentation");finish.Stop();
            }
            Check("CAP1-editor-applies-parameters",picker.SelectedLayout=="CAP1_3" && picker.SelectedGap=="0.3" && picker.SelectedClearance=="0.8");
            using(var bitmap=new Bitmap(picker.Width,picker.Height)) {picker.DrawToBitmap(bitmap,picker.ClientRectangle);bitmap.Save(Path.Combine(output,"library-highway.png"));}
            picker.Close();
        }
        foreach(string code in new[] {"P.127-80","DP.134-60","R.306-40","P.117@4.5","S.505a@8","R.E9b@22:00-05:00"}) {
            using(var picker=new SignPickerForm(code,"","")) {
                picker.StartPosition=FormStartPosition.Manual;picker.Location=new Point(-3000,-3000);picker.Show();Application.DoEvents();
                Check("legacy-inputs-absent-from-sidebar",!Children(picker).Contains((Control)Field(picker,"speed")) && !Children(picker).Contains((Control)Field(picker,"metres")));
                using(var finish=new Timer {Interval=80}) {
                    finish.Tick+=(sender,args)=> {
                        var dialog=Application.OpenForms.Cast<Form>().FirstOrDefault(d=>d.Text=="Nội dung biển");if(dialog==null)return;finish.Stop();
                        var table=Children(dialog).OfType<DataGridView>().Single();
                        Check("unified-editor-has-legacy-field-"+code,table.Rows.Count>0);
                        if(code=="P.127-80") {
                            table.Rows[0].Cells[2].Value="800";Children(dialog).OfType<Button>().Single(b=>b.Text=="Áp dụng").PerformClick();
                            Check("unified-speed-rejects-invalid",dialog.Visible);
                            table.Rows[0].Cells[2].Value="90";
                            using(var bitmap=new Bitmap(dialog.Width,dialog.Height)){dialog.DrawToBitmap(bitmap,dialog.ClientRectangle);bitmap.Save(Path.Combine(output,"unified-content.png"));}
                        }
                        Children(dialog).OfType<Button>().Single(b=>b.Text=="Áp dụng").PerformClick();
                        if(dialog.DialogResult!=DialogResult.OK) {using(var bitmap=new Bitmap(dialog.Width,dialog.Height)){dialog.DrawToBitmap(bitmap,dialog.ClientRectangle);bitmap.Save(Path.Combine(output,"failed-editor.png"));} string problem="Enabled="+Children(dialog).OfType<Button>().Single(b=>b.Text=="Áp dụng").Enabled+" Visible="+Children(dialog).OfType<Button>().Single(b=>b.Text=="Áp dụng").Visible+" | "+string.Join(" | ",Children(dialog).OfType<Label>().Select(l=>l.Text));dialog.Close();throw new System.Exception("Unified editor could not apply "+code+": "+problem);}
                    };finish.Start();Call(picker,"EditPresentation");finish.Stop();
                }
                Call(picker,"AcceptSign");Check("unified-editor-persists-"+code,picker.SelectedCode==(code=="P.127-80" ? "P.127-90" : code));
            }
        }
        using(var picker=new SignPickerForm("P.127-80","","P.127-80; P.127-40")) {
            picker.StartPosition=FormStartPosition.Manual;picker.Location=new Point(-3000,-3000);picker.Show();Application.DoEvents();
            using(var finish=new Timer {Interval=80}) {
                finish.Tick+=(sender,args)=> {
                    var dialog=Application.OpenForms.Cast<Form>().FirstOrDefault(d=>d.Text=="Nội dung biển");if(dialog==null)return;finish.Stop();
                    var table=Children(dialog).OfType<DataGridView>().Single();Check("two-speed-faces-have-distinct-rows",table.Rows.Count==2);
                    table.Rows[0].Cells[2].Value="90";table.Rows[1].Cells[2].Value="50";
                    Children(dialog).OfType<Button>().Single(b=>b.Text=="Áp dụng").PerformClick();
                };finish.Start();Call(picker,"EditPresentation");finish.Stop();
            }
            Call(picker,"AcceptSign");Check("unified-editor-keeps-per-face-speed",picker.SelectedFaces.SequenceEqual(new[] {"P.127-90","P.127-50"}));
        }
        using(var picker=new SignPickerForm("IE.456A-1","","IE.456A-1; IE.456A-1")) {
            picker.ConfigurePresentation("","CAP1_9","0.2","0.6"); picker.StartPosition=FormStartPosition.Manual;picker.Location=new Point(-3000,-3000);picker.Show(); Application.DoEvents();
            Call(picker,"AcceptSign"); Check("place-name-required-before-accept",picker.DialogResult!=DialogResult.OK && ((Label)Field(picker,"validation")).Text.Contains("nội dung thực tế"));
            using(var finish=new Timer {Interval=80}) {
                finish.Tick+=(sender,args)=> {
                    var dialog=Application.OpenForms.Cast<Form>().FirstOrDefault(d=>d.Text=="Nội dung biển"); if(dialog==null) return; finish.Stop();
                    var table=Children(dialog).OfType<DataGridView>().Single();
                    Check("place-sample-separated-from-record",Convert.ToString(table.Rows[0].Cells[2].Value)=="" && Convert.ToString(table.Rows[0].Cells[3].Value)!="");
                    foreach(DataGridViewRow row in table.Rows) if(Convert.ToString(row.Cells[2].Value)=="") row.Cells[2].Value=Convert.ToString(row.Cells[0].Value).StartsWith("1 / ") ? "HÀ NỘI" : "ĐÀ NẴNG";
                    using(var bitmap=new Bitmap(dialog.Width,dialog.Height)) {dialog.DrawToBitmap(bitmap,dialog.ClientRectangle);bitmap.Save(Path.Combine(output,"cap1-highway-content.png"));}
                    Children(dialog).OfType<Button>().Single(b=>b.Text=="Áp dụng").PerformClick();
                }; finish.Start(); Call(picker,"EditPresentation"); finish.Stop();
            }
            Call(picker,"AcceptSign"); var content=SignContent.Read(picker.SelectedContent);
            Check("two-identical-highway-faces-keep-different-place-names",picker.DialogResult==DialogResult.OK && content.Count==2 && content[0].Values.ContainsValue("HÀ NỘI") && content[1].Values.ContainsValue("ĐÀ NẴNG"));
        }
        using(var picker=new SignPickerForm("I.441a","","")) {
            picker.StartPosition=FormStartPosition.Manual;picker.Location=new Point(-3000,-3000);picker.Show();Application.DoEvents();
            using(var finish=new Timer {Interval=80}) {
                finish.Tick+=(sender,args)=> {
                    var dialog=Application.OpenForms.Cast<Form>().FirstOrDefault(d=>d.Text=="Nội dung biển");if(dialog==null)return;finish.Stop();
                    Check("default-content-editor-hides-advanced-layout",!Children(dialog).OfType<CheckBox>().Single(c=>c.Text.Contains("khung/trụ")).Checked);
                    var table=Children(dialog).OfType<DataGridView>().Single();var apply=Children(dialog).OfType<Button>().Single(b=>b.Text=="Áp dụng");
                    Check("numeric-CAD-text-shown-with-unit",table.Rows.Count==1 && Convert.ToString(table.Rows[0].Cells[1].Value).Contains("(m)") && Convert.ToString(table.Rows[0].Cells[3].Value)=="500 m");
                    table.Rows[0].Cells[2].Value="2 km";apply.PerformClick();Check("numeric-editor-rejects-wrong-unit",dialog.DialogResult!=DialogResult.OK && Children(dialog).OfType<Label>().Any(l=>l.Text.Contains("Đơn vị phải")));
                    table.Rows[0].Cells[2].Value="350,5";
                    using(var bitmap=new Bitmap(dialog.Width,dialog.Height)){dialog.DrawToBitmap(bitmap,dialog.ClientRectangle);bitmap.Save(Path.Combine(output,"parameter-editor.png"));}
                    apply.PerformClick();
                };finish.Start();Call(picker,"EditPresentation");finish.Stop();
            }
            Check("numeric-editor-saves-decimal-and-native-unit",SignContent.ForFace(picker.SelectedContent,0,"I.441a").ContainsValue("350.5 m"));
            Call(picker,"AcceptSign");Check("numeric-edited-sign-can-be-selected",picker.DialogResult==DialogResult.OK);
        }
        using(var picker=new SignPickerForm("P.127a","","")) {
            picker.StartPosition=FormStartPosition.Manual;picker.Location=new Point(-3000,-3000);picker.Show();Application.DoEvents();
            using(var finish=new Timer {Interval=80}) {
                finish.Tick+=(sender,args)=> {
                    var dialog=Application.OpenForms.Cast<Form>().FirstOrDefault(d=>d.Text=="Nội dung biển");if(dialog==null)return;finish.Stop();
                    var table=Children(dialog).OfType<DataGridView>().Single();var first=table.Rows.Cast<DataGridViewRow>().Single(r=>Convert.ToString(r.Cells[1].Value).Contains("Time1"));var last=table.Rows.Cast<DataGridViewRow>().Single(r=>Convert.ToString(r.Cells[1].Value).Contains("Time2"));var apply=Children(dialog).OfType<Button>().Single(b=>b.Text=="Áp dụng");
                    first.Cells[2].Value="24:00";apply.PerformClick();Check("hour-editor-rejects-invalid-hour",dialog.DialogResult!=DialogResult.OK);
                    first.Cells[2].Value="22:15";last.Cells[2].Value="5:30";apply.PerformClick();
                };finish.Start();Call(picker,"EditPresentation");finish.Stop();
            }
            var values=SignContent.ForFace(picker.SelectedContent,0,"P.127a");Check("hour-editor-keeps-two-overnight-values",values.ContainsValue("22:15") && values.ContainsValue("05:30"));
        }
        using (var editor = new BhtPaletteControl())
        using (var host = new Form { ShowInTaskbar = false, StartPosition = FormStartPosition.Manual, Location = new Point(-3000, -3000), ClientSize = new Size(480, 850) })
        {
            host.Controls.Add(editor);
            host.Show();
            var tabs = (TabControl)Field(editor, "_tabs");
            Check("bulk-heading-action-present", Children(editor).OfType<Button>().Any(b => b.Text.Contains("Xoay biển vuông góc")));
            Check("workflow-tab-order", tabs.TabPages[2] == Field(editor, "_tabObjects") && tabs.TabPages[3] == Field(editor, "_tabPhotos"));
            tabs.SelectedTab = (TabPage)Field(editor, "_tabObjects");
            Application.DoEvents();
            Check("empty-editor-clean", !(bool)Call(editor, "IsObjectEditorDirty"));
            ((TextBox)Field(editor, "_oDesc")).Text = "Biển báo đang sửa";
            Check("editing-detects-unsaved-changes", (bool)Call(editor, "IsObjectEditorDirty"));
            Check("unsaved-label-visible", ((Label)Field(editor, "_oMode")).Text.Contains("Chưa lưu"));
            Call(editor, "MarkObjectEditorClean");
            Check("accepted-state-clean", !(bool)Call(editor, "IsObjectEditorDirty"));
            ((TextBox)Field(editor, "_oId")).Text = "OBJ-000001";
            Check("id-edit-detected", (bool)Call(editor, "IsObjectEditorDirty"));
            Call(editor, "MarkObjectEditorClean");
            ((TextBox)Field(editor, "_oChainage")).Text = "Km12+345";
            Check("manual-station-edit-detected", (bool)Call(editor, "IsObjectEditorDirty"));
            Check("new-object-placement-disabled", !((Button)Field(editor, "_placeObjectButton")).Enabled);
            Check("new-object-delete-disabled", !((Button)Field(editor, "_deleteObjectButton")).Enabled);
            var parameter = typeof(BhtPaletteControl).GetMethod("SaveObject", Hidden).GetParameters()[0];
            Check("save-does-not-sync-symbol-by-default", (bool)parameter.DefaultValue == false);
            var draft = (Action)Call(editor, "CaptureObjectDraft");
            Set(editor,"_signLayout","CAP1_9"); Set(editor,"_signGap","0.7");
            var presentationDraft=(Action)Call(editor,"CaptureObjectDraft");
            Call(editor,"ClearObjectEditor"); presentationDraft();
            Check("draft-retains-CAP1",(string)Field(editor,"_signLayout")=="CAP1_9" && ((BhtRecord)Call(editor,"EditorFields")).Get(ObjFields.SignGap)=="0.7");
            Call(editor, "ClearObjectEditor"); draft();
            Check("draft-restores-manual-station-and-id", ((TextBox)Field(editor, "_oChainage")).Text == "Km12+345" && ((TextBox)Field(editor, "_oId")).Text == "OBJ-000001");
            Check("restored-draft-still-unsaved", (bool)Call(editor, "IsObjectEditorDirty"));
            Call(editor, "ClearObjectEditor");
            var document = Autodesk.AutoCAD.ApplicationServices.Core.Application.DocumentManager.MdiActiveDocument;
            using (var tr = document.Database.TransactionManager.StartTransaction())
            {
                BhtStore.Write(tr, document.Database, "OBJ", "UI-001", new BhtRecord().Add(ObjFields.Group, "BIEN_BAO").Add(ObjFields.Desc, "Biển tốc độ").Add(ObjFields.Code, "P.127-80"));
                BhtStore.Write(tr, document.Database, "OBJ", "UI-002", new BhtRecord().Add(ObjFields.Group, "COC_TIEU").Add(ObjFields.Desc, "Cọc tiêu"));
                tr.Commit();
            }
            editor.BindTo(document);
            Call(editor, "LoadObject", "UI-001");
            var automaticFaces=(TextBox)Field(editor,"_oFaces");
            Check("single-sign-face-count-automatic-readonly",automaticFaces.ReadOnly && automaticFaces.Text=="1" && !(bool)Call(editor,"IsObjectEditorDirty"));
            var faceCodes=(ComboBox)Field(editor,"_oFaceCodes");faceCodes.Text="P.127-80; P.127-80";
            Check("same-code-two-physical-faces-counted",automaticFaces.Text=="2");
            faceCodes.Text="P.127-80";
            Check("remove-face-updates-count",automaticFaces.Text=="1");
            faceCodes.Text="";((ComboBox)Field(editor,"_oCode")).Text="R.306-40";
            Check("one-main-code-without-face-list-counted",automaticFaces.Text=="1");
            faceCodes.Text="P.127-80; P.127-80";
            using(var picker=new SignPickerForm("W.207a","",""))
            {
                Call(picker,"AcceptSign"); Call(editor,"ApplyPickedSign",picker);
                Check("single-pick-replaces-stale-multiple-faces",automaticFaces.Text=="1" && faceCodes.Text=="W.207a" && ((ComboBox)Field(editor,"_oCode")).Text=="W.207a");
            }
            Call(editor,"LoadObject","UI-001");
            var library=(SignPickerForm)Call(editor,"CreateSignPicker");
            library.StartPosition=FormStartPosition.Manual;library.Location=new Point(-3000,-3000);library.Show(host);Application.DoEvents();
            Check("picker-modeless-single-instance",!library.Modal && ReferenceEquals(library,Call(editor,"CreateSignPicker")));
            document.Editor.Command("_.ZOOM","_E");Application.DoEvents();editor.RefreshAll();
            Check("CAD-command-with-picker-keeps-editing-target",library.Visible && ReferenceEquals(library,Field(editor,"_signPicker")) && ((TextBox)Field(editor,"_oId")).Text=="UI-001");
            Call(library,"AcceptSign");Application.DoEvents();
            Check("modeless-choice-applies-to-current-draft",Field(editor,"_signPicker")==null && ((ComboBox)Field(editor,"_oCode")).Text=="P.127-80");
            var abandoned=(SignPickerForm)Call(editor,"CreateSignPicker");abandoned.StartPosition=FormStartPosition.Manual;abandoned.Location=new Point(-3000,-3000);abandoned.Show(host);
            Call(editor,"LoadObject","UI-002");
            Check("switch-object-closes-picker-without-applying",abandoned.IsDisposed && Field(editor,"_signPicker")==null && ((TextBox)Field(editor,"_oId")).Text=="UI-002");
            Call(editor,"LoadObject","UI-001");
            var detached=(SignPickerForm)Call(editor,"CreateSignPicker");detached.StartPosition=FormStartPosition.Manual;detached.Location=new Point(-3000,-3000);detached.Show(host);
            editor.Unbind(false);
            Check("unbind-closes-modeless-picker",detached.IsDisposed && Field(editor,"_signPicker")==null);
            editor.BindTo(document);Call(editor,"LoadObject","UI-001");
            ((TextBox)Field(editor, "_oNote")).Text = "Nội dung chưa lưu";
            editor.RefreshAll();
            Check("refresh-preserves-unsaved-note", ((TextBox)Field(editor, "_oNote")).Text == "Nội dung chưa lưu" && (bool)Call(editor, "IsObjectEditorDirty"));
            ((TextBox)Field(editor, "_objSearch")).Text = "toc do";
            var list = (ListView)Field(editor, "_objList");
            Check("accent-insensitive-object-search", list.Items.Count == 1 && (string)list.Items[0].Tag == "UI-001");
            Check("filter-preserves-editor", ((TextBox)Field(editor, "_oNote")).Text == "Nội dung chưa lưu");
            Check("group-label-keeps-stored-code", ((ComboBox)Field(editor, "_oGroup")).Text == "Biển báo" && ((BhtRecord)Call(editor, "EditorFields")).Get(ObjFields.Group) == "BIEN_BAO");
            editor.BindTo(null);
            Check("unbound-editor-cleared", ((TextBox)Field(editor, "_oNote")).Text == "");
            editor.BindTo(document);
            Check("drawing-draft-restored", ((TextBox)Field(editor, "_oNote")).Text == "Nội dung chưa lưu" && ((TextBox)Field(editor, "_oId")).Text == "UI-001" && (bool)Call(editor, "IsObjectEditorDirty"));
            Check("redundant-object-zoom-button-removed", !Children((TabPage)Field(editor, "_tabObjects")).OfType<Button>().Any(b => b.Text == "Thu phóng"));
            var supportHint = (Label)Field(editor, "_oSupportHint");
            ((ComboBox)Field(editor, "_oGroup")).SelectedIndex = 4;
            ((TextBox)Field(editor, "_oPoles")).Text = "2";
            var objectPoints = (ListBox)Field(editor, "_oPoints"); objectPoints.Items.Clear(); objectPoints.Items.Add("FOOT-1 | Chân 1"); Call(editor, "UpdateObjectEditorState");
            Check("two-supports-one-point-shows-missing-foot", supportHint.Visible && supportHint.Text.Contains("Thiếu 1 điểm chân RTK"));
            objectPoints.Items.Add("FOOT-2 | Chân 2"); Call(editor, "UpdateObjectEditorState");
            Check("second-measured-point-clears-foot-warning", !supportHint.Visible && supportHint.Text == "");
            ((TextBox)Field(editor, "_oPoles")).Text = "1"; objectPoints.Items.RemoveAt(1); Call(editor, "UpdateObjectEditorState");
            Check("one-support-one-point-needs-no-warning", !supportHint.Visible);
            Call(editor, "LoadObject", "UI-001");
            ((TextBox)Field(editor, "_oNote")).Text = "Nội dung chưa lưu";
            ((TextBox)Field(editor, "_objSearch")).Text = "";
            Application.DoEvents();
            var status = (Label)Field(editor, "_status");
            var itemBounds = list.Items[1].Bounds;
            var mouse = typeof(Control).GetMethod("OnMouseDoubleClick", Hidden);
            // The clicked row can differ from the dirty editor after a cancelled selection change.
            status.Text = "Before double click";
            mouse.Invoke(list, new object[] { new MouseEventArgs(MouseButtons.Left, 2, itemBounds.Left + 5, itemBounds.Top + 5, 0) });
            Check("double-click-zooms-clicked-record", status.Text == "Hồ sơ chưa có điểm RTK hợp lệ.");
            Check("double-click-preserves-unsaved-editor", ((TextBox)Field(editor, "_oId")).Text == "UI-001" && ((TextBox)Field(editor, "_oNote")).Text == "Nội dung chưa lưu" && (bool)Call(editor, "IsObjectEditorDirty"));
            status.Text = "Blank area";
            mouse.Invoke(list, new object[] { new MouseEventArgs(MouseButtons.Left, 2, 5, list.ClientSize.Height - 5, 0) });
            Check("double-click-blank-area-does-nothing", status.Text == "Blank area");
            mouse.Invoke(list, new object[] { new MouseEventArgs(MouseButtons.Right, 2, itemBounds.Left + 5, itemBounds.Top + 5, 0) });
            Check("right-double-click-does-nothing", status.Text == "Blank area");
            var fill = (CheckBox)Field(editor, "_oSignFill");
            var api = new LispApi();
            Check("fill-API-on-confirmed", api.Call("bht:api-sign-fill", "1").Ok);
            Set(editor, "_lispOk", true);
            Call(editor, "RefreshSignFill");
            Check("fill-reads-confirmed-on", fill.Checked);
            int generation = (int)Field(editor, "_lispGeneration");
            // Delay the completion boundary while refresh reads the old drawing state.
            Set(editor, "_pendingSignFill", (bool?)false); Set(editor, "_lispRunning", true);
            editor.RefreshAll(); editor.RefreshAll();
            Check("fill-refresh-does-not-recheck-pending-off", !fill.Checked && !fill.Enabled);
            fill.Checked = true;
            Check("fill-second-change-rejected-while-pending", !fill.Checked);
            var off = api.Call("bht:api-sign-fill", "0");
            Check("fill-API-off-confirmed", off.Ok);
            Set(editor, "_lispRunning", false);
            Call(editor, "CompleteSignFill", document, generation, off);
            editor.RefreshAll();
            Check("fill-off-persists-after-completion-and-refresh", !fill.Checked && fill.Enabled && Field(editor, "_pendingSignFill") == null);
            Set(editor, "_pendingSignFill", (bool?)true); Set(editor, "_lispRunning", true);
            editor.RefreshAll();
            Check("fill-refresh-keeps-pending-on", fill.Checked && !fill.Enabled);
            Set(editor, "_lispRunning", false);
            Call(editor, "CompleteSignFill", document, generation, LispReply.FromStrings(new[] { "LOI", "Rejected fill operation" }));
            Check("fill-failure-restores-confirmed-off-and-reports", !fill.Checked && fill.Enabled && status.Text.Contains("Rejected fill operation"));
            Set(editor, "_pendingSignFill", (bool?)true); Set(editor, "_lispRunning", true);
            Call(editor, "CompleteSignFill", document, generation - 1, off);
            Check("fill-old-completion-ignored", (bool?)Field(editor, "_pendingSignFill") == true && (bool)Field(editor, "_lispRunning"));
            editor.Unbind();
            Check("fill-unbind-clears-pending-and-disables", Field(editor, "_pendingSignFill") == null && !fill.Enabled);
            editor.BindTo(document);
            Set(editor, "_lispOk", true);
            Call(editor, "RefreshSignScale");
            var scaleButton = (Button)Field(editor, "_signScaleButton");
            Check("scale-button-enabled-with-ready-drawing", scaleButton.Enabled);
            Check("fill-API-on-after-off-confirmed", api.Call("bht:api-sign-fill", "1").Ok);
            Call(editor, "RefreshSignFill");
            Check("fill-rebind-reads-drawing-and-enables", fill.Checked && fill.Enabled);
            fill.Checked = false;
            Check("fill-busy-rejection-keeps-confirmed-state", fill.Checked && !((bool?)Field(editor, "_pendingSignFill")).HasValue && status.Text.Contains("Chưa đổi tô nền"));
            Set(editor, "_lispRunning", true); Call(editor, "UpdateSignFillAvailability");
            Check("fill-disabled-during-other-Lisp-operation", !fill.Enabled);
            Check("scale-disabled-during-other-Lisp-operation", !scaleButton.Enabled);
            Set(editor, "_lispRunning", false); Call(editor, "UpdateSignFillAvailability");
            var rtkScale = (Button)Field(editor, "_rtkScaleButton");
            var rtkUpdate = (Button)Field(editor, "_rtkUpdateLabelsButton");
            Check("RTK-independent-actions-enabled", rtkScale.Enabled && rtkUpdate.Enabled && rtkScale.Text == "Tỷ lệ ký hiệu và nhãn RTK…" && rtkUpdate.Text == "Cập nhật nhãn RTK");
            Set(editor, "_lispRunning", true); Call(editor, "UpdateSignFillAvailability");
            Check("RTK-actions-disabled-while-busy", !rtkScale.Enabled && !rtkUpdate.Enabled);
            Set(editor, "_lispRunning", false); Call(editor, "UpdateSignFillAvailability");
            Check("RTK-scale-registered-through-acedInvoke", api.Call("bht:api-rtk-scale", "2", "0.75").Ok);
            tabs.SelectedTab = (TabPage)Field(editor, "_tabPoints");
            var points = Enumerable.Range(0, 70).Select(n => new SurveyPoint { Id = "UI-RTK-" + n.ToString("000"), Name = n.ToString(), Description = "Điểm thử", Class = "CHUA_XAC_DINH" }).ToList();
            Set(editor, "_points", points); Call(editor, "FillPointList"); Application.DoEvents();
            var pointList = (ListView)Field(editor, "_ptList");
            Set(editor, "_suppressSel", true); pointList.Items[35].Selected = true; pointList.Items[36].Selected = true; Set(editor, "_suppressSel", false);
            pointList.TopItem = pointList.Items[33];
            string pointTop = ((SurveyPoint)pointList.TopItem.Tag).Id;
            Call(editor, "FillPointList"); Application.DoEvents();
            Check("RTK-refresh-keeps-multiple-selection", pointList.SelectedItems.Count == 2 && pointList.SelectedItems.Cast<ListViewItem>().All(i => ((SurveyPoint)i.Tag).Id == "UI-RTK-035" || ((SurveyPoint)i.Tag).Id == "UI-RTK-036"));
            Check("RTK-refresh-keeps-list-top", ((SurveyPoint)pointList.TopItem.Tag).Id == pointTop);
            ((TextBox)Field(editor, "_ptSearch")).Text = "UI-RTK-0"; Application.DoEvents();
            Check("RTK-filter-keeps-visible-selection-and-top", pointList.SelectedItems.Count == 2 && ((SurveyPoint)pointList.TopItem.Tag).Id == pointTop);
            foreach (var size in new[] { new Size(340, 600), new Size(340, 850), new Size(480, 850) })
            {
                host.ClientSize = size; Application.DoEvents();
                foreach (var button in new[] { rtkScale, rtkUpdate })
                    Check("RTK-action-visible-" + size.Width + "-" + size.Height + "-" + button.Text, editor.ClientRectangle.Contains(editor.PointToClient(button.PointToScreen(new Point(button.Width - 1, button.Height - 1)))));
                using (var bitmap = new Bitmap(editor.Width, editor.Height)) { editor.DrawToBitmap(bitmap, editor.ClientRectangle); bitmap.Save(Path.Combine(output, "RTK-" + size.Width + "-" + size.Height + ".png")); }
            }
            editor.Unbind(); Check("RTK-actions-disabled-without-drawing", !rtkScale.Enabled && !rtkUpdate.Enabled);
            editor.BindTo(document); Set(editor, "_lispOk", true); Call(editor, "UpdateSignFillAvailability");
            tabs.SelectedTab = (TabPage)Field(editor, "_tabObjects"); host.ClientSize = new Size(480, 850); Application.DoEvents();
            using (var tr = document.Database.TransactionManager.StartTransaction())
            {
                for (int n = 0; n < 70; n++)
                    BhtStore.Write(tr, document.Database, "OBJ", "UI-L" + n.ToString("000"), new BhtRecord().Add(ObjFields.Group, "BIEN_BAO").Add(ObjFields.Code, "P.127-80").Add(ObjFields.Desc, "Biển tốc độ " + n));
                tr.Commit();
            }
            Call(editor, "MarkObjectEditorClean"); Call(editor, "RefreshObjects");
            Call(editor, "SelectObjectInList", "UI-L035");
            var deleteButton=(Button)Field(editor,"_deleteObjectButton");
            Check("saved-object-delete-enabled",deleteButton.Enabled);
            Set(editor,"_lispRunning",true);Call(editor,"UpdateObjectEditorState");
            Check("running-command-delete-disabled",!deleteButton.Enabled);
            Set(editor,"_lispRunning",false);Call(editor,"UpdateObjectEditorState");
            Check("delete-enabled-after-command",deleteButton.Enabled);
            Check("delete-button-outside-scroll-form",deleteButton.Parent!=Field(editor,"_objectForm"));
            list.TopItem = list.Items.Cast<ListViewItem>().Single(item => (string)item.Tag == "UI-L033");
            string topBeforeSave = list.TopItem.Tag as string;
            ((TextBox)Field(editor, "_oNote")).Text = "Lưu ở giữa danh sách";
            using (var tr = document.Database.TransactionManager.StartTransaction())
            {
                BhtStore.Write(tr, document.Database, "OBJ", "UI-L035", new BhtRecord().Add(ObjFields.Group, "BIEN_BAO").Add(ObjFields.Code, "P.127-80").Add(ObjFields.Desc, "Biển tốc độ 35").Add(ObjFields.Note, "Lưu ở giữa danh sách"));
                tr.Commit();
            }
            Call(editor, "MarkObjectEditorClean"); editor.RefreshAll();
            Application.DoEvents();
            Check("saved-record-refresh-preserves-object-list-top", (string)list.TopItem.Tag == topBeforeSave);
            editor.RefreshAll(); Application.DoEvents();
            Check("refresh-preserves-object-list-top", (string)list.TopItem.Tag == topBeforeSave);
            ((TextBox)Field(editor, "_objSearch")).Text = "UI-L0"; Application.DoEvents();
            Check("filter-preserves-top-record-when-visible", (string)list.TopItem.Tag == topBeforeSave);
            ((TextBox)Field(editor, "_objSearch")).Text = "";
            foreach (var size in new[] { new Size(340, 600), new Size(340, 850), new Size(480, 850) })
            {
                int width = size.Width;
                host.ClientSize = size;
                Application.DoEvents();
                Call(editor, "ClearObjectEditor");
                var form = (TableLayoutPanel)Field(editor, "_objectForm");
                var info = (TextBox)Field(editor, "_oInfo");
                info.Focus(); form.ScrollControlIntoView(info);
                Application.DoEvents();
                Call(editor, "NewObjectFromPoints", new System.Collections.Generic.List<string> { "UI-NEW-POINT" });
                Application.DoEvents();
                Check("new-record-at-top-" + width + "-" + size.Height, form.AutoScrollPosition.Y == 0 && ((ComboBox)Field(editor, "_oGroup")).Focused);
                var group = (ComboBox)Field(editor, "_oGroup");
                group.SelectedIndex = 4;
                ((TextBox)Field(editor, "_oDesc")).Text = "Bảng quảng cáo cửa hàng";
                Application.DoEvents();
                Check("advertising-name-label-" + width, ((Label)Field(editor, "_objectNameLabel")).Text == "Tên trên bảng");
                Check("group-change-stays-at-top-" + width, form.AutoScrollPosition.Y == 0);
                Call(editor, "MarkObjectEditorClean");
                ((TextBox)Field(editor, "_oNote")).Focus();
                int beforeEdit = form.AutoScrollPosition.Y;
                ((TextBox)Field(editor, "_oNote")).Text = "Ghi chú chưa lưu";
                Application.DoEvents();
                Check("dirty-status-does-not-jump-" + width, form.AutoScrollPosition.Y == beforeEdit);
                                group.SelectedIndex=group.Items.Cast<object>().Select((item,index)=>new{item,index}).Single(x=>x.item.ToString()=="Đèn tín hiệu").index;
                Check("signal-group-code-"+width,((BhtRecord)Call(editor,"EditorFields")).Get(ObjFields.Group)=="DEN_TH");
                Check("signal-picker-visible-"+width,((Button)Field(editor,"_lightButton")).Visible);
                Check("signal-types-have-shipped-dwg-"+width,LightModels.ForGroup("DEN_TH").Length==2 && LightModels.ForGroup("DEN_TH").All(m=>File.Exists(Path.Combine(CustomDwgBlock.LightFolder(),m[0]+".dwg"))));
                group.SelectedIndex=group.Items.Cast<object>().Select((item,index)=>new{item,index}).Single(x=>x.item.ToString()=="Đèn chiếu sáng").index;
                Check("lighting-group-code-"+width,((BhtRecord)Call(editor,"EditorFields")).Get(ObjFields.Group)=="DEN_CS");
                Check("lighting-types-have-shipped-dwg-"+width,LightModels.ForGroup("DEN_CS").Length==5 && LightModels.ForGroup("DEN_CS").All(m=>File.Exists(Path.Combine(CustomDwgBlock.LightFolder(),m[0]+".dwg"))));
                group.SelectedIndex=group.Items.Cast<object>().Select((item,index)=>new{item,index}).Single(x=>x.item.ToString()=="Khác").index;
                Check("other-hides-light-picker-"+width,!((Button)Field(editor,"_lightButton")).Visible);
                Check("other-name-label-" + width, ((Label)Field(editor, "_objectNameLabel")).Text == "Tên trên bảng");
                Call(editor, "MarkObjectEditorClean");
                Call(editor, "LoadObject", "UI-001");
                form.ScrollControlIntoView(info);
                Application.DoEvents();
                int beforeRefresh = form.AutoScrollPosition.Y;
                editor.RefreshAll(); Application.DoEvents();
                Check("clean-refresh-keeps-scroll-" + width, form.AutoScrollPosition.Y == beforeRefresh);
                using (var picker = new SignPickerForm("S.509a@4.75", "", "W.239a; S.509a@4.75"))
                {
                    typeof(SignPickerForm).GetMethod("AcceptSign", Hidden).Invoke(picker, null);
                    Check("picker-confirmed-" + width, picker.SelectedCode == "W.239a");
                    int beforePicker = form.AutoScrollPosition.Y;
                    Call(editor, "KeepObjectScroll", (Action)(() => {
                        ((ComboBox)Field(editor, "_oGroup")).Focus();
                        Call(editor, "ApplyPickedSign", picker);
                        Application.DoEvents();
                    }));
                    Application.DoEvents();
                    Check("picker-return-keeps-form-scroll-" + width, form.AutoScrollPosition.Y == beforePicker);
                    Check("picker-return-keeps-face-codes-" + width, ((ComboBox)Field(editor, "_oFaceCodes")).Text.Contains("S.509a@4.75"));
                }
                int beforeScale = form.AutoScrollPosition.Y;
                string draftBeforeScale = ((TextBox)Field(editor, "_oNote")).Text;
                bool dirtyBeforeScale = (bool)Call(editor, "IsObjectEditorDirty");
                using (var closeScale = new Timer { Interval = 50 })
                {
                    closeScale.Tick += (s, e) => {
                        var dialog = Application.OpenForms.Cast<Form>().OfType<SignScaleForm>().FirstOrDefault();
                        if (dialog == null) return;
                        closeScale.Stop(); dialog.DialogResult = DialogResult.Cancel; dialog.Close();
                    };
                    closeScale.Start(); Call(editor, "ChooseSignScale"); closeScale.Stop();
                }
                Application.DoEvents();
                Check("scale-dialog-keeps-draft-and-scroll-" + width, form.AutoScrollPosition.Y == beforeScale && ((TextBox)Field(editor, "_oNote")).Text == draftBeforeScale && (bool)Call(editor, "IsObjectEditorDirty") == dirtyBeforeScale);
                Call(editor, "ClearObjectEditor");
                Call(editor, "NewObjectFromPoints", new System.Collections.Generic.List<string> { "UI-NEW-POINT" });
                group.SelectedIndex = 4;
                ((TextBox)Field(editor, "_oDesc")).Text = "Cửa hàng vật liệu xây dựng";
                Application.DoEvents();
                foreach (string name in new[] { "_saveObjectButton", "_placeObjectButton", "_insertObjectButton", "_signScaleButton" })
                {
                    var button = (Button)Field(editor, name);
                    Check("action-within-panel-" + width + "-" + name, button.Right <= button.Parent.ClientSize.Width && button.Width > 90 && button.Height >= 30);
                }
                var actionGrid = (TableLayoutPanel)scaleButton.Parent;
                Check("grouped-symbol-actions-" + width, actionGrid.GetRow(scaleButton) == 1 && actionGrid.GetRow((Button)Field(editor, "_placeObjectButton")) == 2 && actionGrid.GetRow((Button)Field(editor, "_insertObjectButton")) == 2);
                Check("RTK-actions-next-to-points-" + width, Children(form).OfType<Button>().Any(b => b.Text == "Thêm điểm CAD…") && Children(form).OfType<Button>().Any(b => b.Text == "Gỡ điểm chọn"));
                Call(editor, "MarkObjectEditorClean"); Call(editor, "SelectObjectInList", "UI-001");
                form.AutoScrollPosition = Point.Empty; Application.DoEvents();
                using (var bitmap = new Bitmap(editor.Width, editor.Height))
                {
                    editor.DrawToBitmap(bitmap, editor.ClientRectangle);
                    bitmap.Save(Path.Combine(output, "objects-" + width + "-" + size.Height + ".png"));
                }
            }
        }
        double parsed;
        using (var scale = new RtkScaleForm("2", "0,75"))
        {
            scale.StartPosition = FormStartPosition.Manual; scale.Location = new Point(-3000, -3000);
            scale.Show(); Application.DoEvents(); Call(scale, "AcceptScale");
            Check("RTK-dialog-independent-comma-values", scale.DialogResult == DialogResult.OK && scale.SymbolScale == "2" && scale.LabelScale == "0.75");
        }
        using (var scale = new RtkScaleForm("1", "1"))
        {
            scale.StartPosition = FormStartPosition.Manual; scale.Location = new Point(-3000, -3000);
            scale.Show(); Application.DoEvents();
            ((ComboBox)Field(scale, "label")).Text = "0"; Call(scale, "AcceptScale");
            Check("RTK-dialog-invalid-stays-open", scale.DialogResult == DialogResult.None && ((Label)Field(scale, "error")).Text.Length > 0 && scale.LabelScale == null);
            Children(scale).OfType<Button>().Single(b => b.Text == "Về chuẩn 1:1").PerformClick(); Application.DoEvents();
            Check("RTK-dialog-reset-both-values", ((ComboBox)Field(scale, "symbol")).Text == "1" && ((ComboBox)Field(scale, "label")).Text == "1");
            foreach (var button in Children(scale).OfType<Button>())
                Check("RTK-dialog-visible-" + button.Text, scale.ClientRectangle.Contains(scale.PointToClient(button.PointToScreen(new Point(button.Width - 1, button.Height - 1)))));
            using (var bitmap = new Bitmap(scale.Width, scale.Height)) { scale.DrawToBitmap(bitmap, scale.ClientRectangle); bitmap.Save(Path.Combine(output, "RTK-scale.png")); }
            Children(scale).OfType<Button>().Single(b => b.Text == "Hủy").PerformClick();
            Check("RTK-dialog-cancel-no-values", scale.DialogResult == DialogResult.Cancel && scale.SymbolScale == null && scale.LabelScale == null);
        }
        foreach (string valid in new[] { "0.01", "0,75", "1", "2.125", "100" })
            Check("scale-input-valid-" + valid, SignScaleForm.TryScale(valid, out parsed));
        foreach (string invalid in new[] { "", "0", "-1", "0.001", "101", "1.0001", "NaN", "Infinity", "1e2", "1:100" })
            Check("scale-input-invalid-" + invalid, !SignScaleForm.TryScale(invalid, out parsed));
        using (var scale = new SignScaleForm("2", "0.75"))
        {
            scale.StartPosition = FormStartPosition.Manual; scale.Location = new Point(-3000, -3000);
            scale.Show(); Application.DoEvents();
            Call(scale, "AcceptScale");
            Check("scale-dialog-independent-normalized-values", scale.DialogResult == DialogResult.OK && scale.SymbolScale == "2" && scale.LabelScale == "0.75");
        }
        using (var scale = new SignScaleForm("1", "1"))
        {
            scale.StartPosition = FormStartPosition.Manual; scale.Location = new Point(-3000, -3000);
            scale.Show(); Application.DoEvents();
            ((ComboBox)Field(scale, "label")).Text = "0"; Call(scale, "AcceptScale");
            Check("scale-dialog-invalid-stays-open", scale.DialogResult == DialogResult.None && ((Label)Field(scale, "error")).Text.Length > 0 && scale.LabelScale == null);
            Children(scale).OfType<Button>().Single(b => b.Text == "Về chuẩn 1:1").PerformClick();
            Check("scale-dialog-reset-both-controls", ((ComboBox)Field(scale, "symbol")).Text == "1" && ((ComboBox)Field(scale, "label")).Text == "1");
            foreach (var button in Children(scale).OfType<Button>())
                Check("scale-dialog-visible-" + button.Text, scale.ClientRectangle.Contains(scale.PointToClient(button.PointToScreen(new Point(button.Width - 1, button.Height - 1)))));
            using (var bitmap = new Bitmap(scale.Width, scale.Height)) { scale.DrawToBitmap(bitmap, scale.ClientRectangle); bitmap.Save(Path.Combine(output, "sign-scale.png")); }
            Children(scale).OfType<Button>().Single(b => b.Text == "Hủy").PerformClick();
            Check("scale-dialog-cancel-no-values", scale.DialogResult == DialogResult.Cancel && scale.SymbolScale == null && scale.LabelScale == null);
        }
    }
}

