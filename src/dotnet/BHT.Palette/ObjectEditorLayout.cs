using System;
using System.Drawing;
using System.Windows.Forms;
using BHT.Core;

namespace BHT.Palette
{
    public partial class BhtPaletteControl
    {
        private ObjectFormPanel _objectForm;
        private Label _objectNameLabel;
        private int _objectLayoutDepth;

        private sealed class ObjectFormPanel : TableLayoutPanel
        {
            internal bool Updating;
            internal ObjectFormPanel() { DoubleBuffered = true; }
            protected override Point ScrollToControl(Control activeControl)
            {
                // Rebinding must not scroll to the field that had focus before CAD selection.
                return Updating ? DisplayRectangle.Location : base.ScrollToControl(activeControl);
            }
        }

        private void ChangeObjectEditor(Action change, bool startAtTop = false)
        {
            if (_objectForm == null) { change(); return; }
            bool outer = _objectLayoutDepth++ == 0;
            Point scroll = _objectForm.AutoScrollPosition;
            bool updating = _objectForm.Updating;
            if (outer) { _objectForm.Updating = true; _objectForm.SuspendLayout(); }
            try { change(); }
            finally
            {
                _objectLayoutDepth--;
                if (outer)
                {
                    _objectForm.ResumeLayout(true);
                    if (startAtTop) _oGroup.Focus();
                    _objectForm.AutoScrollPosition = startAtTop ? Point.Empty : new Point(-scroll.X, -scroll.Y);
                    _objectForm.Updating = updating;
                }
            }
        }

        private void KeepObjectScroll(Action action)
        {
            Point scroll = _objectForm.AutoScrollPosition;
            bool updating = _objectForm.Updating;
            _objectForm.Updating = true;
            try { action(); }
            finally
            {
                _objectForm.AutoScrollPosition = new Point(-scroll.X, -scroll.Y);
                _objectForm.Updating = updating;
            }
        }

        private void UpdateObjectGroupLayout()
        {
            ChangeObjectEditor(() => {
                string group = EditorGroup();
                if(_lightButton!=null) _lightButton.Visible=_lightLabel.Visible=group=="DEN" || group=="DEN_CS" || group=="DEN_TH";
                foreach (var control in _signRows) control.Visible = GroupRules.HasSignCode(group);
                foreach (var control in _markerRows) control.Visible = group == "COC_TIEU" || group == "COT_KM";
                bool namedBoard = group == "BANG_QC" || group == "KHAC";
                if (_objectNameLabel != null) _objectNameLabel.Text = namedBoard ? "Tên trên bảng" : "Mô tả";
                _objectTips.SetToolTip(_oDesc, namedBoard ? "Nhập tên hiển thị trên bảng chữ nhật nền xanh, chữ trắng. Block tùy chỉnh được ưu tiên nếu đã gán." : "Mô tả đối tượng khảo sát.");
                UpdateMarkerStation();
            });
        }
    }
}
