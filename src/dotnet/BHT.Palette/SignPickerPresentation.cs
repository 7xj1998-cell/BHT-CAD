using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Windows.Forms;
using BHT.Bridge;
using BHT.Core;
namespace BHT.Palette
{
    public sealed partial class SignPickerForm
    {
        public string SelectedContent { get; private set; }
        public string SelectedLayout { get; private set; }
        public string SelectedGap { get; private set; }
        public string SelectedClearance { get; private set; }
        public void ConfigurePresentation(string content,string layout,string gap,string clearance)
        {
            SelectedContent=content ?? ""; SelectedLayout=string.IsNullOrEmpty(layout) ? "LEGACY" : layout;
            SelectedGap=string.IsNullOrEmpty(gap) ? "0.2" : gap; SelectedClearance=string.IsNullOrEmpty(clearance) ? "0.6" : clearance;
        }
        private List<string> PresentationCodes()
        { return multi.Checked && faces.Items.Count>0 ? faces.Items.Cast<string>().ToList() : new List<string> { CurrentCode() ?? "" }; }
        private void ReindexContent(int index,int target,bool remove)
        {
            var all=SignContent.Read(SelectedContent);
            if(remove) { all.RemoveAll(f=>f.Index==index); foreach(var f in all) if(f.Index>index) f.Index--; }
            else foreach(var f in all) { if(f.Index==index) f.Index=target; else if(f.Index==target) f.Index=index; }
            SelectedContent=SignContent.Write(all);
        }
        private string ValidatePresentation(IList<string> codes)
        {
            double gap,height;
            if(!Number(SelectedGap,out gap) || !Number(SelectedClearance,out height)) return "Khoảng cách và chiều cao đáy biển phải là số.";
            string error=SignLayoutSpec.Validate(SelectedLayout,codes.Count,gap,height); if(error!="") return error;
            for(int i=0;i<codes.Count;i++)
            {
                var fields=SignContentBlocks.Fields(codes[i]); var values=SignContent.ForFace(SelectedContent,i,codes[i]);
                foreach(var field in fields) if(IsPlace(field.Tag)) {
                    string value; if(!values.TryGetValue(field.Key,out value) || string.IsNullOrWhiteSpace(value)) return "Mặt "+(i+1)+" cần nội dung thực tế: "+field.Tag+". Mở Nội dung biển để nhập.";
                }
                foreach(var field in fields) {string value;if(values.TryGetValue(field.Key,out value))try{field.Parameter.Normalize(value);}catch(ArgumentException e){return "Mặt "+(i+1)+" / "+field.Label+": "+e.Message;}}
            }
            return "";
        }
        private static bool IsPlace(string tag)
        { string t=TextSearch.Fold(tag); return t.Contains("name") || t.Contains("dia") || t.Contains("ten") || t.Contains("dest") || t.Contains("location") || t.Contains("pagoda") || t=="start" || t=="end"; }
        private static bool Number(string text,out double value)
        { return double.TryParse(text.Replace(',','.'),NumberStyles.Float,CultureInfo.InvariantCulture,out value); }
        // Legacy code parameters are edited in the same table, then persisted in their original format.
        private List<SignContentField> EditorFields(string code)
        {
            var result=SignContentBlocks.Fields(code);
            Action<string,string,string,SignParameter> add=(key,label,value,param)=>result.Insert(0,new SignContentField {Key="@"+key,Tag=label,Sample=value,Parameter=param});
            string baseCode=SignPresentation.BaseCode(code);
            string speedBase=SignPresentation.SpeedBase(code);
            if(speedBase!="") add("speed","Tốc độ (km/h)",(SignPresentation.Speed(code,"") ?? (speedBase=="R.306" ? 30 : 50)).ToString(),new SignParameter {Kind="number",Integer=true,Minimum=5,Maximum=130,Label="Tốc độ"});
            if(SignPresentation.HasWeight(code)) add("weight","Tải trọng (tấn)",SignPresentation.WeightValue(code),new SignParameter {Kind="number",Minimum=0.001,Maximum=100000,Label="Tải trọng"});
            if(SignPresentation.MetreDefault(code)!="") add("metres","Giá trị thực tế (m)",SignPresentation.MetreValue(code)=="" ? SignPresentation.MetreDefault(code) : SignPresentation.MetreValue(code),new SignParameter {Kind="number",Minimum=0.001,Maximum=100000,Label="Giá trị"});
            if(SignPresentation.HasZoneTime(code)) add("hours","Giờ áp dụng",SignPresentation.ZoneTime(code),new SignParameter {Kind="time",Label="Giờ"});
            if(baseCode=="I.439") {
                add("road","Tên đường",bridgeRoad.Text,new SignParameter());
                add("station","Lý trình trên biển",bridgeStation.Text,new SignParameter());
                add("bridge","Tên cầu",bridgeName.Text,new SignParameter());
            }
            return result;
        }
        private void AdoptEditorCode(string code)
        {
            speed.Text=SignPresentation.Speed(code,"").HasValue ? SignPresentation.Speed(code,"").Value.ToString() : "";
            weight.Text=SignPresentation.WeightValue(code);
            metres.Text=SignPresentation.MetreValue(code)=="" ? SignPresentation.MetreDefault(code) : SignPresentation.MetreValue(code);
            zoneHours.Text=SignPresentation.ZoneTime(code);
        }
        private void EditPresentation()
        {
            try { EditPresentationCore(); }
            catch(Exception e) { validation.Text="Không đọc được nội dung biển: "+e.Message; }
        }
        private void EditPresentationCore()
        {
            var codes=PresentationCodes(); if(codes.Any(string.IsNullOrEmpty)) { validation.Text="Chọn biển hoặc thêm các mặt trước khi bố trí."; return; }
            using(var dialog=new Form { Text="Nội dung biển", Size=new Size(920,700),MinimumSize=new Size(820,620),StartPosition=FormStartPosition.CenterParent,Font=Font,ShowInTaskbar=false })
            {
                var layout=new ComboBox { DropDownStyle=ComboBoxStyle.DropDownList,Width=235 }; layout.Items.AddRange(SignLayoutSpec.All); layout.SelectedItem=SignLayoutSpec.Find(SelectedLayout);
                var gap=new TextBox { Text=SelectedGap,Width=65 }; var height=new TextBox { Text=SelectedClearance,Width=65 };
                var settings=new FlowLayoutPanel { Dock=DockStyle.Top,Height=68,Padding=new Padding(8) };
                settings.Controls.AddRange(new Control[] { new Label { Text="Bố trí:",AutoSize=true },layout,new Label { Text="Cách mặt:",AutoSize=true },gap,new Label { Text="Cao đáy:",AutoSize=true },height,new Label { Text="Đơn vị CAD trước khi nhân tỷ lệ ký hiệu; đây là bố trí trình bày 2D.",AutoSize=true } });
                var picture=new Panel { Dock=DockStyle.Top,Height=185,BackColor=Color.White };
                var advanced=new CheckBox { Text="Bố trí khung/trụ nâng cao…", Dock=DockStyle.Top,Height=32,Checked=SelectedLayout!="LEGACY",Padding=new Padding(8,0,0,0) };
                settings.Visible=picture.Visible=advanced.Checked;
                advanced.CheckedChanged+=(s,e)=> { settings.Visible=picture.Visible=advanced.Checked; if(!advanced.Checked) layout.SelectedItem=SignLayoutSpec.Find("LEGACY"); };
                var table=new DataGridView { Dock=DockStyle.Fill,AllowUserToAddRows=false,AllowUserToDeleteRows=false,RowHeadersVisible=false,AutoSizeColumnsMode=DataGridViewAutoSizeColumnsMode.Fill };
                table.Columns.Add("face","Mặt / mã"); table.Columns.Add("tag","Trường"); table.Columns.Add("value","Nội dung hồ sơ"); table.Columns.Add("sample","Chữ mẫu tham khảo");
                table.Columns[0].ReadOnly=table.Columns[1].ReadOnly=table.Columns[3].ReadOnly=true;
                var fieldsByRow=new List<Tuple<int,string,SignContentField>>();
                for(int i=0;i<codes.Count;i++)
                {
                    var values=SignContent.ForFace(SelectedContent,i,codes[i]);
                    foreach(var field in EditorFields(codes[i]))
                    {
                        string value; if(!values.TryGetValue(field.Key,out value)) value=field.Key.StartsWith("@") ? field.Sample : IsPlace(field.Tag) ? "" : field.Sample;
                        value=SignContentBlocks.ResolveContentValue(codes[i],field.Tag,value);
                        table.Rows.Add((i+1)+" / "+codes[i],field.Label,value,field.Sample); fieldsByRow.Add(Tuple.Create(i,codes[i],field));
                    }
                }
                var message=new Label { Dock=DockStyle.Bottom,Height=43,ForeColor=Color.Firebrick,Text="Nhập số, giờ, khoảng cách và địa danh theo hồ sơ. Giá trị số giữ đơn vị của mẫu; giờ có thể qua đêm. Mọi thông số được nhập tại bảng này. Biển không có nội dung thay đổi sẽ không có dòng nhập." };
                if(table.Rows.Count==0) {message.Text="Biển này không có chữ hoặc số cần thay đổi. Có thể chọn bố trí khung/trụ nâng cao nếu cần.";message.ForeColor=Color.DimGray;}
                var buttons=new FlowLayoutPanel { Dock=DockStyle.Bottom,Height=43 };
                var save=new Button { Text="Áp dụng",AutoSize=true }; var sample=new Button { Text="Dùng mẫu dòng chọn",AutoSize=true }; var cancel=new Button { Text="Đóng",DialogResult=DialogResult.Cancel };
                buttons.Controls.AddRange(new Control[] { save,sample,cancel });
                sample.Click+=(s,e)=> { foreach(DataGridViewRow row in table.SelectedRows) row.Cells[2].Value=row.Cells[3].Value; if(table.SelectedRows.Count==0 && table.CurrentRow!=null) table.CurrentRow.Cells[2].Value=table.CurrentRow.Cells[3].Value; };
                Action refresh=()=>picture.Invalidate(); layout.SelectedIndexChanged+=(s,e)=>refresh(); gap.TextChanged+=(s,e)=>refresh(); height.TextChanged+=(s,e)=>refresh();
                picture.Paint+=(s,e)=> {
                    if(!advanced.Checked) return;
                    double g,h; if(!Number(gap.Text,out g)||!Number(height.Text,out h)) return;
                    var spec=(SignLayoutSpec)layout.SelectedItem; if(SignLayoutSpec.Validate(spec.Code,codes.Count,g,h)!="") return;
                    var boxes=SignLayoutSpec.Arrange(spec.Code,codes.Select(c=>new SignPlateBox(0,0,1,.65)).ToList(),g,h);
                    double left=Math.Min(0,boxes.Min(b=>b.Left))-.4,right=boxes.Max(b=>b.Right)+.4,top=boxes.Max(b=>b.Top)+.3;
                    float scale=(float)Math.Min((picture.Width-40)/(right-left),(picture.Height-20)/top);
                    Func<double,float> x=v=>20+(float)(v-left)*scale; Func<double,float> y=v=>picture.Height-10-(float)v*scale;
                    using(var pen=new Pen(Color.DimGray,2)) {
                        double[] posts=spec.Code=="CAP1_9" ? new[] { boxes.Min(b=>b.Left)-.25,boxes.Max(b=>b.Right)+.25 } : spec.Posts==2 ? new[] { -.3,.3 } : new[] { 0.0 };
                        bool frame=spec.Code=="CAP1_9"||spec.Code=="CAP1_10";
                        foreach(double p in posts) e.Graphics.DrawLine(pen,x(p),y(0),x(p),y(frame ? top-.15 : h));
                        if(frame) e.Graphics.DrawLine(pen,x(posts.Min()),y(top-.15),x(spec.Code=="CAP1_10" ? right-.25 : posts.Max()),y(top-.15));
                        else if(boxes.Count>1) e.Graphics.DrawLine(pen,x(boxes.Min(b=>b.Left)),y(h-.04),x(boxes.Max(b=>b.Right)),y(h-.04));
                    }
                    for(int i=0;i<boxes.Count;i++) { var b=boxes[i]; var rect=new RectangleF(x(b.Left),y(b.Top),(float)b.Width*scale,(float)b.Height*scale); e.Graphics.FillRectangle(Brushes.RoyalBlue,rect); e.Graphics.DrawString((i+1)+". "+codes[i],Font,Brushes.White,rect); }
                };
                save.Click+=(s,e)=> {
                    table.EndEdit();
                    if (table.Rows.Cast<DataGridViewRow>().Any(row=>Convert.ToString(row.Cells[2].Value).Trim().Length>160)) { message.Text="Mỗi trường nội dung tối đa 160 ký tự. Rút gọn chữ rồi áp dụng lại."; return; }
                    double g,h;
                    if(!Number(gap.Text,out g)||!Number(height.Text,out h)) { message.Text="Nhập khoảng cách và chiều cao bằng số."; return; }
                    string error=SignLayoutSpec.Validate(((SignLayoutSpec)layout.SelectedItem).Code,codes.Count,g,h); if(error!="") { message.Text=error; return; }
                    var all=new List<SignContentFace>();
                    var nextCodes=new List<string>(codes);
                    string nextBridge=bridgeName.Text,nextStation=bridgeStation.Text,nextRoad=bridgeRoad.Text;
                    for(int r=0;r<fieldsByRow.Count;r++) {
                        var f=fieldsByRow[r];string value;
                        try {value=f.Item3.Parameter.Normalize(SignContentBlocks.ResolveContentValue(f.Item2,f.Item3.Tag,Convert.ToString(table.Rows[r].Cells[2].Value)));}
                        catch(ArgumentException ex){message.Text="Mặt "+(f.Item1+1)+" / "+f.Item3.Label+": "+ex.Message;table.CurrentCell=table.Rows[r].Cells[2];return;}
                        string key=f.Item3.Key;
                        if(key.StartsWith("@")) {
                            if(key=="@bridge") nextBridge=value;
                            else if(key=="@station") nextStation=value;
                            else if(key=="@road") nextRoad=value;
                            else if(key=="@speed") nextCodes[f.Item1]=SignPresentation.SpeedBase(f.Item2)+(value=="" ? "" : "-"+value);
                            else nextCodes[f.Item1]=SignPresentation.BaseCode(f.Item2)+(value=="" ? "" : "@"+value);
                        } else {
                            var face=all.FirstOrDefault(a=>a.Index==f.Item1);
                            if(face==null) {face=new SignContentFace {Index=f.Item1,Code=f.Item2};all.Add(face);}
                            face.Values[key]=value;
                        }
                    }
                    foreach(string code in nextCodes) {error=SignPresentation.ValidationError(code);if(error!=""){message.Text=error;return;}}
                    if(nextCodes.Contains("I.439")) {
                        double stationValue;
                        if(string.IsNullOrWhiteSpace(nextBridge)){message.Text="Nhập tên cầu thực tế.";return;}
                        if(nextStation!="" && !Chainage.TryParse(nextStation,out stationValue)){message.Text="Lý trình không hợp lệ; ví dụ Km252+831.";return;}
                    }
                    foreach(var face in all) face.Code=nextCodes[face.Index];
                    string xml=SignContent.Write(all); SignContent.Read(xml);
                    if(multi.Checked && faces.Items.Count>0) {int selected=faces.SelectedIndex;faces.Items.Clear();foreach(string code in nextCodes)faces.Items.Add(code);faces.SelectedIndex=selected;}
                    else AdoptEditorCode(nextCodes[0]);
                    bridgeName.Text=nextBridge;bridgeStation.Text=nextStation;bridgeRoad.Text=nextRoad;CaptureBridgeText();
                    SelectedContent=xml; SelectedLayout=((SignLayoutSpec)layout.SelectedItem).Code; SelectedGap=g.ToString("R",CultureInfo.InvariantCulture); SelectedClearance=h.ToString("R",CultureInfo.InvariantCulture);
                    dialog.DialogResult=DialogResult.OK; dialog.Close();
                };
                dialog.Controls.Add(table); dialog.Controls.Add(picture); dialog.Controls.Add(settings); dialog.Controls.Add(advanced); dialog.Controls.Add(message); dialog.Controls.Add(buttons); dialog.CancelButton=cancel;
                dialog.ShowDialog(this);
            }
        }
    }
}
