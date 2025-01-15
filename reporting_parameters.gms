* reporting parameters
* specific for reporting


set cost_items /"var_production","var_investment","fixed_investment","feedstock","transport","distribution","Total biofuel","Fuel change","Total fossil"/;


parameter tot_feedstockSE(f) 'Total feedstock available in Sweden, tonne';
parameter feedstock_use_supply(f,g);
parameter feedstock_use_percent(f);
parameter feedstock_use_percent_supply(f,g);
parameter tot_cost(fuels, *,*,*);
parameter cost_share(fuels, *,*,cost_items);
* "marginals", per feedsetock buit then need demand transort too.
parameter least_cost(f,fuels,tech,i,*);
parameter highest_cost(f,fuels,tech,i,*);
parameter unit_cost( fuels,*,*, cost_items);
parameter distance_feedstock_res(fuels,i,g);
parameter distance_demand_res(fuels,i,h);
parameter rep_feedstock(fuels,knname,g);
alias (knname, knname2)
parameter rep_feedstockKnName(fuels,knName,knname2);
parameter rep_feedstock2(fuels,i,g,*);
parameter obj_costs 'costs in the objective function - to check if it works';
parameter p_ghg(GHGcat,*)'ghg in a facility region i, per category';
parameter p_LUC(*,g) 'land use changes in ha (?) per abanndoned land categoreis';

parameter p_solveInfo(*) 'information on solve status';
scalar starttime;

