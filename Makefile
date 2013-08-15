all:
	xcodebuild

pkg: all
	rm -f Detached-app.tgz
	tar -czf Detached-app.tgz -C build/Release Detached.app

release: pkg
	cp Detached-app.tgz ~/Dropbox/Public/

