## Cerby Fork

### Things that changed

- Bundled https://github.com/nut-tree/node-mac-permissions here
- Fixed MacOS 15 permissions in `node-mac-permissions` and in `src/macos`
- **Enhanced `getWindows()` function**: Modified to return window information objects instead of just handles
  - **Breaking change**: `getWindows()` now returns `Array<{handle: number, pid: number}>` instead of `number[]`
  - Added PID (Process ID) information for each window across all platforms (macOS, Windows, Linux)
  - Updated TypeScript definitions to include new `WindowInfo` interface
  - Platform-specific implementations:
    - macOS: Uses existing `kCGWindowOwnerPID` from CoreGraphics
    - Windows: Added `GetWindowThreadProcessId()` call to retrieve PID
    - Linux: Added `_NET_WM_PID` property lookup via X11

## Building

Please ensure you have the required dependencies before installing:

* Windows
  * windows-build-tools npm package (`npm install --global --production windows-build-tools` from an elevated PowerShell or CMD.exe)
* Mac
  * Xcode Command Line Tools.
* Linux
  * cmake
  * A C/C++ compiler like GCC.
  * libxtst-dev and libpng++-dev (`sudo apt-get install libxtst-dev libpng++-dev`).

### Release build

```
npm install
npm run build:release
```

### Debug build

```
npm install
npm run build:debug
```
