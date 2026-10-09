Name: marble-device-support
Version: 1.0.0
Release: alt1
Summary: Hardware support package for Xiaomi Poco F5 (marble)
License: GPL-2.0-or-later and MIT
Group: System/Configuration/Hardware
Url: https://github.com/iLtanaka/marble-device-support

ExclusiveArch: aarch64

Source: %name-%version.tar

BuildRequires: gcc make

Requires: alsa-ucm-conf
Requires: uclampset

%description
This package provides device-specific configuration, ALSA UCM2 audio
profiles, udev rules, and performance tuning daemons for running
ALT Mobile on Xiaomi Poco F5 / Redmi Note 12 Turbo (SM7475).

%prep
%setup

%build
%make_build

%install
%makeinstall_std PREFIX=%_prefix

%files
%_libexecdir/marble-*
%_datadir/alsa/ucm2/conf.d/sm8450/*
%_datadir/alsa/ucm2/Qualcomm/sm8450/xiaomi-marble/*
%_udevrulesdir/*
%_unitdir/marble-*
%_unitdir/*.service.d/*
%_sysctldir/*
%_environmentdir/*

%changelog
* Fri Oct 09 2026 Tatsuki Tanaka <tatsuki@tanakatatsuki.dev> 1.0.0-alt1
- Initial release for Xiaomi Poco F5 (SM7475)
