* ---------------------------------
* State equations and solve model
* ---------------------------------
scalar p_useEndoDemand /0/;
scalar p_distributeBiofuel /0/;
scalar p_hasStartValues /0/;
scalar p_policy /1/;

$ifi %distributeBiofuel%==ON p_distributeBiofuel = 1;
$ifi %distributeBiofuel%==OFF p_distributeBiofuel = 0;
$ifi %endoDemand%==ON p_useEndoDemand = 1;
$ifi %endoDemand%==OFF p_useEndoDemand = 0;
$ifi %policy%==OFF p_policy = 0;
$ifi %policy%==ON p_policy = 1;


$ontext
* --- Declare variables to test infeasabilities, if needed
positive variable v_art1(f,b_fuel,tech,i,g);
positive variable v_art2(b_fuel, tech,i);
positive variable v_art3(b_fuel, tech,i);
positive variable v_art4(b_fuel,h);

positive variable v_art6(b_fuel,tech,i);
positive variable v_art7(b_fuel, tech, i);
$offtext

* ---------------------------------
* State equations
* ---------------------------------

eq_production(b_fuel, tech,i)..
    v_y(b_fuel,tech,i) =e=
        sum(f, conversion_factor(f,b_fuel,i) * v_tot_feedstock(f,b_fuel,tech,i)) ;



* Cost function (at site)
eq_production_cost(b_fuel,tech,i)..
v_production_cost(b_fuel,tech,i) =e=
  investment_cost(b_fuel,tech) * J(b_fuel,tech,i)
  + sum((g,f), v_feedstock(f,b_fuel,tech,i,g) * (production_cost(f,b_fuel,tech)+investment_cost_var(b_fuel,tech)))
;
* Purchase cost
eq_feedstock_cost(b_fuel,tech,i)..
v_feedstock_cost(b_fuel,tech,i) =e=
    sum((f,g), v_feedstock(f,b_fuel,tech,i,g) * cost_feedstock(f,g));


* Transport costs
eq_transport_cost(b_fuel,tech,i)..
v_transport_cost(b_fuel,tech,i) =e=
    sum((f,g), v_feedstock(f,b_fuel,tech,i,g) * (transport_cost_fixed + transport_cost(f,i) * distance(i,g)) );

eq_fueltransport_cost(b_fuel,tech,i)$ p_distributeBiofuel..
v_fueltransport_cost(b_fuel,tech,i) =e=
    sum(h, v_y_sales(b_fuel,tech,i,h) * (fuel_transport_cost_fixed + distance_demand(i,h) * fuel_transportcost(b_fuel,i)))
;

* Relational equations and constraints

*Total feedstock to one facility
eq_tot_feedstock(f,b_fuel,tech,i)..
    v_tot_feedstock(f,b_fuel,tech,i) =e= sum(g, v_feedstock(f,b_fuel,tech,i,g));


* Restrict feedstock f from one region to be below a max
eq_feedstock(f,g)..
  sum((b_fuel,tech,i), v_feedstock(f,b_fuel,tech,i,g)
*-v_art1(f,b_fuel,tech,i,g)
) =l= feedstock(f,g);


* Restricting production to be within tech bounds
* Also assures production only if J is positive (production facility exists)
eq_capacity_up(b_fuel,tech,i)..
v_y(b_fuel,tech,i)
*-v_art2(b_fuel,tech,i)
 =l= capacity_constraint_up(b_fuel,tech,i) * J(b_fuel,tech,i);

eq_capacity_lo(b_fuel,tech,i)..
v_y(b_fuel,tech,i)
*+ v_art3(b_fuel, tech,i)
=g= capacity_constraint_lo(b_fuel,tech,i) * J(b_fuel,tech,i);

* demand restriction. All production must be sold to a point h


eq_demandEq(b_fuel,tech,i)$ p_distributeBiofuel..
v_y(b_fuel,tech,i) =e= sum(h, v_y_sales(b_fuel,tech,i,h));

eq_tot_demand(b_fuel,h)$ p_distributeBiofuel..
v_tot_demand(b_fuel, h) =e= sum((tech,i), v_y_sales(b_fuel,tech,i,h));
*eq_tot_demand(b_fuel,h)..
*v_tot_demand(b_fuel, h) =e= 1;
* Specify maximum demand per point, and also minimum




* The following only for exogenous demand
eq_demandMax(b_fuel,h)$ (p_distributeBiofuel and not p_useEndoDemand)..
*  v_tot_demand(b_fuel, h) =l= max_demand(b_fuel,h);
    sum((tech,i), v_y_sales(b_fuel,tech,i,h))
