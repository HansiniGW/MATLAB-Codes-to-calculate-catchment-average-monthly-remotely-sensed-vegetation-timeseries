clear all; close all; clc;
% This code opens 0.25degrees monthly mean VOD in each year and calculate area weighted monthly VOD over catchments

addpath 'Add the location of gridded monthly Ku-VOD data folder here';

P = 1988:2017;
NumYears = size(P,2);

LonVOD = load("Load the Longitudes of VOD dataset")';
LatVOD = load("Load the latitudes of VOD dataset")';

% Catchment
Catchments = load("Load the names of the study catchments");
NumCatch = size(Catchments,1);

% Load grid area intersected catchment details
IntersecA_details = importdata("load grid intersected catchment area details (i.e: GridIntersec25_VOD.csv)");
GridIntersecCatch = IntersecA_details.data(:,4);
GridIntersecCatchArea = IntersecA_details.data(:,5);
IntersecGrids_Lon = IntersecA_details.data(:,2);
IntersecGrids_Lat = IntersecA_details.data(:,3);


for iYear = 1:NumYears
    ThisYear = P(iYear);
    AreaAvgVOD = [];
    All_VOD = [];
    
    for iMonth = 1:12
        % Load your monthly Ku-VOD file
        ThisVOD = load(['Mean_monthlyVOD_' num2str(iMonth) '_' num2str(ThisYear) '.out']);
        
        for iCatch = 1:NumCatch
            All_AreaGridVOD = [];
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

                    %Find position of Grids in VOD matrix
                    PosLon = find(abs(LonVOD - ThisLon) <= 0.001);
                    PosLat = find(abs(LatVOD - ThisLat)<= 0.001);
                    GridVOD = ThisVOD(PosLon,PosLat); %Ku VOD Lon and Lat
                    
                    if isnan(GridVOD)
                       TotalArea = (TotalArea - ThisCatchArea);
                    end

                    AreaGridVOD = GridVOD.*ThisCatchArea;
                    All_AreaGridVOD(iGrid) = AreaGridVOD; 

                end
            Mat_VOD = nansum(All_AreaGridVOD);
            
            %Calculate Catchment area without NaN VOD
            AreaPercent = (TotalArea./TotalArea_Initial)*100;
            
            if AreaPercent>= 75
                AreaAvgVOD(iCatch) = Mat_VOD./TotalArea;  
            else
                AreaAvgVOD(iCatch) = NaN;
            end
        end
        All_VOD(:,iMonth) = AreaAvgVOD;
    
    end
    Mat = [Catchments, All_VOD]';
    dlmwrite(sprintf('Monthly_CatchKuVOD_%i.csv',ThisYear), Mat, 'delimiter', ',', 'precision', 6);
       
end