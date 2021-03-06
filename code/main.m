%% Measuring and Modelling Evapotranspiration
% Authors:       Debora J�ckel, Simon Roth, Gabriela Sch�r, Alexandra Schuler //
%                Institute of Environmental Engineering, ETH Zurich //
%                Labor II //
% Version:       March 2013 //
% Last revision: 20. March 2013


%% Reset workspace

clear all
close all


%% Import data

lysimeter.folder = 'data/2012/lysimeter/';
lysimeter.file   = '2012_lysimeter_01.txt';
meteo.folder     = 'data/2012/meteo/';
meteo.file       = '2012_meteodata_data.txt';

% read data
lysimeter.data = dlmread( [ lysimeter.folder lysimeter.file ] );
meteo.data     = dlmread( [ meteo.folder meteo.file ], ';', 3, 1 );

% correct time shift
lysimeter.data( :, 1 ) = datenum( num2str( lysimeter.data( :, 1 ) ), 'yyyymmddHH' );
meteo.data             = [ nan( 1, size( meteo.data, 2 ) ); meteo.data ];
meteo.data             = [ lysimeter.data( :, 1 ), meteo.data( 1:end-1, 2:end ) ];


%% Analysis specification
cropFactor = 1.15;                              % [-]


%% Define constants

alpha    = 0.23;            % [-]
latitude = 47+26/60;        % [�]
Gsc      = 0.0820;          % [MJ/m2 min]
hGeo     = 443;             % [m]
sigma    = 4.903*10^-9;     % [MJ/K4 m2 d]


%% Define vectors

% time
time.h = lysimeter.data( :, 1 );
time.d = floor( dailyMean( time.h ) );
time.m = datevec( floor( monthlyMean( time.h, time.h ) ) );
time.m = datenum( time.m )-time.m( :, 3 )+1;
time.y = year( mean( time.h ) );

% storage [mm]
storage.h = gradient( lysimeter.data( :, 4 ) );
storage.d = dailySum( storage.h );
storage.m = monthlySum( storage.h, time.h );

% percolation [mm]
percol.h = lysimeter.data( :, 5 );
percol.d = dailySum( percol.h );
percol.m = monthlySum( percol.h, time.h );

% solar radiation [W/m2]
Rs.h = meteo.data( :, 5 );
Rs.d = dailyMean( Rs.h );
Rs.m = monthlyMean( Rs.h, time.h );

% pressure [hPa]
press.h = meteo.data( :, 6 );
press.d = dailyMean( press.h );
press.m = monthlyMean( press.h, time.h );

% air temperature [�C]
Tair.h    = meteo.data( :, 7 );
Tair.dMax = dailyMax( Tair.h );
Tair.dMin = dailyMin( Tair.h );
Tair.d    = ( Tair.dMax+Tair.dMin )/2;
Tair.mMax = monthlyMean( Tair.dMax, time.d );
Tair.mMin = monthlyMean( Tair.dMin, time.d );
Tair.m    = ( Tair.mMax+Tair.mMin )/2;

% precipitation [mm]
precip.h = meteo.data( :, 9 );
precip.d = dailySum( precip.h );
precip.m = monthlySum( precip.h, time.h );

% relative humidity [%]
RH.h = meteo.data( :, 10 );
RH.d = dailyMean( RH.h );
RH.m = monthlyMean( RH.h, time.h );

% wind speed [m/s]
windSp.h = meteo.data( :, 12 );
windSp.d = dailyMean( windSp.h );
windSp.m = monthlyMean( windSp.h, time.h );

clear lysimeter meteo

% mean saturation vapour pressure [kPa]
es.d = ( satVapPressure( Tair.dMax )+satVapPressure( Tair.dMin ) )/2;
es.m = ( satVapPressure( Tair.mMax )+satVapPressure( Tair.mMin ) )/2;


%% Compute evapotranspiration

% actual evapotranspiration [mm]
AET.h              = precip.h-percol.h-storage.h;
AET.h( AET.h < 0 ) = 0;
AET.d              = precip.d-percol.d-storage.d;
AET.d( AET.d < 0 ) = 0;
AET.m              = precip.m-percol.m-storage.m;
AET.m( AET.m < 0 ) = 0;

% Penman-Monteith [mm]
penMonPET.d = penmanMonteith( es.d, Tair.d, RH.d, alpha, Rs.d, time.d, latitude, Gsc, hGeo, sigma, Tair.dMax, Tair.dMin, press.d, windSp.d )*cropFactor;
penMonPET.m = penmanMonteith( es.m, Tair.m, RH.m, alpha, Rs.m, time.m, latitude, Gsc, hGeo, sigma, Tair.mMax, Tair.mMin, press.m, windSp.m )*cropFactor.*eomday( time.y, 1:12)';

% Turc [mm]
turcPET.d = turc( RH.d, Rs.d, Tair.d )*cropFactor;
turcPET.m = turc( RH.m, Rs.m, Tair.m )*cropFactor.*eomday( time.y, 1:12)';

% Ivanov [mm]
ivanovPET = ivanov( Tair, RH, cropFactor );

% Turc and Ivanov combined [mm]
turcIvanovPET.d = [ ivanovPET.d( 1:sum( eomday( time.y, 1:2 ) ) ); turcPET.d( sum( eomday( time.y, 1:2 ) )+1:sum( eomday( time.y, 1:10 ) ) ); ivanovPET.d( sum( eomday( time.y, 1:10 ) )+1:sum( eomday( time.y, 1:12 ) ) ) ];
turcIvanovPET.m = [ ivanovPET.m( 1:2 ); turcPET.m( 3:10 ); ivanovPET.m( 11:12 ) ];


%% Figures

% AET + precip, Tair, Rs, RH, windSP (week hourly)
%t = { '01.04.2012', '08.04.2012' };     % [dd.mm.yyyy]
%niceFigure( time.h, AET.h, time.h, precip.h, t )
%niceFigure( time.h, AET.h, time.h, Tair.h, t )
%niceFigure( time.h, AET.h, time.h, Rs.h, t )
%niceFigure( time.h, AET.h, time.h, RH.h, t )
%niceFigure( time.h, AET.h, time.h, windSp.h, t )

% AET + PET ( year monthly )
%t = { '01.01.2012', '31.12.2012' };     % [dd.mm.yyyy]
%niceFigure( time.m, AET.m, time.m, [ penMonPET.m, turcIvanovPET.m ], t )
%niceFigure( time.m, AET.m, time.m, [ turcPET.m, ivanovPET.m ], t )

% AET ( year monthly )
%t = { '01.01.2012', '31.12.2012' };     % [dd.mm.yyyy]
%stairs( time.m, AET.m )
%xlim( [ datenum( t( 1 ), 'dd.mm.yyyy' ) datenum( t( 2 ), 'dd.mm.yyyy' ) ] )
%datetick( 'x', 'keeplimits' )


%% Free memory

clear all