* -v_art4(b_fuel,h)
    =l= max_demand(b_fuel,h);

eq_demandMin(b_fuel,h)$ (p_distributeBiofuel and not p_useEndoDemand)..
        sum((tech,i), v_y_sales(b_fuel,tech,i,h))
*        + v_art4(b_fuel,h)
        =g= min_demand(b_fuel,h);




* The endogenous demand

eq_energyEkv(blend_fuel,h) $ p_useEndoDemand..
v_yEnergy(blend_fuel,h) =e= sum(fuels $ fuel_blend(blend_fuel,fuels), energy_ekv(fuels)*v_tot_demand(fuels, h)) ;

eq_blendCap(blend_fuel,h )$ p_useEndoDemand..
sum(b_fuel $ fuel_blend(blend_fuel,b_fuel), energy_ekv(b_fuel) * v_tot_demand(b_fuel, h)) =l= blend_cap(blend_fuel,h) * (f_fuel_0(blend_fuel,h) +v_yEnergy(blend_fuel,h));

end_uses(blend_fuel,h) $ p_useEndoDemand..
v_yEnergy(blend_fuel,h) =e= sum(end_fuel $ end_fuel_map(end_fuel, blend_fuel), v_endY(end_fuel,h));

eq_redY_max(end_fuel, h) $ p_useEndoDemand..
v_endY(end_fuel,h) =g= max_redY(end_fuel, h);

eq_redY_min(end_fuel, h) $ p_useEndoDemand..
v_endY(end_fuel,h) =l= min_redY(end_fuel, h);

eq_redYCost(h) $ p_useEndoDemand..
v_redY_cost(h) =e= - sum(b_fuel, sum(blend_fuel $ fuel_blend(blend_fuel,b_fuel), p_0(blend_fuel)) * energy_ekv(b_fuel) * v_tot_demand(b_fuel, h))
                 + sum(end_fuel, sum(blend_fuel $ end_fuel_map(end_fuel, blend_fuel), p_0(blend_fuel)) * v_endY(end_fuel,h))
                 - sum(end_fuel, md_consumer(end_fuel, h) * v_endY(end_fuel,h));


* --- Emissions



eq_EFeedstock(f,b_fuel,tech,i,g)..
v_biofuelEmis(f,"feedstock",b_fuel,tech,i,g)  =e=  v_feedstock(f,b_fuel,tech,i,g) * ghg_factor(f,"feedstock",g);
*v_EFeedstock(f,b_fuel,tech,i,g)  =e=  v_feedstock.l(f,b_fuel,tech,i,g) * sum(lan$lan_to_kn(lan,g),ghg_factor(f,"feedstock",lan));

eq_EProduction(b_fuel,tech,i)..
v_biofuelEmis("all","production",b_fuel,tech,i,"all") =e= v_y(b_fuel,tech,i) * ghg_factor("all","production","all");

eq_EInvestment(b_fuel,tech,i)..
v_biofuelEmis("all","investment", b_fuel,tech,i, "all") =e= J(b_fuel,tech,i) * ghg_factor("all","investment","all");

eq_ETransport(f,b_fuel,tech,i,g)..
v_biofuelEmis(f,"transport",b_fuel,tech,i,g) =e= v_feedstock(f,b_fuel,tech,i,g)* distance(i,g)*ghg_factor("all", "transport","all");

eq_EDistribution(b_fuel,tech,i,h) $ p_distributeBiofuel..
v_biofuelEmis("all","distribution",b_fuel,tech,i,h) =e= v_y_sales(b_fuel,tech,i,h)* distance_demand(i,h)*ghg_factor("all", "distribution","all");

eq_ELUC(ab,b_fuel,tech,i,g)..
* will only take abanndonned land as ony these have carbon stock changes
v_biofuelEmis(ab,"LUC",b_fuel,tech, i,g) =e=  v_feedstock(ab,b_fuel,tech,i,g)  * ghg_factor(ab,"LUC",g);


eq_EFossilSubs(b_fuel,tech,i,h) $ (p_distributeBiofuel and not p_useEndoDemand)..
*for assumed direct  substitution
v_biofuelEmis("all","gasolineSubs",b_fuel,tech,i,h) =e= v_y_sales(b_fuel,tech,i,h)*
                                                    [ghg_factor("all", "gasolineSubs","all")$ sameas(b_fuel, "gas")
                                                    + ghg_factor("all", "dieselSubs","all")$ sameas(b_fuel, "die")
                                                    ];
