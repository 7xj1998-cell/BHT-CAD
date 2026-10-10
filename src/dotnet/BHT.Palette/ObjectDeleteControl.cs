using System;
using System.Windows.Forms;
using BHT.Core;

namespace BHT.Palette
{
    public partial class BhtPaletteControl
    {
        private void DeleteCurrentObject()
        {
            if (_oIsNew || _oId.Text.Trim()=="" || !NeedDoc() || !NeedLisp() || _lispRunning) return;
            string id=_oId.Text.Trim();
            if(MessageBox.Show(this,"Xóa hồ sơ "+id+" cùng ký hiệu, nhãn và đường nối?\r\nĐiểm RTK và ảnh gốc được giữ nguyên.","BHT — Xóa hồ sơ",MessageBoxButtons.YesNo,MessageBoxIcon.Warning,MessageBoxDefaultButton.Button2) != DialogResult.Yes) return;
            DeleteObjectById(id);
        }

        private void DeleteObjectById(string id)
        {
            var document=_doc;
            CallLisp("bht:api-object-delete",new[] {id},"Xóa hồ sơ "+id,reply => {
                if(reply.Ok && _doc==document && _oId.Text.Equals(id,StringComparison.OrdinalIgnoreCase))
                {
                    _objectDrafts.Remove(document);
                    ClearObjectEditor();
                    Status("Đã xóa hồ sơ "+id+" và ký hiệu. Điểm RTK và ảnh gốc giữ nguyên.");
                }
            });
        }
    }
}
