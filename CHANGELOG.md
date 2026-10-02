## v0.6.8 — 2026-10-02

- Đã bỏ 14 bí danh Lisp và hai bí danh mở bảng; có bảng lệnh thay thế cho script CAD.
- Đã chặn tốc độ/mét sai và mã không khớp, tránh vẽ biển mặc định khi nhập sai. Giữ các cách ghi tốc độ cũ và mã ghép W.239a + S.509a.
- Đã giới hạn bộ chọn ở 20 mặt/trụ và kiểm tra từng mặt trước khi xác nhận; kiểm tra block thiếu và cụm rỗng.
- Đã từ chối giá trị mét quá ba số thập phân thay vì âm thầm làm tròn, kể cả làm tròn về 0.
- Đã bỏ control không dùng, hai bản sao thư mục ảnh và tệp biên dịch trong mã nguồn đóng gói. Ảnh được nhúng trong DLL Palette.
- Đã đồng bộ README/hướng dẫn với phiên bản và thêm kiểm tra chống sai tên ZIP cài đặt.

## v0.6.7 — 2026-10-02

- Sửa đăng ký hàm ghép cụm nhiều mặt biển để Lisp gọi được; kiểm tra chèn/cập nhật 1 trụ với W.239 và S.509a@7 qua API Palette.
- Thanh thao tác hồ sơ có hai hàng cố định; Đặt tự do và Thư viện biển nằm trên cùng.
- Hiển thị hướng dẫn khi Lisp trả lỗi rỗng.

## v0.6.6 — 2026-10-02

- Nhúng ảnh biển báo vào DLL Palette, bảo đảm R.122 và toàn bộ thư viện có ảnh ngay cả khi thiếu thư mục Images. Giữ hỗ trợ ảnh TDT cho mã ngoài bộ ảnh đi kèm.
- Kiểm tra riêng ảnh R.122, P.131c, S.508a/b và toàn bộ mục thư viện bằng WinForms.

## 0.6.5 (2026-10-02)

- Tiếp tục từ v0.6.3; không lấy v0.6.4 làm nền.
- Gốc cọc tiêu tại chân đuôi; nhãn trên đầu, hướng theo ký hiệu. Đặt tự do và xoay theo tuyến áp dụng mọi nhóm.
- Hộp tùy chọn đặt tự do riêng; Palette chia thông tin hồ sơ, ký hiệu CAD, vị trí/ảnh. Bỏ BHTNANGCAP, BHTVEMODEL, BHTROUTE đời cũ.
- Dựng đủ nhiều mặt trên một trụ, giữ thứ tự và các biến thể số; lặp mã vẫn tạo đủ tấm. Nút chèn/cập nhật lưu thay đổi trước khi dựng ký hiệu.
- Nhập giá trị mét cho S.501, S.502, S.509a và P.117–P.120; xử lý cả số TDT bị tách thành nhiều TEXT. Không đổi chữ hay mã hiệu khác.
- 376 mã biển hợp lệ có ảnh thật; bỏ 36 tiêu đề/mục trùng của XML cũ khỏi bảng chọn. Ảnh bổ sung có nguồn QCVN hoặc hình từ block CAD và được đóng gói.

## 0.6.3 (2026-10-01)

- Palette chỉ tạo/hiện khi gọi BTH/BHT; bỏ tự nạp giao diện từ Lisp và lệnh khôi phục Palette cũ. Đóng bảng hoặc chuyển bản vẽ ngắt theo dõi dữ liệu và timer; gọi lệnh để mở lại.
- “Tô màu biển” nằm cùng hàng “Chèn biển tự do”, lưu theo bản vẽ và cập nhật mọi biển BHT đã chèn. Biển chèn sau theo cùng lựa chọn; không thay Hatch ngoài BHT.
- Nhãn biển đặt dưới, căn giữa khung block và quay cùng biển kể cả có điểm trung gian. Cỡ chữ tự tính theo chiều cao block, bỏ ô cỡ nhãn CAD; trường cũ giữ trong hồ sơ nhưng không dùng cho biển.
- Rút gọn tiêu đề hồ sơ mới; hướng dẫn phân nhóm chuyển vào tooltip. Đổi “Cho phép tạo hồ sơ mới” thành “Cho phép dùng chung điểm RTK”.
- Core 127 ca đạt; biển/native/offline/WinForms đạt; REVIEW 10, S0 20, V5 21 ca đạt. TX thiếu fixture. GUI chỉ đọc được Start của bản cũ, chưa thao tác chuột v0.6.3; tỷ lệ số mặc định TDT chưa xác minh.
## 0.5.1 — 2026-10-01

