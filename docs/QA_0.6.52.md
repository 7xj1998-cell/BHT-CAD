# Kiểm tra tỷ lệ 0.6.52

## Nguyên nhân đã đối chiếu trực tiếp
Bản vẽ 261010.Bienbao BOT830.dwg có sign_scale=3. Biển địa phận OBJ-000120 / INSERT 23453 thuộc KHAC, scale X=Y=1; biển W.239a OBJ-000119 / INSERT 2342E thuộc BIEN_BAO, scale X=Y=3. Bảng quảng cáo OBJ-000088 cũng ở scale 1.

Chỉ đọc XRecord/XData và INSERT qua COM; không thay đổi đối tượng bản vẽ.

## Kiểm tra
- Core: 233 kiểm tra đạt.
- FAS + DLL protected: 21 kiểm tra tỷ lệ đạt, phủ đủ 5 nhóm, bảng hai trụ chỉnh tay, hệ số đều XYZ, giữ vị trí/góc/hồ sơ và RTK, áp dụng lặp, biển mới, khoảng cách tự động không đổi.
- Không thay đổi chuẩn hóa hình dạng từng mẫu, không ép mọi mặt biển cùng chiều rộng/cao. Sửa hệ số chèn bị bỏ sót theo nhóm.
- Bộ kiểm tra biển 467 mẫu và picker native đạt; Palette đạt 683 kiểm tra.
