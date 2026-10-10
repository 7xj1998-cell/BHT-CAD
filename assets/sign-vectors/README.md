# Hình CAD đã đối chiếu

Từ 0.6.31, ADSCivil là nguồn chính. R.415a/b trong XML là phương án dự phòng được xuất từ đường bao hatch CAD gốc ADSCivil, giữ cung bulge, nhiều vùng ngoài và lỗ biểu tượng. scripts/import_r415_vectors.py tạo XML/SVG từ DXF xuất cục bộ. Các mô tả bên dưới ghi lịch sử các bản trước; R.415 hiện tại không dùng hình xe dựng thủ công của 0.6.30. Xem docs/ADSCIVIL_LIBRARY.md.

`qcvn-corrections.xml` lưu các đường bao biểu tượng lấy từ hình có nhãn W.205c, W.207a, W.239a/b và R.415a/b trong QCVN 41:2024/BGTVT. Nguồn: [bản quy chuẩn do Chính phủ công bố](https://datafiles.chinhphu.vn/cpp/files/vbpq/2024/11/51-bgtvt-kem.pdf), cũng được [Hải Phòng đăng lại](https://pbgdpl.haiphong.gov.vn/upload/phobienphapluat/product/2025/09-2025/000175499/51-bgtvt-kem-29797.pdf).

Nền tam giác/chữ nhật được tạo bằng hình học CAD; biểu tượng được chuyển từ ảnh quy chuẩn thành đường bao, không dùng hình AI. W.239b tạo chữ chiều cao từ giá trị nhập, tách khỏi biểu tượng. Bộ dữ liệu được nhúng trong BHT.Bridge.dll nên các biển này không phụ thuộc mã chung trong TDT cũ.

Từ 0.6.20, R.415a/b dùng hình xe vẽ lại bằng đường CAD sạch, với đường tròn dạng cung bulge cho bánh xe/đèn, vạch phân làn thẳng và dải huỷ liền. Bố trí loại xe giữ theo hình mẫu R.415a/b đã đối chiếu. W.239a dùng các cạnh thẳng cho ký hiệu điện. Các hình này thay đường bao cũ bị răng cưa do ảnh nguồn có độ phân giải thấp. Khi tắt Hatch, BHT giữ đường bao đã có, tránh tạo thêm nét trùng.

Từ 0.6.26, W.207a được sửa hai nhánh đối diện theo mẫu có nhãn. R.415a/b dùng đường bao khớp mẫu độ phân giải cao do người dùng gửi, đối chiếu bố trí xe với Hình D.18; lọc nét thừa, giữ các lỗ cửa kính/grille và cung tròn bánh xe. Palette dựng ảnh từ cùng XML để tránh ảnh thư viện và hình chèn bị lệch nhau. DP.134 và R.306 tạo hình tròn, chữ số và dải huỷ trực tiếp trong CAD. Tài nguyên TDT nguyên bản giữ nguyên.

Từ 0.6.30, R.415a/b dùng hình xe dựng thủ công bằng đường cong và cung tròn CAD, thay đường bao dò ảnh của 0.6.26/27. Bố trí giữ theo Hình D.18 và ảnh mẫu người dùng: ô tô bên trái; ô tô và xe máy ở làn giữa; xe máy, xe ba bánh và xe đạp ở làn phải. r415-pictograms.svg lưu nguồn hình học có thể chỉnh sửa; XML dùng chung cho CAD và ảnh xem trước. Dải hủy R.415b nằm trên các hình xe. Mẫu xuất CAD: docs/BIEN_R415_0.6.30.png.