- Đã sửa chữ CAD mặc định sang `vnromanc.shx` và tự chuyển Unicode sang TCVN3 tại lớp hiển thị, gồm nhãn điểm RTK, nhãn đối tượng và chữ BHT tạo trên CAD. Hồ sơ, Palette, XData và báo cáo giữ Unicode.
- Đã đồng bộ phiên bản `0.5.1` cho Lisp, DLL, bundle, bộ cài và tên gói phát hành.
- Đã bổ sung công cụ tăng/kiểm tra phiên bản và chặn phát hành cùng số phiên bản khi nội dung thay đổi.
- Giữ các sửa lỗi biển báo: Hatch, chiều cao chuẩn, tốc độ P.127, block riêng từng hồ sơ, thư viện ảnh và xoay theo tuyến.

# CHANGELOG

## 0.6.2 (2026-10-01)

- Layer BHT_KYHIEU mặc định ACI 7 (trắng trên nền tối); layer đỏ mặc định cũ đổi sang trắng, màu tùy chỉnh khác giữ nguyên. Biển không tô màu dùng nét ByBlock/layer 0 để theo màu INSERT thay vì màu xanh cố định của nguồn TDT.
- Chặn con lăn đổi lựa chọn trong mọi ComboBox Palette và thư viện ảnh.
- Nhãn CAD mặc định 0.35 thay cho 1.5; thêm ô cỡ nhãn theo hồ sơ và đặt nhãn tự động cao hơn mặt biển.
- Thao tác nối tiếp từ Palette chờ kết thúc EXECUTEFUNCTION trước khi xử lý kết quả; ngăn bấm lặp khi BHT đang chạy. Không bỏ kiểm tra lệnh CAD đang chạy.
- Đặt tự do có đường dẫn thẳng, gấp khúc tự động hoặc điểm trung gian; hướng ngang/theo tuyến/chọn trên CAD/nhập góc. Luồng nhanh chỉ cần chọn vị trí, hủy không ghi hồ sơ.
- Core, CAD Core Console, offline và WinForms đạt; AutoCAD GUI chưa xác minh do công cụ capture timeout sau một lần phục hồi.


## 0.6.1 (2026-10-01)

- Thêm “Tô màu báo hiệu (Hatch)” trong thư viện ảnh và hồ sơ đối tượng; mặc định bật, lưu riêng từng hồ sơ.
- Tắt tô màu tạo biến thể block riêng, ẩn Hatch/Solid và tạo đường bao, xử lý cả block lồng nhau; hỗ trợ biển TDT, biển nội bộ và block tùy chỉnh.
- Bật lại khôi phục block có màu; đồng bộ giữ vị trí, góc quay, tỉ lệ và không đổi FILLMODE toàn bản vẽ.
- Xác nhận chuỗi “Tô mầu biển báo” / “Không tô mầu biển báo” / HatchBB trong RoadSignsUI.arx. Giao diện TDT trực tiếp bị chặn bởi lỗi ProjectDH.arx.
- 124 kiểm tra Core đạt; kiểm tra AutoCAD Core Console, chế độ không TDT và WinForms đạt. Chưa nghiệm thu thao tác giao diện AutoCAD thật.


## 0.6.0 (2026-10-01)

