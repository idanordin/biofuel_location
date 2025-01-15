* ---------------------------------
* Reporting
* ---------------------------------

*execute_loadpoint 'm_locate_p';

* Calculate more reporting
* ---------------------------------

p_solveInfo("solveStat") = m_locate.solvestat;
p_solveInfo("modelStat") = m_locate.modelstat;
p_solveInfo("iterUsd") = m_locate.iterusd;
p_solveInfo("resUsd") = m_locate.resusd;
p_solveInfo("numInfes") = m_locate.Numinfes;
p_solveInfo("objval") = m_locate.objval;
p_solveInfo("objEst") = m_locate.objEst;
p_solveInfo("relGap") $ (p_solveInfo("objEst") AND p_solveInfo("objval"))
*    = (p_solveInfo("objEst")-p_solveInfo("objval")) / max(abs(p_solveInfo("objEst")),abs(p_solveInfo("objval")));
     = ABS[p_solveInfo("objEst")-p_solveInfo("objval")] / (1.0e1 - 10 + ABS(p_solveInfo("objval")));
     
* Meta information
parameter p_meta(*);
acronym %endoDemand%;
acronym %distributeBiofuel%;
acronym %data%;
acronym A_%level%;
acronym A_%scen%       ;
acronym A_%gap%        ;
acronym A_%reslim%     ;
acronym A_%mipstart%   ;
acronym A_%threads%    ;
acronym A_%start_value1% ;
acronym A_%holdfixed_var%;
acronym A_%distConstr%;
p_meta("endoDemand") = %endoDemand%;
p_meta("distributeBiofuel") = %distributeBiofuel%;
p_meta("level") = A_%level%;
p_meta("data") = %data%;

p_meta("scen") = A_%scen%;
p_meta("gap") = A_%gap%;
p_meta("reslim") = A_%reslim%;
p_meta("mipstart") = A_%mipstart%;
p_meta("threads") = A_%threads%;
p_meta("startvalue1") = A_%start_value1%;
p_meta("holdfixed_var") = A_%holdfixed_var%;
p_meta("dist_constr") = A_%distConstr%;


* feedstock info
tot_feedstockSE(f) =   sum(g,feedstock(f,g));

feedstock_use_supply(f,g) = sum((b_fuel),v_feedstock_prod.l(f,b_fuel,g))  ;
feedstock_use_percent(f) $ (tot_feedstockSE(f)>0)=  (sum(g,feedstock_use_supply(f,g))/tot_feedstockSE(f))*100 ;
feedstock_use_percent_supply(f,g)= 1;
feedstock_use_percent_supply(f,g) $ ((feedstock(f,g)>0) and (feedstock_use_supply(f,g)>0))=  (feedstock_use_supply(f,g)/feedstock(f,g))*100;


* cost caclulation  for both each tech type, and them togheter
*tot_cost(fuel, tech,i,"production") =v_production_cost.l(b_fuel,tech,i);
tot_cost(b_fuel, tech,i,"var_production") =sum(g, v_feedstock.l(b_fuel,i,g) * production_cost(b_fuel,tech));
tot_cost(b_fuel, tech,i,"var_investment") =sum(g, v_feedstock.l(b_fuel,i,g) * investment_cost_var(b_fuel,tech));
tot_cost(b_fuel, tech,i,"fixed_investment") =investment_cost(b_fuel,tech) * J.l(b_fuel,tech,i);
tot_cost(b_fuel, tech,i,"feedstock")
    = J.l(b_fuel,tech,i)*sum(g $ sum(f_eq, v_feedstock_prod.l(f_eq,b_fuel,g)), v_feedstock.l(b_fuel,i,g)*v_feedstock_cost.l(g) / sum(f_eq, v_feedstock_prod.l(f_eq,b_fuel,g)));
*above: call cost not price
tot_cost(b_fuel, tech,i,"transport")
    = J.l(b_fuel,tech,i)*v_transport_cost.l(b_fuel,i);
tot_cost(b_fuel, tech,i,"distribution")
    = J.l(b_fuel,tech,i)*v_fueltransport_cost.l(b_fuel,i);
* above: call distribution
tot_cost(b_fuel, tech,i,"total biofuel")= tot_cost(b_fuel, tech,i,"var_production")+ tot_cost(b_fuel, tech,i,"var_investment") + tot_cost(b_fuel, tech,i,"fixed_investment") +
                                      tot_cost(b_fuel, tech,i,"feedstock") +  tot_cost(b_fuel, tech,i,"transport") +  tot_cost(b_fuel, tech,i,"distribution");
