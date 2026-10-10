using System;
using System.IO;
using System.Windows.Forms;
using BHT.Bridge;
using BHT.Core;

namespace BHT.Palette
{
    public partial class BhtPaletteControl
    {
        private void ImportCustomDwg()
        {
            if(!NeedDoc()) return;
            string path;
            using(var dialog=new OpenFileDialog {Title="Nạp block DWG cho hồ sơ — thư viện đèn BHT",Filter="Block AutoCAD (*.dwg)|*.dwg",InitialDirectory=CustomDwgBlock.LightFolder()})
            {
                if(dialog.ShowDialog(this)!=DialogResult.OK) return;
                path=dialog.FileName;
            }
            var document=_doc;
            AcadDispatcher.RunInCommandContext("Nạp block DWG",()=> {
                try {return OpResult.Success(CustomDwgBlock.Import(document.Database,path));}
                catch(Exception ex){return OpResult.Fail("Không nạp được DWG: "+ex.Message);}
            },result=> {
                if(result.Ok && _doc==document)
                {
                    _oCustomBlock.Text=result.Message;
                    Status("Đã nạp "+Path.GetFileName(path)+". Bấm Lưu để gán cho hồ sơ, rồi Chèn / cập nhật ký hiệu.");
                }
                else StatusResult(result);
            });
        }
    }
}
