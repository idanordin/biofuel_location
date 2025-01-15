* ---------------------------------
* Biofuel facility location model
*
* declaration of parameters, sets, variables, equations
* ---------------------------------

* --- create sets to use for model

set kn_map(*,*);
set knkod;
set objectid;

* load set from data
$gdxin 'data\municip_scb.gdx'
$load knkod
$gdxin

* load regional sets and mappings
$gdxin 'data\kommunlankod_1219_SCB.gdx'
$load
sets
lan
prodOmr
landsdel
nuts2
lan_to_kn
prodOmr_to_kn
kommunkod
knName
kn_to_knName
lan_to_landsdel
nuts2_to_lan
$load lan prodOmr landsdel nuts2 lan_to_kn kommunkod knName prodOmr_to_kn kn_to_knName lan_to_landsdel nuts2_to_lan
$gdxin
display nuts2;



* Regions per use
set i(knkod) 'facility locations' /set.knkod/;
set g(knkod) 'feedstock locations'/set.knkod/;
set h(knkod) 'demand locations' /set.knkod/;
set tech 'technology, type and size - base set' /low, medium,high/;
*set capacity 'capacity levels' /low, medium, high/;
set tech_eq(tech) 'technology, type and size - adjustable set for equations' /set.tech/;

set fuels 'all fuel types' /ethanol, methanol, gas, die/ ;

set f_fuel(fuels) 'Fossil fuels' /gas, die/;


set b_fuel(fuels) 'biofuels' /ethanol/;

set blend_fuel 'Fuels blended to fossils' /gasE, dieB/;


set f 'feedstock types, base set' /wheat, grass1, grass2, grass3,ab1, ab2, ab3, abP1, abP2, abP3/;
set f_eq(f) 'feedstock types, adjustable in equations' /set.f/;

set grass(f) 'feedstock from ley land' /grass1,grass2,grass3/;
set ab(f) 'subset of abandonned land' /ab1, ab2, ab3/;
set abP(f) 'subset of ALA on old pasture . Can have different properties' /abP1, abP2, abP3 /;



set GHGcat /feedstock, production, investment, transport, distribution, LUC, LUCabovenat, LUCabovecrp, SOCcrp, SOCgrassland, altEmisALA, all, gasolineSubs, dieselSubs, gasoline, diesel, allgasoline, carbonstock/;


set fuel_blend(blend_fuel,fuels) 'mapping fuel that can be blended in each blend'
                                    /gasE.ethanol
                                   gasE.gas
                                   dieB.die
/;

* stepwise linear demand function. Define each fuel as its own element, also negative posssible (gasE_m1)
set end_fuel_Large 'end use fuels, i.e. blended in fuels, differnt cost level based on demand elasicitites'
/gasE_m1,gasE_1, gasE_2, gasE_3, gasE_4, gasE_5, dieB_m1, dieB_1, dieB_2, dieB_3, dieB_4, dieB_5, gasE_1b, gasE_2b, gasE_3b, gasE_4b, gasE_5b, dieB_1b, dieB_2b, dieB_3b, dieB_4b, dieB_5b/;
set end_fuel(end_fuel_Large) 'SAubset of end use fuels, i.e. blended in fuels, differnt cost level based on demand elasicitites'
/gasE_1, gasE_2, gasE_3, gasE_4, gasE_5, dieB_1, dieB_2, dieB_3, dieB_4, dieB_5/;
set end_fuel_small(end_fuel_Large) 'SAubset of end use fuels, i.e. blended in fuels, differnt cost level based on demand elasicitites'
/gasE_1, gasE_2,gasE_3, dieB_1, dieB_2, dieB_3/;
*/gasE_m1, gasE_1, gase_2,gasE_3, dieB_1/;
*set end_fuel 'end use fuels, i.e. blended in fuels, differnt cost level based on demand elasicitites'
*/gasE_m1,gasE_1, gase_2, gasE_3, dieB_m1, dieB_1, dieB_2, dieB_3/;

