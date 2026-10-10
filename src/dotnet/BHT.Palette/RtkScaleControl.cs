using System;
using System.Globalization;
using System.Linq;
using System.Windows.Forms;

namespace BHT.Palette
{
    public partial class BhtPaletteControl
    {
        private Button _rtkScaleButton, _rtkUpdateLabelsButton;

        private void UpdateRtkActionAvailability()
        {
            bool ready = _doc != null && _lispOk && !_lispRunning;
            if (_rtkScaleButton != null) _rtkScaleButton.Enabled = ready;
            if (_rtkUpdateLabelsButton != null) _rtkUpdateLabelsButton.Enabled = ready;
        }

        private void ChooseRtkScale()
        {
            if (_lispRunning || !NeedDoc() || !NeedLisp()) return;
            double height;
            if (!double.TryParse(_svc.Meta("nhan_h", "0.5"), NumberStyles.Float, CultureInfo.InvariantCulture, out height) || double.IsNaN(height) || double.IsInfinity(height) || height <= 0) height = 0.5;
            using (var options = new RtkScaleForm(_svc.Meta("pt_size", "1"), (height / 0.5).ToString("0.###", CultureInfo.InvariantCulture)))
            {
                if (options.ShowDialog(this) != DialogResult.OK) return;
                CallLisp("bht:api-rtk-scale", new[] { options.SymbolScale, options.LabelScale }, "Đổi tỷ lệ dấu X và nhãn RTK", null);
            }
        }

        private void UpdateRtkLabels()
        {
            var ids = SelectedListPointIds();
            CallLisp("bht:api-label-sync", new[] { ids.Count > 0 ? string.Join(",", ids.ToArray()) : "ALL" },
                ids.Count > 0 ? "Cập nhật nhãn " + ids.Count + " điểm RTK" : "Cập nhật tất cả nhãn RTK", null);
        }
    }
}
