# MouseHook
MouseHook is an open source macOS app written in Swift that allows you to hook a duplicate mouse cursor to your mouse's location and have it mimic the appearance of your mouse. This is especially useful for fixing the annoying issue where the software Parsec doesn't show the host mouse when using it as a monitor extender.

Please note that MouseHook has only been developed and tested in my personal environment and I cannot provide any guarantees that it will work in other environments. Use at your own risk.

## Installation

To install Togemon, download the latest release from the releases page and drag the app to your Applications folder. You may have to allow unsigned applications in `Security and Privacy`.

Alternatively, you can clone the repository and build the app from source:

```
git clone https://github.com/brgj/Togemon.git
cd Togemon
xcodebuild
```

## Usage

To use MouseHook, simply launch the app and click the app icon in the menu bar. Any monitors currently allowing mousehook functionality will appear with a ✅ and by clicking the monitor label, it will turn it off for that monitor. Monitors on which the app is disabled are denoted by an ❌.

### Demo
