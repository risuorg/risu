# [1.14.0](https://github.com/risuorg/risu/compare/1.13.0...1.14.0) (2022-11-18)

### Features

- **risu.html:** show <pre> in profile's output ([bfb98dd](https://github.com/risuorg/risu/commit/bfb98dd50e7a126f1507de554577d42175dee7f8))

# [1.13.0](https://github.com/risuorg/risu/compare/1.12.2...1.13.0) (2022-11-18)

### Features

- fill long_name with description if empty ([c34ece4](https://github.com/risuorg/risu/commit/c34ece4036dfbdb20872d055e7564576116c39d1))

## [1.12.2](https://github.com/risuorg/risu/compare/1.12.1...1.12.2) (2022-11-14)

### Bug Fixes

- ifcfg files are no longer mandatory in EL9 ([5431fdc](https://github.com/risuorg/risu/commit/5431fdc590582a297d24f4da7d0cb803209db8a0))

## [1.12.1](https://github.com/risuorg/risu/compare/1.12.0...1.12.1) (2022-11-14)

### Bug Fixes

- **STIC-619:** properly handle EL9 password minlen option ([1986369](https://github.com/risuorg/risu/commit/198636977dac3ab6a5cf78f69d1aec0f01000eda))

# [1.12.0](https://github.com/risuorg/risu/compare/1.11.0...1.12.0) (2022-11-10)

### Features

- discover EL9 release ([8820562](https://github.com/risuorg/risu/commit/8820562c26c81437e5ca35ef9957d1d9cc5410f0))
- Enhance STIC619 login defs for EL9 ([7eb5a75](https://github.com/risuorg/risu/commit/7eb5a75a42d7b4d7b9ca0850420758972929e027))

# [1.11.0](https://github.com/risuorg/risu/compare/1.10.0...1.11.0) (2022-11-10)

### Features

- enable env-for-debug.sh to be easily accessible when installing as package ([5368957](https://github.com/risuorg/risu/commit/5368957ca0224676e97365c31355c3877a3c5d65))

# [1.10.0](https://github.com/risuorg/risu/compare/1.9.0...1.10.0) (2022-11-09)

### Features

- report NIC firmware version ([45523e4](https://github.com/risuorg/risu/commit/45523e41fd7fe1ea4bea9df8898cbcb737cd6f7f))

# [1.9.0](https://github.com/risuorg/risu/compare/1.8.0...1.9.0) (2022-11-08)

### Bug Fixes

- handle when options are not passed ([ec847a1](https://github.com/risuorg/risu/commit/ec847a1aabc9162ab9dad76c60fee2a336877b74))

### Features

- add two checks from STIC-610A22 ([491af49](https://github.com/risuorg/risu/commit/491af4934babd2db67681038b40f17ba51b64a3c))

## [1.8.1](https://github.com/risuorg/risu/compare/1.8.0...1.8.1) (2022-11-04)

### Bug Fixes

- handle when options are not passed ([ec847a1](https://github.com/risuorg/risu/commit/ec847a1aabc9162ab9dad76c60fee2a336877b74))

## [1.8.1](https://github.com/risuorg/risu/compare/1.8.0...1.8.1) (2022-10-27)

### Bug Fixes

- handle when options are not passed ([ec847a1](https://github.com/risuorg/risu/commit/ec847a1aabc9162ab9dad76c60fee2a336877b74))

# [1.8.0](https://github.com/risuorg/risu/compare/1.7.7...1.8.0) (2022-10-27)

### Features

- Allow to limit the number of parallel processes ([99c02e8](https://github.com/risuorg/risu/commit/99c02e884e2c25dda654266ed8d5f6dc61871d4e))

## [1.7.7](https://github.com/risuorg/risu/compare/1.7.6...1.7.7) (2021-05-19)

### Bug Fixes

- **shell.py:** catch exceptions in category and subcategory generation ([e3c8424](https://github.com/risuorg/risu/commit/e3c8424a2346a14c6a59d37346eb120da3de0723))

## [1.7.6](https://github.com/risuorg/risu/compare/1.7.5...1.7.6) (2021-05-19)

### Bug Fixes

- **Dockerfile:** set utf8 locale for avoiding issues ([8cd221e](https://github.com/risuorg/risu/commit/8cd221eb34c9a041a1b8bace2bba7fec6a2fcb9e))

## [1.7.5](https://github.com/risuorg/risu/compare/1.7.4...1.7.5) (2021-05-19)

### Bug Fixes

- **Dockerfile:** fix entrypoint ([b8edb9e](https://github.com/risuorg/risu/commit/b8edb9e47e739aed4b53270cbe9a8e6fdcd6a99f))

## [1.7.4](https://github.com/risuorg/risu/compare/1.7.3...1.7.4) (2021-05-19)

### Bug Fixes

- **Dockerfile:** use python3 for installation ([336ff0d](https://github.com/risuorg/risu/commit/336ff0d6524ae8808a82edb8603bb4263be8d232))

## [1.7.3](https://github.com/risuorg/risu/compare/1.7.2...1.7.3) (2021-05-17)

### Bug Fixes

- **interface-onboot.sh:** fix processing of ifcfg options with quotes or different case ([f0e16b1](https://github.com/risuorg/risu/commit/f0e16b143c1b14ba0ab0f9da86f422c2fa9b70b3))

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
