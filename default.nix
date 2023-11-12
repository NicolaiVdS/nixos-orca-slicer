{ stdenv
, lib
, openexr
, jemalloc
, c-blosc
, binutils
, fetchFromGitHub
, cmake
, pkg-config
, wrapGAppsHook
, boost
, cereal
, cgal_5
, curl
, dbus
, eigen
, expat
, glew
, glib
, gmp
, gtk3
, hicolor-icon-theme
, ilmbase
, libpng
, mpfr
, nanosvg
, nlopt
, opencascade-occt
, openvdb
, pcre
, qhull
, tbb_2021_8
, wxGTK32
, xorg
, fetchpatch
, withSystemd ? lib.meta.availableOn stdenv.hostPlatform systemd, systemd
, wxGTK-override ? null
}:
let
  wxGTK-orca = wxGTK32.overrideAttrs (old: rec {
    pname = "wxwidgets-orca-patched";
    version = "3.2.0";
    configureFlags = old.configureFlags ++ [ "--disable-glcanvasegl" ];
    patches = [ ./wxWidgets-Makefile.in-fix.patch ];
    src = fetchFromGitHub {
      owner = "SoftFever";
      repo = "OrcaSlicer";
      rev = "v1.7.0";
      hash = "sha256-qwlLHtTVIRW1g5WRQ5NhDh+O8Bypra/voIu39yU2tbw=";
      fetchSubmodules = true;
    };
  });
  nanosvg-fltk = nanosvg.overrideAttrs (old: rec {
    pname = "nanosvg-fltk";
    version = "unstable-2022-12-22";

    src = fetchFromGitHub {
      owner = "fltk";
      repo = "nanosvg";
      rev = "abcd277ea45e9098bed752cf9c6875b533c0892f";
      hash = "sha256-WNdAYu66ggpSYJ8Kt57yEA4mSTv+Rvzj9Rm1q765HpY=";
    };
  });
  openvdb_tbb_2021_8 = openvdb.overrideAttrs (old: rec {
    buildInputs = [ openexr boost tbb_2021_8 jemalloc c-blosc ilmbase ];
  });
  wxGTK-override' = if wxGTK-override == null then wxGTK-orca else wxGTK-override;
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "OrcaSlicer";
    version = "1.7.0";

    nativeBuildInputs = [
      cmake
      pkg-config
      wrapGAppsHook
    ];

    buildInputs = [
      binutils
      boost
      cereal
      cgal_5
      curl
      dbus
      eigen
      expat
      glew
      glib
      gmp
      gtk3
      hicolor-icon-theme
      ilmbase
      libpng
      mpfr
      nanosvg-fltk
      nlopt
      opencascade-occt
      openvdb_tbb_2021_8
      pcre
      qhull
      tbb_2021_8
      wxGTK-override'
      xorg.libX11
    ] ++ lib.optionals withSystemd [
      systemd
    ];

    seperateDebugInfo = true;

    NLOPT = nlopt;

    NIX_LDFLAGS = lib.optionalString withSystemd "-ludev";

    prePatch = ''
      # Since version 2.5.0 of nlopt we need to link to libnlopt, as libnlopt_cxx
      # now seems to be integrated into the main lib.
      sed -i 's|nlopt_cxx|nlopt|g' cmake/modules/FindNLopt.cmake

      # Disable slic3r_jobs_tests.cpp as the test fails sometimes
      sed -i 's|slic3r_jobs_tests.cpp||g' tests/slic3rutils/CMakeLists.txt

      # Fix resources folder location on macOS
      substituteInPlace src/OrcaSlicer.cpp \
        --replace "#ifdef __APPLE__" "#if 0"
    '';
    
    patches = [
      (fetchpatch {
        url = "https://github.com/prusa3d/PrusaSlicer/commit/24a5ebd65c9d25a0fd69a3716d079fd1b00eb15c.patch";
        hash = "sha256-MNGtaI7THu6HEl9dMwcO1hkrCtIkscoNh4ulA2cKtZA=";
      })
    ];

    src = fetchFromGitHub {
      owner = "SoftFever";
      repo = "OrcaSlicer";
      hash = "sha256-qwlLHtTVIRW1g5WRQ5NhDh";
      rev = "v${finalAttrs.version}";
    };

    cmakeFlags = [
      "-DSLIC3R_STATIC=0"
      "-DSLIC3R_FHS=1"
      "-DSLIC3R_GTK=3"
    ];

    postInstall = ''
      ln -s "$out/bin/orca-slicer" "$out/bin/orca-gcodeviewer"

      mkdir -p "$out/lib"
      mv -v $out/bin/*.* $out/lib/

      mkdir -p "$out/share/pixmaps/"
      ln -s "$out/share/OrcaSlicer/icons/OrcaSlicer.png" "$out/share/pixmaps/OrcaSlicer.png"
      ln -s "$out/share/OrcaSlicer/icons/OrcaSlicer-gcodeviewer_192px.png" "$out/share/pixmaps/OrcaSlicer-gcodeviewer.png"
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix LD_LIBRARY_PATH : "$out/lib"
      )
    '';

    doCheck = true;

    checkPhase = ''
      runHook preCheck

      ctest \
        --force-new-ctest-process \
        -E 'libslic3r_tests|sla_print_tests'

      runHook postCheck
    '';

    meta = with lib; {
      description = "G-code generator for 3D printer";
      homepage = "https://github.com/SoftFever/OrcaSlicer";
      license = licenses.agpl3;
      maintainers = with maintainers; [ NicolaiVdS ];
    } // lib.optionalAttrs (stdenv.isDarwin) {
      mainProgram = "OrcaSlicer";
    };
  })

