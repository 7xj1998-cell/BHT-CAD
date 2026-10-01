using System.Windows.Forms;
namespace BHT.Palette
{
    public class NoWheelComboBox : ComboBox
    {
        protected override void WndProc(ref Message m)
        {
            if (m.Msg == 0x020A || m.Msg == 0x020E) return;
            base.WndProc(ref m);
        }
    }
}
