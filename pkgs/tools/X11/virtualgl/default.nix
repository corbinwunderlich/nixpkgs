{
  lib,
  stdenv,
  fetchurl,
  cmake,
  libGL,
  libGLU,
  libXv,
  libXtst,
  libXi,
  libjpeg_turbo,
  fltk,
  xorg,
  opencl-headers,
  opencl-clhpp,
  ocl-icd,
  addDriverRunpath,
  vulkan-loader,
  makeWrapper,
  customLibraries ? [ ], # If a program complains about missing graphics libraries, like vulkan-loader, override the package and add it to this list
}:

stdenv.mkDerivation rec {
  pname = "virtualgl";
  version = "3.0.2";

  src = fetchurl {
    url = "mirror://sourceforge/virtualgl/VirtualGL-${version}.tar.gz";
    sha256 = "sha256-OIEbwAQ71yOuHIzM+iaK7QkUJrKg6sXpGuFQOUPjM2w=";
  };

  postPatch = ''
    # the unit tests take significant hacks to build and can't run anyway due to the lack
    # of a 3D X server in the build sandbox. so we just chop out their build instructions.
    head -n $(grep -n 'UNIT TESTS' server/CMakeLists.txt | cut -d : -f 1) server/CMakeLists.txt > server/CMakeLists2.txt
    mv server/CMakeLists2.txt server/CMakeLists.txt
  '';

  cmakeFlags = [
    "-DVGL_SYSTEMFLTK=1"
    "-DTJPEG_LIBRARY=${libjpeg_turbo.out}/lib/libturbojpeg.so"
  ];

  makeFlags = [ "PREFIX=$(out)" ];

  nativeBuildInputs = [
    cmake
    makeWrapper
  ];

  buildInputs = [
    libjpeg_turbo
    libGL
    libGLU
    fltk
    libXv
    libXtst
    libXi
    xorg.xcbutilkeysyms
    opencl-headers
    opencl-clhpp
    ocl-icd
  ];

  fixupPhase = ''
    substituteInPlace $out/bin/vglrun \
      --replace "LD_PRELOAD=libvglfaker" "LD_PRELOAD=$out/lib/libvglfaker" \
      --replace "LD_PRELOAD=libdlfaker" "LD_PRELOAD=$out/lib/libdlfaker" \
      --replace "LD_PRELOAD=libgefaker" "LD_PRELOAD=$out/lib/libgefaker"

      wrapProgram $out/bin/vglrun \
        --prefix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath (
            [
              addDriverRunpath.driverLink

              #Needed for vulkaninfo to work
              vulkan-loader
            ]
            ++ customLibraries
          )
        }"
  '';

  meta = with lib; {
    homepage = "https://www.virtualgl.org/";
    description = "X11 GL rendering in a remote computer with full 3D hw acceleration";
    license = licenses.wxWindows;
    platforms = platforms.linux;
    maintainers = with maintainers; [
      abbradar
      corbinwunderlich
    ];
  };
}
