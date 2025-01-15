* ---------------------------------
* State equations 
* ---------------------------------
* scalars for endogenous demand, biofeul production and use start values. can be changed in $setglobal statements
scalar p_useEndoDemand /0/;
scalar p_distributeBiofuel /0/;
scalar p_hasStartValues /0/;
scalar p_useNeighbourFcn /0/;
scalar p_useCountRestrictions "Activate certain restrictions" /0/;

$ifi %distributeBiofuel%==ON p_distributeBiofuel = 1;
$ifi %distributeBiofuel%==OFF p_distributeBiofuel = 0;
$ifi %endoDemand%==ON p_useEndoDemand = 1;
$ifi %endoDemand%==OFF p_useEndoDemand = 0;
$ifi %useNeighbourFcn%==ON p_useNeighbourFcn = 1;
$ifi %useNeighbourFcn%==OFF p_useNeighbourFcn = 0;


$ontext
* --- Declare variables to test infeasabilities, if needed
positive variable v_art1(f_eq,b_fuel,tech_eq,i,g);
positive variable v_art2(b_fuel, tech_eq,i);
positive variable v_art3(b_fuel, tech_eq,i);
positive variable v_art4(b_fuel,h);

positive variable v_art6(b_fuel,tech_eq,i);
positive variable v_art7(b_fuel, tech_eq, i);
$offtext

* ---------------------------------
* State equations
* ---------------------------------
* Production function
eq_production(b_fuel,i)..
    v_y(b_fuel,i) =e=
*        sum(f_eq, conversion_factor(b_fuel) * v_tot_feedstock(b_fuel,tech_eq,i)) ;
        conversion_factor(b_fuel) * sum(tech_eq, v_tot_feedstock(b_fuel,tech_eq,i));


* Cost function (at site)
eq_production_cost(b_fuel,tech_eq,i)..
v_production_cost(b_fuel,tech_eq,i) =e=
  investment_cost(b_fuel,tech_eq) * J(b_fuel,tech_eq,i)
  + v_tot_feedstock(b_fuel,tech_eq,i) * (production_cost(b_fuel,tech_eq)+investment_cost_var(b_fuel,tech_eq))
;



*TJ Matching total supply to total demand of feedstock in each production region g
eq_feedstock_supbal(b_fuel,g) ..
sum(i, v_feedstock(b_fuel,i,g)) =e= sum(f_eq, v_feedstock_prod(f_eq,b_fuel,g));
    
*TJ feedstock production cost (not accounted for at each factory anymore)
eq_feedstock_cost(g)..
v_feedstock_cost(g) =e=
    sum((b_fuel,f_eq), v_feedStock_prod(f_eq,b_fuel,g) * cost_feedstock(f_eq,g));


* Feedstock transport costs
eq_transport_cost(b_fuel,i)..
v_transport_cost(b_fuel,i) =e=
    sum(g, v_feedStock(b_fuel,i,g) * (transport_cost_fixed + transport_cost(i) * distance(i,g)) );

* Biofuel transport costs
eq_fueltransport_cost(b_fuel,i)$ p_distributeBiofuel..
v_fueltransport_cost(b_fuel,i) =e=
    sum(h, v_y_sales(b_fuel,i,h) * (fuel_transport_cost_fixed + distance_demand(i,h) * fuel_transportcost(b_fuel,i)))
;

* --- Relational equations and constraints

* Total feedstock to one facility
eq_tot_feedstock(b_fuel,i)..
    sum(tech_eq, v_tot_feedstock(b_fuel,tech_eq,i)) =e= sum(g, v_feedStock(b_fuel,i,g));


* Restrict feedstock f from one region to be below a max available feedsetock
eq_feedstock(f_eq,g)..
  sum(b_fuel, v_feedStock_prod(f_eq,b_fuel,g)
*-v_art1(f_eq,b_fuel,tech_eq,i,g)
    ) =l= feedstock(f_eq,g);


* Restricting production to be within technological bounds
* Also assures production only if J is 1 (production facility exists)
eq_capacity_up(b_fuel,tech_eq,i)..
   v_tot_feedstock(b_fuel,tech_eq,i) * conversion_factor(b_fuel)
*  -v_art2(b_fuel,tech_eq,i)
   =l= capacity_constraint_up(b_fuel,tech_eq,i) * J(b_fuel,tech_eq,i);

eq_capacity_lo(b_fuel,tech_eq,i)..
   v_tot_feedstock(b_fuel,tech_eq,i) * conversion_factor(b_fuel)
