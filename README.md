# BreviaryExtractorBackend

Takes the Liturgy of the Hours from iBreviary (http://www.ibreviary.com/m/breviario.php) and converts each hour to a Kindle-friendly format.

# Notes for compiling.

In both OS X and Windows, the program should build simply by entering the root of the archive and typing

    dub build

The binary, the resources, and (for Windows) the `tidy.dll` file will all be located in the `bin/osx` or `bin\windows` folder.

However, there are dependencies.

## For all platforms

 - `dub`, which can be obtained at http://code.dlang.org/download.
 - [Python 3.5](https://www.python.org/downloads/) or higher with the [PyInstaller](http://www.pyinstaller.org/) and [RoboBrowser](http://robobrowser.readthedocs.org/en/latest/) modules installed. (Both of the modules are easily installed using [`pip`](https://pypi.python.org/pypi/pip).)

Be sure that both `dub` and `pyinstaller` are on the path.

## For Windows.

 - The D compiler, [DMD](http://dlang.org/dmd-windows.html) (Possibly [GDC](http://gdcproject.org/) will work, but I have not tested it, and it might require changing a few of the imports, since GDC uses a somewhat out-of-date version of the runtime library.)
 - The [HTML Tidy library](http://www.html-tidy.org/) must be installed as a dynamic library in the DMD hierarchy. This is done as follows.
   - Download the library and also [CMake](https://cmake.org/).
   - Compile it and install it to a local directory [as follows](http://www.html-tidy.org/documentation/#part_building). From the command line, enter

            cd {your-tidy-html5-directory}/build/cmake
            cmake ../.. -DCMAKE_INSTALL_PREFIX={wherever you would like to install it} 
            cmake --build . --config Release --target INSTALL

   - Go to the folder where you installed it and from the `bin` folder copy `tidy.dll` to the folder `C:\D\dmd2\windows\bin` (assuming that DMD has been installed in its default location: `C:\D`).
   - Also, from the `lib` folder, copy `tidy.lib` to the folder `C:\D\dmd2\windows\lib`.
   - However, you must convert `tidy.lib` to the “OMF” format. This can be done using the utility [`coffimplib`](http://www.digitalmars.com/ctg/coffimplib.html) which can be found in the `scripts` folder under `BreviaryExtractor`. Simply copy unzip the archive `coffimplib.zip` and copy `coffimplib.exe` to the folder `C:\D\dmd2\windows\lib`. From a command line, type

            c:
            cd \D\dmd2\windows\lib
            coffimplib tidy.lib -f

     You may then delete `coffimplib.exe` from the folder `C:\D\dmd2\windows\lib`.
