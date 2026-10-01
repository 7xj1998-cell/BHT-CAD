# BHT v0.5.1 — ngày 01/10/2026

Đã sửa phông chữ CAD mặc định sang `vnromanc.shx`, bảng mã TCVN3 (ABC). Các nhãn tiếng Việt lấy từ hồ sơ Unicode được tự động chuyển mã khi tạo hoặc cập nhật TEXT. Áp dụng cho nhãn điểm RTK, nhãn đối tượng, nhãn ảnh và chữ BHT tạo trên CAD. Dữ liệu hồ sơ, XRecord/XData, Palette, tìm kiếm và báo cáo Excel vẫn giữ Unicode.

## Cài đặt và cập nhật bản vẽ

1. Đóng tất cả cửa sổ AutoCAD, giải nén **BHT-0.5.1.zip**, chạy **INSTALL_BHT.cmd** rồi mở lại AutoCAD.
2. Gõ **BTH** hoặc **BHT**. Phiên bản hiển thị phải là **0.5.1**.
3. Chạy **BHTKYHIEU** để cập nhật nhãn đối tượng; chạy **BHTSAPNHAN** để cập nhật và sắp lại nhãn điểm RTK theo phạm vi chọn.
4. Khi gõ trực tiếp vào TEXT có kiểu chữ **BHT_TCVN** hoặc **BHT_BIENBAO**, chọn **TCVN3 (ABC)** trong UniKey. Khi nhập dữ liệu trên Palette hoặc CSV, dùng **Unicode**; BHT tự chuyển mã khi vẽ chữ.

Gói phát hành kèm `vnromanc.shx`. Các kiểu chữ mặc định cũ `BHT_ARIAL`/`BHT_RTK` được chuyển sang mặc định mới khi đồng bộ nhãn BHT; kiểu chữ riêng được giữ. Nhãn sửa tay giữ vị trí. Nếu thiếu phông SHX, hệ thống dùng Arial với chuỗi Unicode.

Các block mặt biển TDT tiếp tục giữ phông chuyên dụng của thư viện. Các sửa lỗi biển báo đã thực hiện trước đó vẫn có trong v0.5.1: Hatch, chiều cao chuẩn 1,8, tốc độ P.127, block riêng từng hồ sơ, thư viện thumbnail và xoay theo tuyến.

## Quản lý phiên bản

- Số phiên bản lấy từ `VERSION`; DLL của bản này có Assembly/FileVersion **0.5.1.0**.
- Mỗi đợt sửa phải tăng số phiên bản. Dùng `scripts/set-version.ps1 -Version 0.5.2` cho đợt sửa kế tiếp.
- Build và package kiểm tra sự đồng bộ giữa VERSION, Lisp, DLL, bundle và bộ cài.
- Package dùng `RELEASE_STATE.json` để chặn phát hành lại cùng số phiên bản khi mã nguồn/tài liệu thay đổi. Bản nguồn trong ZIP có kèm trạng thái phát hành để tiếp tục áp dụng quy tắc này.

## Kiểm tra

- Core: **122 PASS, 0 FAIL**.
- AutoCAD Core Console: **18 kiểm tra TCVN3 PASS**, gồm chữ có dấu, Unicode tổ hợp, nhãn cũ, nhãn đối tượng, nhãn ảnh, giữ vị trí sửa tay, đồng bộ lặp, dữ liệu nguồn không đổi và thiếu phông.
- **13 kiểm tra Lisp biển báo PASS**; kiểm tra DWG TDT xác nhận Hatch, chiều cao và các biến thể tốc độ.
- Hộp thư viện WinForms: 412 mã, 292 ảnh BMP; tìm kiếm và lọc nhóm đạt.
- Quy tắc phiên bản: chặn nội dung đổi dưới số phiên bản cũ, đồng bộ metadata khi tăng phiên bản, từ chối giảm phiên bản; kiểm tra trên bản sao, không đổi phiên bản thật.

Bảng mã được đối chiếu với [bảng chuyển mã UniKey](https://github.com/fcitx/fcitx5-unikey/blob/master/unikey/data.cpp). Hướng dẫn chọn bảng mã khi gõ trực tiếp tham khảo [hướng dẫn UniKey](https://www.unikey.org/support/ukmanual.html).

Chạy lại: `scripts/build.ps1 -UseCsc -Test`, `tests/IntegrationTests/run_signs.ps1`, `tests/ReleaseTests/version-policy.ps1`.
