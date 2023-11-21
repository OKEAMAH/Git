.PHONY: all
all:
	(cd .. && . ./scripts/version.sh && dune exec ci/bin/main.exe)

# Used in the CI to verify that [.gitlab-ci.yml] is up to date.
.PHONY: check
check: all
	@git status | grep "nothing to commit" > /dev/null || ( \
	  echo "Repository not clean after 'make -C ci'."; \
	  echo "You should not edit generated GitLab CI .yml files directly."; \
	  echo "Edit ci/bin/main.ml instead."; \
	  echo "Then run 'make -C ci' and commit the difference."; \
	  exit 1 \
	)
