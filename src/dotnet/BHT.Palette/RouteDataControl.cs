using System;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using Autodesk.AutoCAD.DatabaseServices;
using BHT.Bridge;
using BHT.Core;
namespace BHT.Palette
{
    public partial class BhtPaletteControl
    {
        private ListView routeList;
        private bool refreshingRoutes;
        private ObjectId highlightedRoute=ObjectId.Null;
        private void ClearRouteHighlight()
        {
            if(highlightedRoute.IsNull)return;
            try {using(var tr=highlightedRoute.Database.TransactionManager.StartOpenCloseTransaction()) {var e=tr.GetObject(highlightedRoute,OpenMode.ForRead,false) as Entity;if(e!=null)e.Unhighlight();}} catch { }
            try { if(_doc!=null) { var selected=_doc.Editor.SelectImplied(); if(selected.Status==Autodesk.AutoCAD.EditorInput.PromptStatus.OK && selected.Value.Count==1 && selected.Value.GetObjectIds()[0]==highlightedRoute) _doc.Editor.SetImpliedSelection(new ObjectId[0]); } } catch { }
            highlightedRoute=ObjectId.Null;
        }
        private void HighlightSelectedRoute()
        {
            if(refreshingRoutes)return;
            ClearRouteHighlight();
            if(_tabs.SelectedIndex!=4 || _doc==null || routeList==null || routeList.SelectedItems.Count==0)return;
            string busy;if(AcadDispatcher.IsBusy(_doc,out busy))return;
            try {
                using(_doc.LockDocument()) using(var tr=_doc.Database.TransactionManager.StartOpenCloseTransaction()) {
                    var id=CadView.IdFromHandle(_doc.Database,Convert.ToString(routeList.SelectedItems[0].Tag));
                    if(id.IsNull)return;
                    var entity=tr.GetObject(id,OpenMode.ForRead) as Entity;
                    if(entity!=null){_doc.Editor.SetImpliedSelection(new[] {id});entity.Highlight();highlightedRoute=id;}
                }
            } catch(Exception ex){Status("Không làm sáng được tuyến: "+ex.Message);}
        }
        private void SelectedRouteCommand(string command)
        {
            if(routeList.SelectedItems.Count==0){Status("Chọn tuyến trong bảng trước.");return;}
            string id=routeList.SelectedItems[0].Text;
            CallLisp("bht:api-route-select",new[] {id},"Chọn tuyến",r=>{if(r.Ok)SendCmd(command);});
        }
        private Control BuildRouteData()
        {
            var panel=RouteSection("DỮ LIỆU TUYẾN", "Các tuyến đã nạp trong bản vẽ. Bấm chọn dòng để làm sáng tuyến trên CAD; nhấp đúp để zoom toàn tuyến.");
            routeList=new ListView {Width=365,Height=175,View=View.Details,FullRowSelect=true,MultiSelect=false,HideSelection=false};
            routeList.Columns.Add("Tuyến",95);routeList.Columns.Add("Nguồn",75);routeList.Columns.Add("Chiều dài",85);routeList.Columns.Add("Trạng thái",100);
            panel.Controls.Add(routeList);
            var row=new FlowLayoutPanel {AutoSize=true,Width=365};
            row.Controls.Add(Btn("Làm mới tuyến",(s,e)=>RefreshRouteData()));
            row.Controls.Add(Btn("Hiển thị / zoom tuyến",(s,e)=>ZoomSelectedRoute()));
            panel.Controls.Add(row);
            var edits=new FlowLayoutPanel {AutoSize=true,Width=365};
            edits.Controls.Add(Btn("Sửa tuyến…",(s,e)=>SelectedRouteCommand("BHTSUATUYEN")));
            edits.Controls.Add(Btn("Chọn lại tuyến…",(s,e)=>SelectedRouteCommand("BHTCHONLAITUYEN")));
            edits.Controls.Add(Btn("Xóa tuyến…",(s,e)=>SelectedRouteCommand("BHTXOATUYEN")));
            panel.Controls.Add(edits);
            routeList.SelectedIndexChanged+=(s,e)=>HighlightSelectedRoute();
            routeList.DoubleClick+=(s,e)=>ZoomSelectedRoute();
            return panel;
        }
        private void RefreshRouteData()
        {
            if(routeList==null) return;
            string selected=routeList.SelectedItems.Count==0 ? "" : routeList.SelectedItems[0].Text;
            refreshingRoutes=true;
            routeList.BeginUpdate();
            try {
                routeList.Items.Clear();if(_doc==null)return;
                using(var tr=_doc.Database.TransactionManager.StartOpenCloseTransaction())
                foreach(var pair in BhtStore.All(tr,_doc.Database,"ROUTE")) {
                    var id=CadView.IdFromHandle(_doc.Database,pair.Value.Get("handle"));
                    var curve=id.IsNull ? null : tr.GetObject(id,OpenMode.ForRead) as Curve;
                    string length="",state=curve==null ? "Thiếu hình học" : "Sẵn sàng";
                    if(curve!=null) try {length=(curve.GetDistanceAtParameter(curve.EndParam)-curve.GetDistanceAtParameter(curve.StartParam)).ToString("0.##");}catch {state="Kiểm tra hình học";}
                    var item=new ListViewItem(new[] {pair.Key,pair.Value.Get("nguon"),length,state}) {Tag=pair.Value.Get("handle")};
                    routeList.Items.Add(item);if(item.Text==selected)item.Selected=true;
                }
            } finally {routeList.EndUpdate();refreshingRoutes=false;HighlightSelectedRoute();}
        }
        private void ZoomSelectedRoute()
        {
            if(!NeedDoc() || routeList.SelectedItems.Count==0){Status("Chọn một tuyến trong bảng dữ liệu tuyến.");return;}
            var doc=_doc;string handle=Convert.ToString(routeList.SelectedItems[0].Tag);
            AcadDispatcher.RunInCommandContext("Hiển thị tuyến",()=> {
                if(_doc!=doc)return OpResult.Fail("Bản vẽ đã thay đổi.");
                return CadView.ShowRoute(doc,handle);
            },result=>{StatusResult(result);if(result.Ok)HighlightSelectedRoute();});
        }
    }
}