- Bắt đầu chuyển Lisp sang .NET: Unicode NFC, encode/decode TCVN và suy ra biến thể tốc độ dùng BHT.Bridge/BHT.Core; giữ fallback Lisp và kiểm thử tương đương cả hai engine.
- Tách lõi Lisp thành 12 module và loader chung; bundle tự nạp Bridge, bộ kiểm phiên bản kiểm đủ module.
- Thêm chế độ BUILTIN không dùng TDT; đọc XML theo tên thuộc tính, chặn DTD/external entity, từ chối container TDT chưa hỗ trợ và fallback an toàn. Biển tốc độ dự phòng có số thực 5–130, không nhầm 120 với 20.
- Bộ cài kiểm SHA256/phiên bản/thiếu file/file lạ/path traversal trước khi cài, giữ bản cũ và rollback khi thay thế lỗi. Gói mặc định không kèm mã nguồn C#; -IncludeSource chỉ dùng khi cần bàn giao nguồn.
- Core/AutoCAD/WinForms, 6 ca lỗi nguồn TDT và 7 ca bộ cài đạt. Kiểm thử giao diện AutoCAD thật chưa xác nhận: công cụ capture timeout hai lần; không tính kiểm thử tự động là nghiệm thu UI.

## 0.5.5 (2026-10-01)

- Bỏ giao diện DCL dự phòng và hai lệnh BHTDCL/BHTUITEST theo review mới; giữ Palette .NET và 67 lệnh Lisp còn lại.
- Giữ hàm bỏ dấu tìm kiếm, tình trạng và các hàm trạng thái; sửa BHTTEST để không gọi helper DCL đã xóa.
- Cập nhật BHTHELP/BHTLOAD, thông báo nạp và hướng dẫn cài/sử dụng; khi Palette lỗi hướng dẫn kiểm tra DLL và thử lại.
- Thêm runner kiểm tra review dùng profile riêng; cập nhật kỳ vọng kiểm thử theo font Unicode VNRomancUpdate.shx và 17 hàm API hiện có.
- Build/122 kiểm tra Core, REVIEW/S0/V5 và bộ kiểm thử biển/phông/WinForms đạt. TX chưa chạy do thiếu bản vẽ proxy mẫu. Đồng bộ phiên bản 0.5.5/0.5.5.0.

## 0.5.4 (2026-10-01)

- Xử lý review v0.5.3: rút gọn bảng TCVN/NFC, giữ đủ chữ hoa và đầu vào cũ; sửa ghép dấu trên chữ đã ghép một phần và thứ tự dấu đảo.
- Dùng helper chung cho ẩn/hiện nhãn, giữ 69 lệnh và alias; làm rõ các section và kết quả đếm hàm trong report.
- Chuẩn hóa ID khi chèn biển tự do; bổ sung hồi quy ID thiếu, hồ sơ không có RTK và đảo thứ tự điểm trung gian của đường dẫn.
- 122 kiểm tra Core, kiểm thử AutoCAD/WinForms và chính sách tăng phiên bản đạt; đồng bộ Lisp/DLL/bundle/bộ cài 0.5.4/0.5.4.0.

## 0.5.3 (2026-10-01)

- Thêm “Chèn biển tự do” trên Palette và lệnh BHTBIENTUDO: chọn hướng, thêm/xóa điểm trung gian, rồi chọn vị trí biển. Hủy trước bước cuối không ghi thay đổi.
- Lưu bố trí tự do theo hồ sơ; đường dẫn gấp khúc giữ qua lần cập nhật, theo điểm cuối khi di chuyển biển. BHTKYHIEU > R bỏ bố trí tự do để trở về tự động theo tuyến.
- Giữ RTK, liên kết tuyến, ảnh và nội dung biển. Quy đổi hướng từ UCS sang WCS; tiếp tục dùng phông Unicode VNRomancUpdate.shx.
- Build và kiểm tra Core, AutoCAD, nhập tương tác và thư viện ảnh đạt; đồng bộ phiên bản 0.5.3/0.5.3.0.

## 0.5.2 (2026-10-01)

