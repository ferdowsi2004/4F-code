clc;
clear;
close all;

%% 1. GENERATE A 3D TEST OBJECT

N = 256;

% Define the x, y and z coordinates of the 3D space
x = linspace(-1,1,N);
y = linspace(-1,1,N);
z = linspace(-1,1,N);

% Create a 3D coordinate grid
[X,Y,Z] = meshgrid(x,y,z);

% Create three different 3D shapes
sphere = (X.^2 + Y.^2 + Z.^2) <= 0.45^2;

cylinder = ((X-0.35).^2 + (Y+0.25).^2 <= 0.15^2) ...
           & (abs(Z) <= 0.5);

cube = (abs(X+0.35) <= 0.15) ...
       & (abs(Y-0.3) <= 0.15) ...
       & (abs(Z-0.25) <= 0.15);

% Combine the shapes to form one 3D object
object3D = double(sphere) ...
         + 0.8*double(cylinder) ...
         + double(cube);


%% Display the 3D object

figure;
isosurface(X,Y,Z,object3D,0.5);
xlabel('x');
ylabel('y');
zlabel('z');
title('3D Test Object');
axis equal;
grid on;
view(3);


%% 2. CONVERT THE 3D OBJECT TO A 2D OPTICAL OBJECT

% A conventional 4f system operates on a 2D optical field U(x,y).
% Therefore, we obtain a 2D projection of the 3D object by
% integrating/summing it along the z direction:
%
%       U(x,y) = integral O(x,y,z) dz
%
% Numerically, the integration is represented by summation.

object2D = sum(object3D,3);

% Normalize the object so that its maximum value is 1
object2D = object2D/max(object2D(:));


figure;
imagesc(x,y,object2D);
axis image;
colormap gray;
colorbar;
xlabel('x');
ylabel('y');
title('2D Projection of 3D Object');


%% 3. CALCULATE THE 2D FOURIER TRANSFORM

% fft2 calculates the 2D Fourier transform:
%
%       F(fx,fy) = FT{U(x,y)}
%
% In Fourier optics, this represents the spatial-frequency
% distribution of the optical field.

F = fft2(object2D);

% MATLAB normally places the zero-frequency component at
% the corners of the Fourier array.
%
% fftshift moves the zero-frequency component to the CENTER,
% which corresponds to the usual way of displaying a Fourier
% spectrum and makes it convenient to construct circular filters.

F_shifted = fftshift(F);


%% Fourier amplitude

% The Fourier transform is complex:
%
%       F = |F| exp(j*phi)
%
% Therefore, abs(F) gives the amplitude and angle(F)
% gives the phase.

amplitude = abs(F_shifted);

% The Fourier spectrum usually has a very large dynamic range.
% The central components can be much stronger than the outer
% components, so logarithmic scaling is used for visualization.

amplitude_log = log(1 + amplitude);


figure;
imagesc(amplitude_log);
axis image;
colormap gray;
colorbar;
xlabel('f_x');
ylabel('f_y');
title('Logarithmic Amplitude of Fourier Spectrum');


%% Fourier phase

% angle() gives the phase of the complex Fourier spectrum

phase = angle(F_shifted);

figure;
imagesc(phase);
axis image;
colormap hsv;
colorbar;
xlabel('f_x');
ylabel('f_y');
title('Phase Distribution of Fourier Spectrum');


%% 4. NUMERICAL 4f OPTICAL SYSTEM

% The physical 4f system is:
%
%       Object
%          |
%        Lens 1
%          |
%    Fourier Plane
%     [Filter H]
%          |
%        Lens 2
%          |
%        Image
%
% Numerically, this becomes:
%
%       U(x,y)
%          |
%         FFT
%          |
%       U_F(fx,fy)
%          |
%       × H(fx,fy)
%          |
%        IFFT
%          |
%       U_i(x,y)

U_fourier = fftshift(fft2(object2D));


%% Define spatial-frequency coordinates

