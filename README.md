# ZX Spectrum emulator

------

## Prerequisites

### Windows

- CMake 3.10 or higher.
- Python 3.
- Visual Studio 2026 (Community, Professional or Enterprise).

#### Compile

- 1. Execute "x64 Native Tools Command Prompt for VS" from start menu.
- 2. Inside command prompt go to repos's src folder.
- 2. Run "python3 generate_vs.py" to generate a Visual Studio project.
- 3. Open visual studio project generated at src/build.
- 4. Build.

#### Emulator command keys

- F1: Loads tap/wav/sna file into emulator.
- F2: Save tap/sna from emulator memory.
- F3: Enable/Disable real Z80 speed sync.
- F4: Enable/Disable tap file fast load.
- F5: Hardware reset