- Dùng VNRomancUpdate.shx Unicode, sửa Ê/ê và chữ hoa có dấu; giữ tên kiểu cũ, chuyển TEXT TCVN3 của BHT khi cập nhật phông, bảo toàn dữ liệu Unicode/vị trí/góc quay.
- Thư viện biển thêm ảnh xem trước lớn, tốc độ P.127 gợi ý từ hồ sơ, kiểm tra giá trị và chọn nhiều mặt cùng trụ có thêm/bỏ/sắp thứ tự; hủy không ghi thay đổi.
- Ghi nghiên cứu menu/tài nguyên TDT 9.1 và giới hạn xác nhận giao diện do lỗi ProjectDH.arx; không sửa tài nguyên TDT gốc.
- Đồng bộ phiên bản 0.5.2/0.5.2.0, kèm phông mới, chặn phát hành thiếu phông mặc định; kiểm thử Core, AutoCAD và WinForms đạt.

## 0.4.6-fix3 (2026-09-29)

- Thanh thẻ dọc bên phải Palette có tên thẻ (trước đây là các ô xanh trống). Nguyên nhân: 0.4.6/fix2 xoay chữ −90° bằng `TextRenderer` (GDI) — GDI bỏ qua phép xoay của `Graphics` và ô chữ sau khi xoay chỉ dài 34 px, nên chữ bị vẽ lệch/cắt mất. Nay chữ ngang trong ô 86 × 38 px (độ rộng dải thẻ giữ nguyên 86 px), tự xuống 2 dòng khi dài. Tên thẻ: **Tổng quan**, **Điểm RTK**, **Ảnh hiện trường**, **Hồ sơ đối tượng**, **Tuyến & báo cáo**; rê chuột lên thẻ để xem mô tả. Thẻ thường nền `#065F46` chữ `#D1FAE5`; thẻ đang chọn nền `#D1FAE5` chữ `#065F46` và vạch đậm bên trái.
- Lỗi và cảnh báo cần người dùng xử lý hiện cửa sổ thông báo (tiêu đề `BHT`, biểu tượng lỗi/cảnh báo) và vẫn in ra dòng lệnh: lỗi `BHT lỗi: …` của các lệnh BHT, “chưa có tuyến. Dùng BHTTUYEN trước.”, tim TDT dạng proxy, không nạp được `BHT.Bridge.dll`, không mở được file, không ghi được file (đang mở trong Excel), dữ liệu nhập không hợp lệ… Hủy lệnh (Esc, `*Cancel*`) và thông tin thường chỉ in dòng lệnh. Tắt cửa sổ bằng `(setq *bht-popup* nil)`. Không hiện cửa sổ khi chạy script `.scr` hoặc trong AutoCAD Core Console (kiểm thử tự động không bị treo).
- Palette: lỗi phía Palette (lỗi đọc/ghi bản vẽ, gọi Lisp thất bại, Lisp không cùng phiên bản, xuất Excel lỗi, dữ liệu nhập sai…) hiện MessageBox `BHT`. Khi lệnh gửi từ Palette báo lỗi, vùng trạng thái hiện “Lệnh … THẤT BẠI.” kèm nội dung lỗi trên nền đỏ nhạt (trước đây hiện “đã kết thúc. 1 dòng kết quả.” như thành công); lệnh có cảnh báo hiện nền vàng nhạt.
- Thông báo khi tim TDT còn là proxy giải thích rõ: phiên AutoCAD này chưa nạp TDTSolution 9.1 nên không nhận ra tim tuyến; lưu và đóng AutoCAD, mở lại bằng biểu tượng/profile TDTSolution 9.1 (cắm khóa USB TDT nếu phần mềm yêu cầu), mở bản vẽ rồi chạy lại bước 1. BHT không sửa tim TDT gốc.
- Đồng bộ phiên bản: `BHT-0.4.6-fix3.lsp`, `*bht-version*` = `0.4.6-fix3`, DLL `0.4.6.3`, `PackageContents.xml` `AppVersion` `0.4.6.3` (giữ ProductCode/UpgradeCode), bộ cài fix1 (CMD ASCII + PS1 UTF-8 BOM) với phiên bản `0.4.6-fix3`.
- Dữ liệu bản vẽ, POINT RTK, thuật toán nhãn và lý trình, bố cục Palette và bảng màu fix2 giữ nguyên.

