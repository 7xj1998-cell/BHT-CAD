using System;using System.IO;using System.Linq;using System.Reflection;using System.Collections.Generic;using System.Windows.Forms;using Autodesk.AutoCAD.Runtime;using Autodesk.AutoCAD.DatabaseServices;using Autodesk.AutoCAD.Geometry;using BHT.Bridge;using BHT.Core;using BHT.Palette;using AcApp=Autodesk.AutoCAD.ApplicationServices.Core.Application;
public class RouteDataProbe {
static List<string> report=new List<string>();static void Check(string n,bool ok){report.Add((ok?"PASS ":"FAIL ")+n);}
[CommandMethod("BHTROUTEDATAPROBE")]public void Run(){try{
var doc=AcApp.DocumentManager.MdiActiveDocument;var db=doc.Database;string handle;ObjectId lineId,layerId;
using(var tr=db.TransactionManager.StartTransaction()){
var lt=(LayerTable)tr.GetObject(db.LayerTableId,OpenMode.ForWrite);var layer=new LayerTableRecord {Name="BHT_ROUTE_QA637",IsOff=true};layerId=lt.Add(layer);tr.AddNewlyCreatedDBObject(layer,true);
var bt=(BlockTable)tr.GetObject(db.BlockTableId,OpenMode.ForRead);var space=(BlockTableRecord)tr.GetObject(bt[BlockTableRecord.ModelSpace],OpenMode.ForWrite);
var line=new Polyline();line.AddVertexAt(0,new Point2d(500000,1100000),0,0,0);line.AddVertexAt(1,new Point2d(504000,1100200),0,0,0);line.LayerId=layerId;line.Visible=false;lineId=space.AppendEntity(line);tr.AddNewlyCreatedDBObject(line,true);handle=line.Handle.ToString();
BhtStore.Write(tr,db,"ROUTE","QA637",new BhtRecord().Set("handle",handle).Set("nguon","QA"));BhtStore.Write(tr,db,"ROUTE","QA637-MISSING",new BhtRecord().Set("handle","FFFFFFFFFFFFFF"));tr.Commit();}
using(var view=doc.Editor.GetCurrentView()){view.ViewTwist=.7;doc.Editor.SetCurrentView(view);}
Check("show-route-success",CadView.ShowRoute(doc,handle).Ok);
using(var tr=db.TransactionManager.StartOpenCloseTransaction()){
var line=(Entity)tr.GetObject(lineId,OpenMode.ForRead);Check("reveals-hidden-route-and-layer",line.Visible && !((LayerTableRecord)tr.GetObject(layerId,OpenMode.ForRead)).IsOff);
using(var view=doc.Editor.GetCurrentView()){
var b=line.GeometricExtents;var t=Matrix3d.PlaneToWorld(view.ViewDirection);t=Matrix3d.Displacement(view.Target-Point3d.Origin)*t;t=Matrix3d.Rotation(-view.ViewTwist,view.ViewDirection,view.Target)*t;b.TransformBy(t.Inverse());
Check("entire-route-fits-twisted-view",b.MinPoint.X>=view.CenterPoint.X-view.Width/2 && b.MaxPoint.X<=view.CenterPoint.X+view.Width/2 && b.MinPoint.Y>=view.CenterPoint.Y-view.Height/2 && b.MaxPoint.Y<=view.CenterPoint.Y+view.Height/2);}}
var originalLayer=db.Clayer;db.Clayer=layerId;
try { Check("route-on-current-layer",CadView.ShowRoute(doc,handle).Ok); }
catch(System.Exception ex) { report.Add("FAIL route-on-current-layer "+ex); }
db.Clayer=originalLayer;
using(var tr=db.TransactionManager.StartTransaction()) {
    var layer=(LayerTableRecord)tr.GetObject(layerId,OpenMode.ForWrite);layer.IsFrozen=true;layer.IsOff=true;
    tr.Commit();
}
Check("frozen-off-route-shown",CadView.ShowRoute(doc,handle).Ok);
using(var tr=db.TransactionManager.StartTransaction()) {
    var layer=(LayerTableRecord)tr.GetObject(layerId,OpenMode.ForWrite);
    Check("route-layer-thawed",!layer.IsFrozen && !layer.IsOff);
    ((Entity)tr.GetObject(lineId,OpenMode.ForWrite)).Visible=false;layer.IsLocked=true;tr.Commit();
}
Check("hidden-route-on-locked-layer",CadView.ShowRoute(doc,handle).Ok);
using(var tr=db.TransactionManager.StartOpenCloseTransaction()) {
    Check("preserves-layer-lock-and-shows-entity",((LayerTableRecord)tr.GetObject(layerId,OpenMode.ForRead)).IsLocked && ((Entity)tr.GetObject(lineId,OpenMode.ForRead)).Visible);
}
Check("preserves-current-layer",db.Clayer==originalLayer);

Check("missing-route-rejected",!CadView.ShowRoute(doc,"FFFFFFFFFFFFFF").Ok);
using(var editor=new BhtPaletteControl()){
var flags=BindingFlags.Instance|BindingFlags.NonPublic;typeof(BhtPaletteControl).GetField("_doc",flags).SetValue(editor,doc);
typeof(BhtPaletteControl).GetMethod("RefreshRouteData",flags).Invoke(editor,null);var list=(ListView)typeof(BhtPaletteControl).GetField("routeList",flags).GetValue(editor);
Check("table-includes-loaded-and-missing-routes",list.Items.Cast<ListViewItem>().Any(i=>i.Text=="QA637") && list.Items.Cast<ListViewItem>().Any(i=>i.Text=="QA637-MISSING" && i.SubItems[3].Text.Contains("Thiếu")));
Check("table-includes-real-test-route",list.Items.Cast<ListViewItem>().Any(i=>i.Text=="TUYEN1"));
var tabs=(TabControl)typeof(BhtPaletteControl).GetField("_tabs",flags).GetValue(editor);
var highlight=typeof(BhtPaletteControl).GetField("highlightedRoute",flags);
var tabHandle=tabs.Handle;tabs.SelectedIndex=4;
highlight.SetValue(editor,lineId);
tabs.SelectedIndex=0;
Check("switch-tab-clears-owned-highlight",((ObjectId)highlight.GetValue(editor)).IsNull);
highlight.SetValue(editor,lineId);
typeof(BhtPaletteControl).GetMethod("RefreshRouteData",flags).Invoke(editor,null);
Check("refresh-other-tab-does-not-restore-highlight",((ObjectId)highlight.GetValue(editor)).IsNull);
highlight.SetValue(editor,lineId);
editor.Unbind(false);
Check("unbind-clears-owned-highlight",((ObjectId)highlight.GetValue(editor)).IsNull);
foreach(ListViewItem i in list.Items)report.Add("ROW "+string.Join(" | ",i.SubItems.Cast<ListViewItem.ListViewSubItem>().Select(x=>x.Text)));
typeof(BhtPaletteControl).GetMethod("ClearAll",flags).Invoke(editor,null);Check("clears-route-table-on-document-close",list.Items.Count==0);
typeof(BhtPaletteControl).GetField("_doc",flags).SetValue(editor,null);
}
}catch(System.Exception ex){report.Add("FAIL "+ex);}File.WriteAllLines(Path.Combine(Path.GetDirectoryName(typeof(RouteDataProbe).Assembly.Location),"route-data-probe.txt"),report);}}
