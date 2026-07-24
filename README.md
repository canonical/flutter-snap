# Flutter Snap

[![Get it from the Snap Store](https://snapcraft.io/en/dark/install.svg)](https://snapcraft.io/flutter)

This repository contains the packaging used to build the [Flutter](https://flutter.dev/)
snap published in the [Snap Store](https://snapcraft.io/flutter).

[Flutter](https://flutter.dev/) is an open-source framework for building
beautiful, natively compiled, multi-platform applications from a single
codebase.

The snap provides the `flutter` and `dart` command line tools. On first use the
snap downloads the latest stable Flutter SDK into your home directory so it can
be upgraded independently of the snap itself.

Building Linux desktop applications relies on a build toolchain that is not
bundled in the snap and must be installed on your system. The snap checks for
these tools and, if any are missing, prints how to install them for your
distribution.

## Installation

Install the snap from the Snap Store:

```sh
sudo snap install flutter --classic
```

The snap uses [classic confinement](https://snapcraft.io/docs/classic-confinement)
so that Flutter can use the host's build toolchain and access the files needed
to build applications.

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
