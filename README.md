# CryptexManager
CryptexManager is an open-source replacement for cryptexctl.
It supports creating, signing, installing, uninstalling and listing cryptexes.

# Building
First, make sure libimobiledevice is installed (`brew install libimobiledevice`). Afterwards, it should be sufficient to run `swift build -c release -Xlinker -L/usr/local/lib` (or `swift build -c release -Xlinker -L/opt/homebrew/lib` on arm64). The executable can then be found at `.build/release/CryptexManager`.

# Using
For now, just run CryptexManager without arguments to see the usage.

# Using in a Makefile
To use CryptexManager instead of cryptexctl in a Makefile (assuming you're using the example Makefile provided by Apple), replace the install/uninstall actions with this:
```Makefile
# Uninstall the cryptex from the device
.PHONY: uninstall
uninstall:
	@$(call log, Removing ${CRYPTEX_ID} from device: ${CRYPTEXCTL_UDID})
	$(call check_path, CryptexManager, "CryptexManager is not on your path. Please make sure it is installed.")
	CryptexManager -u ${CRYPTEXCTL_UDID} list
	CryptexManager -u ${CRYPTEXCTL_UDID} uninstall ${CRYPTEX_ID}
	CryptexManager -u ${CRYPTEXCTL_UDID} list

# Install the cryptex onto the device
.PHONY: install
install: ${CRYPTEX_PATH}
	@$(call log, Installing ${CRYPTEX_PATH} onto device: ${CRYPTEXCTL_UDID})
	$(call check_path, CryptexManager, "CryptexManager is not on your path. Please make sure it is installed.")
	CryptexManager -u ${CRYPTEXCTL_UDID} uninstall ${CRYPTEX_ID} || true
	CryptexManager -u ${CRYPTEXCTL_UDID} install ${CRYPTEX_PATH} || log_die "Failed to install cryptex... Is your device '${CRYPTEXCTL_UDID}' connected?" $?
	CryptexManager -u ${CRYPTEXCTL_UDID} list
```

Additionally, replace the create rule with this:
```Makefile
# Create the cryptex from the disk image containing the distribution root
${CRYPTEX_PATH}: ${CRYPTEX_DMG_NAME}
	@$(call log, Creating cryptex ${CRYPTEX_PATH} - ${CRYPTEX_VERSION} from the disk image ${CRYPTEX_DMG_NAME})
	$(call check_path, CryptexManager, "CryptexManager is not on your path. Please make sure it is installed.")
	CryptexManager -u ${CRYPTEXCTL_UDID} create -i ${CRYPTEX_ID} -v ${CRYPTEX_VERSION} ${CRYPTEX_DMG_NAME} ${CRYPTEX_ROOT_DIR} ${CRYPTEX_PATH}
```
