CASE ?= $(TEST)

test:
	prove -vl tests/t/$(CASE)*.t
cover:
	cover -test -ignore_re '^tests/t/'
