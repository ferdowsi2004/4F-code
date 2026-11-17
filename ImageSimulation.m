
clc;
clear;
close all;

%% ============================================================
%  1. LOAD THE OBJECT IMAGE
% =============================================================
imagePath = "C:\Users\bisht\OneDrive\Documents\IISC\Semester 1\Optical instrumentation\4F experiment\Test Kit\Grid with low f.tiff" 
img = imread(imagePath);

% Convert RGB image to grayscale
if size(img, 3) == 3
    img = rgb2gray(img);
end

% Convert to double precision
img = im2double(img);

% Resize image
img = imresize(img, [512 512]);

[N, M] = size(img);


%% ============================================================
%  2. CALCULATE 2D FOURIER TRANSFORM
% =============================================================

F = fft2(img);

% Shift zero frequency to centre
F_shift = fftshift(F);

% Calculate Fourier intensity
I_fourier = abs(F_shift).^2;

% Logarithmic scaling for better visualization
I_fourier_log = log(1 + I_fourier);


%% ============================================================
%  3. DEFINE SPATIAL FREQUENCY COORDINATES
% =============================================================

fx = (-M/2:M/2-1)/M;
fy = (-N/2:N/2-1)/N;

[FX, FY] = meshgrid(fx, fy);

% Radial spatial frequency
FR = sqrt(FX.^2 + FY.^2);


%% ============================================================
%  4. DEFINE FILTER PARAMETERS
% =============================================================

% Radial cutoff frequency
cutoff = 0.15;

% Half-width of vertical slit
slitWidth = 0.05;


%% ============================================================
%  5. CIRCULAR LOW-PASS FILTER
% =============================================================

H_LP = double(FR <= cutoff);


%% ============================================================
%  6. CIRCULAR HIGH-PASS FILTER
% =============================================================

H_HP = double(FR >= cutoff);


%% ============================================================
%  7. CREATE VERTICAL SLIT
% =============================================================

% Restrict horizontal spatial frequency fx
% This creates a vertical slit in the Fourier plane

H_SLIT = double(abs(FX) <= slitWidth);


%% ============================================================
%  8. DIRECTIONAL LOW-PASS FILTER
% =============================================================

H_DLP = H_LP .* H_SLIT;


%% ============================================================
%  9. DIRECTIONAL HIGH-PASS FILTER
% =============================================================

H_DHP = H_HP .* H_SLIT;


%% ============================================================
%  10. APPLY ALL FOUR FILTERS
% =============================================================

F_LP = F_shift .* H_LP;

F_HP = F_shift .* H_HP;

F_DLP = F_shift .* H_DLP;

F_DHP = F_shift .* H_DHP;


%% ============================================================
%  11. CALCULATE FILTERED FOURIER INTENSITIES
% =============================================================

I_LP = abs(F_LP).^2;

I_HP = abs(F_HP).^2;

I_DLP = abs(F_DLP).^2;

I_DHP = abs(F_DHP).^2;


%% ============================================================
%  12. FOURIER RECONSTRUCTION
% =============================================================

% Low-pass reconstruction
img_LP_field = ifft2(ifftshift(F_LP));
img_LP = abs(img_LP_field).^2;

% High-pass reconstruction
img_HP_field = ifft2(ifftshift(F_HP));
img_HP = abs(img_HP_field).^2;

% Directional low-pass reconstruction
img_DLP_field = ifft2(ifftshift(F_DLP));
img_DLP = abs(img_DLP_field).^2;

% Directional high-pass reconstruction
img_DHP_field = ifft2(ifftshift(F_DHP));
img_DHP = abs(img_DHP_field).^2;


%% ============================================================
%  13. DISPLAY ALL FOUR FILTERS
% =============================================================

figure('Name', 'Spatial Frequency Filters', ...
       'NumberTitle', 'off', 'Color', 'w');

subplot(2,2,1);
imagesc(fx, fy, H_LP);
axis image;
colormap(gca, 'gray');
colorbar;
title('Circular Low-Pass Filter');
xlabel('f_x (cycles/pixel)');
ylabel('f_y (cycles/pixel)');

