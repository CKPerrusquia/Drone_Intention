% Dynamic Mode Decomposition for Trajectory Intent Prediction
% Transform the nonlinear drone model to a linear one for predictions
% Required data: X, U , Xd
% X: Drone states (linear positions and velocities)
% U: Drone inputs (roll, pitch, yaw and thrust)
% Xd: Desired reference (positions and velocities)

clc
close all
clear

% Seed to obtain the same results
rng(800)

% Load the data
Data = load('Drone1/X_tray_4.mat');
Data2 = load('Drone1/X_tray.mat');

% Corrupt the data with noise to emulate sensor noise
StateData = Data.X + 1e-1*std(Data.X,[],'all').*randn(size(Data.X));
InputData = Data.U + 1e-2*std(Data.U,[],'all').*randn(size(Data.U));

% Create the data matrices for the DMDc
X = StateData(:, 1:end-1); % States in instance k
X_prime = StateData(:, 2:end); % States in instance k+1
Ups = InputData(:, 1 :end-1); % Control inputs

Omega = [X;Ups]; % Concatenate States and Control Matrices

% SVD of Omega
[U, Sig, V] = svd(Omega, 'econ');

% Check that the singular values are greater than a threshold
thresh = 1e-10;
rtil = length(find(diag(Sig) > thresh));

% Consider only the dimensions that satisfy the threshold
Util = U(:, 1:rtil);
Sigtil = Sig(1:rtil, 1:rtil);
Vtil = V(:, 1: rtil);

% SVD of the future states
[U, Sig, V] = svd(X_prime, 'econ');

% Check that the singular values are greater than a threshold
r = length(find(diag(Sig) > thresh));
Uhat = U(:, 1: r);
Shat = Sig(1:r, 1:r);
Vhat = V(:, 1:r);

% Separate the matrices A and B
n = size(X, 1);  % Number of states
m = size(Ups, 1); % Number of inputs

% Left singular vectors for each matrix
U1 = Util(1:n, :);
U2 = Util(1+n: n+m, :);

% Estimated linear matrices
Aest = X_prime*Vtil*pinv(Sigtil)*U1.';
Best = X_prime*Vtil*pinv(Sigtil)*U2.';

% Desired reference
Xd = Data.Xd(1:6, 1: end-1);

% Estimate the control input with a discrete LQR controller

Q = diag([1, 1, 1, 0.001, 0.001, 0.001]); % States weight matrix
R = diag([0.001, 0.001, 0.001, 0.001]); % Control input weight matrix

% Solve a Discrete Algebraic Ricatti Equation
[~ , ~, K] = dare(Aest, Best, Q, R);

% Final linear model obtained from the data
x(:,1) = Xd(:,1); % Initial state same as the initial data of X

for i=1:length(Xd)
    % Linear moel with linear controller
    x(:,i+1) = Aest*x(:,i) + Best*K*(Xd(:,i)-x(:,i));
end


% Plots of the state estimations and predictions
% Sampling time 0.02 s
t = linspace(0, length(Xd)*0.02, length(Xd));
Uest = K*(Xd-x(:,1:end-1));

K1 = Uest*pinv(Xd- x(:, 1:end-1));
c1 = 0.7*[1 1 1];