* for assumed andogenous substitution, where gaoline is endogenous
*v_EFossilSubs(b_fuel,tech,i,h) =e= (v_yEnergy("gasoline",h) - p_yEnergy0("gasoline",h))* ghg_factor("all", "gasoline","all");

* ghg_factor in t tonne co2 per t m3 fuel
eq_fossilEmissions(f_fuel,h) $ p_useEndoDemand..
v_fossil_emissions(f_fuel,h)=e= v_tot_demand(f_fuel,h) * ghg_factor("all", "gasoline","all") $ sameas(f_fuel, "gas")
                         + v_tot_demand(f_fuel,h) * ghg_factor("all", "diesel","all") $ sameas(f_fuel, "die")
                         ;


eq_biofuelEmissions(i)..
v_biofuelEmis_atI(i) =e= 
sum(GHGcat,
                    sum((f,b_fuel,tech,g),v_biofuelEmis(f,GHGcat,b_fuel,tech,i,g)) $ [sameas(GHGcat,"feedstock") or sameas(GHGcat,"transport")]
                  + sum((ab,b_fuel,tech,g), v_biofuelEmis(ab,GHGcat,b_fuel,tech, i,g)) $ [sameas(GHGcat,"LUC")]
                  + sum((b_fuel,tech), v_biofuelEmis("all",GHGcat,b_fuel,tech,i,"all"))  $ [sameas(GHGcat,"production") or sameas(GHGcat,"investment")]
                  + sum((b_fuel,tech,h), v_biofuelEmis("all",GHGcat,b_fuel,tech,i,h))  $ [sameas(GHGcat,"distribution")]
                  + sum((b_fuel, tech,h), v_biofuelEmis("all",GHGcat,b_fuel,tech,i,h))$ [(p_distributeBiofuel and not p_useEndoDemand)  and (sameas(GHGcat,"gasolineSubs") or sameas(GHGcat,"dieselSubs"))]
                  )
                        ;



eq_totEmissions..
v_totEmissions =e=
    sum(i, v_biofuelEmis_atI(i))
+   sum((f_fuel, h), v_fossil_emissions(f_fuel,h)) $ p_useEndoDemand
;
*$offtext
*eq_totEmissions..
*v_totEmissions =e=
*sum((f,b_fuel,tech,g),v_EFeedstock(f,b_fuel,tech,i,g)+ v_ELUC(f,b_fuel,tech, i,g)+v_ETransport(f,b_fuel,tech,i,g))
*                  + sum((b_fuel,tech,i), v_EProduction(b_fuel,tech,i))
*+v_EInvestment(b_fuel,tech,i))
*                  + sum((b_fuel,tech,h), v_EDistribution(b_fuel,tech,i,h))
*                  + sum((b_fuel, tech,h), v_EFossilSubs(b_fuel,tech,i,h)))



* --- Targtes

eq_prodTarget(b_fuel)  $ (not p_policy)..
  sum((tech,i),v_y(b_fuel,tech,i)
*+v_art7, b_fuel, tech, i)
) =g= p_prodTarget(b_fuel);

eq_emisTarget  $ (not p_policy)..
  v_totEmissions =l= p_EmisTarget;





* --- Objective function: minimize total costs
parameter emis_tax 'tax on emissions based on shadow value of emission target' ;
parameter location_subsidy(b_fuel,tech,i)'subsidy based on the need to fix location';
emis_tax = 0;
location_subsidy(b_fuel,tech,i) = 0;

eq_tot_cost..
    v_tot_cost =e= sum((b_fuel,tech,i), v_production_cost(b_fuel,tech,i)+ v_feedstock_cost(b_fuel,tech,i)
    + v_transport_cost(b_fuel,tech,i)
* WHen demand  active - transport costs in objective

+ v_fueltransport_cost(b_fuel,tech,i) $ p_distributeBiofuel

)
+ sum(h, v_redY_cost(h)) $ p_useEndoDemand
*+ sum((f,b_fuel,tech,i,g),art_cost*v_art1(f,b_fuel,tech,i,g))+
*sum((b_fuel, tech, i),art_cost*v_art2(b_fuel,tech,i)+art_cost*v_art3(b_fuel, tech,i)) + sum((b_fuel, tech,i),art_cost*v_art6(b_fuel, tech,i)) + sum((b_fuel,tech,i),art_cost*v_art7(b_fuel,tech,i))

*Policy measures

- (emis_tax * (v_totEmissions )) $ p_policy
- sum((b_fuel, tech,i),location_subsidy(b_fuel,tech,i) *J(b_fuel,tech,i)) $ p_policy;
;


