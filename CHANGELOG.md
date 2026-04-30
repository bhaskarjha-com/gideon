# Changelog

## 1.0.0 (2026-04-30)


### Features

* add identity guard hook and post-setup verification ([29e9d38](https://github.com/bhaskarjha-com/gitsetu/commit/29e9d38f1e9bda793702f6aabc2f9d7dfef9f090))
* add main CLI with setup wizard and CRLF self-healing ([064eb97](https://github.com/bhaskarjha-com/gitsetu/commit/064eb97095b5d52266f924c6dee90fa784df73db))
* add Manual Mode (directory-less profiles) for power users ([ff95fdb](https://github.com/bhaskarjha-com/gitsetu/commit/ff95fdb0fa95ae283c110b6db0aedd8b9a8f0dc8))
* add multi-provider support and SSH passphrases for v1.0.0 ([ca07835](https://github.com/bhaskarjha-com/gitsetu/commit/ca07835e305f3efe0fda39900e37e1278e7f48b5))
* **core:** implement final v1.1.0-alpha Must-Have features ([cc7a0c5](https://github.com/bhaskarjha-com/gitsetu/commit/cc7a0c5260c13c5ee845acc1422e01be0069e821))
* **core:** implement high-value integrations (Should Have) ([dd3305f](https://github.com/bhaskarjha-com/gitsetu/commit/dd3305f268c54485834bd063fd75a890bc273b43))
* **core:** rename project to GitSetu and implement headless add cmd ([2d155cd](https://github.com/bhaskarjha-com/gitsetu/commit/2d155cd87ec7dc1d5e8104f651cd994eb2f6ddc1))
* **gitconfig:** add git configuration generator ([38e4b46](https://github.com/bhaskarjha-com/gitsetu/commit/38e4b46df27205b1c782d5ee2b70c7f706c91d2d))
* implement teardown functionality to safely remove gideon configurations and add supporting documentation ([71bf75c](https://github.com/bhaskarjha-com/gitsetu/commit/71bf75ca1c9c08ac871ce24372ec53e69ff0b7e7))
* **lib:** add core library modules ([c93ee1c](https://github.com/bhaskarjha-com/gitsetu/commit/c93ee1c6a7ce6114a0a771f9553eb5fc0ebffa51))
* native integration of git safe.directory rules to solve VirtualBox/WSL dubious ownership issues ([6526805](https://github.com/bhaskarjha-com/gitsetu/commit/65268059635b84e8bbf99767ab7c5bc1d6d4cf7f))
* restore global fallback, refine discovery, add gideon doctor ([ca09d59](https://github.com/bhaskarjha-com/gitsetu/commit/ca09d59d435254fb9ade6e9727d2350a58d3dbfc))
* **security:** implement privacy guard-rails, gideon run, and test suite expansion ([d0ef7cb](https://github.com/bhaskarjha-com/gitsetu/commit/d0ef7cb596c84561fd28b701addfa09c60adb8f2))
* **ssh:** add SSH key generation and config management ([c2360b8](https://github.com/bhaskarjha-com/gitsetu/commit/c2360b8a70121c691786c222c41b66548252d112))


### Bug Fixes

* **architecture:** resolve audit report findings ([13fb60c](https://github.com/bhaskarjha-com/gitsetu/commit/13fb60c5c335ec10a441ba421872cdb409c976c5))
* **cli:** resolve argument parsing and label validation edge cases ([72fe523](https://github.com/bhaskarjha-com/gitsetu/commit/72fe523043418aca9ec4453eed43fd1dbca11fc6))
* **core:** replace source &lt;(...) with eval for cross-environment compatibility ([fd2e223](https://github.com/bhaskarjha-com/gitsetu/commit/fd2e2235996e1d930f487e3e2c20e196ff5bd857))
* **core:** use gideon_source for doctor.sh ([e95c197](https://github.com/bhaskarjha-com/gitsetu/commit/e95c197ff471617945dcc87b70bd5e65fc8f10e7))
* ensure gideon executable bit is tracked and integration tests use bash ([41fec68](https://github.com/bhaskarjha-com/gitsetu/commit/41fec68880a10ae0e72b56156074e42ea351a4cb))
* move shellcheck directives to preceding line (SC1126) ([d788bec](https://github.com/bhaskarjha-com/gitsetu/commit/d788bec4fc2b803f5f3248b76abb92adb16b02fa))
* remove unused MAGENTA color variable from UI ([dc6285d](https://github.com/bhaskarjha-com/gitsetu/commit/dc6285d5c0a5a4a0771defe61dc5e709280ff142))
* resolve all ShellCheck warnings for clean CI ([231a3ae](https://github.com/bhaskarjha-com/gitsetu/commit/231a3aec9adfa0546705730eb5859c3ca38b7d12))
* resolve awk escaping bug in gitconfig generation ([993a1fb](https://github.com/bhaskarjha-com/gitsetu/commit/993a1fb61755a0390cff735486eb403243490f59))
* resolve shellcheck SC2034 warnings ([adec5aa](https://github.com/bhaskarjha-com/gitsetu/commit/adec5aaf180274f1221359d2801e462fc7356ecf))
* resolve shellcheck warnings in router and setup ([de6a1a3](https://github.com/bhaskarjha-com/gitsetu/commit/de6a1a3b4288147d9ebf66c78ae49bb57ae8f49d))
* resolve Windows path mismatch in teardown guard uninstallation ([fd3f9c9](https://github.com/bhaskarjha-com/gitsetu/commit/fd3f9c958855e7b9a64c07bba8f6aed3d5b828ac))
* **security:** enforce useConfigOnly guardrail and resolve registry race condition ([8e96fea](https://github.com/bhaskarjha-com/gitsetu/commit/8e96fea502705a553faa2ce6f17bcec0aa80854a))
* skip permission test on Git Bash (NTFS has no chmod) ([942b68c](https://github.com/bhaskarjha-com/gitsetu/commit/942b68cf0373ad279f5b0d1871f685863384a0bd))
* **test:** strip trailing CRLF from gideon_script path ([43420e9](https://github.com/bhaskarjha-com/gitsetu/commit/43420e9bc20baa5e983308d1db537115277ee2cb))
* update test coverage and add validation for empty strings in existing paths ([c753991](https://github.com/bhaskarjha-com/gitsetu/commit/c753991542024787fc6935be806a9ec5b4230c42))
* use tr -s for double-slash collapse (Git Bash compat) ([5352bc5](https://github.com/bhaskarjha-com/gitsetu/commit/5352bc5e9ce794014a6827dc1a6ccfcbce3aa42a))
