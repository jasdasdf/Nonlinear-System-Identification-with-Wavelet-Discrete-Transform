function [en,S] = WAFadapt(un,dn,S)

% WSAFadapt         Wavelet-transformed Subband Adaptive Filter (WAF)
%                   Transformation with an orthogonal matrix W.                    
%
% Arguments:
% un                Input signal
% dn                Desired signal
% S                 Adptive filter parameters as defined in WSAFinit.m
% en                History of error signal

M = length(S.coeffs);
mu = S.step;                     % Step Size
alpha = S.alpha';                 % Small constant
beta = S.beta;                   % Forgettig factor
AdaptStart = S.AdaptStart;
W = S.W;                         % Transform Matrix
L = S.levels;                    % Wavelet Levels
w = S.coeffs;                    % Adaptive filtering

u = zeros(M,1);
power_vec = zeros(M,1);

ITER = length(un);
yn = zeros(1,ITER);                 % Initialize output sequence to zero
en = zeros(1,ITER);                 % Initialize error sequence to zero

b = S.unknownsys;
norm_Wb = norm(W*b);
eml = zeros(1,ITER);                % System error norm (normalized)

% Len = zeros(L,1);                   % Each subband lenght [cAn cDn cDn-1 ... cD1]
% for i= 1:L
%     Len = [M/(2^i); Len(1:end-1)];
% end
% Len = [Len(1); Len]';

for n = 1:ITER    
    u = [un(n); u(1:end-1)];        % Input signal vector contains [u(n),u(n-1),...,u(n-M+1)]'%     
    U = W*u;                        % Transformed (DWT) input vector [Mx1]    

    yn(n) = w'*U;                   % Output signal
    en(n) = dn(n) - yn(n);          % Estimation error

    eml(n) = norm(W*b-w)/norm_Wb;   % System error norm (normalized)
        
    if n >= AdaptStart
%         P = [ones(64,1)*norm(U(1:64)); ones(64,1)*norm(U(65:128)); ones(128,1)*norm(U(129:end))]; %Estimated power each subband
%         power_vec =  beta*power_vec + (1-beta)*P;        
        
        power_vec= beta*power_vec+(1-beta)*(U.*U);	% Estimated power                                    
        inv_sqrt_power = 1./(sqrt(power_vec+alpha));
        
        w = w + (mu*en(n)*inv_sqrt_power).*U; % Tap-weight adaptation        
        S.iter = S.iter + 1;  
        
    if mod(n,5000)== 0
        plot(10*log10(en.^2));
        xlabel('Number of iteration'); 
        ylabel('Live MSE error (dB)');    
        linkdata on %Live plotting      
    end
   
    end
end


en = en(1:ITER);
S.coeffs = w;
S.eml = eml;
end


    