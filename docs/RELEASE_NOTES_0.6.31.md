# BHT 0.6.31 — Thư viện biển ADSCivil

Đã thay nguồn biển mặc định bằng ADSCivil: 469 DWG mặt biển, hiển thị 467 mẫu riêng trong thư viện. R.415a/b giữ hình xe, cửa kính, bánh xe và vạch phân làn từ CAD gốc. Thứ tự vẽ được giữ để nền không che biểu tượng; dải hủy của R.415b và DP.134 hiển thị đúng.

Bộ cài kèm 1.630 tài nguyên ADSCivil và phông chữ để dùng cục bộ khi máy nhận không cài ADSCivil/TDT. BHT vẫn dùng cơ chế trụ, nhiều mặt, hai chân và nối RTK đã có. Các model ADSCivil được lưu kèm để nghiên cứu, chưa triển khai hệ BIM/gantry.

Ảnh chọn biển lấy từ thư viện ADSCivil. Tốc độ, mét, giờ và tên cầu nhập trong hồ sơ được áp dụng vào CAD; ảnh thư viện là ảnh mẫu. Khi mở DWG bằng phiên bản mới, BHT cập nhật ký hiệu đã đặt sau khi lõi nạp xong, giữ vị trí, góc quay, tỷ lệ và dữ liệu RTK. Lưu DWG để giữ thay đổi.

Đóng AutoCAD, chạy **BHT-Setup-0.6.31.exe**, sau đó mở CAD và gõ `BHT` hoặc `BTH`. Bản 0.6.30 và tài nguyên nhà cung cấp gốc được giữ nguyên.

Chi tiết trong [nghiên cứu ADSCivil](ADSCIVIL_LIBRARY.md) và [kết quả kiểm tra](QA_0.6.31.md).
