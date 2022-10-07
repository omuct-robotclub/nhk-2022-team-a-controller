let  
  pkgs = import <nixpkgs> {};
  godot-mono = import ./godot.nix;

  android-nixpkgs = pkgs.callPackage (import (builtins.fetchGit {
    url = "https://github.com/tadfisher/android-nixpkgs.git";
  })) {
    channel = "stable";
  };

  android-sdk = android-nixpkgs.sdk (sdkPkgs: with sdkPkgs; [
    platform-tools
    platforms-android-32
    build-tools-32-0-0
    build-tools-30-0-3
    cmdline-tools-latest
    ndk-23-2-8568313
    emulator
    patcher-v4
  ]);

in

pkgs.mkShell {
  buildInputs = with pkgs; [
    android-sdk
    android-studio
    godot-mono
    openjdk11
  ];

  GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${android-sdk}/share/android-sdk/build-tools/32.0.0/aapt2";
}