# Extended Test Suite for Risu

This document describes the comprehensive test suite extensions added to improve stability, performance, and code coverage for the Risu project.

## Overview

The extended test suite adds 8 new test modules that provide comprehensive coverage across different aspects of the Risu plugin ecosystem:

1. **Performance Testing** (`test_performance.py`)
2. **Coverage Analysis** (`test_coverage.py`)
3. **OpenStack Plugin Testing** (`test_openstack_plugins.py`)
4. **OpenShift Plugin Testing** (`test_openshift_plugins.py`)
5. **Security Plugin Testing** (`test_security_plugins.py`)
6. **Network Plugin Testing** (`test_network_plugins.py`)
7. **Integration Testing** (`test_integration.py`)
8. **Plugin Validation Testing** (`test_plugin_validation.py`)

## Quick Start

### Running All Extended Tests

```bash
cd tests
python run_extended_tests.py
```

### Running Specific Test Modules

```bash
# Run only performance tests
python run_extended_tests.py --module test_performance

# Run quick tests (skip performance and integration)
python run_extended_tests.py --quick

# Run with verbose output
python run_extended_tests.py --verbose
```

### Running Individual Test Files

```bash
# Using unittest
python -m unittest test_performance.py
python -m unittest test_coverage.py

# Using pytest (if available)
pytest test_performance.py -v
pytest test_coverage.py -v
```

## Test Module Details

### 1. Performance Testing (`test_performance.py`)

**Purpose**: Measure plugin execution performance and identify bottlenecks.

**Key Tests**:

- `test_plugin_execution_times` - Measures individual plugin execution times
- `test_parallel_execution_performance` - Compares sequential vs parallel execution
- `test_memory_usage_patterns` - Monitors memory usage during plugin execution
- `test_plugin_category_performance` - Analyzes performance by plugin category

**Benefits**:

- Identifies slow plugins that need optimization
- Validates parallel execution performance gains
- Monitors memory usage patterns
- Provides performance baselines for regression testing

### 2. Coverage Analysis (`test_coverage.py`)

**Purpose**: Analyze test coverage across different plugin categories and metadata.

**Key Tests**:

- `test_plugin_category_coverage` - Analyzes distribution of plugins across categories
- `test_plugin_execution_coverage` - Tests plugin execution success rates
- `test_plugin_metadata_coverage` - Validates metadata field coverage
- `test_plugin_priority_distribution` - Analyzes priority distribution

**Benefits**:

- Ensures comprehensive plugin coverage
- Validates metadata completeness
- Identifies gaps in plugin categories
- Monitors plugin execution success rates

### 3. OpenStack Plugin Testing (`test_openstack_plugins.py`)

**Purpose**: Comprehensive testing of OpenStack-specific plugins.

**Key Tests**:

- `test_nova_plugins` - Tests Nova-specific functionality
- `test_neutron_plugins` - Tests Neutron networking plugins
- `test_keystone_plugins` - Tests Keystone authentication plugins
- `test_database_plugins` - Tests database-related plugins
- `test_rabbitmq_plugins` - Tests RabbitMQ messaging plugins

**Benefits**:

- Ensures OpenStack plugin functionality
- Validates appropriate priority assignments
- Tests OpenStack-specific scenarios
- Monitors OpenStack plugin metadata quality

### 4. OpenShift Plugin Testing (`test_openshift_plugins.py`)

**Purpose**: Comprehensive testing of OpenShift-specific plugins.

**Key Tests**:

- `test_etcd_plugins` - Tests etcd cluster health plugins
- `test_master_api_plugins` - Tests master API server plugins
- `test_node_plugins` - Tests node-specific plugins
- `test_cluster_plugins` - Tests cluster-wide plugins

**Benefits**:

- Ensures OpenShift plugin functionality
- Validates container orchestration checks
- Tests Kubernetes-specific scenarios
- Monitors OpenShift plugin consistency

### 5. Security Plugin Testing (`test_security_plugins.py`)

**Purpose**: Test security vulnerability detection plugins.

**Key Tests**:

- `test_meltdown_plugins` - Tests Meltdown vulnerability checks
- `test_spectre_plugins` - Tests Spectre vulnerability checks
- `test_speculative_store_bypass_plugins` - Tests SSB vulnerability checks
- `test_security_plugin_kb_references` - Validates KB references

**Benefits**:

- Ensures security vulnerability detection
- Validates high priority assignments for security issues
- Tests security plugin metadata quality
- Monitors security plugin consistency

