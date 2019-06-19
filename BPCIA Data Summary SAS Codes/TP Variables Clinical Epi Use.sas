%let  _sdtm=%sysfunc(datetime());
*********************************************************
*********************************************************
BPCIA: 
Code to calculate the use of target price variables
*********************************************************
*********************************************************;
options mprint;

***** USER INPUTS ******************************************************************************************;
%let mode = main; *main = main interface, base = baseline interface;

%let label = y201905;


proc printto;run;


****** REFERENCE PROGRAMS ***********************************************************************************;
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";

%let main = H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code;
%include "&main.\000 - Formats - BPCIA.sas";

%include "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code\000 - BPCIA_Interface_BPIDs.sas";

****** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
/*libname out "&dataDir.\07 - Processed Data";*/
libname tp "&dataDir.\08 - Target Price Data";

libname ref "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets" ;

%macro modesetup;
%if &mode.=main %then %do;
libname out "&dataDir.\07 - Processed Data\";
proc printto log="R:\data\HIPAA\BPCIA_BPCI Advanced\88 - Documentation\50 - BPCI Advanced 2019\Checking Documentation\_Data Summary\TP Variables Epi Use_&label._&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=base %then %do;
libname out "&dataDir.\07 - Processed Data\Baseline Interface Demo";
proc printto log="R:\data\HIPAA\BPCIA_BPCI Advanced\88 - Documentation\50 - BPCI Advanced 2019\Checking Documentation\_Data Summary\Baseline TP Variables Epi Use_&label._&sysdate..log" print=print new;
run;
%end;
%mend modesetup;

%modesetup;


data baseline;
	set out.tp_ybase_:;
	format PERIOD $12. CLINICAL_EPISODE $100.;
	PERIOD = 'Baseline';
	if ANCHOR_TYPE = 'ip' then ANC_TYPE = 'IP';
	else ANC_TYPE = 'OP';
	CLINICAL_EPISODE = strip(ANC_TYPE) || ' - ' || strip(EPISODE_GROUP_NAME);
	Client=0;
	if BPID in (&PMR_EI_lst.) then Client=1;
run;

data perf;
	set out.tp_&label._:;
	format PERIOD $12. CLINICAL_EPISODE $100.;
	PERIOD = 'Performance';
	if ANCHOR_TYPE = 'ip' then ANC_TYPE = 'IP';
	else ANC_TYPE = 'OP';
	CLINICAL_EPISODE = strip(ANC_TYPE) || ' - ' || strip(EPISODE_GROUP_NAME);
	Client=0;
	if BPID in (&PMR_EI_lst.) then Client=1;
run;

data tp;
	set baseline perf;
run;


