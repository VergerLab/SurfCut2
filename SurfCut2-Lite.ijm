///======================MACRO=========================///
macro_name = "SurfCut2Lite";
///====================================================///
///File author(s): Stéphane Verger======================///

///====================Description=====================///
/* This macro allows the extraction of a layer of signal
 * in a 3D stack at a distance from the surface of the 
 * object in the stack (see doi.org/10.1186/s12915-019-0657-1)
 * This is a light version of SurfCut (https://github.com/sverger/SurfCut) 
 * meant to be run on the web browser based version of 
 * imageJ (https://ij.imjoy.io/.
 * 
 * To run, first open a stack, then run the macro.
*/
macro_source = "https://github.com/VergerLab/SurfCut2";

///====================================================///
///=====Global variables===============================///
///====================================================///

///====Image Name======================================///
var imgDir;
var imgName;
var imgPath;
var imgNameNoExt;

///====Parameters======================================///
var Rad;
var Thld;
var Cut1;
var Cut2;

///====Edge-Detect=====================================///
var slices;


///====================================================///
///=====Macro==========================================///
///====================================================///

///====Start===========================================///
print("\\Clear");
print("=== SurfCut2Lite ===");

///SurfCut parameters selection
Dia_BatchSurfCut_Parameters(); //Shows dialog with parameters to be entered
	
setBatchMode(true);
	
///Surfcut workflow
GetImageName(); //Get image name and path
ProcessingInfo(); //Print info in log (name, path, date, time). Saved at the end for record keeping of the image processing session
Preprocessing(); //8-bit conversion
Denoising(Rad); //Gaussian blur with input Radius (Rad)
Thresholding(); //Binarisation by manual (fixed) or automatic (variable) threshold
EdgeDetection(imgName); //"Edge detect"-like binary signal projection.
ZAxisShifting(Cut1, Cut2); //Creates layer mask from the binarized surface signal
open(imgPath); //Open signal to be cropped
StackCropping(); //Cropping target signel with newly created mask
SurfCutZProjections(); //Z Project cutting output
OriginalZProjections(); //Z-project the original image to compare with SurfCut output

//Close the output of "EdgeDetection" 
close("Mask-0-invert");
close("Mask-0");
setBatchMode("exit and display");

///====End=============================================///
print("===== Done =====");

///====================================================///
///=====Functions======================================///
///====================================================///

///====Dialogs=========================================///

function Dia_BatchSurfCut_Parameters(){
	Dialog.create("SurfCut Parameters");
	Dialog.addMessage("1) Choose Gaussian blur radius");
	Dialog.addNumber("Radius\t", 3);
	Dialog.addMessage("2) Choose an intensity threshold\nfor surface detection\n(Between 0 and 255)");
	Dialog.addNumber("Threshold\t", 80);
	Dialog.addMessage("3) Cutting depth parameters");
	Dialog.addNumber("Top\t", 10);
	Dialog.addNumber("Bottom\t", 11);
	Dialog.show();
	Rad = Dialog.getNumber();
	Thld = Dialog.getNumber();
	Cut1 = Dialog.getNumber();
	Cut2 = Dialog.getNumber();
};

///====Tools===========================================///

function GetImageName(){
	imgDir = File.directory;
	imgName = getTitle();
	imgPath = imgDir+imgName;
	imgNameNoExt = File.nameWithoutExtension();
};

function ProcessingInfo(){
	print("\n-> Processing: " + imgName);
	print("Image path: " + imgPath);
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print("Date: " + year + "/" + month + "/" + dayOfMonth);
	print("Time: " + hour + ":" + minute + ":" + second);
}

///====Workflow components=============================///

function Preprocessing(){
	//8-bit conversion to ensure correct format for next steps
	print ("Pre-processing");
	run("8-bit");
};

function Denoising(Rad){
	//Gaussian blur (uses the variable "Rad" to define the sigma of the gaussian blur)
	print ("Gaussian Blur");	
	run("Gaussian Blur...", "sigma=&Rad stack");	
};

function Thresholding(){
	//Object segmentation (uses the variable Thld or auto thresholding to define the threshold applied)
	print ("Threshold segmentation" + Thld);
	setThreshold(Thld, 255);
	run("Convert to Mask", "method=Default background=Dark black");
};

