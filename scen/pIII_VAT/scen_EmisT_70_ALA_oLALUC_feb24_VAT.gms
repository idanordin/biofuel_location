* Scenario
* Run all levels for GHG, + 35 and 45%
$setglobal scen _crpALA_onlyLowArableLUC_feb24_VAT

* reach climate target based on 35% reduction of current gasoline emissions (half of 70% target)
* Use new demand



$setglobal endoDemand ON
$setglobal optfile 1
$setglobal level 00
$setglobal startValueFile results\results_data_rev_EndoON_distrON_gap005_target00_emistarget100_7feb.gdx




*  --- 
* --------------------------------------------------------------------------------
$setglobal emistarget 70

* No ALA
v_feedstock.fx(abP, b_fuel,tech,i,g) = 0;
v_feedstock.fx(ab, b_fuel,tech,i,g) = 0;

* Add LUC emissions on arable land, equal to ALA, for simplicity
ghg_factor(grass,"LUC",g)= 0.5* (ghg_factor("ab1","LUCabovecrp",g) +  ghg_factor("ab1","SOCcrp",g));

* no tax on bio
biotax("ethanol")= 0;
* only add VAT tax based on production cost
p_VAT = 0.25;


* Change feedstock cost to "new"
parameter old_cost_feedstock(f,g);
old_cost_feedstock(f,g) =cost_feedstock(f,g);
cost_feedstock(grass,g)= cost_feedstock_Ag(grass,g);

* Assume emissions from gasoline and diesel should decrease by 70%
* assume that is these fuels multiplied with emission factors. this will leave out some emission weel ok

p_emisTarget = -%emistarget% /100 * (sum(h, f_fuel_0("gasE",h)/energy_ekv("gas")) * ghg_factor("all", "gasoline","all"));
display p_emisTarget, ghg_factor, f_fuel_0;

$include 'scenario_setting.gms' ;

* --- Reset ---
* reset emission target
p_emisTarget = deafult_emisTarget;

* Reset LUC

ghg_factor(grass,"LUC",g)= 0;

* Reset production costs
cost_feedstock(f,g)= old_cost_feedstock(f,g);
$ontext
*  --- 45 %
* --------------------------------------------------------------------------------
$setglobal emistarget 45

* Assume emissions from gasoline and diesel should decrease by 70%
* assume that is these fuels multiplied with emission factors. this will leave out some emission weel ok

p_emisTarget = - %emistarget% /100 * (sum(h, f_fuel_0("gasE",h)/energy_ekv("gas")) * ghg_factor("all", "gasoline","all"));
display p_emisTarget, ghg_factor, f_fuel_0;

$include 'scenario_setting.gms' ;

* --- Reset ---
* reset emission target
p_emisTarget = deafult_emisTarget;


*  --- 50 %
* --------------------------------------------------------------------------------
$setglobal emistarget 50

* Assume emissions from gasoline and diesel should decrease by 70%
* assume that is these fuels multiplied with emission factors. this will leave out some emission weel ok

p_emisTarget = -%emistarget% /100 * (sum(h, f_fuel_0("gasE",h)/energy_ekv("gas")) * ghg_factor("all", "gasoline","all"));
display p_emisTarget, ghg_factor, f_fuel_0;

$include 'scenario_setting.gms' ;

* --- Reset ---
* reset emission target
p_emisTarget = deafult_emisTarget;

*$offtext

*  --- 60 %
* --------------------------------------------------------------------------------
$setglobal emistarget 60

* ALA from cropland, not pasture
v_feedstock.fx(abP, b_fuel,tech,i,g) = 0;

* Assume emissions from gasoline and diesel should decrease by 70%
* assume that is these fuels multiplied with emission factors. this will leave out some emission weel ok

p_emisTarget = -%emistarget% /100* (sum(h, f_fuel_0("gasE",h)/energy_ekv("gas")) * ghg_factor("all", "gasoline","all"));
display p_emisTarget, ghg_factor, f_fuel_0;

$include 'scenario_setting.gms' ;

* --- Reset ---
* reset emission target
p_emisTarget = deafult_emisTarget;


