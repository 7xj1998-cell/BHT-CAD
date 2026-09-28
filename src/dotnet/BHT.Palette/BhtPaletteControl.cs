using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using BHT.Bridge;
using BHT.Core;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Application;
using Font = System.Drawing.Font;

namespace BHT.Palette
{
    /// <summary>
    /// Noi dung palette (WinForms, dung bang code - khong designer / XAML).
    /// Nguyen tac: moi du lieu doc tu DWG qua BhtDataService; ghi qua AcadDispatcher
    /// (khoa tai lieu, tu choi khi dang co lenh); thuat toan cua Lisp goi qua bht:api-*.
    /// </summary>
    public partial class BhtPaletteControl : UserControl
    {
        private Document _doc;
        private BhtDataService _svc;
        private readonly Timer _selTimer = new Timer();
        private readonly Timer _probeTimer = new Timer();
        private bool _suppressSel;
        private DateTime _suppressUntil = DateTime.MinValue;
        private readonly CommandWatcher _watcher = new CommandWatcher();
        private bool _lispOk;
        private string _lispMsg = "chưa kiểm tra";

        private readonly TabControl _tabs = new TabControl();
        private readonly Label _status = new Label();
        private readonly Label _docLabel = new Label();

        public BhtPaletteControl()
        {
            Font = new Font("Segoe UI", 9f);
            Dock = DockStyle.Fill;
            _docLabel.Dock = DockStyle.Top; _docLabel.Height = 20; _docLabel.Padding = new Padding(4, 3, 0, 0);
            _docLabel.BackColor = Color.FromArgb(45, 45, 48); _docLabel.ForeColor = Color.White;
            _status.Dock = DockStyle.Bottom; _status.Height = 52; _status.Margin = new Padding(4);
            _status.Padding = new Padding(7, 5, 7, 5); _status.BorderStyle = BorderStyle.FixedSingle;
            _status.AutoEllipsis = true; _status.TabStop = false;
            _tabs.Dock = DockStyle.Fill; _tabs.Multiline = false;
            _tabs.TabPages.Add(BuildOverviewTab());
            _tabs.TabPages.Add(BuildPointsTab());
            _tabs.TabPages.Add(BuildPhotosTab());
            _tabs.TabPages.Add(BuildObjectsTab());
            _tabs.TabPages.Add(BuildRoutesTab());
            Controls.Add(_tabs);
            Controls.Add(_docLabel);
            Controls.Add(_status);
            PaletteTheme.Apply(this, _tabs, _docLabel, _status);
            _selTimer.Interval = 300;
            _selTimer.Tick += OnSelTimer;
            _probeTimer.Interval = 300;
            _probeTimer.Tick += (s, e) => { _probeTimer.Stop(); ProbeLisp(); };
            _watcher.Finished += OnCommandFinished;
            Status("Sẵn sàng.");
        }

        // ------------------------------------------------------------------ gan tai lieu

        public void BindTo(Document doc)
        {
            if (doc == _doc && _svc != null) { RefreshAll(); return; }
            Unbind();
            _doc = doc;
            if (doc == null) { _docLabel.Text = "(không có bản vẽ)"; ClearAll(); return; }
            try
            {
                _svc = new BhtDataService(doc.Database, CurrentDwgPrefix, true);
                doc.ImpliedSelectionChanged += OnImpliedSelectionChanged;
                _docLabel.Text = "Bản vẽ: " + SafeName(doc);
                _lispOk = false; _lispMsg = "chưa kiểm tra";
                RefreshAll();
                ProbeLisp();
            }
            catch (Exception ex) { Status("Lỗi gắn bản vẽ: " + ex.Message); }
        }

        public void Unbind()
        {
            _selTimer.Stop();
            _probeTimer.Stop();
            _watcher.Detach();
            if (_doc != null) { try { _doc.ImpliedSelectionChanged -= OnImpliedSelectionChanged; } catch { } }
            if (_svc != null) { _svc.Dispose(); _svc = null; }
            _doc = null;
        }

        public void DocumentClosing(Document doc)
        {
            if (doc != null && doc == _doc) { Unbind(); ClearAll(); _docLabel.Text = "(bản vẽ đã đóng)"; }
        }

        private static string SafeName(Document d) { try { return System.IO.Path.GetFileName(d.Name); } catch { return "?"; } }

        private string CurrentDwgPrefix()
        {
            try
            {
                if (_doc != null && _doc == AcApp.DocumentManager.MdiActiveDocument)
                    return Convert.ToString(AcApp.GetSystemVariable("DWGPREFIX"));
                if (_doc != null && System.IO.Path.IsPathRooted(_doc.Name))
                    return System.IO.Path.GetDirectoryName(_doc.Name) + "\\";
            }
            catch { }
            return "";
        }

