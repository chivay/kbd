{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:chivay/nixpkgs?ref=qmk-fix";
  };

  outputs = { self, nixpkgs }: let 
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        keychron_src = pkgs.fetchFromGitHub {
          owner = "chivay";
          repo = "qmk_firmware";
          rev = "6c326c72dd5dde054ca8c88ce58ca8134467ebb5";
          sha256 = "sha256-ibGzSiI4l4vdjyNk5ZjUeZBm8ExjnofZeRDpUXSxGcw=";
          fetchSubmodules = true;
        }; 
  in {
    packages.x86_64-linux.flash = pkgs.writeShellScriptBin "flash_script" ''
        export QMK_HOME=${keychron_src}
        ${pkgs.qmk}/bin/qmk flash ${self.packages.x86_64-linux.firmware}/fw.bin
        ${pkgs.wb32-dfu-updater}/bin/wb32-dfu-updater_cli -R
      '';

    packages.x86_64-linux.firmware = pkgs.stdenv.mkDerivation rec {
      pname = "lemokey-p1-firmware";
      version = "0.1";
      buildInputs = [ pkgs.qmk pkgs.git ];

      src = keychron_src;

      SKIP_GIT=1;

      patchPhase = ''
        mkdir -p keyboards/lemokey/p1_pro/ansi_encoder/keymaps/chivay/
        cp -r ${./chivay}/* keyboards/lemokey/p1_pro/ansi_encoder/keymaps/chivay/
      '';

      buildPhase = ''
        qmk compile -kb lemokey/p1_pro/ansi_encoder -km chivay
      '';

      installPhase = ''
        mkdir -p $out
        cp .build/lemokey_p1_pro_ansi_encoder_chivay.bin $out/fw.bin
      '';
    };
  };
}
