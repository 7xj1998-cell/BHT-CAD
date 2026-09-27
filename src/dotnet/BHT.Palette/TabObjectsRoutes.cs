using System;
using System.Collections.Generic;
using System.Drawing;
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
        private TextBox _oId, _oCode, _oDesc, _oPoles, _oFaces, _oFaceCodes, _oCond, _oNote, _oInfo;
        private ComboBox _oGroup, _oCodeType, _oSide;
        private CheckBox _oChecked, _oAllowShared;
        private ListBox _oPoints, _oPhotos;
        private Label _oBasis, _oMode;
        private bool _oIsNew;

        private TabPage BuildObjectsTab()
        {
            var tp = new TabPage("Hồ sơ");
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
            _oBasis = new Label { AutoSize = true, MaximumSize = new Size(300, 0), ForeColor = Color.DimGray };
            _oCode = new TextBox { Dock = DockStyle.Fill };
            _oCodeType = new ComboBox { Dock = DockStyle.Fill, DropDownStyle = ComboBoxStyle.DropDownList };
            _oCodeType.Items.AddRange(new object[] { "CHUA_XAC_DINH", "QCVN", "NOI_BO" });
            _oDesc = new TextBox { Dock = DockStyle.Fill };
            _oPoles = new TextBox { Dock = DockStyle.Fill };
            _oFaces = new TextBox { Dock = DockStyle.Fill };
            _oFaceCodes = new TextBox { Dock = DockStyle.Fill };
            _oCond = new TextBox { Dock = DockStyle.Fill };
            _oSide = new ComboBox { Dock = DockStyle.Fill, DropDownStyle = ComboBoxStyle.DropDownList };
            _oSide.Items.AddRange(new object[] { "CHUA_XAC_DINH", "TRAI", "PHAI", "HAI_BEN" });
            _oChecked = new CheckBox { Text = "Đã kiểm tra hiện trường", AutoSize = true };
            _oNote = new TextBox { Dock = DockStyle.Fill };
            _oPoints = new ListBox { Dock = DockStyle.Fill, Height = 60, SelectionMode = SelectionMode.MultiExtended, IntegralHeight = false };
            _oPhotos = new ListBox { Dock = DockStyle.Fill, Height = 45, IntegralHeight = false };
            _oPhotos.DoubleClick += (s, e) => { var p = _oPhotos.SelectedItem as string; if (p != null) { _tabs.SelectedTab = _tabPhotos; SelectPhoto(p.Split('|')[0]); } };
            _oAllowShared = new CheckBox { Text = "Cho phép tạo hồ sơ MỚI dùng chung điểm (sẽ hỏi xác nhận)", AutoSize = true };
            _oInfo = new TextBox { Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Vertical, Dock = DockStyle.Fill, Height = 70, Font = new Font("Consolas", 8.5f) };
            Action<string, Control> row = (t, c) => { form.Controls.Add(new Label { Text = t, AutoSize = true, Padding = new Padding(0, 5, 0, 0) }); form.Controls.Add(c); };
            form.Controls.Add(new Label()); form.Controls.Add(_oMode);
            row("ID", _oId); row("Nhóm", _oGroup); form.Controls.Add(new Label()); form.Controls.Add(_oBasis);
            row("Mã hiệu", _oCode); row("Loại mã", _oCodeType); row("Mô tả", _oDesc);
            row("Số trụ/chân", _oPoles); row("Số mặt biển", _oFaces); row("Mã các mặt", _oFaceCodes);
            row("Tình trạng", _oCond); row("Phía đường", _oSide); form.Controls.Add(new Label()); form.Controls.Add(_oChecked);
            row("Ghi chú", _oNote); row("Điểm RTK", _oPoints); row("Ảnh", _oPhotos); row("Lý trình", _oInfo);
            form.Controls.Add(new Label()); form.Controls.Add(_oAllowShared);

            var f1 = Flow();
            f1.Controls.Add(Btn("Chọn điểm trên CAD và tạo hồ sơ", (s, e) => PickSurveyPoints(NewObjectFromPoints)));
            f1.Controls.Add(Btn("Lưu", (s, e) => SaveObject()));
            f1.Controls.Add(Btn("Chèn/Cập nhật ký hiệu", (s, e) => SymbolForCurrent()));
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
            _oId.Text = ""; _oId.ReadOnly = false;
            _oGroup.SelectedIndex = Groups.All.Length - 1;
            _oBasis.Text = "";
            _oCode.Text = ""; _oCodeType.SelectedIndex = 0; _oDesc.Text = ""; _oPoles.Text = ""; _oFaces.Text = ""; _oFaceCodes.Text = "";
            _oCond.Text = ""; _oSide.SelectedIndex = 0; _oChecked.Checked = false; _oNote.Text = "";
            _oPoints.Items.Clear(); _oPhotos.Items.Clear(); _oInfo.Text = ""; _oAllowShared.Checked = false;
        }

        private static void SelectCombo(ComboBox c, string value)
        {
            for (int i = 0; i < c.Items.Count; i++)
                if (((string)c.Items[i]).Split(' ')[0] == value) { c.SelectedIndex = i; return; }
            if (!string.IsNullOrEmpty(value)) { c.Items.Add(value); c.SelectedIndex = c.Items.Count - 1; }
        }

        private void LoadObject(string oid)
        {
            if (_svc == null) return;
            var r = _svc.GetObject(oid);
            if (r == null) { Status("Không có hồ sơ " + oid); return; }
            _oIsNew = false;
            _oMode.Text = "SỬA HỒ SƠ " + oid.ToUpperInvariant();
            _oId.Text = oid.ToUpperInvariant(); _oId.ReadOnly = true;
            SelectCombo(_oGroup, r.Get(ObjFields.Group));
            _oBasis.Text = "";
            _oCode.Text = r.Get(ObjFields.Code); SelectCombo(_oCodeType, r.Get(ObjFields.CodeType) == "" ? "CHUA_XAC_DINH" : r.Get(ObjFields.CodeType));
            _oDesc.Text = r.Get(ObjFields.Desc); _oPoles.Text = r.Get(ObjFields.PoleCount); _oFaces.Text = r.Get(ObjFields.FaceCount);
            _oFaceCodes.Text = string.Join("; ", r.GetAll(ObjFields.Face).ToArray());
            _oCond.Text = r.Get(ObjFields.Condition); SelectCombo(_oSide, r.Get(ObjFields.RoadSide) == "" ? "CHUA_XAC_DINH" : r.Get(ObjFields.RoadSide));
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
            var km = new StringBuilder();
            if (r.Get(ObjFields.ChainageKm) != "") km.Append(r.Get(ObjFields.ChainageKm)).Append(" offset ").Append(r.Get(ObjFields.OffsetM)).Append(" m ").Append(r.Get(ObjFields.RouteSide));
            else km.Append("(chưa tính lý trình - ").Append(r.Get(ObjFields.KmState)).Append(")");
            km.Append("\r\nĐoạn/gói: ").Append(r.Get(ObjFields.Segment)).Append(" / ").Append(r.Get(ObjFields.Package))
              .Append("\r\nTạo ").Append(r.Get(ObjFields.CreatedAt)).Append(" | sửa ").Append(r.Get(ObjFields.ModifiedAt));
            _oInfo.Text = km.ToString();
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
            if (ids.Count == 0) { Status("Chưa chọn điểm RTK nào (chọn POINT/nhãn BHT trong CAD hoặc trong tab B)."); return; }
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
            _oBasis.Text = "Gợi ý nhóm: " + basis;
            if (pts.Count == 1) _oDesc.Text = pts[0].Description;
            _oMode.Text = "HỒ SƠ MỚI từ " + ids.Count + " điểm - kiểm tra nhóm rồi bấm Lưu";
            Status("Soạn hồ sơ mới. Nhóm chỉ là GỢI Ý từ mô tả gốc - hãy xác nhận.");
        }

        private BhtRecord EditorFields()
        {
            var f = new BhtRecord()
                .Add(ObjFields.Group, ((string)_oGroup.SelectedItem ?? "CHUA_XAC_DINH").Split(' ')[0])
                .Add(ObjFields.Code, _oCode.Text.Trim())
                .Add(ObjFields.CodeType, ((string)_oCodeType.SelectedItem ?? "CHUA_XAC_DINH"))
                .Add(ObjFields.Desc, _oDesc.Text)
                .Add(ObjFields.PoleCount, _oPoles.Text.Trim())
                .Add(ObjFields.FaceCount, _oFaces.Text.Trim())
                .Add(ObjFields.Condition, _oCond.Text)
                .Add(ObjFields.RoadSide, ((string)_oSide.SelectedItem ?? "CHUA_XAC_DINH"))
                .Add(ObjFields.CheckState, _oChecked.Checked ? "DA_KIEM_TRA" : "CHUA_KIEM_TRA")
                .Add(ObjFields.Note, _oNote.Text);
            foreach (var m in _oFaceCodes.Text.Split(';').Select(x => x.Trim()).Where(x => x != "")) f.Add(ObjFields.Face, m);
            return f;
        }

        private static bool IsCount(string s) { int n; return s == "" || (int.TryParse(s, out n) && n >= 0 && n <= 999); }

        private void SaveObject()
        {
            if (!NeedDoc()) return;
            if (!IsCount(_oPoles.Text.Trim()) || !IsCount(_oFaces.Text.Trim())) { Status("Số trụ / số mặt phải là số nguyên ≥ 0 (hoặc để trống)."); return; }
            var f = EditorFields();
            if (_oIsNew)
            {
                var ids = EditorPointIds();
                if (ids.Count == 0) { Status("Hồ sơ mới cần ít nhất 1 điểm RTK."); return; }
                List<string> hits, same;
                ObjectLogic.Overlap(ids, _svc.GetObjects(), out hits, out same);
                bool share = false;
                if (hits.Count > 0)
                {
                    if (!_oAllowShared.Checked) { Status("Điểm đã thuộc hồ sơ " + string.Join(", ", hits.ToArray()) + " - KHÔNG tạo (đánh dấu 'Cho phép dùng chung' nếu thật sự cần)."); return; }
                    if (MessageBox.Show(this, "Tạo hồ sơ MỚI dùng chung điểm với " + string.Join(", ", hits.ToArray()) + "?" +
                        (same.Count > 0 ? "\nCHÚ Ý: bộ điểm trùng khớp hồ sơ " + string.Join(", ", same.ToArray()) + "." : ""),
                        "BHT - xác nhận dùng chung điểm", MessageBoxButtons.YesNo, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2) != DialogResult.Yes)
                    { Status("Đã hủy - không tạo hồ sơ."); return; }
                    share = true;
                }
                string id = _oId.Text.Trim().ToUpperInvariant();
                var r = AcadDispatcher.RunWrite(_doc, "Tạo hồ sơ", db => _svc.CreateObject(id, f, ids, share));
                Status(r.Ok ? "Đã tạo hồ sơ " + r.Message + "." : r.ToString());
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
                Status(r.ToString());
                if (!r.Ok) return;
                RefreshAll();
                if (_lispOk) CallLisp("bht:api-symbol-sync", new[] { id }, "Cập nhật ký hiệu " + id, null); // chi cap nhat / tao theo object_id
            }
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
            Status(AcadDispatcher.RunWrite(_doc, "Thêm điểm", db => _svc.AddPoints(oid, ids)).ToString());
            RefreshAll();
        }

        private void RemoveListPoints()
        {
            var sel = _oPoints.SelectedItems.Cast<string>().Select(s => s.Split('|')[0].Trim()).ToList();
            if (sel.Count == 0) { Status("Chọn điểm trong danh sách Điểm RTK của hồ sơ."); return; }
            if (_oIsNew) { foreach (var s in _oPoints.SelectedItems.Cast<string>().ToList()) _oPoints.Items.Remove(s); return; }
            string oid = _oId.Text;
            if (MessageBox.Show(this, "Gỡ " + sel.Count + " điểm khỏi " + oid + "? (điểm RTK giữ nguyên)", "BHT", MessageBoxButtons.YesNo, MessageBoxIcon.Question, MessageBoxDefaultButton.Button2) != DialogResult.Yes) return;
            Status(AcadDispatcher.RunWrite(_doc, "Gỡ điểm", db => _svc.RemovePoints(oid, sel)).ToString());
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
            var tp = new TabPage("Tuyến");
            var f = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoScroll = true, Padding = new Padding(4) };
            f.Controls.Add(new Label { Text = "Các nút gửi lệnh Lisp BHT (tương tác ở dòng lệnh). 'Đã gửi' chưa phải 'xong':\npalette chờ AutoCAD báo lệnh kết thúc rồi đọc lại dữ liệu.", AutoSize = true, MaximumSize = new Size(380, 0) });
            string[][] cmds =
            {
                new[] { "BHTTUYEN", "Khai báo Polyline tuyến tham chiếu" },
                new[] { "BHTMOCKM", "Thêm mốc Km đã xác nhận" },
                new[] { "BHTDSMOC", "Xem / xóa mốc Km" },
                new[] { "BHTLYTRINH", "Tính lý trình / offset" },
                new[] { "BHTGOITHAU", "Nạp bảng gói thầu" },
                new[] { "BHTPHANDOAN", "Gán đoạn / gói tự động" },
                new[] { "BHTGANDOAN", "Gán đoạn thủ công" },
                new[] { "BHTXUAT", "Xuất CSV thống kê" },
                new[] { "BHTTRANGTHAI", "Trạng thái bản vẽ" },
                new[] { "BHTKT", "Kiểm tra toàn vẹn" },
                new[] { "BHTSAPNHAN", "Sắp xếp nhãn theo phạm vi" },
                new[] { "BHTTHUTUVE", "Thứ tự hiển thị" },
                new[] { "BHTGHEPANH", "Đề xuất ghép ảnh (chỉ đề xuất)" },
                new[] { "BHTTHUMUCANH", "Chỉ lại thư mục ảnh" }
            };
            foreach (var c in cmds)
            {
                string cmd = c[0];
                var b = Btn(c[0] + " - " + c[1], (s, e) => SendCmd(cmd));
                b.TextAlign = ContentAlignment.MiddleLeft;
                f.Controls.Add(b);
            }
            tp.Controls.Add(f);
            return tp;
        }
    }
}