* --- Model restrictions

e_J(b_fuel,tech)..

* the number of facilites must be non-negative (can be restricted to a given number)
    sum(i, J(b_fuel,tech,i)
*-v_art6(b_fuel,tech,i)
)
*=g= 0
=l= facility_max(tech)
;

* Restrict to at most one tech level type of facility (fuel type) per region

eq_facilityRestrictionTech(b_fuel,i)..
    sum(tech, J(b_fuel,tech,i)) =l= max_facilityReg;

* Restrict to only one type of fuel per facility...
* not ready
eq_facilityRestrictionFeed(b_fuel, tech, i)..
1=e=1;
*    sum(f,abs(v_tot_feedstock(f,b_fuel,tech,i))) =l= max(f,v_tot_feedstock(f,b_fuel,tech,i));


* If 1, it is suitable, otherwise zero and non-suitable. Possibility to exclude facility sites
eq_facility_suitability(b_fuel,tech,i)..
    J(b_fuel,tech,i) =l= facilitySuitability(b_fuel,tech,i);


* -----------------------------
* Declare model
* -----------------------------

Model m_locatepolicy /all/;

* --- Bounds implied by constraints
v_y.up(b_fuel,tech,i)
    = capacity_constraint_up(b_fuel,tech,i);
v_production_cost.up(b_fuel,tech,i) $ smax(f, conversion_factor(f,b_fuel,i) * (production_cost(f,b_fuel,tech)+investment_cost_var(b_fuel,tech)))
    = capacity_constraint_up(b_fuel,tech,i) /smax(f, conversion_factor(f,b_fuel,i) * (production_cost(f,b_fuel,tech)+investment_cost_var(b_fuel,tech)));
v_feedstock_cost.up(b_fuel,tech,i) $ smax(f, conversion_factor(f,b_fuel,i) * smax(g, cost_feedstock(f,g)))
    = capacity_constraint_up(b_fuel,tech,i) / smax(f, conversion_factor(f,b_fuel,i) * smax(g, cost_feedstock(f,g)));
v_transport_cost.up(b_fuel,tech,i) $ smax(f, conversion_factor(f,b_fuel,i) * (transport_cost_fixed + transport_cost(f,i) * smax(gg, distance(i,gg))) )
    = capacity_constraint_up(b_fuel,tech,i) / smax(f, conversion_factor(f,b_fuel,i) * (transport_cost_fixed + transport_cost(f,i) * smax(gg, distance(i,gg))) );
v_fueltransport_cost.up(b_fuel,tech,i) = capacity_constraint_up(b_fuel,tech,i) * (fuel_transport_cost_fixed +  fuel_transportcost(b_fuel,i) * smax(hh, distance_demand(i,hh) ));
v_tot_feedstock.up(f,b_fuel,tech,i) $ conversion_factor(f,b_fuel,i)
    = capacity_constraint_up(b_fuel,tech,i) /conversion_factor(f,b_fuel,i);
v_feedstock.up(f,b_fuel,tech,i,g) $ conversion_factor(f,b_fuel,i)
    = capacity_constraint_up(b_fuel,tech,i) /conversion_factor(f,b_fuel,i);
v_feedstock.up(f,b_fuel,tech,i,g)
    = feedstock(f,g);

* based on assumption that fuel will not increase dramatically, and cannot be egative
v_yEnergy.up(blend_fuel,h)
    = f_fuel_0(blend_fuel,h);
v_yEnergy.lo(blend_fuel,h)
    = -f_fuel_0(blend_fuel,h);

v_biofuelEmis.up(f,"feedstock",b_fuel,tech,i,g) $ (conversion_factor(f,b_fuel,i) * ghg_factor(f,"feedstock",g))
    =  capacity_constraint_up(b_fuel,tech,i) /conversion_factor(f,b_fuel,i) * ghg_factor(f,"feedstock",g);
v_biofuelEmis.up("all","production",b_fuel,tech,i,"all")
    = capacity_constraint_up(b_fuel,tech,i) * ghg_factor("all","production","all");
v_biofuelEmis.up("all","investment", b_fuel,tech,i, "all")
    =  ghg_factor("all","investment","all");
v_biofuelEmis.up(f,"transport",b_fuel,tech,i,g)
    = feedstock(f,g)* distance(i,g)*ghg_factor("all", "transport","all");
v_biofuelEmis.up("all","distribution",b_fuel,tech,i,h)
    = capacity_constraint_up(b_fuel,tech,i) * distance_demand(i,h)*ghg_factor("all", "distribution","all");