*alias (end_fuel.end_fuel_Large);
set end_fuel_map(end_fuel_Large, blend_fuel) 'mapping of the blended fuel, to the segment of decrease in fuel consumption' 
         /gasE_m1.gasE
         gasE_1.gasE
         gasE_2.gasE
         gasE_3.gasE
         gasE_4.gasE
         gasE_5.gasE
         dieB_m1.dieB
         dieB_1.dieB
         dieB_2.dieB
         dieB_3.dieB
         dieB_4.dieB
         dieB_5.dieB

         gasE_1b.gasE
         gasE_2b.gasE
         gasE_3b.gasE
         gasE_4b.gasE
         gasE_5b.gasE         

         dieB_1b.dieB
         dieB_2b.dieB
         dieB_3b.dieB
         dieB_4b.dieB
         dieB_5b.dieB
         /;

* Decides if small fuel set is on or off.  Neeeded to compute costs in data
$if %smallFuelSet% == OFF end_fuel(end_fuel_Large) =yes;

$ontext
set end_fuel 'end use fuels, i.e. blended in fuels, differnt cost level based on demand elasicitites'
/gasE_m1,gasE_1, gase_2, gasE_3, dieB_m1, dieB_1, dieB_2, dieB_3,
gasE_1b, gase_2b, gasE_3b, dieB_1b, dieB_2b, dieB_3b/;
set extraend_fuel(end_fuel) /gasE_1b, gase_2b, gasE_3b, dieB_1b, dieB_2b, dieB_3b/;
*alias (end_fuel.end_fuel2);
set end_fuel_map(end_fuel, blend_fuel)
         /gasE_m1.gasE
         gasE_1.gasE
         gasE_2.gasE
         gasE_3.gasE
         dieB_m1.dieB
         dieB_1.dieB
         dieB_2.dieB
         dieB_3.dieB

         gasE_1b.gasE
         gasE_2b.gasE
         gasE_3b.gasE

         dieB_1b.dieB
         dieB_2b.dieB
         dieB_3b.dieB
         /;
$offtext

* Alias to be able to allow summations
alias (i,ii);
alias (g,gg);
alias (h,hh);
alias(f,ff);
alias(ab,aabb);
alias(abP, aabbP);
alias (f_fuel,f_fuelb);
alias (f_fuel, f_fuel3);


* --- Declare parameters
* distances
parameter distance(i,g)'Distance between feedstock region g and facility region i';
parameter distance_demand(i,h)'Distance betseen a faciality location i and demand point h';

*costs
parameter transport_cost(i)'variable transport cost SEK per km of feedstock f to region i';
parameter transport_cost_fixed 'fixed transport cost of feedstock';
parameter cost_feedstock(f,g)   'Price of biomass feedstock f in region g';
parameter elas_fodder(f,lan) "own price elasticities for Fodder, used for Reed canary grass, as they compete for land and similar: SE11, SE21,SE22,SE23,SE31,SE32";
parameter production_cost(b_fuel, tech)'variable biofuel production cost per tonne feedstock of feedstock per capacity level(per year) ';
parameter production_cost_2(b_fuel,tech);
parameter investment_cost_var(b_fuel,tech)'Variable investment cost per year, per tonne feedstock, for a fuel and capacity level';
parameter investment_cost(b_fuel,tech) 'Fixed investment cost for a fuel and capacity level, annulized ';
parameter fuel_transportcost(b_fuel,i) 'variable transport cost SEK per km of fuel from region i';
parameter fuel_transport_cost_fixed 'fixed transport cost of fuel';
parameter p_0(blend_fuel) 'initial fuel price';
parameter conversion_cost(g,f) 'per tonne dm conversion cost' ;
parameter prod_costAb(g,f);
parameter conversion_cost_ha(f) 'per hectare conversion cost' ;
*scalar interceptAb /1/;
*scalar slopeAb /0.1/;

