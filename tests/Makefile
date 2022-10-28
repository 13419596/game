
ODIN=$(shell which odin)
PYTHON=$(shell which python3)
COLLECTIONS=-collection:tests=./ -collection:game=../src

all: generate_test_assets test_util test_container_set test_gmath test_gstrconv test_trie test_argparse

generate_test_assets:
	$(PYTHON) -m pip install numpy
	$(PYTHON) -m pip install numpy-quaternion
	$(PYTHON) generate_complex_test_data.py

test_util:
	$(ODIN) run util/ $(COLLECTIONS)

# No test format, odin is still broken
# test_fmt:
# 	$(ODIN) run fmt/ $(COLLECTIONS)
#
# test_regex:
# 	$(ODIN) run regex/ $(COLLECTIONS)

test_container_set:
	$(ODIN) run container/set/ $(COLLECTIONS)

test_gmath:
	$(ODIN) run gmath/ $(COLLECTIONS)

test_gstrconv:
	$(ODIN) run gstrconv/ $(COLLECTIONS)

test_trie:
	$(ODIN) run trie/ $(COLLECTIONS)

test_argparse:
	$(ODIN) run argparse/ $(COLLECTIONS)

