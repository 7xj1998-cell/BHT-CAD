# Lộ trình phát triển BHT

**Phạm vi hỗ trợ:** AutoCAD 2021–2024, Windows 64-bit. Không hỗ trợ AutoCAD 2025 trở lên trong lộ trình này.
**Điểm xuất phát:** mã nguồn v0.6.54. Bản phát hành mới nhất trên GitHub Releases hiện vẫn là v0.6.13.

## Nguyên tắc chung

1. Mỗi mốc kết thúc bằng một bản phát hành có thể tải về, không chỉ có mã nguồn.
2. Mỗi mốc có **tiêu chí đạt** đo được. Chưa đạt tiêu chí thì chưa chuyển mốc.
3. Không báo "đạt" nếu chưa chạy thật. Test cần AutoCAD mà môi trường không có thì ghi rõ "chưa chạy".
4. Mọi thay đổi chức năng đều tăng phiên bản bằng `scripts/set-version.ps1` và ghi `CHANGELOG.md` (theo `AGENTS.md`).
5. Không đổi định dạng dữ liệu trong DWG hoặc tên lệnh khi chưa có kế hoạch nâng cấp dữ liệu (xem `docs/DATA_CONTRACT.md`).
6. Dữ liệu hiện trạng đã nhập bằng bản cũ phải mở và dùng được ở bản mới, không mất dữ liệu, không lệch lý trình.

---

## Mốc 1 — từ v0.6.54, sửa đổi phát hành v0.6.55 trở lên: Ổn định hệ thống

**Mục tiêu:** bản đang có chạy đáng tin trên máy người dùng thật.

### Việc cần làm

| # | Việc | Cách kiểm |
|---|---|---|
| 1.1 | Phát hành v0.6.54 lên GitHub Releases (bộ cài, `.zip`, checksum) | Có release và tag `v0.6.54`; tải về cài được |
| 1.2 | Kiểm thử thật cơ chế nạp FAS | Cài bằng bộ cài trên máy sạch; mở AutoCAD; mở Palette; API nạp đúng phiên bản. Thử đường dẫn có dấu và khoảng trắng; thử khi thư mục nằm trong Support Path và khi không |
| 1.3 | Kiểm tra chuyển đổi nhiều bản vẽ | Mở 3 bản vẽ liên tiếp; chuyển qua lại; đóng bản vẽ đang nạp; hủy LOAD giữa chừng. Palette phải đúng trạng thái theo bản vẽ hiện hành, không treo, không dữ liệu chéo giữa các bản vẽ |
| 1.4 | Kiểm tra lưu và mở lại DWG | Chèn đủ các loại đối tượng (điểm RTK, biển, cọc, đèn, tuyến, mốc Km); lưu; đóng; mở lại; so sánh số lượng, vị trí, hồ sơ, lý trình |
| 1.5 | Hoàn thiện xử lý lỗi Palette | Khi thiếu DLL, thiếu FAS, phiên bản không khớp, LOAD lỗi: có thông báo tiếng Việt nêu rõ nguyên nhân và cách khắc phục; không hộp thoại lỗi giả |
| 1.6 | Thử trên nhiều bản AutoCAD | Theo quyết định chủ dự án 11/10/2026: chỉ kiểm thử AutoCAD 2024; các bản 2021–2023 chưa được xác minh |
| 1.7 | Dọn đường dẫn cá nhân và tài liệu | Xem mục "Dọn nền tảng" bên dưới |

### Tiêu chí đạt

- Toàn bộ 1.1–1.6 chạy xong, kết quả ghi vào `docs/QA_0.6.54.md` (bổ sung), mục nào chưa chạy được thì ghi rõ lý do.
- 233 kiểm tra Core vẫn đạt.
- Một người khác (không phải người phát triển) cài và dùng được theo hướng dẫn.

### Dọn nền tảng (làm trong mốc này, không đổi hành vi)

- Bỏ đường dẫn `C:\Users\Le Bao\...` trong `RELEASE_STATE.json` và các `tests/IntegrationTests/*.lsp|ps1`; dùng biến môi trường (ví dụ `BHT_TEST_DIR`, `ACAD_INSTALL_DIR`). Đọc `scripts/package.ps1` trước khi sửa `RELEASE_STATE.json`, vì cơ chế chặn phát hành lại có thể dựa vào file này.
- Sửa tài liệu mô tả các giai đoạn cũ (README, hướng dẫn) cho khớp bản hiện hành; chuyển tài liệu phiên bản cũ vào `docs/archive/`.
- Thêm tài liệu `KNOWN_ISSUES` và checklist nghiệm thu cho dòng 0.6.x.
- LICENSE: **chủ dự án quyết định loại giấy phép**; Codex không tự chọn.

