%% Project #1
% Authors: Adedayo Lawal and Blake Levy
clc;clear;
%% Set up Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% set up field characteristics%%%%%%%%%%%%%%%%
c = 299792458; % speed of light in free space
mu = (4*pi)*1e-7; % permiability of free space
sigma_x = 1; % conductivity for PML region X (Y)-direction
sigma_y = 1; % conductivity for PML region Y (Z)-direction
epsilon = 1/(mu*c^2); % permitivity of free space
e_top = epsilon; % relative permitivity of top slab (free space)
e_bottom = 4*epsilon; % relative permitivity of bottom slab
c_bottom = 1/sqrt(e_bottom*mu);% relative wave speed in bottom slab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% set up gaussian pulse %%%%%%%%%%%%%%%%%%%%%%
f = 1e6; % Center Frequency  of Gaussian Pulse = 1 MHz
w = 2*pi*f; % Angular Frequency Omega
sigma = 3/w; % Time and Bandwidth of the Gaussian Pulse    
t_d = 8*sigma; % Allow for the pulse to be zero at t = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% set up geometry %%%%%%%%%%%%%%%%%%%%%%%%%%%%
lambda_top = c/f; % wavelength of top slab
lambda_bottom = c_bottom/f; % wavelength of bottom slab
num_of_wavelengths = 16; % propagate 16 wavelengths in X,Y-direction
b = num_of_wavelengths*lambda_top; % Width of computational domain
a = num_of_wavelengths*lambda_top; % Height of computational domain
num_of_nodes_x = num_of_wavelengths*10;
num_of_nodes_y = num_of_nodes_x;
delx = b/num_of_nodes_x; % space discretization
dely = a/num_of_nodes_y;
delta = dely;
delt = delx/(sqrt(2)*c); % time discretization
pml_offset_x = 0; % additional thickness of boundary in X-direction
pml_offset_y = 0; % additional thickness of boundary in Y-direction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% set up E,H,T, matrices%%%%%%%%%%%%%%%%%%%%%%
E_x = zeros(2,num_of_nodes_x + 2*pml_offset_x,num_of_nodes_y + 2*pml_offset_y); % E-field - row one: L+1, row two: L
H_y = zeros(2,num_of_nodes_x + 2*pml_offset_x,num_of_nodes_y + 2*pml_offset_y); % H_y-field - row one: L+1/2, row two: L-1/2
H_z = zeros(2,num_of_nodes_x + 2*pml_offset_x,num_of_nodes_y + 2*pml_offset_y); % H_z-field - row one: L+1/2, row two: L-1/2
Time = 2*num_of_nodes_x; % total time steps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% set up Source %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
source_x = num_of_nodes_x/2; % x-position of source centered on X-axis
source_y = floor((2/3)*num_of_nodes_y); % y-position of source on top slab
J = zeros(1,Time); % create source in time-domain
for L = 2:Time
    J(L) = exp(-(((L-1)*delt-t_d)^2)/(2*sigma^2));    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for L = 1:Time % Time March
    tic; % start timer
%     for j = 1:num_of_nodes_y + 2*pml_offset_y % Z-direction (up/down)
%         for i = 1:num_of_nodes_x + 2*pml_offset_x % Y- direction (left/right)
    for j = 2:num_of_nodes_y + pml_offset_y % Z-direction (up/down)
        for i = 2:num_of_nodes_x + pml_offset_x % Y- direction (left/right)
%%%%%%%%%%%%% Boundary region of computation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if ((i >= num_of_nodes_x+2*pml_offset_x) ||...
                    (j>=num_of_nodes_y+2*pml_offset_y) || (i == 1)...
                    || (j == 1))
                location = 'boundary';
%%%%%%%%%%%%% PML region of computation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            elseif((i <= pml_offset_x) || (j <= pml_offset_y) ||...
                    (i >= num_of_nodes_x +pml_offset_x) || (j >= num_of_nodes_y + pml_offset_y))              
                location = 'PML';
%%%%%%%%%%%%% interface region of computation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
            elseif (j == num_of_nodes_y/2 + pml_offset_y)
                location = 'interface';
%%%%%%%%%%%%% source region of computation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            elseif ((i == source_x) && (j == source_y))
                location = 'source';
