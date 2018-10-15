%% WAVELET PACKET DECOMPOSITION TEST FOR PERFECT RECONSTRUTION

addpath 'Common';             % Functions in Common folder
 clear all; close all

% Testing Signal

d = 256;        %Total signal length
t=0:0.001:10;
un=20*(t.^2).*(1-t).^4.*cos(12*t.*pi)+sin(2*pi*t*5000)+sin(2*pi*t*150);
un = un(1:d)';
Ovr = 1; 


%% wavpack parameters

mu = 0.1;                      % ignored here 
M = 256;                        % Length of unknown system response also ignored here
level = 5;                     % Levels of Wavelet decomposition
filters = 'db1';               % Set wavelet type


S = QMFInit(M,mu,level,filters);
%S = SWAFinit(M, mu, level, filters); 

M = S.length;                     % Unknown system length (Equivalent adpative filter lenght)

F = S.analysis;                   % Analysis filter bank
H = S.synthesis;                  % Synthesis filter bank 


%% petraglia aliasing free structure adaptation

% filters for the aliasing free bank 

%upsampled filters


% %check for two layers
check_H_extd = cat(2, conv(H(:,1), upsample(H(:,1),2)), conv(H(:,1), upsample(H(:,2),2)), conv(H(:,2), upsample(H(:,1),2)), conv(H(:,2), upsample(H(:,2),2)) ); 
% H0, H1, H2, H3, H4

check_H_extd = check_H_extd(1:end-1,:);

check_H_af = cat(2, conv(check_H_extd(:,1), check_H_extd(:,1)), conv(check_H_extd(:,1), check_H_extd(:,2)), ...
                conv(check_H_extd(:,2), check_H_extd(:,2)),  conv(check_H_extd(:,2), check_H_extd(:,3)), ...
                  conv(check_H_extd(:,3), check_H_extd(:,3)),  conv(check_H_extd(:,3), check_H_extd(:,4)), ...
                   conv(check_H_extd(:,4), check_H_extd(:,4))   ); 


%F = cat(2, conv(F(:,1), upsample(F(:,1),2)), conv(F(:,1), upsample(F(:,2),2)), conv(F(:,2), upsample(F(:,1),2)), conv(F(:,2), upsample(F(:,2),2)) ); 
  

%check one layer
% H_af = cat(2, conv(H(:,1), H(:,1)), conv(H(:,1), H(:,2)), conv(H(:,2), H(:,2))); 


% equivalent filters in one level: 


Hi = zeros(2^(level-1)*size(H,1), 2^(level));

indx = 1;

for i = 1:size(H,2)
for j=1:level-1
    
   up{i,j} = upsample(H(:,i), 2^(j)); 
   
   
end
end

% upsampled versions 
% HAAR example for lvl 2: 
% 1+z^-2  1+z^-4
% 1-      1- 

% outer product
H_tmp = H; 
for i=1:size(up,2)

H_tmp = outer_conv(H_tmp, up(:,i));
end

Hi = H_tmp(1:find(H_tmp(:,1), 1, 'last'),:); % bug works only db1 

% for k=1:size(up,2)  
%     
%     
% 
% % for i=1:size(H_temp,2)
% %     
% %     tmp = H_temp(:,i);
% %     
% %     for j=1:size(up,1)                  
% %     
% %     tmp = conv(tmp1, up{j,k});
% %     H_tmp{indx} = tmp(1:find(tmp, 1, 'last'),:);
% %     indx = indx +1; 
% %      
% %     end
%     
%     
%     
% end 
% 
%    Hi(:, indx) = tmp(1:find(tmp, 1, 'last'),:); % strip zeros
%     indx = indx + 1;  
% 
% end





% indx =1 ; 
% 
% for i=1:size(H(:,2))
%     
%     
%     
% for k=1:size(H(:,2))
%     
%     tmp=H(:,i);
%     
%     
% for j=2:level
%     
%     tmp = conv(tmp, upsample(H(:,k), 2^(j-1)));
%     
%     tmp = tmp(1:find(tmp, 1, 'last'),:); % strip zeros
% 
%  
% end
% 
% 
% 
% Hi(:,indx) = tmp; 
% indx = indx+1; 
% 
% end
% 
% end

Fi = flip(Hi); 

% analysis and synthesis are used in reverse to obtain in U.Z a column
% vector with cD in the first position

[len, ~] = size(Hi); 

level = S.levels;                 % Wavelet Levels
L = S.L.*Ovr;                     % Wavelet decomposition Length, sufilter length [cAn cDn cDn-1 ... cD1 M]

% Init Arrays

% everything is brought to the first level
    
U_c = zeros(L(end-level),2^level);            
eDr = zeros(len,1);          % Error signal, time domain
delay = 1;                    % Level delay for synthesis
           
w = zeros(L(end-level),2^level);           % Last level has 2 columns, cD and cA

w(1,:) = 1;                   % set filters to kronecker delta

eD = zeros(1,2^level);              % Last level has 2 columns, cD and cA

pwr = w;
beta = 1./L(2:end-1);

u = zeros(len,1);                 % Tapped-delay line of input signal (Analysis FB)  

ITER = length(un);
en = zeros(1,ITER);               % Initialize error sequence to zero


for n = 1:ITER    
    u = [un(n); u(1:end-1)];        % Input signal vector contains [u(n),u(n-1),...,u(n-M+1)]'

    % Analysis Bank
    U.tmp = u;
    
        if mod(n,2^level) == 0
            
            
            U.Z = Hi'*U.tmp; % column [cD ; cA] 
            
         
            [rows, cols] = size(U.Z);
            
            indx = 1;
            
            for col=1:cols
                for row=1:rows 
                    
                    U_c(:,indx) = cat(1,U.Z(row,col), U_c(1:end-1, indx)); %CD||CA
        
                indx=indx+1;
                end  
            end
            
            %U.tmp = U_c(1:len,:);    
            
            direct = zeros(1 ,2^level); 
            
            indx = 1; 
            
            % direct nodes 
            for j=1:1:size(U_c,2)
            direct(:,indx) = sum(U_c(:,j).*w(:,indx));
            indx = indx +1; 
            end
                   
            eD = direct' ; 
                
            % Synthesis 
            eDr = Fi*eD ;
           
            S.iter{1} = S.iter{1} + 1;  
            
            en(n-2^level+1:n) = eDr(1:2^level);
            
        end
        
     
end
en = en(1:ITER);


%% check for perfect reconstruction

tot_delay = 1;%(2^level - 1)*(len-1) +1 ;

stem(en(tot_delay:end));
hold on;
stem(un); 

