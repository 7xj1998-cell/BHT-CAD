using System;
namespace BHT.Core
{
    public static class LightModels
    {
        public static string[][] ForGroup(string group)
        {
            if(group=="DEN_TH") return new[] {
                new[]{"DEN_TIN_HIEU_3_MAU","Tín hiệu giao thông ba màu (đỏ – vàng – xanh)"},
                new[]{"DEN_CANH_BAO_VANG","Đèn cảnh báo vàng"} };
            if(group=="DEN_CS") return new[] {
                new[]{"DEN_CS_DON_MB","Chiếu sáng đơn — mặt bằng"},
                new[]{"DEN_CS_DOI_MB","Chiếu sáng đôi — mặt bằng"},
                new[]{"DEN_CS_TRANG_TRI_MB","Chiếu sáng trang trí — mặt bằng"},
                new[]{"DEN_CS_TRAI_MD","Chiếu sáng cần trái — mặt đứng"},
                new[]{"DEN_CS_PHAI_MD","Chiếu sáng cần phải — mặt đứng"} };
            return new string[0][];
        }
    }
}
