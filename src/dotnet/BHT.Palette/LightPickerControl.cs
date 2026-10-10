using System;
using System.IO;
using System.Drawing;
using System.Windows.Forms;
using BHT.Bridge;
using BHT.Core;
namespace BHT.Palette
{
    public partial class BhtPaletteControl
    {
        private Label _lightLabel;
        private Button _lightButton;
        private void RefreshLightChoice()
        {
            if(_lightButton==null || _oCustomBlock==null) return;
            _lightButton.Text="Chọn loại đèn…";
            foreach(string group in new[]{"DEN_CS","DEN_TH"})
                foreach(var model in LightModels.ForGroup(group))
                    if(_oCustomBlock.Text.IndexOf("BHT_LIGHT_"+model[0]+"_",StringComparison.OrdinalIgnoreCase)>=0)
                        _lightButton.Text=model[1]+" — đổi…";
            _lightButton.AutoSize=false; _lightButton.Dock=DockStyle.Fill; _lightButton.Height=52;
        }
        private void ChooseLight()
        {
            if(!NeedDoc()) return;
            string group=EditorGroup();
            using(var dialog=new Form {Text="Chọn loại đèn",Width=560,Height=265,StartPosition=FormStartPosition.CenterParent,MinimizeBox=false,MaximizeBox=false,FormBorderStyle=FormBorderStyle.FixedDialog})
            {
                var kind=new ComboBox {Left=18,Top=18,Width=505,DropDownStyle=ComboBoxStyle.DropDownList};
                kind.Items.Add(new CodeChoice("DEN_CS","Đèn chiếu sáng"));
                kind.Items.Add(new CodeChoice("DEN_TH","Đèn tín hiệu"));
                var model=new ComboBox {Left=18,Top=62,Width=505,DropDownStyle=ComboBoxStyle.DropDownList};
                var note=new Label {Left=18,Top=105,Width=505,Height=62,Text="Chọn mẫu để gán cho hồ sơ. Sau đó bấm Lưu hồ sơ và Chèn / cập nhật. Mẫu cần vươn theo kích thước riêng: dùng Block tùy chỉnh."};
                var apply=new Button {Text="Dùng mẫu này",Left=290,Top=177,Width=125};
                var cancel=new Button {Text="Đóng",Left=425,Top=177,Width=98,DialogResult=DialogResult.Cancel};
                Action populate=()=>{
                    model.Items.Clear();
                    foreach(var item in LightModels.ForGroup(ComboCode(kind))) model.Items.Add(new CodeChoice(item[0],item[1]));
                    model.SelectedIndex=0;
                    for(int i=0;i<model.Items.Count;i++)
                        if(_oCustomBlock.Text.IndexOf(((CodeChoice)model.Items[i]).Code+"_",StringComparison.OrdinalIgnoreCase)>=0) model.SelectedIndex=i;
                };
                kind.SelectedIndexChanged+=(s,e)=>populate();
                kind.SelectedIndex=group=="DEN_TH" ? 1 : 0;
                dialog.Controls.AddRange(new Control[]{kind,model,note,apply,cancel});
                dialog.CancelButton=cancel;
                apply.Click+=(s,e)=>{
                    string path=Path.Combine(CustomDwgBlock.LightFolder(),ComboCode(model)+".dwg");
                    if(!File.Exists(path)){MessageBox.Show(dialog,"Không tìm thấy mẫu đèn. Cài lại bộ thư viện BHT đầy đủ.");return;}
                    string selectedGroup=ComboCode(kind),oid=_oId.Text;
                    var document=_doc;
                    dialog.DialogResult=DialogResult.OK;dialog.Close();
                    AcadDispatcher.RunInCommandContext("Chọn mẫu đèn",()=>{
                        try{return OpResult.Success(CustomDwgBlock.Import(document.Database,path));}
                        catch(Exception ex){return OpResult.Fail("Không nạp được mẫu đèn: "+ex.Message);}
                    },result=>{
                        if(result.Ok && _doc==document && _oId.Text==oid){
                            SelectCombo(_oGroup,selectedGroup);
                            _oCustomBlock.Text=result.Message;
                            OnGroupChangedByUser();
                            Status("Đã chọn mẫu đèn. Bấm Lưu hồ sơ rồi Chèn / cập nhật.");
                        } else if(!result.Ok) StatusResult(result);
                    });
                };
                dialog.ShowDialog(this);
            }
        }
    }
}
