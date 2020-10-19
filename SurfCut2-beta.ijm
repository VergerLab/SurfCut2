///======================MACRO=========================///
macro_name = "SurfCut2.0";
///====================================================///
///File author(s): Stéphane Verger======================///

///====================Description=====================///
/*This macro allows the extraction of a layer of signal
 * in a 3D stack at a distance from the surface of the 
 * object in the stack (see doi.org/10.1186/s12915-019-0657-1)
 * This is an update and full reimplementation of the
 * original SurfCut Macro, (https://github.com/sverger/SurfCut)
 * with some added functionalities, bug correction and 
 * refactoring of the code.
*/
macro_source = "https://github.com/VergerLab/SurfCut2";

///====Action Tool Icon================================///
macro "SurfCut2 Action Tool - C000 T0e10S T6e10C Tee102" {

///====================================================///
///=====Global variables===============================///
///====================================================///

///====Various=========================================///
var Mode;
var More;
var ParamMode;
var SurfaceSatified;
var CuttingSatisfied;

///====Image Name======================================///
var imgDir;
var imgName;
var imgPath;
var imgNameNoExt;

///====Parameters======================================///
var Rad;
var AutoThld;
var AutoThldType;
var AutoThldlower;
var Thld;
var CuttingMethod;
var Cut1;
var Cut2;
var TargetSignal;
var TargetChannelSuffix;
var OriginalChannelSuffix;
var Suffix;

///====Edge-Detect=====================================///
var slices;

///====StackOfCuts=====================================///
var StackOfCuts;
var from;
var to;
var thickness;
var overlay;

///====Saving==========================================///
var SaveStackOfCuts;
var	SaveSCP;
var	SaveSCS;
var	SaveOP;
var	SaveParam;
var SaveFinalLog;

///====================================================///
///=====Macro==========================================///
///====================================================///

///====Start===========================================///
print("\\Clear");
do{ //Do...while loop over the whole macro to process multiple images one-by-one or run a batch processing right after a calibation
Dia_SurfCut_Start(); //Dialog to choose between "Calibrate" and "Batch" mode
if (Mode=="Calibrate"){

///====Calibrate Mode==================================///
	print("=== SurfCut Calibrate mode ===");
	
	OpenSingleImage(); //Open single image for calibrate process
	GetImageName(); //Get image name and path
	SurfImgName = imgName; //Stores the name of the image used for surface detection in "SurfImgName"
	ProcessingInfo(); //Print info in log (name, path, date, time). Saved at the end for record keeping of the image processing session
	File.makeDirectory(imgDir+File.separator+"SurfCutCalibrate"); //Create a directory to save SurfCut Calibrate output
	
	///Surface detection parameters selection
	do{
		Dia_SurfaceDetection_Parameters(); //Dialog to define which parameters to use for surface detection
		
		setBatchMode(true);
		
		run("Duplicate...", "title=Binary duplicate"); //Duplicate the original image to work on the copy
		Preprocessing(); //8-bit conversion
		Denoising(Rad); //Gaussian blur with input Radius (Rad)
		Thresholding(); //Binarisation by manual or automatic threshold
		
		ThreeD_Viewer("Binary"); //Visualisation of output in the 3D Viewer
		Dia_SurfaceDetection_Satisfied(); //Dialog to validate quality of the output or return to parameters selection
		call("ij3d.ImageJ3DViewer.close"); //Close 3D viewer
		
		//If the surface detection is bad, closes processed stack and returns to parameters selection 
		if (SurfaceSatified == false){
			selectWindow("Binary");
			close();
		};
	} while (SurfaceSatified == false);
	//If the surface detection is good, closes original image and continues with processed stack
	close(imgName);

	///"Edge detect"-like binary signal projection.
	setBatchMode(true);
	EdgeDetection("Binary"); //Makes a filled binary object from the simple binary stack generated above

	///Cutting parameters selection
	do{
		
		imgName = SurfImgName; //Reset "imgName" to the original name of the image used for surface detection
		imgPath = imgDir + imgName; //Reset "imgPath". Useful when the following "Cutting" process is run multiple time with a different target signal
		
		Dia_Cutting_Parameters(); //Dialog to define which parameters to use for signal cutting
		setBatchMode(true);

		//If cutting a different channel, define name
		if (TargetSignal=="Other channel"){
			Dia_TargetChannel();
		};
		
		//"Stack Of Cuts" depth parameter scanning
		if (StackOfCuts == true){
			Dia_StackOfCuts_Parameters(); //Dialog to define which parameters to use for this parameter scanning
			StacKOfCuts(); //Generates a series of Surfcut output at successive depths to help choose the most appropriate
			Dia_StackOfCuts_Satisfied(); //Dialog to pause, examine which depth parameters are appropriate, save the "StackOfCuts" and/or return to parameters selection
			
			//Save and close the "StackOfCuts"
			if (SaveStackOfCuts == true){
				StackOfCutsName = "StackOfCuts_" + from + "-" + to + "-" + thickness + "_" + Rad + "-" + AutoThld + "-" + AutoThldlower + "-" + Thld + "_" + CuttingMethod + "_" + imgName;
				saveAs("Tiff", imgDir + File.separator + "SurfCutCalibrate" + File.separator + StackOfCutsName);
				close(StackOfCutsName);
			} else {
				close("StackOfCuts"); //Close the "StackOfCuts"
			};
			
		} else {
			//Directly generate a single Surfcut output with the input parameters
			Cutting(Cut1, Cut2); //Creates layer mask, crop target signal and Z-project the SurfCut output
			OriginalZProjections(); //Z-project the original image to compare with SurfCut output
			run("Tile");
			Dia_Cutting_Satisfied(); //Dialog to validate quality of the output or return to parameters selection
			SaveOutputAndClose(); //Save and close the different outputs of the process
		};
		
	} while (CuttingSatisfied == false);
	
	//Close the output of "EdgeDetection" 
	close("Mask-0-invert");
	close("Mask-0");

	///End of calibrate mode
	print("=== Calibration Done ===");

} else {
	
///====Batch Mode======================================///
	print("=== SurfCut Batch mode ===");

	///Batch processing directory selection
	imgDir = getDirectory("Choose a directory"); //Choose directory for batch process
	File.makeDirectory(imgDir + File.separator + "SurfCutResult"); //Create a directory to save SurfCut Batch output

	///SurfCut parameters selection
	Dia_Loading_Parameters(); //Dialog ask to load parameter file or enter parameters manually
	if (ParamMode=="Parameter file"){
		Loading_Parameters(); //Load parameters
	} else {
		print("-> Manual parameters");
	};
	Dia_BatchSurfCut_Parameters(); //Shows dialog with loaded or to be entered parameters
	
	setBatchMode(true);
	
	///Batch processing for loop on .tif files in the folder
	list = getFileList(imgDir); //Gets the list of files in the folder to be analyzed in batch 
	for (j=0; j<list.length; j++){ 
		if (TargetSignal=="Same"){
			if(endsWith (list[j], ".tif")){
				open(imgDir+File.separator+list[j]); //Open .tif images in the folder
			};
		} else if (TargetSignal=="Other channel"){
			if (endsWith (list[j], OriginalChannelSuffix + ".tif")){
				open(imgDir+File.separator+list[j]); //Open only .tif images of the specified channel for surface detection
			};
		};
		if (isOpen(list[j])){	
			GetImageName(); //Get image name and path
			SurfImgName = imgName; //Stores the name of the image used for surface detection in "SurfImgName"
			ProcessingInfo(); //Print info in log (name, path, date, time). Saved at the end for record keeping of the image processing session
			Preprocessing(); //8-bit conversion
			Denoising(Rad); //Gaussian blur with input Radius (Rad)
			Thresholding(); //Binarisation by manual (fixed) or automatic (variable) threshold
			EdgeDetection(list[j]); //"Edge detect"-like binary signal projection.
			Cutting(Cut1, Cut2); //Creates layer mask, crop target signal and Z-project the SurfCut output
			OriginalZProjections(); //Z-project the original image to compare with SurfCut output
			SaveOutputAndClose(); //Save and close the different outputs of the process
			//Close the output of "EdgeDetection" 
			close("Mask-0-invert");
			close("Mask-0");
		};
	};
	///End of Batch mode
	print("=== Batch processing Done ===");
};

///====End=============================================///
/// Dialog asking to process other images with SurfCut
Dia_SurfCut_More();
} while (More=="Yes");

///Save the final log?
Dia_SaveFinalLog();
selectWindow("Log");
if (SaveFinalLog){
	LodDir = getDirectory("Choose a directory"); //Choose a directory to save the log file
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	LogPath = LodDir + File.separator + "SurfCut_SessionLog_" + year + "-" + month + "-" + dayOfMonth + "_" + hour +":"+minute + ".txt";
	saveAs("text", LogPath);
};

///End of SurfCut macro
print("===== Done =====");

///====================================================///
///=====Functions======================================///
///====================================================///

///====Dialogs=========================================///

function Dia_SurfCut_Start(){
	Dialog.create("SurfCut");
	Dialog.addMessage("Choose between Calibrate and Batch mode");
	Dialog.addChoice("Mode", newArray("Calibrate", "Batch"));
	Dialog.show();
	Mode = Dialog.getChoice();
};

function Dia_SurfCut_More(){
	Dialog.create("More?");
	Dialog.addMessage("Do you want to process other images with SurfCut?");
	Dialog.addChoice("More", newArray("Yes", "No, I'm done"));
	Dialog.show();
	More = Dialog.getChoice();
};

function Dia_SurfaceDetection_Parameters(){
	Dialog.create("SurfCut Parameters");
	Dialog.addMessage("1) Choose Gaussian blur radius");
	Dialog.addNumber("Radius\t", 3);
	Dialog.addCheckbox("2) Automatic  Threshold", AutoThld);
	Dialog.addMessage("Define Automatic thresholding");
	Dialog.addChoice("method", newArray("Default", "Huang", "Otsu", "Intermodes", "IsoData", "Li", "None"), AutoThldType);
	Dialog.addMessage("Or");
	Dialog.addMessage("2) Choose the intensity threshold\nfor surface detection\n(Between 0 and 255)");
	Dialog.addNumber("Threshold\t", Thld);
	Dialog.show();
	Rad = Dialog.getNumber();
	AutoThld = Dialog.getCheckbox();
	AutoThldType = Dialog.getChoice();
	Thld = Dialog.getNumber();
};

function Dia_Cutting_Parameters(){
	Dialog.create("SurfCut Cutting Parameters");
	Dialog.addMessage("3) Cutting method");
	Dialog.addChoice("", newArray("Z-Shift", "erode"), CuttingMethod);
	Dialog.addMessage("'Z-Shift' is the classical method\nin which the mask is simply shifted\nin the Z direction. In 'erode' the cut\nwill follow perpandicular to the surface\nbut the process takes more time");
	Dialog.addMessage(" ");
	Dialog.addMessage("4) Cutting depth parameters");
	Dialog.addCheckbox("Scan different depth?", StackOfCuts);
	Dialog.addMessage("This will generate a new stack of\ncuttings from the surface to help\nyou choose which depth parameter\nis adequate below");
	Dialog.addMessage("Or");
	Dialog.addMessage("Choose the depths between which\nthe stack will be cut relative to the\ndetected surface in voxels for\nerode or number of slices for Z-Shift");
	Dialog.addNumber("Top\t", Cut1);
	Dialog.addNumber("Bottom\t", Cut2);
	Dialog.addMessage(" ");
	Dialog.addMessage("5) Target signal to be cropped");
	Dialog.addChoice("", newArray("Same", "Other channel"), TargetSignal);
	Dialog.show();
	CuttingMethod = Dialog.getChoice();
	StackOfCuts = Dialog.getCheckbox();
	Cut1 = Dialog.getNumber();
	Cut2 = Dialog.getNumber();
	TargetSignal = Dialog.getChoice();
};

function Dia_StackOfCuts_Parameters(){
	Dialog.create("Stack_of_crop");
	Dialog.addMessage("Start depth");
	Dialog.addNumber("Top\t", 0);
	Dialog.addMessage("End depth");
	Dialog.addNumber("Bottom\t", slices-1);
	Dialog.addMessage("Thickness");
	Dialog.addNumber("Thickness\t", 1);
	Dialog.addCheckbox("Add text overlay to\ndisplay cutting depths?", true);
	Dialog.show();
	from = Dialog.getNumber();
	to = Dialog.getNumber();
	thickness = Dialog.getNumber();
	overlay = Dialog.getCheckbox();
};

function Dia_Loading_Parameters(){
	Dialog.create("Load Parameter file?");
	Dialog.addMessage("Choose between loading a parameter file\nform a calibration previously done,\nor manually enter the parameters.");
	Dialog.addChoice("Parameter mode", newArray("Parameter file", "Manual"));
	Dialog.show();
	ParamMode = Dialog.getChoice();
};

function Dia_BatchSurfCut_Parameters(){
	Dialog.create("SurfCut Parameters");
	Dialog.addMessage("1) Choose Gaussian blur radius");
	Dialog.addNumber("Radius\t", Rad);
	Dialog.addCheckbox("2) Automatic (variable) Threshold", AutoThld);
	Dialog.addMessage("Define Automatic thresholding");
	Dialog.addChoice("method", newArray("Default", "Huang", "Otsu", "Intermodes", "IsoData", "Li", "None"), AutoThldType);
	Dialog.addMessage("Or");
	Dialog.addMessage("2) Choose a fixed intensity threshold\nfor surface detection\n(Between 0 and 255)");
	Dialog.addNumber("Threshold\t", Thld);
	Dialog.addMessage("3) Cutting method");
	Dialog.addChoice("", newArray("Z-Shift", "erode"), CuttingMethod);
	Dialog.addMessage("4) Cutting depth parameters");
	Dialog.addNumber("Top\t", Cut1);
	Dialog.addNumber("Bottom\t", Cut2);
	Dialog.addMessage("5) Target signal to be cropped");
	Dialog.addChoice("", newArray("Same", "Other channel"), TargetSignal);
	Dialog.addString("Original channel suffix", OriginalChannelSuffix);
	Dialog.addString("Target channel suffix", TargetChannelSuffix);
	Dialog.addMessage("6) Suffix added to saved file");
    Dialog.addString("Suffix", Suffix);
	Dialog.addCheckbox("Save SurfCut projections?", true);
	Dialog.addCheckbox("Save SurfCut stacks?", false);
	Dialog.addCheckbox("Save original projections?", false);
	Dialog.addCheckbox("Save parameter files?", true);
	Dialog.show();
	Rad = Dialog.getNumber();
	AutoThld = Dialog.getCheckbox();
	AutoThldType = Dialog.getChoice();
	Thld = Dialog.getNumber();
	CuttingMethod = Dialog.getChoice();
	Cut1 = Dialog.getNumber();
	Cut2 = Dialog.getNumber();
	TargetSignal = Dialog.getChoice();
	OriginalChannelSuffix = Dialog.getString();
	TargetChannelSuffix = Dialog.getString();
	Suffix = Dialog.getString();
	SaveSCP = Dialog.getCheckbox();
	SaveSCS = Dialog.getCheckbox();
	SaveOP = Dialog.getCheckbox();
	SaveParam = Dialog.getCheckbox();
};

function Dia_TargetChannel(){
	Dialog.create("Define name for target channel");
	Dialog.addMessage("Current image name (used for surface detection) is:");
	Dialog.addMessage(SurfImgName);
	Dialog.addMessage("Current channel suffix: " + substring(SurfImgName,lastIndexOf(SurfImgName, "C="), indexOf(SurfImgName, ".tif")));
	Dialog.addString("Enter suffix for target channel ", "C=");
	Dialog.show();
	TargetChannelSuffix = Dialog.getString();
	OriginalChannelSuffix = substring(SurfImgName,lastIndexOf(SurfImgName, "C="), indexOf(SurfImgName, ".tif"));
};

function Dia_SurfaceDetection_Satisfied(){
	waitForUser("Check Sample binarization", "Check If the surface of the samples is properly detected\nThen click OK.");
	Dialog.create("Satisfied with surface detection?");
	Dialog.addMessage("If you are not satisfied, do not tick the box and just click Ok.\nThis will take you back to the previous step.\nOtherwise tick the box and click OK to proceed to the next step.");
	Dialog.addCheckbox("Satisfied?", false);
	Dialog.show();
	SurfaceSatified = Dialog.getCheckbox();
};

function Dia_StackOfCuts_Satisfied(){
	setBatchMode("exit and display");
	waitForUser("Check the stack created", "From this stack, you can determine the depths of cut that will be appropriate\nfor the cutting in your samples. See number at the top left corner.\nThen click OK.");
	Dialog.create("Satisfied with the output?");
	Dialog.addCheckbox("Save stack of cuts?", false);
	Dialog.addCheckbox("Done?", false);
	Dialog.addMessage("Or go back to previous step\nto specify cutting parameters?");
	Dialog.show();
	SaveStackOfCuts = Dialog.getCheckbox();
	CuttingSatisfied = Dialog.getCheckbox();
};

function Dia_Cutting_Satisfied(){
	setBatchMode("exit and display");
	Dialog.create("Satisfied with the output?");
	Dialog.addCheckbox("Satisfied?", false);
	Dialog.addMessage("");
	Dialog.addMessage("6) Suffix added to saved file");
    Dialog.addString("Suffix", "L1_cells");
	Dialog.addCheckbox("Save SurfCut projection?", false);
	Dialog.addCheckbox("Save SurfCut stack?", false);
	Dialog.addCheckbox("Save original projection?", false);
	Dialog.addCheckbox("Save parameter file?", false);
	Dialog.show();
	CuttingSatisfied = Dialog.getCheckbox();
	Suffix = Dialog.getString();
	SaveSCP = Dialog.getCheckbox();
	SaveSCS = Dialog.getCheckbox();
	SaveOP = Dialog.getCheckbox();
	SaveParam = Dialog.getCheckbox();
};

function Dia_SaveFinalLog(){
	Dialog.create("Save final Log of this SurfCut session?");
	Dialog.addMessage("Save final Log of this SurfCut session?\nIt can be useful to keep it as record of your image processing experiment.");
	Dialog.addCheckbox("Save session log?", true);
	Dialog.show();
	SaveFinalLog = Dialog.getCheckbox();
};

///====Tools===========================================///

function OpenSingleImage(){
	open();
	imgDir = File.directory;
};

function GetImageName(){
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

function ThreeD_Viewer(ThreeDstack){
	setBatchMode("exit and display");
	run("3D Viewer");
	call("ij3d.ImageJ3DViewer.setCoordinateSystem", "false");
	call("ij3d.ImageJ3DViewer.add", ThreeDstack, "None", ThreeDstack, "0", "true", "true", "true", "2", "0");
};

function Cutting(Cut1, Cut2){
	if (CuttingMethod=="erode"){
		Erosion(Cut1, Cut2);
	} else if (CuttingMethod=="Z-shift"){
		ZAxisShifting(Cut1, Cut2); 
	};
	//Define target signal
	if (TargetSignal=="Same"){
		open(imgPath);
	} else if (TargetSignal=="Other channel"){
		imgNameNoChannel = substring(imgNameNoExt, 0, lastIndexOf(imgNameNoExt, "C="));
		imgPathTargetChannel = imgDir + imgNameNoChannel + TargetChannelSuffix + ".tif";
		print("Target image: " + imgPathTargetChannel);
		open(imgPathTargetChannel);
		GetImageName();
	};
	//Cropping target signel with newly created mask
	StackCropping();
	//Z Project cutting output
	SurfCutZProjections();
};

function StacKOfCuts(){
	//for loop to scan depth parameters
	print ("Stack of Cuts: From " + from + " to " + to + " with " + thickness + "thickness");
	for (cutx=from; cutx<to; cutx++){
		cuty = cutx + thickness;
		print(cutx+1 + "/" + to);
		//Define cutting method
		Cutting(cutx, cuty);
		close(imgName);
		close("SurfCutStack_" + imgName);
		if (overlay==true){
			text = ""+ cutx + " - " + cuty + "";
			setFont("SansSerif", 28, " antialiased");
			makeText(text, 10, 20);
			run("Add Selection...", "stroke=white new");
		};
	};
	run("Images to Stack", "name=StackOfCuts");
};

function SaveOutputAndClose(){
	print("Saving output");
	//Saving path (variable) 
	if (Mode == "Calibrate"){
		outPath = File.separator + "SurfCutCalibrate" + File.separator;
	} else {
		outPath = File.separator + "SurfCutResult" + File.separator;
	};
	//Output name with suffix (variable)
	ParamSummary = "_SC-" + Rad + "-" + AutoThld + "-" + AutoThldType + "-" + AutoThldlower + "-" + Thld + "-" + Cut1 + "-" + Cut2 + "_" + CuttingMethod + "_" + Suffix;
	SCProjName = "SurfCutProjection_" + imgNameNoExt + ParamSummary + ".tif";
	SCStackName = "SurfCutStack_" + imgNameNoExt + ParamSummary + ".tif";
	OProjName = "OriginalProjection_" + imgName;
	SCParamName = "ParameterFile_" + imgNameNoExt + ParamSummary + ".txt";

	//Save SurfCut Projection
	selectWindow("SurfCutProjection_" + imgName);
	rename(SCProjName);
	if (SaveSCP){
		print("Save SurfCut Projection"); 
		saveAs("Tiff", imgDir + outPath + SCProjName);
	};
	close(SCProjName);

	//Save SurfCut Stack
	selectWindow("SurfCutStack_" + imgName);
	rename(SCStackName);
	if (SaveSCS){
		print("Save SurfCutProj"); 
		saveAs("Tiff", imgDir + outPath + SCStackName);
	};
	close(SCStackName);
	
	//Save original projection
	selectWindow("OriginalProjection_" + imgName);
	rename(OProjName);
	if (SaveOP){
		print("Save OriginalProj");
		saveAs("Tiff", imgDir + outPath + OProjName);
	};
	close(OProjName);
	close(imgName);
	
	//Save SurfCut Parameter File
    if (SaveParam){
		print("Save Parameters");
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		f = File.open(imgDir + outPath + SCParamName);
		print(f, "Parameters used for:\t" + SCProjName);
		print(f, "Radius\t" + Rad);
		print(f, "AutoThld\t" + AutoThld);
		print(f, "AutoThld Type\t" + AutoThldType);
		print(f, "AutoThld value\t" + AutoThldlower);
		print(f, "ManualThld value\t" + Thld);
		print(f, "Top\t" + Cut1);
		print(f, "Bottom\t" + Cut2);
		print(f, "Cutting Method\t" + CuttingMethod);
		print(f, "Target Signal\t" + TargetSignal);
		print(f, "Original image channel suffix\t" + OriginalChannelSuffix);
		print(f, "Target image channel suffix\t" + TargetChannelSuffix);
		print(f, "Suffix\t" + Suffix);
		print(f, "Time stamp\t" + hour+":"+minute+":"+second+" "+dayOfMonth+"/"+month+"/"+year);
		print(f, "Image used for surface detection\t" + SurfImgName);
		print(f, "Image used for signal cropping\t" + imgName);
		File.close(f);
	};
};

function Loading_Parameters(){
	print("-> Loading parameter file");
	///Retrieve parameter text file values
	pathfile=File.openDialog("Choose the Parameter file to use"); 
	filestring=File.openAsString(pathfile); 
	print(filestring);
	rows=split(filestring, "\n"); 
	x=newArray(rows.length); 
	y=newArray(rows.length); 
	for(i=0; i<rows.length; i++){ 
		columns=split(rows[i],"\t"); 
		x[i]=parseFloat(columns[1]);
		y[i]=columns[1]; 
	};
	Rad = x[1];
	AutoThld = x[2];
	AutoThldType = y[3];
	AutoThldlower = x[4];
	Thld = x[5];
	Cut1 = x[6];
	Cut2 = x[7];
	CuttingMethod = y[8];
	TargetSignal = y[9];
	OriginalChannelSuffix = y[10];
	TargetChannelSuffix = y[11];
	Suffix = y[12];
};

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
	print ("Threshold segmentation");
	if (AutoThld == true){
		Thld = 0; //Reset manually defined Thld value to 0
		setAutoThreshold(AutoThldType + " dark no-reset stack");
		getThreshold(AutoThldlower, upper);
		print ("Auto threshold type " + AutoThldType);
		print ("Auto threshold value " + AutoThldlower);
		run("Convert to Mask", "method=" + AutoThldType + " background=Dark black");
	}else{
		print ("Manually defined threshold value " + Thld);
		AutoThldType = "None"; //Reset auto thld type to "None"
		AutoThldlower = 0; //Reset auto Thld value to 0
		setThreshold(Thld, 255);
		run("Convert to Mask", "method=Default background=Dark black");
	};
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

function Erosion(Cut1, Cut2){
	print ("Layer mask creation - Erosion - " + Cut1 + "-" + Cut2);
	Ero1 = Cut1;
	Ero2 = Cut2-Cut1;
	
	//Erosion 1
	selectWindow("Mask-0");
	run("Duplicate...", "title=Mask-0-Ero1 duplicate");
	print("    Erosion1");
	print("    " + Ero1 + " erosion steps");
	print("        Erode1 ");
	for (erode1=0; erode1<Ero1; erode1++){ 
		print("\\Update:" + "        Erode1 " + erode1+1 + "/" + Ero1);
		run("Erode (3D)", "iso=255");
	};
	//Erosion 2 (here instead of restarting from the original mask, the eroded mask is duplictaed and further eroded. In this case Ero2 corresponds
	//to the number of additional steps of erosion, or the thickness of the future layer mask)
	selectWindow("Mask-0-Ero1");
	run("Duplicate...", "title=Mask-0-Ero2 duplicate");
	print("    Erosion2");
	print("    " + Ero2 + " additional erosion steps");
	print("        Erode2 ");
	for (erode2=0; erode2<Ero2; erode2++){ 
		print("\\Update:" + "        Erode2 " + erode2+1 + "/" + Ero2);
		run("Erode (3D)", "iso=255");
	};	
	selectWindow("Mask-0-Ero1");
	run("Invert", "stack");
	//Subtract both shifted masks to create a layer mask
	imageCalculator("Add create stack", "Mask-0-Ero1","Mask-0-Ero2");
	close("Mask-0-Ero1");
	close("Mask-0-Ero2");
	selectWindow("Result of Mask-0-Ero1");
	rename("Layer Mask");
	//Close eroded masks ("Mask-0-Ero1" and "Mask-0-Ero2"), but keeps the layer mask ("Layer Mask")
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
};