        private void ClearAll()
        {
            _ovText.Text = "";
            _ptList.Items.Clear(); _ptDetail.Text = "";
            _phList.Items.Clear(); ShowImage(null); _phInfo.Text = "";
            _objList.Items.Clear(); ClearObjectEditor();
        }

        public void RefreshAll()
        {
            RefreshAll(true);
        }

        private void RefreshAll(bool reportStatus)
        {
            if (_svc == null) return;
            try
            {
                RefreshOverview();
                RefreshPoints();
                RefreshPhotos();
                RefreshObjects();
                if (reportStatus) Status("Đã đọc dữ liệu từ bản vẽ.");
            }
            catch (Exception ex) { Status("Lỗi đọc dữ liệu: " + ex.Message); }
        }

        private void ProbeLisp()
        {
            if (_doc == null) return;
            string busy;
            if (AcadDispatcher.IsBusy(_doc, out busy))
            {
                _lispMsg = "đang chờ AutoCAD kết thúc lệnh để kiểm tra lõi Lisp";
                _probeTimer.Stop();
                _probeTimer.Start();
                return;
            }
            AcadDispatcher.RunLisp("bht:api-version", new string[0], r => UI(() =>
            {
                _lispOk = r.Ok && r.Values.Count > 1 && BhtVersion.LispCompatible(r.Values[0], r.Values[1]);
                string loaded = r.Values.Count > 0 ? r.Values[0] : "không rõ";
                _lispMsg = _lispOk
                    ? "BHT Lisp " + loaded + " đã nạp"
                    : "Plugin " + BhtVersion.Version + " / Lisp " + loaded + " không cùng phiên bản. Đóng tất cả AutoCAD rồi cài lại BHT " + BhtVersion.Version + ".";
                Status(_lispMsg);
                RefreshOverview();
            }));
        }

        // ------------------------------------------------------------------ tien ich

        protected void Status(string s)
        {
            _status.Text = s ?? "";
            _status.BackColor = PaletteTheme.StatusBack(s);
        }

        protected void ShowReportDialog(string title, string content)
        {
            using (var dialog = new Form())
            {
                dialog.Text = "BHT " + BhtVersion.Version + " — " + (title ?? "Báo cáo");
                dialog.StartPosition = FormStartPosition.CenterScreen;
                dialog.Size = new Size(860, 620);
                dialog.MinimumSize = new Size(620, 420);
                dialog.ShowIcon = false;
                var body = new RichTextBox
                {
                    Dock = DockStyle.Fill,
                    ReadOnly = true,
                    DetectUrls = false,
                    WordWrap = false,
                    Font = new Font("Consolas", 10f),
                    BackColor = Color.White,
                    Text = content ?? ""
                };
                var buttons = new FlowLayoutPanel
                {
                    Dock = DockStyle.Bottom,
                    Height = 42,
                    FlowDirection = System.Windows.Forms.FlowDirection.RightToLeft,
                    Padding = new Padding(5)
                };
                var close = Btn("Đóng", (s, e) => dialog.Close());
                var copy = Btn("Sao chép", (s, e) =>
                {
                    try { Clipboard.SetText(body.Text ?? ""); Status("Đã sao chép nội dung báo cáo."); }
                    catch (Exception ex) { Status("Không sao chép được: " + ex.Message); }
                });
                close.Width = 90; copy.Width = 100;
                buttons.Controls.Add(close); buttons.Controls.Add(copy);
                dialog.Controls.Add(body); dialog.Controls.Add(buttons);
                PaletteTheme.ApplyDialog(dialog);
                dialog.ShowDialog();
            }
        }

        /// <summary>Dua viec ve luong giao dien, sau khi callback AutoCAD ket thuc (tranh tai nhap).</summary>
        protected void UI(Action a)
        {
            if (IsDisposed) return;
            try
            {
                if (IsHandleCreated) BeginInvoke(a); else a();
            }
            catch (Exception ex) { Status("Lỗi: " + ex.Message); }
        }

        private bool NeedDoc()
        {
            if (_doc == null || _svc == null) { Status("Không có bản vẽ đang mở."); return false; }
            if (_doc != AcApp.DocumentManager.MdiActiveDocument) { BindTo(AcApp.DocumentManager.MdiActiveDocument); }
            return _svc != null;
        }

