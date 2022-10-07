
let
  pkgs = import <nixpkgs> {};
  arch = "64";
  version = "3.5";
  releaseName = "stable";
  subdir = "";
  pkg = pkgs.stdenv.mkDerivation  {
    name = "godot-mono-unwrapped";
    buildInputs = with pkgs; [ unzip ];
    unpackPhase = "unzip $src";
    version = version;
    src = pkgs.fetchurl {
      url = "https://downloads.tuxfamily.org/godotengine/${version}${subdir}/mono/Godot_v${version}-${releaseName}_mono_x11_${arch}.zip";
      sha256 = "sha256-rQyhvfgiqa81Pxf4Nz2/0yhi5Vyp+CMNx1K3hAZWuJ4=";
    };
    installPhase = ''
      cp -r . $out
    '';
  };
in pkgs.buildFHSUserEnv {
  name = "godot-mono";
  targetPkgs = pkgs: (with pkgs;
    [ alsaLib
      dotnetCorePackages.sdk_5_0
      libGL
      libpulseaudio
      udev
      xorg.libX11
      xorg.libXcursor
      xorg.libXext
      xorg.libXi
      xorg.libXinerama
      xorg.libXrandr
      xorg.libXrender
      zlib
    ]);
  runScript = "${pkg.outPath}/Godot_v${version}-${releaseName}_mono_x11_${arch}/Godot_v${version}-${releaseName}_mono_x11.${arch}";
}