% These coordinates correspond to the positions in the
% Fourier plane.
%
% For a physical 4f system:
%
%       f_x = x_f/(lambda*f)
%       f_y = y_f/(lambda*f)
%
% Here we use normalized spatial-frequency coordinates.

fx = (-N/2:N/2-1)/N;
fy = (-N/2:N/2-1)/N;

[FX,FY] = meshgrid(fx,fy);

% R gives the radial distance from the center of the
% Fourier plane:
%
%       R = sqrt(fx^2 + fy^2)
%
% This is used to construct circular apertures.

R = sqrt(FX.^2 + FY.^2);


%% 5. LOW-PASS FILTER

% Cutoff spatial frequency.
%
% Only frequencies inside this radius will pass through
% the circular aperture.

fc_low = 0.05;

% Circular low-pass filter:
%
%       H_LP = 1       for R <= fc
%       H_LP = 0       for R >  fc
%
% Physically, this represents a circular aperture placed
% at the Fourier plane.

H_low = double(R <= fc_low);


%% Apply low-pass filter

% Filtering in the Fourier plane is simply multiplication:
%
%       U_filtered = U_fourier * H(fx,fy)
%
% This is the key operation in the numerical 4f system.

U_low_fourier = U_fourier .* H_low;

% The second lens performs the inverse Fourier transform.
%
% Therefore, we use IFFT to reconstruct the filtered image.

U_low = ifft2(ifftshift(U_low_fourier));

% The original object is real, but numerical round-off can
% produce a very small imaginary component.
U_low = real(U_low);


%% Display low-pass filter

figure;
imagesc(fx,fy,H_low);
axis image;
colormap gray;
colorbar;
xlabel('f_x');
ylabel('f_y');
title('Circular Low-Pass Filter');


%% Display low-pass filtered image

figure;
imagesc(x,y,U_low);
axis image;
colormap gray;
colorbar;
xlabel('x');
ylabel('y');
title('Image After Low-Pass Filtering');


%% 6. HIGH-PASS FILTER

% The high-pass filter does the opposite of the low-pass filter.
%
% It blocks the central low-frequency components and allows
% high-frequency components to pass.

fc_high = 0.05;

% Circular high-pass filter:
%
%       H_HP = 0       for R < fc
%       H_HP = 1       for R >= fc

H_high = double(R >= fc_high);


%% Apply high-pass filter

% Multiply the Fourier spectrum by the high-pass filter

U_high_fourier = U_fourier .* H_high;

% Transform back to the image plane

U_high = ifft2(ifftshift(U_high_fourier));

% Remove negligible imaginary numerical errors

U_high = real(U_high);


%% Display high-pass filter

figure;
imagesc(fx,fy,H_high);
axis image;
colormap gray;
colorbar;
xlabel('f_x');
ylabel('f_y');
title('Circular High-Pass Filter');


%% Display high-pass filtered image

figure;
imagesc(x,y,U_high);
axis image;
colormap gray;
colorbar;
xlabel('x');
ylabel('y');
title('Image After High-Pass Filtering');


%% 7. EFFECT OF LOW-PASS FILTER SIZE

% Changing fc changes the size of the aperture in the
% Fourier plane.
%
% Smaller fc:
%   -> smaller aperture
%   -> fewer spatial frequencies pass
%   -> more blurring
%
% Larger fc:
%   -> larger aperture
%   -> more spatial frequencies pass
%   -> better resolution

fc1 = 0.02;
fc2 = 0.05;
fc3 = 0.10;
fc4 = 0.20;


% Create four different circular apertures

H1 = double(R <= fc1);
H2 = double(R <= fc2);
H3 = double(R <= fc3);
H4 = double(R <= fc4);


% Apply each aperture and reconstruct the image

I1 = real(ifft2(ifftshift(U_fourier .* H1)));
I2 = real(ifft2(ifftshift(U_fourier .* H2)));
I3 = real(ifft2(ifftshift(U_fourier .* H3)));
I4 = real(ifft2(ifftshift(U_fourier .* H4)));