        private bool NeedLisp()
        {
            if (!_lispOk) { Status("Lõi Lisp BHT " + BhtVersion.Version + " chưa sẵn sàng. " + _lispMsg); ProbeLisp(); return false; }
            return true;
        }

        protected static Button Btn(string text, EventHandler h)
        {
            var b = new Button { Text = text, AutoSize = true, Margin = new Padding(2) };
            b.Click += h;
            return b;
        }

        protected static FlowLayoutPanel Flow()
        {
            return new FlowLayoutPanel { Dock = DockStyle.Top, AutoSize = true, WrapContents = true, Padding = new Padding(2) };
        }

        /// <summary>Goi ham Lisp; hien ket qua; lam moi du lieu khi xong (ket qua that tu Lisp, khong gia dinh).</summary>
        private void CallLisp(string fn, string[] args, string label, Action<LispReply> after)
        {
            if (!NeedDoc() || !NeedLisp()) return;
            Status(label + ": đang chạy ...");
            AcadDispatcher.RunLisp(fn, args, r => UI(() =>
            {
                if (r.Ok) Status(label + ": xong. " + string.Join("; ", r.Values.Take(8).ToArray()));
                else Status(label + ": LỖI - " + r.Error);
                if (after != null) after(r);
                RefreshAll(false);
            }));
        }

        private void SendCmd(string cmd)
        {
            if (!NeedDoc() || !NeedLisp()) return;
            Action send = () =>
            {
                var r = AcadDispatcher.SendCommand(_doc, cmd, _watcher);
                Status(r.Ok ? "Đang chạy " + cmd + "… Kết quả sẽ hiện tại đây." : r.ToString());
            };
            // Bo cac dong thong bao con lai tu lenh truoc, roi moi gui lenh moi.
            AcadDispatcher.RunLisp("bht:api-messages", new[] { "DRAIN" }, r => UI(send));
        }

        private void OnCommandFinished(string cmd, string state)
        {
            UI(() =>
            {
                if (!_lispOk)
                {
                    RefreshAll(false);
                    Status("Lệnh " + cmd + (state == "KET_THUC" ? " đã kết thúc." : state == "HUY" ? " đã bị hủy." : " bị lỗi."));
                    return;
                }
                AcadDispatcher.RunLisp("bht:api-messages", new[] { "DRAIN" }, r => UI(() =>
                {
                    RefreshAll(false);
                    string head = "Lệnh " + cmd + (state == "KET_THUC" ? " đã kết thúc." : state == "HUY" ? " đã bị hủy." : " bị lỗi.");
                    string detail = r.Ok && r.Values.Count > 0 ? string.Join("\r\n", r.Values.ToArray()) : "";
                    string upper = (cmd ?? "").ToUpperInvariant();
                    bool report = upper.Contains("BHTKT") || upper.Contains("BHTTRANGTHAI")
                        || upper.Contains("BHTXUAT") || detail.Length > 220 || r.Values.Count > 3;
                    Status(detail == "" ? head : head + " " + r.Values.Count + " dòng kết quả.");
                    if (report && detail != "") ShowReportDialog(head, detail);
                }));
            });
        }

        // ------------------------------------------------------------------ dong bo lua chon

        private void OnImpliedSelectionChanged(object sender, EventArgs e)
        {
            if (_suppressSel || DateTime.Now < _suppressUntil) return;
            _selTimer.Stop(); _selTimer.Start(); // debounce
        }

        private void OnSelTimer(object sender, EventArgs e)
        {
            _selTimer.Stop();
            if (_doc == null || _svc == null || _suppressSel) return;
            try
            {
                var res = _doc.Editor.SelectImplied();
                if (res.Status != PromptStatus.OK || res.Value == null || res.Value.Count == 0) return;
                KeyValuePair<string, string>? hit = null;
                using (var tr = _doc.Database.TransactionManager.StartOpenCloseTransaction())
                {
                    foreach (ObjectId id in res.Value.GetObjectIds())
                    {
                        hit = CadView.Classify(tr, id);
                        if (hit.HasValue) break;
                    }
                    tr.Commit();
                }
                if (!hit.HasValue) return;
                _suppressSel = true;
                try
                {
                    switch (hit.Value.Key)
                    {
                        case "PT":
                        case "NHAN": _tabs.SelectedTab = _tabPoints; SelectPointInList(hit.Value.Value); break;
                        case "ANH": _tabs.SelectedTab = _tabPhotos; SelectPhoto(hit.Value.Value); break;
                        case "KH": _tabs.SelectedTab = _tabObjects; SelectObjectInList(hit.Value.Value); break;
                    }
                }
                finally { _suppressSel = false; }
            }
            catch (Exception ex) { Status("Đồng bộ lựa chọn: " + ex.Message); }
        }

