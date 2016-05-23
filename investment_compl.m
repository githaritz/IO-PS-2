% adding path for solver
setenv('PATH_LICENSE_STRING','3413119131&Courtesy&&&USR&54784&12_1_2016&1000&PATH&GEN&31_12_2017&0_0_0&5000&0_0');
addpath('/Users/mreguant/Dropbox/TEACHING/GRAD/Econ_450_3_2016/problemsets/pset2/pathmexmaci64');

load data

T = 200; %max 200
p_actual = data(1:T,3);
q_actual = data(1:T,2);
q_wind1  = data(1:T,4);
q_wind2  = data(1:T,5);

% parameters
I = 3; %number of technologies
Tweight = data(1:T,1)/(T*1000/200);
c = [20.6;42.9;79]; %coal, gas, peaking
e = [0.95;0.35;0.80];
tax = 0;
F = [282;136;96];

% demand parameters
b = 20;
a = q_actual + b*p_actual; % choose q_actual, q_wind1, q_wind2

% variable indexes
% K_i, q_it, p_t, psi_it
% price condition, capacity condition, zero profit condition
indk = 1;
indK = I;
indq = indK+1;
indQ = indK+T*I;
inds = indQ+1;
indS = indQ+T*I;

N = indS;

% bounds
lb = zeros(N,1);
ub = Inf*ones(N,1);

% complementarities M*z + q >= 0 compl z >= 0

M = zeros(N,N); % rows: conditions, columns: # variables

M(indk:indK,inds:indS) = -kron(eye(I),Tweight');

M(indq:indQ,indq:indQ) = repmat(kron(ones(1,I),eye(T)),I,1)/b;
M(indq:indQ,inds:indS) = eye(T*I);
 
M(inds:indS,indk:indK) = kron(eye(I),ones(T,1));
M(inds:indS,indq:indQ) = -eye(T*I);

% linear
q = zeros(N,1);
q(indk:indK,1) = F;
q(indq:indQ,1) = kron(c,ones(T,1)) + kron(e,ones(T,1))*tax - repmat(a,I,1)/b;
q(inds:indS,1) = 0;

% solution
sol = pathlcp(M,q,lb,ub);

compl.sol = sol;
compl.capacity = sol(indk:indK);
compl.quantity = sol(indq:indQ);
compl.shadow = sol(inds:indS);
compl.price  = a/b - sum(reshape(compl.quantity,T,I),2)/b;
compl.demand = sum(reshape(compl.quantity,T,I),2);
compl.revenue= sum(reshape(compl.shadow,T,I).*repmat(Tweight,1,I),1);

compl.coal = [compl.shadow(1:T) compl.price compl.capacity(1)-compl.quantity(1:T,1) compl.quantity(1:T,1)];
compl.gas  = [compl.shadow(1+T:T*2) compl.price compl.capacity(2)-compl.quantity(1+T:T*2,1) compl.quantity(1+T:T*2,1)];

sum(compl.capacity)

corr(compl.price,p_actual);
scatter(compl.price,p_actual);

corr(compl.demand,q_actual);
scatter(compl.demand,q_actual);
