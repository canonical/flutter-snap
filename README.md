# Flutter Snap

[![Get it from the Snap Store](https://snapcraft.io/en/dark/install.svg)](https://snapcraft.io/flutter)

This repository contains the packaging used to build the [Flutter](https://flutter.dev/)
snap published in the [Snap Store](https://snapcraft.io/flutter).

[Flutter](https://flutter.dev/) is an open-source framework for building
beautiful, natively compiled, multi-platform applications from a single
codebase.

The snap provides the `flutter` and `dart` command line tools, bundled together
with the libraries and build tools (such as `clang`, `cmake`, `ninja`,
`pkg-config` and the GTK development headers) needed to build Linux desktop
applications. On first use the snap downloads the latest stable Flutter SDK into
your home directory so it can be upgraded independently of the snap itself.

## Installation

Install the snap from the Snap Store:

```sh
sudo snap install flutter --classic
```

The snap uses [classic confinement](https://snapcraft.io/docs/classic-confinement)
so that Flutter can access the toolchain and files needed to build applications.

## Usage

Once installed, use the `flutter` and `dart` commands as described in the
[Flutter documentation](https://docs.flutter.dev/).

The first time you run `flutter`, the snap downloads the latest stable release of
the Flutter SDK into `~/snap/flutter/common/flutter`. This is a normal Flutter
git checkout, so you can inspect and upgrade it as usual.

The bundled Dart SDK is available through the `dart` command. When another snap
also provides a `dart` command, use `flutter.dart` to run the one from this snap:

```sh
flutter.dart --version
```

### Upgrading Flutter

Upgrade the bundled Flutter SDK to the latest release on its channel:

```sh
flutter upgrade
```

### Resetting the SDK

If the SDK checkout gets into a bad state, you can remove it and download a fresh
copy:

```sh
flutter --reset
```
