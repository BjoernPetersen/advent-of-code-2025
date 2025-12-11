.PHONY: worker
worker: gen
	cd packages/frontend && dart compile js lib/async/day_worker.dart -o web/workers/day-worker.js -O2

.PHONY: gen
gen:
	cd packages/solutions && dart run build_runner build --delete-conflicting-outputs

.PHONY: watch
watch:
	cd packages/solutions && dart run build_runner watch --delete-conflicting-outputs

.PHONY: format
format:
	dart format packages/*/bin packages/*/lib packages/*/test packages/*/tool tool

upload:
	dart run tool/sync.dart

download:
	dart run tool/sync.dart download