*technology/restrictins
parameter conversion_factor(b_fuel) 'm^3 of fuel per tonne feedstock f, at facility at i ';
parameter feedstock(f,g) 'maximum feedstock supply of f in region g';
parameter max_demand(b_fuel,h) 'maximum fuel demand in demand region h';
parameter min_demand(b_fuel,h) 'minimum fuel demand in demand region h';
parameter capacity_constraint_up(b_fuel,tech,i) 'maximum capacity of production of a fuel at facility i, in m^3';
parameter capacity_constraint_lo(b_fuel,tech,i) 'minimium capacity of production of a fuel at facility i, in m^3';
parameter facilitySuitability(b_fuel,tech,i) 'facility sutability indicator, 1 or 0, ';
parameter max_target(b_fuel) 'Max biofuel production target in thousand m3 biofuel';
parameter p_prodTarget(b_fuel) 'Target value of production of a fuel in the whole region, m^3';
parameter p_emisTarget 'Target value for emission reduction in the whole region, kg CO2eq';
parameter max_target(b_fuel) 'max target level of all scenarios';
parameter yield(g,f) 'yield per hectar in 1000 kg (dry weight)' ;
parameter area_factor(f,g) 'how large share of land can be used for biofuel for each cost category';
parameter feedstock_area(g,f) 'max area (HA) that can be used to grow crop f in region g';

parameter energy_ekv(fuels) 'multiplicator for t m3 to TJ';
parameter fuel_ekv(b_fuel,blend_fuel);
parameter blend_cap(blend_fuel,h) 'max blending of biofuel into fossil fuel';
parameter carbon_change(g,f) 'change in carbon stock from abanndonned to energy crop';
parameter GHG_factor(*,*,*)'emission factors, kg per m3(for fuel) or tonne  (for feedstock)';
parameter max_redY(end_fuel_Large, h) 'max level of reduction of this end fuel';
parameter min_redY(end_fuel_Large, h) 'min level of reduction of this end fuel';
parameter f_fuel_0(blend_fuel,h) 'Initial levels of fossil fuels in TJ';
parameter fuelUse_0_Tm3(h,fuels) 'initial fossil fuel use in thousand m3';
parameter p_0(blend_fuel) 'initial price for fossil fuels';
parameter md_consumer(end_fuel_Large, h) 'marginal demand consumer, per end use fuel, piecewise linear';

parameter biotax(b_fuel) 'Tax on biofuel';
parameter p_VAT 'VAT tax rate on biofuel';


* modelling constriants for easiness
parameter p_facility_max(tech);
scalar distance_max;
scalar p_max_facilityReg;
parameter p_noBio;



* ---------------------------------
*  Declaration of variables
* ---------------------------------

* Declare variables
positive variable v_feedstock(b_fuel,i,g) 'feedstock delivered to facility i from supplier at g for production of a fuel. Tonne';
positive variable v_feedstock_prod(f,b_fuel,g) 'Total output of feedstock of cost category f at location g';
positive variable v_production_cost(b_fuel,tech,i) 'Total variable production costs at facility at i';
positive variable v_feedstock_cost(g) 'Total cost to produce feedstock in region g';
positive variable v_transport_cost(b_fuel,i) 'Total transport cost for feedstock shipped to facility at i ';
positive variable v_tot_feedstock(b_fuel,tech,i)'Total feedstock used by facility tech at i';
positive variable v_fueltransport_cost(b_fuel,i)'Total transport cost of fuel from facility at i ';
positive variable v_y_sales(b_fuel,i,h) 'Total sales of y to demand point h';
positive variable v_y(b_fuel,i)'Total production of fuel at i';
variable v_tot_demand(fuels, h) 'total demand at one location h, of any fuel (fossil or bio)';
v_tot_demand.lo(b_fuel,h)=0;


variable v_biofuelEmis(GHGcat,b_fuel,*,*,*);
variable v_biofuelEmis_tot "Sum of biofuel production emissions, including all transportations";
variable v_fossil_emissions(f_fuel,h);
variable v_totEmissions;

variable v_tot_cost 'total cost';

Binary Variable J(b_fuel,tech,i) 'Investment decision 1 or 0';

variable v_yEnergy(blend_fuel,h) 'fuels expressed in energy equivalents';
*positive variable v_blend_rate(blend_fuel,h) 'blending rate of biofuel into fossil fuel';

variable v_endY(end_fuel_Large,h) 'end use fuel, i.e. possibly fossil mixed with biofuel, GJ';