*  + v_art3(b_fuel, tech_eq,i)
   =g= capacity_constraint_lo(b_fuel,tech_eq,i) * J(b_fuel,tech_eq,i);

equation eq_production_up(b_fuel,i) "Help the solver by explicitly removing production where there is no facility";
eq_production_up(b_fuel,i)..
   v_y(b_fuel,i) =l= sum(tech_eq, J(b_fuel,tech_eq,i)*capacity_constraint_up(b_fuel,tech_eq,i));


* demand restriction. All production must be sold to some point h
eq_demandEq(b_fuel,i)$ p_distributeBiofuel..
v_y(b_fuel,i) =e= sum(h, v_y_sales(b_fuel,i,h));

* total demand in one region equals all streams to it
eq_tot_demand(b_fuel,h)$ p_distributeBiofuel..
v_tot_demand(b_fuel, h) =e= sum(i, v_y_sales(b_fuel,i,h));


* --- The following only for exogenous demand

* Setting maximum and minimum demand, if other than blend in cap
eq_demandMax(b_fuel,h)$ (p_distributeBiofuel and not p_useEndoDemand)..
*  v_tot_demand(b_fuel, h) =l= max_demand(b_fuel,h);
    sum(i, v_y_sales(b_fuel,i,h))
* -v_art4(b_fuel,h)
    =l= max_demand(b_fuel,h);

eq_demandMin(b_fuel,h)$ (p_distributeBiofuel and not p_useEndoDemand)..
        sum(i, v_y_sales(b_fuel,i,h))
*        + v_art4(b_fuel,h)
        =g= min_demand(b_fuel,h);
 
* fix blend fuel energy volume to current

eq_fixFuelvolume(blend_fuel, h) $ (p_distributeBiofuel and not p_useEndoDemand)..
f_fuel_0(blend_fuel,h) + v_yEnergy(blend_fuel,h) =e= f_fuel_0(blend_fuel,h);


* Retriction on blend - in 
eq_blendCap(blend_fuel,h )$ p_useEndoDemand..
sum(b_fuel $ fuel_blend(blend_fuel,b_fuel), energy_ekv(b_fuel) * v_tot_demand(b_fuel, h)) =l= blend_cap(blend_fuel,h) * (f_fuel_0(blend_fuel,h) +v_yEnergy(blend_fuel,h));


* -- The endogenous fuel demand

* Blend fuels to consumption of blended fuels, in energy units
eq_energyEkv(blend_fuel,h) $ p_useEndoDemand..
v_yEnergy(blend_fuel,h) =e= sum(fuels $ fuel_blend(blend_fuel,fuels), energy_ekv(fuels)*v_tot_demand(fuels, h)) ;


* fuel consumption equals sum of consumption in all cost segments
eq_end_uses(blend_fuel,h) $ p_useEndoDemand..
v_yEnergy(blend_fuel,h) =e= sum(end_fuel $ end_fuel_map(end_fuel, blend_fuel), v_endY(end_fuel,h));

* Each cost segment is bounded 
eq_redY_max(end_fuel, h) $ [p_useEndoDemand or v_endY.range(end_fuel,h)]..
v_endY(end_fuel,h) =g= max_redY(end_fuel, h);

v_endY.lo(end_fuel,h) =max_redY(end_fuel, h);

eq_redY_min(end_fuel, h) $ [p_useEndoDemand  or v_endY.range(end_fuel,h)]..
v_endY(end_fuel,h) =l= min_redY(end_fuel, h);
v_endY.up(end_fuel,h) = min_redY(end_fuel, h);


* Equations defining differnt parts of cost (and benefits) of decreasing fuel use         
eq_redY_fossilCostGainRed(end_fuel,h) $ p_useEndoDemand ..
v_redY_fossilCostGainRed(end_fuel, h) =e= sum(blend_fuel $ end_fuel_map(end_fuel, blend_fuel), p_0(blend_fuel)) * v_endY(end_fuel,h);

eq_redY_fossilCostGainBio(b_fuel, h)$ p_useEndoDemand..
v_redY_fossilCostGainBio(b_fuel, h) =e= - (sum(blend_fuel $ fuel_blend(blend_fuel,b_fuel), p_0(blend_fuel)) - biotax(b_fuel)) * energy_ekv(b_fuel) * v_tot_demand(b_fuel, h);

eq_redY_consLoss(end_fuel,h) $ p_useEndoDemand..
v_redY_consLoss(end_fuel, h) =e= -  md_consumer(end_fuel, h) * v_endY(end_fuel,h);

