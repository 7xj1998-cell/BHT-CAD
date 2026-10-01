# BHT v0.6.0 — Chuyển dần sang .NET, module và giảm phụ thuộc TDT

Ngày 01/10/2026. Đây là đợt chuyển đầu tiên, chưa chuyển toàn bộ thuật toán CAD sang .NET.

## Đã chuyển

Lisp bht:unicode-nfc / bht:tcvn-encode / bht:tcvn-decode gọi BHTNATIVETEXT trong BHT.Bridge. .NET thực hiện chuẩn hóa Unicode NFC và encode/decode TCVN3; các bản ghi vẫn Unicode. BHTNATIVESIGNCODE dùng BHT.Core.SignPresentation để suy ra P.127-80 từ gioihan80, phục vụ cả nguồn TDT và hình học BHT độc lập. Lisp cũ làm fallback khi Bridge chưa nạp; *bht-force-lisp-text* cho phép kiểm thử riêng engine cũ. Không xóa engine dự phòng trước khi có nghiệm thu tương đương.

Loader BHT-0.6.0.lsp nạp 12 module theo thứ tự: foundation, points, labels, objects, photos, routes, segments, signs, draworder, reports, diagnostics, api. Tên hàm/lệnh và hợp đồng DWG giữ nguyên. Bộ build/version/package kiểm đủ module; bundle tự nạp Bridge và khai báo Support Path cho Windows/Fonts. Không tự hạ SECURELOAD của máy người dùng.

Khi load bằng đường dẫn tuyệt đối ngoài Support Path để phát triển, đặt *bht-module-root* thành thư mục chứa loader trước khi load; runner đã làm bước này. Bundle là cách cài khuyến nghị.

## TDT là nguồn bổ sung

- BHT_SIGN_PROVIDER=BUILTIN: không dò hoặc đọc TDT. Danh mục BHT có 16 mã phổ biến, lọc nhóm/tìm kiếm/chọn tốc độ/nhiều mặt hoạt động. Mã chưa có ảnh được trình bày bằng thẻ ghi mã rõ ràng, không giả làm hình biển chuẩn.
- BHT_TDT_ROOT: đường dẫn thư viện thay thế, phục vụ adapter và kiểm thử. TDT mặc định vẫn chỉ đọc từ thư mục đã cài.
- XML đọc bằng tên thuộc tính tiếng Việt thay vì vị trí thuộc tính. XML rỗng, sai cấu trúc, DTD/external entity trở về danh mục BHT. Container bienbao.set chỉ chấp nhận layout được hỗ trợ và kiểm tra kích thước; nguồn khác trả lỗi để Lisp dùng hình học tích hợp.
- Không có vector TDT vẫn chèn được các block BHT đã tích hợp và custom block. P.127 sinh số tốc độ 5–130, giữ đúng 80/120. Không còn nhầm P.127-120 với biến thể 20.
- Bộ ảnh/vector hoàn chỉnh mọi biển chưa độc lập TDT; hiện chỉ có tập BHT tích hợp. Biển đặc thù dùng block riêng và ảnh hiện trường. Tuyến tham chiếu Polyline thường hoạt động độc lập; đọc tim TDT còn cần module TDT nhận diện đối tượng sống, hoặc người dùng cung cấp Polyline riêng.

Không đóng gói tài sản DWG/BMP TDT. Hướng phát triển: danh mục/vector/preview BHT tự quản lý theo schema riêng; adapter TDT có phiên bản và diagnostics, chỉ nhập vào mô hình nội bộ. Khi adapter không hiểu cấu trúc mới thì từ chối nguồn, không sửa TDT hay làm mất hồ sơ.

## Bộ cài và giới hạn bảo mật

Bộ cài PowerShell/CMD kiểm manifest SHA256, phiên bản DLL/bundle, file thiếu, file ngoài manifest, đường dẫn vượt thư mục và reparse point nguồn. Chép vào staging rồi xác minh; giữ bản cũ trong thư mục backup không có đuôi .bundle; lỗi thay thế phục hồi bản cũ. -ValidateOnly kiểm tra gói mà không cài. Không thay DLL khi AutoCAD đang mở.

Gói mặc định không kèm source C# hoặc PDB; -IncludeSource dùng riêng khi bàn giao nguồn. Lisp module còn là văn bản và .NET có thể bị dịch ngược. SHA256 chỉ đối chiếu nội dung với manifest; người thay được cả manifest lẫn file vẫn có thể giả gói. Chưa có chứng thư/ký Authenticode, chưa obfuscate hoặc biên dịch FAS/VLX. Không tuyên bố chống sao chép tuyệt đối.

Theo [Autodesk SECURELOAD](https://help.autodesk.com/cloudhelp/2024/ENU/AutoCAD-Core/files/GUID-541566C6-2738-49DD-87C3-C1490E924A02.htm), executable được quản lý qua trusted locations; không hạ SECURELOAD để né kiểm tra. [Application Bundle](https://help.autodesk.com/cloudhelp/2024/ENU/AutoCAD-Customization/files/GUID-5E50A846-C80B-4FFD-8DD3-C20B22098008.htm) là hình thức triển khai hiện có. Bước bảo vệ tiếp theo cần chứng thư nhà phát hành và quy trình ký riêng, không lưu khóa riêng vào repo/gói ZIP.

## Kiểm thử và phần còn phải nghiệm thu

- Build Core/Bridge/Palette 0.6.0.0, 122 Core PASS.
- SIGN/TCVN trên Core Console: 28 kiểm tra ký hiệu, 7 ca tương tác/menu, 32 kiểm tra phông gồm xác nhận engine NET đang chạy, đối chiếu 266 đầu vào TCVN/178 cặp NFC, decode và ép fallback Lisp.
- REVIEW/S0/V5: 10/20/21 PASS; BHTTEST 46 PASS.
- Không TDT: 6 probe cho BUILTIN, thiếu vector, schema XML lạ, external entity, đảo thứ tự thuộc tính và container thay đổi; 30 kiểm tra ký hiệu (thêm số 80 thật và 120), 32 kiểm tra phông đạt. WinForms picker cả TDT và BUILTIN đạt, bao gồm lọc nhóm, chọn tốc độ/nhiều mặt, sắp thứ tự, hủy.
- Bộ cài: 7 ca trên fixture riêng đạt (gói hợp lệ, module đổi, module thiếu, executable lạ, path traversal, giữ bản cũ, rollback khi thay thế lỗi).
- TX proxy TDT chưa chạy vì thiếu fixture.
- Giao diện AutoCAD thật: tìm thấy Autodesk AutoCAD 2024 - [Drawing1.dwg], cửa sổ 398390. Hai lần capture thất bại: FrameArrived timed out và window capture timed out. Không quan sát được Palette, chưa nghiệm thu thao tác chuột. WinForms ẩn/Core Console không thay thế kiểm thử này; chưa cài bản mới vào phiên đang mở.

## Bước chuyển tiếp

1. Sau khi công cụ giao diện hoạt động, nghiệm thu [checklist UI thật](UI_ACCEPTANCE_0.6.0.md) trên bản vẽ thử riêng.
2. Chuyển draw order/leader/block insertion sang dịch vụ .NET transaction; giữ kết quả DXF, vị trí RTK, undo và sự tương đương Lisp làm chuẩn.
3. Chuyển nhãn/tuyến/ảnh theo từng module sau khi có fixture hồi quy; không thay đồng thời storage và thuật toán.
4. Phát triển nguồn hình biển BHT độc lập, rồi ký gói phát hành bằng chứng thư nhà phát hành.
