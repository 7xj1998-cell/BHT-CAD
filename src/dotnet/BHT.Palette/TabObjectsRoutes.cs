using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using BHT.Bridge;
using BHT.Core;

namespace BHT.Palette
{
    public partial class BhtPaletteControl
    {
        // ================================================================ D. HO SO DOI TUONG
        private TabPage _tabObjects;
        private ListView _objList;
        private TextBox _oId, _oDesc, _oPoles, _oFaces, _oNote, _oChainage, _oInfo;
        private ComboBox _oCustomBlock;
        private ComboBox _oGroup, _oCode, _oCodeType, _oSide, _oFaceCodes, _oCond;
        private SignComboFilter _codeFilter, _faceFilter;
        private string _faceAuto;
        private CheckBox _oChecked, _oAllowShared;
        private ListBox _oPoints, _oPhotos;
        private Label _oMode;
        private bool _oIsNew;

        private TabPage BuildObjectsTab()
        {
            var tp = new TabPage("Hồ\u00A0sơ đối\u00A0tượng") { ToolTipText = "Hồ sơ đối tượng: tạo / sửa hồ sơ từ điểm RTK, ký hiệu, ảnh và lý trình của đối tượng" };
            _tabObjects = tp;
            _objList = new ListView { View = View.Details, FullRowSelect = true, HideSelection = false, MultiSelect = false, Dock = DockStyle.Top, Height = 150 };
            _objList.Columns.Add("ID", 95); _objList.Columns.Add("Nhóm", 90); _objList.Columns.Add("Mã", 55);
            _objList.Columns.Add("Trụ", 35); _objList.Columns.Add("Điểm", 40); _objList.Columns.Add("Ảnh", 40); _objList.Columns.Add("Tình trạng", 80);
            _objList.SelectedIndexChanged += (s, e) => { var it = _objList.SelectedItems.Count > 0 ? _objList.SelectedItems[0] : null; if (it != null) LoadObject((string)it.Tag); };

            var form = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, AutoScroll = true };
            form.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 92));
            form.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            _oMode = new Label { AutoSize = true, ForeColor = Color.DarkBlue, Font = new Font("Segoe UI", 9f, FontStyle.Bold) };
            _oId = new TextBox { Dock = DockStyle.Fill };
            _oGroup = new ComboBox { Dock = DockStyle.Fill, DropDownStyle = ComboBoxStyle.DropDownList };
            foreach (var g in Groups.All) _oGroup.Items.Add(g[1] + " - " + g[2]);
            _oGroup.SelectionChangeCommitted += (s, e) => OnGroupChangedByUser();
            // 5.0: tim khi go (khong dau) tren ma + ten bien; coc tieu / cot Km khong co ma bien -> danh sach rong.
            _oCode = new ComboBox { Dock = DockStyle.Fill, MaxDropDownItems = 18, DropDownWidth = 430 };
            Func<List<TdtSignEntry>> catalog = () => { try { return TdtSignLibrary.GetCatalog(); } catch { return new List<TdtSignEntry>(); } };
            _codeFilter = new SignComboFilter(_oCode, catalog, () => GroupRules.HasSignCode(EditorGroup()), false);
            _oCode.SelectedIndexChanged += (s, e) => { if (!_codeFilter.Busy) ApplySelectedSignSuggestion(); };
            _oCodeType = new ComboBox { Dock = DockStyle.Fill, DropDownStyle = ComboBoxStyle.DropDownList };
            _oCodeType.Items.AddRange(new object[] { "CHUA_XAC_DINH", "QCVN", "NOI_BO" });
            _oDesc = new TextBox { Dock = DockStyle.Fill };
            _oPoles = new TextBox { Dock = DockStyle.Fill };
            _oFaces = new TextBox { Dock = DockStyle.Fill };
            _oFaceCodes = new ComboBox { Dock = DockStyle.Fill, MaxDropDownItems = 18, DropDownWidth = 430 };
            _faceFilter = new SignComboFilter(_oFaceCodes, catalog, () => GroupRules.HasSignCode(EditorGroup()), true);
            _oFaceCodes.TextChanged += (s, e) => { _faceFilter.Remember(); if (!_faceFilter.Busy) AutoFaceCount(); };
            // 5.0: Tinh trang = o chon (Tốt / Bình thường / Hư hỏng), van go tu do duoc de giu gia tri cu.
            _oCond = new ComboBox { Dock = DockStyle.Fill, DropDownStyle = ComboBoxStyle.DropDown };
            _oCond.Items.AddRange(ConditionOptions.All);
            _oSide = new ComboBox { Dock = DockStyle.Fill, DropDownStyle = ComboBoxStyle.DropDownList };
            _oSide.Items.AddRange(new object[] { "CHUA_XAC_DINH", "TRAI", "PHAI", "HAI_BEN" });
            _oChecked = new CheckBox { Text = "Đã kiểm tra hiện trường", AutoSize = true };
            _oNote = new TextBox { Dock = DockStyle.Fill };
            _oPoints = new ListBox { Dock = DockStyle.Fill, Height = 60, SelectionMode = SelectionMode.MultiExtended, IntegralHeight = false };
            _oPhotos = new ListBox { Dock = DockStyle.Fill, Height = 45, IntegralHeight = false };
            _oPhotos.DoubleClick += (s, e) => OpenSelectedObjectPhoto();
            var photoPanel = new TableLayoutPanel { Dock = DockStyle.Fill, Height = 82, RowCount = 2, ColumnCount = 1 };
            photoPanel.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            photoPanel.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            var photoActions = Flow(); photoActions.Dock = DockStyle.Fill;
            photoActions.Controls.Add(Btn("Xem ở tab Ảnh", (s, e) => OpenSelectedObjectPhoto()));
            photoActions.Controls.Add(Btn("Nhập KMZ", (s, e) => SendCmd("BHTKMZ")));
            photoPanel.Controls.Add(_oPhotos, 0, 0);
            photoPanel.Controls.Add(photoActions, 0, 1);

            _oChainage = new TextBox { Dock = DockStyle.Fill };
            var chainPanel = new TableLayoutPanel { Dock = DockStyle.Fill, Height = 64, ColumnCount = 3, RowCount = 2 };
            chainPanel.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 33.34f));
            chainPanel.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 33.33f));
            chainPanel.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 33.33f));
            chainPanel.RowStyles.Add(new RowStyle(SizeType.Absolute, 28));
            chainPanel.RowStyles.Add(new RowStyle(SizeType.Absolute, 34));
            chainPanel.Controls.Add(_oChainage, 0, 0);
            chainPanel.SetColumnSpan(_oChainage, 3);
            var saveChainage = Btn("Ghi tay", (s, e) => SaveManualChainage()); saveChainage.Dock = DockStyle.Fill;
            var clearChainage = Btn("Xóa", (s, e) => ClearManualChainage()); clearChainage.Dock = DockStyle.Fill;
            var calculateChainage = Btn("Tính tuyến", (s, e) => SendCmd("BHTLYTRINH")); calculateChainage.Dock = DockStyle.Fill;
            chainPanel.Controls.Add(saveChainage, 0, 1);
            chainPanel.Controls.Add(clearChainage, 1, 1);
            chainPanel.Controls.Add(calculateChainage, 2, 1);
            _oAllowShared = new CheckBox { Text = "Cho phép tạo hồ sơ MỚI dùng chung điểm (sẽ hỏi xác nhận)", AutoSize = true };
            _oInfo = new TextBox { Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Vertical, Dock = DockStyle.Fill, Height = 65, Font = new Font("Consolas", 8.5f) };
            Action<string, Control> row = (t, c) => { form.Controls.Add(new Label { Text = t, AutoSize = true, Padding = new Padding(0, 5, 0, 0) }); form.Controls.Add(c); };
            form.Controls.Add(new Label()); form.Controls.Add(_oMode);
            row("ID", _oId); row("Nhóm", _oGroup);
            _oCustomBlock = new ComboBox { Dock = DockStyle.Fill };
            _oCustomBlock.DropDown += (s, e) => RefreshCustomBlocks();
            var customPanel = Flow(); customPanel.Dock = DockStyle.Fill;
            _oCustomBlock.Width = 170; _oCustomBlock.Dock = DockStyle.None;
            customPanel.Controls.Add(_oCustomBlock);
            customPanel.Controls.Add(Btn("Chọn block CAD", (s, e) => PickCustomBlock()));
            customPanel.Controls.Add(Btn("Bỏ gán", (s, e) => _oCustomBlock.Text = ""));
            row("Block tùy chỉnh", customPanel);
            row("Mã hiệu", _oCode); row("Loại mã", _oCodeType); row("Mô tả", _oDesc);
            row("Số trụ/chân", _oPoles); row("Số mặt biển", _oFaces); row("Mã các mặt", _oFaceCodes);
            var tip = new ToolTip { AutoPopDelay = 15000 };
            tip.SetToolTip(_oCode, "Mã biển chính (quyết định ký hiệu/nhãn). Gõ mã hoặc tên, có dấu hay không dấu: vd 'di cham', '245a'. Cọc tiêu / Cột Km: để trống.");
            tip.SetToolTip(_oFaceCodes, "Mã từng mặt biển trên CÙNG trụ, cách nhau dấu ';' - vd 'W.245a; S.509a'. Gõ để tìm; chọn để thêm. Số mặt biển tự điền theo số mã nếu đang trống.");
            tip.SetToolTip(_oFaces, "Số tấm biển (mặt) gắn trên trụ. Để trống thì tự lấy theo số mã ở 'Mã các mặt'.");
            tip.SetToolTip(_oPoles, "Số trụ/cột/chân đỡ của đối tượng (1 trụ gắn 2 biển: Số trụ = 1, Số mặt = 2).");
            row("Tình trạng", _oCond); row("Phía đường", _oSide); form.Controls.Add(new Label()); form.Controls.Add(_oChecked);
            row("Ghi chú", _oNote); row("Điểm RTK", _oPoints); row("Ảnh", photoPanel);
            row("Lý trình tay", chainPanel); row("Thông tin", _oInfo);
            form.Controls.Add(new Label()); form.Controls.Add(_oAllowShared);

            var f1 = Flow();
            f1.Controls.Add(Btn("Chọn điểm trên CAD và tạo hồ sơ", (s, e) => PickSurveyPoints(NewObjectFromPoints)));
            f1.Controls.Add(Btn("Lưu", (s, e) => SaveObject()));
            f1.Controls.Add(Btn("Chèn/Cập nhật ký hiệu", (s, e) => SymbolForCurrent()));
            f1.Controls.Add(Btn("Chèn biển tự do", (s, e) => {
                if (_oIsNew || _oId.Text == "") { Status("Lưu hồ sơ biển báo trước khi chèn tự do."); return; }
                CallLisp("bht:api-sign-free", new[] { _oId.Text }, "Chèn biển tự do " + _oId.Text, null);
            }));
            f1.Controls.Add(Btn("Thư viện block", (s, e) => OpenSignPicker()));
            var f2 = Flow(); f2.Dock = DockStyle.Bottom;
            f2.Controls.Add(Btn("Chọn thêm điểm trên CAD", (s, e) => PickSurveyPoints(AddPointIds)));
            f2.Controls.Add(Btn("Gỡ điểm đã chọn", (s, e) => RemoveListPoints()));
            f2.Controls.Add(Btn("Thu phóng", (s, e) => ZoomObject()));
            f2.Controls.Add(Btn("Thông tin (BHTINFO)", (s, e) =>
            {
                if (_oIsNew || _oId.Text == "") return;
                CallLisp("bht:api-info-object", new[] { _oId.Text }, "Thông tin " + _oId.Text, r => { if (r.Ok) _oInfo.Text = string.Join("\r\n", r.Values.ToArray()); });
            }));
            tp.Controls.Add(form);
            tp.Controls.Add(f1);
            tp.Controls.Add(_objList);
            tp.Controls.Add(f2);
            ClearObjectEditor();
            return tp;
        }

        private void RefreshObjects()
        {
            string keep = _oIsNew ? null : _oId.Text;
            var objs = _svc.GetObjects();
            _objList.BeginUpdate();
            _objList.Items.Clear();
            foreach (var kv in objs.OrderBy(k => k.Key, StringComparer.Ordinal))
            {
                var r = kv.Value;
                var it = new ListViewItem(new[] { kv.Key, Groups.Label(r.Get(ObjFields.Group)), r.Get(ObjFields.Code), r.Get(ObjFields.PoleCount),
                    r.GetAll(ObjFields.Point).Count.ToString(), r.GetAll(ObjFields.Photo).Count.ToString(), r.Get(ObjFields.Condition) });
                it.Tag = kv.Key;
                _objList.Items.Add(it);
            }
            _objList.EndUpdate();
            if (!string.IsNullOrEmpty(keep) && objs.ContainsKey(keep)) LoadObject(keep);
        }

        private void SelectObjectInList(string oid)
        {
            foreach (ListViewItem it in _objList.Items)
            {
                bool m = string.Equals((string)it.Tag, oid, StringComparison.OrdinalIgnoreCase);
                it.Selected = m; if (m) it.EnsureVisible();
            }
            LoadObject(oid);
        }

        private void ClearObjectEditor()
        {
            _oIsNew = true;
            _oMode.Text = "HỒ SƠ MỚI (chưa lưu)";
            _oId.Text = ""; _oId.ReadOnly = false; _oCustomBlock.Text = "";
            _oGroup.SelectedIndex = Groups.All.Length - 1;
            _oCode.SelectedIndex = -1; _oCode.Text = ""; _oCodeType.SelectedIndex = 0; _oDesc.Text = ""; _oPoles.Text = ""; _oFaces.Text = ""; _oFaceCodes.Text = ""; _faceAuto = null;
            _oCond.Text = ""; _oSide.SelectedIndex = 0; _oChecked.Checked = false; _oNote.Text = "";
            _oPoints.Items.Clear(); _oPhotos.Items.Clear();
            _oPhotos.Items.Add("(chưa gắn ảnh — bấm Nhập KMZ hoặc sang tab Ảnh)");
            _oChainage.Text = ""; _oInfo.Text = ""; _oAllowShared.Checked = false;
        }

        private static void SelectCombo(ComboBox c, string value)
        {
            for (int i = 0; i < c.Items.Count; i++)
                if (((string)c.Items[i]).Split(' ')[0] == value) { c.SelectedIndex = i; return; }
            if (!string.IsNullOrEmpty(value)) { c.Items.Add(value); c.SelectedIndex = c.Items.Count - 1; }
        }

        private void ApplySelectedSignSuggestion()
        {
            var sign = _oCode.SelectedItem as TdtSignEntry;
            if (sign == null) return;
            SelectCombo(_oGroup, "BIEN_BAO");
            SelectCombo(_oCodeType, "QCVN");
            if (string.IsNullOrWhiteSpace(_oDesc.Text) || _oDesc.Text == "bb" || _oDesc.Text.StartsWith("bb.", StringComparison.OrdinalIgnoreCase))
                _oDesc.Text = sign.Description;
        }

        private string EditorSignCode()
        {
            var sign = _oCode.SelectedItem as TdtSignEntry;
            if (sign != null) return sign.Code;
            // danh sach da loc lai -> chi con chu "W.245a — Đi chậm": lay phan ma
            string t = _oCode.Text.Trim();
            int i = t.IndexOf(" — ", StringComparison.Ordinal);
            return i > 0 ? t.Substring(0, i).Trim() : t;
        }

        private string EditorGroup()
        {
            return ((string)_oGroup.SelectedItem ?? "CHUA_XAC_DINH").Split(' ')[0];
        }

        /// <summary>5.0: Coc tieu / Cot Km khong co ma bien - bo ma bien (neu co) khi nguoi dung chon nhom nay.</summary>
        private void OnGroupChangedByUser()
        {
            if (GroupRules.HasSignCode(EditorGroup())) return;
            if (_oCode.Text.Trim() != "")
            {
                _oCode.SelectedIndex = -1; _oCode.Text = "";
                SelectCombo(_oCodeType, "CHUA_XAC_DINH");
                Status("Nhóm " + Groups.Label(EditorGroup()) + " không có mã biển - đã để trống Mã hiệu.");
            }
            _oCode.DroppedDown = false; _oCode.Items.Clear();
        }

        /// <summary>5.0: So mat bien tu dong = so ma trong "Mã các mặt" khi o dang trong / dang la gia tri tu dong.</summary>
        private void AutoFaceCount()
        {
            string next = SignSearch.AutoFaceCount(_oFaces.Text, _faceAuto, _oFaceCodes.Text);
            if (next != _oFaces.Text.Trim()) { _oFaces.Text = next; _faceAuto = next; }
        }

        private void LoadObject(string oid)
        {
            if (_svc == null) return;
            var r = _svc.GetObject(oid);
            if (r == null) { Status("Không có hồ sơ " + oid); return; }
            _oIsNew = false;
            _oMode.Text = "SỬA HỒ SƠ " + oid.ToUpperInvariant();
            _oId.Text = oid.ToUpperInvariant(); _oId.ReadOnly = true; _oCustomBlock.Text = r.Get(ObjFields.CustomBlock);
            SelectCombo(_oGroup, r.Get(ObjFields.Group));
            _oCode.Text = r.Get(ObjFields.Code); SelectCombo(_oCodeType, r.Get(ObjFields.CodeType) == "" ? "CHUA_XAC_DINH" : r.Get(ObjFields.CodeType));
            _oDesc.Text = r.Get(ObjFields.Desc); _oPoles.Text = r.Get(ObjFields.PoleCount); _oFaces.Text = r.Get(ObjFields.FaceCount);
            _oFaceCodes.Items.Clear(); _oFaceCodes.Text = string.Join("; ", r.GetAll(ObjFields.Face).ToArray()); _faceAuto = null;
            _oCode.Items.Clear(); _oCode.Text = r.Get(ObjFields.Code);
            _oCond.Text = ConditionOptions.Display(r.Get(ObjFields.Condition)); SelectCombo(_oSide, r.Get(ObjFields.RoadSide) == "" ? "CHUA_XAC_DINH" : r.Get(ObjFields.RoadSide));
            _oChecked.Checked = r.Get(ObjFields.CheckState) == "DA_KIEM_TRA"; _oNote.Text = r.Get(ObjFields.Note);
            _oPoints.Items.Clear();
            var idx = _svc.PointIndex();
            foreach (var p in r.GetAll(ObjFields.Point))
            {
                SurveyPoint sp;
                _oPoints.Items.Add(idx.TryGetValue(p.ToUpperInvariant(), out sp) ? p + " | " + sp.Name + " | " + sp.Description : p + " | (KHÔNG CÒN ĐIỂM)");
            }
            _oPhotos.Items.Clear();
            foreach (var a in r.GetAll(ObjFields.Photo)) _oPhotos.Items.Add(a);
            if (_oPhotos.Items.Count == 0) _oPhotos.Items.Add("(chưa gắn ảnh — sang tab Ảnh để chọn và xác nhận gắn)");
            _oChainage.Text = r.Get(ObjFields.ChainageKm);
            var km = new StringBuilder();
            if (r.Get(ObjFields.ChainageKm) != "") km.Append(r.Get(ObjFields.ChainageKm)).Append(" offset ").Append(r.Get(ObjFields.OffsetM)).Append(" m ").Append(r.Get(ObjFields.RouteSide));
            else km.Append("(chưa tính lý trình - ").Append(r.Get(ObjFields.KmState)).Append(")");
            km.Append("\r\nĐoạn/gói: ").Append(r.Get(ObjFields.Segment)).Append(" / ").Append(r.Get(ObjFields.Package))
              .Append("\r\nTạo ").Append(r.Get(ObjFields.CreatedAt)).Append(" | sửa ").Append(r.Get(ObjFields.ModifiedAt));
            _oInfo.Text = km.ToString();
        }

        private void OpenSelectedObjectPhoto()
        {
            var link = _oPhotos.SelectedItem as string;
            if (string.IsNullOrEmpty(link) || link.StartsWith("(", StringComparison.Ordinal))
            {
                _tabs.SelectedTab = _tabPhotos;
                Status(_photos.Count == 0 ? "Chưa có dữ liệu ảnh — bấm Nhập KMZ." : "Chọn ảnh, chọn hồ sơ rồi bấm Xác nhận gắn.");
                return;
            }
            string photoId = ObjectLogic.PhotoIdOfLink(link);
            _tabs.SelectedTab = _tabPhotos;
            SelectPhoto(photoId);
        }

        private void SaveManualChainage()
        {
            if (_oIsNew || string.IsNullOrEmpty(_oId.Text)) { Status("Lưu hồ sơ trước khi nhập lý trình."); return; }
            if (!NeedDoc()) return;
            double metres;
            if (!Chainage.TryParse(_oChainage.Text, out metres))
            {
                StatusWarn("Lý trình không hợp lệ. Nhập dạng Km12+345.67, 12+345.67 hoặc số mét 12345.67.");
                return;
            }
            var fields = new BhtRecord()
                .Add(ObjFields.ChainageM, LispFormat.Fnum(metres, 3))
                .Add(ObjFields.ChainageKm, Chainage.Format(metres))
                .Add(ObjFields.KmState, "NHAP_TAY")
                .Add(ObjFields.KmSource, "Nhập thủ công từ Palette")
                .Add(ObjFields.StationStatus, "MANUAL").Add(ObjFields.StationRouteRevision, "")
                .Add(ObjFields.RouteId, "").Add(ObjFields.OffsetM, "").Add(ObjFields.RouteSide, "")
                .Add(ObjFields.Segment, "").Add(ObjFields.Package, "")
                .Add(ObjFields.SegMethod, "CHUA_PHAN_DOAN").Add(ObjFields.SegCandidates, "");
            string id = _oId.Text;
            var result = AcadDispatcher.RunWrite(_doc, "Ghi lý trình tay", db => _svc.UpdateObject(id, fields));
            if (result.Ok) Status("Đã ghi " + Chainage.Format(metres) + " cho " + id + "."); else StatusError(result.ToString());
            if (!result.Ok) return;
            RefreshAll();
            if (_lispOk) CallLisp("bht:api-symbol-sync", new[] { id }, "Cập nhật ký hiệu " + id, null);
        }

        private void ClearManualChainage()
        {
            if (_oIsNew || string.IsNullOrEmpty(_oId.Text) || !NeedDoc()) return;
            string id = _oId.Text;
            var fields = new BhtRecord()
                .Add(ObjFields.RouteId, "").Add(ObjFields.ChainageM, "").Add(ObjFields.ChainageKm, "")
                .Add(ObjFields.OffsetM, "").Add(ObjFields.RouteSide, "")
                .Add(ObjFields.KmState, "CHUA_TINH").Add(ObjFields.KmSource, "")
                .Add(ObjFields.StationStatus, "NO_ROUTE").Add(ObjFields.StationRouteRevision, "")
                .Add(ObjFields.Segment, "").Add(ObjFields.Package, "")
                .Add(ObjFields.SegMethod, "CHUA_PHAN_DOAN").Add(ObjFields.SegCandidates, "");
            var result = AcadDispatcher.RunWrite(_doc, "Xóa lý trình", db => _svc.UpdateObject(id, fields));
            if (result.Ok) Status("Đã xóa lý trình của " + id + "."); else StatusError(result.ToString());
            if (result.Ok) RefreshAll();
        }

        private List<string> EditorPointIds()
        {
            return _oPoints.Items.Cast<string>().Select(s => s.Split('|')[0].Trim().ToUpperInvariant()).ToList();
        }

        /// <summary>
        /// Tao ho so tu diem: doc ten / mo ta / toa do, goi y nhom TU MO TA (co can cu), kiem tra diem da thuoc ho so khac.
        /// Mac dinh KHONG tao ho so moi khi diem da thuoc ho so khac.
        /// </summary>
        private void NewObjectFromPoints(List<string> ids)
        {
            if (!NeedDoc()) return;
            if (ids.Count == 0) { Status("Chưa chọn điểm RTK nào (chọn POINT/nhãn BHT trong CAD hoặc trong thẻ Điểm RTK)."); return; }
            _tabs.SelectedTab = _tabObjects;
            List<string> hits, same;
            ObjectLogic.Overlap(ids, _svc.GetObjects(), out hits, out same);
            if (hits.Count > 0)
            {
                string msg = "Điểm đã chọn ĐÃ THUỘC hồ sơ: " + string.Join(", ", hits.ToArray()) + "."
                    + (same.Count > 0 ? "\nBộ điểm TRÙNG KHỚP hồ sơ " + string.Join(", ", same.ToArray()) + " - có thể hồ sơ đã được tạo." : "")
                    + "\n\nYes = mở hồ sơ " + hits[0] + " để xem / sửa / thêm điểm\nNo = soạn hồ sơ MỚI dùng chung điểm (khi Lưu sẽ hỏi xác nhận lần nữa)\nCancel = hủy (mặc định)";
                var ans = MessageBox.Show(this, msg, "BHT - điểm đã thuộc hồ sơ khác", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button3);
                if (ans == DialogResult.Yes) { SelectObjectInList(hits[0]); return; }
                if (ans != DialogResult.No) { Status("Đã hủy - không tạo hồ sơ."); return; }
            }
            ClearObjectEditor();
            _oId.Text = _svc.NextObjectId();
            _oAllowShared.Checked = hits.Count > 0;
            var idx = _svc.PointIndex();
            var pts = new List<SurveyPoint>();
            foreach (var id in ids)
            {
                SurveyPoint sp;
                if (idx.TryGetValue(id, out sp)) { pts.Add(sp); _oPoints.Items.Add(sp.Id + " | " + sp.Name + " | " + sp.Description); }
                else _oPoints.Items.Add(id + " | (KHÔNG CÒN ĐIỂM)");
            }
            string basis;
            SelectCombo(_oGroup, Groups.Suggest(pts, out basis));
            if (pts.Count == 1) _oDesc.Text = pts[0].Description;
            _oMode.Text = "HỒ SƠ MỚI từ " + ids.Count + " điểm — gợi ý: " + basis + ". Kiểm tra nhóm rồi bấm Lưu.";
            Status("Soạn hồ sơ mới. Nhóm chỉ là GỢI Ý từ mô tả gốc - hãy xác nhận.");
        }

        private void OpenSignPicker()
        {
            using (var picker = new SignPickerForm(EditorSignCode(), _oDesc.Text, _oFaceCodes.Text))
            {
                if (picker.ShowDialog(this) != DialogResult.OK || picker.SelectedSign == null) return;
                var sign = picker.SelectedSign;
                SelectCombo(_oGroup, "BIEN_BAO");
                _oCode.Items.Clear(); _oCode.SelectedIndex = -1; _oCode.Text = picker.SelectedCode;
                if (picker.SelectedFaces != null)
                {
                    _oFaceCodes.Items.Clear(); _oFaceCodes.Text = string.Join("; ", picker.SelectedFaces.ToArray());
                    _oFaces.Text = picker.SelectedFaces.Count.ToString(); _faceAuto = _oFaces.Text;
                }
                SelectCombo(_oCodeType, "QCVN");
                string previous = _oDesc.Text.Trim();
                bool catalogDescription = TdtSignLibrary.GetCatalog().Any(x => x.Description == previous);
                if (previous == "" || catalogDescription) _oDesc.Text = sign.Description;
                else if (!previous.Contains(sign.Description) && !string.IsNullOrWhiteSpace(sign.Description))
                    _oDesc.Text = sign.Description + " | " + previous;
                Status("Đã chọn " + picker.SelectedCode + " — " + sign.Description + ". Bấm Lưu để ghi hồ sơ.");
            }
        }

        private bool CustomBlockExists(string name)
        {
            using (var tr = _doc.Database.TransactionManager.StartOpenCloseTransaction())
            {
                var table = (Autodesk.AutoCAD.DatabaseServices.BlockTable)tr.GetObject(_doc.Database.BlockTableId, Autodesk.AutoCAD.DatabaseServices.OpenMode.ForRead);
                if (!table.Has(name)) return false;
                var block = (Autodesk.AutoCAD.DatabaseServices.BlockTableRecord)tr.GetObject(table[name], Autodesk.AutoCAD.DatabaseServices.OpenMode.ForRead);
                return !block.IsLayout && !block.IsAnonymous && !block.IsFromExternalReference;
            }
        }

        private void RefreshCustomBlocks()
        {
            if (!NeedDoc()) return;
            string text = _oCustomBlock.Text;
            using (var tr = _doc.Database.TransactionManager.StartOpenCloseTransaction())
            {
                var table = (Autodesk.AutoCAD.DatabaseServices.BlockTable)tr.GetObject(_doc.Database.BlockTableId, Autodesk.AutoCAD.DatabaseServices.OpenMode.ForRead);
                _oCustomBlock.Items.Clear();
                foreach (Autodesk.AutoCAD.DatabaseServices.ObjectId id in table)
                {
                    var block = (Autodesk.AutoCAD.DatabaseServices.BlockTableRecord)tr.GetObject(id, Autodesk.AutoCAD.DatabaseServices.OpenMode.ForRead);
                    if (!block.IsLayout && !block.IsAnonymous && !block.IsFromExternalReference) _oCustomBlock.Items.Add(block.Name);
                }
            }
            _oCustomBlock.Text = text;
        }

        private void PickCustomBlock()
        {
            if (!NeedDoc()) return;
            var document = _doc;
            AcadDispatcher.RunInCommandContext("Chọn block tùy chỉnh", () =>
            {
                var prompt = new Autodesk.AutoCAD.EditorInput.PromptEntityOptions("\nChọn block dùng cho hồ sơ này: ");
                prompt.SetRejectMessage("\nHãy chọn một block.");
                prompt.AddAllowedClass(typeof(Autodesk.AutoCAD.DatabaseServices.BlockReference), true);
                var result = document.Editor.GetEntity(prompt);
                if (result.Status != Autodesk.AutoCAD.EditorInput.PromptStatus.OK) return OpResult.Fail("Đã hủy chọn.");
                using (var tr = document.Database.TransactionManager.StartOpenCloseTransaction())
                {
                    var block = (Autodesk.AutoCAD.DatabaseServices.BlockReference)tr.GetObject(result.ObjectId, Autodesk.AutoCAD.DatabaseServices.OpenMode.ForRead);
                    var definition = (Autodesk.AutoCAD.DatabaseServices.BlockTableRecord)tr.GetObject(
                        block.IsDynamicBlock ? block.DynamicBlockTableRecord : block.BlockTableRecord, Autodesk.AutoCAD.DatabaseServices.OpenMode.ForRead);
                    if (definition.IsFromExternalReference) return OpResult.Fail("Không dùng Xref làm block hồ sơ.");
                    return OpResult.Success(definition.Name);
                }
            }, result =>
            {
                if (result.Ok && _doc == document) { _oCustomBlock.Text = result.Message; Status("Đã chọn block " + result.Message + ". Bấm Lưu để gán riêng cho hồ sơ."); }
                else StatusResult(result);
            });
        }

        private BhtRecord EditorFields()
        {
            var f = new BhtRecord()
                .Add(ObjFields.Group, EditorGroup())
                .Add(ObjFields.CustomBlock, _oCustomBlock.Text.Trim())
                .Add(ObjFields.Code, SignPresentation.ResolveCode(EditorSignCode(), _oDesc.Text))
                .Add(ObjFields.CodeType, ((string)_oCodeType.SelectedItem ?? "CHUA_XAC_DINH"))
                .Add(ObjFields.Desc, _oDesc.Text)
                .Add(ObjFields.PoleCount, _oPoles.Text.Trim())
                .Add(ObjFields.FaceCount, _oFaces.Text.Trim())
                .Add(ObjFields.Condition, _oCond.Text.Trim())
                .Add(ObjFields.RoadSide, ((string)_oSide.SelectedItem ?? "CHUA_XAC_DINH"))
                .Add(ObjFields.CheckState, _oChecked.Checked ? "DA_KIEM_TRA" : "CHUA_KIEM_TRA")
                .Add(ObjFields.Note, _oNote.Text);
            foreach (var m in SignSearch.SplitCodes(_oFaceCodes.Text)) f.Add(ObjFields.Face, m);
            return f;
        }

        private static bool IsCount(string s) { int n; return s == "" || (int.TryParse(s, out n) && n >= 0 && n <= 999); }

        private void SaveObject()
        {
            if (!NeedDoc()) return;
            if (!IsCount(_oPoles.Text.Trim()) || !IsCount(_oFaces.Text.Trim())) { StatusWarn("Số trụ / số mặt phải là số nguyên ≥ 0 (hoặc để trống)."); return; }
            var f = EditorFields();
            if (f.Get(ObjFields.CustomBlock) != "" && !CustomBlockExists(f.Get(ObjFields.CustomBlock)))
            { StatusWarn("Block tùy chỉnh không tồn tại trong bản vẽ hiện tại."); return; }
            if (!_oIsNew && !ConfirmNoDuplicate(f, false)) return;
            if (_oIsNew)
            {
                var ids = EditorPointIds();
                if (ids.Count == 0) { StatusWarn("Hồ sơ mới cần ít nhất 1 điểm RTK."); return; }
                List<string> hits, same;
                ObjectLogic.Overlap(ids, _svc.GetObjects(), out hits, out same);
                bool share = false;
                if (hits.Count > 0)
                {
                    if (!_oAllowShared.Checked) { StatusWarn("Điểm đã thuộc hồ sơ " + string.Join(", ", hits.ToArray()) + " - KHÔNG tạo (đánh dấu 'Cho phép dùng chung' nếu thật sự cần)."); return; }
                    if (MessageBox.Show(this, "Tạo hồ sơ MỚI dùng chung điểm với " + string.Join(", ", hits.ToArray()) + "?" +
                        (same.Count > 0 ? "\nCHÚ Ý: bộ điểm trùng khớp hồ sơ " + string.Join(", ", same.ToArray()) + "." : ""),
                        "BHT - xác nhận dùng chung điểm", MessageBoxButtons.YesNo, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2) != DialogResult.Yes)
                    { Status("Đã hủy - không tạo hồ sơ."); return; }
                    share = true;
                }
                if (!ConfirmNoDuplicate(f, share)) return;
                string id = _oId.Text.Trim().ToUpperInvariant();
                var r = AcadDispatcher.RunWrite(_doc, "Tạo hồ sơ", db => _svc.CreateObject(id, f, ids, share));
                if (r.Ok) Status("Đã tạo hồ sơ " + r.Message + "."); else StatusError(r.ToString());
                if (!r.Ok) return;
                RefreshAll();
                SelectObjectInList(r.Message);
                if (_lispOk && MessageBox.Show(this, "Chèn ký hiệu cho " + r.Message + " ngay?", "BHT", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                    CallLisp("bht:api-symbol-sync", new[] { r.Message }, "Chèn ký hiệu " + r.Message, null);
            }
            else
            {
                string id = _oId.Text;
                var r = AcadDispatcher.RunWrite(_doc, "Cập nhật hồ sơ", db => _svc.UpdateObject(id, f));
                StatusResult(r);
                if (!r.Ok) return;
                RefreshAll();
                if (_lispOk) CallLisp("bht:api-symbol-sync", new[] { id }, "Cập nhật ký hiệu " + id, null); // chi cap nhat / tao theo object_id
            }
        }

        /// <summary>
        /// 5.0: Coc tieu / Cot Km - canh bao trung (cung diem RTK, cach &lt;= nguong meta trung_kc_m mac dinh 0.5 m,
        /// Cot Km trung gia tri Km) voi ho so CUNG nhom. Chi doc, khong dich/sua diem RTK. true = tiep tuc luu.
        /// </summary>
        private bool ConfirmNoDuplicate(BhtRecord f, bool sharedConfirmed)
        {
            string g = f.Get(ObjFields.Group);
            if (!DuplicateCheck.Applies(g)) return true;
            List<DuplicateHit> hits;
            double tol;
            try
            {
                tol = DuplicateCheck.ParseTolerance(_svc.Meta(DuplicateCheck.MetaKey, "0.5"));
                string km = _oIsNew ? "" : (_svc.GetObject(_oId.Text) ?? new BhtRecord()).Get(ObjFields.ChainageKm);
                hits = DuplicateCheck.Find(_oId.Text, g, EditorPointIds(), km, _svc.GetObjects(), _svc.PointIndex(), tol, sharedConfirmed);
            }
            catch (Exception ex) { StatusWarn("Không kiểm tra được trùng: " + ex.Message); return true; }
            if (hits.Count == 0) return true;
            string msg = Groups.Label(Groups.Code(g)) + " " + (_oIsNew ? "mới" : _oId.Text) + " có thể TRÙNG với:\n  "
                + string.Join("\n  ", hits.Take(10).Select(h => h.ToString()).ToArray())
                + (hits.Count > 10 ? "\n  ... (+" + (hits.Count - 10) + ")" : "")
                + "\n\nNgưỡng khoảng cách: " + LispFormat.Fnum(tol, 2) + " m (meta " + DuplicateCheck.MetaKey + ")."
                + "\nĐiểm RTK KHÔNG bị di chuyển hay sửa.\n\nYes = vẫn lưu    No = hủy (mặc định)";
            if (MessageBox.Show(this, msg, "BHT - cảnh báo trùng " + Groups.Label(Groups.Code(g)), MessageBoxButtons.YesNo,
                    MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2) == DialogResult.Yes) return true;
            Status("Đã hủy lưu - trùng " + hits[0].Id + ".");
            return false;
        }

        private void SymbolForCurrent()
        {
            if (_oIsNew || _oId.Text == "") { Status("Lưu hồ sơ trước khi chèn ký hiệu."); return; }
            CallLisp("bht:api-symbol-sync", new[] { _oId.Text }, "Ký hiệu " + _oId.Text, null);
        }

        private void AddSelectedPoints()
        {
            AddPointIds(SelectedSurveyIds());
        }

        private void AddPointIds(List<string> ids)
        {
            if (ids.Count == 0) { Status("Chọn điểm RTK trong CAD trước."); return; }
            if (_oIsNew)
            {
                foreach (var id in ids) if (!EditorPointIds().Contains(id)) _oPoints.Items.Add(id);
                return;
            }
            string oid = _oId.Text;
            List<string> hits, same;
            ObjectLogic.Overlap(ids, _svc.GetObjects(), out hits, out same);
            hits.Remove(oid);
            if (hits.Count > 0 && MessageBox.Show(this, "Điểm đã thuộc hồ sơ khác: " + string.Join(", ", hits.ToArray()) + ". Vẫn thêm vào " + oid + "?",
                "BHT", MessageBoxButtons.YesNo, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2) != DialogResult.Yes) return;
            StatusResult(AcadDispatcher.RunWrite(_doc, "Thêm điểm", db => _svc.AddPoints(oid, ids)));
            RefreshAll();
        }

        private void RemoveListPoints()
        {
            var sel = _oPoints.SelectedItems.Cast<string>().Select(s => s.Split('|')[0].Trim()).ToList();
            if (sel.Count == 0) { Status("Chọn điểm trong danh sách Điểm RTK của hồ sơ."); return; }
            if (_oIsNew) { foreach (var s in _oPoints.SelectedItems.Cast<string>().ToList()) _oPoints.Items.Remove(s); return; }
            string oid = _oId.Text;
            if (MessageBox.Show(this, "Gỡ " + sel.Count + " điểm khỏi " + oid + "? (điểm RTK giữ nguyên)", "BHT", MessageBoxButtons.YesNo, MessageBoxIcon.Question, MessageBoxDefaultButton.Button2) != DialogResult.Yes) return;
            StatusResult(AcadDispatcher.RunWrite(_doc, "Gỡ điểm", db => _svc.RemovePoints(oid, sel)));
            RefreshAll();
        }

        private void ZoomObject()
        {
            if (_svc == null || _oId.Text == "") return;
            var rec = _oIsNew ? new BhtRecord().SetAll(ObjFields.Point, EditorPointIds()) : _svc.GetObject(_oId.Text);
            double x, y, z;
            if (rec == null || !ObjectLogic.Position(rec, _svc.PointIndex(), out x, out y, out z)) { Status("Hồ sơ chưa có điểm RTK hợp lệ."); return; }
            HighlightAndZoom(null, x, y, 40.0);
        }

        // ================================================================ E. TUYEN & BAO CAO
        private TabPage BuildRoutesTab()
        {
            var tp = new TabPage("Tuyến & báo cáo") { ToolTipText = "Route Model V5: hình học, điểm đầu, chiều tăng lý trình, cọc TDT, Station Control và báo cáo" };
            var f = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoScroll = true, Padding = new Padding(7) };
            string root = Tdt91Installation.FindRoot();
            string tdt = root == ""
                ? "TDTSolution 9.1: chưa tìm thấy bản thường."
                : "TDTSolution 9.1 bản thường: sẵn sàng • " + TdtSignLibrary.GetCatalog().Count + " mã biển • tim/cọc chỉ đọc.";
            f.Controls.Add(new Label { Text = tdt, AutoSize = true, MaximumSize = new Size(390, 0), ForeColor = root == "" ? Color.DarkRed : Color.DarkGreen, Font = new Font("Segoe UI Semibold", 9f) });

            var geometry = RouteSection("1. THÔNG TIN TUYẾN", "Chọn hình học, điểm đầu và chiều tăng lý trình. Mũi tên trên CAD cho phép kiểm tra trực quan.");
            AddRouteCommandButton(geometry, "BHTTUYENTDT", "Lấy / cập nhật tim từ TDT 9.1", 365);
            AddRouteCommandButton(geometry, "BHTTUYEN", "Chọn Polyline thường", 365);
            AddRouteCommandButton(geometry, "BHTROUTESTART", "Chọn điểm đầu và chiều tuyến", 365);
            AddRouteCommandButton(geometry, "BHTROUTEREVERSE", "Đảo chiều tuyến", 365);
            f.Controls.Add(geometry);

            var station = RouteSection("2. STATION CONTROL & CỌC", "Đọc cọc Km quanh tuyến, cảnh báo cọc bất thường rồi mới cho người dùng xác nhận nạp.");
            AddRouteCommandButton(station, "BHTDOCCOCTDT", "Đọc / kiểm tra cọc TDT", 365);
            AddRouteCommandButton(station, "BHTMOCKM", "Thêm mốc Km đã xác nhận", 365);
            AddRouteCommandButton(station, "BHTDSMOC", "Xem / xóa Station Control", 365);
            f.Controls.Add(station);

            var actions = RouteSection("3. KIỂM TRA & CẬP NHẬT", "Chẩn đoán revision/hình học, sau đó tính lại lý trình, offset và phía cho hồ sơ.");
            var routeDiag = Btn("Kiểm tra tuyến (BHTROUTEDIAG)", (s, e) => CallLisp("bht:api-route-diag", new[] { "" }, "Chẩn đoán tuyến", r =>
            {
                if (r.Ok) ShowReportDialog("Chẩn đoán Route Model V5", string.Join("\r\n", r.Values.ToArray()));
            }));
            routeDiag.Width = 365; routeDiag.TextAlign = ContentAlignment.MiddleLeft; actions.Controls.Add(routeDiag);
            AddRouteCommandButton(actions, "BHTLYTRINH", "Cập nhật lý trình / offset / phía", 365);
            AddRouteCommandButton(actions, "BHTSAPNHAN", "Sắp xếp nhãn trên bản vẽ", 365);
            f.Controls.Add(actions);

            var reports = RouteSection("4. BÁO CÁO", "Báo cáo mở trong hộp thoại lớn; Excel giữ Unicode tiếng Việt.");
            var export = Btn("Xuất báo cáo biển báo Excel", (s, e) => ExportSignReport());
            export.Width = 365; export.TextAlign = ContentAlignment.MiddleLeft; reports.Controls.Add(export);
            var check = Btn("Kiểm tra dữ liệu và mở báo cáo", (s, e) => CallLisp("bht:api-check", new string[0], "Kiểm tra", r =>
            {
                if (r.Ok) ShowReportDialog("Kiểm tra dữ liệu", string.Join("\r\n", r.Values.ToArray()));
            }));
            check.Width = 365; check.TextAlign = ContentAlignment.MiddleLeft; reports.Controls.Add(check);
            f.Controls.Add(reports);

            var advanced = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoSize = true, Visible = false, Margin = new Padding(0) };
            string[][] cmds =
            {
                new[] { "BHTGOITHAU", "Nạp bảng gói thầu" },
                new[] { "BHTPHANDOAN", "Gán đoạn / gói tự động" },
                new[] { "BHTGANDOAN", "Gán đoạn thủ công" },
                new[] { "BHTXUAT", "Xuất bộ CSV dữ liệu kỹ thuật" },
                new[] { "BHTTRANGTHAI", "Trạng thái chi tiết bản vẽ" },
                new[] { "BHTKIEUDIEM", "Dấu X của điểm và sắp lại nhãn" },
                new[] { "BHTBLOCK", "Danh mục chuẩn / nạp block tùy chọn" },
                new[] { "BHTTHUTUVE", "Thứ tự hiển thị" },
                new[] { "BHTGHEPANH", "Đề xuất ghép ảnh (chỉ đề xuất)" },
                new[] { "BHTTHUMUCANH", "Chỉ lại thư mục ảnh" }
            };
            foreach (var c in cmds)
            {
                AddRouteCommandButton(advanced, c[0], c[0] + " — " + c[1], 375);
            }
            var showAdvanced = new CheckBox { Text = "Hiện công cụ nâng cao", AutoSize = true, Margin = new Padding(3, 10, 3, 3) };
            showAdvanced.CheckedChanged += (s, e) => advanced.Visible = showAdvanced.Checked;
            f.Controls.Add(showAdvanced);
            f.Controls.Add(advanced);
            tp.Controls.Add(f);
            return tp;
        }

        private FlowLayoutPanel RouteSection(string title, string description)
        {
            var panel = new FlowLayoutPanel
            {
                FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoSize = true, Width = 380,
                Padding = new Padding(6), Margin = new Padding(0, 8, 0, 0), BackColor = PaletteTheme.GreenLight
            };
            panel.Controls.Add(new Label { Text = title, AutoSize = true, ForeColor = PaletteTheme.GreenDark, Font = new Font("Segoe UI Semibold", 9.5f) });
            panel.Controls.Add(new Label { Text = description, AutoSize = true, MaximumSize = new Size(360, 0), ForeColor = Color.FromArgb(65, 80, 88), Margin = new Padding(3, 0, 3, 5) });
            return panel;
        }

        private void AddRouteCommandButton(Control parent, string command, string text, int width)
        {
            string cmd = command;
            var button = Btn(text, (s, e) => SendCmd(cmd));
            button.Width = width;
            button.TextAlign = ContentAlignment.MiddleLeft;
            parent.Controls.Add(button);
        }

        private void ExportSignReport()
        {
            if (!NeedDoc()) return;
            string project = Path.GetFileNameWithoutExtension(SafeName(_doc));
            var source = _svc.GetObjects()
                .Where(x => string.Equals(x.Value.Get(ObjFields.Group), "BIEN_BAO", StringComparison.OrdinalIgnoreCase))
                .OrderBy(x => x.Value.Get(ObjFields.ChainageM) == "" ? double.MaxValue : ParseDouble(x.Value.Get(ObjFields.ChainageM)))
                .ThenBy(x => x.Key, StringComparer.OrdinalIgnoreCase)
                .ToList();
            var rows = new List<SignReportRow>();
            int number = 1;
            foreach (var pair in source)
            {
                var record = pair.Value;
                string code = record.Get(ObjFields.Code);
                var sign = TdtSignLibrary.Find(code);
                string description = record.Get(ObjFields.Desc);
                if (string.IsNullOrWhiteSpace(description) && sign != null) description = sign.Description;
                rows.Add(new SignReportRow
                {
                    Number = number++,
                    Project = project,
                    Segment = record.Get(ObjFields.Segment),
                    Package = record.Get(ObjFields.Package),
                    SignGroup = sign == null || string.IsNullOrWhiteSpace(sign.Group) ? "Biển báo" : sign.Group,
                    Code = code,
                    Description = description,
                    Side = DisplaySide(record.Get(ObjFields.RoadSide) == "" ? record.Get(ObjFields.RouteSide) : record.Get(ObjFields.RoadSide)),
                    Chainage = record.Get(ObjFields.ChainageKm),
                    Route = record.Get(ObjFields.RouteId),
                    Offset = record.Get(ObjFields.OffsetM),
                    StationSource = record.Get(ObjFields.KmSource),
                    StationStatus = record.Get(ObjFields.StationStatus) == "" ? record.Get(ObjFields.KmState) : record.Get(ObjFields.StationStatus),
                    RouteRevision = record.Get(ObjFields.StationRouteRevision),
                    Condition = record.Get(ObjFields.Condition),
                    PoleCount = record.Get(ObjFields.PoleCount),
                    FaceCount = record.Get(ObjFields.FaceCount),
                    Checked = record.Get(ObjFields.CheckState) == "DA_KIEM_TRA" ? "Đã kiểm tra" : "Chưa kiểm tra",
                    Note = record.Get(ObjFields.Note),
                    ObjectId = pair.Key
                });
            }

            using (var dialog = new SaveFileDialog())
            {
                dialog.Title = "Xuất báo cáo biển báo BHT";
                dialog.Filter = "Excel Workbook (*.xlsx)|*.xlsx";
                dialog.DefaultExt = "xlsx";
                dialog.AddExtension = true;
                dialog.FileName = "BHT_BAO_CAO_BIEN_BAO_" + (project == "" ? "BAN_VE" : project) + ".xlsx";
                string folder = CurrentDwgPrefix();
                if (!string.IsNullOrEmpty(folder) && Directory.Exists(folder)) dialog.InitialDirectory = folder;
                if (dialog.ShowDialog() != DialogResult.OK) return;
                try
                {
                    SignReportWorkbook.Write(dialog.FileName, project, rows);
                    Status("Đã xuất " + rows.Count + " biển báo: " + dialog.FileName);
                    ShowReportDialog("Xuất báo cáo biển báo",
                        "Đã tạo tệp Excel UTF-8/Unicode:\r\n" + dialog.FileName
                        + "\r\n\r\nSố hồ sơ biển báo: " + rows.Count
                        + "\r\nTrang Tổng hợp: đếm theo mã và tình trạng."
                        + "\r\nTrang Danh sách biển: công trình, đoạn tuyến, loại biển, phía, lý trình, tuyến, offset, nguồn/trạng thái lý trình, route revision, tình trạng và ghi chú.");
                }
                catch (Exception ex) { StatusError("Lỗi xuất Excel: " + ex.Message); }
            }
        }

        private static double ParseDouble(string value)
        {
            double number;
            return double.TryParse(value, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out number)
                ? number : double.MaxValue;
        }

        private static string DisplaySide(string value)
        {
            switch ((value ?? "").ToUpperInvariant())
            {
                case "TRAI": return "Trái";
                case "PHAI": return "Phải";
                case "HAI_BEN": return "Hai bên";
                case "TREN_TUYEN": return "Trên tuyến";
                default: return "Chưa xác định";
            }
        }
    }
}
