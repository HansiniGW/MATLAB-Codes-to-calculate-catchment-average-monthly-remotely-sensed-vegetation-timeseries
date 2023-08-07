clear all; close all; clc;
% This code opens gridded monthly 1km MODIS NDVI in each year and calculate area weighted monthly NDVI over catchments
addpath 'Add the location of gridded monthly MODIS NDVI data folder here';

MODISLon = load("Load the Longitudes of MODIS NDVI dataset");
MODISLat = load("Load the latitudes of MODIS NDVI dataset");


%Catchments
Catchments =load("Load the names of the study catchments");
NumCatch = size(Catchments,1);


% Load grid area intersected catchment details
IntersecA_details = importdata('load grid intersected catchment area details (i.e., CatchGridIntersect1km_MODNDVI_EVI.csv)');
GridIntersecCatch = IntersecA_details.data(:,4);
GridIntersecCatchArea = IntersecA_details.data(:,5);
IntersecGrids_Lon = IntersecA_details.data(:,2);
IntersecGrids_Lat = IntersecA_details.data(:,3);

% Load monthly MODIS NDVI
load('Load your monthly MODIS NDVI. eg:Vic_MODIS1km_NDVI.mat');
monthlysetp = size(VicMODIS_NDVI,3); % Total months from 2000 Feb to 2020 Dec




for iMonthstep = 1:monthlysetp
    ThisMonth_NDVI = VicMODIS_NDVI(:,:,iMonthstep); %This month Veg index

    % Calculate catchment average VI
    for iCatch = 1:NumCatch
        All_AreaGridNDVI = [];
        indCatch = [];
        AreaNaN = 0; % Assign zero value to inital area with NaN value
        ThisCatch = Catchments(iCatch);
        indCatch = find(GridIntersecCatch==ThisCatch); NumGrids =size(indCatch,1); % num of grids which intersected with the given catchment
        CatchLon = IntersecGrids_Lon(indCatch); 
        CatchLat = IntersecGrids_Lat(indCatch);
        CatchArea = GridIntersecCatchArea(indCatch);  TotalArea = sum(CatchArea,'all');
        
        for iGrid = 1:NumGrids               
                ThisLon = CatchLon(iGrid);
                ThisLat = CatchLat(iGrid);
                ThisCatchArea = CatchArea(iGrid); %Catchment area

                %Find position of Grids in MODIS NDVI matrix
                PosLon = find(abs(MODISLon - ThisLon) <= 0.0001);
                PosLat = find(abs(MODISLat - ThisLat)<= 0.0001);
                GridNDVI = ThisMonth_NDVI(PosLon,PosLat);
                
                if isnan(GridNDVI)    % calculate grid areas having NaN inside catchments
                AreaNaN = AreaNaN + ThisCatchArea;    
                end
                
                AreaGridNDVI = GridNDVI.*ThisCatchArea;
                All_AreaGridNDVI(iGrid) = AreaGridNDVI; 
        end
        Mat_NDVI = nansum(All_AreaGridNDVI);
        AreaAvgNDVI(iCatch) = Mat_NDVI./(TotalArea-AreaNaN); 
        
    end
    Total_AreaAvgNDVI(:,iMonthstep) = AreaAvgNDVI;
end

MatNDVI = [Catchments,Total_AreaAvgNDVI]';
dlmwrite('CatchmentAvg_MonthlyNDVI.csv',MatNDVI,'delimiter', ',', 'precision', 6); 

    