tot_cost(b_fuel, tech, "SE",cost_items)= sum(i, tot_cost(b_fuel, tech,i,cost_items));
tot_cost(b_fuel, "highLow","SE",cost_items)= sum(tech, tot_cost(b_fuel, tech,"SE",cost_items));
tot_cost(b_fuel, "highLow",i,cost_items)= sum(tech, tot_cost(b_fuel, tech,i,cost_items));

*cost_share(b_fuel, tech,i,"production") $tot_cost(b_fuel, tech,i, "total")=v_production_cost.l(b_fuel,tech,i)/tot_cost(b_fuel, tech,i,"total");

cost_share(b_fuel, tech,i,cost_items) $tot_cost(b_fuel, tech,i, "total")=
    tot_cost(b_fuel, tech,i,cost_items) /tot_cost(b_fuel, tech,i,"total");
cost_share(b_fuel, tech,"SE",cost_items) $tot_cost(b_fuel, tech,"SE", "total")=
    tot_cost(b_fuel, tech,"SE",cost_items) /tot_cost(b_fuel, tech,"SE","total");
cost_share(b_fuel, "highLow",i,cost_items) $ sum(tech,tot_cost(b_fuel, tech,i, "total"))=
    sum(tech,tot_cost(b_fuel, tech,i, cost_items)) /sum(tech,tot_cost(b_fuel, tech,i, "total"));
cost_share(b_fuel, "highLow","SE",cost_items) $ sum(tech,tot_cost(b_fuel, tech,"SE", "total"))=
    sum(tech,tot_cost(b_fuel, tech,"SE", cost_items)) /sum(tech,tot_cost(b_fuel, tech,"SE", "total"));


unit_cost(b_fuel,tech,i,cost_items)$ v_y.l(b_fuel,i) =
    tot_cost(b_fuel, tech,i,cost_items)/v_y.l(b_fuel,i);
unit_cost(b_fuel,tech,"SE",cost_items)$ sum(i,v_y.l(b_fuel,i)) =
    tot_cost(b_fuel, tech,"SE",cost_items)/sum(i,v_y.l(b_fuel,i));
unit_cost(b_fuel,"highLow",i,cost_items)$ sum(tech,v_y.l(b_fuel,i)) =
    tot_cost(b_fuel, "highLow",i,cost_items)/sum(tech, v_y.l(b_fuel,i));
unit_cost(b_fuel,"highLow","SE",cost_items)$ sum((tech,i),v_y.l(b_fuel,i)) =
    tot_cost(b_fuel, "highLow","SE",cost_items)/sum((tech,i), v_y.l(b_fuel,i));


distance_feedstock_res(b_fuel,i,g)$ (v_feedstock.l(b_fuel,i,g)ne 0) = distance(i,g);
distance_demand_res(b_fuel,i,h)$ (v_y_sales.l(b_fuel,i,h) ne 0) = distance_demand(i,h);

* assigning municipality names to numbers
rep_feedstock(b_fuel,knName,g)= sum(i $ kn_to_knName(i,knName), v_feedstock.l(b_fuel,i,g));
rep_feedstockKnName(b_fuel,knName,knName2)
    = sum[g $ kn_to_knName(g,knName2),   rep_feedstock(b_fuel,knName,g)];

* counting used distances
rep_feedstock2(b_fuel,i,g,"distance") $ (v_feedstock.l(b_fuel,i,g) ne 0) = distance(i,g);
* counting non-zero supply
rep_feedstock2(b_fuel,i,g,"supply") $ (v_feedstock.l(b_fuel,i,g) ne 0) = v_feedstock.l(b_fuel,i,g) ;


obj_costs =    sum((b_fuel,tech,i), v_production_cost.l(b_fuel,tech,i)
                + v_transport_cost.l(b_fuel,i)
* WHen demand not active - no transport costs in objective
                + v_fueltransport_cost.l(b_fuel,i))
        + sum(g, + v_feedstock_cost.l(g));

* Land use changes
p_LUC(ab,g)= sum(b_fuel, v_feedstock_prod.l(ab,b_fuel,g));
p_LUC('all_ab',g)= sum(ab, p_LUC(ab,g));

* GHG
* --------------------

*TJ allocate to factory site by taking transport times average ghg emission at origin
p_ghg("feedstock",i)
    = sum((b_fuel,g) $ sum(f, v_feedStock_prod.l(f,b_fuel,g)), v_feedstock.l(b_fuel,i,g)
         * sum(f, v_feedStock_prod.l(f,b_fuel,g) * sum(lan$lan_to_kn(lan,g),ghg_factor(f,"feedstock",lan)))
         / sum(f, v_feedStock_prod.l(f,b_fuel,g)));
