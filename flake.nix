{
  inputs = {
    nixpkgs = { };
    flakelib.url = "github:flakelib/fl";
    flex = {
      url = "github:arcnmx/flex.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flakelib.follows = "flakelib";
      };
    };
  };
  outputs = { self, flakelib, nixpkgs, ... }@inputs: let
    nixlib = nixpkgs.lib;
  in flakelib {
    inherit inputs;

    legacyPackages = {
      apache-flex-sdk = { flex'apache-flex-sdk-full }: flex'apache-flex-sdk-full;
      apache-flash-player-sdk = { flex'apache-flash-player-sdk, apache-flex-sdk, adobe-flex-playerglobal }: flex'apache-flash-player-sdk.override {
        inherit apache-flex-sdk adobe-flex-playerglobal;
      };
      apache-air-sdk = { flex'apache-air-sdk, apache-flex-sdk }: flex'apache-air-sdk.override {
        inherit apache-flex-sdk;
      };
      apache-air-harman-sdk = { flex'apache-air-harman-sdk, apache-flex-sdk }: flex'apache-air-harman-sdk.override {
        inherit apache-flex-sdk;
      };
      source = { linkFarm, symlinkJoin, self'lib'src, self'lib'assets, fetchurl }: let
        inherit (nixlib) mapAttrsToList optionalString;
        linkFarm' = name: entries: (linkFarm name entries).overrideAttrs (_: {
          allowSubstitutes = true;
        });
        ref = "main";
        fetchAsset = { name, sha256, dir ? null, ref }: let
          dir' = optionalString (dir != null) "${dir}/";
        in fetchurl {
          inherit name;
          url = "https://github.com/flashflashrevolution/rCubed/raw/${ref}/${dir'}${name}?download=";
          inherit sha256;
        };
        noteskins = linkFarm' "r3-assets-noteskins" (mapAttrsToList (name: { sha256 }: {
          name = "src/game/noteskins/${name}.swf";
          path = fetchurl {
            url = "https://www.flashflashrevolution.com/game/r3/noteskins/${name}.swf";
            inherit sha256;
          };
        }) self'lib'assets.noteskins);
        fonts = linkFarm' "r3-assets-fonts" (mapAttrsToList (key: { sha256, dir ? key, name ? "${key}.ttf" }: let
          dir' = "fonts/${dir}/assets";
        in {
          name = "${dir'}/${name}";
          path = fetchAsset {
            inherit name sha256 ref;
            dir = dir';
          };
        }) self'lib'assets.fonts);
        libs = linkFarm' "r3-assets-libs" (mapAttrsToList (name: { sha256, dir ? null }: let
          dir' = "libs" + optionalString (dir != null) "/${dir}";
        in {
          name = "${dir'}/${name}.swc";
          path = fetchAsset {
            inherit sha256 ref;
            name = "${name}.swc";
            dir = dir';
          };
        }) self'lib'assets.libs);
      in symlinkJoin {
        name = self'lib'src.name;
        allowSubstitutes = true;
        paths = [
          noteskins
          fonts
          libs
          self'lib'src
        ];
      };
    };
    packages = let
      inherit (nixlib.meta) getExe;
    in {
      default = { r3air }: r3air;
      r3 = { stdenvNoCC, gnumake, air-sdk, source, buildType ? "release" }: let
        binName = {
          release = "bin/release/R3Air.swf";
          debug = "bin/develop/R3Air.swf";
          lib = "bin/R3Lib.swc";
        }.${buildType};
      in stdenvNoCC.mkDerivation rec {
        pname = "rCubed";
        version = "2.0";
        src = source;

        nativeBuildInputs = [
          gnumake
          air-sdk
        ];

        enableParallelBuilding = true;
        buildFlags = [ buildType "VERSION=${version}" ];

        inherit binName;
        installPhase = ''
          runHook preInstall

          install -Dt $out/bin -m 0755 $binName

          runHook postInstall
        '';
      };
      r3air = {
        r3
      , stdenvNoCC
      , makeWrapper, autoPatchelfHook
      , gnumake
      , air-sdk
      , glib
      , gtk2-x11
      , xorg'xorgserver
      }: stdenvNoCC.mkDerivation {
        pname = "rCubed";
        version = "2.0";
        inherit (r3) src binName;
        inherit r3;

        nativeBuildInputs = [
          autoPatchelfHook
          makeWrapper
          gnumake
          air-sdk
          # naip requires a display why...
          xorg'xorgserver
        ];
        buildInputs = [
          glib
          gtk2-x11
        ];

        enableParallelBuilding = true;
        buildFlags = [ "package" "TSA=none" ];

        preBuild = ''
          mkdir -p bin/release bin/fonts certs
          touch bin/fonts/Embedded-Fonts.swc
          cp $r3/bin/R3Air.swf bin/release/R3Air.swf
          touch bin/release/R3Air.swf

          export DISPLAY=:1
          Xvfb $DISPLAY -nolisten tcp &
          XPID=$!
        '';

        postBuild = ''
          kill $XPID || true
        '';

        installPhase = ''
          runHook preInstall

          install -d $out/lib
          cp -a bin/release/R3 $out/lib/r3air
          chmod -R +w $out/lib/r3air

          makeWrapper $out/lib/r3air/R3 $out/bin/R3

          autoPatchelf $out/lib/r3air/R3
          autoPatchelf $out/lib/r3air/Adobe\ Air/Versions/1.0/libCore.so

          runHook postInstall
        '';

        meta = {
          mainProgram = "R3";
        };
      };
      r3-ruffle = { r3, ruffle, gnome'zenity, writeShellScriptBin }: writeShellScriptBin "r3-ruffle" ''
        export PATH="$PATH:${gnome'zenity}/bin"
        exec ${getExe ruffle} ${r3}/bin/${r3.binName} --player-runtime air -Pruffle=1 "$@"
      '';
    };
    devShells = {
      default = { outputs'devShells'air }: outputs'devShells'air;
      harman = { mkShell, gnumake, harman-air-sdk-33, writeShellScriptBin }: mkShell {
        nativeBuildInputs = [
          gnumake
          harman-air-sdk-33
        ];
      };
      air-harman = { outputs'devShells'air, apache-air-harman-sdk }: outputs'devShells'air.override {
        apache-air-sdk = apache-air-harman-sdk;
      };
      air = { mkShell, gnumake, apache-air-sdk }: mkShell {
        nativeBuildInputs = [
          gnumake
          apache-air-sdk
        ];
      };
      flash = { mkShell, gnumake, apache-flash-player-sdk, adobe-flex-playerglobal }: mkShell {
        AIR = "0";
        TARGET_PLAYER = adobe-flex-playerglobal.version;
        EMBED_FONTS = "0";
        nativeBuildInputs = [
          gnumake
          apache-flash-player-sdk
        ];
      };
    };

    lib = {
      src = let
        inherit (nixlib.strings) hasPrefix hasSuffix removePrefix;
        inherit (nixlib.lists) elem;
        inherit (nixlib.trivial) flip;
        src = ./.;
        removeSrc = removePrefix (toString src + "/");
      in nixlib.cleanSourceWith {
        inherit src;
        name = "r3-src";
        filter = srcpath: type: let
          path = removeSrc srcpath + {
            directory = "/";
          }.${type} or "";
          name = baseNameOf path;
          pathSuffix = flip hasSuffix path;
          pathPrefix = flip hasPrefix path;
          srcFilter = pathSuffix ".as";
          dataFilter = pathPrefix "data/icons/" && pathSuffix ".png";
          fontsFilter = pathSuffix ".as";
          explicit = [
            "Makefile"
            "fonts/config.xml"
            "config.xml"
            "config-app.xml"
            "config-debug.xml"
            "config-release.xml"
            "config-lib.xml"
            "application.xml"
            "changelog.txt"
          ];
        in (pathPrefix "src/" && (srcFilter || type == "directory"))
          || (pathPrefix "data/" && (dataFilter || type == "directory"))
          || (pathPrefix "fonts/" && (fontsFilter || type == "directory"))
          || elem path explicit;
      };
      assets = {
        noteskins = {
          NoteSkin1.sha256 = "06224097b3574c466a2862b58a09c3c1e89a7f14b95a626fa5520a2e0b18d6cb";
          NoteSkin2.sha256 = "5de2c0e4adf614ec9947e8665185ad4a80ee37da5a73aeba4a4ee90e6fcef8e9";
          NoteSkin3.sha256 = "6aae9d9f78853cb122a135a818719afcb7e2ed3379c29156cee44d7a7460768f";
          NoteSkin4.sha256 = "cde3da948233805c97a60a8c6bfe4d253ad84b076125efe841dbf1e13c582c9e";
          NoteSkin5.sha256 = "8782acc4b8c6875114bfc274703e60e7129841ba73da621b5e7e220efaafefde";
          NoteSkin6.sha256 = "16b04ffb2770fc57c645b96defca59ab60169de63206c867caa220e692a9524e";
          NoteSkin7.sha256 = "e25ff19eaa4acd915c46b2780b7d33ea7fad863a8f49397cb17d08fcd45e4d45";
          NoteSkin8.sha256 = "0cd1ce584e07de4995ad694f5b5f1672a5fc9b1e6cd53d4a8ce03c63358459b6";
          NoteSkin9.sha256 = "835470cc7ed7a4dcf365713cf02acaa054d8d096326124ae56ea996c1c053bc3";
          NoteSkin10.sha256 = "db725724518cf8170360f7772a7d0d22895962ab4f7fc2bc1aec99cc9af697d5";
        };
        fonts = {
          AachenLight.sha256 = "9b925be107ca38044171db98ab4643eac17f4e016ce545c0d991e125cc45e112";
          BebasNeue-Regular = {
            dir = "BebasNeue";
            sha256 = "f2d8f000fd44a71714be0321ae12d3d6bc8bb0ea290b0c1312516f4448cec117";
          };
          BreeSerif-Regular = {
            dir = "BreeSerifRegular";
            sha256 = "bbbe2e2e4c0ccc33fcd92bf6b40ef86f9ef4458433d3c3ee11b57aebdcc92c50";
          };
          Hussar-Regular = {
            dir = "HussarBold";
            sha256 = "40b58388a5ea92a8d4d7b3734cac59f0a12b49a00cf27607754f6f86dbb94de7";
          };
          Hussar-Italic = {
            dir = "HussarBold";
            sha256 = "cd63b130045b168550d3ca28fa3c82a79af8997f8014262a00b97c9d44f27e66";
          };
          NotoSans-Bold = {
            dir = "NotoSans";
            sha256 = "7c15ac396d2ce6bc33a3b4efacdbd322c9e46376599a725c6f790d8036052cab";
          };
          NotoSans-CJK-Bold = {
            dir = "NotoSans";
            name = "NotoSans-CJK-Bold.ttc";
            sha256 = "0c066cc1f22541fd9e138190de26dc480a4b8221bef5321e27e7b7802b26ee5e";
          };
          Ultra.sha256 = "d38e3ce88d12aec61e936c76516535a230d72acf29d18aeb1798d8b028475a21";
          Xolonium-Regular = {
            dir = "Xolonium";
            sha256 = "d6453340972bfa0d42a660765021a915703e4536adc37888fe8eba3981e0ad3d";
          };
          Xolonium-Bold = {
            dir = "Xolonium";
            sha256 = "ae20d97e70f62703fd0b55b07e1c0d0b3ea8ddda9fb6505088bec85a30619b1c";
          };
        };
        libs = {
          assets = {
            sha256 = "a67131333cbd0911aaa1a905219184da0b9fca37c9e68c4ca11d0a93e0813b42";
            dir = "assets";
          };
          branding = {
            sha256 = "e3ff80d0360ac88b9a6d5fb96f3adda37eac4697cc5a57df19bf2103ab1f7068";
            dir = "assets";
          };
          icons = {
            sha256 = "1b30ff5fe3ac743a4b09c2042bcb2dcedb6ff2789da25ca0bf8d4fe4e84e3cce";
            dir = "assets";
          };
          blooddy_crypto.sha256 = "78769746a81edb31b507d344bd3f96f5aae15da8bcce1f49ada75af15409729d";
        };
      };
    };
  };
}
