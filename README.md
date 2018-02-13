## What is it?

This is a simple "walking skeleton" of GIS viewer which uses GEOS library to store and manipulate features' geometry data. It supports MapInfo MIF files (subset only).

The GUI is very limited so if you find the app almost useless I won't be suprised. There is only one preconfigured 'demodata/project.xml' to load and no ability to configure and save new projects inside the app.

And what does 'marfa' mean? This is an abbreviation which consists of 'map', 'feature' and other such kind of buzzwords.:) Think of it as a codename of a bigger project that didn't survive.

## Technical notes

The project utilizes the following third-party libraries:

- SimpleXML <http://www.audio-data.de/simplexml.html>;
- GDI+ library <http://www.progdigy.com/?page_id=7>;
- GEOS library <http://trac.osgeo.org/geos/>.

I've made Delphi interface for GEOS library and simple wrapper classes (very limited) - see 'Geos_c.pas', 'GeosGeometry.pas' units. Some examples of 'Geos_c.pas' usage can be found in 'test/DummyGeosUseTest.pas' which are made up as DUnit test cases. 

You may come across russian comments somewhere - just ignore it. I think the code itself is quite clear.

Developed with Delphi XE2.

### Using sources

1. First open '*_components.dproj', then compile and install 'TMapControl' component. It will be installed to 'Samples' page. You have to put 'geoc_c.dll' (see bellow) to 'C:\Users\Public\Documents\RAD Studio\9.0\Bpl' to make it work.
2. Now you can open '*.groupproj' to access all the code inside. You have to put 'geoc_c.dll' to 'bin/debug' and/or 'bin/release' folders where the app will be compiled.

### GEOS dependency

I included 'geos_c.dll' i've used in the 'dll' folder.

Newer versions could be found at GEOS home page:
<http://trac.osgeo.org/geos/>

or you can build it from sources:
<https://github.com/libgeos/libgeos>

## Demo data

Borrowed from State Government of Victoria Land Channel at:
<https://services.land.vic.gov.au/landchannel/content/help?name=sampledata>

## Screenshots

![alt text](https://github.com/dvfed/gis-viewer/blob/master/doc/images/screen.png "Screenshot")
