import json
from pathlib import Path

# Get the file path relative to this script
opcode_table_file = Path(__file__).parent / "opcode-table.json"
asm_opcode_table_file_in = (
    Path(__file__).parent / ".." / "src" / "z80" / "cpu" / "opcodesdef.inc"
)
asm_opcode_table_file_out = (
    Path(__file__).parent / ".." / "src" / "z80" / "cpu" / "opcodesdef_out.inc"
)


def read_asm_opcode_table(file_path):
    """Read and parse the assembly opcode table from a JSON file."""
    try:
        with open(file_path, "r") as f:
            content = f.read()
            return content
        print(f"Successfully loaded asm file")
    except FileNotFoundError:
        print(f"Error: {file_path} not found")
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")


# Parse and analyze the opcode table structure
def parse_opcode_table(opcode_table):
    """Parse the opcode table and extract structured information."""
    parsed_opcodes = []

    for entry in opcode_table:
        parsed_entry = {
            "opcode": entry.get("bytes"),
            "cycles": entry.get("cycles"),
            "mnemonic": entry.get("mnemonic"),
        }
        parsed_opcodes.append(parsed_entry)

    return parsed_opcodes


def read_opcode_table(file_path):
    try:
        with open(opcode_table_file, "r") as f:
            opcode_table = json.load(f)
            if opcode_table:
                parsed_opcodes = parse_opcode_table(opcode_table)
                parsed_opcodes.sort(key=lambda x: x["opcode"])
                return parsed_opcodes
        print(f"Successfully loaded {len(opcode_table)} entries")
    except FileNotFoundError:
        print(f"Error: {opcode_table_file} not found")
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")


def override_table(name, prefix, lines):
    l = 0
    output = []
    while l < len(lines):
        line = lines[l].strip()
        pad = 0
        if line.startswith(name):
            op_counter = 0
            while l < len(lines):
                line = lines[l].strip()
                if len(line) == 0:
                    output.append("")
                    return output
                last_word = line.split()[-1] if line.split() else ""
                operand = f"{prefix}{op_counter:02X}"
                if last_word != operand:
                    words = line.split()
                    words[-1] = operand
                    line = " ".join(words)
                    lines[l] = line
                output.append(" " * pad + line)
                op_counter += 1
                l += 1
                pad = 8
        l += 1
    return output


def create_full_opcode_defs():
    asm_text = read_asm_opcode_table(asm_opcode_table_file_in)
    lines = asm_text.splitlines()
    output = override_table("_TOp1B", "Op", lines)
    output.extend(override_table("_TOpCB", "OpCB", lines))
    output.extend(override_table("_TOpDD", "OpDD", lines))
    output.extend(override_table("_TOpED", "OpED", lines))
    output.extend(override_table("_TOpFD", "OpFD", lines))
    output.extend(override_table("_TOpDDCB", "OpDDCB", lines))
    output.extend(override_table("_TOpFDCB", "OpFDCB", lines))
    # with open(asm_opcode_table_file_out, "w") as f:
    #    f.write("\n".join(output))
    return output


if __name__ == "__main__2":
    opcode_defs = create_full_opcode_defs()
    opcode_table = read_opcode_table(opcode_table_file)
    for line in opcode_defs:
        last_word = line.split()[-1] if line.split() else ""
        if last_word.startswith("Op"):
            opcode_hex = last_word[2:]
            try:
                found = False
                entries = []
                for entry in opcode_table:
                    if entry["opcode"][0] == opcode_hex:
                        entries.append(entry)
                        found = True
                if found == False:
                    print(line)
            except ValueError:
                print(line)


def read_asm_file_lines(file_path):
    """Read the assembly file line by line and return a list of lines."""
    try:
        with open(file_path, "r") as f:
            return f.readlines()
    except FileNotFoundError:
        print(f"Error: {file_path} not found")
        return []


def write_asm_file_lines(file_path, lines):
    """Write the list of lines to the assembly file."""
    try:
        with open(file_path, "w") as f:
            f.writelines("\n".join(lines))
    except Exception as e:
        print(f"Error writing to {file_path}: {e}")


if __name__ == "__main__":

    asm_file_lines_proc = []
    asm_times = read_asm_file_lines("C:\\Users\\wadrw\\Documents\\develop\\asm.txt")
    asm_opcodes = read_asm_file_lines("C:\\Users\\wadrw\\Documents\\develop\\asm1.txt")
    total_missing = 0
    found = False
    for line_t in asm_times:
        line_t = line_t.rstrip()
        lines_t = line_t.split(";")
        key = f"Op{lines_t[0].strip()}:"
        for i in range(len(asm_opcodes)):
            line_o = asm_opcodes[i].rstrip()
            if found is False and line_o.strip().startswith(key):
                found = True
                asm_opcodes[i] = line_o
                continue
            elif found is True:
                found = False
                line_o2 = line_o.strip()
                if line_o2.startswith(";"):
                    idx = line_o.index(";")
                    asm_opcodes[i] = line_o.replace(
                        line_o[idx:],
                        f"; {lines_t[1].strip().upper()} cycles: {lines_t[2].strip()}",
                    ).rstrip()
                else:
                    asm_opcodes[i] = line_o
                    print(f"Missing comment for {key}")
                break
            elif "acumulate_opcode_cycles," in line_o:
                lines = line_o.split(",")
                if len(lines) > 2:
                    asm_opcodes[i] = lines[0] + f",{lines[1].strip()}"
                    txt = lines[2].split(";")
                    if len(txt) > 1:
                        asm_opcodes[i] += f" ;{txt[1].strip()}"
        for i in range(len(asm_opcodes)):
            asm_opcodes[i] = asm_opcodes[i].rstrip()
        write_asm_file_lines(
            "C:\\Users\\wadrw\\Documents\\develop\\asm_out.txt", asm_opcodes
        )
