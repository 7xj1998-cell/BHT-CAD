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
        // ================================================================ C. ANH TIMEMARK
        private TabPage _tabPhotos;
        private ListBox _phList;
        private PictureBox _phPic;
        private TextBox _phInfo;
        private ComboBox _phObj;
        private Label _phFilter;
        private SurveyPoint _photoFilterPoint;
        private Dictionary<string, BhtRecord> _photos = new Dictionary<string, BhtRecord>();

        private TabPage BuildPhotosTab()
        {
            var tp = new TabPage("Ảnh hiện\u00A0trường") { ToolTipText = "Ảnh hiện trường (KMZ / TimeMark): xem ảnh, gắn / bỏ gắn ảnh với hồ sơ, đồng bộ ký hiệu ảnh" };
            _tabPhotos = tp;
            var layout = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 1, RowCount = 7, Padding = new Padding(3) };
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 22));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 28));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 42));
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 30));

            _phList = new ListBox { Dock = DockStyle.Fill, IntegralHeight = false };
            _phList.SelectedIndexChanged += (s, e) => ShowPhoto();
            _phFilter = new Label { Dock = DockStyle.Fill, ForeColor = Color.DarkBlue, AutoEllipsis = true };
            var nav = Flow();
            nav.Dock = DockStyle.Fill;
            nav.Controls.Add(Btn("◀ Trước", (s, e) => StepPhoto(-1)));
            nav.Controls.Add(Btn("Sau ▶", (s, e) => StepPhoto(1)));
            nav.Controls.Add(Btn("Bỏ lọc", (s, e) => { _photoFilterPoint = null; FillPhotoList(); }));
            nav.Controls.Add(Btn("Nhập KMZ", (s, e) => SendCmd("BHTKMZ")));
            nav.Controls.Add(Btn("Chỉ thư mục ảnh", (s, e) => SendCmd("BHTTHUMUCANH")));

            _phPic = new PictureBox { Dock = DockStyle.Fill, SizeMode = PictureBoxSizeMode.Zoom, BackColor = Color.Black };
            _phPic.DoubleClick += (s, e) => OpenPhotoExternal();
            _phInfo = new TextBox { Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Vertical, Dock = DockStyle.Fill, Font = new Font("Consolas", 8.5f) };
            var linkRow = new TableLayoutPanel { Dock = DockStyle.Fill, AutoSize = true, ColumnCount = 2 };
            linkRow.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            linkRow.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            _phObj = new ComboBox { Dock = DockStyle.Fill, DropDownStyle = ComboBoxStyle.DropDownList };
            linkRow.Controls.Add(_phObj, 0, 0);
            linkRow.Controls.Add(Btn("Xác nhận gắn", (s, e) => LinkCurrentPhoto()), 1, 0);
            var act = Flow(); act.Dock = DockStyle.Fill;
            act.Controls.Add(Btn("Thu phóng vị trí chụp", (s, e) => ZoomPhoto()));
            act.Controls.Add(Btn("Bỏ gắn", (s, e) => UnlinkCurrentPhoto()));
            act.Controls.Add(Btn("Mở ảnh gốc", (s, e) => OpenPhotoExternal()));
            act.Controls.Add(Btn("Thông tin", (s, e) =>
            {
                var id = CurrentPhotoId(); if (id == null) return;
                CallLisp("bht:api-info-photo", new[] { id }, "Thông tin ảnh " + id, r => { if (r.Ok) _phInfo.Text = string.Join("\r\n", r.Values.ToArray()); });
            }));
            act.Controls.Add(Btn("Đồng bộ ký hiệu ảnh", (s, e) => CallLisp("bht:api-photo-sync", new string[0], "Đồng bộ ký hiệu ảnh", null)));
            layout.Controls.Add(nav, 0, 0);
            layout.Controls.Add(_phFilter, 0, 1);
            layout.Controls.Add(_phList, 0, 2);
            layout.Controls.Add(_phPic, 0, 3);
            layout.Controls.Add(linkRow, 0, 4);
            layout.Controls.Add(act, 0, 5);
            layout.Controls.Add(_phInfo, 0, 6);
            tp.Controls.Add(layout);
            return tp;
        }

        private void RefreshPhotos()
        {
            string keep = CurrentPhotoId();
            _photos = _svc.GetPhotos();
            FillPhotoList();
            if (keep != null) SelectPhoto(keep);
            else if (_phList.Items.Count > 0) _phList.SelectedIndex = 0;
        }

        private void FillPhotoList()
        {
            if (_phList == null) return;
            IEnumerable<string> ids;
            if (_photoFilterPoint != null)
            {
                var r = ObjectLogic.ParseIntLikeLisp(_svc == null ? "10" : _svc.Meta("ghep_r", "10"));
                var near = Geo.PhotosNear(_photoFilterPoint.X, _photoFilterPoint.Y, _photos, r > 0 ? r : 10);
                ids = near.Select(n => n.Item);
                _phFilter.Text = "Ảnh chụp gần điểm " + _photoFilterPoint.Name + " (" + near.Count + ", chỉ gợi ý)";
            }
            else
            {
                ids = _photos.Keys.OrderBy(k => k, StringComparer.Ordinal);
                _phFilter.Text = "Tất cả ảnh: " + _photos.Count;
            }
            _phList.BeginUpdate();
            _phList.Items.Clear();
            foreach (var id in ids)
            {
                var rec = _photos[id];
                string st = rec.Get(PhotoFields.State);
                string gps = PhotoLogic.GpsValid(rec) ? "" : " [GPS 0,0]";
                _phList.Items.Add(new PhotoItem(id, id + "  " + (st == "" ? "CHUA_GHEP" : st) + gps));
            }
            if (_phList.Items.Count == 0)
            {
                string empty = _photoFilterPoint == null
                    ? "(chưa có ảnh — bấm Nhập KMZ ở phía trên)"
                    : "(không có ảnh gần điểm — bấm Bỏ lọc để xem tất cả)";
                _phList.Items.Add(new PhotoItem(null, empty));
            }
            _phList.EndUpdate();
        }

        private sealed class PhotoItem
        {
            public readonly string Id; private readonly string _t;
            public PhotoItem(string id, string t) { Id = id; _t = t; }
            public override string ToString() { return _t; }
        }

        private string CurrentPhotoId()
        {
            var it = _phList == null ? null : _phList.SelectedItem as PhotoItem;
            return it == null ? null : it.Id;
        }

        private void SelectPhoto(string id)
        {
            string u = (id ?? "").ToUpperInvariant();
            for (int pass = 0; pass < 2; pass++)
            {
                for (int i = 0; i < _phList.Items.Count; i++)
                    if (string.Equals(((PhotoItem)_phList.Items[i]).Id, u, StringComparison.OrdinalIgnoreCase)) { _phList.SelectedIndex = i; return; }
                if (_photoFilterPoint == null) break;
                _photoFilterPoint = null; FillPhotoList();
            }
            Status("Không có ảnh " + id + " trong danh sách.");
        }

        private void StepPhoto(int d)
        {
            if (_phList.Items.Count == 0) return;
            int i = _phList.SelectedIndex + d;
            if (i < 0) i = 0; if (i >= _phList.Items.Count) i = _phList.Items.Count - 1;
            _phList.SelectedIndex = i;
        }

        private void ShowImage(Image img)
        {
            if (_phPic == null) return;
            var old = _phPic.Image;
            _phPic.Image = img;
            if (old != null) old.Dispose();
        }

        /// <summary>Doc JPG vao bo nho (khong khoa tep), thu nho toi da 1600 px de tiet kiem RAM.</summary>
        private static Image LoadPreview(string path)
        {
            byte[] bytes = File.ReadAllBytes(path);
            using (var ms = new MemoryStream(bytes))
            using (var src = Image.FromStream(ms))
            {
                ApplyExifOrientation(src);
                double k = Math.Min(1.0, 1600.0 / Math.Max(src.Width, src.Height));
                int w = Math.Max(1, (int)(src.Width * k)), h = Math.Max(1, (int)(src.Height * k));
                var bmp = new Bitmap(w, h);
                using (var g = Graphics.FromImage(bmp))
                {
                    g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                    g.DrawImage(src, 0, 0, w, h);
                }
                return bmp;
            }
        }

        private static void ApplyExifOrientation(Image img)
        {
            try
            {
                if (!img.PropertyIdList.Contains(0x0112)) return;
                int o = img.GetPropertyItem(0x0112).Value[0];
                RotateFlipType t = RotateFlipType.RotateNoneFlipNone;
                if (o == 3) t = RotateFlipType.Rotate180FlipNone;
                else if (o == 6) t = RotateFlipType.Rotate90FlipNone;
                else if (o == 8) t = RotateFlipType.Rotate270FlipNone;
                if (t != RotateFlipType.RotateNoneFlipNone) img.RotateFlip(t);
            }
            catch { }
        }

        private void ShowPhoto()
        {
            var id = CurrentPhotoId();
            if (id == null || _svc == null)
            {
                ShowImage(null);
                if (_phObj != null) _phObj.Items.Clear();
                _phInfo.Text = _photos.Count == 0
                    ? "Chưa có dữ liệu ảnh. Bấm Nhập KMZ để giải nén ảnh TimeMark và nạp BHT_PHOTO.tsv.\r\nNếu đã di chuyển thư mục JPG, bấm Chỉ thư mục ảnh."
                    : "Không có ảnh trong bộ lọc hiện tại. Bấm Bỏ lọc để xem toàn bộ ảnh.";
                return;
            }
            BhtRecord rec;
            if (!_photos.TryGetValue(id, out rec)) return;
            string path = _svc.ResolvePhotoPath(id);
            try { ShowImage(path != null ? LoadPreview(path) : null); }
            catch (Exception ex) { ShowImage(null); Status("Không đọc được JPG: " + ex.Message); }

            var sb = new StringBuilder();
            sb.Append(id).Append(" | ").Append(rec.Get(PhotoFields.Time)).Append(" | ").Append(rec.Get(PhotoFields.Name)).Append("\r\n");
            double e, n;
            bool shot = PhotoLogic.ShotEN(rec, out e, out n);
            if (!PhotoLogic.GpsValid(rec)) sb.Append("GPS: 0,0 / không có -> KHÔNG đặt ký hiệu; chỉ gắn thủ công.\r\n");
            else sb.Append("GPS (WGS84): ").Append(rec.Get(PhotoFields.Lon)).Append(", ").Append(rec.Get(PhotoFields.Lat))
                   .Append(shot ? " | vị trí chụp E,N: " + rec.Get(PhotoFields.E) + ", " + rec.Get(PhotoFields.N) : " | chưa tính E,N (chạy Đồng bộ ký hiệu ảnh)").Append("\r\n");
            sb.Append("Trạng thái ghép: ").Append(rec.Get(PhotoFields.State) == "" ? "CHUA_GHEP" : rec.Get(PhotoFields.State)).Append("\r\n");
            var linked = rec.GetAll(PhotoFields.Objects);
            sb.Append("Đã xác nhận với hồ sơ: ").Append(linked.Count > 0 ? string.Join(", ", linked.ToArray()) : "(chưa)").Append("\r\n");
            var sug = rec.GetAll(PhotoFields.Suggest);
            if (sug.Count > 0) sb.Append("Đề xuất (CHƯA xác nhận): ").Append(string.Join("; ", sug.Select(x => x.Replace("|", " ") + "m").ToArray())).Append("\r\n");
            var objChoices = new List<string>();
            foreach (var s in sug) { var t = s.Split('|')[0]; if (t.StartsWith("O:")) objChoices.Add(t.Substring(2)); }
            if (shot)
            {
                var r = ObjectLogic.ParseIntLikeLisp(_svc.Meta("ghep_r", "10"));
                var near = Geo.PointsNear(e, n, _points, r > 0 ? r : 10, 8);
                sb.Append("Điểm RTK gần vị trí chụp (chỉ gợi ý, GPS ảnh KHÔNG thay tọa độ RTK):\r\n");
                if (near.Count == 0) sb.Append("  (không có trong bán kính)\r\n");
                foreach (var nb in near)
                {
                    List<string> ow;
                    bool has = _owners.TryGetValue(nb.Item.IdUpper, out ow);
                    sb.Append("  ").Append(LispFormat.Fnum(nb.Distance, 2)).Append(" m  ").Append(nb.Item.Name).Append("  [").Append(nb.Item.Description).Append("]")
                      .Append(has ? "  hồ sơ " + string.Join(",", ow.ToArray()) : "  (chưa có hồ sơ)").Append("\r\n");
                    if (has) foreach (var o in ow) if (!objChoices.Contains(o)) objChoices.Add(o);
                }
            }
            sb.Append(path != null ? "JPG: " + path : "THIẾU FILE JPG (" + rec.Get(PhotoFields.RelPath) + ") - dùng BHTTHUMUCANH để chỉ lại thư mục ảnh.");
            _phInfo.Text = sb.ToString();

            _phObj.Items.Clear();
            foreach (var o in objChoices) _phObj.Items.Add(o + "  (gợi ý)");
            foreach (var o in _svc.GetObjects().Keys.OrderBy(k => k, StringComparer.Ordinal)) if (!objChoices.Contains(o)) _phObj.Items.Add(o);
            _phObj.SelectedIndex = -1; // KHONG chon san - nguoi dung phai chon
        }

        private string ChosenObject()
        {
            var s = _phObj.SelectedItem as string;
            if (string.IsNullOrEmpty(s)) return null;
            return s.Split(' ')[0];
        }

        private void LinkCurrentPhoto()
        {
            var pid = CurrentPhotoId(); var oid = ChosenObject();
            if (pid == null || oid == null) { Status("Chọn ảnh và chọn hồ sơ đối tượng cần gắn."); return; }
            if (!NeedDoc()) return;
            if (MessageBox.Show(this, "Xác nhận ảnh " + pid + " là ảnh của hồ sơ " + oid + "?\n(Đề xuất theo khoảng cách chỉ là gợi ý; chỉ gắn khi bạn đã nhìn ảnh và chắc chắn.)",
                                "BHT - xác nhận gắn ảnh", MessageBoxButtons.YesNo, MessageBoxIcon.Question, MessageBoxDefaultButton.Button2) != DialogResult.Yes) return;
            var r = AcadDispatcher.RunWrite(_doc, "Gắn ảnh", db => _svc.LinkPhoto(pid, oid, "THU_CONG"));
            StatusResult(r);
            RefreshAll();
        }

        private void UnlinkCurrentPhoto()
        {
            var pid = CurrentPhotoId();
            if (pid == null || !NeedDoc()) return;
            var linked = _photos.ContainsKey(pid) ? _photos[pid].GetAll(PhotoFields.Objects) : new List<string>();
            string oid = ChosenObject();
            if (oid == null && linked.Count == 1) oid = linked[0];
            if (oid == null || !linked.Contains(oid)) { Status("Chọn hồ sơ đang gắn với ảnh (" + string.Join(", ", linked.ToArray()) + ")."); return; }
            if (MessageBox.Show(this, "Bỏ gắn ảnh " + pid + " khỏi hồ sơ " + oid + "?", "BHT", MessageBoxButtons.YesNo, MessageBoxIcon.Question, MessageBoxDefaultButton.Button2) != DialogResult.Yes) return;
            StatusResult(AcadDispatcher.RunWrite(_doc, "Bỏ gắn ảnh", db => _svc.UnlinkPhoto(pid, oid)));
            RefreshAll();
        }

        private void ZoomPhoto()
        {
            var pid = CurrentPhotoId(); BhtRecord rec;
            if (pid == null || !_photos.TryGetValue(pid, out rec)) return;
            double e, n;
            if (!PhotoLogic.ShotEN(rec, out e, out n)) { Status("Ảnh không có vị trí chụp hợp lệ (GPS 0,0) - không thu phóng."); return; }
            HighlightAndZoom(null, e, n, 40.0);
        }

        private void OpenPhotoExternal()
        {
            var pid = CurrentPhotoId(); if (pid == null || _svc == null) return;
            var p = _svc.ResolvePhotoPath(pid);
            if (p == null) { Status("Không tìm thấy JPG của " + pid + "."); return; }
            try { System.Diagnostics.Process.Start(p); } catch (Exception ex) { StatusError("Không mở được: " + ex.Message); }
        }
    }
}