## 0.4.6-fix2 (2026-09-29)

- Sửa lỗi bước “1. Lấy hoặc cập nhật tim từ TDT 9.1” (`BHTTUYENTDT`) báo `BHT lỗi: no function definition: FBOUNDP`: `fboundp` không phải hàm AutoLISP. Thay bằng `bht:fn-defined-p` (kiểm tra `type` là `SUBR`/`USUBR`/`EXRXSUBR`). Đã rà toàn bộ Lisp và C#: không còn hàm ngoài AutoLISP nào khác.
- `BHTTUYENTDT` tự `NETLOAD` `BHT.Bridge.dll` nằm cạnh file Lisp khi hàm `BHTTDT91ROUTE` chưa được đăng ký, rồi mới báo lỗi; báo rõ khi ID tuyến hoặc khoảng cách tối đa không hợp lệ (trước đây lệnh kết thúc im lặng).
- Sửa lỗi `bad function: BHTTDTBLOCK` khi tạo ký hiệu biển báo lúc `BHT.Bridge` chưa đăng ký hàm Lisp (lỗi này thoát khỏi `vl-catch-all-apply` và làm dừng lệnh/phiên kiểm thử S0 từ 0.4.6): nay kiểm tra hàm trước, dùng block nội bộ như thiết kế.
- `BHT.Bridge`: khi tim TDT 9.1 được Explode thành nhiều đoạn Line/Arc nối tiếp, BHT nối các đoạn chung đầu mút thành một Polyline tham chiếu trên layer `BHT_TUYEN_TDT` (trước đây chỉ lấy đoạn dài nhất). Tim TDT gốc vẫn chỉ mở `ForRead`, không sửa.
- Palette đổi sang bảng màu xanh lá: nền `#047857`; nút, tiêu đề, thẻ và dòng đang chọn nền `#065F46` chữ `#D1FAE5`; ô nhập, danh sách, vùng thông tin và trạng thái nền `#D1FAE5` chữ `#065F46`. Thanh thẻ dọc bên phải không còn ô đen và mục chọn xanh dương. Bố cục giữ nguyên.
- Đổi tên nút thẻ RTK “Dấu X 1u + sắp nhãn” thành “Đặt dấu X (cỡ 1) + sắp lại nhãn” cho đúng chức năng (đặt POINT dạng dấu X kích thước 1 đơn vị bản vẽ và sắp lại toàn bộ nhãn). Chức năng không đổi.
- Tiêu đề Palette luôn hiện phiên bản đang chạy (`BHT 0.4.6-fix2 — QUẢN LÝ HIỆN TRẠNG TUYẾN`); không còn hiện “BHT 0.4.4” do AutoCAD khôi phục tên cũ lưu trong profile.
- Đồng bộ phiên bản: `BHT-0.4.6-fix2.lsp`, `*bht-version*` = `0.4.6-fix2`, DLL `0.4.6.2`, `PackageContents.xml` `AppVersion` `0.4.6.2` (giữ ProductCode/UpgradeCode), bộ cài fix1 (CMD ASCII + PS1 UTF-8 BOM) với phiên bản `0.4.6-fix2`.
- Dữ liệu bản vẽ, POINT RTK, thuật toán nhãn và lý trình giữ nguyên như 0.4.6.

## 0.4.6 (2026-09-29)

