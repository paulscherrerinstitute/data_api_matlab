# Overview

Matlab provide a ready to use tooling to access REST APIs.
Following example shows how to retrieve data from the Epics Channel Archiver:

```Matlab
base_url = 'http://data-api.psi.ch/sf';

% Receive all available channels
url = strcat(base_url, '/channels');
data = struct('regex','.*');
options = weboptions('MediaType','application/json');
channels = webwrite(url, data, options);
disp(channels)


% Receive data
url = strcat(base_url, '/query');
% data = struct('channels', ['SWBGB-CVME-LLRF1:TEMP1';], 'range', struct('startDate', '2016-02-09T08:00:00.000+01:00', 'startNanos', 0, 'endDate', '2016-02-09T08:10:00.000+01:00', 'endNanos', 0),'dbMode', 'archiverappliance');
data = '{"channels": ["SWBGB-CVME-LLRF1:TEMP1"], "range":{"startDate":"2016-04-18T08:00:00.000+01:00",  "endDate":"2016-04-18T08:20:00.000+01:00"}}';

options = weboptions('MediaType','application/json');
display(data)
response = webwrite(url, data, options)

plot([response.data.value])
```
