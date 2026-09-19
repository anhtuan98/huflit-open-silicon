# docs/vi — Tài liệu tiếng Việt

Thư mục này có hai mục đích song song:

## 1. Bản dịch gửi ngược upstream

Bản dịch tiếng Việt của tài liệu gốc thuộc các dự án mã nguồn mở mà chương
trình đóng góp (LibreLane, cocotb, IHP, v.v.), theo Giai đoạn 1 của lộ trình
(`docs/OPEN_SILICON_KICKOFF.md` §4).

**Nguyên tắc:** mỗi bản dịch loại này phải được **gửi ngược lại dự án gốc**
(upstream PR), không chỉ nằm ở đây. Đây là tài sản công khai mang tên
HUFLIT, không phải bản dịch nội bộ dùng riêng.

## 2. Tài liệu học tập gốc tiếng Việt cho sinh viên

Ghi chú, giải thích khái niệm, và glossary Anh-Việt các thuật ngữ EDA/
verification (LibreLane, cocotb, DRC/LVS/STA, v.v.) gom lại trong quá trình
làm việc — viết trực tiếp bằng tiếng Việt, **không** cần gửi upstream (nội
dung upstream vẫn là tiếng Anh, xem `CLAUDE.md` § Ngôn ngữ làm việc).
Mục tiêu: hạ rào cản ngôn ngữ cho sinh viên Việt Nam muốn tiếp cận mảng này.

Đã có:

- [`chip-making-a-to-z.md`](chip-making-a-to-z.md) — toàn cảnh quy trình
  RTL-to-GDSII theo khái niệm (không gắn với một mốc cụ thể), dùng
  `counter3` làm ví dụ minh hoạ, kèm bảng thuật ngữ Anh-Việt. Phỏng theo
  bản gốc tiếng Anh
  [`docs/chip_making_a_to_z.md`](../chip_making_a_to_z.md).
- [`cocotb-huong-dan-viet-testbench.md`](cocotb-huong-dan-viet-testbench.md)
  — hướng dẫn đọc từng dòng code testbench cocotb, dùng
  `test_counter3.py` làm ví dụ. Phỏng theo bản gốc tiếng Anh
  [`docs/cocotb-testbench-guide.md`](../cocotb-testbench-guide.md).
- [`counter3-bao-cao-ky-thuat.md`](counter3-bao-cao-ky-thuat.md) — báo cáo
  kỹ thuật thiết kế `counter3` (tuần 3-6 Giai đoạn 0), kèm bảng thuật ngữ
  Anh-Việt. Phỏng theo bản gốc tiếng Anh
  [`docs/counter3-technical-report.md`](../counter3-technical-report.md).
- [`counter3-slides.md`](counter3-slides.md) — slide thuyết trình dựa trên
  báo cáo trên.
- [`uart-bao-cao-ky-thuat.md`](uart-bao-cao-ky-thuat.md) — báo cáo kỹ
  thuật thiết kế `uart_top` (thiết kế học tập thứ hai, tùy chọn), kèm
  bảng thuật ngữ Anh-Việt bổ sung. Phỏng theo bản gốc tiếng Anh
  [`docs/uart-technical-report.md`](../uart-technical-report.md).
- [`uart-slides.md`](uart-slides.md) — slide thuyết trình dựa trên báo
  cáo trên.
- [`picorv32-bao-cao-ky-thuat.md`](picorv32-bao-cao-ky-thuat.md) — nhật
  ký debug đầy đủ (9 lần thử) cho thiết kế học tập thứ ba, `picorv32`
  (core RISC-V thật, ~19k instance), kèm bảng thuật ngữ Anh-Việt bổ
  sung. Phỏng theo bản gốc tiếng Anh
  [`docs/picorv32-technical-report.md`](../picorv32-technical-report.md).
  Mục 1 của bài trả lời thẳng câu hỏi "có đáng công bố không".

Chưa có bản dịch nào ở mục 1 — Giai đoạn 0 chưa đến bước bản địa hóa
(Giai đoạn 1, xem `backlog.md`).
