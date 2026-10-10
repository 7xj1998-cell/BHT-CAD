using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;
using Autodesk.AutoCAD.ApplicationServices;

namespace BHT.Palette
{
    public partial class BhtPaletteControl
    {
        private readonly Dictionary<Document, Action> _objectDrafts = new Dictionary<Document, Action>();

        private Action CaptureObjectDraft()
        {
            var text = new Control[] { _oId, _oDesc, _oPoles, _oFaces, _oNote, _oCode, _oCodeType, _oGroup, _oFaceCodes, _oCond, _oSide, _oCustomBlock, _oMarkerKm, _oMarkerH, _oChainage, _oInfo }
                .ToDictionary(c => c, c => c.Text);
            var checks = new[] { _oMarkerNumber, _oChecked, _oAllowShared }.ToDictionary(c => c, c => c.Checked);
            object[] points = _oPoints.Items.Cast<object>().ToArray(), photos = _oPhotos.Items.Cast<object>().ToArray();
            string baseline = _objectBaseline, bridge = _bridgeName, station = _bridgeStation, road = _roadName, stored = _storedChainage;
            string content = _signContent, layout = _signLayout, gap = _signGap, clearance = _signClearance;
            bool isNew = _oIsNew, readOnly = _oId.ReadOnly;
            return () => ChangeObjectEditor(() => {
                _objectBaseline = null;
                _oIsNew = isNew; _oId.ReadOnly = readOnly; _oAllowShared.Enabled = isNew;
                _signContent = content; _signLayout = layout; _signGap = gap; _signClearance = clearance;
                _bridgeName = bridge; _bridgeStation = station; _roadName = road; _storedChainage = stored;
                foreach (var pair in checks) pair.Key.Checked = pair.Value;
                foreach (var pair in text) pair.Key.Text = pair.Value;
                _oPoints.Items.Clear(); _oPoints.Items.AddRange(points);
                _oPhotos.Items.Clear(); _oPhotos.Items.AddRange(photos);
                _objectBaseline = baseline;
                UpdateMarkerStation(); UpdateObjectEditorState();
            });
        }

        private void RememberObjectDraft(Document doc)
        {
            if (doc == null) return;
            if (IsObjectEditorDirty()) _objectDrafts[doc] = CaptureObjectDraft();
            else _objectDrafts.Remove(doc);
        }

        private void RestoreObjectDraft(Document doc)
        {
            Action restore;
            if (doc != null && _objectDrafts.TryGetValue(doc, out restore))
            {
                restore();
                Status("Đã khôi phục nội dung hồ sơ chưa lưu của bản vẽ này.");
            }
        }
    }
}