- Đổi Palette sang bảng màu tối phù hợp AutoCAD: nền than–xanh, chữ thao tác vàng chanh, thông tin cyan và trạng thái lỗi/cảnh báo có màu tương phản riêng.
- Chuyển năm thẻ `Tổng quan / RTK / Ảnh / Hồ sơ / Tuyến` thành thanh dọc sát mép phải, giải phóng chiều ngang và giữ phần nhập liệu theo bố cục nhãn trái–điều khiển phải.
- Nghiên cứu chỉ đọc TDT 9.1 bản thường và DPSurvey 3.3: giữ nguyên nguyên tắc block tỷ lệ 1:1 của TDT, đồng thời áp dụng mô hình kiểu điểm tách biệt dữ liệu của DPSurvey cho BHT.
- Thêm kiểu chữ `BHT_RTK` dùng Arial Unicode với hệ số rộng `0,85` cho lần nhập RTK đầu tiên trên bản vẽ mới; tên, mô tả và cao độ tiếp tục được bố trí như một cụm nhãn.
- Bảo toàn bản vẽ cũ: bản vẽ không có khóa kiểu chữ tiếp tục dùng `BHT_ARIAL`; lần cập nhật đầu không đổi font hoặc dời nhãn legacy. Dấu X vẫn đúng tâm, kích thước 1 unit; POINT RTK không bị di chuyển hoặc làm tròn.
- Đồng bộ `BHT-0.4.6.lsp`, `BHT.Core`, `BHT.Bridge`, `BHT.Palette`, Application Bundle, bộ cài và kiểm thử về phiên bản 0.4.6.
- Kiểm thử phát hành: 62 PASS Core; 172 PASS, 0 FAIL, 1 BLOCKED trên AutoCAD Core Console. Mục BLOCKED là mở giao diện DCL do Core Console không có UI; Palette tối và thanh tab phải được đưa vào checklist nghiệm thu thủ công.

## 0.4.5 (2026-09-29)