---

## Mốc 2 — v0.7.x: Nâng cấp lõi xử lý tuyến

**Mục tiêu:** tính lý trình thống nhất, có thể kiểm thử tự động, không làm lệch dữ liệu cũ.

Chia thành ba bản nhỏ, không gộp.

### v0.7.0 — Chốt đáp án chuẩn và đo hiệu năng (chưa đổi thuật toán)

| # | Việc | Cách kiểm |
|---|---|---|
| 2.1 | **Bộ kiểm thử hồi quy lý trình** | Tạo tập tuyến mẫu: thẳng, có cung tròn, nhiều đoạn, tuyến kín, đầu tuyến ngược chiều, mốc Km từ hồ sơ và mốc nhập tay. Chạy bản hiện tại và lưu kết quả (Km, bên lệch, khoảng lệch) làm đáp án chuẩn trong `tests/` |
| 2.2 | Đo hiệu năng | Đo thời gian tính lý trình cho 100, 1.000, 5.000 điểm RTK; ghi vào tài liệu |
| 2.3 | Rà tim tuyến độc lập với TDT | Liệt kê chức năng nào còn phụ thuộc TDT (`Tdt91Interop.cs`, `BHTTUYENTDT`, cọc TDT) và chức năng nào đã chạy với polyline thường. Chỉ ghi nhận hiện trạng |

**Tiêu chí đạt:** đáp án chuẩn nằm trong repo và chạy được tự động (phần Core); có số liệu hiệu năng; có bảng phụ thuộc TDT.

### v0.7.1 — Viết bộ máy mới, chạy song song với Lisp

| # | Việc | Cách kiểm |
|---|---|---|
| 2.4 | Viết `BHT.AlignmentEngine` trong `BHT.Core` (không phụ thuộc AutoCAD) | Xử lý Polyline thẳng/cung, điểm đầu, chiều tuyến, chiếu điểm, lý trình, khoảng lệch trái/phải |
| 2.5 | Cầu nối Bridge | Lisp có thể gọi bộ máy mới qua Bridge; vẫn giữ nguyên code Lisp cũ |
| 2.6 | So sánh song song | Chạy cả hai trên toàn bộ đáp án chuẩn; báo cáo mọi ca khác nhau |

**Tiêu chí đạt:** 100% ca trong đáp án chuẩn trùng nhau (trong sai số khai báo trước, ghi vào tài liệu), hoặc mỗi ca khác biệt có giải thích và chủ dự án xác nhận.

### v0.7.2 — Chuyển hẳn sang bộ máy mới

| # | Việc | Cách kiểm |
|---|---|---|
| 2.7 | Lisp gọi bộ máy mới làm đường chính | Toàn bộ test hồi quy và test AutoCAD đạt như trước |
| 2.8 | Tăng tốc hàng loạt (chỉ nếu 2.2 cho thấy chưa đủ nhanh) | Số liệu đo trước/sau; không làm đổi kết quả |
| 2.9 | Tim tuyến độc lập với TDT (chỉ phần còn thiếu theo 2.3) | Tạo, sửa, đổi chiều tuyến bằng polyline thường không cần TDT |
| 2.10 | Chuyển các phần Lisp phức tạp sang .NET **khi có lý do rõ** (hay lỗi hoặc chậm) | Mỗi phần chuyển có test tương ứng; giữ tên lệnh `bht:*` và lệnh người dùng |

**Tiêu chí đạt:** hồi quy đạt; bản vẽ làm bằng 0.6.x mở và tính lại lý trình cho kết quả như cũ; không còn hai nơi cùng tính lý trình.

---

## Mốc 3 — v1.0: Phần mềm khảo sát hoàn chỉnh

**Mục tiêu:** một quy trình trọn vẹn, có thể giao cho người khác dùng.

