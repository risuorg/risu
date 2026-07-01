# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Risu is a Python-based framework for system configuration validation that runs against live systems or sosreport/filesystem snapshots. It executes plugins to detect configuration issues, common problems, and preventive measures needed for system health.

**Key Components:**

- **Risu**: Main validation framework (`risuclient/`) - executes plugins against single systems
- **Magui**: Multi-system analysis wrapper (`maguiclient/`) - aggregates data across multiple hosts for cluster-wide validation
- **Plugins**: Validation scripts in multiple languages (bash, Python, Ansible, Go) organized under `risuclient/plugins/`
- **Extensions**: Backend handlers (`risuclient/extensions/`) for different plugin types (core/bash, ansible, golang, faraday, metadata)

## Development Commands

### Testing

```bash
# Run all tests (Python 2.7, Python 3, and flake8)
tox

# Run specific test environments
tox -e py27      # Python 2.7 tests
tox -e py3       # Python 3 tests
tox -e flake8    # Linting only

# Run tests with coverage
py.test --cov=risuclient --cov=maguiclient

# Run specific test file
py.test tests/test_integration.py -v
```

### Running Risu

```bash
# Against a sosreport/snapshot
./risu.py /path/to/sosreport

# Against live system
./risu.py -l

# With filters
./risu.py -i openstack -x nova /path/to/sosreport  # include openstack, exclude nova
./risu.py -p 800 -l  # only run plugins with priority >= 800

# Generate JSON output
./risu.py --output results.json /path/to/sosreport

# Generate web interface
./risu.py --output /output/path --web /path/to/sosreport

# List available plugins
./risu.py --list-plugins --description
```

### Running Magui (multi-system analysis)

```bash
# Analyze multiple sosreports
./magui.py /path/to/sosreport1 /path/to/sosreport2 /path/to/sosreport3

# With output
./magui.py --output magui.json /path/to/sosreport*
```

### Code Quality

```bash
# Pre-commit hooks are configured - install with:
pre-commit install

# Manual formatting
black risuclient/ maguiclient/
ruff check --fix risuclient/ maguiclient/

# Shell script formatting
shfmt -w -i 4 -s risuclient/plugins/**/*.sh
```

### Plugin Development

```bash
# Debug a plugin using the debug environment
source ./env-for-debug.sh
sh -x /path/to/plugin.sh

# Test individual common functions
. ./env-for-debug.sh
is_rpm qemu-kvm-rhev
```

## Architecture

### Plugin Execution Flow

1. **Entry Point**: `risu.py` or `magui.py` CLI scripts
2. **Main Controller**: `risuclient/shell.py` - orchestrates plugin discovery, loading, and execution
3. **Extension System**: `risuclient/extensions/` - each extension type (core, ansible, golang, etc.) provides:
   - Plugin discovery logic
   - Execution wrapper
   - Result parsing
4. **Plugin Execution**: Plugins run in multiprocessing pool, return standardized JSON results
5. **Output**: Results aggregated to JSON, can be rendered via HTML interface (`risu.html`)

### Plugin Types & Extensions

- **core** (`extensions/core.py`): Bash shell scripts - most common plugin type
- **ansible** (`extensions/ansible.py`): Ansible playbooks (must end in `.yml`)
- **golang** (`extensions/golang.py`): Compiled Go binaries
- **faraday** (`extensions/faraday.py`): Python scripts using faraday library
- **metadata** (`extensions/metadata.py`): System metadata collection

### Plugin Metadata Headers

All plugins must include these headers (bash example):

```bash
# long_name: Descriptive name for web UI
# description: What this plugin checks
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=XXXXX
# priority: 1-999 (999=max criticality, 1=lowest)
# kb: https://access.redhat.com/solutions/XXXXX
```

### Plugin Priority System

Priority ranges determine execution order and criticality (999 = maximum, 1 = minimum):

- **900-999**: Maximum criticality - system can break at any moment (filesystem corruption, etcd health)
- **800-899**: High criticality - core system services at risk (network, systemd, node health)
- **600-799**: Medium criticality - applications & services (OpenStack, OpenShift, databases)
- **400-599**: Medium-low - middleware & support services
- **200-399**: Low - monitoring & logging systems
- **100-199**: Very low - informational checks
- **1-99**: Lowest - metadata collection

### Environment Variables (Plugin Execution Context)

Plugins run with these environment variables set by the framework:

- `RISU_BASE`: Framework base directory path
- `RISU_LIVE`: 1 if running on live system, 0 if snapshot
- `RISU_ROOT`: Root of the system being analyzed (/ for live, sosreport path for snapshot)
- `TEXTDOMAIN`, `TEXTDOMAINDIR`: i18n support

### Return Codes

Plugins must exit with these codes (defined in `common-functions.sh` and `shell.py`):

- `RC_OKAY=10`: Check passed
- `RC_FAILED=20`: Check failed (issue detected)
- `RC_SKIPPED=30`: Check skipped (not applicable)
- `RC_INFO=40`: Informational output

### Common Plugin Utilities

Bash plugins can use functions from `risuclient/common-functions.sh`:

- `is_rpm <package>`: Check if RPM package is installed
- `is_required_file <path>`: Verify file exists, skip plugin if not
- `is_process <name>`: Check if process is running
- `is_lineinfile <pattern> <file>`: Search for pattern in file
- Many more - see `common-functions.sh` for full list

## Testing Plugins

All new plugins should include unit tests in `tests/`:

- Integration tests: `tests/test_integration.py`
- OpenStack-specific: `tests/test_openstack_plugins.py`
- Security-specific: `tests/test_security_plugins.py`

Test structure uses Python's `unittest.TestCase`.

## File Organization

```
risu/
├── risu.py, magui.py, citellus.py  # Entry point CLI scripts
├── risuclient/                      # Main framework code
│   ├── shell.py                    # Core orchestration logic
│   ├── common-functions.sh         # Bash plugin utilities
│   ├── extensions/                 # Plugin type handlers
│   ├── plugins/                    # All validation plugins
│   │   ├── core/                   # Bash plugins (largest collection)
│   │   ├── ansible/                # Ansible playbook plugins
│   │   ├── golang/                 # Go binary plugins
│   │   └── ...
│   └── tools/                      # Utility scripts
├── maguiclient/                    # Multi-system analysis
│   └── magui.py                    # Magui core logic
├── tests/                          # Unit tests
└── doc/                            # Documentation
```

## Important Notes

- **Python 2.7 & 3 Compatibility**: Code must support both Python 2.7 and Python 3.x
- **Multi-language Plugins**: Framework supports bash, Python, Ansible, Go - choose appropriate extension
- **Sosreport vs Live**: Plugins should work on both live systems (`-l` flag) and sosreport snapshots when possible
- **Exit Codes**: Always use standard return codes (RC_OKAY, RC_FAILED, RC_SKIPPED, RC_INFO) - never exit 0/1
- **Commit Messages**: Use format `[component][subcomponent] Description` (e.g., `[plugins][openstack][nova] Check nova configuration`)
- **Pre-commit Hooks**: Always run before committing - enforces black, ruff, shfmt, and other quality checks