### 6. Network Plugin Testing (`test_network_plugins.py`)

**Purpose**: Test network connectivity and configuration plugins.

**Key Tests**:

- `test_interface_plugins` - Tests network interface plugins
- `test_external_connectivity_plugins` - Tests connectivity checks
- `test_openstack_network_plugins` - Tests OpenStack networking
- `test_network_plugin_error_handling` - Tests error handling

**Benefits**:

- Ensures network plugin functionality
- Validates connectivity checks
- Tests network configuration validation
- Monitors network plugin error handling

### 7. Integration Testing (`test_integration.py`)

**Purpose**: Test plugin interactions and system-wide functionality.

**Key Tests**:

- `test_full_risu_run` - Tests complete Risu execution
- `test_magui_integration` - Tests Magui integration
- `test_plugin_dependency_handling` - Tests plugin dependencies
- `test_concurrent_execution_safety` - Tests concurrent execution
- `test_large_scale_execution` - Tests large-scale plugin execution

**Benefits**:

- Validates system-wide functionality
- Tests plugin interactions
- Ensures concurrent execution safety
- Validates integration with external tools

### 8. Plugin Validation Testing (`test_plugin_validation.py`)

**Purpose**: Validate plugin metadata consistency and format compliance.

**Key Tests**:

- `test_plugin_metadata_completeness` - Validates required metadata fields
- `test_plugin_naming_consistency` - Tests naming conventions
- `test_plugin_priority_consistency` - Validates priority assignments
- `test_plugin_header_format_validation` - Tests header format compliance
- `test_plugin_category_organization` - Validates category organization

**Benefits**:

- Ensures metadata consistency
- Validates plugin format compliance
- Tests naming conventions
- Monitors category organization

## Test Execution Metrics

The extended test suite provides comprehensive metrics:

- **Performance Metrics**: Execution times, memory usage, bottleneck identification
- **Coverage Metrics**: Plugin category coverage, metadata coverage, execution success rates
- **Quality Metrics**: Metadata completeness, format compliance, consistency validation
- **Integration Metrics**: Multi-plugin execution, concurrent safety, error handling

## CI/CD Integration

The extended test suite is designed for CI/CD integration:

```bash
# Quick validation for pull requests
python run_extended_tests.py --quick

# Full test suite for nightly builds
python run_extended_tests.py --verbose

# Performance regression testing
python run_extended_tests.py --module test_performance
```

## Configuration

### Test Environment Variables

- `RISU_TEST_TIMEOUT`: Default timeout for plugin execution (default: 30s)
- `RISU_TEST_PARALLEL`: Number of parallel workers for testing (default: 4)
- `RISU_TEST_VERBOSE`: Enable verbose output (default: False)

### Test Data

The test suite uses temporary directories and mock data:

- Temporary sosreport directories for plugin execution
- Mock configuration files for specific scenarios
- Sample plugin outputs for validation testing

## Troubleshooting

### Common Issues

1. **Test Timeouts**: Increase timeout values for slow systems
2. **Memory Issues**: Reduce parallel worker count
3. **Permission Errors**: Ensure test directories are writable
4. **Plugin Failures**: Check plugin dependencies and requirements

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
python run_extended_tests.py --verbose --module test_performance
```

## Contributing

When adding new tests:

1. Follow the existing test structure and naming conventions
2. Include comprehensive docstrings and comments
3. Add appropriate assertions and error handling
4. Update this documentation with new test descriptions
5. Ensure tests are deterministic and can run in isolation

## Dependencies

The extended test suite requires:

- Python 3.6+
- unittest (built-in)
- Risu client libraries
- Magui client libraries
- psutil (for memory monitoring)
- concurrent.futures (for parallel execution testing)

## Performance Expectations

Typical execution times (may vary by system):

- Quick tests: 2-5 minutes
- Full test suite: 10-20 minutes
- Performance tests: 5-10 minutes
- Integration tests: 5-15 minutes

## Maintenance

Regular maintenance tasks:

1. Update test thresholds based on system performance
2. Add new plugin categories as they are introduced
3. Update validation rules for new metadata fields
4. Refresh test data and mock scenarios
5. Monitor test execution times and optimize as needed

## Support

For issues with the extended test suite:

1. Check the troubleshooting section above
2. Review test output for specific error messages
3. Run individual test modules to isolate issues
4. Use verbose mode for detailed debugging information
5. Check plugin dependencies and system requirements
