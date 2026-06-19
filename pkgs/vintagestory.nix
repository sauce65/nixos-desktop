# Vintage Story client bumped ahead of what nixpkgs ships. Reuses nixpkgs's
# derivation but overrides version + hash, and patches installPhase because
# 1.22 renamed gameicon.xpm -> gameicon.png.
{ vintagestory, fetchurl }:

vintagestory.overrideAttrs (old: rec {
  version = "1.22.2";
  src = fetchurl {
    url = "https://cdn.vintagestory.at/gamefiles/stable/vs_client_linux-x64_${version}.tar.gz";
    hash = "sha256-caLSOm/WXpXrjC1az72Nc0XDWOpWB2R9iVq8ShDEZgU=";
  };
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/vintagestory $out/bin $out/share/icons/hicolor/512x512/apps $out/share/fonts/truetype
    cp -r * $out/share/vintagestory
    cp $out/share/vintagestory/assets/gameicon.png $out/share/icons/hicolor/512x512/apps/vintagestory.png
    cp $out/share/vintagestory/assets/game/fonts/*.ttf $out/share/fonts/truetype

    rm -rvf $out/share/vintagestory/{install,run,server}.sh

    runHook postInstall
  '';
})
