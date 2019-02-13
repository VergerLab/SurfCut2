# SurfCut

Copyright 2019 INRA - CNRS

File author(s): Stéphane Verger stephane.verger@slu.se

Distributed under the Cecill-C License.
See accompanying file LICENSE.txt or copy at
http://www.cecill.info/licences/Licence_CeCILL-C_V1-en.html

Please cite the original publications:

Erguvan, O., ... To be published...

Github: https://github.com/sverger/SurfCut

## Description

SurfCut is an imageJ macro for image analysis, that allows the extraction of a layer of signal from a 3D confocal stack relative to it's surface.

The macro has two modes: the first one, called “Calibrate” is to be used in order to manually find the proper settings for the signal layer extraction, but can also be used to process samples manually one by one. The second one called “Batch” can then be used to run batch signal layer extraction on series of equivalent Z-stacks, using appropriate parameters as determined with the “Calibrate” mode.

## How it works
In this macro the signal layer extraction is done using a succession of classical ImageJ functions. The first slice of the stack should be the top of the sample in order for the process to work properly. The stack is first converted to 8-bit. De-noising of the raw signal is then performed using the “Gaussian Blur” function. The signal is then binarized using the “Threshold” function. An equivalent of an “edge detect” function is preformed by successive projection of the upper slices in the stack. This creates a new stack in which the first slice (top of the stack), is simply the first slice, the second slice is a projection of the first and second slice, the third slice is a projection of the first to the third slice, etc… This new stack is then used as a mask shifted in the Z direction, to subtract the signal from the original stack above and below the chosen values depending on the desired depth of signal extraction. The cropped stack is finally maximal intensity Z-projected in order to obtain a 2D image. The values for each of the functions used are to be determined with the Calibrate mode.

Note that while SurfCut is easy to use, automatized and overall an efficient way to obtain signal layer extraction, it is in principle only adequate for sample with a relatively simple geometry.

## Prerequists:
- Fiji (https://fiji.sc).
- The "SurfCut.ijm" macro file.
- Data: 3D confocal stacks in .tif format, in which the top of the stack should also be the top of the sample. 

## Install/run:
1) Download the "SurfCut.ijm" macro file somewhere on your computer (You can put it in the Fiji "macros" folder for exemple)
2) Start Fiji.
3) In Fiji, run the macro: Plugins>Macros>Run…, and then select the “SurfCut.ijm” file.
4) Then follow the instructions step by step. You can also follow the step by step user guide (https://github.com/sverger/SurfCut/SurfCut_UserGuide.pdf

## Output:
The macro can output 4 types of files:
- The SurfCut output stack: a 3D stack of the layer of signal that has been extracted by the macro.
- The SurfCut output Projection: A max-intensity Z projection of the SurfCut output stack.
- The original projection: A max-intensity Z projection of the original stack for comparison.
- The parameter file: A .txt file of the parameters that have been used to analyse the image as well as a log of the images that have been processed.