subplot(2,2,2);
imagesc(fx, fy, H_HP);
axis image;
colormap(gca, 'gray');
colorbar;
title('Circular High-Pass Filter');
xlabel('f_x (cycles/pixel)');
ylabel('f_y (cycles/pixel)');

subplot(2,2,3);
imagesc(fx, fy, H_DLP);
axis image;
colormap(gca, 'gray');
colorbar;
title('Directional Low-Pass: Vertical Slit');
xlabel('f_x (cycles/pixel)');
ylabel('f_y (cycles/pixel)');

subplot(2,2,4);
imagesc(fx, fy, H_DHP);
axis image;
colormap(gca, 'gray');
colorbar;
title('Directional High-Pass: Vertical Slit');
xlabel('f_x (cycles/pixel)');
ylabel('f_y (cycles/pixel)');

sgtitle('Spatial Frequency Filters');


%% ============================================================
%  14. DISPLAY FOURIER INTENSITY DISTRIBUTIONS
% =============================================================

figure('Name', 'Fourier Intensity Distributions', ...
       'NumberTitle', 'off', 'Color', 'w');

subplot(2,3,1);
imagesc(fx, fy, I_fourier_log);
axis image;
colormap(gca, 'hot');
colorbar;
title('Original Fourier Intensity');
xlabel('f_x (cycles/pixel)');
ylabel('f_y (cycles/pixel)');

subplot(2,3,2);
imagesc(fx, fy, log(1 + I_LP));
axis image;
colormap(gca, 'hot');
colorbar;
title('Low-Pass Fourier Intensity');
xlabel('f_x (cycles/pixel)');
ylabel('f_y (cycles/pixel)');

subplot(2,3,3);
imagesc(fx, fy, log(1 + I_HP));
axis image;
colormap(gca, 'hot');
colorbar;
title('High-Pass Fourier Intensity');
xlabel('f_x (cycles/pixel)');
ylabel('f_y (cycles/pixel)');

subplot(2,3,5);
imagesc(fx, fy, log(1 + I_DLP));
axis image;
colormap(gca, 'hot');
colorbar;
title('Directional Low-Pass Intensity');
xlabel('f_x (cycles/pixel)');
ylabel('f_y (cycles/pixel)');

subplot(2,3,6);
imagesc(fx, fy, log(1 + I_DHP));
axis image;
colormap(gca, 'hot');
colorbar;
title('Directional High-Pass Intensity');
xlabel('f_x (cycles/pixel)');
ylabel('f_y (cycles/pixel)');

sgtitle('Fourier Plane Intensity Distributions');


%% ============================================================
%  15. DISPLAY RECONSTRUCTED IMAGES
% =============================================================

figure('Name', 'Fourier Reconstructions', ...
       'NumberTitle', 'off', 'Color', 'w');

subplot(2,3,1);
imshow(img, []);
title('Original Object');

subplot(2,3,2);
imshow(img_LP, []);
title('Circular Low-Pass');

subplot(2,3,3);
imshow(img_HP, []);
title('Circular High-Pass');

subplot(2,3,5);
imshow(img_DLP, []);
title('Directional Low-Pass');

subplot(2,3,6);
imshow(img_DHP, []);
title('Directional High-Pass');

sgtitle('4f Optical System: Reconstructed Intensity');


%% ============================================================
%  16. COMPARE ORIGINAL AND DIRECTIONAL RECONSTRUCTIONS
% =============================================================

figure('Name', 'Directional Filtering Comparison', ...
       'NumberTitle', 'off', 'Color', 'w');

subplot(1,3,1);
imshow(img, []);
title('Original Object');

subplot(1,3,2);
imshow(img_DLP, []);
title('Directional Low-Pass');

subplot(1,3,3);
imshow(img_DHP, []);
title('Directional High-Pass');

sgtitle('Comparison of Directional Spatial Filtering');
