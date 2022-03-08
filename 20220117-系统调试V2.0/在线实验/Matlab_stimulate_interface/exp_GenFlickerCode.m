function code = exp_GenFlickerCode(clen, freq, refresh, varargin)
% exp_GenFlickerCode(clen, freq, refresh [, type] [, phase] [, duty])
%
% In:
%   CLEN    : Code length [sample],i.e.round(refreshRate*stimDur);stimDur: s
%   
%   FREQ    : Stimulation frequency [Hz]
%
%   REFRESH : Refresh rate of display [Hz]
%
%   TYPE    : Stimulation signal type
%       'square'    : Square stimulation [1],[2]
%       'sinusoid'  : Sampled sinusoidal stimulation (default)
%
%   PHASE   : Initial phase of 'square' or 'sinusoid' signal [rad] (0<=PHASE<=2*pi). 
%
%   DUTY    : Duty cycle for 'square' stimulation model [%]
%
% Out:
%   CODE    : Flickering code (1 * CLEN)
%
% Reference:
%   [1] Y. Wang, Y. -T. Wang, T. -P. Jung,
%       "Visual stimulus design for high-rate SSVEP BCI",
%       Electron. Lett., 46(15), 1057-1058, 2010.
%   [2] M. Nakanishi, Y. Wang, Y. -T. Wang, Y. Mitsukura, T. -P. Jung,
%       "Generating Visual Flickers for Eliciting Robust Steady-State Visual
%       Evoked Potentials at Flexible Frequencies Using Monitor Refresh Rate", 
%       PLoS ONE, 9(6), e99235, 2014.
%
% Masaki Nakanishi, Swartz Center for Computational Neuroscience, Institute
% for Neural Computation, University of California, San Diego
% Date: Aug-05-2014, Update: Aug-05-2014.

if nargin < 1 || isempty(clen)
    error('stats:exp_GenFlickerCode:InputSizeMismatch', 'CLEN, FREQ, REFRESH are required.');
elseif nargin < 2 || isempty(freq)
    error('stats:exp_GenFlickerCode:InputSizeMismatch', 'FREQ, REFRESH are required.');
elseif nargin < 3 || isempty(refresh)
    error('stats:exp_GenFlickerCode:InputSizeMismatch', 'REFRESH is required.');
end % if

% Select a stimulation signal type
if nargin < 4 || isempty(varargin{1})
    type = 'sinusoid';
elseif ischar(varargin{1})
    types = {'sinusoid', 'square'};
    type_i = strmatch(lower(varargin{1}), types);
    if length(type_i) > 1
        error('stats:exp_GenFlickerCode:BadType', 'Ambiguous value for TYPE: %s', varargin{1});
    elseif isempty(type_i)
        error('stats:exp_GenFlickerCode:BadType', 'Unknown value for TYPE: %s', varargin{1});
    end % if
    type = types{type_i};
else
    error('stats:exp_GenFlickerCode:BadType', 'TYPE must be a string.');
end % if

% Set phase [0 2*pi]
if nargin < 5 || isempty(varargin{2})
    phase = 0;
elseif isnumeric(varargin{2})
    phase = wrapTo2Pi(varargin{2});
end % if
    
switch type
    
    % Generate flicker code based on square wave
    case 'square'
        if nargin < 6 || isempty(varargin{3})
            duty = 50;
        elseif isnumeric(varargin{3})
            duty = varargin{2};
        else
            error('stats:exp_GenFlickerCode:BadDuty','DUTY must be a number.');
        end % if
        
        index = 0:1:clen-1;
        tmp = square(2*pi*freq*(index/refresh)+phase, duty);
        code = (tmp>=0);
        
    % Generate flicker code based on sampled sinusoidal wave
    case 'sinusoid'
        index = 0:1:clen-1;
        tmp = cos(2*pi*freq*(index/refresh)+phase);
        %tmp = cos(2*pi*freq*(index/refresh)+phase);
        code = (tmp+1)/2;
                
end % switch model