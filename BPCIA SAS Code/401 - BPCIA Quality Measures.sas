options minoperator mlogic;
/***********************************************************/
*********************************************************
BPCIA: 401 Quality Measure Workbook
Code to create the Qaulity Measure for the BPCI Advanced
*********************************************************
*********************************************************;
libname bpcia "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets";
libname out "R:\data\HIPAA\BPCIA_BPCI Advanced\07 - Processed Data";
%include "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code\000 - BPCIA_Interface_BPIDs.sas";

****** REFERENCE PROGRAMS ***********************************************************************************;
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";

%let exportDir=R:\data\HIPAA\BPCIA_BPCI Advanced\11 - Outside Data Sources;


/* Macro to create the Quality Measure Worksheet which includes (Measure Score, Percentile, Percentile rounded and percentile Raw) */
%macro Quality_Measure (dataset, Measure, Name,type,date,code,max);
data &type._Table_0;
	set bpcia.&dataset.;
	where Measure_ID = "&Measure.";
run;

/*Isolating the Measure Scores for the specific measure */
data scores;
	set &type._Table_0;
	keep score;
	where score ne . ; 
run;

proc sort data = scores;
	by score;
run;

/*Finding the unique list of scores for the specific measure*/
proc sort data = scores nodupkey out = scores_unique;
	by score;
run;

/*Joining the two scores tables together to find the number of scores that are greater than or equal to a specific score */
proc sql;
	create table scores_greater as
	select A.Score
		 , B.Score as Score_Plus
	from scores_unique as a join scores as b on a.score <= b.score
	;

/*Counting the number of scores greater than or equal to a specfic score*/
	create table score_summary as
	select Score
		 , count(*) as Scores_Greater_Equal
	from scores_greater
	group by Score
	;
quit;

/*Generating the total count of all the scores present for specific Measure */ 
proc sql noprint;
	select max(Scores_Greater_Equal)
	into :row_total
	from score_summary
	;
quit;

/*Finding the percentiles by dividing the (number of scores greater than or equal to a specific score) by the (total number of scores present specific to the measure) */ 
proc sql;
	create table percentiles as
	select Score
	     , Floor((Scores_Greater_Equal / &row_total.)*100) as Percentile_RAW
		 , Scores_Greater_Equal / &row_total. as Percentile_RAW_Not_Rounded
	from score_summary
	;
quit; 


/*Creating the final outcome table */
proc sql ;
 create table Table_&type. as
 select distinct 
 		"&Name." as Measure length = 255
		,a.Measure_Period_Start
		,a.Measure_Period
		,b.BPID
 		,a.CCN
		,b.Anchor_Fac_Code_Name as Anchor_Facility
		,case when a.Score=. then 'N/A' else put (c.Score,best6.) 
					end as Measure_Score
		,case when a.score=. then 'N/A' else put(c.Percentile_RAW,3.)
 					end as Measure_Pcnt
		,case when a.score=. then 'N/A' else  put(c.Percentile_RAW,3.)
 					end as Measure_Pcnt_RAW
		,case when a.score=. then 'N/A' else put(c.Percentile_RAW_Not_Rounded,best12.)
 					end as Measure_Pcnt_RAW_Not_Rounded
from &type._Table_0 as a
inner join out.all_epi_detail as b
on a.CCN = b.anchor_ccn 
left join percentiles as c 
on a.score = c.score 
;
quit ; 

/*Reorganizing the final table to include the Measurement Percentile*/ 
 proc sql ; 
	 create table Final_Table_&type._&date.  as
	 select distinct
		 a.Measure
%if &type. = Mort  %then %do ; 
		,"CABG" as Clinical_Episode_Name 
		,b.Coronary_artery_bypass_graft as CABG
%end;
%else %if &type. = PSI  %then %do ; 
		,"All Inpatient" as Clinical_Episode_Name 
		,b.ALL_IP as PSI
%end; 
%else %if &type. = Comp  %then %do ; 
		,"Major joint - lower extr and Double joint - lower extr" as Clinical_Episode_Name 
		,b.Major_joint_replacement_of_the_l as Comp
		,b.Double_joint_replacement_of_the as Double
%end; 
%else %if &type. = Heart  %then %do ; 
		,"AMI" as Clinical_Episode_Name 
		,b.Acute_myocardial_infarction as AMI
