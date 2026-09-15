# CLAUDE.md — Vega (HUFLIT Open Silicon)

Hướng dẫn cho Claude Code khi làm việc trong repo này.

## Xưng hô

- Khi hội thoại bằng **tiếng Việt**: gọi người dùng là **"thầy"**, tự xưng
  **"em"**.
- Khi hội thoại bằng **tiếng Anh**: dùng "you"/"I" bình thường như tiếng Anh
  chuẩn — **không** chèn "thầy"/"em" vào câu tiếng Anh (thầy đã sửa lại điều
  này 2026-09-14, ghi đè quy tắc cũ trong bản trước của file này).

## Ngôn ngữ làm việc (2026-09-14)

- **Từ nay ngôn ngữ chính của hội thoại là tiếng Anh** — dự án công khai,
  đóng góp cho cộng đồng quốc tế. Thầy sẽ gõ prompt bằng tiếng Anh; trả lời
  bằng tiếng Anh chuẩn (you/I, xem mục Xưng hô).
- Thỉnh thoảng thầy sẽ chèn từ/cụm tiếng Việt vào prompt khi chưa biết thuật
  ngữ tiếng Anh tương ứng (thường là thuật ngữ chuyên ngành EDA/verification).
  Khi gặp trường hợp này:
  - Nhận diện đúng phần tiếng Việt đó, đề xuất thuật ngữ tiếng Anh chuẩn
    (thuật ngữ ngành dùng trong LibreLane/OpenROAD/cocotb docs, không tự
    chế), kèm giải thích ngắn 1 câu nếu là khái niệm mới.
  - Không âm thầm dịch cả câu rồi trả lời như không có gì — nêu rõ mình vừa
    sửa/chọn từ gì, để thầy học được thuật ngữ đó luôn.
  - Toàn bộ code, docs (ngoài `docs/vi/`), commit message, PR description
    vẫn tiếng Anh (ADR-OS-004).

## Bối cảnh dự án

- Đây là chương trình **HUFLIT Open Silicon**, codename `Vega` (xem `brainstorming/code_naming_guide.md`).
- Nguồn sự thật cho định vị, lộ trình, ADR: `docs/OPEN_SILICON_KICKOFF.md` (bản kickoff) và `PROJECT_INSTRUCTIONS.md` (nguồn sự thật cho quyết định đang tiến hóa — cập nhật liên tục).
- Giai đoạn hiện tại: **Giai đoạn 0** — xác thực con người, không lập tổ chức, không mua sắm, không công bố. Xem §4 và §11 của kickoff doc.
- Quy ước repo, DevSecOps: dùng skill `huflit-dev-op-skill`. Bảo mật ứng dụng: `huflit-secure-by-design`. Phát hiện & ứng phó sự cố: `huflit-threat-detect`. Thiết kế test: `huflit-test-design`. Web style (nếu có dashboard/report): `huflit-web-style`.
- Bộ nhớ agent cho repo này: `wiki/` (theo skill `wiki-memory`) — đọc `wiki/index.md` trước khi khám phá source, ghi hint sau khi khám phá sâu.
- `docs/vi/` — tài liệu tiếng Việt, hai mục đích song song (xem
  `docs/vi/README.md`): (1) bản dịch tài liệu gốc gửi ngược upstream (Giai
  đoạn 1), (2) tài liệu học tập nguyên bản tiếng Việt cho sinh viên HUFLIT
  (khái niệm, glossary Anh-Việt các thuật ngữ EDA/verification gặp trong quá
  trình làm) — không bắt buộc gửi upstream, mục tiêu là hạ rào cản ngôn ngữ
  cho người học trong nước.

## Scratch / temp files

- Dùng thư mục **`./tmp`** trong repo này cho cache và file tạm — không dùng
  `/tmp` hệ thống hay scratchpad ngoài repo. Nội dung `tmp/` bị `.gitignore`,
  chỉ `tmp/.gitkeep` được track.
- **Tuyệt đối không dùng tool Artifact** (không publish artifact.claude.ai)
  cho dự án này. Báo cáo, mockup, file output đều để dưới dạng file trong
  repo (ví dụ `tmp/` cho bản nháp, `docs/` cho tài liệu chính thức).

## Nguyên tắc vận hành (nhắc lại từ kickoff doc)

Mỗi khi cân nhắc một việc, hỏi: *Việc này tạo ra tài sản công khai mang tên HUFLIT, hay chỉ tạo ra chuyển động?* Nếu là chuyển động — dừng lại.