p_ghg("production",i)= sum((b_fuel),v_y.l(b_fuel,i) * ghg_factor("all", "production","all"));
p_ghg("investment",i)= sum((b_fuel, tech),J.l(b_fuel,tech,i)*ghg_factor("all","investment", "all"));
p_ghg("transport",i) = sum((f, b_fuel,g), v_feedstock.l(b_fuel,i,g)* distance(i,g)*ghg_factor("all", "transport","all"));
p_ghg("distribution",i) = sum((b_fuel,h), v_y_sales.l(b_fuel,i,h)* distance_demand(i,h)*ghg_factor("all", "distribution","all"));
p_ghg("LUC",i)
    = sum((b_fuel,g) $ sum(f, v_feedStock_prod.l(f,b_fuel,g)), v_feedstock.l(b_fuel,i,g)
        * sum(f, v_feedstock_prod.l(f,b_fuel,g) * ghg_factor("all","LUC",g))
        / sum(f, v_feedStock_prod.l(f,b_fuel,g)));
p_ghg('gasoline', i)=  sum((b_fuel),v_y.l(b_fuel,i))* ghg_factor("all", "gasoline","all");

p_ghg(GHGcat,"SE")= sum(i,p_ghg(GHGcat,i));
p_ghg("all", "SE") $ (p_ghg("all","SE")=0)=sum(GHGcat,p_ghg(GHGcat,"SE"));
p_ghg("allGasoline", "SE")=p_ghg("all", "SE")+p_ghg('gasoline', "SE");



* --- UNload results ----
execute_unload '%results_out%\results_%data%_Endo%endodemand%_distr%distributeBiofuel%_gap%gap%_target%level%_emistarget%emistarget%%scen%_LP.gdx'
v_feedstock v_feedstock_prod
v_y_sales v_y
v_transport_cost v_feedstock_cost J v_production_cost v_tot_cost v_fueltransport_cost
v_tot_demand v_tot_feedstock
v_biofuelEmis
v_biofuelemis_tot v_totEmissions
v_redY_fossilCostGainRed v_redY_fossilCostGainBio v_redY_consLoss v_redY_cost v_nodemand_fossilCostGainBio
v_endY v_yEnergy v_fossil_emissions
distance tot_feedstockSE feedstock
feedstock_use_supply feedstock_use_percent_supply feedstock_use_percent cost_share tot_cost
areaHA2, yield,elas_fodder, ghg_factor, cost_feedstock, borderAndCityMunicipality
rep_feedstock rep_feedstockKnName rep_feedstock2
least_cost highest_cost unit_cost obj_costs
p_EmisTarget p_prodTarget
p_LUC p_ghg
capacity_constraint_up
p_solveInfo, p_meta
fix
eq_emisTarget,
eq_fix, 
eq_feedstock
eq_capacity_up
eq_capacity_lo

eq_blendCap
               
;

*TJ unload everything, for debugging.
*execute_unload "chk_all_out.gdx";

* Delete variable valus for next

option kill = v_feedstock                                    ;
option kill = v_feedstock_prod                               ;
option kill = v_tot_feedstock                                ;
option kill = v_y_sales                                      ;
option kill = v_y                                            ;
option kill = v_transport_cost                               ;
option kill = v_feedstock_cost                                ;
option kill = J                                              ;
option kill = v_production_cost                              ;
option kill = v_tot_cost                                     ;
option kill = v_fueltransport_cost                         ;
option kill = v_tot_demand                                   ;
option kill = v_tot_feedstock                                ;
option kill = v_biofuelEmis                                ;
option kill = v_biofuelemis_tot                              ;
option kill = v_totEmissions                                       ;
option kill = v_nodemand_fossilCostGainBio                   ;
option kill = v_redY_fossilCostGainBio                      ;
option kill = v_redY_consLoss                               ;
option kill = v_redY_fossilCostGainRed                      ;
option kill = v_redY_cost;
option kill =  v_endY;
option kill =  v_yEnergy;
option kill = v_fossil_emissions;
option kill =fix;
option kill =p_J;

option kill = feedstock_use_supply                           ;
option kill = feedstock_use_percent_supply                   ;
option kill = feedstock_use_percent                          ;
option kill = cost_share                                     ;
option kill = tot_cost                                       ;
option kill = rep_feedstock                                  ;
option kill = rep_feedstockKnName                                 ;
option kill = rep_feedstock2                                 ;
option kill = least_cost                          ;
option kill = highest_cost;
option kill = unit_cost;
option kill = obj_costs    ;
option kill = p_solveInfo;
option kill = p_meta ;



