* --- Solve model --
*-------------------

* Chose solver
Option MIP = OSICPLEX;

* define option fiel
m_locate.OptFile =%optfile%;

* set start time to calculate elapsed time
starttime = jnow;

* --- Solve settings


* Turn off or on biofuel to only allow consumption changes
p_noBio =0;
$ifi %noBio%==1 p_noBio= 1;
v_y.fx(b_fuel,i)$ p_noBio = 0;
p_prodtarget(b_fuel) $ p_noBio =0;


* --- setttings to speed up (hopefully) optimization
* Fix variables with known outcome to avoid varibales in equations
m_locate.holdfixed = 1;

* as alternative, Defining variables that should be holdfixed to zero, i.e no possible values for these as excluded from model
*$ifi ( %holdfixed_var% = 1,
*$include holdfixed_var.gms
*);

* Constrain if distance between demand and supply regions can be longer than a certain distance
$ifi %distConstr%==1 p_distConstraint = 1;
v_feedstock.fx(b_fuel,i,g) $ ((distance(i,g) > 1000) and p_distConstraint)= 0 ;
display  v_feedstock.l, v_feedstock.up;

* Dfine max facilities per region, and in total 
p_max_facilityReg = %maxfacilityReg%;
p_facility_max("high") = %highFacility_max%;
p_facility_max("low") = %lowFacility_max%;

*p_facility_max(tech) $ [sum(, b_fuel, i), conversion_factor("grass1", b_fuel,i)) and  sum(, b_fuel, i), capacity_constraint_lo, b_fuel,tech,i))] = sum((f,g), feedstock(f,g)) /
*                                          [sum(, b_fuel,i) $ (conversion_factor("grass1", b_fuel,i) and  capacity_constraint_lo, b_fuel,tech,i)), capacity_constraint_lo, b_fuel,tech,i)/conversion_factor("grass1", b_fuel,i))
*                                              /sum(, b_fuel, i) $ conversion_factor("grass1", b_fuel,i),1)]
*                                    ;


* Priority order of integer variables, to speed up
m_locate.prioropt = 1;
J.prior(b_fuel,"high",i)   = 1;
J.prior( b_fuel,"low",i)   = 2;
J.prior(b_fuel,"medium",i)  = 3;


m_locate.savepoint = 1;
m_locate.Reslim    =  %reslim% * 60;

* defines optimlity gap
m_locate.optcr= 0.%gap%;

*Option BRatio = 1.0;
* Define use of threads
m_locate.threads=%threads%;


* indicate using MIP start values or not
m_locate.integer4 = %mipstart%;

* startvalues set to 1, to have starting vaules
if ( %start_value1% = 1,
$include start_value_1.gms
);

* Load startvalues for MIP start
execute_loadpoint '%startValueFile%'
J
v_feedstock
v_feedstock_prod
v_y_sales
v_y
v_transport_cost
v_feedstock_cost
v_production_cost
v_fueltransport_cost
v_tot_demand
v_tot_feedstock

v_biofuelEmis
v_biofuelEmis_tot
v_fossil_emissions
v_totEmissions

v_tot_cost

v_yEnergy
*v_blend_rate
v_endY
v_redY_cost

;
execute_unload 'debug_MIP.gdx';
if(execError gt 0,
    display "Tried to load restart values, but got an error.";
   execError = 0;
);




*           === SOLVE the model ===
*           (minimizing the weighted sum of squared deviations under constraints)

*           The first solve may be either far off or perfect (if starting values are good)
*           We give just a little time at this point, because experience shows that
*           if the solver is restarted from a better point, it is faster.
            m_locate.Reslim    =  (%reslim% ) * 60;
            SOLVE m_locate USING MIP MINIMIZING v_tot_cost;
            if ( EXECERROR > 0, abort "internal error in xxxx");
*$ontext
*
*           Try re-starting solver twice if non-optimal or infeasible
            if(  (m_locate.modelstat eq 7) OR (m_locate.modelstat eq 4) OR (m_locate.solvestat eq 3),
               m_locate.Reslim    =  60;
               SOLVE m_locate USING MIP MINIMIZING v_tot_cost;
            );

*           Now we should have a good starting point. Give it some time now.
            if(  (m_locate.modelstat eq 7) OR (m_locate.modelstat eq 4) OR (m_locate.solvestat eq 3),
               m_locate.Reslim    =  (%reslim% ) * 60;
               SOLVE m_locate USING MIP MINIMIZING v_tot_cost;
            );

* Calculate elapsed time for solving model
p_solveInfo("elapsedtime") = (jnow - starttime)*24*3600;


