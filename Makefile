.PHONY: build clean validate shellcheck

build:
	sudo ./build.sh

clean:
	sudo ./build.sh --clean
	sudo rm -rf work/

validate:
	@echo "Validating archiso profile..."
	@test -f archiso-profile/profiledef.sh || (echo "Missing profiledef.sh" && exit 1)
	@test -f archiso-profile/packages.x86_64 || (echo "Missing packages.x86_64" && exit 1)
	@test -f archiso-profile/pacman.conf || (echo "Missing pacman.conf" && exit 1)
	@echo "Profile OK"

shellcheck:
	shellcheck -S warning build.sh scripts/*.sh
	shellcheck -S warning archiso-profile/airootfs/usr/local/bin/erinos
	shellcheck -S warning archiso-profile/airootfs/usr/local/bin/erinos-onboard
	shellcheck -S warning archiso-profile/airootfs/etc/profile.d/erinos-motd.sh
	shellcheck -S warning archiso-profile/airootfs/root/customize_airootfs.sh
