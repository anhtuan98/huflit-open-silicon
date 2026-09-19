# Hướng dẫn viết testbench cocotb — đọc từng dòng code

| | |
|---|---|
| **Chương trình** | HUFLIT Open Silicon (codename Vega) |
| **Ví dụ minh hoạ** | [`designs/counter3/verify/test_counter3.py`](../../designs/counter3/verify/test_counter3.py) |
| **Đối tượng đọc** | Người sắp viết testbench cocotb đầu tiên |
| **Bản gốc tiếng Anh** | [`docs/cocotb-testbench-guide.md`](../cocotb-testbench-guide.md) |
| **Vì sao quan trọng với chương trình** | Đây chính xác là kỹ năng Cổng 0 cần (`docs/OPEN_SILICON_KICKOFF.md` §4, tuần 7-12): viết testbench cocotb cho RTL của người khác (`obi_uart`/`apb_timer`), tìm bug thật, gửi PR |
| **Trạng thái** | Tài liệu khái niệm — không phải một mốc chương trình, thuộc mục đích #2 của `docs/vi/` |

## 0. Ý tưởng cốt lõi trước khi đọc code

cocotb làm một việc: cho phép viết testbench **bằng Python thay vì
Verilog**, rồi điều khiển mạch RTL đang chạy trong trình mô phỏng
(Verilator, ở đây) — bơm tín hiệu vào, đọc tín hiệu ra, so sánh với kỳ
vọng.

Điểm lạ nhất với người mới: test không chạy tuần tự như hàm Python bình
thường, mà chạy theo **thời gian mô phỏng**. Muốn "chờ tới cạnh lên tiếp
theo của clock" thì phải `await` — nhường quyền điều khiển lại cho bộ mô
phỏng cho tới khi sự kiện đó xảy ra. Đây là lý do mọi test cocotb đều là
hàm `async def`.

## 1. `Makefile` — cầu nối giữa Python và Verilator

```makefile
SIM ?= verilator
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(shell pwd)/../src/counter3.v
TOPLEVEL = counter3
MODULE = test_counter3
include $(shell cocotb-config --makefiles)/Makefile.sim
```

Chỉ cần khai báo 4 thứ, phần còn lại cocotb tự lo:
- `SIM` — dùng trình mô phỏng nào (Verilator)
- `VERILOG_SOURCES` — file RTL nào
- `TOPLEVEL` — module nào là "gốc" (`counter3`)
- `MODULE` — file Python nào chứa test (`test_counter3.py`, không có đuôi
  `.py`)

Chạy `make` sẽ: biên dịch `counter3.v` thành mô hình C++ (qua Verilator)
→ chạy nó → nạp `test_counter3.py` → gọi từng hàm có decorator
`@cocotb.test()`.

## 2. Giải phẫu `test_counter3.py` từng dòng

```python
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
```
Ba thứ cần nhất: `cocotb` (khung test), `Clock` (helper sinh xung clock),
`RisingEdge` (helper "chờ tới cạnh lên").

### Test đầu tiên — đơn giản nhất, đọc trước

```python
@cocotb.test()
async def test_reset_clears_count(dut):
    """count is 0 while rst is held."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert int(dut.count.value) == 0
```

- `@cocotb.test()` — decorator này báo cho cocotb: "đây là một test case,
  hãy chạy nó". Một file có thể có nhiều hàm như vậy, mỗi hàm là 1 test
  độc lập.
- `dut` — tham số bắt buộc, là **handle trỏ tới mạch đang mô phỏng**.
  `dut.rst`, `dut.clk`, `dut.count` chính là 3 cổng của `counter3.v`
  (`rst`, `clk`, `count`) — cocotb tự map theo đúng tên trong RTL, không
  cần khai báo gì thêm.
- `cocotb.start_soon(Clock(...).start())` — **quan trọng**: dòng này khởi
  động một coroutine clock chạy **song song, vô thời hạn**, tự sinh xung
  clock 10ns liên tục ở nền. `start_soon` nghĩa là "chạy nó, nhưng đừng
  chờ nó xong" (clock không bao giờ "xong" cả) — khác với `await` là "chờ
  tới khi xong mới đi tiếp".
- `dut.rst.value = 1` — gán giá trị vào cổng `rst`. Đây là cách "bơm tín
  hiệu vào" mạch.
