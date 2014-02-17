function myPipe = basic_pipeline(varargin)
% BASIC_PIPELINE - A very basic preprocessing pipeline

import meegpipe.node.*;

nodeList = {};

%% Node 1: data import
myImporter = physioset.import.poly5;
myNode = physioset_import.new('Importer', myImporter);
nodeList = [nodeList {myNode}];

%% Node 2: Discard any data that is not EEG
myNode = subset.new('DataSelector', pset.selector.sensor_class('Class', 'EEG'));
nodeList = [nodeList {myNode}];

%% Node 3: reject bad epochs
% For whatever reason, there are large outliers at the end of the Poly5
% files. 
myCrit = bad_epochs.criterion.stat.new(...
    'Max',          @(stats) median(stats)+2*mad(stats), ...
    'EpochStat',        @(x) max(x));
myNode = bad_epochs.sliding_window(5, 5, 'Criterion', myCrit);
nodeList = [nodeList {myNode}];

%% Node 4: center
% This is not really required but will make the report of the subsequent
% filtering node more meaningful (since filter input and output will have a
% more similar dynamic range). 
nodeList = [nodeList {center.new}];

%% Node 5: Band pass filtering
myFilter = @(sr) filter.bpfilt('Fp', [1 42]/(sr/2));
myNode = filter.new('Filter', myFilter);
nodeList = [nodeList {myNode}];

%% Node 6: reject EOG components
myNode = bss.eog('RetainedVar', 99.95);
nodeList = [nodeList {myNode}];

%% Node 7: compute spectral features 
% (topographies, spectral ratios, ...)
myNode = spectra.new;
nodeList = [nodeList {myNode}];

%% Create the pipeline
myPipe = pipeline.new(...
    'Name',             'tsmi-basic-pipeline', ...
    'NodeList',         nodeList, ...
    'Save',             true, ...
    varargin{:});

end