proc sql;
	create table sasout as 
	select Client, PERIOD, PERFORMANCE_PERIOD, CLINICAL_EPISODE,
		count(*) as Episodes,
		sum(ANY_DUAL) as ANY_DUAL,
		sum(APC_5193) as APC_5193,
		sum(APC_5194) as APC_5194,
		sum(APC_5232) as APC_5232,
		sum(APC_5432) as APC_5432,
		sum(CANCER_IMMUNE) as CANCER_IMMUNE,
		sum(CHF_COPD) as CHF_COPD,
		sum(CHF_RENAL) as CHF_RENAL,
		sum(COPD_CARD_RESP_FAIL) as COPD_CARD_RESP_FAIL,
		sum(DIABETES_CHF) as DIABETES_CHF,
		sum(DISABLED_HCC110) as DISABLED_HCC110,
		sum(DISABLED_HCC176) as DISABLED_HCC176,
		sum(DISABLED_HCC34) as DISABLED_HCC34,
		sum(DISABLED_HCC46) as DISABLED_HCC46,
		sum(DISABLED_HCC54) as DISABLED_HCC54,
		sum(DISABLED_HCC55) as DISABLED_HCC55,
		sum(DISABLED_HCC6) as DISABLED_HCC6,
		sum(DRG_CD_062) as DRG_CD_062,
		sum(DRG_CD_063) as DRG_CD_063,
		sum(DRG_CD_064) as DRG_CD_064,
		sum(DRG_CD_065) as DRG_CD_065,
		sum(DRG_CD_066) as DRG_CD_066,
		sum(DRG_CD_178) as DRG_CD_178,
		sum(DRG_CD_179) as DRG_CD_179,
		sum(DRG_CD_191) as DRG_CD_191,
		sum(DRG_CD_192) as DRG_CD_192,
		sum(DRG_CD_193) as DRG_CD_193,
		sum(DRG_CD_194) as DRG_CD_194,
		sum(DRG_CD_195) as DRG_CD_195,
		sum(DRG_CD_202) as DRG_CD_202,
		sum(DRG_CD_203) as DRG_CD_203,
		sum(DRG_CD_217) as DRG_CD_217,
		sum(DRG_CD_218) as DRG_CD_218,
		sum(DRG_CD_219) as DRG_CD_219,
		sum(DRG_CD_220) as DRG_CD_220,
		sum(DRG_CD_221) as DRG_CD_221,
		sum(DRG_CD_223) as DRG_CD_223,
		sum(DRG_CD_224) as DRG_CD_224,
		sum(DRG_CD_225) as DRG_CD_225,
		sum(DRG_CD_226) as DRG_CD_226,
		sum(DRG_CD_227) as DRG_CD_227,
		sum(DRG_CD_232) as DRG_CD_232,
		sum(DRG_CD_233) as DRG_CD_233,
		sum(DRG_CD_234) as DRG_CD_234,
		sum(DRG_CD_235) as DRG_CD_235,
		sum(DRG_CD_236) as DRG_CD_236,
		sum(DRG_CD_243) as DRG_CD_243,
		sum(DRG_CD_244) as DRG_CD_244,
		sum(DRG_CD_247) as DRG_CD_247,
		sum(DRG_CD_248) as DRG_CD_248,
		sum(DRG_CD_249) as DRG_CD_249,
		sum(DRG_CD_250) as DRG_CD_250,
		sum(DRG_CD_251) as DRG_CD_251,
		sum(DRG_CD_266) as DRG_CD_266,
		sum(DRG_CD_267) as DRG_CD_267,
		sum(DRG_CD_273) as DRG_CD_273,
		sum(DRG_CD_274) as DRG_CD_274,
		sum(DRG_CD_281) as DRG_CD_281,
		sum(DRG_CD_282) as DRG_CD_282,
		sum(DRG_CD_292) as DRG_CD_292,
		sum(DRG_CD_293) as DRG_CD_293,
		sum(DRG_CD_309) as DRG_CD_309,
		sum(DRG_CD_310) as DRG_CD_310,
		sum(DRG_CD_330) as DRG_CD_330,
		sum(DRG_CD_331) as DRG_CD_331,
		sum(DRG_CD_378) as DRG_CD_378,
		sum(DRG_CD_379) as DRG_CD_379,
		sum(DRG_CD_389) as DRG_CD_389,
		sum(DRG_CD_390) as DRG_CD_390,
		sum(DRG_CD_442) as DRG_CD_442,
		sum(DRG_CD_443) as DRG_CD_443,
		sum(DRG_CD_454) as DRG_CD_454,
		sum(DRG_CD_455) as DRG_CD_455,
		sum(DRG_CD_460) as DRG_CD_460,
		sum(DRG_CD_462) as DRG_CD_462,
		sum(DRG_CD_470) as DRG_CD_470,
		sum(DRG_CD_472) as DRG_CD_472,
		sum(DRG_CD_473) as DRG_CD_473,
		sum(DRG_CD_481) as DRG_CD_481,
		sum(DRG_CD_482) as DRG_CD_482,
		sum(DRG_CD_493) as DRG_CD_493,
		sum(DRG_CD_494) as DRG_CD_494,
		sum(DRG_CD_519) as DRG_CD_519,
		sum(DRG_CD_520) as DRG_CD_520,
		sum(DRG_CD_534) as DRG_CD_534,
		sum(DRG_CD_535) as DRG_CD_535,
		sum(DRG_CD_536) as DRG_CD_536,
		sum(DRG_CD_603) as DRG_CD_603,
		sum(DRG_CD_683) as DRG_CD_683,
		sum(DRG_CD_684) as DRG_CD_684,
		sum(DRG_CD_690) as DRG_CD_690,
		sum(DRG_CD_871) as DRG_CD_871,
		sum(DRG_CD_872) as DRG_CD_872,
		sum(FRACTURE_FLAG) as FRACTURE_FLAG,
		sum(HCC_CNT_1_3) as HCC_CNT_1_3,
		sum(HCC_CNT_4_6) as HCC_CNT_4_6,
		sum(HCC_CNT_7_PLUS) as HCC_CNT_7_PLUS,
		sum(HCC1) as HCC1,
		sum(HCC10) as HCC10,
		sum(HCC100) as HCC100,
		sum(HCC103) as HCC103,
		sum(HCC104) as HCC104,
		sum(HCC106) as HCC106,
		sum(HCC107) as HCC107,
		sum(HCC108) as HCC108,
		sum(HCC11) as HCC11,
		sum(HCC110) as HCC110,
		sum(HCC111) as HCC111,
		sum(HCC112) as HCC112,
		sum(HCC114) as HCC114,
		sum(HCC115) as HCC115,
		sum(HCC12) as HCC12,
		sum(HCC122) as HCC122,
		sum(HCC124) as HCC124,
		sum(HCC134) as HCC134,
		sum(HCC135) as HCC135,
		sum(HCC136) as HCC136,
		sum(HCC137) as HCC137,
		sum(HCC157) as HCC157,
		sum(HCC158) as HCC158,
		sum(HCC161) as HCC161,
		sum(HCC162) as HCC162,
		sum(HCC166) as HCC166,
		sum(HCC167) as HCC167,
		sum(HCC169) as HCC169,
		sum(HCC17) as HCC17,
		sum(HCC170) as HCC170,
		sum(HCC173) as HCC173,
		sum(HCC176) as HCC176,
		sum(HCC18) as HCC18,
		sum(HCC186) as HCC186,
		sum(HCC188) as HCC188,
		sum(HCC189) as HCC189,
		sum(HCC19) as HCC19,
		sum(HCC2) as HCC2,
		sum(HCC21) as HCC21,
		sum(HCC22) as HCC22,
		sum(HCC23) as HCC23,
		sum(HCC27) as HCC27,
		sum(HCC28) as HCC28,
		sum(HCC29) as HCC29,
		sum(HCC33) as HCC33,
		sum(HCC34) as HCC34,
		sum(HCC35) as HCC35,
		sum(HCC39) as HCC39,
		sum(HCC40) as HCC40,
		sum(HCC46) as HCC46,
		sum(HCC47) as HCC47,
		sum(HCC48) as HCC48,
		sum(HCC54) as HCC54,
		sum(HCC55) as HCC55,
		sum(HCC57) as HCC57,
		sum(HCC58) as HCC58,
		sum(HCC6) as HCC6,
		sum(HCC70) as HCC70,
		sum(HCC71) as HCC71,
		sum(HCC72) as HCC72,
		sum(HCC73) as HCC73,
		sum(HCC74) as HCC74,
		sum(HCC75) as HCC75,
		sum(HCC76) as HCC76,
		sum(HCC77) as HCC77,
		sum(HCC78) as HCC78,
		sum(HCC79) as HCC79,
		sum(HCC8) as HCC8,
		sum(HCC80) as HCC80,
		sum(HCC82) as HCC82,
		sum(HCC83) as HCC83,
		sum(HCC84) as HCC84,
		sum(HCC85) as HCC85,
		sum(HCC86) as HCC86,
		sum(HCC87) as HCC87,
		sum(HCC88) as HCC88,
		sum(HCC9) as HCC9,
		sum(HCC96) as HCC96,
		sum(HCC99) as HCC99,
		sum(LTI) as LTI,
		sum(ORIGDS) as ORIGDS,
		sum(PRIOR_HOSP_W_ANY_IP_FLAG_90) as PRIOR_HOSP_W_ANY_IP_FLAG_90,
		sum(SEPSIS_CARD_RESP_FAIL) as SEPSIS_CARD_RESP_FAIL,
		sum(TKA_FLAG) as TKA_FLAG,
		sum(TKA_FRACTURE_FLAG) as TKA_FRACTURE_FLAG
	from tp
	group by Client, PERIOD, PERFORMANCE_PERIOD, CLINICAL_EPISODE;
quit;


%MACRO EXPORT;
%if &mode.=main %then %do;
	proc export data= sasout
	    outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\88 - Documentation\50 - BPCI Advanced 2019\Checking Documentation\_Data Summary\sasout_TP Variable Epi Use_&label._&sysdate..csv"
	    dbms=csv replace; 
	run;
%end;
%else %if &mode.=base %then %do;
	proc export data= sasout
	    outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\88 - Documentation\50 - BPCI Advanced 2019\Checking Documentation\_Data Summary\sasout_Baseline TP Variable Epi Use_&label._&sysdate..csv"
	    dbms=csv replace; 
	run;
%end;
%mend EXPORT;

%EXPORT;

proc printto;run;
%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;


