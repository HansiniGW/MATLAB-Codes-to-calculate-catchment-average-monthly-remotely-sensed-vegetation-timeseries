clear all; close all; clc;
% This code opens gridded monthly AVHRR fPAR in each year and calculate area weighted monthly fPAR over catchments

addpath 'Add the location of gridded monthly fPAR data folder here';

LonfPAR = load("Load the Longitudes of fPAR dataset");
LatfPAR = load("Load the latitudes of fPAR dataset");

P = [1981:2011]; 
NumYears = size(P,2);
% Catchment
Catchments = load("Load the names of the study catchments");
NumCatch = size(Catchments,1);

% Load grid area intersected catchment details
IntersecA_details = importdata("load grid intersected catchment area details(i.e: CatchIntersecGrid_fPAR8km.csv)");
GridIntersecCatch = IntersecA_details.data(:,4);
GridIntersecCatchArea = IntersecA_details.data(:,5);
IntersecGrids_Lon = IntersecA_details.data(:,2);
IntersecGrids_Lat = IntersecA_details.data(:,3);

%%
for iYear = 1:NumYears
    ThisYear = P(iYear);
    AreaAvgfPAR = [];
    All_fPAR = [];
    All_CatchNaN = []; All_CatchAreaPercent = [];
    for iMonth = 1:12
        % Load your monthly AVHRR fPAR file
        ThisfPAR = load(['MonthlyVic_fPAR_' num2str(iMonth) '_' num2str(ThisYear) '.out']);
        ThisfPAR(ThisfPAR==-999) = NaN;
        
        for iCatch = 1:NumCatch
            All_AreaGridfPAR = [];
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

                    %Find position of Grids in fPAR matrix
                    PosLon = find(abs(LonfPAR - ThisLon) <= 0.001);
                    PosLat = find(abs(LatfPAR - ThisLat)<= 0.001);
                    GridfPAR = ThisfPAR(PosLat,PosLon); %fPAR Lat Lon

                    if isnan(GridfPAR)
                       TotalArea = (TotalArea - ThisCatchArea);
                    end
                    AreaGridfPAR = GridfPAR.*ThisCatchArea;
                    All_AreaGridfPAR(iGrid) = AreaGridfPAR;

                end
            Mat_fPAR = nansum(All_AreaGridfPAR);
            
            % Number of missing grids
            MissingGrids = sum(isnan(All_AreaGridfPAR));
            CatchNaN(iCatch) = MissingGrids;
            
                       
            %Calculate Catchment area without NaN fPAR
            AreaPercent = (TotalArea./TotalArea_Initial)*100;
            
            % Catchment areas with Gaps
            Catchs_AreaP(iCatch) = 100 - AreaPercent;
           
            
            if AreaPercent>= 75
                AreaAvgfPAR(iCatch) = Mat_fPAR./TotalArea;  
            else
                AreaAvgfPAR(iCatch) = NaN;
            end

        end
        All_fPAR(:,iMonth) = AreaAvgfPAR;
        
    end
    Mat = [Catchments, All_fPAR]';
    dlmwrite(sprintf('MonthlyAVHRRfPAR_%i.csv',ThisYear), Mat, 'delimiter', ',', 'precision', 6);  
    
end