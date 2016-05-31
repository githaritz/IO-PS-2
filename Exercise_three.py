#!/usr/bin/python
'''
This is a simple example to show how to use constrained mixed integer programs using
Gurobi.

Coded by Mar Reguant, May 2016
'''
from gurobipy import *
import pandas as pd

# read data
df = pd.read_csv('/Users/nilka/Dropbox/python/dta3.csv')

# parameters
T = df.shape[0]  # time periods
df.wind = df.q_act - df.wind1
df.weight = df.weight / (1000.0)  # weight for each period
#df.cap = df.wind1/(max(df.wind1))
df.cap = df.wind/(max(df.wind))
# df.cap = df.random
I = 4   # number of technologies
c = [20.6, 42.9, 79.0, 0]  # coal, gas, peaking,
F = [282.0, 136.0, 96.0, 100]  # fixed cost per MW
s = 0#subsidy for wind
M = 10e6  # large number
# demand parameters
b = 20.0  # slope
a = df.q_act + b * df.p_act  # intercept

# set up model
m = Model("investment_example")
m.setParam("OutputFlag", 1)
m.setParam("Threads", 4)

# variables
capacity = {}
for i in range(I):
    capacity[i] = m.addVar(lb=0, vtype=GRB.CONTINUOUS)

price = {}
for t in range(T):
    price[t] = m.addVar(lb=0, vtype=GRB.CONTINUOUS)

shadow = {}
quantity = {}
for i in range(I):
    for t in range(T):
        shadow[i, t] = m.addVar(lb=0, vtype=GRB.CONTINUOUS)
        quantity[i, t] = m.addVar(lb=0, vtype=GRB.CONTINUOUS)

# auxiliary integer variables for complementarities
u1 = {}
u2 = {}
u3 = {}
for i in range(I):
    u3[i] = m.addVar(vtype=GRB.BINARY)  # investment positive if u3=1
    for t in range(T):
        u1[i, t] = m.addVar(vtype=GRB.BINARY)  # quantity used if u1 = 1
        u2[i, t] = m.addVar(vtype=GRB.BINARY)  # quantity at capacity if u2 = 1

# objective function
m.update()  # update passes new info to model (e.g., new variables, new constraints, etc.)
m.setObjective(0)  # here you can write an objective function

# constraints
#u3[3] == 0
for t in range(T):  # market clearing
    m.addConstr(quicksum(quantity[i, t] for i in range(I)) == a[t] - b * price[t], "MarketClearing%d" % (t))

for i in range(3):  # foc
    for t in range(T):
        m.addConstr(price[t] * (1 -  (e[i]/4))   - c[i] - shadow[i, t] <= 0, "FOC1%d" % (t))
        m.addConstr(quantity[i, t] <= M * u1[i, t], "FOC2%d" % (t))
        m.addConstr(price[t] * (1 - (e[i]/4))   - c[i] - shadow[i, t] >= -M * (1 - u1[i, t]), "FOC3%d" % (t))

for t in range(T):
    m.addConstr(price[t] * (1 + s)- c[3] - shadow[3, t] / df.cap[t] <= 0, "FOC1%d" % (t))
    m.addConstr(quantity[3,t] <= M * u1[3, t], "FOC2%d" % (t))
    m.addConstr(price[t] * (1 + s) - c[3] - shadow[3, t] / df.cap[t] >= -M * (1 - u1[3, t]), "FOC3%d" % (t))

for i in range(3):  # shadow only if at capacity
    for t in range(T):
        m.addConstr(quantity[i, t] - capacity[i] <= 0, "Shadow1%d" % (t))
        m.addConstr(shadow[i, t] <= M * u2[i, t], "Shadow2%d" % (t))
        m.addConstr(quantity[i, t] - capacity[i] >= -M * (1 - u2[i, t]), "Shadow3%d" % (t))


for t in range(T):
    m.addConstr(quantity[3, t] - df.cap[t] * capacity[3] <= 0, "windbound%d" % (t))
    m.addConstr(shadow[3, t] <= M * u2[3, t], "Shadow2%d" % (t))
    m.addConstr(quantity[3, t] - df.cap[t] * capacity[3] >= -M * (1 - u2[3, t]), "Shadow3%d" % (t))

for i in range(I):  # zero profit
    m.addConstr(quicksum(df.weight[t] * shadow[i, t] for t in range(T)) - F[i] <= 0, "Invest1%d" % (t))
    m.addConstr(capacity[i] <= M * u3[i], "Invest2%d" % (t))
    m.addConstr(quicksum(df.weight[t] * shadow[i, t] for t in range(T)) - F[i] >= -M * (1 - u3[i]), "Invest3%d" % (t))

# m.addConstr(quicksum(df.weight[t] *  df.cap[t] * shadow[3, t] for t in range(T)) - F[3] <= 0, "Invest1w%d" % (t))
# m.addConstr(capacity[3] <= M * u3[3], "Invest2w%d" % (t))
# m.addConstr(quicksum(df.weight[t] *  df.cap[t] * shadow[3, t] for t in range(T)) - F[3] >= -M * (1 - u3[3]), "Invest3w%d" % (t))


# solve model
m.update()
m.optimize()

# for i in range(I):
#     for t in range(T):
#         print('Quantity' % ( quantity[i,t].x))

#print (some) results
print('Optimal investment:')
for i in range(I):
    print('Investment %d: %f' % (i, capacity[i].x))
#for t in range(T):
 #   print('Price %d: %f' % (t, price[t].x), )