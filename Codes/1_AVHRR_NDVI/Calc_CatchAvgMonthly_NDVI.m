clear all; close all; clc;
% This code opens gridded monthly NDVI in each year and calculate area weighted monthly NDVI over catchments

addpath 'Add the location of gridded monthly NDVI data folder here';

LonNDVI = load("Load the Longitudes of NDVI dataset");
LatNDVI = load("Load the latitudes of NDVI dataset");

P = [1981:2015]; 
NumYears = size(P,2);
% Catchment
Catchments = load("Load the names of the study catchments");
NumCatch = size(Catchments,1);

% Load grid intersected catchment area details
IntersecA_details = importdata("load grid intersected catchment area details (i.e: CatchGrid_8kmGIMMSNDVI.csv)");
GridIntersecCatch = IntersecA_details.data(:,4);
GridIntersecCatchArea = IntersecA_details.data(:,5);
IntersecGrids_Lon = IntersecA_details.data(:,2);
IntersecGrids_Lat = IntersecA_details.data(:,3);

%%
for iYear = 1:NumYears
    ThisYear = P(iYear);
    AreaAvgNDVI = [];
    All_NDVI = [];
    for iMonth = 1:12
	
		% Load your monthly AVHRR NDVI file
        ThisNDVI = load(['MonthQA_AVHRR_NDVI_' num2str(iMonth) '_' num2str(ThisYear) '.out']);
        ThisNDVI(find(ThisNDVI<0)) = NaN;
        for iCatch = 1:NumCatch
            All_AreaGridNDVI = [];
            indCatch = []; 
            ThisCatch = Catchments(iCatch);
            indCatch = find(GridIntersecCatch==ThisCatch); NumGrids =size(indCatch,1); % num of grids which intersected with the given catchment
            CatchLon = IntersecGrids_Lon(indCatch); 
            CatchLat = IntersecGrids_Lat(indCatch);
            CatchArea = GridIntersecCatchArea(indCatch);  TotalArea_Initial = sum(CatchArea,'all');
            TotalArea = sum(CatchArea,'all'); % Same catchment area to calculate catchments havig NaN grids

                for iGrid = 1:NumGrids
                    ThisLon = CatchLon(iGrid);
                    ThisLat = CatchLat(iGrid);
                    ThisCatchArea = CatchArea(iGrid); %Catchment area

                    %Find position of grids in NDVI matrix
                    PosLon = find(abs(LonNDVI - ThisLon) <= 0.004);
                    PosLat = find(abs(LatNDVI - ThisLat)<= 0.004);
                    GridNDVI = ThisNDVI(PosLon,PosLat); %NDVI Lon Lat

                    if isnan(GridNDVI)
                       TotalArea = (TotalArea - ThisCatchArea);
                    end
                    AreaGridNDVI = GridNDVI.*ThisCatchArea;
                    All_AreaGridNDVI(iGrid) = AreaGridNDVI;

                end
            Mat_NDVI = nansum(All_AreaGridNDVI);
                       
            %Calculate Catchment area without NaN NDVI
            AreaPercent = (TotalArea./TotalArea_Initial)*100;
            
            if AreaPercent>= 75
                AreaAvgNDVI(iCatch) = Mat_NDVI./TotalArea;  
            else
                AreaAvgNDVI(iCatch) = NaN;
            end

        end
        All_NDVI(:,iMonth) = AreaAvgNDVI;
    
    end
    Mat = [Catchments, All_NDVI]';
    dlmwrite(sprintf('MonthlyGIMMSNDVIQA_%i.csv',ThisYear), Mat, 'delimiter', ',', 'precision', 6);  
end