%end; 
%else %if &type. = Readmit  %then %do ; 
		,"All" as Clinical_Episode_Name 
		,b.ALL as All
%end; 
		 ,a.Measure_Period_Start
		 ,a.Measure_Period
		 ,a.BPID
		 ,a.CCN
		 ,a.Anchor_Facility
		 ,a.Measure_Score
   		 ,case when a.Measure_Pcnt = 'N/A' then "N/A"
	        when a.Measure_Pcnt = '  0' then "0th"
			when substr(a.Measure_Pcnt,2,2)="11" then a.Measure_Pcnt||"th"
			when substr(a.Measure_Pcnt,2,2)="12" then a.Measure_Pcnt||"th"
			when substr(a.Measure_Pcnt,2,2)="13" then a.Measure_Pcnt||"th"
		 	when substr(a.Measure_Pcnt,3,1)="1" then a.Measure_Pcnt||"st"
					when substr(a.Measure_Pcnt,3,1)="2" then a.Measure_Pcnt||"nd"
					when substr(a.Measure_Pcnt,3,1)="3" then a.Measure_Pcnt||"rd"
					else a.Measure_Pcnt||"th"
					end as Measure_Percentile 	
		,a.Measure_Pcnt_RAW	
		,a.Measure_Pcnt_RAW_Not_Rounded
%if &max. = 1 %then %do ;
		,1 as max_date_flag 
%end ; 
%else  %do;
		,0 as max_date_flag 
%end; 

	from Table_&type. as a
	left join bpcia.bpcia_episode_initiator_info as b
	on a.BPID = b.BPCI_Advanced_ID_Number_2

;
quit; 


 %mend Quality_Measure; 

/*Macro Calls for the Qaulity Measures*/

  /*MACRO CALLS FOR - QM - 20181008 */;
  %Quality_Measure(quality_measure_QM_20181008,MORT_30_CABG, CABG 30-Day Mortality Rate, Mort, 20181008,0,1) ; 
  %Quality_Measure(quality_measure_QM_20181008,PSI_90_SAFETY, Patient Safety Indicators , PSI, 20181008,0,1) ; 
  %Quality_Measure(quality_measure_QM_20181008,COMP_HIP_KNEE, THA/TKA Complication Rate, Comp, 20181008,0,1) ; 
  %Quality_Measure(measure_unplanned_QM_20181008,EDAC_30_AMI, Excess Days in Acute Care 30 Days after AMI Hospitalization ,Heart, 20181008,0,1) ; 
  %Quality_Measure(measure_unplanned_QM_20181008,READM_30_HOSP_WIDE, All-Cause 30-Day Unplanned Hospital Readmission Rate, Readmit, 20181008,0,1) ; 

/*MACRO CALLS FOR - QM - 20180523*/;
  %Quality_Measure(quality_measure_QM_20180523,MORT_30_CABG, CABG 30-Day Mortality Rate, Mort, 20180523,0,0) ; 
  %Quality_Measure(quality_measure_QM_20180523,PSI_90_SAFETY, Patient Safety Indicators , PSI, 20180523,0,0) ; 
  %Quality_Measure(quality_measure_QM_20180523,COMP_HIP_KNEE, THA/TKA Complication Rate, Comp, 20180523,0,0) ; 
  %Quality_Measure(measure_unplanned_QM_20180523,EDAC_30_AMI, Excess Days in Acute Care 30 Days after AMI Hospitalization ,Heart, 20180523,0,0) ; 
  %Quality_Measure(measure_unplanned_QM_20180523,READM_30_HOSP_WIDE, All-Cause 30-Day Unplanned Hospital Readmission Rate, Readmit, 20180523,0,0) ; 

  /*MACRO CALLS FOR - QM - 201611*/;
   %Quality_Measure(measure_unplanned_QM_201611,MORT_30_CABG, CABG 30-Day Mortality Rate, Mort, 201611,1,0) ; 
  %Quality_Measure(quality_measure_QM_201611,PSI_90_SAFETY, Patient Safety Indicators , PSI, 201611,1,0) ; 
  %Quality_Measure(quality_measure_QM_201611,COMP_HIP_KNEE, THA/TKA Complication Rate, Comp, 201611,1,0) ; 
