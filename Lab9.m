% tire_stud_detector.m
clear; clc; close all;

imageFiles = {'studded_tire.jpeg', 'summer_tire.jpg'};

for i = 1:numel(imageFiles)

    % ---------- 1) Read & resize ----------
    I = imread(imageFiles{i});
    I = imresize(I, 0.5);   % optional scaling

    % ---------- 2) Convert to grayscale ----------
    if ndims(I) == 3
        Igray = rgb2gray(I);
    else
        Igray = I;
    end

    % Work with normalized double for thresholding
    IgrayN = mat2gray(Igray);

    % ---------- 3) Create tire mask ----------
    % Tire is darker than bright background
    % Use Otsu threshold on normalized image and invert
    levelTire = graythresh(IgrayN);
    tireMask = ~imbinarize(IgrayN, levelTire);

    % Clean the tire mask: fill holes, remove small regions, smooth edges
    tireMask = imfill(tireMask, 'holes');
    tireMask = bwareaopen(tireMask, 500);                 % remove tiny blobs
    seTire = strel('disk', 5);
    tireMask = imclose(tireMask, seTire);

    tireArea = nnz(tireMask);

    % ---------- 4) Candidate studs ----------
    % Studs are bright points inside the tire
    % Use mean plus a multiple of std inside the tire as bright threshold
    tirePixels = IgrayN(tireMask);
    muTire = mean(tirePixels);
    sigmaTire = std(tirePixels);
    brightLevel = muTire + 1.5 * sigmaTire;              % tune if needed
    brightLevel = min(max(brightLevel, 0), 1);          % clip to [0,1]

    % Optional Gaussian blur to reduce noise
    Iblur = imgaussfilt(IgrayN, 1);                     % small sigma

    cand = (Iblur > brightLevel) & tireMask;

    % Clean candidate map: remove small noise, open slightly, fill tiny holes
    cand = bwareaopen(cand, 3);
    seStud = strel('disk', 1);
    cand = imopen(cand, seStud);
    cand = imfill(cand, 'holes');

    % ---------- 5) Connected components ----------
    CC = bwconncomp(cand);
    stats = regionprops(CC, 'Area', 'Perimeter', 'Eccentricity');

    % ---------- 6) Filter candidates ----------
    studMask = false(size(cand));
    studCount = 0;

    % Reasonable limits for small bright studs
    minA = 4;      % min area of a stud
    maxA = 120;    % max area of a stud
    minCirc = 0.6; % minimum circularity
    maxEcc = 0.85; % maximum eccentricity

    for k = 1:numel(stats)
        A = stats(k).Area;
        P = stats(k).Perimeter;
        E = stats(k).Eccentricity;

        if P == 0
            continue;
        end

        % Circularity: 4*pi*A / P^2
        circ = 4 * pi * A / (P^2);

        if A >= minA && A <= maxA && circ >= minCirc && E <= maxEcc
            studMask(CC.PixelIdxList{k}) = true;
            studCount = studCount + 1;
        end
    end

    % ---------- 7) Decision rule ----------
    % Simple rule based on absolute count, adjust threshold if needed
    isStudded = (studCount > 20);

    % ---------- 8) Visualization ----------
    figure;
    subplot(1,3,1);
    imshow(I);
    title(sprintf('Input: %s', imageFiles{i}), 'Interpreter', 'none');

    subplot(1,3,2);
    imshow(cand);
    title('Candidate studs (binary)');

    subplot(1,3,3);
    imshow(I);
    hold on;
    visboundaries(studMask, 'LineWidth', 0.7);

    if isStudded
        title(sprintf('STUDDED TIRE (studs: %d)', studCount));
    else
        title(sprintf('NON-STUDDED TIRE (studs: %d)', studCount));
    end

end