$ontext
*  --- 70 %
* --------------------------------------------------------------------------------
$setglobal emistarget 70

* Assume emissions from gasoline and diesel should decrease by 70%
* assume that is these fuels multiplied with emission factors. this will leave out some emission weel ok

p_emisTarget = -%emistarget% /100 * (sum(h, f_fuel_0("gasE",h)/energy_ekv("gas")) * ghg_factor("all", "gasoline","all"));
display p_emisTarget, ghg_factor, f_fuel_0;

$include 'scenario_setting.gms' ;

* --- Reset ---
* reset emission target
p_emisTarget = deafult_emisTarget;

*  --- 80 %
* --------------------------------------------------------------------------------
$setglobal emistarget 80

* Assume emissions from gasoline and diesel should decrease by 70%
* assume that is these fuels multiplied with emission factors. this will leave out some emission weel ok

p_emisTarget = -%emistarget% /100 * (sum(h, f_fuel_0("gasE",h)/energy_ekv("gas")) * ghg_factor("all", "gasoline","all"));
display p_emisTarget, ghg_factor, f_fuel_0;

$include 'scenario_setting.gms' ;

* --- Reset ---
* reset emission target
p_emisTarget = deafult_emisTarget;

*  --- 90 %
* --------------------------------------------------------------------------------
$setglobal emistarget 90

* Assume emissions from gasoline and diesel should decrease by 70%
* assume that is these fuels multiplied with emission factors. this will leave out some emission weel ok

p_emisTarget = -%emistarget% /100 * (sum(h, f_fuel_0("gasE",h)/energy_ekv("gas")) * ghg_factor("all", "gasoline","all"));
display p_emisTarget, ghg_factor, f_fuel_0;

$include 'scenario_setting.gms' ;

* --- Reset ---
* reset emission target
p_emisTarget = deafult_emisTarget;



*  --- 110 %
* --------------------------------------------------------------------------------
$setglobal emistarget 110

* Assume emissions from gasoline and diesel should decrease by 70%
* assume that is these fuels multiplied with emission factors. this will leave out some emission weel ok

p_emisTarget = -%emistarget% /100 * (sum(h, f_fuel_0("gasE",h)/energy_ekv("gas")) * ghg_factor("all", "gasoline","all"));
display p_emisTarget, ghg_factor, f_fuel_0;

$include 'scenario_setting.gms' ;

* --- Reset ---
* reset emission target
p_emisTarget = deafult_emisTarget;


*  --- 120 %
* --------------------------------------------------------------------------------
$setglobal emistarget 120

* Assume emissions from gasoline and diesel should decrease by 70%
* assume that is these fuels multiplied with emission factors. this will leave out some emission weel ok

p_emisTarget = -%emistarget% /100 * (sum(h, f_fuel_0("gasE",h)/energy_ekv("gas")) * ghg_factor("all", "gasoline","all"));
display p_emisTarget, ghg_factor, f_fuel_0;

$include 'scenario_setting.gms' ;

* --- Reset ---
* reset emission target
p_emisTarget = deafult_emisTarget;

$ontext

*  --- 250 %
* --------------------------------------------------------------------------------
$setglobal emistarget  250

* Assume emissions from gasoline and diesel should decrease by 70%
* assume that is these fuels multiplied with emission factors. this will leave out some emission weel ok

p_emisTarget = -%emistarget% /100 * (sum(h, f_fuel_0("gasE",h)/energy_ekv("gas")) * ghg_factor("all", "gasoline","all"));
display p_emisTarget, ghg_factor, f_fuel_0;

$include 'scenario_setting.gms' ;

* --- Reset ---
* reset emission target
p_emisTarget = deafult_emisTarget;
$offtext

* Reset bound on ALA
v_feedstock.lo(ab,b_fuel,tech,i,g) = 0;
v_feedstock.up(ab,b_fuel,tech,i,g) = +inf;
v_feedstock.lo(abP,b_fuel,tech,i,g) = 0;
v_feedstock.up(abP,b_fuel,tech,i,g) = +inf;