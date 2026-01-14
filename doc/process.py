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


if __name__ == "__main__":
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