| # | Việc | Cách kiểm |
|---|---|---|
| 3.1 | Quy trình đầu-cuối: nhập dữ liệu, quản lý hồ sơ, bố trí ký hiệu, tính lý trình, xuất báo cáo | Chạy trọn trên một dự án mẫu (dữ liệu tổng hợp hoặc đã ẩn danh) không lỗi, trên AutoCAD 2021–2024 |
| 3.2 | Bộ kiểm thử hồi quy đầy đủ | Core trong CI; các phiên AutoCAD chạy được bằng một lệnh; có hướng dẫn chuẩn bị dữ liệu mẫu để máy khác chạy lại |
| 3.3 | Tương thích ngược dữ liệu | Mở bản vẽ làm bằng các bản 0.6.x và 0.7.x; có chức năng nâng cấp dữ liệu hoặc báo rõ giới hạn |
| 3.4 | Bộ cài | Cài, gỡ, cài đè, bản vẽ mở lại bình thường; kiểm tra payload lỗi |
| 3.5 | Tài liệu sử dụng | Hướng dẫn theo từng bước có ảnh; mục xử lý sự cố; bảng phiên bản AutoCAD hỗ trợ |
| 3.6 | Giấy phép và thông tin phát hành | LICENSE đã được chủ dự án chọn; CHANGELOG thống nhất |

**Tiêu chí đạt:** 3.1–3.6 hoàn tất và có biên bản nghiệm thu; ít nhất một dự án khảo sát thật đã dùng bản release trước 1.0 một thời gian mà không phát sinh lỗi nghiêm trọng.

---

## Không làm trong lộ trình này

- Hỗ trợ AutoCAD 2025 trở lên, BricsCAD hoặc bản không phải Windows.
- Viết lại toàn bộ Lisp sang .NET; chỉ chuyển phần có lý do rõ.
- Đổi định dạng dữ liệu trong DWG khi chưa có kế hoạch nâng cấp và kiểm thử đọc lại bản vẽ cũ.

## Điểm cần chủ dự án quyết định

1. Loại giấy phép (mục 1.7 và 3.6).
2. Sai số chấp nhận khi so sánh lý trình giữa bản cũ và bản mới (mục 2.6).
3. Đã chốt: chỉ kiểm thử AutoCAD 2024 trong đợt này.
4. Đã chốt: tiếp tục cho phép lấy tim từ TDT 9.1.


## Quyết định triển khai ngày 11/10/2026

- Chủ dự án yêu cầu bắt đầu Mốc 1 ngay.
- Không phát hành đè 0.6.54; nếu sửa code, tăng tối thiểu lên 0.6.55.
- Đợt nghiệm thu này chỉ chạy AutoCAD 2024. Phạm vi dự kiến 2021–2024 không đồng nghĩa đã kiểm thử các bản cũ.
- Giữ khả năng lấy tim từ TDT 9.1.
- Nếu kết quả cũ sai, tách ca đó, đối chiếu tính tay/hồ sơ và chờ chủ dự án xác nhận đáp án; không tự coi kết quả cũ là đúng.
- Đã chốt GPL-3.0-only cho mã BHT do chủ dự án sở hữu.
- Sai số so sánh lý trình và khoảng lệch giữa hai bộ máy: tối đa 0,001 m. Cách tim không quá 0,001 m coi là trên tim; ngoài vùng này phải đúng bên.
- Mục tiêu 100/1.000/5.000 điểm lần lượt không quá 1/3/10 giây trên máy AutoCAD 2024 hiện tại: đo 5 lượt, lấy trung vị, gồm tính lý trình và cập nhật hồ sơ, không gồm vẽ lại ký hiệu. Đây là tiêu chí, chưa phải kết quả đo.
- Chủ dự án chưa xác nhận quyền phân phối tài nguyên ADSCivil/TDT: chỉ phát hành công khai gói không chứa các tài nguyên đó.
- Máy sạch và người nghiệm thu độc lập chưa được xác nhận có sẵn; không thay bằng kết quả test trên máy phát triển.

## Hiện trạng bắt đầu Mốc 1

- Mã nguồn GitHub: 0.6.54; GitHub Releases mới nhất: 0.6.13.
- Đã có bộ cài/ZIP 0.6.54 cục bộ; chưa công bố bộ tài nguyên đi kèm lên GitHub Releases.
- RELEASE_STATE.json còn đường dẫn tuyệt đối máy phát triển. Phải giữ contentHash và quy tắc không ghi đè phiên bản khi chuẩn hóa.
- run_all.ps1, run_session.ps1, run_review.ps1 còn đường dẫn fixture cá nhân.
- Các kết quả kiểm thử đã có xem docs/QA_0.6.54.md; chưa coi Mốc 1 hoàn tất.