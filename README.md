# Tire Stud Detector in MATLAB

This repository contains a simple MATLAB script `tire_stud_detector.m` to detect metal studs on tire images using image preprocessing and connected component analysis (análisis de componentes conectados).

The script processes two example images:

- `studded_tire.jpg` (winter tire with studs)
- `summer_tire.jpg` (non studded tire)

and classifies each one as `STUDDED TIRE` or `NON-STUDDED TIRE`.

---

## Requirements

- MATLAB
- Image Processing Toolbox  
- Input images in the working folder:
  - `studded_tire.jpg`
  - `summer_tire.jpg`

---

## Usage

1. Place `tire_stud_detector.m` and the tire images in the same folder.
2. Open MATLAB in that folder.
3. Run.

For each input image, a figure with three subplots is shown:

1. Original image.
2. Binary candidate stud mask.
3. Final detection result with detected studs outlined and text classification.

---

## Code structure

The main script loops over all images in `imageFiles` and applies the same pipeline:

### 1. Read and resize

* Reads the image with `imread`.
* Optionally resizes it with `imresize` to speed up processing.

### 2. Convert to grayscale

* Converts RGB images to grayscale with `rgb2gray`.
* Normalizes grayscale values to `[0, 1]` using `mat2gray` for robust thresholding.

### 3. Create tire mask

Goal: isolate the dark tire from the typically bright background.

* Uses Otsu threshold (`graythresh`) on the normalized image.
* Inverts the binary image so the dark tire region becomes foreground.
* Cleans the mask:

  * Fills holes with `imfill`.
  * Removes tiny blobs with `bwareaopen`.
  * Smooths the tire contour using morphological closing with a disk structuring element.

The area of the tire (`tireArea`) is also computed as the number of pixels inside the mask.

### 4. Candidate studs

Goal: find bright points inside the tire region.

* Extracts grayscale values only inside the tire mask.
* Computes mean and standard deviation of these pixels.
* Defines a dynamic bright threshold:
  `brightLevel = mean + 1.5 * std` (clipped to `[0, 1]`).
* Optionally applies a small Gaussian blur (`imgaussfilt`) to reduce noise.
* Generates a binary candidate map:

  * Pixel is a candidate if it is bright and inside the tire mask.
* Cleans the candidate map:

  * Removes very small objects (`bwareaopen`).
  * Applies morphological opening to remove speckles.
  * Fills small holes.

### 5. Connected components

* Finds connected components in the cleaned candidate map with `bwconncomp`.
* Uses `regionprops` to measure:

  * `Area`
  * `Perimeter`
  * `Eccentricity` (how elongated the region is)

### 6. Filter candidates (stud selection)

Goal: keep only small, round, bright blobs that look like metal studs.

For each region:

* Computes circularity:
  `circ = 4 * pi * Area / Perimeter^2`
* Applies constraints:

  * Area between `minA` and `maxA`.
  * Circularity above `minCirc`.
  * Eccentricity below `maxEcc`.

If a region passes all filters, it is added to `studMask` and `studCount` is incremented.

### 7. Decision rule

The tire is classified based on the number of valid studs:

```matlab
isStudded = (studCount > 20);
```

This threshold can be adjusted depending on the tire image resolution and expected stud density.

### 8. Visualization

For each image, a figure with three panels is displayed:

1. Original input image.
2. Binary candidate stud mask.
3. Original image with boundaries of accepted studs drawn using `visboundaries` and a title showing the classification and stud count.

---

<img width="1043" height="530" alt="Figure_1" src="https://github.com/user-attachments/assets/39e04774-3867-48a2-8bd5-066a974997fe" />

<img width="1000" height="198" alt="Figure_2" src="https://github.com/user-attachments/assets/97e3f940-a028-4e45-99d0-1b6ef8147345" />

---

## Tuning

Key parameters that you may need to tune for different datasets:

* Resize factor in `imresize`.
* Bright threshold factor (`1.5 * sigmaTire`).
* Morphological structuring element sizes.
* Region filters:

  * `minA`, `maxA`
  * `minCirc`
  * `maxEcc`
* Decision threshold on `studCount` (or you can use stud density: `studCount / tireArea`).

Adjusting these values allows the same script to work with different image resolutions and lighting conditions.