eq_redYCost(h) $ p_useEndoDemand..
v_redY_cost(h) =e= sum(end_fuel, v_redY_fossilCostGainRed(end_fuel, h))
                    + sum(b_fuel, v_redY_fossilCostGainBio(b_fuel,h))
                    + sum(end_fuel, v_redY_consLoss(end_fuel, h));

equation eq_nodemand_fossilCostGainBio(b_fuel,i);
variable v_nodemand_fossilCostGainBio(b_fuel,i);                    
eq_nodemand_fossilCostGainBio(b_fuel,i) $ (not p_useEndoDemand)..
v_nodemand_fossilCostGainBio(b_fuel, i) =e= - (sum(blend_fuel $ fuel_blend(blend_fuel,b_fuel), p_0(blend_fuel)) - biotax(b_fuel)) * energy_ekv(b_fuel) * v_y(b_fuel,i);


* --- Emissions

eq_EFeedstock(b_fuel,g)..
v_biofuelEmis("feedstock",b_fuel,"all","all",g)  =e=  sum(f_eq, v_feedStock_prod(f_eq,b_fuel,g) * ghg_factor(f_eq,"feedstock",g));

eq_EProduction(b_fuel,i)..
v_biofuelEmis("production",b_fuel,"all",i,"all") =e= v_y(b_fuel,i) * ghg_factor("all","production","all");

eq_EInvestment(b_fuel,tech_eq,i)..
v_biofuelEmis("investment", b_fuel,tech_eq,i, "all") =e= J(b_fuel,tech_eq,i) * ghg_factor("all","investment","all");

eq_ETransport(b_fuel,i,g)..
v_biofuelEmis("transport",b_fuel,"all",i,g) =e= v_feedStock(b_fuel,i,g)* distance(i,g)*ghg_factor("all", "transport","all");

eq_EDistribution(b_fuel,i,h) $ p_distributeBiofuel..
v_biofuelEmis("distribution",b_fuel,"all",i,h) =e= v_y_sales(b_fuel,i,h)* distance_demand(i,h)*ghg_factor("all", "distribution","all");

eq_ELUC(b_fuel,g)..
* will only take abanndonned land as ony these have carbon stock changes
v_biofuelEmis("LUC",b_fuel,"all", "all",g) =e=  sum(f_eq, v_feedStock_prod(f_eq, b_fuel,g)  * ghg_factor(f_eq,"LUC",g));

* equation for fossil emission decrease, when endogenous demand not used
eq_EGasolineSubs(b_fuel,i,h) $ (p_distributeBiofuel and not p_useEndoDemand)..
*for assumed direct  substitution
v_biofuelEmis("gasolineSubs",b_fuel,"all",i,h) =e= v_y_sales(b_fuel,i,h)*
                                                    [ghg_factor("all", "gasolineSubs","all")$ sameas(b_fuel, "ethanol")];

eq_EDieselSubs(b_fuel,i,h) $ (p_distributeBiofuel and not p_useEndoDemand)..
*for assumed direct  substitution                                                    
v_biofuelEmis("dieselSubs",b_fuel,"all",i,h) =e= v_y_sales(b_fuel,i,h)*
                                                    [ghg_factor("all", "dieselSubs","all")$ sameas(b_fuel, "biodie")];                                                    

* equation for fossil emission decrease, when endogenous demand not used
equation eq_EGasolineSubsNodemand(b_fuel,i);
eq_EGasolineSubsNodemand(b_fuel,i) $ ((not p_distributeBiofuel) and (not p_useEndoDemand))..
*for assumed direct  substitution
v_biofuelEmis("gasolineSubs",b_fuel,"all",i,"") =e= v_y(b_fuel,i)*
                                                    [ghg_factor("all", "gasolineSubs","all")$ sameas(b_fuel, "ethanol")];



* Emission decrease per fossil fuel ,  in t tonne co2 per t m3 fuel
eq_fossilEmissions(f_fuel,h) $ p_useEndoDemand..
v_fossil_emissions(f_fuel,h)=e= v_tot_demand(f_fuel,h) * ghg_factor("all", "gasoline","all") $ sameas(f_fuel, "gas")
                         + v_tot_demand(f_fuel,h) * ghg_factor("all", "diesel","all") $ sameas(f_fuel, "die")
                         ;