function EdgeDetection(Name){
	print ("Edge detect");
	//Get the dimensions of the image to know the number of slices in the stack and thus the number of loops to perform
	getDimensions(w, h, channels, slices, frames);
	print ("    " + slices + " slices in the stack");
	print ("Edge detect projection ");
	for (img=0; img<slices; img++){
		//Display progression in the log
		print("\\Update:" + "    Edge detect projection " + img+1 + "/" + slices);
		slice = img+1;
		selectWindow(Name);
		//Successively projects stacks with increasing slice range (1-1, 1-2, 1-3, 1-4,...)
		run("Z Project...", "stop=&slice projection=[Max Intensity]");
	};
	//Make a new stack from all the Z-projected images generated in the loop above
	run("Images to Stack", "name=Mask-0 title=[]");
	//Duplicate and invert
	run("Duplicate...", "title=Mask-0-invert duplicate");
	run("Invert", "stack");
	selectWindow(Name);
	close();
	//Close binarized image generated previously (Name), but keeps the image (mask) generated after the edge detect ("Mask-0") 
	//and an inverted version of this mask ("Mask-0-invert"). Both masks are used in the next steps to be shifted in Z-Axis and make a layer mask.
};

function ZAxisShifting(Cut1, Cut2){
	print ("Layer mask creation - Z-axis shift - " + Cut1 + "-" + Cut2);
	
	///First z-axis shift
	//Get dimension w and h, and pre-defined variable Cut1 depth to create an new "empty" stack
	selectWindow("Mask-0");
	getDimensions(w, h, channels, slices, frames);
	if (Cut1 == 0){
		selectWindow("Mask-0-invert");
		run("Duplicate...", "duplicate");
		rename("StackUpShifted");
	} else {
		newImage("AddUp", "8-bit white", w, h, Cut1);
		//Duplicate Mask-0-invert while removing bottom slices corresponding to the z-axis shift (Cut1 depth)
		Slice1 = slices - Cut1;
		selectWindow("Mask-0-invert");
		run("Duplicate...", "title=StackUpSub duplicate range=1-&Slice1");
		//Add newly created empty slices (AddUp) at begining of stackUpSub, thus recreating a stack with the original dimensions of the image and in whcih the binarized object is shifted in the Z-axis.
		run("Concatenate...", "  title=[StackUpShifted] image1=[AddUp] image2=[StackUpSub] image3=[-- None --]");
	};
	
	///Second z-axis shift
	//Use image dimension w and h from component3 and pre-defined variable Cut2 depth to create an new "empty" stack
	newImage("AddInv", "8-bit black", w, h, Cut2);
	//Duplicate Mask-0 while removing bottom slices corresponding to the z-axis shift (Cut2 depth)
	Slice2 = slices - Cut2;
	selectWindow("Mask-0");
	run("Duplicate...", "title=StackInvSub duplicate range=1-&Slice2");
	//Add newly created empty slices (AddInv) at begining of stackInvSub,
	run("Concatenate...", "  title=[StackInvShifted] image1=[AddInv] image2=[StackInvSub] image3=[-- None --]");
	
	///Subtract both shifted masks to create a layer mask
	imageCalculator("Add create stack", "StackUpShifted","StackInvShifted");
	close("StackUpShifted");
	close("StackInvShifted");
	selectWindow("Result of StackUpShifted");
	rename("Layer Mask");
	//Close shifted masks ("StackUpShifted" and "StackInvShifted"), but keeps the layer mask (renamed "Layer Mask")
	//resulting from the subtraction of the two shifted masks
};

function StackCropping(){
	print ("Cropping stack");
	//Open raw image
	selectWindow(imgName);
	run("Grays");
	//Apply mask to raw image
	imageCalculator("Subtract create stack", imgName, "Layer Mask");
	close("Layer Mask");
};

function SurfCutZProjections(){
	print ("SurfCut Z-Projections");
	selectWindow("Result of " + imgName);
	rename("SurfCutStack_" + imgName);
	run("Z Project...", "projection=[Max Intensity]");
	rename("SurfCutProjection_" + imgName);
};

function OriginalZProjections(){
	print ("Original Z-Projections");
	selectWindow(imgName);
	run("Z Project...", "projection=[Max Intensity]");
	rename("OriginalProjection_" + imgName);
};
