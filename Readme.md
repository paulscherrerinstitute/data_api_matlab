# Overview

This is a brief description on how to retrieve SwissFEL Epics Channel Access Archiver. SwissFEL DataBuffer, SwissFEL ImageBuffer or GLS data via the PSI data_api from Matlab.

As Matlab provides ready to use tooling to access REST APIs the access to the data api is relatively easy. Details on the data api REST API can be found on https://git.psi.ch/sf_daq/ch.psi.daq.queryrest (only accessible within PSI)

Following example shows how to retrieve data from the Epics Channel Archiver:

__Get all available channels__
```matlab
base_url = 'http://data-api.psi.ch/sf';

% Receive all available channels
url = strcat(base_url, '/channels');
data = struct('regex','.*');
options = weboptions('MediaType','application/json');
channels = webwrite(url, data, options);

disp(channels)

% channels = list of structs with the attributes backend and channels
channels(1).backend

% List all backend
for i = 1:numel(channels)         
    fprintf("%s   \n", channels(i).backend);
    % This holds all channels for this backend
    % channels(i).channels
end

% List channels of a specific backend
for i = 1:numel(channels)            
    if (strcmp(channels(i).backend, 'sf-archiverappliance'))
        disp(channels(i).channels);                
    end
end


```

__Retrieve data__

```matlab
url = strcat(base_url, '/query');
% data = struct('channels', ['SWBGB-CVME-LLRF1:TEMP1';], 'range', struct('startDate', '2016-02-09T08:00:00.000+01:00', 'startNanos', 0, 'endDate', '2016-02-09T08:10:00.000+01:00', 'endNanos', 0),'dbMode', 'archiverappliance');
data = '{"channels": ["SWBGB-CVME-LLRF1:TEMP1"], "range":{"startDate":"2016-04-18T08:00:00.000+01:00",  "endDate":"2016-04-18T08:20:00.000+01:00"}}';

options = weboptions('MediaType','application/json');
display(data)
response = webwrite(url, data, options)

plot([response.data.value])
```

The file [get_sf_archiver_data.m](get_sf_archiver_data.m) provides some more examples on how to use the API.


__Another Example__

This is an other easy way to retrieve data via Matlab:
```
base_url = 'https://data-api.psi.ch/sf-databuffer';
url = strcat(base_url, '/channels');
data = struct('regex','.*');
options = weboptions('MediaType','application/json');
options.Timeout = 560; % Man kann das variieren
channels = webwrite(url, data, options);
url = strcat(base_url, '/query');

% Beispiel PVs
ch_list = [
   '"SARCL01-DBAM110:EOM1_T1",',...
   '"SARUN20-DBAM020:EOM1_T1"'
   ];

% Beispiel Zeitbereich
archiver_range = '"startDate":"2022-02-03T13:00:00.000+01:00",  "endDate":"2022-02-03T13:01:00.000+01:00"}';

data = ['{"channels": [' ch_list '], "range":{' archiver_range ', "eventFields": ["pulseId", "globalSeconds","value"]}'];

response = webwrite(url, data, options);
```

# Additional Notes

While retrieving a lot of data, in the past, we experienced some performance penalty while using Matlab (mostly due to the deserialization). Because of this we highly encourage you to use Python to retrieve and analyze data instead of Matlab in such cases (actually in general we encourage the use of the Python library over Matlab).

The documentation of the Python library you can find here: https://github.com/paulscherrerinstitute/data_api_python
