clear all; close all; clc;
% This code opens gridded monthly 1km MODIS EVI in each year and calculate area weighted monthly EVI over catchments

addpath 'Add the location of gridded monthly MODIS EVI data folder here';

% Load monthly 1km QA MOD EVI
load("Load your monthly MODIS EVI. eg:VicQA_MODEVI.mat");
monthlystep = size(MODISEVI_QA,3); % Total months from 2000 Feb to 2020 Dec

MODISLon = load("Load the Longitudes of MODIS EVI dataset");
MODISLat = load("Load the latitudes of MODIS EVI dataset");

%Catchments
Catchments =load("Load the names of the study catchments");
NumCatch = size(Catchments,1);

% Load grid area intersected catchment details
IntersecA_details = importdata('CatchGridIntersect1km_MODNDVI_EVI.csv');
GridIntersecCatch = IntersecA_details.data(:,4);
GridIntersecCatchArea = IntersecA_details.data(:,5);
IntersecGrids_Lon = IntersecA_details.data(:,2);
IntersecGrids_Lat = IntersecA_details.data(:,3);

for iMonthstep = 1:monthlysetp
    ThisMonth_EVI = MODISEVI_QA(:,:,iMonthstep); %This month Veg index
    AreaAvgEVI = [];
    % Calculate catchment average VI
    for iCatch = 1:NumCatch
        All_AreaGridEVI = [];
        indCatch = [];
        ThisCatch = Catchments(iCatch);
        indCatch = find(GridIntersecCatch==ThisCatch); NumGrids =size(indCatch,1); % num of grids which intersect with catchments
        CatchLon = IntersecGrids_Lon(indCatch); 
        CatchLat = IntersecGrids_Lat(indCatch);
        CatchArea = GridIntersecCatchArea(indCatch);  TotalArea_Initial = sum(CatchArea,'all');
        TotalArea = sum(CatchArea,'all');
        for iGrid = 1:NumGrids               
                ThisLon = CatchLon(iGrid);
                ThisLat = CatchLat(iGrid);
                ThisCatchArea = CatchArea(iGrid); %Catchment area

                %Find position of Grids in MODIS EVI matrix
                PosLon = find(abs(MODISLon - ThisLon) <= 0.0001);
                PosLat = find(abs(MODISLat - ThisLat)<= 0.0001);
                GridEVI = ThisMonth_EVI(PosLon,PosLat);
                
                if isnan(GridEVI)    % calculate grid areas having NaN inside catchments
                TotalArea = TotalArea - ThisCatchArea;    
                end
                
                AreaGridEVI = GridEVI.*ThisCatchArea;
                All_AreaGridEVI(iGrid) = AreaGridEVI; 
        end
        Mat_EVI = nansum(All_AreaGridEVI);
        
        % Calculate catchment area without NaN EVI
        AreaPercent = (TotalArea./TotalArea_Initial)*100;
        
        if AreaPercent>= 75
            AreaAvgEVI(iCatch) = Mat_EVI./TotalArea;
        else
            AreaAvgEVI(iCatch) = NaN;
        end
    end
    All_EVI(:,iMonthstep)= AreaAvgEVI;
end

MatEVI = [Catchments,All_EVI]';
dlmwrite('CatchmentAvgQA_MonthlyEVI.csv',MatEVI,'delimiter', ',', 'precision', 6); 

    