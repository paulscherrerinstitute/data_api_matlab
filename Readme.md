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
