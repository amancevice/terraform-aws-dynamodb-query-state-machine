validate:
	terraform fmt -check
	make -C example $@

.PHONY: validate
