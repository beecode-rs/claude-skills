.PHONY: toc

# Regenerate the table of contents in README.md (requires the <!-- toc --> markers to stay in place)
toc:
	npx -y markdown-toc -i --bullets "-" README.md
