# Makefile for the tools/ sub-directory

# Here, we can update the config.* scripts.
# If we're in CT_LIB_DIR, then CT_LIB_DIR == CT_TOP_DIR, and we can update those
# scripts for later inclusion mainline. If CT_LIB_DIR != CT_TOP_DIR, then those
# scripts are downloaded only for use in CT_TOP_DIR.

CONFIG_SUB_SRC="http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD"
CONFIG_SUB_DEST="$(CT_TOP_DIR)/tools/config.sub"
CONFIG_GUESS_SRC="http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD"
CONFIG_GUESS_DEST="$(CT_TOP_DIR)/tools/config.guess"

$(CT_TOP_DIR)/tools:
	$(SILENT)mkdir -p $(CT_TOP_DIR)/tools

PHONY += updatetools
updatetools: $(CT_TOP_DIR)/tools $(CONFIG_SUB_DEST) $(CONFIG_GUESS_DEST)

$(CONFIG_SUB_DEST):
	$(SILENT)wget $(CONFIG_SUB_SRC) -O $@
	$(SILENT)chmod u+rwx,go+rx-w $@

$(CONFIG_GUESS_DEST):
	$(SILENT)wget $(CONFIG_GUESS_SRC) -O $@
	$(SILENT)chmod u+rwx,go+rx-w $@

help-distrib::
	@echo  '  updatetools        - Update the config tools'

distclean::
	$(SILENT)[ $(CT_TOP_DIR) = $(CT_LIB_DIR) ] || rm -rf $(CT_TOP_DIR)/tools
