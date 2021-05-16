## [1.7.2](https://github.com/risuorg/risu/compare/1.7.1...1.7.2) (2021-05-16)

### Bug Fixes

- **shell.py:** do not follow links when processing --find to avoid issues in sosreports ([103334d](https://github.com/risuorg/risu/commit/103334d148b23278f39a01dc0f08105c49256782))

## [1.7.1](https://github.com/risuorg/risu/compare/1.7.0...1.7.1) (2021-05-16)

### Bug Fixes

- **reboots.py:** properly handle releases ([3029a49](https://github.com/risuorg/risu/commit/3029a49145f838a487dfedca145b7654666fcbfe))

# [1.7.0](https://github.com/risuorg/risu/compare/1.6.5...1.7.0) (2021-05-16)

### Features

- **reboots.py:** support newer rhel, centos and fedora releases ([c6a1f3d](https://github.com/risuorg/risu/commit/c6a1f3da862d0c9ca60dd28ea7c99e0dcd746117))

## [1.6.5](https://github.com/risuorg/risu/compare/1.6.4...1.6.5) (2021-05-15)

### Bug Fixes

- **magui.py:** fix group processing ([5a35a72](https://github.com/risuorg/risu/commit/5a35a720681c9dbb9dd364909998075f5a093cbc))

## [1.6.4](https://github.com/risuorg/risu/compare/1.6.3...1.6.4) (2021-05-15)

### Bug Fixes

- **risu.sh:** add compat variables to shell wrapper ([858d011](https://github.com/risuorg/risu/commit/858d011ee8fbd64238fa0c76e4e936cbe5d62098))

## [1.6.3](https://github.com/risuorg/risu/compare/1.6.2...1.6.3) (2021-05-15)

### Bug Fixes

- **shell.py:** sets compatibility mode env vars ([0c8ff38](https://github.com/risuorg/risu/commit/0c8ff384ed1fbbdfb5df5e4696981ed2c7e9905c))

## [1.6.2](https://github.com/risuorg/risu/compare/1.6.1...1.6.2) (2021-05-15)

### Bug Fixes

- **shell.py:** fix loading of legacy path overriding new ones ([88b30ce](https://github.com/risuorg/risu/commit/88b30ceee407e373a4655b279b90788552bff8f7))

# [1.6.0](https://github.com/risuorg/risu/compare/1.5.0...1.6.0) (2021-05-15)

### Features

- Update contributors to each file ([0b01270](https://github.com/risuorg/risu/commit/0b01270134eea642ea3139cc86c5db5e57c0a4ba))
- **shell.py:** Use new logo ([1e804d5](https://github.com/risuorg/risu/commit/1e804d55591cdf01c5cb6034dbaf33f7590ccf61))
- remove dmidecode test in UT ([a60907e](https://github.com/risuorg/risu/commit/a60907eeb67a134d2a99032ea3a4ca94dde15aae))
- Rename files ([b7c4a9f](https://github.com/risuorg/risu/commit/b7c4a9f73b8472544764ac04c054ce734c458063))

# [1.5.0](https://github.com/risuorg/risu/compare/1.4.0...1.5.0) (2021-05-03)

### Features

- **risu.html:** match window title with report name ([f18aad9](https://github.com/risuorg/risu/commit/f18aad9f0e6582f6deb1190dda1bc98152a6028b))

# [1.4.0](https://github.com/risuorg/risu/compare/1.3.3...1.4.0) (2021-05-03)

### Features

- **shell.py:** search for configuration file in current directory automatically ([2379374](https://github.com/risuorg/risu/commit/2379374ea86869ae5b458add35604a4cf33a992a))

## [1.3.3](https://github.com/risuorg/risu/compare/1.3.2...1.3.3) (2021-04-21)

### Bug Fixes

- **nagios.py:** unknown is defined as RC 3 ([0ae7617](https://github.com/risuorg/risu/commit/0ae7617357d9e4cab3bf45f9523ea207169c8863))

## [1.3.2](https://github.com/risuorg/risu/compare/1.3.1...1.3.2) (2021-04-21)

### Bug Fixes

- **nagios.py:** Also consider UKNOWN as SKIPPED ([6ca49dd](https://github.com/risuorg/risu/commit/6ca49dd2df7a75e1f4fff0318fa8a6c29a8739d6))

## [1.3.1](https://github.com/risuorg/risu/compare/1.3.0...1.3.1) (2021-04-21)

### Bug Fixes

- **nagios.py:** Also process WARNING as RC_INFO for Nagios plugins ([f38efce](https://github.com/risuorg/risu/commit/f38efce9a13961d3b9c967390df2846e4cffc6cb))

# [1.3.0](https://github.com/risuorg/risu/compare/1.2.0...1.3.0) (2021-04-20)

### Features

- **risu.html:** Use html file name for finding the json data ([69246dd](https://github.com/risuorg/risu/commit/69246dde55f6204bb9ea9a79d0a83f36200fc3f4))

# [1.2.0](https://github.com/risuorg/risu/compare/1.1.1...1.2.0) (2021-04-20)

### Features

- **nagios.py:** Add Nagios extension to process shell scripts with standard return codes 0/1/2 ([1d2776a](https://github.com/risuorg/risu/commit/1d2776ae4fab4c825ee8a2f35e53bbdc0e9ec4c4))

## [1.1.1](https://github.com/risuorg/risu/compare/1.1.0...1.1.1) (2020-10-18)

### Bug Fixes

- **release.yml:** use automation via GHA for release process ([9011813](https://github.com/risuorg/risu/commit/901181398adfed12e78d0e550f71ab79f4aaafd1))