variable v_redY_fossilCostGainRed(end_fuel, h) 'Gain for reducing fossil fuel use, part connected to total reduction in fuel use (as we typically loock at reductions)';
variable v_redY_fossilCostGainBio(b_fuel, h) 'Gain for reducing fossil fuel use, part connected to biofuel replacement (as we typically loock at reductions)';
variable v_redY_consLoss(end_fuel, h)  'Consumer losses of reduced fuel use, excluding reduced purchase costs';

variable v_redY_cost(h) 'consumer surplus cost for reducing fuel';



*$ontext
* ---------------------------------
* Declaration of equations
* ---------------------------------
equation eq_production_cost(b_fuel,tech,i) "cost function for production at facility";
equation eq_feedstock_cost(g) "Total cost of feedstock production in region g";
equation eq_transport_cost(b_fuel,i) "Total cost for transporting feedstock to facility at i";
equation eq_tot_feedstock(b_fuel,i) ;
equation eq_feedstock_supbal(b_fuel,g) "Sum of demand for feedstock at g equals supply";

equation eq_fueltransport_cost(b_fuel,i);
equation eq_production(b_fuel,i) "production function at facility";

*--- Restrictions
equation e_J(b_fuel,tech) 'Number of facilities restriction';
equation eq_prodTarget(b_fuel) "production target";
equation eq_emisTarget;

equation eq_facilityRestrictionTech(b_fuel,i) 'Restricting number of differnt facility technology at same place';
equation eq_facilityRestrictionFeed(b_fuel,tech, i) 'Restricting number of differnt feedstock per facility';
equation eq_noNeighbour(b_fuel,i) 'equation to reduce time for solve - restrict facilities not to be too close to each other';

equation eq_feedstock(f,g) "max feedstock uptake from supply region g";
equation eq_capacity_up(b_fuel,tech,i) 'tech capacity constraint upper';
equation eq_capacity_lo(b_fuel,tech,i) 'tech capacity constraint lower';

equation eq_demandEq(b_fuel,i)"sales of y equals production of y";
equation eq_demandMax(b_fuel,h) "restrict max demand at point h";
equation eq_demandMin(b_fuel,h) "restrict min demand at point h";
equation eq_fixFuelvolume(blend_fuel, h) 'Equation fixing fuel volume for the case when only biofuel replacemnt occurs (exogenous demand)';

equation eq_tot_demand(b_fuel,h) 'Total demand at one location h';

equation eq_facility_suitability(b_fuel,tech,i) 'restrict only suitable places for facility location';

equation eq_tot_cost 'Total cost of the biofuel system';


*Emissions
equation eq_EFeedstock(b_fuel,g);
equation eq_EProduction(b_fuel,i);
equation eq_EInvestment(b_fuel,tech,i);
equation eq_ETransport(b_fuel,i,g);
equation eq_EDistribution(b_fuel,i,h);
equation eq_ELUC(b_fuel,g);
equation eq_EGasolineSubs(b_fuel,i,h);
equation eq_EDieselSubs(b_fuel,i,h);
equation eq_fossilEmissions(f_fuel,h);
equation eq_biofuelEmissions;
equation eq_TotEmissions;


*  fuel consumption equations
equation eq_energyEkv(blend_fuel,h) 'tranforming fuels to energy content';
equation eq_blendCap(blend_fuel,h) 'quantity energy biofuel should be less than a cap of the total blended fuel';

equation eq_end_uses(blend_fuel,h) 'each end fuel can be of one of several fuel segments with differnt consumer surplus cost';
equation eq_redY_max(end_fuel_Large, h);
equation eq_redY_min(end_fuel_Large, h);

equation eq_redY_fossilCostGainRed(end_fuel, h) 'equation defining v_redY_fossilCostGainRed(h)' ;
equation eq_redY_fossilCostGainBio(b_fuel, h) 'equation defining v_redY_fossilCostGainBio(h)' ;
equation eq_redY_consLoss(end_fuel, h) 'equation defining v_redY_consLoss(h)' ;
equation eq_redYCost(h) 'welfare cost for changing fuel consumption';