% Control Roll (rad)
figure(1)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,Ups(1,:), 'linewidth', 2, 'Color', c1)
hold on
plot(t,Uest(1,:), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Roll $\phi$ (rad)'}, 'interpreter', 'latex');
legend({'Ground truth', 'DMD-LQR Estimation'}, ...
     'interpreter','latex');
set(gca,'fontsize', 14);
axis([0 120 -0.2 0.2]);

% Control Pitch (rad)
figure(2)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,Ups(2,:), 'linewidth', 2, 'Color', c1)
hold on
plot(t,Uest(2,:), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Pitch $\theta$ (rad)'}, 'interpreter', 'latex');
legend({'Ground truth', 'DMD-LQR Estimation'}, ...
     'interpreter','latex');
set(gca,'fontsize', 14);
axis([0 120 -0.25 0.25]);

% Control Yaw (rad)
figure(3)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,Ups(3,:), 'linewidth', 2, 'Color', c1)
hold on
plot(t,Uest(3,:), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Yaw $\psi$ (rad)'}, 'interpreter', 'latex');
legend({'Ground truth', 'DMD-LQR Estimation'}, ...
     'interpreter','latex');
set(gca,'fontsize', 14);
axis([0 120 -0.2 0.2]);

% Control Thrust (N)
figure(4)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,Ups(4,:), 'linewidth', 2, 'Color', c1)
hold on
plot(t,Uest(4,:), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Thrust $\mu$ (N)'}, 'interpreter', 'latex');
legend({'Ground truth', 'DMD-LQR Estimation'}, ...
     'interpreter','latex');
set(gca,'fontsize', 14);

% Position in X
figure(5)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,X_prime(1,:), 'linewidth', 2, 'Color', c1)
hold on
plot(t,x(1,2:end), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Position in $X$ (m)'}, 'interpreter', 'latex');
legend({'Ground truth', 'DMD-LQR Estimation'}, ...
     'interpreter','latex');
set(gca,'fontsize', 14);
axis([0 120 -2 2]);

% Position in Y
figure(6)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,X_prime(2,:), 'linewidth', 2, 'Color', c1)
hold on
plot(t,x(2,2:end), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Position in $Y$ (m)'}, 'interpreter', 'latex');
legend({'Ground truth', 'DMD-LQR Estimation'}, ...
     'interpreter','latex');
set(gca,'fontsize', 14);
axis([0 120 -2 2]);

% Position in Z
figure(7)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,X_prime(3,:), 'linewidth', 2, 'Color', c1)
hold on
plot(t,x(3,2:end), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Position in $Z$ (m)'}, 'interpreter', 'latex');
legend({'Ground truth', 'DMD-LQR Estimation'}, ...
     'interpreter','latex');
set(gca,'fontsize', 14);
axis([0 120 -5 5]);

% Verify the model in different trajectories
% Corrupt the data with noise to emulate sensor noise
StateData2 = Data2.X + 1e-1*std(Data2.X,[],'all').*randn(size(Data2.X));
Xd = Data2.Xd(1:6, 1: end-1);

X2 = StateData2(:, 2:end); 
X_prime2 = StateData2(:, 2:end); % States in instance k+1

% Final linear model obtained from the data
x(:,1) = Xd(:,1); % Initial state same as the initial data of X

for i=1:length(Xd)
    % Linear moel with linear controller
    x(:,i+1) = Aest*x(:,i) + Best*K*(Xd(:,i)-x(:,i));
end


% Plots of the state estimations and predictions
% Sampling time 0.02 s
t = linspace(0, length(Xd)*0.02, length(Xd));
Uest = K*(Xd-x(:,1:end-1));
c1 = 0.7*[1 1 1];

% Position in X
figure(8)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,X_prime2(1,:), 'linewidth', 2, 'Color', c1)
hold on
plot(t,x(1,2:end), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Position in $X$ (m)'}, 'interpreter', 'latex');
legend({'Ground truth', 'DMD-LQR Estimation'}, ...
     'interpreter','latex');
set(gca,'fontsize', 14);
axis([0 120 -5.5 5.5]);

% Position in Y
figure(9)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,X_prime2(2,:), 'linewidth', 2, 'Color', c1)
hold on
plot(t,x(2,2:end), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Position in $Y$ (m)'}, 'interpreter', 'latex');
legend({'Ground truth', 'DMD-LQR Estimation'}, ...
     'interpreter','latex');
set(gca,'fontsize', 14);
axis([0 120 -5 5]);

% Position in Z
figure(10)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,X_prime2(3,:), 'linewidth', 2, 'Color', c1)
hold on
plot(t,x(3,2:end), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Position in $Z$ (m)'}, 'interpreter', 'latex');
legend({'Ground truth', 'DMD-LQR Estimation'}, ...
     'interpreter','latex');
set(gca,'fontsize', 14);
axis([0 120 -3 2]);

% Control Roll (rad)
figure(11)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,Uest(1,:), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Roll $\phi$ (rad)'}, 'interpreter', 'latex');
set(gca,'fontsize', 14);

% Control Pitch (rad)
figure(12)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,Uest(2,:), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Pitch $\theta$ (rad)'}, 'interpreter', 'latex');
set(gca,'fontsize', 14);

% Control Yaw (rad)
figure(13)
set(gcf,'Position',[100 100 500 200])
set(gcf,'PaperPositionMode','auto')
plot(t,Uest(3,:), 'r', 'LineWidth', 2)
grid on;
xlabel({'Time (s)'}, 'interpreter', 'latex');
ylabel({'Yaw $\psi$ (rad)'}, 'interpreter', 'latex');
set(gca,'fontsize', 14);