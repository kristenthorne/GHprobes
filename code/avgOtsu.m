function avgThresh = avgOtsu(ds)
%  Thresholding images with Otsu's Method
% 
% T = graythresh(I) computes a global threshold T from grayscale image I,
% using Otsu's method[1]. Otsu's method chooses a threshold that minimizes
% the intraclass variance of the thresholded black and white pixels. The
% global threshold T can be used with imbinarize to convert a grayscale
% image to a binary image.

% One representative threshold (avgThresh) will be applied uniformly to
% improve comparability across multiple images.

% [1] Otsu, N., "A Threshold Selection Method from Gray-Level Histograms."
% IEEE Transactions on Systems, Man, and Cybernetics. Vol. 9, No. 1, 1979,
% pp. 62–66.

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