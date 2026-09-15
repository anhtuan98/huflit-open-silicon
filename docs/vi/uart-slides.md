---
marp: true
paginate: true
title: uart_top -- Thiết kế RTL-to-GDSII thứ hai
---

# uart_top

**Thiết kế RTL-to-GDSII thứ hai**

HUFLIT Open Silicon (Vega) — Giai đoạn 0, mở rộng tùy chọn tuần 3-6
Báo cáo đầy đủ: `docs/vi/uart-bao-cao-ky-thuat.md`

---

## Vì sao làm thêm thiết kế thứ hai

- `counter3` một mình đã đủ thỏa cổng tuần 3-6.
- Hai lý do vẫn làm thêm:
  1. **Chạm nhiều hơn vào luồng** -- FSM thật, nhiều cell hơn, một input
     trông như bất đồng bộ từ bên ngoài.
  2. **Diễn tập cho Cổng 0** -- `obi_uart` (pulp-platform/obi_peripherals)
     đã được chọn làm mục tiêu upstream thật; testbench đóng khung byte
     của thiết kế này là bài khởi động trực tiếp cho việc đó.

---

## Thiết kế

```verilog
module uart_top #(parameter CLKS_PER_BIT = 4) (
    input  wire       clk, rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output wire       tx_serial, tx_busy,
    input  wire       rx_serial,
    output wire [7:0] rx_data,
    output wire       rx_done
);
```

Khung 8N1 (start=0, 8 bit dữ liệu LSB trước, stop=1). `tx_serial` /
`rx_serial` là hai cổng độc lập -- loopback nằm bên ngoài.

---

## TX: FSM 4 trạng thái

`IDLE -> START -> DATA -> STOP -> IDLE`, mỗi trạng thái giữ
`CLKS_PER_BIT` chu kỳ. Không có miền clock baud riêng -- chỉ là bộ đếm
dựa trên `clk`. `tx_busy` đánh dấu suốt thời gian gửi một khung.

## RX: Lấy mẫu giữa bit + bộ đồng bộ hóa

- Lấy mẫu mỗi bit gần **giữa**, không phải ở cạnh -- chịu được sai lệch
  clock nhỏ với transmitter bên ngoài.
- `rx_serial` đi qua **2 tầng flip-flop đồng bộ hóa** trước khi FSM đọc
  -- biện pháp chống metastability chuẩn cho input bất đồng bộ (khái
  niệm "CDC" từ kickoff doc §5.3), dù ở đây chỉ có một miền clock.

---

## Kiểm thử: 3/3 test pass

1. `test_tx_frames_byte` -- 0xA5 (không toàn 0/1, bắt lỗi thứ tự bit),
   kiểm tra trọn khung 10 bit.
2. `test_rx_decodes_byte` -- lái một khung 8N1 từ ngoài, kiểm tra giải mã.
3. `test_tx_rx_loopback` -- dây loopback phần mềm, 5 byte trường hợp
   biên.

Cùng bài học như `counter3`: hàm hỗ trợ TX đợi trên **chuyển trạng thái
của `tx_busy`**, không giả định số chu kỳ cố định.

---

## Config vật lý: điều bất ngờ

```yaml
DESIGN_NAME: uart_top
VERILOG_FILES: dir::src/*.v
CLOCK_PERIOD: 10
CLOCK_PORT: clk
DESIGN_REPAIR_MAX_SLEW_PCT: 25
GRT_DESIGN_REPAIR_MAX_SLEW_PCT: 15
```

**Không `FP_SIZING: absolute`, không `DIE_AREA`, không tuning PDN** --
khác hẳn `counter3`. Sizing mặc định tự đạt 75,3% utilization.

---

## Phát hiện #1: Cách vá cho thiết kế tí hon không áp dụng chung

- `counter3` (3 flip-flop, ~22 cell) cần tinh chỉnh floorplan/PDN thủ
  công -- sizing mặc định tính ra die quá nhỏ.
- `uart_top` (50 sequential, ~290 stdcell) **không cần gì cả**.
- **Quy tắc:** thử config tối giản trước. Chỉ dùng `FP_SIZING: absolute`
  / tuning PDN khi `PDN-0185`/`DPL-0036` thật sự xuất hiện. Đừng copy
  `DIE_AREA` của `counter3` lên mọi thiết kế mới một cách máy móc.

---

## Phát hiện #2: Một cạm bẫy ký duyệt mới

Lần đầu: **4 vi phạm max-slew**, chỉ ở corner `ss`, một net fanout 3,
~7% vượt giới hạn.

**Nguyên nhân gốc:** các bước resizer chạy *trước* khi đi dây chi tiết
-- tối ưu theo ký sinh ước lượng, không phải ký sinh cuối cùng sau đi
dây. Một khoảng chênh nhỏ có thể tồn tại tới tận ký duyệt cuối.

**Cách sửa:** nới biên của resizer --
`DESIGN_REPAIR_MAX_SLEW_PCT: 25` / `GRT_..._PCT: 15` (mặc định 20/10).
4 -> 0 vi phạm, không cần đổi gì khác.

---

## Cạm bẫy debug đáng biết

Ở lần chạy lỗi, `Checker.MaxSlewViolations` in ra:
- một khối `WARNING` nêu tên corner vi phạm, **rồi**
- một dòng `VERBOSE`: *"No max slew violations found"*

Cùng một bước, cùng một lần chạy. Luồng vẫn thoát mã 0 dù thế nào.

**Tin vào `design__max_slew_violation__count` trong `metrics.json`,
không tin vào dòng log nào cả.**

---

## Kết quả -- Cell & diện tích

| Chỉ số | Giá trị |
|---|---|
| Standard cell | 290 (50 seq + 105 comb + buffer) |
| Fill / tap cell | 207 / 48 |
| Diện tích die | 72,3 x 83,0 um (5.997 um^2) |
| Độ lấp đầy core | **75,3%** (so với 5,24% của counter3) |

---

## Kết quả -- Timing, công suất, ký duyệt

| Chỉ số | Giá trị |
|---|---|
| Setup / hold slack xấu nhất (9 PVT corner) | +2,52 ns / +0,12 ns |
| Vi phạm setup / hold / slew | 0 / 0 / 0 |
| Tổng công suất (corner danh định) | ≈ 566,8 nW |
| DRC (Magic + KLayout) / LVS / antenna | 0 / 0 / 0 |

Dư địa hẹp hơn `counter3` -- làm việc thật nhiều hơn mỗi chu kỳ, cây
clock cao hơn (16 buffer so với 4). Vẫn dương thoải mái.

---

## Tái lập kết quả

```bash
docker compose -f docker/docker-compose.yml build
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/uart/verify \
  librelane-dev --skip make
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/uart \
  librelane-dev --skip \
  librelane -p sky130A -s sky130_fd_sc_hd config.yaml
```

---

## Vị trí trong lộ trình

- Cổng tuần 3-6 đã thỏa mãn bởi `counter3` -- đây là phần cộng thêm.
- Bước kế tiếp thật: thăm dò maintainer `pulp-platform/obi_peripherals`,
  rồi tái dùng mẫu test đóng khung byte của testbench này cho testbench
  cocotb của `obi_uart` (Cổng 0, tuần 7-12).

---

## Hỏi đáp

`docs/vi/uart-bao-cao-ky-thuat.md` — báo cáo đầy đủ
`wiki/uart-signoff-sizing-and-slew-margin.md` — chi tiết sizing & slew margin
`docs/vi/counter3-bao-cao-ky-thuat.md` — thiết kế đầu tiên, nền tảng của bài này