* Total biofuel emissions
eq_biofuelEmissions..
v_biofuelEmis_tot =e= 
sum(GHGcat,
                    sum((b_fuel,g),           v_biofuelEmis(GHGcat,b_fuel,"all","all",g))   $ [sameas(GHGcat,"feedstock")]
                  + sum((b_fuel,i,g),         v_biofuelEmis(GHGcat,b_fuel,"all",i,g))       $ [sameas(GHGcat,"transport")]
                  + sum((b_fuel,g),           v_biofuelEmis(GHGcat,b_fuel,"all","all",g))   $ [sameas(GHGcat,"LUC")]
                  + sum((b_fuel,i),           v_biofuelEmis(GHGcat,b_fuel,"all",i,"all"))   $ [sameas(GHGcat,"production")]
                  + sum((b_fuel,tech_eq,i),   v_biofuelEmis(GHGcat,b_fuel,tech_eq,i,"all")) $ [sameas(GHGcat,"investment")]
                  + sum((b_fuel,i,h),         v_biofuelEmis(GHGcat,b_fuel,"all",i,h))       $ [p_distributeBiofuel and sameas(GHGcat,"distribution")]
                  + sum((b_fuel,i,h),           v_biofuelEmis(GHGcat,b_fuel,"all",i,h))       $ [(p_distributeBiofuel and not p_useEndoDemand)  and sameas(GHGcat,"gasolineSubs")]
                  + sum((b_fuel,i,h),           v_biofuelEmis(GHGcat,b_fuel,"all",i,h))       $ [(p_distributeBiofuel and not p_useEndoDemand)  and sameas(GHGcat,"dieselSubs")]
                  + sum((b_fuel,i),           v_biofuelEmis(GHGcat,b_fuel,"all",i,""))      $ [((NOT p_distributeBiofuel) and (not p_useEndoDemand))  and sameas(GHGcat,"gasolineSubs")]
)                                                                        
                        ;

eq_totEmissions..
v_totEmissions =e=
    v_biofuelEmis_tot
+   sum((f_fuel, h), v_fossil_emissions(f_fuel,h)) $ p_useEndoDemand
;

* --- Targtes

eq_prodTarget(b_fuel)..
  sum(i,v_y(b_fuel,i)
*+v_art7, b_fuel, tech_eq, i)
) =g= p_prodTarget(b_fuel);

eq_emisTarget..
  v_totEmissions =l= p_EmisTarget;





* --- Objective function: minimize total costs

eq_tot_cost..
v_tot_cost =e=
   [sum((b_fuel,i), sum(tech_eq, v_production_cost(b_fuel,tech_eq,i))
        + v_transport_cost(b_fuel,i)
    
* When demand  active - transport costs in objective

        + v_fueltransport_cost(b_fuel,i) $ p_distributeBiofuel )
    
    + sum(g, v_feedstock_cost(g))
    ]* (1 + p_VAT)
*
+ sum(h, v_redY_cost(h)) $ p_useEndoDemand
+ sum((b_fuel, i), v_nodemand_fossilCostGainBio(b_fuel, i)) $ (not p_useEndoDemand)
*+ sum((f_eq,b_fuel,tech_eq,i,g),art_cost*v_art1(f_eq,b_fuel,tech_eq,i,g))+
*sum((b_fuel, tech_eq, i),art_cost*v_art2(b_fuel,tech_eq,i)+art_cost*v_art3(b_fuel, tech_eq,i)) + sum((b_fuel, tech_eq,i),art_cost*v_art6(b_fuel, tech_eq,i)) + sum((b_fuel,tech_eq,i),art_cost*v_art7(b_fuel,tech_eq,i))

;


* --- Model restrictions

e_J(b_fuel,tech_eq)$ p_useCountRestrictions ..
* the number of facilites must be non-negative (can be restricted to a given number)
* the number of facilites must be non-negative (can be restricted to a given number)
    sum(i, J(b_fuel,tech_eq,i)
*-v_art6(b_fuel,tech_eq,i)
)
*=g= 0
=l= p_facility_max(tech_eq)
;

* Restrict to at most one tech_eqlevel type of facility (fuel type) per region

eq_facilityRestrictionTech(b_fuel,i) $ p_useCountRestrictions ..
    sum(tech_eq, J(b_fuel,tech_eq,i)) =l= p_max_facilityReg;

* Restrict to only one type of fuel per facility...
* not ready
eq_facilityRestrictionFeed(b_fuel, tech_eq, i) $ p_useCountRestrictions ..
1=e=1;
*    sum(f_eq,abs(v_tot_feedstock(b_fuel,tech_eq,i))) =l= max(f_eq,v_tot_feedstock(b_fuel,tech_eq,i));


* If 1, it is suitable, otherwise zero and non-suitable. Possibility to exclude facility sites
eq_facility_suitability(b_fuel,tech_eq,i) $ p_useCountRestrictions ..
    J(b_fuel,tech_eq,i) =l= facilitySuitability(b_fuel,tech_eq,i);
