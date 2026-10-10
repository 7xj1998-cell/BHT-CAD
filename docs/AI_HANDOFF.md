# Bàn giao BHT 0.6.53 cho AI/người phát triển tiếp theo

## Đọc theo thứ tự

1. AGENTS.md — quy tắc phiên bản và bảo toàn công việc.
2. VERSION, CHANGELOG.md — trạng thái bản hiện tại.
3. docs/DATA_CONTRACT.md — Dictionary/XRecord/XData, nguồn dữ liệu trong DWG.
4. src/lisp/modules/12-api.lsp, src/dotnet/BHT.Bridge/LispApi.cs, AcadDispatcher.cs — hợp đồng giao tiếp.
5. src/dotnet/BHT.Palette/BhtPaletteControl.cs — gắn tài liệu, gọi API, trạng thái giao diện.
6. docs/QA_0.6.53.md và các ghi chú/QA theo phiên bản liên quan.

Đây là bản tổng hợp phát triển từ 0.6.13 lên 0.6.53. Các đường dẫn máy cá nhân trong script/tài liệu lịch sử là cấu hình của máy phát triển, không phải đường dẫn bắt buộc trên máy mới.

## Bản đồ xử lý

- Điểm RTK, hồ sơ đối tượng: Lisp 02-points, 04-objects; BhtDataService ở Bridge.
- Tuyến/đầu tuyến/mốc Km và lý trình: 06-routes, 07-segments; RouteDataControl và TabObjectsRoutes.
- Sinh, nối, xoay và đổi tỷ lệ ký hiệu: 08-signs; SignSupports, SignLayout, SignContentBlocks.
- Thư viện/ảnh biển: BhtSignLibrary và TdtSignLibrary ở Bridge; SignPicker* ở Palette.
- Đèn: LightModels, LightPickerControl, scripts/LightLibraryBuilder.cs.
- Chữ: NativeTextService, quy tắc Unicode/phông trong AGENTS.md.
- Gói cài: scripts/package.ps1, compile-lisp.ps1, protect-dotnet.ps1, packaging/SingleFileInstaller.cs.

## Những quyết định cần giữ

- Không tự nâng cấp/sinh lại ký hiệu lúc khởi động. Cơ chế cũ từng gây lỗi native CAD; cập nhật hình học chỉ khi người dùng thực hiện thao tác tương ứng.
- Tỷ lệ biển chung áp dụng BIEN_BAO, BANG_CHI_DAN, BANG_QC, KHAC, CHUA_XAC_DINH; cọc và đèn có quy tắc riêng. Giữ tọa độ/góc INSERT khi đổi tỷ lệ.
- Tắt tô nền chỉ bỏ nền; giữ hatch hình vật thể và viền.
- Nhãn cọc đặt dưới ký hiệu, xoay theo INSERT; giữ H4/40. Hồ sơ Km/H đủ dữ liệu được dùng làm mốc theo tuyến phù hợp, không bắt nhập lại bằng BHTMOCKM.
- Đèn chiếu sáng/tín hiệu tách nhóm, không có nhãn ngoài dưới chân.
- Trụ mất mặt biển dùng khung có chữ “Trụ mất biển”, không nhãn ngoài; giữ mã gốc để khôi phục.
- Lưu nội dung Unicode; chuyển bảng mã cũ chỉ tại lớp hiển thị khi cần.
- Không sửa tài nguyên TDT gốc hoặc đưa thư viện vendor cục bộ vào Git.

## Sửa lỗi nạp Lisp 0.6.53

BhtPaletteControl.ProbeLisp trước đây quy mọi lỗi gọi API thành khác phiên bản. Bản mới phân biệt phản hồi phiên bản hợp lệ nhưng không tương thích với tình trạng chưa gọi được API.

LispRuntimeLoader tìm FAS (hoặc LSP khi phát triển) đúng tên phiên bản cạnh DLL Bridge. Gửi LOAD qua hàng đợi CAD; Lisp gọi BHTRUNTIMELOADED với token khi hoàn tất, sau đó Palette kiểm tra lại API. Mỗi lượt mở bảng thử một lần, chờ tối đa 30 giây; callback cũ bị bỏ khi đổi/đóng tài liệu.

Không thay SECURELOAD trong luồng sản phẩm. Test cô lập có thiết lập riêng. Không dùng NETLOAD chồng DLL mới để thử trong phiên CAD người dùng.

**Còn cần xác minh:** nguyên nhân autoload ban đầu trong phiên CAD ở ảnh chưa được tái hiện; hành vi đổi/đóng nhiều tài liệu và hủy LOAD cần kiểm thử tương tác AutoCAD đầy đủ. Không coi kiểm tra Core Console là xác nhận toàn bộ giao diện thật.

## Kiểm thử đã thực hiện

- CoreTests: 233 đạt.
- Palette layout/editor workflow: 683 đạt.
- Bootstrap DLL đã bảo vệ + FAS, đường dẫn có dấu/khoảng trắng: thiếu API ban đầu -> nạp -> gọi API đúng phiên bản.
- Nhánh lỗi thiếu file, LOAD lỗi và phiên bản không tương thích.
- Runtime độc lập: chèn biển, lưu và mở lại DWG.
- Bộ cài một file: 39 kiểm tra, kiểm tra payload lỗi và validate-only không cài đè.

Các script chính: tests/IntegrationTests/run_bootstrap653.ps1, run_palette_layout.ps1; tests/ReleaseTests/protected-runtime.ps1, single-file-installer.ps1. Tests tích hợp cần AutoCAD và có thể cần tài nguyên local; không báo đạt nếu môi trường thiếu.

## Tiếp tục phát triển

- Đọc mã trước khi đề xuất; không dựa riêng vào README/hướng dẫn cũ vì chúng mô tả nhiều giai đoạn lịch sử.
- Thay đổi chức năng tiếp theo phải tăng phiên bản bằng scripts/set-version.ps1, tối thiểu 0.6.54.
- Hoàn tất code, test và tài liệu trước package: RELEASE_STATE.json chặn đóng gói lại cùng phiên bản với nội dung đã đổi.
- Không đưa kết quả build, DLL Autodesk, dữ liệu người dùng hoặc bản sao tài nguyên vendor lên repo.
- Kho hiện chưa có LICENSE riêng cho mã BHT; công khai để đọc không thay thế việc lựa chọn giấy phép phân phối/tái sử dụng.
