.PHONY: gen
gen:
	cd packages/solutions && dart run build_runner build --delete-conflicting-outputs

.PHONY: watch
watch:
	cd packages/solutions && dart run build_runner watch --delete-conflicting-outputs

.PHONY: format
format:
	dart format packages/*/bin packages/*/lib packages/*/tool
