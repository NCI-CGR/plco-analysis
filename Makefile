SUPPORTED_METHODS := saige boltlmm fastgwa
.PHONY: all $(SUPPORTED_METHODS) meta
all: meta
meta: $(SUPPORTED_METHODS)
	$(MAKE) -C shared-makefiles/Makefile.metal
$(SUPPORTED_METHODS):
	$(MAKE) -C shared-makefiles/Makefile.$@
