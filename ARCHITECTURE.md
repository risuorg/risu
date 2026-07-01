# Risu Architecture

**Version**: 2.0  
**Date**: 2026-07-01

---

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Component Details](#component-details)
- [Data Flow](#data-flow)
- [Extension System](#extension-system)
- [Plugin Execution Lifecycle](#plugin-execution-lifecycle)
- [Magui Multi-System Analysis](#magui-multi-system-analysis)

---

## Overview

Risu is a framework for validating system configuration by executing plugins against:

- **Live systems** (`-l` flag)
- **Sosreport snapshots** (directory path)

### Key Principles:

1. **Plugin-Based**: All checks are plugins (bash, Python, Ansible, Go)
2. **Extensible**: Extension system for different plugin types
3. **Parallel**: Multiprocessing for fast execution (798+ plugins)
4. **Cacheable**: Metadata caching for 5-10x speedup
5. **Multi-System**: Magui for cross-system analysis

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         CLI Layer                            │
│  risu.py (single system) │ magui.py (multiple systems)      │
└──────────────┬────────────────────────────────┬─────────────┘
               │                                │
               ▼                                ▼
┌──────────────────────────────┐  ┌───────────────────────────┐
│     risuclient/shell.py      │  │  maguiclient/magui.py     │
│  Main orchestration logic    │  │  Multi-system wrapper     │
│  - Plugin discovery          │  │  - Calls risu per host    │
│  - Execution (PluginExecutor)│  │  - Autogroup generation   │
│  - Result aggregation        │  │  - Comparative analysis   │
└───────────┬──────────────────┘  └──────────┬────────────────┘
            │                                │
            ▼                                ▼
┌─────────────────────────────────────────────────────────────┐
│                    Extension System                          │
│  risuclient/extensions/*.py                                 │
│  - core (bash)                                              │
│  - ansible (playbooks)                                       │
│  - golang (compiled binaries)                                │
│  - faraday (Python scripts)                                  │
│  - metadata (system info)                                    │
└───────────┬─────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Plugin Layer                              │
│  risuclient/plugins/                                        │
│  - core/ (798+ bash scripts)                                │
│  - ansible/ (YAML playbooks)                                 │
│  - golang/ (Go source + binaries)                           │
│  - faraday/ (Python scripts)                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Details

### Core Modules (risuclient/)

#### 1. shell.py (1935 lines)

**Purpose**: Main orchestration and execution logic

**Key Functions**:

- `main()` - Entry point, parses arguments
- `dorisu()` - Main execution orchestrator
- `runplugin()` - Executes single plugin via extension
- `findplugins()` - Discovers plugins in directories
- `generic_get_metadata()` - Extracts plugin metadata
- `write_results()` - Outputs JSON/HTML results

**Key Classes** (via imports):

- `PluginExecutor` - Parallel execution with multiprocessing
- `MetadataCache` - Caching for 5-10x speedup
- `RisuConfig` - Configuration management

#### 2. config.py

**Purpose**: Configuration management

```python
class RisuConfig:
    - risu_dir: Framework base directory
    - plugins: List of plugins to run
    - is_live: Running on live system vs snapshot
    - include/exclude: Filter patterns
    - priority: Minimum plugin priority
    # ... 20+ more attributes
```

#### 3. cache.py

**Purpose**: Metadata caching for performance

```python
class MetadataCache:
    - get(plugin_path): Retrieve cached metadata
    - set(plugin_path, metadata): Cache metadata
    - save(): Persist to ~/.risu/metadata_cache.pkl
    - cleanup(): Remove stale entries
```

**Performance**:

- First run: ~5-10 seconds (parse 798 plugins)
- Cached run: ~0.5-1 second (5-10x speedup)

#### 4. executor.py

**Purpose**: Safe parallel plugin execution

```python
class PluginExecutor:
    - execute_plugins(): Parallel execution
    - execute_plugins_serial(): Serial fallback
    - Context managers for Pool cleanup
    - Timeout handling (30s per plugin)
    - Graceful Ctrl+C handling
```

#### 5. metadata.py

**Purpose**: Plugin metadata extraction

```python
class PluginMetadata:
    - long_name: Human-readable name
    - description: What the plugin checks
    - priority: 1-999 (999=critical)
    - bugzilla: Bug tracker URL
    - kb: Knowledge base URL

PRIORITY_CATEGORIES:
    - critical: 900-999
    - high: 800-899
    - medium: 600-799
    - low: 400-599
    - info: 1-399
```

#### 6. formatter.py

**Purpose**: Output formatting and colorization

```python
class Colors:
    RED, GREEN, YELLOW, BLUE, END...

Functions:
    - colorize(text, color)
    - format_return_code(rc)
    - format_plugin_result(plugin, result)
    - format_summary(results)
```

#### 7. exceptions.py

**Purpose**: Exception hierarchy

```python
RisuError (base)
├── ConfigError
├── PluginError
│   ├── PluginNotFoundError
│   ├── PluginMetadataError
│   ├── PluginExecutionError
│   └── PluginTimeoutError
├── ExtensionError
├── HookError
├── OutputError
└── ValidationError
```

---

### Extension System

#### Base Extension (risuclient/extensions/base.py)

```python
class BaseExtension:
    extension_name = None  # MUST set in subclass
    file_extension = None  # e.g., ".yml"
    executables_only = True
    comment_char = "#"

    def init(): return [extension_name]
    def listplugins(options): yield plugins
    def get_metadata(plugin): return metadata
    def run(plugin): raise NotImplementedError
    def help(): return help_text
```

**Extensions**:

1. **core** - Bash scripts (most plugins)
2. **ansible** - YAML playbooks
3. **golang** - Go binaries (compile then run)
4. **faraday** - Python scripts
5. **metadata** - System information collection

---

### Magui Components (maguiclient/)

#### 1. magui.py

**Purpose**: Multi-system analysis wrapper

**Key Functions**:

- `domagui()` - Execute risu on multiple sosreports
- `callrisu()` - Execute risu on single sosreport
- `filterresults()` - Filter results by plugin triggers

#### 2. autogroup.py

**Purpose**: Automatic grouping of similar systems

```python
class AutoGroupManager:
    - generate_groups(metadata): Create groups
    - find_next_target(groups): Optimal processing order
    - is_duplicate_group(hosts): Avoid duplicate work
```

**Grouping Algorithm**:

1. Collect metadata from all hosts (release, role, UUID, etc.)
2. Group hosts with matching metadata values
3. Exclude groups with all hosts or single host
4. Process groups in optimal order to minimize memory

**Example Groups**:

```python
{
    'release-7.5': ['host1', 'host2', 'host3'],
    'role-controller': ['host1', 'host4'],
    'role-compute': ['host2', 'host3'],
}
```

---

## Data Flow

### Single System Analysis (risu.py)

```
1. Parse Arguments
   └─> RisuConfig.from_options()

2. Discover Plugins
   └─> extensions.listplugins()
       └─> findplugins(folders, prio, filters)
           └─> Returns: [{plugin: path, backend: ext, ...}]

3. Load Metadata (with caching)
   └─> For each plugin:
       └─> cache.get(plugin_path)
           ├─> Hit: return cached
           └─> Miss: extension.get_metadata()
                   └─> cache.set(plugin_path, metadata)

4. Execute Plugins (parallel)
   └─> PluginExecutor.execute_plugins()
       └─> Pool.apply_async(runplugin, plugin)
           └─> extension.run(plugin)
               └─> Returns: (returncode, out, err)

5. Aggregate Results
   └─> {plugin_id: {result: {rc, out, err}, metadata...}}

6. Output
   └─> write_results()
       ├─> JSON: risu.json
       ├─> HTML: risu.html (web interface)
       └─> Console: colored summary
```

### Multi-System Analysis (magui.py)

```
1. Parse Arguments
   └─> Multiple sosreport paths

2. Run Risu Per Host
   └─> For each sosreport:
       └─> callrisu(path, plugins)
           └─> dorisu(path=sosreport)

3. Generate Groups (optional)
   └─> AutoGroupManager.generate_groups(metadata)
       └─> Returns: {group_name: [hosts]}

4. Process Groups
   └─> For each group:
       ├─> Filter results for group hosts
       ├─> Run magui plugins on filtered data
       └─> Save group-specific output

5. Run Magui Plugins
   └─> For each magui plugin:
       ├─> Filter data by plugin triggers
       ├─> plugin.run(filtered_data)
       └─> Collect results

6. Output
   └─> write_results()
       ├─> magui.json (all systems)
       ├─> magui-<group>.json (per group)
       └─> HTML web interface
```

---

## Plugin Execution Lifecycle

```
┌──────────────────────────────────────────────────────────┐
│ 1. Plugin Discovery                                      │
│    findplugins(folders, prio, include, exclude)         │
│    └─> Returns list of plugin dicts                     │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│ 2. Metadata Extraction (cached)                          │
│    extension.get_metadata(plugin)                        │
│    ├─> Bash: Parse # headers                            │
│    ├─> Ansible: Parse YAML                              │
│    └─> Returns: {priority, long_name, description...}   │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│ 3. Filtering                                             │
│    Apply include/exclude/priority filters                │
│    └─> Final list of plugins to run                     │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│ 4. Parallel Execution (PluginExecutor)                   │
│    Pool.apply_async(runplugin, plugin)                  │
│    └─> Up to CPU cores processes                        │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│ 5. Per-Plugin Execution (runplugin)                      │
│    ├─> Set environment (RISU_ROOT, RISU_LIVE, etc.)    │
│    ├─> Find matching extension by backend               │
│    ├─> extension.run(plugin)                            │
│    │   ├─> Bash: execonshell(script)                   │
│    │   ├─> Ansible: ansible-playbook                   │
│    │   ├─> Golang: compile + execute                   │
│    │   └─> Returns: (rc, stdout, stderr)               │
│    ├─> Timeout after 30 seconds                         │
│    └─> Return result dict                               │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│ 6. Result Collection                                     │
│    Collect all results from async workers                │
│    └─> {plugin_id: {result, metadata, time...}}        │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│ 7. Output Generation                                     │
│    ├─> JSON file (machine-readable)                     │
│    ├─> HTML web interface (human-readable)              │
│    └─> Console summary (colored)                        │
└──────────────────────────────────────────────────────────┘
```

---

## Return Codes

Plugins must use these return codes:

```python
RC_OKAY = 10      # Check passed (green)
RC_FAILED = 20    # Check failed - issue detected (red)
RC_SKIPPED = 30   # Check skipped - not applicable (yellow)
RC_INFO = 40      # Informational output (blue)
```

**Never use `exit 0` or `exit 1`** - these are incorrect!

---

## Environment Variables

Plugins execute with these variables set:

```bash
RISU_BASE=/path/to/risu          # Framework directory
RISU_ROOT=/path/to/sosreport     # System root (/ for live)
RISU_LIVE=0                       # 0=snapshot, 1=live
PLUGIN_BASEDIR=/path/to/plugin    # Plugin's directory
TEXTDOMAIN=risu                   # i18n domain
TEXTDOMAINDIR=/path/to/locale     # i18n translations
```

---

## Extension Pattern

### Adding a New Extension

1. **Create extension class**:

```python
# risuclient/extensions/myext.py
from risuclient.extensions.base import BaseExtension

class MyExtension(BaseExtension):
    extension_name = "myext"
    file_extension = ".myext"
    executables_only = False

    def run(self, plugin):
        # Custom execution logic
        return (returncode, out, err)

# Export for backward compatibility
_instance = MyExtension()
init = _instance.init
listplugins = _instance.listplugins
get_metadata = _instance.get_metadata
run = _instance.run
help = _instance.help
```

2. **Create plugins directory**:

```bash
mkdir -p risuclient/plugins/myext
```

3. **Add plugins**:

```bash
# risuclient/plugins/myext/check-something.myext
# long_name: Check Something
# description: Checks something important
# priority: 800
# ...
```

4. **Test**:

```bash
./risu.py --list-plugins | grep myext
./risu.py -l  # Should execute myext plugins
```

---

## Performance Characteristics

### Typical Execution:

| Operation           | First Run   | Cached Run  | Notes                        |
| ------------------- | ----------- | ----------- | ---------------------------- |
| Plugin discovery    | ~100ms      | ~100ms      | Fast (filesystem scan)       |
| Metadata extraction | ~5-10s      | ~0.5-1s     | **5-10x speedup** with cache |
| Plugin execution    | ~30-60s     | ~30-60s     | Parallel (CPU cores)         |
| **Total**           | **~35-70s** | **~30-60s** | Cache helps repeated runs    |

### Scalability:

- **Plugins**: Currently 798, tested up to 1000+
- **Parallel workers**: Defaults to CPU cores (typically 4-8)
- **Memory**: ~200-500MB for typical run
- **Disk**: Cache file ~50-100KB

---

## Security Considerations

1. **Plugin Execution**: Plugins run with user privileges
   - Live mode: Can modify system
   - Snapshot mode: Read-only on sosreport
2. **Input Validation**: Plugins should validate inputs

3. **Privilege Escalation**: Avoid `sudo` in plugins

4. **Sensitive Data**: Plugins should not output passwords

---

## Future Architecture

### Planned Improvements:

1. **MaguiClient class** - Refactor magui.py for testability
2. **REST API** - HTTP API for remote execution
3. **Plugin dependency graph** - Track plugin relationships
4. **Distributed execution** - Run across multiple machines
5. **Real-time streaming** - Output results as they complete

---

## References

- **CLAUDE.md** - Developer guide
- **IMPROVEMENTS.md** - Improvement roadmap
- **NEW_FEATURES_README.md** - User-facing features
- **Code**: risuclient/, maguiclient/

---

**Last Updated**: 2026-07-01  
**Version**: 2.0 (with modular architecture)
