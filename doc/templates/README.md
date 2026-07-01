# Risu Plugin Templates

This directory contains templates for creating new Risu plugins in different languages.

## Available Templates

### Bash Plugins

- **template_modern.sh** - Modern bash plugin template with best practices
  - Includes comprehensive examples and comments
  - Uses proper common-functions.sh patterns
  - Shows RC code usage
  - Demonstrates common checks (files, services, RPM packages, config parsing)
- **template.sh** - Legacy simple template (kept for compatibility)

- **template_live.sh** - Template optimized for live system checks

### Python Plugins

- **template_python.py** - Python plugin template
  - Python 2.7 and 3.x compatible
  - Shows file checking, content parsing
  - Demonstrates error handling
  - Works in both live and snapshot modes

### Ansible Plugins

- **template_ansible.yml** - Ansible playbook plugin template
  - Shows how to handle RISU_ROOT and RISU_LIVE
  - Demonstrates skip conditions
  - Shows RC code handling in Ansible

## Using Templates

### Creating a New Bash Plugin

```bash
# Copy template
cp doc/templates/template_modern.sh risuclient/plugins/core/myarea/myplugin.sh

# Edit the file:
# 1. Update copyright with your name/email
# 2. Fill in required metadata (long_name, description, priority)
# 3. Add optional metadata (bugzilla, kb) if applicable
# 4. Replace example logic with your checks
# 5. Make executable
chmod +x risuclient/plugins/core/myarea/myplugin.sh

# Validate the plugin
./tools/validate_plugin.py risuclient/plugins/core/myarea/myplugin.sh -v

# Test the plugin
./risu.py -l --include myplugin  # Live test
./risu.py /path/to/sosreport --include myplugin  # Snapshot test
```

### Creating a New Python Plugin

```bash
# Copy template
cp doc/templates/template_python.py risuclient/plugins/faraday/myarea/myplugin.py

# Edit and customize as above
chmod +x risuclient/plugins/faraday/myarea/myplugin.py

# Test
./risu.py -l --include myplugin
```

### Creating a New Ansible Plugin

```bash
# Copy template
cp doc/templates/template_ansible.yml risuclient/plugins/ansible/myarea/myplugin.yml

# Edit and customize
# Note: Ansible plugins don't need chmod +x

# Test
./risu.py -l --include myplugin
```

## Plugin Priority Guidelines

Choose priority based on impact:

- **900-999**: Maximum criticality - system can break at any moment
  - Examples: filesystem corruption (950), etcd cluster health (980)
- **800-899**: High criticality - core system services at risk
  - Examples: network connectivity (870), systemd issues (890)
- **600-799**: Medium criticality - applications & services
  - Examples: OpenStack services (750), databases (700)
- **400-599**: Medium-low - middleware & support services
  - Examples: web servers (580), message queues (500)
- **200-399**: Low - monitoring & logging
  - Examples: monitoring systems (350), log collection (330)
- **100-199**: Very low - informational
  - Examples: system information (150), inventory (130)
- **1-99**: Lowest - metadata & development
  - Examples: metadata collection (70)

## Common Functions Available (Bash)

When you load `common-functions.sh`, you get access to:

### File Checks

- `is_required_file <file>` - Exit RC_SKIPPED if file missing
- `is_mandatory_file <file>` - Exit RC_FAILED if file missing
- `is_required_directory <dir>` - Exit RC_SKIPPED if dir missing

### Package Checks (RPM/DEB)

- `is_rpm <package>` - Check if RPM installed
- `is_rpm_over <package> <version>` - Check RPM version
- `is_dpkg <package>` - Check if DEB installed

### Process/Service Checks

- `is_process <name>` - Check if process running
- `is_active <service>` - Check if systemd service active
- `is_enabled <service>` - Check if systemd service enabled

### Content Checks

- `is_lineinfile <pattern> <file>` - Search for pattern in file
- `iniparser <file> <section> <key>` - Parse INI-style config files

### Container Checks

- `is_containerized` - Check if running in container

See `risuclient/common.d/00-core.sh` for complete list.

## Best Practices

1. **Always load common-functions.sh** for bash plugins
2. **Use RC\_ constants** instead of exit 0/1
3. **Include all required metadata** (long_name, description, priority)
4. **Write to stderr** for error messages (stdout is for structured output)
5. **Use is_required_file** to handle missing files gracefully
6. **Test both live and snapshot modes** if applicable
7. **Run validation** before submitting: `./tools/validate_plugin.py <your-plugin>`
8. **Run shellcheck** on bash plugins: `shellcheck -x <your-plugin.sh>`

## Testing Your Plugin

```bash
# Quick test - live mode
./risu.py -l --include <plugin-name>

# Test against sosreport
./risu.py /path/to/sosreport --include <plugin-name>

# Verbose output
./risu.py -l -v --include <plugin-name>

# Debug mode
./risu.py -l -d DEBUG --include <plugin-name>

# Using debug environment
source ./env-for-debug.sh
bash -x risuclient/plugins/core/myarea/myplugin.sh
```

## Validation

Before submitting a plugin:

```bash
# Validate structure and metadata
./tools/validate_plugin.py risuclient/plugins/core/myarea/myplugin.sh -v

# Run shellcheck (if available)
shellcheck -x risuclient/plugins/core/myarea/myplugin.sh

# Run pre-commit checks
pre-commit run --files risuclient/plugins/core/myarea/myplugin.sh
```

## Contributing

After creating your plugin:

1. Validate it: `./tools/validate_plugin.py <plugin> -v`
2. Test it: `./risu.py -l --include <plugin>`
3. Add to git: `git add <plugin>`
4. Commit: `git commit -m "[plugins][area] Brief description"`
5. Submit PR

See CONTRIBUTING.md for full contribution guidelines.