/*  %Quality_Measure(measure_unplanned_QM_201611,EDAC_30_AMI, Excess Days in Acute Care 30 Days after AMI Hospitalization ,Heart, 201611) ; */
  %Quality_Measure(measure_unplanned_QM_201611,READM_30_HOSP_WIDE, All-Cause 30-Day Unplanned Hospital Readmission Rate, Readmit, 201611,1,0) ; 

    /*MACRO CALLS FOR - QM - 201605*/;
  %Quality_Measure(measure_unplanned_QM_201605,MORT_30_CABG, CABG 30-Day Mortality Rate, Mort, 201605,1,0) ; 
  %Quality_Measure(quality_measure_QM_201605,PSI_90_SAFETY, Patient Safety Indicators , PSI, 201605,1,0) ; 
  %Quality_Measure(quality_measure_QM_201605,COMP_HIP_KNEE, THA/TKA Complication Rate, Comp, 201605,1,0) ; 
/*  %Quality_Measure(measure_unplanned_QM_201611,EDAC_30_AMI, Excess Days in Acute Care 30 Days after AMI Hospitalization ,Heart, 201611) ; */
  %Quality_Measure(measure_unplanned_QM_201605,READM_30_HOSP_WIDE, All-Cause 30-Day Unplanned Hospital Readmission Rate, Readmit, 201605,1,0) ; 

      /*MACRO CALLS FOR - QM - 201505*/;
/*    %Quality_Measure(measure_unplanned_QM_201505,MORT_30_CABG, CABG 30-Day Mortality Rate, Mort, 201505,1) ; */
  %Quality_Measure(quality_measure_QM_201505,PSI_90_SAFETY, Patient Safety Indicators , PSI, 201505,1,0) ; 
  %Quality_Measure(quality_measure_QM_201505,COMP_HIP_KNEE, THA/TKA Complication Rate, Comp, 201505,1,0) ; 
/*  %Quality_Measure(measure_unplanned_QM_201611,EDAC_30_AMI, Excess Days in Acute Care 30 Days after AMI Hospitalization ,Heart, 201611) ; */
  %Quality_Measure(quality_measure_QM_201505,READM_30_HOSP_WIDE, All-Cause 30-Day Unplanned Hospital Readmission Rate, Readmit, 201505,1,0) ; 

/*Stacking the Final Tables */;

/**Macro to stack and out all the measures for all the CCNS that are present within the Source files */;
  %macro Quality_Measure_full(name);
	data Quality_Measure_&name._0 ;
	      set final_table_comp: (where = (Comp = '1' or Double = '1') )
		  	   final_table_Heart: (where = ( AMI = '1') ) 
			   final_table_Mort: (where = (CABG = '1') )
				final_table_Readmit: (where = (All = '1') )
				final_table_PSI: (where = (PSI = '1') ) ;
				BPID_CCN_Key = BPID||"_"||CCN ; 
				
	run ;

	*Splitting the stacked file into two files - one for Premier the other for Milliman. */;
	data Quality_Measure_&name. ;
		set Quality_Measure_&name._0 ; 
	%if &name. = Premier %then %do ;
				where BPID in (&PMR_EI_lst.) ; 
	%end;
	%else %do ; 
				where BPID in (&NON_PMR_EI_lst.) ; 
	%end; 
		run ; 


	proc sort 
				data = Quality_Measure_&name.
							out= bpcia.Quality_Measure_&name. ;
				by   BPID CCN Measure Measure_Period_Start   ;
	run ; 

	proc sort 
				data = Quality_Measure_&name._0
							out=bpcia.Quality_Measure_full ;
				by   BPID CCN Measure Measure_Period_Start   ;
	run ; 

%sas_2_csv(bpcia.Quality_Measure_&name.,BPCIA Quality Measures &name..csv) ; 

%mend Quality_Measure_full;

%Quality_Measure_full(Premier) ; 
%Quality_Measure_full(Milliman) ; 

%sas_2_csv(bpcia.Quality_Measure_full,BPCIA Quality Measures Full.csv) ; 
/**/
  %macro Quality_Measure_latest(name, type);
