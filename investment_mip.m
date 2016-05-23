% adding path for solver
addpath('/Users/mreguant/Applications/IBM/ILOG/CPLEX_Studio1262/cplex/examples/src/matlab');
addpath('/Users/mreguant/Applications/IBM/ILOG/CPLEX_Studio1262/cplex/matlab/x86-64_osx/');

load data

T = 200; %200 max
p_actual = data(1:T,3);
q_actual = data(1:T,2);
q_wind1  = data(1:T,4);
q_wind2  = data(1:T,5);

% parameters
I = 3;
Tweight = data(1:T,1)/(T*1000/200);
c = [20.6;42.9;79]; %coal, gas, peaking
F = [282;136;96];

% penalties
M1 = 1e5;
M2 = 1e5;
M3 = 1e5;

% demand data
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
Nvar = indS*2;

% type
ctype = [repmat('C',1,N) repmat('I',1,N)];

% bounds
lb = zeros(2*N,1);
ub = [Inf*ones(N,1); ones(N,1)];

% no objective function
f = zeros(Nvar,1);

% inequalities for variables (N inequalities <=)
Aineq1 = zeros(N,Nvar);

Aineq1(indk:indK,inds:indS) = kron(eye(I),Tweight');

Aineq1(indq:indQ,indq:indQ) = -repmat(kron(ones(1,I),eye(T)),I,1)/b;
Aineq1(indq:indQ,inds:indS) = -eye(T*I);
 
Aineq1(inds:indS,indk:indK) = -kron(eye(I),ones(T,1));
Aineq1(inds:indS,indq:indQ) = eye(T*I);

bineq1 = zeros(N,1);
bineq1(indk:indK,1) = F;
bineq1(indq:indQ,1) = kron(c,ones(T,1)) - repmat(a,I,1)/b;

% complementarities 1 (2N inequalities with integer variables <=)
Aineq2 = zeros(N,Nvar);

Aineq2(indk:indK,inds:indS) = -kron(eye(I),Tweight');
Aineq2(indk:indK,N+indk:N+indK) = -M1*eye(I);

Aineq2(indq:indQ,indq:indQ) = repmat(kron(ones(1,I),eye(T)),I,1)/b;
Aineq2(indq:indQ,inds:indS) = eye(T*I);
Aineq2(indq:indQ,N+indq:N+indQ) = -M2*eye(T*I);
 
Aineq2(inds:indS,indk:indK) = kron(eye(I),ones(T,1));
Aineq2(inds:indS,indq:indQ) = -eye(T*I);
Aineq2(inds:indS,N+inds:N+indS) = -M3*eye(T*I);

bineq2 = zeros(N,1);
bineq2(indk:indK,1) = - F;
bineq2(indq:indQ,1) = - kron(c,ones(T,1)) + repmat(a,I,1)/b;

% complementarities 2
Aineq3 = zeros(N,Nvar);

Aineq3(indk:indK,indk:indK) = eye(I);
Aineq3(indk:indK,N+indk:N+indK) = M1*eye(I);

Aineq3(indq:indQ,indq:indQ) = eye(T*I);
Aineq3(indq:indQ,N+indq:N+indQ) = M2*eye(I*T);

Aineq3(inds:indS,inds:indS) = eye(I*T);
Aineq3(inds:indS,N+inds:N+indS) = M3*eye(I*T);

bineq3(indk:indK,1) = M1;
bineq3(indq:indQ,1) = M2;
bineq3(inds:indS,1) = M3;

% put together
Aineq = [Aineq1;Aineq2;Aineq3];
bineq = [bineq1;bineq2;bineq3];

% solution
sol = cplexmilp(f, Aineq, bineq, [], [], [], [], [], lb, ub, ctype, []);

mip.sol = sol;
mip.capacity = sol(indk:indK);
mip.quantity = sol(indq:indQ);
mip.shadow = sol(inds:indS);
mip.price  = a/b - sum(reshape(mip.quantity,T,I),2)/b;
mip.demand = sum(reshape(mip.quantity,T,I),2);
mip.revenue= sum(reshape(mip.shadow,T,I).*repmat(Tweight,1,I),1);

mip.coal = [mip.shadow(1:T) mip.price mip.capacity(1)-mip.quantity(1:T,1) mip.quantity(1:T,1)];
mip.gas  = [mip.shadow(1+T:T*2) mip.price mip.capacity(2)-mip.quantity(1+T:T*2,1) mip.quantity(1+T:T*2,1)];

sum(mip.capacity)

corr(mip.price,p_actual)
figure(1);
scatter(mip.price,p_actual);

corr(mip.demand,q_actual)
figure(2);
scatter(mip.demand,q_actual);
