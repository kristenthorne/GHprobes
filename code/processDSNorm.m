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
        imwrite(img_masked,     fullfile(labelDir, baseName + "_mask.tif"));
    end

    % Combine into a table
    resultsTableNorm = table(FileName,Threshold,Area,TotalPixels,...
                        MeanGreyValue,StandardDev,MinGreyValue,...
                        MaxGreyValue,IntDensity,RawIntDensity);
end