data Quality_Measure_latest_date (keep=CCN BPID Measure Anchor_Facility Measure_Pcnt_RAW_Not_Rounded ); 
set bpcia.Quality_Measure_full ; 
where max_date_flag = 1 ;
run ; 

proc sort data =Quality_Measure_latest_date ; 
by  bpid ccn Anchor_Facility ; 
run ; 


proc transpose data=Quality_Measure_latest_date out=Quality_Measure_latest_date_0 ;
  by bpid ccn Anchor_Facility;
  id measure;
  var Measure_Pcnt_RAW_Not_Rounded;
run;

data bpcia.Quality_Measure_latest_date;
set Quality_Measure_latest_date_0;
BPID_CCN_Key = BPID||"_"||CCN ; 
run ;

data bpcia.Quality_Measure_latest_&name. ;
		set bpcia.Quality_Measure_latest_date ; 
	%if &name. = Premier %then %do ;
				where BPID in (&PMR_EI_lst.) ; 
				%end;
				%else %do ; 
				where BPID in (&NON_PMR_EI_lst.) ; 
				%end; 
		run ; 

%sas_2_csv(bpcia.Quality_Measure_latest_&name.,BPCIA_Quality_Measures_Latest_Date_&name..csv) ; 

%mend Quality_Measure_latest;

%Quality_Measure_latest(Premier) ; 
%Quality_Measure_latest(Milliman) ; 

%sas_2_csv(bpcia.Quality_Measure_latest_date,BPCIA_Quality_Measures_Latest_Date.csv) ; 


%macro Quality_Measure_demo(bpid1,bpid2,bpid3,bpid4,bpid5);

	data Quality_Measure_demo_0 ;
	      set final_table_comp: (where = (Comp = '1' ) )
		  	   final_table_Heart: (where = ( AMI = '1') ) 
			   final_table_Mort: (where = (CABG = '1') )
				final_table_Readmit: (where = (All = '1') )
				final_table_PSI: (where = (PSI = '1') ) ;
				BPID_CCN_Key = BPID||"_"||CCN ; 

	 if BPID in ("&bpid1.-0000","&bpid2.-0000","&bpid3.-0000","&bpid4.-0000","&bpid5.-0000");

	*20180610 Update - Overwrite BPID;
	if BPID ="&bpid1.-0000" then BPID = "1111-0000";
	else if BPID = "&bpid2.-0000" then BPID = "2222-0000";
	else if BPID = "&bpid3.-0000" then BPID = "3333-0000";
	else if BPID = "&bpid4.-0000" then BPID = "4444-0000";
	else if BPID = "&bpid5.-0000" then BPID = "5555-0000";
	run ;

	proc sort data = Quality_Measure_demo_0 
							out= bpcia.Quality_Measure_demo ;
	by  BPID CCN Measure Measure_Period_Start  ;
	run ; 

	
%sas_2_csv(bpcia.Quality_Measure_demo,BPCIA_Quality_Measures_Demo.csv) ; 

%mend Quality_Measure_demo;

%Quality_Measure_demo(1032,1075,1125,1167,1148) ; 


  %macro Quality_Measure_latest_demo(name);
data Quality_Measure_latest_&name. (keep=CCN BPID Measure Anchor_Facility Measure_Pcnt_RAW_Not_Rounded ); 
set bpcia.Quality_Measure_&name. ; 
where max_date_flag = 1 ;
run ; 

proc sort data =Quality_Measure_latest_&name. ; 
by  bpid ccn Anchor_Facility ; 
run ; 


proc transpose data=Quality_Measure_latest_&name. out=Quality_Measure_latest_&name._0 ;
  by bpid ccn Anchor_Facility;
  id measure;
  var Measure_Pcnt_RAW_Not_Rounded;
run;

data bpcia.Quality_Measure_latest_&name.;
set Quality_Measure_latest_&name._0;
BPID_CCN_Key = BPID||"_"||CCN ; 
run ;

data bpcia.Quality_Measure_latest_&name. ;
		set bpcia.Quality_Measure_latest_&name. ; 
		run ; 

%sas_2_csv(bpcia.Quality_Measure_latest_&name.,BPCIA_Quality_Measures_Latest_Date_&name..csv) ; 

%mend Quality_Measure_latest;

%Quality_Measure_latest(Demo) ; 
 