*0=e=0;
* Restrict facilities in neigbouring area



eq_noNeighbour(b_fuel, i)$ p_useNeighbourFcn..
*0=e=0;
    sum((tech_eq,ii)$ (distance_facility(i,ii)<300), J(b_fuel,tech_eq,ii)) =l= 1;
* -----------------------------
* Declare model
* -----------------------------

Model m_locate /all/;



* Put some regions as not suitable for facilites, to ease solving
facilitySuitability(b_fuel,tech_eq,i) $borderAndCityMunicipality(i) = 0;
J.fx(b_fuel,tech_eq,i) $ (facilitySuitability(b_fuel,tech_eq,i)=0)  =0;

display facilitySuitability, J.lo, J.up, borderAndCityMunicipality;

* fix medium and low facilities to 0, to avoidnthem (not only in constriant)
*J.fx(b_fuel, "medium",i)=0;
*J.fx(b_fuel, "low",i)=0;

* --- Bounds implied by constraints


v_y.up(b_fuel,i)
    = smax(tech_eq, capacity_constraint_up(b_fuel,tech_eq,i));
    
v_production_cost.up(b_fuel,tech_eq,i) $ (conversion_factor(b_fuel) * (production_cost(b_fuel,tech_eq)+investment_cost_var(b_fuel,tech_eq)))
    = capacity_constraint_up(b_fuel,tech_eq,i)
    /(conversion_factor(b_fuel) * (production_cost(b_fuel,tech_eq)+investment_cost_var(b_fuel,tech_eq)));
    
*v_feedstock_cost.up(g) $ smax(f_eq, conversion_factor(b_fuel) * cost_feedstock(f_eq,g)))
*    = sum(b_fuel, capacity_constraint_up(b_fuel,tech_eq,i) / smax((f_eq, conversion_factor(b_fuel) * cost_feedstock(f_eq,g)));
    
*v_transport_cost.up(b_fuel,tech_eq,i) $ smax(f_eq, conversion_factor(b_fuel) * (transport_cost_fixed + transport_cost(f_eq,i) * smax(gg, distance(i,gg))) )
*    = capacity_constraint_up(b_fuel,tech_eq,i) / smax(f_eq, conversion_factor(b_fuel) * (transport_cost_fixed + transport_cost(f_eq,i) * smax(gg, distance(i,gg))) );
    
v_fueltransport_cost.up(b_fuel,i) = smax(tech_eq, capacity_constraint_up(b_fuel,tech_eq,i) * (fuel_transport_cost_fixed +  fuel_transportcost(b_fuel,i) * smax(hh, distance_demand(i,hh) )));

*v_tot_feedstock.up(b_fuel,i) $ conversion_factor(b_fuel)
*    = capacity_constraint_up(b_fuel,tech_eq,i) /conversion_factor(b_fuel);
    
*v_feedstock.up(b_fuel,i,g) $ conversion_factor(b_fuel)
*    = smax(tech_eq, capacity_constraint_up(b_fuel,tech_eq,i)) / conversion_factor(b_fuel);
    
v_feedstock.up(b_fuel,i,g)
    = sum(f_eq, feedstock(f_eq,g));

* based on assumption that fuel will not increase dramatically, and cannot be egative
v_yEnergy.up(blend_fuel,h)
    = f_fuel_0(blend_fuel,h);
v_yEnergy.lo(blend_fuel,h)
    = -f_fuel_0(blend_fuel,h);

*v_biofuelEmis.up("feedstock",b_fuel,"all",i,g) $ (conversion_factor(b_fuel) * ghg_factor(f_eq,"feedstock",g))
*    =  capacity_constraint_up(b_fuel,tech_eq,i) /conversion_factor(b_fuel) * ghg_factor(f_eq,"feedstock",g);
*v_biofuelEmis.up("production",b_fuel,tech_eq,i,"all")
*    = capacity_constraint_up(b_fuel,tech_eq,i) * ghg_factor("all","production","all");
*v_biofuelEmis.up("investment", b_fuel,tech_eq,i, "all")
*    =  ghg_factor("investment","all");
*v_biofuelEmis.up("transport",b_fuel,tech_eq,i,g)
*    = feedstock(f_eq,g)* distance(i,g)*ghg_factor("all", "transport","all");
*v_biofuelEmis.up("distribution",b_fuel,tech_eq,i,h)
*    = capacity_constraint_up(b_fuel,tech_eq,i) * distance_demand(i,h)*ghg_factor("all", "distribution","all");






