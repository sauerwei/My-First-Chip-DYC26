WORK_DIR=$(shell pwd)
TOP=top
TAG=top-run-full

PDK_ROOT ?= $(WORK_DIR)/../../pdk
PDK = ihp-sg13g2

.PHONY: librelane
librelane:
	PDK_ROOT=$(PDK_ROOT) PDK=$(PDK) librelane --manual-pdk --run-tag $(TAG) --overwrite config.yaml
	cp -r runs/$(TAG)/final final

.PHONY: librelane-skip-synth
librelane-skip-synth:
	PDK_ROOT=$(PDK_ROOT) PDK=$(PDK) librelane --manual-pdk --run-tag $(TAG)_no-synth --overwrite --with-initial-state runs/top-run/06-yosys-synthesis/state_out.json --from Checker.YosysUnmappedCells config.yaml

.PHONY: view-results
view-results:
	PDK_ROOT=$(PDK_ROOT) PDK=$(PDK) librelane --manual-pdk --last-run --flow OpenInOpenROAD config.yaml