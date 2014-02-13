function params = PplotParamLog(P, varargin)
%PPLOTPARAMLOG_COLOR plots the value of each parameter separately.
% 
% Synopsis: params = PplotParamLog(P, [params, [Pall, [method[, title]]]])
% 
% Inputs:
%  - P      : the parameter set for which parameter values are plotted
%  - params : (Optional, default or empty=P.ParamList) names or indexes in
%             P of the parameter to be plotted. Unvalid parameter names or
%             indexes are not plotted
%  - Pall   : (Optional, default or empty=min and max of values) parameter
%             set used to define the lower and upper bound of the plot of
%             each parameter. It must contain only one parameter vector. It
%             is used only for parameter which are uncertain parameter of
%             Pall. Otherwise, the minimal and maximal value of parameter
%             in P is considered.
%  - method : (Optional, default or empty='color') string describing the
%             method used to plot parameter values. It must be either
%             'color' or 'star'.
%  - title  : (Optional, default='') string describing the title shown at
%             the top of the figure. It is interpreted with TeX
%             interpretor.
% 
% Output:
%  - params : a cell array containing the name of plotted parameter
% 
% Example (Lorentz84):
%   CreateSystem;
%   P = CreateParamSet(Sys,{'a','b'},[1,10;10,100]);
%   P = SetParam(P,{'x0','x1','x2'},[1;1;1]);
%   P = Refine(P,10);
%   PplotParamLog(P); % plot repartition (on log scale)
%   
%   P = CreateParamSet(Sys,{'a','b'},[1,10;10,100]);
%   P = SetParam(P,{'x0','x1','x2'},[1;1;1]);
%   P = RandomLogRefine(P,10);
%   PplotParamLog(P,{'x0','a','b'}); % homogeneous repartition (on log scale)
% 
%See also SplotVar SplotTraj
%

if(nargin>=4)
    method = varargin{3};
    varargin(3) = []; % remove the method from varargin
    if strcmpi(method,'star')
        params = PplotParamLog_star(P,varargin{:});
    else
        params = PplotParamLog_color(P,varargin{:});
    end
else
    params = PplotParamLog_color(P,varargin{:});
end

end

function params = PplotParamLog_color(P, params, Pall, title_str)
%PPLOTPARAMLOG_COLOR plots the value of each parameter separately.
% 
% Synopsis: params = PplotParamLog(P[, params[, Pall[, title_str]]])
% 
% Inputs:
%  - P      : the parameter set for which parameter values are plotted
%  - params : parameter to plot
%  - Pall   : parameter set describing the interval of the parameter
% 
% Output:
%  - params : name of plotted parameters
%

if ~exist('params','var')
    params = {};
elseif ischar(params)
    params = {params};
elseif ~iscell(params)
    params = P.ParamList(params);
end
valid = ismember(params,P.ParamList);
params = params(valid);
if isempty(params)
    params = P.ParamList;
end
nParam = numel(params);

figure(gcf);
nParamVect = size(P.pts,2);
toRemove = floor(nParamVect*.125); % colormap part to remove to avoid dark colors
my_map = jet(nParamVect+2*toRemove+1);
my_map = my_map(1+toRemove:end-toRemove,:); %size(my_map,2) must be nParamVect+1
my_map(1,:) = [1,1,1]; % lowest color is white
colormap(my_map); % define the color map associated to the figure

