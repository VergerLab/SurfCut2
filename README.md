# SurfCut2 (Beta)

File author(s): Stéphane Verger stephane.verger@slu.se

Updated version of SurfCut.
https://github.com/sverger/SurfCut

You can try a lite version of SurfCut (SurfCut2-Lite.ijm) with a test image following this link:
https://tinyurl.com/y5rn7kou

## Why SurfCut2?
- The code has been completely re-written to fix bugs, make it more robust and re-usable.
- Most processes have been refactored into user-defined functions.
- New features have been added!

## New features
- Two channels: Detect the surface with one channel (e.g. membrane), crop the signal of a second channel (e.g. Microtubules, nucleus,...).
- Erode: erode the mask of the detected surface instead of Z-axis shift. This allows to crop the signal perpandicular to the surface rather than simply shifting down in Z.
- Auto threshold: You can use an automatic thresholding method (e.g. Ostu, Huang,...) instead of manually choosing a fixed threshold for surface detection.
- Stack of cuts: In the calibrate mode, you can select this mode to generat a series of cropping of the signal a successive depths. You can then easily see which depth parameters are the most adapted by looking through the newly generated "stack of cuts" or simply save and use this new stack containing a virtually flattened version of the original signal.

## What esle is changed?
- Many of the bugs were related to the treamtent of the image and processes with values in micron. This is now gone, and everything is treated as voxels or slices. This mainly affect the depth value used to crop the stack.
- At the end of the "calibrate" mode, you can now save any of the output, and still go back to the previous step (Cropping parameters selection). This allow to save the setting and image for a first cropping depth, then go back and try a different depth, without having to restart the process from the begining. This is useful when you need to extract two different part of the stack.


The userguide will be updated.


# How to cite
The publication
> Erguvan, O., Louveaux, M., Hamant, O., Verger, S. (2019) ImageJ SurfCut: a user-friendly pipeline for high-throughput extraction of cell contours from 3D image stacks. BMC Biology, 17:38. https://doi.org/10.1186/s12915-019-0657-1 

The software


The data
> Erguvan Özer, & Verger Stéphane. (2019). Dataset of confocal microscopy stacks from plant samples - ImageJ SurfCut: a user-friendly, high-throughput pipeline for extracting cell contours from 3D confocal stacks [Data set]. Zenodo. http://doi.org/10.5281/zenodo.2577053

## Description
SurfCut is an ImageJ macro for image analysis, that allows the extraction of a layer of signal from a 3D confocal stack relative to the detected surface of the signal. This can for example be used to extract the cell contours of the epidermal layer of cells.

![Alt text](/surfcut_illustration.png?raw=true)
The macro has two modes: the first one, called “Calibrate” is to be used in order to manually find the proper settings for the signal layer extraction, but can also be used to process samples manually one by one. The second one called “Batch” can then be used to run batch signal layer extraction on series of equivalent Z-stacks, using appropriate parameters as determined with the “Calibrate” mode.

## How it works
In this macro the signal layer extraction is done using a succession of classical ImageJ functions. The first slice of the stack should be the top of the sample in order for the process to work properly. The stack is first converted to 8-bit. De-noising of the raw signal is then performed using the “Gaussian Blur” function. The signal is then binarized using the “Threshold” function. An equivalent of an “edge detect” function is preformed by successive projection of the upper slices in the stack. This creates a new stack in which the first slice (top of the stack), is simply the first slice, the second slice is a projection of the first and second slice, the third slice is a projection of the first to the third slice, etc… This new stack is then used as a mask shifted in the Z direction, to subtract the signal from the original stack above and below the chosen values depending on the desired depth of signal extraction. The cropped stack is finally maximal intensity Z-projected in order to obtain a 2D image. The values for each of the functions used are to be determined with the Calibrate mode.

Note that while SurfCut is easy to use, automatized and overall an efficient way to obtain signal layer extraction, it is in principle only adequate for sample with a relatively simple geometry.

## Prerequisites:
- Fiji (https://fiji.sc).
- The "SurfCut2.ijm" macro file.
- Data: 3D confocal stacks in .tif format, in which the top of the stack should also be the top of the sample. Single channel images, and in the case of 2 channel process (detect surface with one channel and crop a second channel), channels must be splited and have a distinctive suffix like C=0 or C=1. Example files are available in the /test_File folder as well as on the Zenodo data repository https://doi.org/10.5281/zenodo.2577053
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.2577053.svg)](https://doi.org/10.5281/zenodo.2577053)

## Install/run:
1) Download the "SurfCut2.ijm" macro file somewhere on your computer (You can put it in the Fiji "macros" folder for example)
2) Start Fiji.
3) In Fiji, run the macro: Plugins>Macros>Run…, and then select the “SurfCut2.ijm” file.
4) Then follow the instructions step by step. You can also follow the step by step user guide (https://github.com/sverger/SurfCut/blob/master/SurfCut_UserGuide.pdf)

## Output:
The macro can output 4 types of files:
- The SurfCut output stack: a 3D stack of the layer of signal that has been extracted by the macro.
- The SurfCut output Projection: A max-intensity Z projection of the SurfCut output stack.
- The original projection: A max-intensity Z projection of the original stack for comparison.
- The parameter file: A .txt file of the parameters that have been used to analyse the image as well as a log of the images that have been processed.
