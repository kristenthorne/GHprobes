
# <span style="color:rgb(213,80,0)">Image Quantification Workflow</span>

This repository contains MATLAB scripts and functions for processing microscopy images stored in an <samp>imageDatastore</samp>. The workflow performs intensity\-based thresholding, binary mask generation, image quantification, and structured output storage.

<a name="beginToc"></a>

## Table of Contents
&emsp;[Features](#features)
 
&emsp;[System Requirements](#system-requirements)
 
&emsp;[Installation/Use](#installation-use)
 
&emsp;[Repository Structure](#repository-structure)
 
&emsp;[Functions](#functions)
 
&emsp;&emsp;&emsp;[Thresholding images with Otsu's Method](#thresholding-images-with-otsu-s-method)
 
&emsp;&emsp;&emsp;[Processing images in an ImageDatastore using the average threshold](#processing-images-in-an-imagedatastore-using-the-average-threshold)
 
&emsp;[Usage](#usage)
 
&emsp;&emsp;&emsp;[Create variables for relevant directories.](#create-variables-for-relevant-directories-)
 
&emsp;&emsp;&emsp;[Create an ImageDatastore from the image directory. Subfolders within the directory will be used as labels for subsequent analysis (Ex: mRuby3 vs mRuby3 BT0996 E240A)](#create-an-imagedatastore-from-the-image-directory-subfolders-within-the-directory-will-be-used-as-labels-for-subsequent-analysis-ex-mruby3-vs-mruby3-bt0996-e240a-)
 
&emsp;&emsp;&emsp;[Create an ImageDatastore subset with images of your label of interest (Ex: mRuby3 BT0996 E240A). These will be used to generate an average threshold.](#create-an-imagedatastore-subset-with-images-of-your-label-of-interest-ex-mruby3-bt0996-e240a-these-will-be-used-to-generate-an-average-threshold-)
 
&emsp;&emsp;&emsp;[Use the avgOtsu function to generate an average from the global thresholds for all subset images.](#use-the-avgotsu-function-to-generate-an-average-from-the-global-thresholds-for-all-subset-images-)
 
&emsp;&emsp;&emsp;[Use the processDSNorm function to analyze all images with the average threshold.](#use-the-processdsnorm-function-to-analyze-all-images-with-the-average-threshold-)
 
&emsp;&emsp;&emsp;[\[OPTIONAL\] Merge results table with image acquisition information](#-optional-merge-results-table-with-image-acquisition-information)
 
<a name="endToc"></a>

# Features
-  Load images from a datastore (<samp>imageDatastore</samp>). 
-  Apply **rescaling** and **fixed thresholding** (based on an average threshold). 
-  Generate **binary masks** for quantification. 
-  Extract image\-based measurements and save in a summary table: 
-   *Threshold value* 
-   *Area (pixels above threshold)*  
-   *Mean grey value, min/max, and standard deviation*  
-   *Integrated density and raw integrated density*  
-  Export processed images (original, scaled, and masked) as <samp>.tif</samp> files into subfolders grouped by **image label**. 
-  Optional \- Merge image metadata (shutter speed, exposure time, magnification) with computed results. 

# System Requirements
-  MATLAB R2024b 
-  This code was built on macOS (maca64) and tested using MATLAB R2024b 

# Installation/Use
1.  Clone the processDS repository to MATLAB Drive
2. Open the example live script (ImageProcessingExample.mlx) and load the example workspace (ImageProcessingExample.mat)
3. Run the live script to analyze the example images in the data folder OR replace them with your own max projection images.
4. To optionally merge image acquisition information with your final results table, ensure each image file is named correctly. For the following example, the info in bold will be used to categorize images based on magnification, exposure time, and shutter speed.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; MAX\_**20X**r2\_WT\_0.4uM ruby\_75um**\_400ms\_**1Xgain**\_1shut\_**062\_crop.nd2 \- C=0.tif

# Repository Structure
1.  code                    % MATLAB scripts and functions, example workspace files
2. data                     % Example input images
3. results                 % Output quantification tables and saved image outputs
4. README.md

# Functions
### Thresholding images with Otsu's Method

T = graythresh(I) computes a global threshold T from grayscale image I, using Otsu's method\[1\]. Otsu's method chooses a threshold that minimizes the intraclass variance of the thresholded black and white pixels. The global threshold T can be used with imbinarize to convert a grayscale image to a binary image.


***Here, one representative threshold (avgThresh) will be applied uniformly to improve comparability across multiple images.***


\[1\] Otsu, N., "A Threshold Selection Method from Gray\-Level Histograms." IEEE Transactions on Systems, Man, and Cybernetics. Vol. 9, No. 1, 1979, pp. 62–66.

```matlab
function avgThresh = avgOtsu(ds)

allThresh = zeros(numel(ds.Files),1);
reset(ds);
for i = 1:numel(ds.Files)
    img = readimage(ds,i);
    img_dbl = im2double(img);
    img_scaled = rescale(img_dbl);
    allThresh(i) = graythresh(img_scaled);
end
avgThresh = mean(allThresh);
end
```

### Processing images in an ImageDatastore using the average threshold

The pixel intensities of each image are scaled before thresholding 

-  **\*Normalization**\*: Scaling helps normalize the intensity values, making them more comparable across images, especially if there are variations in exposure or background. This can improve the consistency of thresholding results. 
-  **\*Dynamic Range**\*: Rescaling to the range \[0, 1\] ensures that you are utilizing the full dynamic range of the pixel values, which can enhance the performance of thresholding algorithms like Otsu's. 
-  **\*Stability**\*: When intensity values are on a consistent scale, it can lead to more stable threshold values, reducing variability introduced by different imaging conditions. 


**Syntax:**

<pre>
resultsTableNorm = processDSNorm(ds, avgThresh, outputDir)
</pre>

 **Inputs:** 

-  ds \- ImageDatastore with Labels property  
-  avgThresh \- Average threshold value (scalar)  
-  outputDir \- Directory where output images will be saved 


 **Outputs:** 


&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; resultsTableNorm \- Table of normalized quantification results

-  Area = Number of non\-zero elements in selection (in square pixels) 
-  Total Pixels = Number of pixels in an image 
-  Mean Grey Value = Average grey value within the selection. 
-  Integrated Density = The product of Mean Grey Value and Area 
-  Raw Integrated Density = The sum of total pixel value in the selection 
```matlab
function resultsTableNorm = processDSNorm(ds, avgThresh, outputDir)

% Preallocate output table
    nFiles         = numel(ds.Files);
    FileName       = strings(nFiles,1);
    Threshold      = zeros(nFiles,1);
    Area           = zeros(nFiles,1);
    TotalPixels    = zeros(nFiles,1);
    MeanGreyValue  = zeros(nFiles,1);
    StandardDev    = zeros(nFiles,1);
    MinGreyValue   = zeros(nFiles,1);
    MaxGreyValue   = zeros(nFiles,1);
    IntDensity     = zeros(nFiles,1);
    RawIntDensity  = zeros(nFiles,1);

    % Reset datastore
    reset(ds);

    % Process each image
    for i = 1:nFiles
        [img, info] = read(ds);
        [~, baseName, ~] = fileparts(info.Filename);

        % Get label
        label = string(info.Label);

        % Make subfolder for this label if it doesn’t exist
        labelDir = fullfile(outputDir, label);
        if ~exist(labelDir, "dir"), mkdir(labelDir); end

        % --- Preprocess ---

        img_dbl    = im2double(img);

        % R = rescale(A) scales all elements in A to the interval [0, 1]
        % according to the minimum and maximum over all elements in A. The
        % output array R is the same size as A.
        img_scaled = rescale(img_dbl);

        % Each binary mask is made using the average threshold 
        % calculated using Otsu's method
        img_BM     = imbinarize(img_scaled, avgThresh);

        % Apply mask to original (double precision) image
        img_masked = img_dbl .* img_BM;

        % --- Quantification ---
        Area_ = nnz(img_BM);
        AreaSq = sqrt(Area_);
        TotalPixels_ = numel(img_BM);

        RawInt = img_dbl(img_BM > 0);

        if isempty(RawInt)
            MeanGreyValue_ = 0;
            StandardDev_   = 0;
            MinGreyValue_  = 0;
            MaxGreyValue_  = 0;
            IntDensity_    = 0;
            RawIntDensity_ = 0;
        else
            MeanGreyValue_ = mean(RawInt);
            StandardDev_   = std(RawInt);
            MinGreyValue_  = min(RawInt);
            MaxGreyValue_  = max(RawInt);
            IntDensity_    = MeanGreyValue_ .* AreaSq;
            RawIntDensity_ = sum(RawInt);
        end

        % --- Store results ---
        FileName(i)      = string(info.Filename);
        Threshold(i)     = avgThresh;
        Area(i)          = AreaSq;
        TotalPixels(i)   = TotalPixels_;
        MeanGreyValue(i) = MeanGreyValue_;
        StandardDev(i)   = StandardDev_;
        MinGreyValue(i)  = MinGreyValue_;
        MaxGreyValue(i)  = MaxGreyValue_;
        IntDensity(i)    = IntDensity_;
        RawIntDensity(i) = RawIntDensity_;

        % --- Save images into label subfolder ---
        imwrite(img,        fullfile(labelDir, baseName + "_orig.tif"));
        imwrite(img_scaled, fullfile(labelDir, baseName + "_scaled.tif"));
        imwrite(img_masked,     fullfile(labelDir, baseName + "_masked.tif"));
    end

    % Combine into a table
    resultsTableNorm = table(FileName,Threshold,Area,TotalPixels,...
                        MeanGreyValue,StandardDev,MinGreyValue,...
                        MaxGreyValue,IntDensity,RawIntDensity);
end
```

# Usage
### Create variables for relevant directories.

Example input images are in DataDir and results will be stored in ResultsDir

```matlab
DataDir = '../processDS/data';
ResultsDir = '../processDS/results';
```

### Create an ImageDatastore from the image directory. Subfolders within the directory will be used as labels for subsequent analysis (Ex: mRuby3 vs mRuby3 BT0996 E240A)
```matlab
ds = imageDatastore(DataDir,"FileExtensions",".tif","IncludeSubfolders",true,"LabelSource","foldernames");

countEachLabel(ds)
```
| |Label|Count|
|:--:|:--:|:--:|
|1|mRuby3|5|
|2|mRuby3 BT0996 E240A|5|

### Create an ImageDatastore subset with images of your label of interest (Ex: mRuby3 BT0996 E240A). These will be used to generate an average threshold.
```matlab
ds_LOI = subset(ds,ds.Labels == "mRuby3 BT0996 E240A");
```

### Use the avgOtsu function to generate an average from the global thresholds for all subset images. 

The average threshold should be used for images acquired in the same experiment. Do not use the same average across multiple days!

```matlab
avgThresh = avgOtsu(ds_LOI)
```

```matlabTextOutput
avgThresh = 0.1365
```

### Use the processDSNorm function to analyze all images with the average threshold.
```matlab
reset(ds);
ResultsTableNorm = processDSNorm(ds, avgThresh, ResultsDir)
```
| |FileName|Threshold|Area|TotalPixels|MeanGreyValue|StandardDev|MinGreyValue|MaxGreyValue|IntDensity|RawIntDensity|
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
|1|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3/MAX_20Xr2_WT_0.4uM ruby_75um_400ms_1Xgain_1shut_062_crop.nd2 - C=0.tif"|0.1365|778.3495|2585664|0.0268|0.0118|0.0157|0.1098|20.8274|1.6211e+04|
|2|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3/MAX_20Xr3_WT_0.4uM ruby_75um_400ms_1Xgain_1shut_064_crop.nd2 - C=0.tif"|0.1365|824.8648|2585664|0.0420|0.0172|0.0275|0.1961|34.6846|2.8610e+04|
|3|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3/MAX_20Xr4_WT_0.4uM ruby_75um_400ms_1Xgain_1shut_066_crop.nd2 - C=0.tif"|0.1365|618.3146|2585664|0.0302|0.0096|0.0235|0.1451|18.6652|1.1541e+04|
|4|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3/MAX_20Xr5_WT_0.4uM ruby_75um_400ms_1Xgain_1shut_068_crop.nd2 - C=0.tif"|0.1365|779.9782|2585664|0.0151|0.0051|0.0118|0.0824|11.7492|9.1641e+03|
|5|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3/MAX_20Xr6_WT_0.4uM ruby_75um_400ms_1Xgain_1shut_070_crop.nd2 - C=0.tif"|0.1365|764.6457|2585664|0.0336|0.0129|0.0235|0.1569|25.6714|1.9630e+04|
|6|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3 BT0996 E240A/MAX_20Xr1_WT_0.4uM 96E_75um_400ms_1Xgain_1shut_027_crop.nd2 - C=0.tif"|0.1365|649.3797|2585664|0.1525|0.0609|0.1020|0.7059|99.0628|6.4329e+04|
|7|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3 BT0996 E240A/MAX_20Xr2_WT_0.4uM 96E_75um_400ms_1Xgain_1shut_029_crop.nd2 - C=0.tif"|0.1365|475.1021|2585664|0.1719|0.0674|0.1137|0.8235|81.6923|3.8812e+04|
|8|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3 BT0996 E240A/MAX_20Xr3_WT_0.4uM 96E_75um_400ms_1Xgain_1shut_033_crop.nd2 - C=0.tif"|0.1365|583.7911|2585664|0.1359|0.0541|0.0941|0.6784|79.3140|4.6303e+04|
|9|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3 BT0996 E240A/MAX_20Xr5_WT_0.4uM 96E_75um_400ms_1Xgain_1shut_035_crop.nd2 - C=0.tif"|0.1365|590.6319|2585664|0.1579|0.0582|0.1059|0.7255|93.2412|5.5071e+04|
|10|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3 BT0996 E240A/MAX_20Xr6_WT_0.4uM 96E_75um_400ms_1Xgain_1shut_037_crop.nd2 - C=0.tif"|0.1365|672.5258|2585664|0.1521|0.0585|0.1059|0.6745|102.2653|6.8776e+04|

### \[OPTIONAL\] Merge results table with image acquisition information 

Filter through file names and create a categorical array indicating the shutter speed, exposure time, and magnification used in acquisition. 


Shutter Speed

```matlab
Shutter1 = '_1shut_';
Shutter2 = '_2shut_';

dsShutter2 = contains(ds.Files,Shutter2);
disp(['Number of shutter 2 images: ', num2str(nnz(dsShutter2))])
```

```matlabTextOutput
Number of shutter 2 images: 0
```

```matlab

dsShutter1 = contains(ds.Files,Shutter1);
disp(['Number of shutter 1 images: ', num2str(nnz(dsShutter1))])
```

```matlabTextOutput
Number of shutter 1 images: 10
```

```matlab

ShutterSpeedLabels = {"Shutter 1" "Shutter 2"};

assignedShutter = cell(size(dsShutter2));

assignedShutter(dsShutter1) = ShutterSpeedLabels(1);
assignedShutter(dsShutter2) = ShutterSpeedLabels(2);

assignedShutter = string(assignedShutter);
assignedShutter = categorical(assignedShutter);

```

Exposure

```matlab
Exposure_300 = '_300ms_';
Exposure_400 = '_400ms_';

dsExposure300 = contains(ds.Files,Exposure_300);
disp(['Number of 300 ms images: ', num2str(nnz(dsExposure300))])
```

```matlabTextOutput
Number of 300 ms images: 0
```

```matlab

dsExposure400 = contains(ds.Files,Exposure_400);
disp(['Number of 400 ms images: ', num2str(nnz(dsExposure400))])
```

```matlabTextOutput
Number of 400 ms images: 10
```

```matlab

ExposureTimeLabels = {"300 ms" "400 ms"};

assignedExposure = cell(size(dsExposure300));

assignedExposure(dsExposure300) = ExposureTimeLabels(1);
assignedExposure(dsExposure400) = ExposureTimeLabels(2);

assignedExposure = string(assignedExposure);
assignedExposure = categorical(assignedExposure);
```


Magnification

```matlab
Magnification10X = '10X';
Magnification20X = '20X';

ds_10X = contains(ds.Files,Magnification10X);
disp(['Number of 10X images: ', num2str(nnz(ds_10X))])
```

```matlabTextOutput
Number of 10X images: 0
```

```matlab

ds_20X = contains(ds.Files,Magnification20X);
disp(['Number of 20X images: ', num2str(nnz(ds_20X))])
```

```matlabTextOutput
Number of 20X images: 10
```

```matlab

MagnificationLabels = {"10X" "20X"};

assignedMagnification = cell(size(ds_10X));

assignedMagnification(ds_10X) = MagnificationLabels(1);
assignedMagnification(ds_20X) = MagnificationLabels(2);

assignedMagnification = string(assignedMagnification);
assignedMagnification = categorical(assignedMagnification);

```


Create a table containing original file names, labels, assigned shutter speed, and magnification. 


This table will be used to organize data in subsequent processing.

```matlab
info_variables = ["FileName" "Label" "Shutter Speed" "Exposure Time" "Magnification"];
info_ds = table(ds.Files,ds.Labels,assignedShutter,assignedExposure,assignedMagnification,...
                VariableNames=info_variables);
```


Combine ResultsTableNorm with info\_ds to merge image metadata (shutter speed, exposure time, magnification, etc..) with computed results.

```matlab
% Merge based on FileName
ResultsTableNorm_final = outerjoin(info_ds, ResultsTableNorm,  ...
    'Keys', 'FileName', ...
    'MergeKeys', true)
```
| |FileName|Label|Shutter Speed|Exposure Time|Magnification|Threshold|Area|TotalPixels|MeanGreyValue|StandardDev|MinGreyValue|MaxGreyValue|IntDensity|RawIntDensity|
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
|1|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3 BT0996 E240A/MAX_20Xr1_WT_0.4uM 96E_75um_400ms_1Xgain_1shut_027_crop.nd2 - C=0.tif"|mRuby3 BT0996 E240A|Shutter 1|400 ms|20X|0.1365|649.3797|2585664|0.1525|0.0609|0.1020|0.7059|99.0628|6.4329e+04|
|2|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3 BT0996 E240A/MAX_20Xr2_WT_0.4uM 96E_75um_400ms_1Xgain_1shut_029_crop.nd2 - C=0.tif"|mRuby3 BT0996 E240A|Shutter 1|400 ms|20X|0.1365|475.1021|2585664|0.1719|0.0674|0.1137|0.8235|81.6923|3.8812e+04|
|3|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3 BT0996 E240A/MAX_20Xr3_WT_0.4uM 96E_75um_400ms_1Xgain_1shut_033_crop.nd2 - C=0.tif"|mRuby3 BT0996 E240A|Shutter 1|400 ms|20X|0.1365|583.7911|2585664|0.1359|0.0541|0.0941|0.6784|79.3140|4.6303e+04|
|4|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3 BT0996 E240A/MAX_20Xr5_WT_0.4uM 96E_75um_400ms_1Xgain_1shut_035_crop.nd2 - C=0.tif"|mRuby3 BT0996 E240A|Shutter 1|400 ms|20X|0.1365|590.6319|2585664|0.1579|0.0582|0.1059|0.7255|93.2412|5.5071e+04|
|5|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3 BT0996 E240A/MAX_20Xr6_WT_0.4uM 96E_75um_400ms_1Xgain_1shut_037_crop.nd2 - C=0.tif"|mRuby3 BT0996 E240A|Shutter 1|400 ms|20X|0.1365|672.5258|2585664|0.1521|0.0585|0.1059|0.6745|102.2653|6.8776e+04|
|6|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3/MAX_20Xr2_WT_0.4uM ruby_75um_400ms_1Xgain_1shut_062_crop.nd2 - C=0.tif"|mRuby3|Shutter 1|400 ms|20X|0.1365|778.3495|2585664|0.0268|0.0118|0.0157|0.1098|20.8274|1.6211e+04|
|7|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3/MAX_20Xr3_WT_0.4uM ruby_75um_400ms_1Xgain_1shut_064_crop.nd2 - C=0.tif"|mRuby3|Shutter 1|400 ms|20X|0.1365|824.8648|2585664|0.0420|0.0172|0.0275|0.1961|34.6846|2.8610e+04|
|8|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3/MAX_20Xr4_WT_0.4uM ruby_75um_400ms_1Xgain_1shut_066_crop.nd2 - C=0.tif"|mRuby3|Shutter 1|400 ms|20X|0.1365|618.3146|2585664|0.0302|0.0096|0.0235|0.1451|18.6652|1.1541e+04|
|9|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3/MAX_20Xr5_WT_0.4uM ruby_75um_400ms_1Xgain_1shut_068_crop.nd2 - C=0.tif"|mRuby3|Shutter 1|400 ms|20X|0.1365|779.9782|2585664|0.0151|0.0051|0.0118|0.0824|11.7492|9.1641e+03|
|10|"/Users/kthorne/MATLAB-Drive/processDS/data/Example input images/mRuby3/MAX_20Xr6_WT_0.4uM ruby_75um_400ms_1Xgain_1shut_070_crop.nd2 - C=0.tif"|mRuby3|Shutter 1|400 ms|20X|0.1365|764.6457|2585664|0.0336|0.0129|0.0235|0.1569|25.6714|1.9630e+04|

```matlab

% Write table as Excel file
cd(ResultsDir)
writetable(ResultsTableNorm_final, 'ResultsTableNorm_example.xls')
```