- `await RisingEdge(dut.clk)` — dừng hàm test tại đây, nhường lại cho bộ
  mô phỏng, cho tới khi có 1 cạnh lên của `clk` xảy ra thì mới chạy tiếp
  dòng sau. Gọi 2 lần = chờ 2 xung clock.
- `assert int(dut.count.value) == 0` — đọc giá trị hiện tại của `count`,
  ép về kiểu int Python, so sánh. Nếu sai → `AssertionError` → cocotb ghi
  nhận test này **FAIL**.

**Tóm gọn 1 câu:** bật clock chạy nền → giữ `rst=1` → chờ 2 xung → kiểm
tra `count` phải bằng 0.

### Hàm phụ trợ `reset()` — tái sử dụng logic

```python
async def reset(dut):
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
```

Không có `@cocotb.test()` — đây **không phải** một test case, chỉ là một
hàm `async` bình thường để nhiều test dùng chung "quy trình reset chuẩn":
giữ reset 2 chu kỳ, thả ra, rồi chờ thêm 1 chu kỳ nữa để chắc chắn mạch
đã "chạy ổn định" trước khi bắt đầu kiểm tra thật.

### Test thứ hai — phức tạp hơn, có vòng lặp

```python
@cocotb.test()
async def test_counts_and_wraps(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    previous = int(dut.count.value)
    for _ in range(16):
        await RisingEdge(dut.clk)
        current = int(dut.count.value)
        expected = (previous + 1) % 8
        assert current == expected, f"expected {expected} after {previous}, got {current}"
        previous = current
```

- `await reset(dut)` — gọi hàm phụ trợ ở trên, **có `await`** vì lần này
  cần chờ nó chạy xong thật sự (không phải chạy nền như Clock).
- Vòng lặp 16 lần (gấp đôi chu kỳ đếm 8 giá trị, để chắc chắn thấy được
  cả điểm quay vòng 7→0 ít nhất 2 lần, không phải tình cờ).
- **Điểm quan trọng nhất của bài test này:** `expected = (previous + 1) %
  8` — kỳ vọng được tính **dựa trên giá trị quan sát được ở chu kỳ
  trước**, không phải dựa trên "chu kỳ thứ mấy kể từ lúc reset". Đây
  chính là bài học từ lỗi thật đã gặp (`docs/counter3-technical-report.md`
  §4.1): bản đầu tiên assert cứng "count phải bằng 1 ở đúng chu kỳ đầu
  tiên sau reset" — sai không đều đặn, vì gán `.value` ngay sau `await
  RisingEdge` không đảm bảo có hiệu lực ngay ở cạnh kế tiếp (chi tiết lập
  lịch của trình mô phỏng, không phải bug RTL). **Quy tắc rút ra: assert
  tương đối với giá trị vừa quan sát được, tránh assert tuyệt đối gắn
  với một mốc thời gian giả định.**

## 3. Chạy thử thật

```bash
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/counter3/verify \
  librelane-dev --skip make
```

Kết quả in ra terminal dạng bảng PASS/FAIL cho từng `@cocotb.test()`, và
cocotb còn ghi ra `results.xml` (định dạng JUnit) — chính file mà một
pipeline CI sẽ đọc để tự động fail build nếu có test đỏ.

## 4. Bài tập nhỏ nên làm trước khi đi tiếp

Thêm 1 test mới vào cuối `test_counter3.py`: kiểm tra **reset giữa chừng
khi đang đếm** (không phải chỉ reset lúc đầu) — đếm vài chu kỳ, bất ngờ
đặt `rst.value = 1` một chu kỳ, rồi kiểm tra `count` về lại 0 ngay sau
đó. Đây là một trường hợp mà nếu RTL viết sai kiểu `if (rst &&
something)` thay vì `if (rst)` thì sẽ lộ ra ngay — một pattern rất hay
gặp khi tìm bug thật trên IP người khác, chính xác là việc Cổng 0 sẽ làm
(`obi_uart`).

## Tham khảo

- `designs/counter3/verify/test_counter3.py`, `Makefile` — code thật mà
  bài hướng dẫn này bám vào
- `docs/counter3-technical-report.md` §4 — phần verification đầy đủ, kèm
  chi tiết hơn về cái bẫy off-by-one
- `docs/chip_making_a_to_z.md` / `docs/vi/chip-making-a-to-z.md` — "verify
  RTL" nằm ở đâu trong toàn bộ luồng RTL-to-GDSII
- cocotb documentation: `docs.cocotb.org`