%% Compare different low-pass filter sizes

figure;

subplot(2,2,1);
imagesc(x,y,I1);
axis image;
title('LPF: f_c = 0.02');

subplot(2,2,2);
imagesc(x,y,I2);
axis image;
title('LPF: f_c = 0.05');

subplot(2,2,3);
imagesc(x,y,I3);
axis image;
title('LPF: f_c = 0.10');

subplot(2,2,4);
imagesc(x,y,I4);
axis image;
title('LPF: f_c = 0.20');

sgtitle('Effect of Low-Pass Filter Size');
colormap gray;


%% 8. EFFECT OF HIGH-PASS FILTER SIZE

% Increasing fc means that a larger central region of the
% Fourier plane is blocked.
%
% Therefore, more low-frequency information is removed.

fc1 = 0.02;
fc2 = 0.05;
fc3 = 0.10;
fc4 = 0.20;


% Create four different high-pass filters

H1 = double(R >= fc1);
H2 = double(R >= fc2);
H3 = double(R >= fc3);
H4 = double(R >= fc4);


% Apply each filter and reconstruct the image

I1 = real(ifft2(ifftshift(U_fourier .* H1)));
I2 = real(ifft2(ifftshift(U_fourier .* H2)));
I3 = real(ifft2(ifftshift(U_fourier .* H3)));
I4 = real(ifft2(ifftshift(U_fourier .* H4)));


%% Compare different high-pass filter sizes

figure;

subplot(2,2,1);
imagesc(x,y,I1);
axis image;
title('HPF: f_c = 0.02');

subplot(2,2,2);
imagesc(x,y,I2);
axis image;
title('HPF: f_c = 0.05');

subplot(2,2,3);
imagesc(x,y,I3);
axis image;
title('HPF: f_c = 0.10');

subplot(2,2,4);
imagesc(x,y,I4);
axis image;
title('HPF: f_c = 0.20');

sgtitle('Effect of High-Pass Filter Size');
colormap gray;


%% 9. EFFECT OF FILTER SHAPE: DIRECTIONAL FILTER

% Unlike a circular filter, a directional filter allows
% spatial frequencies only within a particular region
% or direction in the Fourier plane.
%
% Here we create a rectangular passband.

fx_cut = 0.03;
fy_cut = 0.15;

% The filter is 1 inside the rectangular region and 0 outside.

H_directional = ...
    double(abs(FX) <= fx_cut & abs(FY) <= fy_cut);


%% Apply directional filter

% Fourier-plane filtering is again multiplication.

U_directional_fourier = U_fourier .* H_directional;

% Reconstruct the image using the inverse Fourier transform.

U_directional = ...
    real(ifft2(ifftshift(U_directional_fourier)));


%% Display directional filter

figure;
imagesc(fx,fy,H_directional);
axis image;
colormap gray;
colorbar;
xlabel('f_x');
ylabel('f_y');
title('Directional Fourier-Plane Filter');


%% Display directional filtered image

figure;
imagesc(x,y,U_directional);
axis image;
colormap gray;
colorbar;
xlabel('x');
ylabel('y');
title('Image After Directional Filtering');


%% ==========================================================
% IMPORTANT RESULT
% ==========================================================
%
% The complete numerical 4f process is:
%
%   U_i(x,y) =
%   IFFT{ FFT[U_o(x,y)] H(fx,fy) }
%
% where H(fx,fy) is the Fourier-plane transfer function.
%
% By the convolution theorem:
%
%   U_i(x,y) = U_o(x,y) * h(x,y)
%
% where:
%
%   h(x,y) = IFFT{H(fx,fy)}
%
% Therefore:
%
% Fourier-plane multiplication
%             ⇓
% Real-space convolution
%
% This is the fundamental principle behind optical
% spatial filtering.
% ==========================================================