        /// <summary>Chon + thu phong 1 thuc the trong CAD tu palette (khong gay vong lap su kien).</summary>
        private void HighlightAndZoom(string handle, double x, double y, double viewHeight)
        {
            if (!NeedDoc()) return;
            string why;
            if (AcadDispatcher.IsBusy(_doc, out why)) { Status(why); return; }
            try
            {
                using (_doc.LockDocument())
                {
                    CadView.ZoomTo(_doc.Editor, x, y, viewHeight);
                    var id = string.IsNullOrEmpty(handle) ? ObjectId.Null : CadView.IdFromHandle(_doc.Database, handle);
                    if (!id.IsNull)
                    {
                        _suppressSel = true;
                        _suppressUntil = DateTime.Now.AddMilliseconds(800);
                        try { _doc.Editor.SetImpliedSelection(new[] { id }); }
                        finally { _suppressSel = false; }
                    }
                }
                try { Autodesk.AutoCAD.Internal.Utils.SetFocusToDwgView(); } catch { }
            }
            catch (Exception ex) { Status("Thu phóng: " + ex.Message); }
        }

        /// <summary>ID diem RTK dang duoc chon trong CAD (POINT BHT_PT hoac nhan BHT_NHAN).</summary>
        private List<string> SelectedSurveyIds()
        {
            var o = new List<string>();
            if (_doc == null) return o;
            try
            {
                var res = _doc.Editor.SelectImplied();
                if (res.Status != PromptStatus.OK || res.Value == null) return o;
                using (var tr = _doc.Database.TransactionManager.StartOpenCloseTransaction())
                {
                    foreach (ObjectId id in res.Value.GetObjectIds())
                    {
                        var c = CadView.Classify(tr, id);
                        if (c.HasValue && (c.Value.Key == "PT" || c.Value.Key == "NHAN"))
                        {
                            var u = c.Value.Value.ToUpperInvariant();
                            if (!o.Contains(u)) o.Add(u);
                        }
                    }
                    tr.Commit();
                }
            }
            catch (Exception ex) { Status("Đọc lựa chọn: " + ex.Message); }
            return o;
        }

        /// <summary>
        /// Bat dau lua chon tu Palette ma khong dong bang. Viec nhan chuot chay trong
        /// command context cua AutoCAD; ket qua duoc tra lai UI sau khi nguoi dung Enter.
        /// </summary>
        private void PickSurveyPoints(Action<List<string>> done)
        {
            if (!NeedDoc()) return;
            var expectedDoc = _doc;
            var ids = new List<string>();
            Status("Chọn POINT RTK hoặc nhãn điểm trên bản vẽ, nhấn Enter để xác nhận ...");
            AcadDispatcher.RunInCommandContext("Chọn điểm RTK", () =>
            {
                var doc = AcadDispatcher.ActiveDocument;
                if (doc == null || doc != expectedDoc) return OpResult.Fail("bản vẽ đang hoạt động đã thay đổi");
                try { Autodesk.AutoCAD.Internal.Utils.SetFocusToDwgView(); } catch { }
                var opt = new PromptSelectionOptions();
                opt.MessageForAdding = "\nChọn POINT RTK hoặc nhãn điểm BHT: ";
                opt.MessageForRemoval = "\nBỏ điểm khỏi tập chọn: ";
                var picked = doc.Editor.GetSelection(opt);
                if (picked.Status != PromptStatus.OK || picked.Value == null)
                    return OpResult.Fail("đã hủy chọn điểm");
                using (var tr = doc.Database.TransactionManager.StartOpenCloseTransaction())
                {
                    foreach (ObjectId id in picked.Value.GetObjectIds())
                    {
                        var c = CadView.Classify(tr, id);
                        if (c.HasValue && (c.Value.Key == "PT" || c.Value.Key == "NHAN"))
                        {
                            string u = c.Value.Value.ToUpperInvariant();
                            if (!ids.Contains(u)) ids.Add(u);
                        }
                    }
                    tr.Commit();
                }
                return ids.Count > 0
                    ? OpResult.Success("đã chọn " + ids.Count + " điểm RTK")
                    : OpResult.Fail("tập chọn không có POINT RTK hoặc nhãn điểm BHT");
            }, r => UI(() =>
            {
                Status(r.ToString());
                if (r.Ok && done != null) done(ids);
            }));
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing) { Unbind(); _selTimer.Dispose(); ShowImage(null); }
            base.Dispose(disposing);
        }
    }
}
