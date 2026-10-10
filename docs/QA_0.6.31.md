# QA BHT 0.6.31

Kiểm tra trên Windows x64, AutoCAD 2024, .NET Framework 4.8. Các ca CAD dùng bản vẽ thử và profile Core Console riêng. Không sửa DWG khảo sát, thư viện ADSCivil/TDT gốc hoặc bundle đang dùng.

| Phạm vi | Kết quả |
|---|---|
| Đồng bộ phiên bản, build C# 5 x64 | 0.6.31 / DLL 0.6.31.0 |
| Core | 179 PASS, 0 FAIL |
| ADSCivil: catalog, clone, thứ tự vẽ, hatch, kích thước, chỉ nét, cache, thông số | 2.832 PASS, 0 FAIL |
| Danh mục ảnh | 467 mẫu, đủ 467 ảnh thực tế; 4 ảnh thiếu được dựng từ DWG |
| Palette/editor | 149 kiểm tra đạt |
| Lisp và API nâng cấp | Đạt: vị trí/góc/tỷ lệ, XData, RTK, hồ sơ, chỉ nét, không tạo ký hiệu chưa đặt |
| Lisp đặt biển | Đạt: UCS xoay, G/T, nhiều mặt, hai chân, cập nhật lặp và đường nối RTK |
| Bộ cài PowerShell | 7 ca đạt, gồm hash, thiếu file, path traversal, backup và rollback |

Đã đối chiếu thứ tự entity/hatch ở cả mặt biển và block lồng với DWG gốc. R.415a/b, DP.134 và các biển mẫu được xuất DXF từ AutoCAD rồi dựng ảnh có áp dụng SORTENTSTABLE. Bộ dựng ảnh ezdxf mặc định không áp dụng thứ tự này trong block lồng; cần phục hồi trước khi đánh giá ảnh. Ảnh dưới là hình dựng từ CAD, không phải ảnh chụp giao diện AutoCAD.

![Các biển ADSCivil và thông số BHT](ADSCIVIL_0.6.31.png)

Các log giữ tại `build/v0.6.31/bin/ads-probe.txt`, `build/v0.6.31/ads-console.txt`, `build/ads-lifecycle.txt`, `build/ads-palette-layout.txt` và `build/ads-installer-security.txt`. Manifest tài nguyên ở `SignLibrary/ADSCivil/BHT_ADS_MANIFEST.json`; hash của toàn gói ở `SHA256SUMS.txt`.

Luồng sự kiện Idle khi mở AutoCAD giao diện đầy đủ chưa được kiểm tra trực tiếp. Core Console đã gọi cùng API nâng cấp, kiểm dấu phiên bản và bảo toàn dữ liệu. Các mẫu có địa danh/attribute chưa có trường nhập tương ứng giữ nội dung mẫu ADSCivil. Model BIM/gantry được lưu kèm, chưa triển khai trong BHT.
