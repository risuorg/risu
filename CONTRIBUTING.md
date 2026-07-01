# Contributing to Risu

Thank you for your interest in contributing to Risu! This guide will help you get started.

---

## Quick Links

- [Getting Started](#getting-started)
- [Adding a Plugin](#adding-a-plugin)
- [Code Style](#code-style)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)

---

## Getting Started

### Prerequisites

- Python 2.7 or Python 3.6+ (Risu supports both)
- Git
- Basic shell scripting knowledge

### Quick Start

```bash
git clone https://github.com/risuorg/risu.git
cd risu
pip install -r test-requirements.txt
pre-commit install
./risu.py --help
```

---

## Adding a Plugin

See `doc/templates/README.md` for complete plugin development guide.

Quick template:

```bash
cp doc/templates/template_modern.sh risuclient/plugins/core/myarea/myplugin.sh
chmod +x risuclient/plugins/core/myarea/myplugin.sh
./tools/validate_plugin.py risuclient/plugins/core/myarea/myplugin.sh -v
```

---

## Code Style

**Python 2.7 compatible!**

✅ DO: `from __future__ import print_function`, `.format()`, specific exceptions
❌ DON'T: f-strings, type hints, bare `except:`

---

## Testing

```bash
python -m pytest                    # Run all tests
python -m pytest tests/test_*.py    # Specific tests
tox                                 # Test multiple Python versions
```

---

## Pull Request Process

1. Create feature branch
2. Make changes
3. Add tests
4. Run `pre-commit run --all-files`
5. Push and create PR

---

For full documentation see CLAUDE.md and ARCHITECTURE.md
