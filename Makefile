PREFIX?=/usr/local

.PHONY: all clean

all: build/vmcli

build:
	mkdir -p build

build/vmcli: build vmcli/Sources/vmcli/main.swift vmcli/Package.swift
	cd vmcli && swift build -c release --disable-sandbox
	cp vmcli/.build/release/vmcli build/vmcli
	codesign -s - --entitlements vmcli/vmcli.entitlements build/vmcli
	chmod +x build/vmcli

clean:
	rm -rf build