%%%%%%%%%%%%% lower region of computation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
            elseif j < pml_offset_y + num_of_nodes_y/2
                location = 'lower';
%%%%%%%%%%%%% upper region of computation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
            else
                location = 'upper';
            end
switch location
    case 'boundary'
        % PEC condition for boundaries, tangential E-fields are continuous
        E_x(:,i,j) = 0;
        H_y(:,i,j) = 0;
        H_z(:,i,j) = 0;
    case 'PML'
%%%%%%%%%%%%%%%%%% PML - X configuration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        if (((i < pml_offset_x) || (i > num_of_nodes_x + pml_offset_x)) &&...
                ((j < pml_offset_y + num_of_nodes_y) && (j > pml_offset_y)))
             sy = 1;
%             sx = 1 + (sigma_x/(sqrt(-1)*w*e_bottom));
%             % Finite Difference Equation (3) from our notes
%             H_z(1,i,j) = (delt/(delta*mu*sx*sy))*(E_x(2,i+1,j)-E_x(2,i,j)) + H_z(2,i,j);
%             % Finite Difference Equation (2) from our notes
%             H_y(1,i,j) = -1*(delt/(delta*mu*sx*(sy^-1)))*(E_x(2,i,j+1)-E_x(2,i,j)) + H_y(2,i,j);        
%             % Finite Difference Equation (1) from our notes (Note: no source)
%             E_x(1,i,j) = (delt/(delta*e_bottom*(sx^-1)*(sy)))*...
%                 (H_z(1,i,j)-H_z(1,i-1,j)-H_y(1,i,j)+H_y(1,i,j-1))+E_x(2,i,j);
%             E_x(1,source_x,source_y) = -1*(delt/(e_top))*J(L);               
%             
%%%%%%%%%%%%%%%%%%% PML - Y configuration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
        elseif (((i < num_of_nodes_x + pml_offset_x) && (i > pml_offset_x)) &&...
                ((j < pml_offset_y) || (j > pml_offset_y + num_of_nodes_y)))
%             sx = 1;
%             sy = 1 + (sigma_y/(sqrt(-1)*w*e_bottom));            
%             % Finite Difference Equation (3) from our notes
%             H_z(1,i,j) = (delt/(delta*mu*sx*sy))*(E_x(2,i+1,j)-E_x(2,i,j)) + H_z(2,i,j);
%             % Finite Difference Equation (2) from our notes
%             H_y(1,i,j) = -1*(delt/(delta*mu*sx*(sy^-1)))*(E_x(2,i,j+1)-E_x(2,i,j)) + H_y(2,i,j);        
%             % Finite Difference Equation (1) from our notes (Note: no source)
%             E_x(1,i,j) = (delt/(delta*e_bottom*(sx^-1)*(sy)))*...
%                 (H_z(1,i,j)-H_z(1,i-1,j)-H_y(1,i,j)+H_y(1,i,j-1))+E_x(2,i,j);
%             E_x(1,source_x,source_y) = -1*(delt/(e_top))*J(L);            
%%%%%%%%%%%%%%%%%%% PML - Corner configuration %%%%%%%%%%%%%%%%%%%%%%%%%%%%            
        else
%             sx = 1 + (sigma_x/(sqrt(-1)*w*e_bottom));                        
%             sy = 1 + (sigma_y/(sqrt(-1)*w*e_bottom));
%             % Finite Difference Equation (3) from our notes
%             H_z(1,i,j) = (delt/(delta*mu*sx*sy))*(E_x(2,i+1,j)-E_x(2,i,j)) + H_z(2,i,j);
%             % Finite Difference Equation (2) from our notes
%             H_y(1,i,j) = -1*(delt/(delta*mu*sx*(sy^-1)))*(E_x(2,i,j+1)-E_x(2,i,j)) + H_y(2,i,j);        
%             % Finite Difference Equation (1) from our notes (Note: no source)
%             E_x(1,i,j) = (delt/(delta*e_bottom*(sx^-1)*(sy)))*...
%                 (H_z(1,i,j)-H_z(1,i-1,j)-H_y(1,i,j)+H_y(1,i,j-1))+E_x(2,i,j);
%             E_x(1,source_x,source_y) = -1*(delt/(e_top))*J(L);           
            
            
        end
        
    case 'interface'
        % Finite Difference Equation (3) from our notes
        H_z(1,i,j) = (delt/(delta*mu))*(E_x(2,i+1,j)-E_x(2,i,j)) + H_z(2,i,j);
        % Finite Difference Equation (2) from our notes
        H_y(1,i,j) = -1*(delt/(delta*mu))*(E_x(2,i,j+1)-E_x(2,i,j)) + H_y(2,i,j);        
        % Finite Difference Equation (1) from our notes Note: Averaged
        % epsilon
        E_x(1,i,j) = (delt/(delta*((e_bottom+e_top)/2)))*...
            (H_z(1,i,j)-H_z(1,i-1,j)-H_y(1,i,j)+H_y(1,i,j-1))+E_x(2,i,j);
        E_x(1,source_x,source_y) = -1*(delt/e_top)*J(L);
        
    case 'source'