for ii = 1:nParam
    subplot(nParam,1,ii); % one subplot for each parameter
    param = params{ii};
    val_log = log10(GetParam(P,param)); % param value on log scale
    
    % clean val_log values
    vl_real = arrayfun(@(x) isreal(x{:}), num2cell(val_log)); % remove complex
    if any(~vl_real)
        warning('PplotParamLog:negativeValue',...
            'A value for parameter %s is negative, it is removed.',param);
        val_log = val_log(vl_real);
    end
    vl_inf = isinf(val_log); % remove inf
    if any(vl_inf)
        warning('PplotParamLog:infiniteValue',...
            'A value for parameter %s is 0 or Inf, it is removed.',param);
        val_log = val_log(~vl_inf);
    end
    
    % define graph upper and lower bound
    if( exist('Pall','var') && ~isempty(Pall) && ~isempty(GetEpsi(Pall,param)) )
        ptsAll = GetParam(Pall,param);
        epsiAll = GetEpsi(Pall,param);
        vl_min = log10(ptsAll-epsiAll);
        vl_max = log10(ptsAll+epsiAll);
        if(isinf(vl_min) || ~isreal(vl_min))
            warning('PplotParamLog:badLowerLimit',...
                'The lower bound for parameter %s is <=0 or Inf, set to lowest valid value of param set.',param);
            vl_min = min(val_log);
        end
        if(isinf(vl_max) || ~isreal(vl_max))
            warning('PplotParamLog:badLowerLimit',...
                'The upper bound for parameter %s is <=0 or Inf, set to highest valid value of param set.',param);
            vl_max = max(val_log);
        end
        if(min(val_log)<vl_min)
            warning('PplotParamLog:badLowerBound',...
                'Some parameter values for %s are lower than the interval.',param);
        end
        if(max(val_log)>vl_max)
            warning('PplotParamLog:badUpperBound',...
                'Some parameter values for %s are higher than the interval.',param);
        end
    else
        vl_min = min(val_log);
        vl_max = max(val_log);
    end
    if(abs(vl_max-vl_min)<0.1) % in case of a singular point
        if(vl_min>0)
            vl_min = vl_min/1.02;
        elseif(vl_min==0)
            vl_min = -0.05;
        else
            vl_min = vl_min*1.02;
        end
        if(vl_max>0)
            vl_max = vl_max*1.02;
        elseif(vl_max==0)
            vl_max=0.05;
        else
            vl_max = vl_max/1.02;
        end
    end
    
    % check validity of parameter
    if isempty(val_log)
        box on;
        set(gca,'XTick',[],'YTick',[]); % display empty graph
        ylabel(param,'Interpreter','none','Rotation',0,'HorizontalAlignment','Right');
        continue;
    end
    
    % compute repartition
    N = 15; % == number of spliting intervals
    edge = [-Inf,vl_min+(1:N-1).*((vl_max-vl_min)/N),Inf]; % numel(edge)==N+1
    histo = histc(val_log,edge); % histo(end) is numel(find(val_log==Inf)) is 0
    
    % define bar x-values
    edge(1) = vl_min;
    edge(end) = vl_max;
    edge = (edge(1:end-1)+edge(2:end))/2; % middle of edge (numel(edge)=N)
    
    % plot
    h = bar(edge,ones(1,N),1);
    delete(findobj('marker','*')) % delete all (unwanted) stars on x axis (maybe not mandatory)
    set(gca,'XLim',[vl_min,vl_max],'YLim',[0,1]); % so the bar fill all vertical space
    
    % define the colors
    caxis([0,nParamVect]); % define the range of color value for the current axis
    bar_child = get(h,'Children');
    set(bar_child,'CData',histo(1:end-1)) % define the color for each bar
    
    % define and print ticks
    set(gca,'YTick',[]);
    set(gca,'TickDir','out','TickLength',get(gca,'TickLength').*2./3);
    XTick = ceil(vl_min):floor(vl_max);
    %if(numel(XTick)>10) % if too much ticks, we remove some
    %    XTick = ceil(vl_min):2:floor(vl_max);
    %    if(XTick(end)~=floor(vl_max))
    %        XTick = [XTick,floor(vl_max)];
    %    end
    %end
    if(10^vl_min<0.96*10^ceil(vl_min)) % if far enougth from last tick
        XTick = [vl_min,XTick];
    end
    if(10^vl_max>1.04*10^floor(vl_max)) % if far enougth from last tick
        XTick = [XTick,vl_max];
    end
    XTickLabel = cellstr(num2str((10.^XTick)','%.1e'))'; % convert to cell array with strings
    % we may improve XTickLabel by showing a "text" based on LaTeX such
    % that if XTick is integer XTickLabel is 10^XTick, and a.10^b otherwise
    set(gca,'XTick',XTick);
    set(gca,'XTicklabel',XTickLabel);
    box off;
    
    ylabel(param,'Interpreter','none','Rotation',0,'HorizontalAlignment','Right');
    if(ii==1 && exist('title_str','var'))
        title(title_str);
    end
end

% print a colorbar in an other windows.
% All this part is based on matlab default values
figure();
axis off
pos = get(gcf,'Position');
set(gcf,'Position', [pos(1), pos(2), pos(3)/5, pos(4)]);
caxis([0,100]); % define lowest and highest color
colormap(my_map);
%title('Legend');
cb = colorbar();
x1=get(gca,'position'); % set colorbar width (code get from matlab website)
x=get(cb,'Position');
x(1)=x(1)/2;
x(3)=x(3)*5;
set(cb,'Position',x)
set(gca,'position',x1)

end


function params = PplotParamLog_star(P, params, Pall, title_str)
%PPLOTPARAMLOG_STAR plots a each parameter separately. For each parameter,
% a star is drawn at the value of the parameter
% 
% Synopsis: params = PplotParamLog_star(P[, params[, Pall[, title_str]]])
%

if ~exist('params','var')
    params = {};
elseif ischar(params)
    params = {params};
elseif ~iscell(params)
    params = P.ParamList(params);
end
valid = ismember(params,P.ParamList);
params = params(valid);
if isempty(params)
    params = P.ParamList;
end
nParam = numel(params);

figure(gcf);
for ii = 1:nParam
    param = params{ii};
    val = GetParam(P,param);

    subplot(numel(P.ParamList),1,ii);
    plot(val,ones(1,numel(val)),'*');
    if(exist('Pall','var')&&~isempty(Pall))
        epsiAll = GetEpsi(Pall,param);
        if ~isempty(epsiAll)
            ptsAll = GetParam(Pall,param);
            set(gca,'XLim',[ptsAll-epsiAll,ptsAll+epsiAll]);
        end
    end
    set(gca,'XScale','log','YTick',[]);
    ylabel(param,'Interpreter','none','Rotation',0,'HorizontalAlignment','Right');
    if(ii==1 && exist('title_str','var'))
        title(title_str);
    end
    
end

end
