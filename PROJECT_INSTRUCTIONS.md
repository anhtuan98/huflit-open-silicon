# PROJECT_INSTRUCTIONS.md — Vega / HUFLIT Open Silicon

Nguồn sự thật cho các quyết định **đang tiến hóa** của chương trình. Tài liệu
chuyên đề, ổn định hơn (bối cảnh khảo sát, ADR khởi đầu, lộ trình đầy đủ) nằm ở
[`docs/OPEN_SILICON_KICKOFF.md`](docs/OPEN_SILICON_KICKOFF.md) — tài liệu này
chỉ ghi những gì đã **thay đổi hoặc được xác nhận thêm** so với bản kickoff.

## Trạng thái hiện tại

- **Giai đoạn:** 0 (90 ngày đầu, bắt đầu 2026-09-14) — xác thực con người.
- **Người dẫn Giai đoạn 0:** Nguyễn Anh Tuấn (xác nhận 2026-09-14). Việc chặn
  tất cả việc khác (kickoff doc §11) đã được giải quyết — có thể bắt đầu tuần
  1-2 (§4).
- **Cổng đang chờ:** Cổng 0 — 1 PR được merge vào một dự án quốc tế trước
  2026-12-13 (90 ngày từ ngày xác nhận người dẫn).
- **Hạ tầng tuần 1-2 đã xong (2026-09-14):** IIC-OSIC-TOOLS qua Docker chạy
  được trên máy Ubuntu (amd64; image cũng có bản arm64 native cho macOS/Apple
  Silicon). `librelane --smoke-test` Pass. Ví dụ `spm` chạy trọn RTL→GDSII,
  DRC/LVS/Antenna Pass, GDSII giữ lại tại `tmp/spm_example/` (local, không
  commit). Chi tiết: `backlog.md`.
- **Repo:** đang tạo remote GitHub công khai (2026-09-14) — theo ADR-OS-004,
  đúng lúc vì đã có người dẫn xác nhận.

## Phi mục tiêu đang hiệu lực (nhắc lại — xem kickoff doc §1.2)

Không mở ngành, không lập trung tâm/lab, không mua thiết bị đo đạc, không
tape-out, không công bố truyền thông, không cạnh tranh trực tiếp với FPT/Viettel
trong mảng verification thương mại.

## Cách cập nhật tài liệu này

- Mỗi lần một quyết định thay đổi hoặc một mốc/cổng được xác nhận đạt/không đạt,
  thêm một mục ngắn vào đây kèm ngày, và ghi ADR mới trong `docs/decisions/`
  nếu quyết định có đánh đổi.
- Khi một giai đoạn chuyển tiếp (0 → 1 → 2), cập nhật mục "Trạng thái hiện tại"
  ở trên.
- Không lặp lại nội dung đã có trong kickoff doc — chỉ ghi phần chênh lệch.

## Lịch sử cập nhật

| Ngày | Thay đổi |
|---|---|
| 2026-09-14 | Khởi tạo từ `OPEN_SILICON_KICKOFF.md` v0.1. Giai đoạn 0 bắt đầu, chưa có người dẫn. |
| 2026-09-14 | Xác nhận người dẫn Giai đoạn 0: Nguyễn Anh Tuấn. Hoàn tất mốc hạ tầng tuần 1-2 (Docker + smoke test). Bắt đầu tạo remote GitHub công khai. |
| 2026-09-16 | ADR-OS-007: thuê VM cloud theo giờ cho compute nặng trong Giai đoạn 0-1, chỉ tính mua server thật khi chương trình tự nuôi sống được về tài chính (mốc cụ thể chưa xác định). Xem `docs/decisions/ADR-OS-007-rent-compute-before-buying.md`. |
