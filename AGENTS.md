## Overview

This is a Node.js native addon that provides YARA bindings for Node.js. [YARA](https://virustotal.github.io/yara/) is a pattern matching tool used primarily for malware identification and classification. The module wraps the libyara C library (version 4.2.3) using N-API (NAN) and provides both callback and promise-based APIs for scanning files and buffers against YARA rules.

## Architecture

### Core Components

**Native C++ Layer (`src/yara.cc`)**
- Implements the native addon using NAN (Native Abstractions for Node.js)
- Wraps the libyara C API with `ScannerWrap` class
- Handles async operations using `AsyncWorker` for non-blocking scans
- Manages YARA compiler, rules compilation, and scanning lifecycle
- Maps libyara error codes to JavaScript exceptions

**JavaScript Wrapper (`index.js`)**
- Exports the main API: `initialize()`, `createScanner()`, `libyaraVersion()`
- Provides the `Scanner` class with `configure()` and `scan()` methods
- Includes promisified versions: `initializeAsync()`, `configureAsync()`, `scanAsync()`
- Parses metadata and match results from the native layer
- Defines `CompileRulesError` for rule compilation errors

**TypeScript Definitions (`index.d.ts`)**
- Type definitions for the public API

### Build System

The module uses a complex build process that statically compiles libyara:

1. **Makefile**: Downloads YARA source (v4.2.3 by default), builds libyara with crypto and magic support, installs to `build/yara/`
2. **binding.gyp**: node-gyp configuration that:
   - Triggers `make libyara` before building the addon
   - Copies `libmagic.a` from system to `build/`
   - Links against static `libyara.a` and `libmagic.a`
   - Configures platform-specific compiler flags

3. **Pre-built Binaries**: Uses `@mapbox/node-pre-gyp` to download pre-built binaries from GitHub's `binaries/` directory, falling back to source compilation if unavailable

### API Flow

1. Call `yara.initialize()` once to initialize the libyara library (calls `yr_initialize()`)
2. Create a scanner with `yara.createScanner()`
3. Configure scanner with rules and variables using `scanner.configure(options, callback)`
   - Rules can be from files (`{filename: "path"}`) or strings (`{string: "rule..."}`)
   - External variables can be defined (Integer, Float, Boolean, String types)
4. Scan content with `scanner.scan(request, callback)`
   - Can scan buffers or files
   - Returns matched rules with metadata, tags, and string matches
5. Scanner can be reconfigured at runtime (even while scanning) using `scanner.configure()` or `scanner.reconfigureVariables()`

## Development Commands

### Initial Setup
```bash
# Install system dependencies (macOS)
brew install autoconf automake libmagic

# Install Node.js dependencies without running scripts
npm install --ignore-scripts

# Build libyara and the native addon
npx node-pre-gyp configure rebuild
```

### Testing
```bash
# Run all tests
npm test

# Run tests with Mocha directly (for more control)
npx mocha test/*

# Run a single test file
npx mocha test/unit_index.js_scanner.scan.js
```

### Building

```bash
# Full rebuild
npx node-pre-gyp configure rebuild

# Create binary package
npx node-pre-gyp package

# Move package to binaries directory
mv build/stage/Automattic/node-yara/raw/master/binaries/yara-*.tar.gz ./binaries
```

### Docker Build (for Linux binaries)
```bash
# Build for specific Node.js version (20, 22, or 24)
docker build --build-arg NODEJS=22 -t node-yara .
```

### Debugging
```bash
# Check dynamic dependencies of compiled addon
ldd build/Release/yara.node  # Linux
otool -L build/Release/yara.node  # macOS

# Get libyara version
node -e "console.log(require('./index.js').libyaraVersion())"
```

## Testing Approach

Tests use Mocha and are organized by API method:
- `unit_index.js_scanner.configure.js` - Tests rule compilation, variables, errors/warnings
- `unit_index.js_scanner.scan.js` - Tests scanning buffers/files, match results, timeouts
- `unit_index.js_scanner.getRules.js` - Tests rule retrieval
- `unit_index.js_scanner.reconfigureVariables.js` - Tests variable reconfiguration

Test patterns:
- Use `before()` hook to initialize YARA and configure scanner once
- Test both synchronous callbacks and async/promise variants
- Validate error objects for rule compilation failures (check `CompileRulesError.errors` array)
- Test data files are in `test/data/`

## Platform Support

**Supported**: Linux (x64), macOS (x64 and arm64)
**Node.js versions**: 20, 22, 24 (see `.nvmrc` for development version)

**Dependencies**:
- libyara 4.2.3 (statically linked)
- libmagic (statically linked)
- libssl (for crypto support)

## Release Process

See `RELEASE.md` for detailed release instructions. Key points:

1. Disable branch protection on master
2. Bump version in `package.json` and push to master
3. Create GitHub Release with tag (e.g., `2.6.0`)
4. GitHub Actions automatically:
   - Builds binaries for all platforms/Node versions
   - Commits `.tar.gz` files to `binaries/` directory on master
   - Publishes to npm via OIDC (runs in parallel, so package may be published before binaries are ready)
5. Re-enable branch protection once builds complete

## Important Implementation Notes

- **Thread Safety**: Scanner uses mutexes to allow rule reconfiguration while scans are in progress
- **Async Workers**: All scan operations run in background threads (Node.js thread pool, default 4 threads, configurable via `UV_THREADPOOL_SIZE`)
- **Memory Management**: Native addon carefully manages YARA compiler and rules lifecycle, freeing resources properly
- **Error Handling**: Compilation errors include line numbers and indices to identify which rule failed
- **Match Data**: `matchedBytes` option allows extracting actual matched bytes (capped by `MAX_MATCH_DATA`)
