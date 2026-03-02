export IMAGE_PATH=images/logo.png
export IMAGE_PATH_2=images/initials.png
export CELLNAME=logo
export CELLNAME_2=initials
export GDS_PATH=gds/logo.gds
export GDS_PATH_2=gds/initials.gds

export PDK_ROOT=../../../../pdk
export PDK=ihp-sg13g2

export CHIP_GDS=../chip/final/gds/top.gds
export CHIP_GDS_WITH_LOGO=gds/final-logo.gds
export CHIP_GDS_WITH_LOGO_AND_INITIALS=gds/final-logo-initials.gds

.PHONY: img2gds
img2gds:
	mkdir -p gds
	python scripts/img2gds.py --cellname $(CELLNAME) --invert --layer 134 --scale 0.25 --pixel-size 2 $(IMAGE_PATH) $(GDS_PATH)
	python scripts/img2gds.py --cellname $(CELLNAME_2) --invert --layer 134 --scale 0.25 --pixel-size 2 $(IMAGE_PATH_2) $(GDS_PATH_2)

.PHONY: drc
drc:
	python $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/drc/run_drc.py --run_dir drc/ --no_density --path $(GDS_PATH)
	python $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/drc/run_drc.py --run_dir drc/ --no_density --path $(GDS_PATH_2)

.PHONY: klayout_logo
klayout_logo:
	KLAYOUT_HOME=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/ klayout -e $(GDS_PATH)


.PHONY: klayout_initials
klayout_initials:
	KLAYOUT_HOME=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/ klayout -e $(GDS_PATH_2)

.PHONY: insert_img
insert_img:
	python scripts/insert_img.py $(CHIP_GDS) $(GDS_PATH) $(CHIP_GDS_WITH_LOGO) 708 713 $(CELLNAME)
	python scripts/insert_img.py $(CHIP_GDS_WITH_LOGO) $(GDS_PATH_2) $(CHIP_GDS_WITH_LOGO_AND_INITIALS) 1300 400 $(CELLNAME_2)

.PHONY: klayout-final
klayout-final:
	KLAYOUT_HOME=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/ klayout -e $(CHIP_GDS_WITH_LOGO_AND_INITIALS)