%         % Finite Difference Equation (3) from our notes
%         H_z(1,i,j) = (delt/(delta*mu))*(E_x(2,i+1,j)-E_x(2,i,j)) + H_z(2,i,j);
%         % Finite Difference Equation (2) from our notes
%         H_y(1,i,j) = -1*(delt/(delta*mu))*(E_x(2,i,j+1)-E_x(2,i,j)) + H_y(2,i,j);        
%         % Finite Difference Equation (1) from our notes (Source Added)
%         E_x(1,i,j) = (delt/(delta*e_top))*...
%             (H_z(1,i,j)-H_z(1,i-1,j)-H_y(1,i,j)+H_y(1,i,j-1))+E_x(2,i,j)...
%             -(delt/e_top)*J(L);        
        
        
    case 'lower'
        % Finite Difference Equation (3) from our notes
        H_z(1,i,j) = (delt/(delta*mu))*(E_x(2,i+1,j)-E_x(2,i,j)) + H_z(2,i,j);
        % Finite Difference Equation (2) from our notes
        H_y(1,i,j) = -1*(delt/(delta*mu))*(E_x(2,i,j+1)-E_x(2,i,j)) + H_y(2,i,j);        
        % Finite Difference Equation (1) from our notes (Note: no source)
        E_x(1,i,j) = (delt/(delta*e_bottom))*...
            (H_z(1,i,j)-H_z(1,i-1,j)-H_y(1,i,j)+H_y(1,i,j-1))+E_x(2,i,j);
        E_x(1,source_x,source_y) = -1*(delt/e_top)*J(L);        
                    
    case 'upper'
        % Finite Difference Equation (3) from our notes
        H_z(1,i,j) = (delt/(delta*mu))*(E_x(2,i+1,j)-E_x(2,i,j)) + H_z(2,i,j);
        % Finite Difference Equation (2) from our notes
        H_y(1,i,j) = -1*(delt/(delta*mu))*(E_x(2,i,j+1)-E_x(2,i,j)) + H_y(2,i,j);        
        % Finite Difference Equation (1) from our notes (Note: no source)
        E_x(1,i,j) = (delt/(delta*e_top))*...
            (H_z(1,i,j)-H_z(1,i-1,j)-H_y(1,i,j)+H_y(1,i,j-1))+E_x(2,i,j);
        E_x(1,source_x,source_y) = -1*(delt/e_top)*J(L);
    otherwise
        
end
        % test comment  
        end
    end
    % Update the row vectors
    H_y(2,:,:) = H_y(1,:,:);   
    H_z(2,:,:) = H_z(1,:,:);    
    E_x(2,:,:) = E_x(1,:,:);
%     display(toc); % Stop timer
    E = reshape(E_x(1,:,:),[(num_of_nodes_x + 2*pml_offset_x) (num_of_nodes_y + 2*pml_offset_y)]);
    E_comp = E((pml_offset_x+1:(num_of_nodes_x + pml_offset_y)),(pml_offset_y+1:(num_of_nodes_y + pml_offset_y)));
    H_y_latest = reshape(H_y(1,:,:),[(num_of_nodes_x + 2*pml_offset_x) (num_of_nodes_y + 2*pml_offset_y)]);
    imagesc(abs(E_comp))
    colorbar
pause(.1)
end





























