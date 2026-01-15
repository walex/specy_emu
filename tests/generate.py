import json
import os
from pathlib import Path
from itertools import product

DATA_PATH = Path(r"C:\Users\wadrw\Documents\develop\projects\personal\z80\v1")
OUT_PATH = Path(
    r"C:\Users\wadrw\Documents\develop\projects\personal\sinclair_spec_emu\test\json"
)


def entero_a_binario(valor, n_bits):
    return format(valor, f"0{n_bits}b").encode()


def posiciones_activas(a):
    return [i for i, b in enumerate(a) if b == ord("1")]


def combine_bits(a):
    n = len(a)
    activos = [i for i, b in enumerate(a) if b == ord("1")]
    k = len(activos)
    combs = []

    for bits in product("01", repeat=k):
        if "1" not in bits:  # al menos un bit encendido
            continue

        valor = 0
        for idx, pos in enumerate(activos):
            if bits[idx] == "1":
                valor |= 1 << (n - 1 - pos)

        combs.append(valor)

    return combs


def toggle_bits(value: int, counter: int, shift: int):
    if value == 0 and counter == 0:
        return []
    values = []
    shifter = []
    for i in range(8):
        bit = 1 << i
        shift_mask = shift & bit
        if shift_mask:
            shifter.append(shift_mask)
    base_values = [value]
    for shift_bit in shifter:
        base_values.append(value ^ shift_bit)
    for shift_value in base_values:
        a = entero_a_binario(counter, 8)
        combs = combine_bits(a)
        combs.insert(0, 0)
        for new_mask in combs:
            modif = value & counter
            result = value & (~counter)
            result2 = modif ^ new_mask
            new_value = result | result2
            values.append(new_value)
    return values


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as fp:
        return json.load(fp)


def parse_test(test: dict, fh) -> None:

    name = test.get("name", "Unknown")

    ports = test.get("ports", {})
    in_ports = []
    out_ports = []
    for port in ports:
        if port[2] == "r":
            in_ports.append(port)
        else:
            out_ports.append(port)
    initial = test.get("initial", {})
    pc = initial["pc"]
    sp = initial["sp"]
    a = initial["a"]
    b = initial["b"]
    c = initial["c"]
    d = initial["d"]
    e = initial["e"]
    f = initial["f"]
    h = initial["h"]
    l = initial["l"]
    i = initial["i"]
    r = initial["r"]
    ei = initial["ei"]
    wz = initial["wz"]
    ix = initial["ix"]
    iy = initial["iy"]
    af_ = initial["af_"]
    bc_ = initial["bc_"]
    de_ = initial["de_"]
    hl_ = initial["hl_"]
    im = initial["im"]
    p = initial["p"]
    q = initial["q"]
    iff1 = initial["iff1"]
    iff2 = initial["iff2"]
    ram = initial["ram"]

    fh.write(f"{name};")
    fh.write(
        f"{pc};{sp};{a};{b};{c};{d};{e};{f};{h};{l};{i};{r};{ei};{wz};{ix};{iy};{af_};{bc_};{de_};{hl_};{im};{p};{q};{iff1};{iff2};"
    )
    fh.write(f"{len(ram)};")
    for v in ram:
        fh.write(f"{v[0]};{v[1]};")

    fh.write(f"{len(in_ports)};")
    for port in in_ports:
        fh.write(f"{port[0]};{port[1]};{port[2]};")

    final = test.get("final", {})
    a = final["a"]
    b = final["b"]
    c = final["c"]
    d = final["d"]
    e = final["e"]
    f = final["f"]
    h = final["h"]
    l = final["l"]
    i = final["i"]
    r = final["r"]
    af_ = final["af_"]
    bc_ = final["bc_"]
    de_ = final["de_"]
    hl_ = final["hl_"]
    ix = final["ix"]
    iy = final["iy"]
    pc = final["pc"]
    sp = final["sp"]
    wz = final["wz"]
    iff1 = final["iff1"]
    iff2 = final["iff2"]
    im = final["im"]
    ei = final["ei"]
    p = final["p"]
    q = final["q"]
    ram = final["ram"]

    fh.write(
        f"{pc};{sp};{a};{b};{c};{d};{e};{f};{h};{l};{i};{r};{ei};{wz};{ix};{iy};{af_};{bc_};{de_};{hl_};{im};{p};{q};{iff1};{iff2};"
    )
    fh.write(f"{len(ram)};")
    for v in ram:
        fh.write(f"{v[0]};{v[1]};")

    fh.write(f"{len(out_ports)};")
    for port in out_ports:
        fh.write(f"{port[0]};{port[1]};{port[2]};")
    fh.write("\n")


def main() -> None:
    if not Path.exists(DATA_PATH):
        raise FileNotFoundError(f"Missing path at {DATA_PATH}")
    if Path.exists(OUT_PATH) is True:
        Path.rmdir(OUT_PATH)
    Path.mkdir(OUT_PATH)
    files = list(DATA_PATH.glob("*.json"))
    for file in files:
        data = load_json(file)
        fname = os.path.basename(file.with_suffix(""))
        out_file = os.path.join(OUT_PATH, f"{fname}.txt")
        with open(out_file, "w", encoding="utf-8") as fh:
            for test in data:
                parse_test(test, fh)


def main2() -> None:
    table = "const std::map<int, std::string> test_data = {\n"
    arch = r"C:\Users\wadrw\Documents\develop\projects\personal\sinclair_spec_emu\trash.txt"
    with open(arch, "r", encoding="utf-8") as fh:
        for line in fh:
            data = line.split(";")
            op_txt = data[0].strip()
            opc = data[1].strip()
            opc = opc.split(" ")
            op = 0
            try:
                if len(opc) > 0:
                    op = int(opc[0], 16)
            except:
                pass
            try:
                if len(opc) > 1:
                    op = (op << 8) | int(opc[1], 16)
            except:
                pass
            try:
                if len(opc) > 3:
                    op = (op << 8) | int(opc[3], 16)
            except:
                pass
            table += f'    {{{op}, "{op_txt}"}},\n'
    table += "};\n"
    arch = r"C:\Users\wadrw\Documents\develop\projects\personal\sinclair_spec_emu\optable.h"
    with open(arch, "w", encoding="utf-8") as fh:
        fh.write(table)


if __name__ == "__main__":
    # main()

    v1 = toggle_bits(0xED, 0x0, 0x0)
    v2 = toggle_bits(0xB0, 0x0, 0x0)
    v3 = toggle_bits(0x0, 0x0, 0x0)
    v4 = toggle_bits(0x0, 0x0, 0x0)
    results = []
    results2 = []
    results3 = []
    for a in v1:
        for b in v2:
            results.append((a << 8) | b)
    for a in results:
        for b in v3:
            results2.append((a << 8) | b)
    if len(results2) > 0:
        results = results2
    for a in results:
        for b in v4:
            results3.append((a << 8) | b)
    if len(results3) > 0:
        results = results3
    for value in results:
        print(f"{value:8X}")
    # for a in v1:
    #     for b in v2:
    #         for c in v3:
    #             for d in v4:
    #                 print(f"{(a<<24)|(b<<16)|(c<<8)|d:08X}")
