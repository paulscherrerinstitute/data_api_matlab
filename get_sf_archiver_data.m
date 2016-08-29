function [ data ] = get_sf_archiver_data( PV, from, to, mean_opt)
%get_sf_archiver_data Extracts or multiple PVs from archiver/data buffer.
%   This function can extract PVs over specified range from
%   archiver/data buffer with a time resolution of 1 seonnd.
%   It is assumed that the PVs exists only in one storage, either archiver
%   or data buffer. If exisitnng in both, the data buffer PV will be
%   retrieved.
%
%   call:
%   [ data ] = get_sf_archiver_data( PV, from, to)             % no reduction, raw retrieval
%   [ data ] = get_sf_archiver_data( PV, from, to, mean_opt)   % data reduction with mean
%
%   example call:
%   [data1] = get_sf_archiver_data({'SINEG01-RLLE-STEMP10:TEMP'}, '2016-06-06T00:00:00', '2016-06-06T01:00:00');
%   [data1] = get_sf_archiver_data({'SINEG01-RLLE-STEMP10:TEMP'}, '2016-06-06T00:00:00', '2016-06-06T01:00:00', 100);       generate mean with total 100 data points over time span
%   [data1] = get_sf_archiver_data({'SINEG01-RLLE-STEMP10:TEMP'}, '2016-06-06T00:00:00', '2016-06-06T01:00:00', 'PT60S');   generate mean with duration of 60 seconds per bin
%
%   PV      = {'SINEG01-RLLE-STEMP10:TEMP'}   struct with strings
%             {'SINEG01-RLLE-STEMP10:TEMP' 'SINEG01-RLLE-STEMP20:TEMP'}
%   from    = '2016-05-30T23:50:00'   in local time zone time CET / CEST
%   to      = '2016-05-30T23:59:59'   in local time zone time CET / CEST
%   Optional agrument:
%   mean_opt= 100      or any integer number between 1 and inf: will return exactly 100 bins with average.
%             'PT10S'  bin size for average choosen 10 seconds
%             'PT1M'   bin size for average choosen 1 minute
%             'PT1H'   bin size for average choosen 1 hour
%             'P1D'    bin size for average choosen 1 day
%             'P1W'    bin size for average choosen 1 week
%             'P1M'    bin size for average choosen 1 month
%
%   return vales:
%   data(i).
%        val        value vector
%        time       time vector
%        pulseID    pulseID vector (zeros in case of archiver appliance data)
%        N          number of data points
%        timespan   Elasped time in seconds between data start and data end
%        SR / Ts    Average sample rate in Hz and sample time in seconds
%
%    where i = number of PV's in PV string
%
%
%
%   Plot data example:
%     figure;
%     plot(data1(1).time, data1(1).val);
%     datetick('x','HH:MM','keeplimits','keepticks');
%     xlim([data1(1).time(1) data1(1).time(end)]);
%
%     Note: In case only 1 PV extracted, the (1) index can be omitted.
%
% KR84, LLRF, 7.6.2016

matlab_ver=version('-release');
if (str2num(matlab_ver(1:4)) < 2015)
    error('get_sf_archiver_data: This function works only with R2015a or newer. Use the module switch matlab/2015a command.');
end

% optional arguments
if nargin==3
    aggregation_options = ''; % no aggregation used
else
    % check type of optional argument
    if isfloat(mean_opt)
        aggregation_options= [',"aggregation":{"nrOfBins":',num2str(mean_opt),',"aggregationType":"value","aggregations":["mean"]}'];
    else
        aggregation_options= [',"aggregation":{"durationPerBin":"',mean_opt,'","aggregationType":"value","aggregations":["mean"]}'];
    end
    %aggregation_options = '';
end

% retrieve data from archiver and analyze / plot it
url = 'http://data-api.psi.ch/sf/query';


% get actual tzoffset to UTC
dnum = datetime(from,'Format','yyyy-MM-dd''T''HH:mm:ss','TimeZone','Europe/Zurich');
[dt_to_UTC current_dst] = tzoffset(dnum);


% construct string
pvnr=size(PV);
pvs = '';
for i=1:pvnr(2)
    pvs=[pvs '"' char( [PV(i)] ) '"'];
    if i<(pvnr(2))
        pvs = [pvs ','];
    end
end
json_str = ['{"channels": [' pvs,'], "range":{"startDate":"',from,'.000+0',num2str(hours(dt_to_UTC)),':00",  "endDate":"',to,'.000+0',num2str(hours(dt_to_UTC)),':00"} ', aggregation_options, '}'];

    
options = weboptions('MediaType','application/json','Timeout',86400);

% print json_str to find easily typos
try
    response = webwrite(url, json_str, options);
catch
    json_str
end

% check if response is empty
for i=1:pvnr(2)
    % check if response is empty
    if isempty(response(i).data)
        warning(['No data available: Check time range and PV name: ', json_str]);
        data = response(i).data;
    else

        
        if nargin==3
            % without mean aggregation
            data(i).val     = [response(i).data.value].';
        else
            % with mean aggregation
            temp            = [response(i).data.value].';  % frist store into temp variable because in substructure mean
            data(i).val     = [temp.mean].';               % get rid of sub structure
        end

        
        
        
        %                                           must use globalSeconds such
        %                                           that there is not differentce
        %                                           between CA and bsdata PVs.
        time_ar = str2num( cell2mat( {response(i).data.globalSeconds}.' ) );
        %                                                 sommer/winter time offset
        data(i).time    = time_ar/86400 + datenum(1970,1,1) + datenum(dt_to_UTC);



        if isequal(response(i).channel.backend,'sf-databuffer')
            data(i).pulseId = [response(i).data.pulseId].';
            pid_expected = [data(i).pulseId(1):1:data(i).pulseId(end)]';

            if ~isequal(data(i).pulseId, pid_expected)
                warning('PulseId increment error in this time range.');
                %error('PulseId increment error in this time range.');
            end

        else
            data(i).pulseId = zeros(length(data(i).time),1);
        end
    end
end


%% return values of this function






%% some statistics (average sample rate)
for i=1:pvnr(2)
    data(i).N = length(data(i).time);
    warning('off','all')
    data(i).timespan = etime( datevec(data(i).time(end),'yyyy mm dd HH:MM:SS.FFF') , datevec(data(i).time(1),'yyyy mm dd HH:MM:SS.FFF') );  % time span in seconds
    warning('on','all')
    data(i).Ts = data(i).timespan / data(i).N;
    data(i).SR = 1/data(i).Ts;
end



end

