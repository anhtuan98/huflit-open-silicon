# CLAUDE.md — Vega (HUFLIT Open Silicon)

Hướng dẫn cho Claude Code khi làm việc trong repo này.

## Xưng hô

- Gọi người dùng là **"thầy"**.
- Tự xưng là **"em"**.
- Áp dụng cho mọi hội thoại trong repo này, kể cả khi trả lời bằng tiếng Anh trong code/docs (nội dung tiếng Anh giữ nguyên chuẩn tiếng Anh; quy tắc xưng hô chỉ áp dụng cho lời thoại tiếng Việt với thầy).

## Bối cảnh dự án

- Đây là chương trình **HUFLIT Open Silicon**, codename `Vega` (xem `brainstorming/code_naming_guide.md`).
- Nguồn sự thật cho định vị, lộ trình, ADR: `docs/OPEN_SILICON_KICKOFF.md` (bản kickoff) và `PROJECT_INSTRUCTIONS.md` (nguồn sự thật cho quyết định đang tiến hóa — cập nhật liên tục).
- Giai đoạn hiện tại: **Giai đoạn 0** — xác thực con người, không lập tổ chức, không mua sắm, không công bố. Xem §4 và §11 của kickoff doc.
- Quy ước repo, DevSecOps: dùng skill `huflit-dev-op-skill`. Bảo mật ứng dụng: `huflit-secure-by-design`. Phát hiện & ứng phó sự cố: `huflit-threat-detect`. Thiết kế test: `huflit-test-design`. Web style (nếu có dashboard/report): `huflit-web-style`.
- Bộ nhớ agent cho repo này: `wiki/` (theo skill `wiki-memory`) — đọc `wiki/index.md` trước khi khám phá source, ghi hint sau khi khám phá sâu.

## Scratch / temp files

- Dùng thư mục **`./tmp`** trong repo này cho cache và file tạm — không dùng
  `/tmp` hệ thống hay scratchpad ngoài repo. Nội dung `tmp/` bị `.gitignore`,
  chỉ `tmp/.gitkeep` được track.
- **Tuyệt đối không dùng tool Artifact** (không publish artifact.claude.ai)
  cho dự án này. Báo cáo, mockup, file output đều để dưới dạng file trong
  repo (ví dụ `tmp/` cho bản nháp, `docs/` cho tài liệu chính thức).

## Nguyên tắc vận hành (nhắc lại từ kickoff doc)

Mỗi khi cân nhắc một việc, hỏi: *Việc này tạo ra tài sản công khai mang tên HUFLIT, hay chỉ tạo ra chuyển động?* Nếu là chuyển động — dừng lại.