- Đã tích hợp TDTSolution 9.1 bản thường tại `C:\Program Files (x86)\TDT Solution 2022\`; không dò hoặc dùng TDT 9.1 Pro.
- Đã thêm `BHTTUYENTDT`: khi module TDT đã nạp và đối tượng tim không còn là proxy, `Tdt91Interop` mở tim `ForRead`, gọi `Entity.Explode` rồi tạo hoặc cập nhật một Polyline riêng trên layer `BHT_TUYEN_TDT`. BHT tính lý trình trên bản sao này và không gọi `vlax-curve-*` trực tiếp trên `TDTDBALIGNMENT`.
- Đã thêm `TdtSignLibrary`: đọc danh mục 412 mã từ bản TDT đang cài, hiện gợi ý `Mã — Tên biển` trong Palette và clone block vector được chọn vào DWG. Tài sản TDT không được sửa và không nằm trong gói BHT.
- Đã chuẩn hóa tỷ lệ hiển thị biển TDT: mặt biển scale `0.2`, cột cao `0.6` đơn vị; biển tự đặt ra ngoài tim theo phía đường, có leader về đúng điểm RTK và nhãn chỉ hiện mã biển cùng lý trình.
- Đã bổ sung báo cáo Excel `.xlsx` Unicode gồm sheet tổng hợp và danh sách biển: STT, công trình, đoạn/gói, loại biển, mã/tên biển, phía, lý trình, tình trạng, số trụ/mặt, trạng thái kiểm tra, ghi chú và ID hồ sơ.
- Đã rút gọn thẻ Tuyến & báo cáo còn sáu thao tác chính; các lệnh ít dùng nằm trong **Công cụ nâng cao**. Báo cáo dài mở trong hộp thoại có thể thay đổi kích thước và sao chép; vùng trạng thái dưới Palette không còn nhận con trỏ nhập.
- Đã cập nhật bố trí nhãn, kích thước chữ mặc định và thứ tự hiển thị; POINT RTK vẫn là dấu X kích thước 1 đơn vị, không di chuyển và không làm tròn tọa độ.
- Đã đồng bộ `BHT-0.4.5.lsp`, `BHT.Core`, `BHT.Bridge`, `BHT.Palette`, Application Bundle và bộ cài về phiên bản 0.4.5.
- Kiểm thử phát hành: 62 PASS Core; 172 PASS, 0 FAIL, 1 BLOCKED trên AutoCAD Core Console. Mục BLOCKED là mở giao diện DCL do Core Console không có UI và được chuyển sang checklist nghiệm thu thủ công.

## 0.4.4 (2026-09-28)

- Hợp nhất thư viện biển báo vào `BHT-0.4.4.lsp`; người dùng chỉ APPLOAD một file Lisp.
- Rà soát 205 ảnh trong KMZ tuyến DT830, ưu tiên các nhóm xuất hiện thực tế: W.207, R.412, W.239a + S.509a, W.245a, W.209, I.414, I.423a, I.428a, I.434a và các biển hạn chế P.
- Sửa các mã sai trong bản nháp: tốc độ tối đa là P.127, P.102 là cấm đi ngược chiều; giao nhau với đường ưu tiên là W.208, W.201 là chỗ ngoặt; W.245 là đi chậm; I.401/I.407 không phải cột Km/chỉ hướng đường.
- Block biển báo có điểm chèn tại chân cột `(0,0)`, tên định nghĩa mang hậu tố `V044`, màu và hình học độc lập với layer; hồ sơ `BIEN_BAO` tự chọn block theo trường `ma_hieu`.
- Thêm `BHTBBDANHMUC`; `BHTBLOCK` có lựa chọn `D` để xem danh mục chuẩn trước khi nạp DWG tùy chọn.
- Kiểm tra thư viện cục bộ của TDT Solution 2022: tách được 5 DWG chứa 329 block vector và xuất danh mục 412 biển ra CSV UTF-8 BOM; bổ sung script kiểm tra chỉ đọc, không đóng gói tài sản TDT.
- Thêm DWG/PNG gallery của 19 block và hồi quy hình học, mã hiệu, tải Lisp, dữ liệu/ảnh/tuyến/plugin: 228 PASS, 0 FAIL.

## 0.4.3 (2026-09-28)

- Đồng bộ chặt phiên bản Lisp/.NET; tiêu đề Palette lấy trực tiếp từ assembly và bộ cài chặn khi AutoCAD còn chạy để tránh DLL cũ bị giữ trong bộ nhớ.
- Palette mở mặc định bên trái rộng 430 px, dùng bảng màu xanh mới, bỏ hàng gợi ý rời bị cắt chữ và có vùng thông báo nhiều dòng.
- Thêm bộ đệm `bht:api-messages`: kết quả lệnh tương tác được hiện trong Palette sau khi lệnh kết thúc.
- CSV dùng UTF-8 BOM với tiêu đề tiếng Việt có dấu.
- Nhãn ký hiệu hiển thị tên nghiệp vụ và mã/lý trình, ví dụ `Cọc tiêu Km 48+500`, không hiện ID hồ sơ nội bộ.
- Vẽ lại block mặc định Cọc tiêu và Cột Km theo mẫu; dùng tên định nghĩa phiên bản mới để cập nhật được cả bản vẽ đã chứa block cũ.

## 0.4.2 (2026-09-27)

- Điểm RTK mặc định dùng `PDMODE=3` (dấu X) và `PDSIZE=1`; thêm `BHTKIEUDIEM` và nút Palette để đổi kích thước, áp dụng lại kiểu điểm và sắp nhãn.
- Mở rộng bố trí nhãn lên 64 vị trí ứng viên, tính cả vùng dấu X; bộ dữ liệu hồi quy 526 điểm còn 0/1574 nhãn chồng lấn sau khi sắp.
- Sửa bố cục thẻ **Ảnh** để danh sách, ảnh xem trước và nút thao tác không che nhau; thêm hướng dẫn và nút nhập KMZ/chỉ lại thư mục khi chưa có ảnh.
- Thẻ **Hồ sơ** cho nhập, xóa hoặc tính lý trình; chấp nhận `Km39+050.5`, `39+050,5` hoặc số mét và lưu trạng thái `NHAP_TAY`.
- Danh sách ảnh của hồ sơ hiện rõ `Chưa có ảnh` và điều hướng sang thẻ Ảnh.
- Nhãn ký hiệu đặt phía trên block và luôn bắt đầu bằng `object_id`, sau đó là mã hiệu.
- Thêm `BHTBLOCK`: nạp một DWG làm block tùy chọn cho từng nhóm, lấy `INSBASE` làm tâm chèn, tự giữ hệ số đơn vị và có thể trở lại block mặc định.
- Giữ nguyên hợp đồng dữ liệu `BHT_V02` và khả năng đọc bản vẽ 0.3.2–0.4.1.

## 0.4.1 (2026-09-27)

- `BTH` và `BHT` cùng mở một .NET Palette duy nhất; giữ `BHTPALETTE` làm bí danh tương thích.
- Thêm Autodesk Application Bundle và bộ cài tự động. Cách APPLOAD tự nạp DLL cạnh file Lisp, không cần người dùng chạy `NETLOAD`.
- Chuyển DCL sang lệnh dự phòng `BHTDCL`; sửa lỗi font bằng tệp DCL UTF-8 BOM.
- Rút gọn tên thẻ để không bị cắt chữ; bổ sung nhập CSV, nhập KMZ và tiếp tục quy trình ở thẻ Tổng quan.
- Cho phép chọn điểm trực tiếp trên CAD để tạo hoặc bổ sung hồ sơ trong khi Palette vẫn mở.
- Đồng bộ chọn điểm hai chiều giữa danh sách và bản vẽ; tiếp tục tự làm mới khi đổi tài liệu hoặc dữ liệu DWG.
- Giữ nguyên hợp đồng dữ liệu `BHT_V02` và các lệnh Lisp hiện có.

## 0.4.0 (2026-09-27)
* Plugin .NET (net48, x64): BHT.Core, BHT.Bridge, BHT.Palette; lệnh `BHTPALETTE` mở palette
  "BHT — QUẢN LÝ HIỆN TRẠNG TUYẾN" (5 thẻ: Tổng quan, Điểm khảo sát, Ảnh TimeMark, Hồ sơ đối tượng, Tuyến & báo cáo).
* BHT-0.4.0.lsp (từ 0.3.3): hàm API `bht:api-*` cho plugin (vl-acad-defun); `BHTPALETTE` trong Lisp chỉ hướng dẫn
  NETLOAD khi plugin chưa nạp; BHTTEST 46 mục.
* BHTTHUTUVE: nhận ảnh nền IRT dạng lưới nhiều tile (mỗi tile một IMAGE, kể cả trên layer 0) theo đường dẫn thư mục
  `IRT\` / `IRT.cache` (mẫu `irt_mau_thumuc`, cấu hình BHTTHUTUVE > C); đọc cấu hình một lần cho cả lưới; báo số tile
  trên layer khóa; không bao giờ coi ảnh BHT là IRT.
* Định dạng dữ liệu DWG không đổi so với 0.3.3 (docs/DATA_CONTRACT.md).

## 0.3.3 và cũ hơn
Xem CHANGELOG trong các gói phát hành `release/BHT-0.3.x`.
## v0.6.9 — 2026-10-02

- Sửa mũi tên chọn/đảo chiều tuyến: hiển thị đầu mũi tên đặc, giữ hình trong lúc xác nhận và REGEN; dọn hình khi chấp nhận, hủy hoặc lỗi. Hỗ trợ UCS xoay và điểm đầu/cuối tuyến.
- Đọc nhãn Km trong đối tượng TDT gốc và block lồng nhau; đọc riêng từng thuộc tính và loại nhãn trùng. Tuyến TDT nguồn chỉ được mở để đọc.
- Lấy vị trí cọc TDT tại vạch trên tim, tránh dùng vị trí chữ gây lệch khoảng 0,75 m. Nếu không nhận diện được vạch, giữ cách chiếu nhãn để người dùng kiểm tra.
- Sửa lỗi `eDegenerateGeometry` khi cập nhật lại Polyline tham chiếu có cung; giữ nguyên handle, không tạo tuyến trùng.
- Kiểm tra trên bản sao bản vẽ TDT thực tế: bản cũ đọc 0 cọc, bản mới đọc đủ 371 cọc; giữ hai cảnh báo để người dùng xét duyệt. Lưu/mở lại giữ 371 cọc đọc được và 369 mốc đã nạp trong ca thử.

