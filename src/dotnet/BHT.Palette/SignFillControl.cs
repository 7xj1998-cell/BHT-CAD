using System;
using Autodesk.AutoCAD.ApplicationServices;
using BHT.Bridge;
using BHT.Core;

namespace BHT.Palette
{
    public partial class BhtPaletteControl
    {
        private bool? _pendingSignFill;

        private void UpdateSignFillAvailability()
        {
            if (_oSignFill != null) _oSignFill.Enabled = _doc != null && _lispOk && !_lispRunning && !_pendingSignFill.HasValue;
            RefreshSignScale();
            if(_deleteObjectButton != null) UpdateObjectEditorState();
            UpdateRtkActionAvailability();
        }

        private void RefreshSignFill()
        {
            UpdateSignFillAvailability();
            if (_doc == null) return;
            bool value = _pendingSignFill ?? (_svc.Meta("sign_fill_all", "1") != "0");
            _syncingSignFill = true;
            try { _oSignFill.Checked = value; }
            finally { _syncingSignFill = false; }
        }

        private void ChangeSignFill()
        {
            if (_syncingSignFill) return;
            if (_pendingSignFill.HasValue) { RefreshSignFill(); return; }
            if (_lispRunning || !NeedDoc() || !_lispOk)
            {
                RefreshSignFill();
                Status("Chưa đổi tô nền: chờ thao tác trước và lõi Lisp BHT sẵn sàng rồi thử lại.");
                return;
            }
            string busy;
            if (AcadDispatcher.IsBusy(_doc, out busy))
            {
                RefreshSignFill(); StatusWarn("Chưa đổi tô nền: " + busy, false); return;
            }
            var doc = _doc;
            int generation = _lispGeneration;
            _pendingSignFill = _oSignFill.Checked;
            UpdateSignFillAvailability();
            bool started = CallLisp("bht:api-sign-fill", new[] { _pendingSignFill.Value ? "1" : "0" },
                "Tô nền tất cả biển BHT", r => CompleteSignFill(doc, generation, r));
            if (!started) { _pendingSignFill = null; RefreshSignFill(); }
        }

        private void CompleteSignFill(Document doc, int generation, LispReply reply)
        {
            if (_doc != doc || generation != _lispGeneration) return;
            _pendingSignFill = null;
            RefreshSignFill();
            if (!reply.Ok) StatusError("Chưa hoàn tất đổi tô nền: " + reply.Error, false);
        }
    }
}
