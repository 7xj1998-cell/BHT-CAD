# BHT 0.6.55 — bản thử nghiệm Mốc 1

- GPL-3.0-only cho mã BHT thuộc quyền chủ dự án; phạm vi xem COPYING_SCOPE.md.
- Gói công khai có mã nguồn tương ứng, không kèm DWG/phông/ảnh thư viện chưa rõ quyền; xem packaging/README_PUBLIC.md.
- Build -PublicDistribution bỏ ảnh preview nhúng. Package công khai bắt buộc IncludeSource, kiểm tra provenance/hash DLL và từ chối tài nguyên bị loại.
- RELEASE_STATE chỉ lưu tên tệp bộ cài/ZIP; giữ contentHash và kiểm tra phiên bản bất biến.
- Fixture tích hợp dùng BHT_TEST_DIR, BHT_LEGACY_TEST_DIR, ACAD_INSTALL_DIR thay đường dẫn cá nhân.
- Không đổi định dạng DWG, thuật toán lý trình hay giao tiếp TDT 9.1.

Đây chưa phải hoàn thành Mốc 1. Chưa nghiệm thu máy sạch, người dùng độc lập hoặc chuỗi chuyển/đóng/hủy giữa nhiều tài liệu AutoCAD đầy đủ. Chỉ kiểm thử AutoCAD 2024 trong đợt này.
