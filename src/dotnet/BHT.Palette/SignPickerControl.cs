using System;
using System.Windows.Forms;
using AcApp = Autodesk.AutoCAD.ApplicationServices.Core.Application;

namespace BHT.Palette
{
    public partial class BhtPaletteControl
    {
        private SignPickerForm _signPicker;

        private SignPickerForm CreateSignPicker()
        {
            if (_signPicker != null && !_signPicker.IsDisposed) return _signPicker;
            var document = _doc;
            string objectId = _oId.Text;
            bool isNew = _oIsNew;
            var picker = new SignPickerForm(EditorSignCode(), _oDesc.Text, _oFaceCodes.Text, _oSignFill.Checked, _bridgeName, _bridgeStation, _roadName);
            picker.ConfigurePresentation(_signContent, _signLayout, _signGap, _signClearance);
            _signPicker = picker;
            picker.FormClosed += (s,e) => {
                bool current = ReferenceEquals(_signPicker,picker);
                if (current) _signPicker = null;
                if (current && picker.DialogResult == DialogResult.OK && picker.SelectedSign != null && document != null && document == _doc && document == AcApp.DocumentManager.MdiActiveDocument && objectId == _oId.Text && isNew == _oIsNew)
                    ApplyPickedSign(picker);
            };
            return picker;
        }

        private void OpenSignPicker()
        {
            if (!NeedDoc()) return;
            KeepObjectScroll(() => {
                var picker = CreateSignPicker();
                if (!picker.Visible) Autodesk.AutoCAD.ApplicationServices.Application.ShowModelessDialog(picker);
                if (picker.WindowState == FormWindowState.Minimized) picker.WindowState = FormWindowState.Normal;
                picker.Activate();
            });
        }

        private void CloseSignPicker()
        {
            var picker = _signPicker;
            _signPicker = null;
            if (picker == null || picker.IsDisposed) return;
            picker.DialogResult = DialogResult.Cancel;
            picker.Close();
            picker.Dispose();
        }
    }
}
