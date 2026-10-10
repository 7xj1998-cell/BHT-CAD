using System;
using System.Windows.Forms;

namespace BHT.Palette
{
    public partial class BhtPaletteControl
    {
        private Button _signScaleButton;

        private void RefreshSignScale()
        {
            if (_signScaleButton == null) return;
            _signScaleButton.Enabled = _doc != null && _lispOk && !_lispRunning;
            if (_svc == null) return;
            string symbol = _svc.Meta("sign_scale", _svc.Meta("kh_scale", "1"));
            string label = _svc.Meta("sign_label_scale", symbol);
            _objectTips.SetToolTip(_signScaleButton, "Hình biển × " + symbol + "; nhãn × " + label + ". Chọn riêng hai tỷ lệ, áp dụng cho biển báo, bảng chỉ dẫn, bảng quảng cáo và bảng thuộc nhóm Khác/Chưa xác định trong bản vẽ.");
        }

        private void ChooseSignScale()
        {
            if (_lispRunning || !NeedDoc() || !NeedLisp()) return;
            KeepObjectScroll(() => {
                string symbol = _svc.Meta("sign_scale", _svc.Meta("kh_scale", "1"));
                using (var options = new SignScaleForm(symbol, _svc.Meta("sign_label_scale", symbol)))
                {
                    if (options.ShowDialog(this) != DialogResult.OK) return;
                    CallLisp("bht:api-sign-scale", new[] { options.SymbolScale, options.LabelScale }, "Đổi tỷ lệ biển báo và nhãn", null);
                }
            });
        }
    }
}
