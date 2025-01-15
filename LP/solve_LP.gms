* --- Solve model --
*-------------------


*lim col=0
*limrow =0
m_locateLP.solprint=1;
*  eqation.m


Option LP = osicplex;
* OSICPLEX, CBC or SOPLEX
m_locateLP.reslim = 30*60;

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

* --- Fix variables with known outcome to avoid varibales in equations

m_locateLP.holdfixed = 1;


*if ( %holdfixed_var% = 1,

*$include holdfixed_var.gms
*);


$ifi %distConstr%==1 p_distConstraint = 1;
v_feedstock.fx(b_fuel,i,g) $ ((distance(i,g) > 1000) and p_distConstraint)= 0 ;

display  v_feedstock.l, v_feedstock.up;


m_locateLP.savepoint = 1;
m_locateLP.Reslim    =  %reslim% * 60;
m_locateLP.optcr= 0.%gap%;

Option BRatio = 1.0;

m_locateLP.threads=%threads%;


*%fixedlocations%

* indicate using MIP start values or not
*m_locateLP.integer4 = %mipstart%;
$ontext
* startvalues set to 1, to have starting vaules
if ( %start_value1% = 1,
$include start_value_1.gms
);

execute_loadpoint '%startValueFile%'
J
v_feedstock
v_y_sales
v_y
v_transport_cost
v_feedstock_cost
v_production_cost
v_fueltransport_cost
v_tot_demand
v_tot_feedstock

v_biofuelEmis
v_biofuelEmis_atI
v_fossil_emissions
v_totEmissions

v_tot_cost

v_yEnergy
*v_blend_rate
v_endY
v_redY_cost

;
$offtext

execute_unload 'debug_LP.gdx';

if(execError gt 0,
    display "Tried to load restart values, but got an error.";
   execError = 0;
);
*$offtext



*           === SOLVE the model ===
*           (minimizing the weighted sum of squared deviations under constraints)

*           The first solve may be either far off or perfect (if starting values are good)
*           We give just a little time at this point, because experience shows that
*           if the solver is restarted from a better point, it is faster.
            m_locateLP.Reslim    =  20;
            SOLVE m_locateLP USING LP MINIMIZING v_tot_cost;
            if ( EXECERROR > 0, abort "internal error in xxxx");
*$ontext
*
*           Try re-starting solver twice if non-optimal or infeasible
            if(  (m_locateLP.modelstat eq 7) OR (m_locateLP.modelstat eq 4) OR (m_locateLP.solvestat eq 3),
               m_locateLP.Reslim    =  60;
               SOLVE m_locateLP USING LP MINIMIZING v_tot_cost;
            );

*           Now we should have a good starting point. Give it some time now.
            if(  (m_locateLP.modelstat eq 7) OR (m_locateLP.modelstat eq 4) OR (m_locateLP.solvestat eq 3),
               m_locateLP.Reslim    =  (%reslim% ) * 60;
               SOLVE m_locateLP USING LP MINIMIZING v_tot_cost;
            );

*$offtext
* Calculate elapsed time for solving model
p_solveInfo("elapsedtime") = (jnow - starttime)*24*3600;


display feedstock;
