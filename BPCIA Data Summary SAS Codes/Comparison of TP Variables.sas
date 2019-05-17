%let  _sdtm=%sysfunc(datetime());
*********************************************************
*********************************************************
BPCIA: 
Code to compare how often target price variables change
*********************************************************
*********************************************************;
options mprint;

***** USER INPUTS ******************************************************************************************;
%let mode = main; *main = main interface, base = baseline interface;


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
proc printto log="R:\data\HIPAA\BPCIA_BPCI Advanced\88 - Documentation\50 - BPCI Advanced 2019\Checking Documentation\_Data Summary\Comparison of TP Variables_&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=base %then %do;
libname out "&dataDir.\07 - Processed Data\Baseline Interface Demo";
proc printto log="R:\data\HIPAA\BPCIA_BPCI Advanced\88 - Documentation\50 - BPCI Advanced 2019\Checking Documentation\_Data Summary\Baseline Comparison of TP Variables_&sysdate..log" print=print new;
run;
%end;
%mend modesetup;

%modesetup;


%MACRO RunHosp(bpid1,bpid2,lbl1,lbl2,label1,label2,timeper);

data t_y201810;
	set out.epi_y201810_&bpid1._&bpid2.;
	format Label $7.;
	Label = 'y201810';
run;
data t_y201811;
	set out.epi_y201811_&bpid1._&bpid2.;
	format Label $7.;
	Label = 'y201811';
run;
data t_y201812;
	set out.epi_y201812_&bpid1._&bpid2.;
	format Label $7.;
	Label = 'y201812';
run;
data t_y201901;
	set out.epi_y201901_&bpid1._&bpid2.;
	format Label $7.;
	Label = 'y201901';
run;
data t_y201902;
	set out.epi_y201902_&bpid1._&bpid2.;
	format Label $7.;
	Label = 'y201902';
run;
data t_y201903;
	set out.epi_y201903_&bpid1._&bpid2.;
	format Label $7.;
	Label = 'y201903';
run;
data t_y201904;
	set out.epi_y201904_&bpid1._&bpid2.;
	format Label $7.;
	Label = 'y201904';
run;
data t0_pre;
	set t_y201810 t_y201811 t_y201812 t_y201901 t_y201902 t_y201903 t_y201904;
	proc sort; by EPI_ID_MILLIMAN Label; 
run;
data t0;
	set t0_pre;
	by EPI_ID_MILLIMAN;
	if first.EPI_ID_MILLIMAN then epi_num=1;
	else epi_num = epi_num + 1;
	retain epi_num;

	ep_num = strip(put(epi_num,BEST12.));
run;

data t1_pre (keep= EPI_ID_MILLIMAN BPID ANCHOR_TYPE EPISODE_GROUP_NAME LABEL_&label1.
			AGE_50_&label1.
			AGE_50_SQ_&label1.
			ANY_DUAL_&label1.
			APC_2019_5193_&label1.
			APC_2019_5194_&label1.
			APC_2019_5232_&label1.
			APC_2019_5432_&label1.
			CANCER_IMMUNE_&label1.
			CHF_COPD_&label1.
			CHF_RENAL_&label1.
			COPD_CARD_RESP_FAIL_&label1.
			DIABETES_CHF_&label1.
			DISABLED_HCC110_&label1.
			DISABLED_HCC176_&label1.
			DISABLED_HCC34_&label1.
			DISABLED_HCC46_&label1.
			DISABLED_HCC54_&label1.
			DISABLED_HCC55_&label1.
			DISABLED_HCC6_&label1.
			DRG_CD_2019_062_&label1.
			DRG_CD_2019_063_&label1.
			DRG_CD_2019_064_&label1.
			DRG_CD_2019_065_&label1.
			DRG_CD_2019_066_&label1.
			DRG_CD_2019_178_&label1.
			DRG_CD_2019_179_&label1.
			DRG_CD_2019_191_&label1.
			DRG_CD_2019_192_&label1.
			DRG_CD_2019_193_&label1.
			DRG_CD_2019_194_&label1.
			DRG_CD_2019_195_&label1.
			DRG_CD_2019_202_&label1.
			DRG_CD_2019_203_&label1.
			DRG_CD_2019_217_&label1.
			DRG_CD_2019_218_&label1.
			DRG_CD_2019_219_&label1.
			DRG_CD_2019_220_&label1.
			DRG_CD_2019_221_&label1.
			DRG_CD_2019_223_&label1.
			DRG_CD_2019_224_&label1.
			DRG_CD_2019_225_&label1.
			DRG_CD_2019_226_&label1.
			DRG_CD_2019_227_&label1.
			DRG_CD_2019_232_&label1.
			DRG_CD_2019_233_&label1.
			DRG_CD_2019_234_&label1.
			DRG_CD_2019_235_&label1.
			DRG_CD_2019_236_&label1.
			DRG_CD_2019_243_&label1.
			DRG_CD_2019_244_&label1.
			DRG_CD_2019_247_&label1.
			DRG_CD_2019_248_&label1.
			DRG_CD_2019_249_&label1.
			DRG_CD_2019_250_&label1.
			DRG_CD_2019_251_&label1.
			DRG_CD_2019_266_&label1.
			DRG_CD_2019_267_&label1.
			DRG_CD_2019_273_&label1.
			DRG_CD_2019_274_&label1.
			DRG_CD_2019_281_&label1.
			DRG_CD_2019_282_&label1.
			DRG_CD_2019_292_&label1.
			DRG_CD_2019_293_&label1.
			DRG_CD_2019_309_&label1.
			DRG_CD_2019_310_&label1.
			DRG_CD_2019_330_&label1.
			DRG_CD_2019_331_&label1.
			DRG_CD_2019_378_&label1.
			DRG_CD_2019_379_&label1.
			DRG_CD_2019_389_&label1.
			DRG_CD_2019_390_&label1.
			DRG_CD_2019_442_&label1.
			DRG_CD_2019_443_&label1.
			DRG_CD_2019_454_&label1.
			DRG_CD_2019_455_&label1.
			DRG_CD_2019_460_&label1.
			DRG_CD_2019_462_&label1.
			DRG_CD_2019_470_&label1.
			DRG_CD_2019_472_&label1.
			DRG_CD_2019_473_&label1.
			DRG_CD_2019_481_&label1.
			DRG_CD_2019_482_&label1.
			DRG_CD_2019_493_&label1.
			DRG_CD_2019_494_&label1.
			DRG_CD_2019_519_&label1.
			DRG_CD_2019_520_&label1.
			DRG_CD_2019_534_&label1.
			DRG_CD_2019_535_&label1.
			DRG_CD_2019_536_&label1.
			DRG_CD_2019_603_&label1.
			DRG_CD_2019_683_&label1.
			DRG_CD_2019_684_&label1.
			DRG_CD_2019_690_&label1.
			DRG_CD_2019_871_&label1.
			DRG_CD_2019_872_&label1.
			FRACTURE_FLAG_&label1.
			HCC_CNT_1_3_&label1.
			HCC_CNT_4_6_&label1.
			HCC_CNT_7_PLUS_&label1.
			HCC1_&label1.
			HCC10_&label1.
			HCC100_&label1.
			HCC103_&label1.
			HCC104_&label1.
			HCC106_&label1.
			HCC107_&label1.
			HCC108_&label1.
			HCC11_&label1.
			HCC110_&label1.
			HCC111_&label1.
			HCC112_&label1.
			HCC114_&label1.
			HCC115_&label1.
			HCC12_&label1.
			HCC122_&label1.
			HCC124_&label1.
			HCC134_&label1.
			HCC135_&label1.
			HCC136_&label1.
			HCC137_&label1.
			HCC157_&label1.
			HCC158_&label1.
			HCC161_&label1.
			HCC162_&label1.
			HCC166_&label1.
			HCC167_&label1.
			HCC169_&label1.
			HCC17_&label1.
			HCC170_&label1.
			HCC173_&label1.
			HCC176_&label1.
			HCC18_&label1.
			HCC186_&label1.
			HCC188_&label1.
			HCC189_&label1.
			HCC19_&label1.
			HCC2_&label1.
			HCC21_&label1.
			HCC22_&label1.
			HCC23_&label1.
			HCC27_&label1.
			HCC28_&label1.
			HCC29_&label1.
			HCC33_&label1.
			HCC34_&label1.
			HCC35_&label1.
			HCC39_&label1.
			HCC40_&label1.
			HCC46_&label1.
			HCC47_&label1.
			HCC48_&label1.
			HCC54_&label1.
			HCC55_&label1.
			HCC57_&label1.
			HCC58_&label1.
			HCC6_&label1.
			HCC70_&label1.
			HCC71_&label1.
			HCC72_&label1.
			HCC73_&label1.
			HCC74_&label1.
			HCC75_&label1.
			HCC76_&label1.
			HCC77_&label1.
			HCC78_&label1.
			HCC79_&label1.
			HCC8_&label1.
			HCC80_&label1.
			HCC82_&label1.
			HCC83_&label1.
			HCC84_&label1.
			HCC85_&label1.
			HCC86_&label1.
			HCC87_&label1.
			HCC88_&label1.
			HCC9_&label1.
			HCC96_&label1.
			HCC99_&label1.
			LTI_&label1.
			ORIGDS_&label1.
			PRIOR_HOSP_W_ANY_IP_FLAG_90_&label1.
			SEPSIS_CARD_RESP_FAIL_&label1.
			TKA_FLAG_&label1.
			TKA_FRACTURE_FLAG_&label1.
			);
	set out.epi_&lbl1._&bpid1._&bpid2. ;

	format DRG_2019 BEST12. LABEL_&label1. $7.;
	if ANCHOR_TYPE = 'ip' then DRG_2019 = input(ANCHOR_CODE,$20.);
	else DRG_2019 = . ;

	LABEL_&label1. = "&lbl1.";

	if EPISODE_GROUP_NAME = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPISODE_GROUP_NAME = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

	if ANCHOR_TYPE = 'ip' then anchor_type_upper = 'IP';
	if ANCHOR_TYPE = 'op' then anchor_type_upper = 'OP';
	else anchor_type_upper = ANCHOR_TYPE;


	Epi_Year = year(POST_DSCH_END_DT);
	Epi_Qtr = qtr(POST_DSCH_END_DT);
	Epi_Half = 1;
	if Epi_Qtr in (3,4) then Epi_Half = 2;

	DRG_CD_2019_062=0;
	DRG_CD_2019_063=0;
	DRG_CD_2019_064=0;
	DRG_CD_2019_065=0;
	DRG_CD_2019_066=0;
	DRG_CD_2019_178=0;
	DRG_CD_2019_179=0;
	DRG_CD_2019_191=0;
	DRG_CD_2019_192=0;
	DRG_CD_2019_193=0;
	DRG_CD_2019_194=0;
	DRG_CD_2019_195=0;
	DRG_CD_2019_202=0;
	DRG_CD_2019_203=0;
	DRG_CD_2019_217=0;
	DRG_CD_2019_218=0;
	DRG_CD_2019_219=0;
	DRG_CD_2019_220=0;
	DRG_CD_2019_221=0;
	DRG_CD_2019_223=0;
	DRG_CD_2019_224=0;
	DRG_CD_2019_225=0;
	DRG_CD_2019_226=0;
	DRG_CD_2019_227=0;
	DRG_CD_2019_232=0;
	DRG_CD_2019_233=0;
	DRG_CD_2019_234=0;
	DRG_CD_2019_235=0;
	DRG_CD_2019_236=0;
	DRG_CD_2019_243=0;
	DRG_CD_2019_244=0;
	DRG_CD_2019_247=0;
	DRG_CD_2019_248=0;
	DRG_CD_2019_249=0;
	DRG_CD_2019_250=0;
	DRG_CD_2019_251=0;
	DRG_CD_2019_266=0;
	DRG_CD_2019_267=0;
	DRG_CD_2019_273=0;
	DRG_CD_2019_274=0;
	DRG_CD_2019_281=0;
	DRG_CD_2019_282=0;
	DRG_CD_2019_292=0;
	DRG_CD_2019_293=0;
	DRG_CD_2019_309=0;
	DRG_CD_2019_310=0;
	DRG_CD_2019_330=0;
	DRG_CD_2019_331=0;
	DRG_CD_2019_378=0;
	DRG_CD_2019_379=0;
	DRG_CD_2019_389=0;
	DRG_CD_2019_390=0;
	DRG_CD_2019_442=0;
	DRG_CD_2019_443=0;
	DRG_CD_2019_454=0;
	DRG_CD_2019_455=0;
	DRG_CD_2019_460=0;
	DRG_CD_2019_462=0;
	DRG_CD_2019_470=0;
	DRG_CD_2019_472=0;
	DRG_CD_2019_473=0;
	DRG_CD_2019_481=0;
	DRG_CD_2019_482=0;
	DRG_CD_2019_493=0;
	DRG_CD_2019_494=0;
	DRG_CD_2019_519=0;
	DRG_CD_2019_520=0;
	DRG_CD_2019_534=0;
	DRG_CD_2019_535=0;
	DRG_CD_2019_536=0;
	DRG_CD_2019_603=0;
	DRG_CD_2019_683=0;
	DRG_CD_2019_684=0;
	DRG_CD_2019_690=0;
	DRG_CD_2019_871=0;
	DRG_CD_2019_872=0;
	APC_2019_5193=0;
	APC_2019_5194=0;
	APC_2019_5232=0;
	APC_2019_5432=0;

	if DRG_2019 = 062 then DRG_CD_2019_062=1;
	if DRG_2019 = 063 then DRG_CD_2019_063=1;
	if DRG_2019 = 064 then DRG_CD_2019_064=1;
	if DRG_2019 = 065 then DRG_CD_2019_065=1;
	if DRG_2019 = 066 then DRG_CD_2019_066=1;
	if DRG_2019 = 178 then DRG_CD_2019_178=1;
	if DRG_2019 = 179 then DRG_CD_2019_179=1;
	if DRG_2019 = 191 then DRG_CD_2019_191=1;
	if DRG_2019 = 192 then DRG_CD_2019_192=1;
	if DRG_2019 = 193 then DRG_CD_2019_193=1;
	if DRG_2019 = 194 then DRG_CD_2019_194=1;
	if DRG_2019 = 195 then DRG_CD_2019_195=1;
	if DRG_2019 = 202 then DRG_CD_2019_202=1;
	if DRG_2019 = 203 then DRG_CD_2019_203=1;
	if DRG_2019 = 217 then DRG_CD_2019_217=1;
	if DRG_2019 = 218 then DRG_CD_2019_218=1;
	if DRG_2019 = 219 then DRG_CD_2019_219=1;
	if DRG_2019 = 220 then DRG_CD_2019_220=1;
	if DRG_2019 = 221 then DRG_CD_2019_221=1;
	if DRG_2019 = 223 then DRG_CD_2019_223=1;
	if DRG_2019 = 224 then DRG_CD_2019_224=1;
	if DRG_2019 = 225 then DRG_CD_2019_225=1;
	if DRG_2019 = 226 then DRG_CD_2019_226=1;
	if DRG_2019 = 227 then DRG_CD_2019_227=1;
	if DRG_2019 = 232 then DRG_CD_2019_232=1;
	if DRG_2019 = 233 then DRG_CD_2019_233=1;
	if DRG_2019 = 234 then DRG_CD_2019_234=1;
	if DRG_2019 = 235 then DRG_CD_2019_235=1;
	if DRG_2019 = 236 then DRG_CD_2019_236=1;
	if DRG_2019 = 243 then DRG_CD_2019_243=1;
	if DRG_2019 = 244 then DRG_CD_2019_244=1;
	if DRG_2019 = 247 then DRG_CD_2019_247=1;
	if DRG_2019 = 248 then DRG_CD_2019_248=1;
	if DRG_2019 = 249 then DRG_CD_2019_249=1;
	if DRG_2019 = 250 then DRG_CD_2019_250=1;
	if DRG_2019 = 251 then DRG_CD_2019_251=1;
	if DRG_2019 = 266 then DRG_CD_2019_266=1;
	if DRG_2019 = 267 then DRG_CD_2019_267=1;
	if DRG_2019 = 273 then DRG_CD_2019_273=1;
	if DRG_2019 = 274 then DRG_CD_2019_274=1;
	if DRG_2019 = 281 then DRG_CD_2019_281=1;
	if DRG_2019 = 282 then DRG_CD_2019_282=1;
	if DRG_2019 = 292 then DRG_CD_2019_292=1;
	if DRG_2019 = 293 then DRG_CD_2019_293=1;
	if DRG_2019 = 309 then DRG_CD_2019_309=1;
	if DRG_2019 = 310 then DRG_CD_2019_310=1;
	if DRG_2019 = 330 then DRG_CD_2019_330=1;
	if DRG_2019 = 331 then DRG_CD_2019_331=1;
	if DRG_2019 = 378 then DRG_CD_2019_378=1;
	if DRG_2019 = 379 then DRG_CD_2019_379=1;
	if DRG_2019 = 389 then DRG_CD_2019_389=1;
	if DRG_2019 = 390 then DRG_CD_2019_390=1;
	if DRG_2019 = 442 then DRG_CD_2019_442=1;
	if DRG_2019 = 443 then DRG_CD_2019_443=1;
	if DRG_2019 = 454 then DRG_CD_2019_454=1;
	if DRG_2019 = 455 then DRG_CD_2019_455=1;
	if DRG_2019 = 460 then DRG_CD_2019_460=1;
	if DRG_2019 = 462 then DRG_CD_2019_462=1;
	if DRG_2019 = 470 then DRG_CD_2019_470=1;
	if DRG_2019 = 472 then DRG_CD_2019_472=1;
	if DRG_2019 = 473 then DRG_CD_2019_473=1;
	if DRG_2019 = 481 then DRG_CD_2019_481=1;
	if DRG_2019 = 482 then DRG_CD_2019_482=1;
	if DRG_2019 = 493 then DRG_CD_2019_493=1;
	if DRG_2019 = 494 then DRG_CD_2019_494=1;
	if DRG_2019 = 519 then DRG_CD_2019_519=1;
	if DRG_2019 = 520 then DRG_CD_2019_520=1;
	if DRG_2019 = 534 then DRG_CD_2019_534=1;
	if DRG_2019 = 535 then DRG_CD_2019_535=1;
	if DRG_2019 = 536 then DRG_CD_2019_536=1;
	if DRG_2019 = 603 then DRG_CD_2019_603=1;
	if DRG_2019 = 683 then DRG_CD_2019_683=1;
	if DRG_2019 = 684 then DRG_CD_2019_684=1;
	if DRG_2019 = 690 then DRG_CD_2019_690=1;
	if DRG_2019 = 871 then DRG_CD_2019_871=1;
	if DRG_2019 = 872 then DRG_CD_2019_872=1;
	if PERF_APC = 5193 then APC_2019_5193=1;
	if PERF_APC = 5194 then APC_2019_5194=1;
	if PERF_APC = 5232 then APC_2019_5232=1;
	if PERF_APC = 5432 then APC_2019_5432=1;

	HCC_CNT = sum(of HCC1 -- HCC189);
	HCC_CNT_1_3=0;
	HCC_CNT_4_6=0;
	HCC_CNT_7_PLUS=0;
	if HCC_CNT > 0 then do;
		if HCC_CNT <= 3 then HCC_CNT_1_3=1;
		else if HCC_CNT <= 6 then HCC_CNT_4_6=1;
		else if HCC_CNT >= 7 then HCC_CNT_7_PLUS=1;
	end; 

	Age_50 = BENE_AGE-50;
	Age_50_SQ = Age_50 * Age_50;

	rename 
		AGE_50 = AGE_50_&label1.
		AGE_50_SQ = AGE_50_SQ_&label1.
		ANY_DUAL = ANY_DUAL_&label1.
		APC_2019_5193 = APC_2019_5193_&label1.
		APC_2019_5194 = APC_2019_5194_&label1.
		APC_2019_5232 = APC_2019_5232_&label1.
		APC_2019_5432 = APC_2019_5432_&label1.
		CANCER_IMMUNE = CANCER_IMMUNE_&label1.
		CHF_COPD = CHF_COPD_&label1.
		CHF_RENAL = CHF_RENAL_&label1.
		COPD_CARD_RESP_FAIL = COPD_CARD_RESP_FAIL_&label1.
		DIABETES_CHF = DIABETES_CHF_&label1.
		DISABLED_HCC110 = DISABLED_HCC110_&label1.
		DISABLED_HCC176 = DISABLED_HCC176_&label1.
		DISABLED_HCC34 = DISABLED_HCC34_&label1.
		DISABLED_HCC46 = DISABLED_HCC46_&label1.
		DISABLED_HCC54 = DISABLED_HCC54_&label1.
		DISABLED_HCC55 = DISABLED_HCC55_&label1.
		DISABLED_HCC6 = DISABLED_HCC6_&label1.
		DRG_CD_2019_062 = DRG_CD_2019_062_&label1.
		DRG_CD_2019_063 = DRG_CD_2019_063_&label1.
		DRG_CD_2019_064 = DRG_CD_2019_064_&label1.
		DRG_CD_2019_065 = DRG_CD_2019_065_&label1.
		DRG_CD_2019_066 = DRG_CD_2019_066_&label1.
		DRG_CD_2019_178 = DRG_CD_2019_178_&label1.
		DRG_CD_2019_179 = DRG_CD_2019_179_&label1.
		DRG_CD_2019_191 = DRG_CD_2019_191_&label1.
		DRG_CD_2019_192 = DRG_CD_2019_192_&label1.
		DRG_CD_2019_193 = DRG_CD_2019_193_&label1.
		DRG_CD_2019_194 = DRG_CD_2019_194_&label1.
		DRG_CD_2019_195 = DRG_CD_2019_195_&label1.
		DRG_CD_2019_202 = DRG_CD_2019_202_&label1.
		DRG_CD_2019_203 = DRG_CD_2019_203_&label1.
		DRG_CD_2019_217 = DRG_CD_2019_217_&label1.
		DRG_CD_2019_218 = DRG_CD_2019_218_&label1.
		DRG_CD_2019_219 = DRG_CD_2019_219_&label1.
		DRG_CD_2019_220 = DRG_CD_2019_220_&label1.
		DRG_CD_2019_221 = DRG_CD_2019_221_&label1.
		DRG_CD_2019_223 = DRG_CD_2019_223_&label1.
		DRG_CD_2019_224 = DRG_CD_2019_224_&label1.
		DRG_CD_2019_225 = DRG_CD_2019_225_&label1.
		DRG_CD_2019_226 = DRG_CD_2019_226_&label1.
		DRG_CD_2019_227 = DRG_CD_2019_227_&label1.
		DRG_CD_2019_232 = DRG_CD_2019_232_&label1.
		DRG_CD_2019_233 = DRG_CD_2019_233_&label1.
		DRG_CD_2019_234 = DRG_CD_2019_234_&label1.
		DRG_CD_2019_235 = DRG_CD_2019_235_&label1.
		DRG_CD_2019_236 = DRG_CD_2019_236_&label1.
		DRG_CD_2019_243 = DRG_CD_2019_243_&label1.
		DRG_CD_2019_244 = DRG_CD_2019_244_&label1.
		DRG_CD_2019_247 = DRG_CD_2019_247_&label1.
		DRG_CD_2019_248 = DRG_CD_2019_248_&label1.
		DRG_CD_2019_249 = DRG_CD_2019_249_&label1.
		DRG_CD_2019_250 = DRG_CD_2019_250_&label1.
		DRG_CD_2019_251 = DRG_CD_2019_251_&label1.
		DRG_CD_2019_266 = DRG_CD_2019_266_&label1.
		DRG_CD_2019_267 = DRG_CD_2019_267_&label1.
		DRG_CD_2019_273 = DRG_CD_2019_273_&label1.
		DRG_CD_2019_274 = DRG_CD_2019_274_&label1.
		DRG_CD_2019_281 = DRG_CD_2019_281_&label1.
		DRG_CD_2019_282 = DRG_CD_2019_282_&label1.
		DRG_CD_2019_292 = DRG_CD_2019_292_&label1.
		DRG_CD_2019_293 = DRG_CD_2019_293_&label1.
		DRG_CD_2019_309 = DRG_CD_2019_309_&label1.
		DRG_CD_2019_310 = DRG_CD_2019_310_&label1.
		DRG_CD_2019_330 = DRG_CD_2019_330_&label1.
		DRG_CD_2019_331 = DRG_CD_2019_331_&label1.
		DRG_CD_2019_378 = DRG_CD_2019_378_&label1.
		DRG_CD_2019_379 = DRG_CD_2019_379_&label1.
		DRG_CD_2019_389 = DRG_CD_2019_389_&label1.
		DRG_CD_2019_390 = DRG_CD_2019_390_&label1.
		DRG_CD_2019_442 = DRG_CD_2019_442_&label1.
		DRG_CD_2019_443 = DRG_CD_2019_443_&label1.
		DRG_CD_2019_454 = DRG_CD_2019_454_&label1.
		DRG_CD_2019_455 = DRG_CD_2019_455_&label1.
		DRG_CD_2019_460 = DRG_CD_2019_460_&label1.
		DRG_CD_2019_462 = DRG_CD_2019_462_&label1.
		DRG_CD_2019_470 = DRG_CD_2019_470_&label1.
		DRG_CD_2019_472 = DRG_CD_2019_472_&label1.
		DRG_CD_2019_473 = DRG_CD_2019_473_&label1.
		DRG_CD_2019_481 = DRG_CD_2019_481_&label1.
		DRG_CD_2019_482 = DRG_CD_2019_482_&label1.
		DRG_CD_2019_493 = DRG_CD_2019_493_&label1.
		DRG_CD_2019_494 = DRG_CD_2019_494_&label1.
		DRG_CD_2019_519 = DRG_CD_2019_519_&label1.
		DRG_CD_2019_520 = DRG_CD_2019_520_&label1.
		DRG_CD_2019_534 = DRG_CD_2019_534_&label1.
		DRG_CD_2019_535 = DRG_CD_2019_535_&label1.
		DRG_CD_2019_536 = DRG_CD_2019_536_&label1.
		DRG_CD_2019_603 = DRG_CD_2019_603_&label1.
		DRG_CD_2019_683 = DRG_CD_2019_683_&label1.
		DRG_CD_2019_684 = DRG_CD_2019_684_&label1.
		DRG_CD_2019_690 = DRG_CD_2019_690_&label1.
		DRG_CD_2019_871 = DRG_CD_2019_871_&label1.
		DRG_CD_2019_872 = DRG_CD_2019_872_&label1.
		FRACTURE_FLAG = FRACTURE_FLAG_&label1.
		HCC_CNT_1_3 = HCC_CNT_1_3_&label1.
		HCC_CNT_4_6 = HCC_CNT_4_6_&label1.
		HCC_CNT_7_PLUS = HCC_CNT_7_PLUS_&label1.
		HCC1 = HCC1_&label1.
		HCC10 = HCC10_&label1.
		HCC100 = HCC100_&label1.
		HCC103 = HCC103_&label1.
		HCC104 = HCC104_&label1.
		HCC106 = HCC106_&label1.
		HCC107 = HCC107_&label1.
		HCC108 = HCC108_&label1.
		HCC11 = HCC11_&label1.
		HCC110 = HCC110_&label1.
		HCC111 = HCC111_&label1.
		HCC112 = HCC112_&label1.
		HCC114 = HCC114_&label1.
		HCC115 = HCC115_&label1.
		HCC12 = HCC12_&label1.
		HCC122 = HCC122_&label1.
		HCC124 = HCC124_&label1.
		HCC134 = HCC134_&label1.
		HCC135 = HCC135_&label1.
		HCC136 = HCC136_&label1.
		HCC137 = HCC137_&label1.
		HCC157 = HCC157_&label1.
		HCC158 = HCC158_&label1.
		HCC161 = HCC161_&label1.
		HCC162 = HCC162_&label1.
		HCC166 = HCC166_&label1.
		HCC167 = HCC167_&label1.
		HCC169 = HCC169_&label1.
		HCC17 = HCC17_&label1.
		HCC170 = HCC170_&label1.
		HCC173 = HCC173_&label1.
		HCC176 = HCC176_&label1.
		HCC18 = HCC18_&label1.
		HCC186 = HCC186_&label1.
		HCC188 = HCC188_&label1.
		HCC189 = HCC189_&label1.
		HCC19 = HCC19_&label1.
		HCC2 = HCC2_&label1.
		HCC21 = HCC21_&label1.
		HCC22 = HCC22_&label1.
		HCC23 = HCC23_&label1.
		HCC27 = HCC27_&label1.
		HCC28 = HCC28_&label1.
		HCC29 = HCC29_&label1.
		HCC33 = HCC33_&label1.
		HCC34 = HCC34_&label1.
		HCC35 = HCC35_&label1.
		HCC39 = HCC39_&label1.
		HCC40 = HCC40_&label1.
		HCC46 = HCC46_&label1.
		HCC47 = HCC47_&label1.
		HCC48 = HCC48_&label1.
		HCC54 = HCC54_&label1.
		HCC55 = HCC55_&label1.
		HCC57 = HCC57_&label1.
		HCC58 = HCC58_&label1.
		HCC6 = HCC6_&label1.
		HCC70 = HCC70_&label1.
		HCC71 = HCC71_&label1.
		HCC72 = HCC72_&label1.
		HCC73 = HCC73_&label1.
		HCC74 = HCC74_&label1.
		HCC75 = HCC75_&label1.
		HCC76 = HCC76_&label1.
		HCC77 = HCC77_&label1.
		HCC78 = HCC78_&label1.
		HCC79 = HCC79_&label1.
		HCC8 = HCC8_&label1.
		HCC80 = HCC80_&label1.
		HCC82 = HCC82_&label1.
		HCC83 = HCC83_&label1.
		HCC84 = HCC84_&label1.
		HCC85 = HCC85_&label1.
		HCC86 = HCC86_&label1.
		HCC87 = HCC87_&label1.
		HCC88 = HCC88_&label1.
		HCC9 = HCC9_&label1.
		HCC96 = HCC96_&label1.
		HCC99 = HCC99_&label1.
		LTI = LTI_&label1.
		ORIGDS = ORIGDS_&label1.
		PRIOR_HOSP_W_ANY_IP_FLAG_90 = PRIOR_HOSP_W_ANY_IP_FLAG_90_&label1.
		SEPSIS_CARD_RESP_FAIL = SEPSIS_CARD_RESP_FAIL_&label1.
		TKA_FLAG = TKA_FLAG_&label1.
		TKA_FRACTURE_FLAG = TKA_FRACTURE_FLAG_&label1.
	;
run;

proc sql;
	create table t1 as 
	select a.*, b.ep_num as ep_num_&label1.
	from t1_pre as a left join t0 as b
	on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
		and a.LABEL_&label1.=b.LABEL;
quit;

data t2_pre (keep= EPI_ID_MILLIMAN BPID ANCHOR_TYPE EPISODE_GROUP_NAME LABEL_&label2.
			AGE_50_&label2.
			AGE_50_SQ_&label2.
			ANY_DUAL_&label2.
			APC_2019_5193_&label2.
			APC_2019_5194_&label2.
			APC_2019_5232_&label2.
			APC_2019_5432_&label2.
			CANCER_IMMUNE_&label2.
			CHF_COPD_&label2.
			CHF_RENAL_&label2.
			COPD_CARD_RESP_FAIL_&label2.
			DIABETES_CHF_&label2.
			DISABLED_HCC110_&label2.
			DISABLED_HCC176_&label2.
			DISABLED_HCC34_&label2.
			DISABLED_HCC46_&label2.
			DISABLED_HCC54_&label2.
			DISABLED_HCC55_&label2.
			DISABLED_HCC6_&label2.
			DRG_CD_2019_062_&label2.
			DRG_CD_2019_063_&label2.
			DRG_CD_2019_064_&label2.
			DRG_CD_2019_065_&label2.
			DRG_CD_2019_066_&label2.
			DRG_CD_2019_178_&label2.
			DRG_CD_2019_179_&label2.
			DRG_CD_2019_191_&label2.
			DRG_CD_2019_192_&label2.
			DRG_CD_2019_193_&label2.
			DRG_CD_2019_194_&label2.
			DRG_CD_2019_195_&label2.
			DRG_CD_2019_202_&label2.
			DRG_CD_2019_203_&label2.
			DRG_CD_2019_217_&label2.
			DRG_CD_2019_218_&label2.
			DRG_CD_2019_219_&label2.
			DRG_CD_2019_220_&label2.
			DRG_CD_2019_221_&label2.
			DRG_CD_2019_223_&label2.
			DRG_CD_2019_224_&label2.
			DRG_CD_2019_225_&label2.
			DRG_CD_2019_226_&label2.
			DRG_CD_2019_227_&label2.
			DRG_CD_2019_232_&label2.
			DRG_CD_2019_233_&label2.
			DRG_CD_2019_234_&label2.
			DRG_CD_2019_235_&label2.
			DRG_CD_2019_236_&label2.
			DRG_CD_2019_243_&label2.
			DRG_CD_2019_244_&label2.
			DRG_CD_2019_247_&label2.
			DRG_CD_2019_248_&label2.
			DRG_CD_2019_249_&label2.
			DRG_CD_2019_250_&label2.
			DRG_CD_2019_251_&label2.
			DRG_CD_2019_266_&label2.
			DRG_CD_2019_267_&label2.
			DRG_CD_2019_273_&label2.
			DRG_CD_2019_274_&label2.
			DRG_CD_2019_281_&label2.
			DRG_CD_2019_282_&label2.
			DRG_CD_2019_292_&label2.
			DRG_CD_2019_293_&label2.
			DRG_CD_2019_309_&label2.
			DRG_CD_2019_310_&label2.
			DRG_CD_2019_330_&label2.
			DRG_CD_2019_331_&label2.
			DRG_CD_2019_378_&label2.
			DRG_CD_2019_379_&label2.
			DRG_CD_2019_389_&label2.
			DRG_CD_2019_390_&label2.
			DRG_CD_2019_442_&label2.
			DRG_CD_2019_443_&label2.
			DRG_CD_2019_454_&label2.
			DRG_CD_2019_455_&label2.
			DRG_CD_2019_460_&label2.
			DRG_CD_2019_462_&label2.
			DRG_CD_2019_470_&label2.
			DRG_CD_2019_472_&label2.
			DRG_CD_2019_473_&label2.
			DRG_CD_2019_481_&label2.
			DRG_CD_2019_482_&label2.
			DRG_CD_2019_493_&label2.
			DRG_CD_2019_494_&label2.
			DRG_CD_2019_519_&label2.
			DRG_CD_2019_520_&label2.
			DRG_CD_2019_534_&label2.
			DRG_CD_2019_535_&label2.
			DRG_CD_2019_536_&label2.
			DRG_CD_2019_603_&label2.
			DRG_CD_2019_683_&label2.
			DRG_CD_2019_684_&label2.
			DRG_CD_2019_690_&label2.
			DRG_CD_2019_871_&label2.
			DRG_CD_2019_872_&label2.
			FRACTURE_FLAG_&label2.
			HCC_CNT_1_3_&label2.
			HCC_CNT_4_6_&label2.
			HCC_CNT_7_PLUS_&label2.
			HCC1_&label2.
			HCC10_&label2.
			HCC100_&label2.
			HCC103_&label2.
			HCC104_&label2.
			HCC106_&label2.
			HCC107_&label2.
			HCC108_&label2.
			HCC11_&label2.
			HCC110_&label2.
			HCC111_&label2.
			HCC112_&label2.
			HCC114_&label2.
			HCC115_&label2.
			HCC12_&label2.
			HCC122_&label2.
			HCC124_&label2.
			HCC134_&label2.
			HCC135_&label2.
			HCC136_&label2.
			HCC137_&label2.
			HCC157_&label2.
			HCC158_&label2.
			HCC161_&label2.
			HCC162_&label2.
			HCC166_&label2.
			HCC167_&label2.
			HCC169_&label2.
			HCC17_&label2.
			HCC170_&label2.
			HCC173_&label2.
			HCC176_&label2.
			HCC18_&label2.
			HCC186_&label2.
			HCC188_&label2.
			HCC189_&label2.
			HCC19_&label2.
			HCC2_&label2.
			HCC21_&label2.
			HCC22_&label2.
			HCC23_&label2.
			HCC27_&label2.
			HCC28_&label2.
			HCC29_&label2.
			HCC33_&label2.
			HCC34_&label2.
			HCC35_&label2.
			HCC39_&label2.
			HCC40_&label2.
			HCC46_&label2.
			HCC47_&label2.
			HCC48_&label2.
			HCC54_&label2.
			HCC55_&label2.
			HCC57_&label2.
			HCC58_&label2.
			HCC6_&label2.
			HCC70_&label2.
			HCC71_&label2.
			HCC72_&label2.
			HCC73_&label2.
			HCC74_&label2.
			HCC75_&label2.
			HCC76_&label2.
			HCC77_&label2.
			HCC78_&label2.
			HCC79_&label2.
			HCC8_&label2.
			HCC80_&label2.
			HCC82_&label2.
			HCC83_&label2.
			HCC84_&label2.
			HCC85_&label2.
			HCC86_&label2.
			HCC87_&label2.
			HCC88_&label2.
			HCC9_&label2.
			HCC96_&label2.
			HCC99_&label2.
			LTI_&label2.
			ORIGDS_&label2.
			PRIOR_HOSP_W_ANY_IP_FLAG_90_&label2.
			SEPSIS_CARD_RESP_FAIL_&label2.
			TKA_FLAG_&label2.
			TKA_FRACTURE_FLAG_&label2.
			);
	set out.epi_&lbl2._&bpid1._&bpid2. ;

	format DRG_2019 BEST12. LABEL_&label2. $7.;
	if ANCHOR_TYPE = 'ip' then DRG_2019 = input(ANCHOR_CODE,$20.);
	else DRG_2019 = . ;

	LABEL_&label2. = "&lbl2.";

	if EPISODE_GROUP_NAME = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPISODE_GROUP_NAME = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

	if ANCHOR_TYPE = 'ip' then anchor_type_upper = 'IP';
	else if ANCHOR_TYPE = 'op' then anchor_type_upper = 'OP';
	else anchor_type_upper = ANCHOR_TYPE;


	Epi_Year = year(POST_DSCH_END_DT);
	Epi_Qtr = qtr(POST_DSCH_END_DT);
	Epi_Half = 1;
	if Epi_Qtr in (3,4) then Epi_Half = 2;

	DRG_CD_2019_062=0;
	DRG_CD_2019_063=0;
	DRG_CD_2019_064=0;
	DRG_CD_2019_065=0;
	DRG_CD_2019_066=0;
	DRG_CD_2019_178=0;
	DRG_CD_2019_179=0;
	DRG_CD_2019_191=0;
	DRG_CD_2019_192=0;
	DRG_CD_2019_193=0;
	DRG_CD_2019_194=0;
	DRG_CD_2019_195=0;
	DRG_CD_2019_202=0;
	DRG_CD_2019_203=0;
	DRG_CD_2019_217=0;
	DRG_CD_2019_218=0;
	DRG_CD_2019_219=0;
	DRG_CD_2019_220=0;
	DRG_CD_2019_221=0;
	DRG_CD_2019_223=0;
	DRG_CD_2019_224=0;
	DRG_CD_2019_225=0;
	DRG_CD_2019_226=0;
	DRG_CD_2019_227=0;
	DRG_CD_2019_232=0;
	DRG_CD_2019_233=0;
	DRG_CD_2019_234=0;
	DRG_CD_2019_235=0;
	DRG_CD_2019_236=0;
	DRG_CD_2019_243=0;
	DRG_CD_2019_244=0;
	DRG_CD_2019_247=0;
	DRG_CD_2019_248=0;
	DRG_CD_2019_249=0;
	DRG_CD_2019_250=0;
	DRG_CD_2019_251=0;
	DRG_CD_2019_266=0;
	DRG_CD_2019_267=0;
	DRG_CD_2019_273=0;
	DRG_CD_2019_274=0;
	DRG_CD_2019_281=0;
	DRG_CD_2019_282=0;
	DRG_CD_2019_292=0;
	DRG_CD_2019_293=0;
	DRG_CD_2019_309=0;
	DRG_CD_2019_310=0;
	DRG_CD_2019_330=0;
	DRG_CD_2019_331=0;
	DRG_CD_2019_378=0;
	DRG_CD_2019_379=0;
	DRG_CD_2019_389=0;
	DRG_CD_2019_390=0;
	DRG_CD_2019_442=0;
	DRG_CD_2019_443=0;
	DRG_CD_2019_454=0;
	DRG_CD_2019_455=0;
	DRG_CD_2019_460=0;
	DRG_CD_2019_462=0;
	DRG_CD_2019_470=0;
	DRG_CD_2019_472=0;
	DRG_CD_2019_473=0;
	DRG_CD_2019_481=0;
	DRG_CD_2019_482=0;
	DRG_CD_2019_493=0;
	DRG_CD_2019_494=0;
	DRG_CD_2019_519=0;
	DRG_CD_2019_520=0;
	DRG_CD_2019_534=0;
	DRG_CD_2019_535=0;
	DRG_CD_2019_536=0;
	DRG_CD_2019_603=0;
	DRG_CD_2019_683=0;
	DRG_CD_2019_684=0;
	DRG_CD_2019_690=0;
	DRG_CD_2019_871=0;
	DRG_CD_2019_872=0;
	APC_2019_5193=0;
	APC_2019_5194=0;
	APC_2019_5232=0;
	APC_2019_5432=0;

	if DRG_2019 = 062 then DRG_CD_2019_062=1;
	if DRG_2019 = 063 then DRG_CD_2019_063=1;
	if DRG_2019 = 064 then DRG_CD_2019_064=1;
	if DRG_2019 = 065 then DRG_CD_2019_065=1;
	if DRG_2019 = 066 then DRG_CD_2019_066=1;
	if DRG_2019 = 178 then DRG_CD_2019_178=1;
	if DRG_2019 = 179 then DRG_CD_2019_179=1;
	if DRG_2019 = 191 then DRG_CD_2019_191=1;
	if DRG_2019 = 192 then DRG_CD_2019_192=1;
	if DRG_2019 = 193 then DRG_CD_2019_193=1;
	if DRG_2019 = 194 then DRG_CD_2019_194=1;
	if DRG_2019 = 195 then DRG_CD_2019_195=1;
	if DRG_2019 = 202 then DRG_CD_2019_202=1;
	if DRG_2019 = 203 then DRG_CD_2019_203=1;
	if DRG_2019 = 217 then DRG_CD_2019_217=1;
	if DRG_2019 = 218 then DRG_CD_2019_218=1;
	if DRG_2019 = 219 then DRG_CD_2019_219=1;
	if DRG_2019 = 220 then DRG_CD_2019_220=1;
	if DRG_2019 = 221 then DRG_CD_2019_221=1;
	if DRG_2019 = 223 then DRG_CD_2019_223=1;
	if DRG_2019 = 224 then DRG_CD_2019_224=1;
	if DRG_2019 = 225 then DRG_CD_2019_225=1;
	if DRG_2019 = 226 then DRG_CD_2019_226=1;
	if DRG_2019 = 227 then DRG_CD_2019_227=1;
	if DRG_2019 = 232 then DRG_CD_2019_232=1;
	if DRG_2019 = 233 then DRG_CD_2019_233=1;
	if DRG_2019 = 234 then DRG_CD_2019_234=1;
	if DRG_2019 = 235 then DRG_CD_2019_235=1;
	if DRG_2019 = 236 then DRG_CD_2019_236=1;
	if DRG_2019 = 243 then DRG_CD_2019_243=1;
	if DRG_2019 = 244 then DRG_CD_2019_244=1;
	if DRG_2019 = 247 then DRG_CD_2019_247=1;
	if DRG_2019 = 248 then DRG_CD_2019_248=1;
	if DRG_2019 = 249 then DRG_CD_2019_249=1;
	if DRG_2019 = 250 then DRG_CD_2019_250=1;
	if DRG_2019 = 251 then DRG_CD_2019_251=1;
	if DRG_2019 = 266 then DRG_CD_2019_266=1;
	if DRG_2019 = 267 then DRG_CD_2019_267=1;
	if DRG_2019 = 273 then DRG_CD_2019_273=1;
	if DRG_2019 = 274 then DRG_CD_2019_274=1;
	if DRG_2019 = 281 then DRG_CD_2019_281=1;
	if DRG_2019 = 282 then DRG_CD_2019_282=1;
	if DRG_2019 = 292 then DRG_CD_2019_292=1;
	if DRG_2019 = 293 then DRG_CD_2019_293=1;
	if DRG_2019 = 309 then DRG_CD_2019_309=1;
	if DRG_2019 = 310 then DRG_CD_2019_310=1;
	if DRG_2019 = 330 then DRG_CD_2019_330=1;
	if DRG_2019 = 331 then DRG_CD_2019_331=1;
	if DRG_2019 = 378 then DRG_CD_2019_378=1;
	if DRG_2019 = 379 then DRG_CD_2019_379=1;
	if DRG_2019 = 389 then DRG_CD_2019_389=1;
	if DRG_2019 = 390 then DRG_CD_2019_390=1;
	if DRG_2019 = 442 then DRG_CD_2019_442=1;
	if DRG_2019 = 443 then DRG_CD_2019_443=1;
	if DRG_2019 = 454 then DRG_CD_2019_454=1;
	if DRG_2019 = 455 then DRG_CD_2019_455=1;
	if DRG_2019 = 460 then DRG_CD_2019_460=1;
	if DRG_2019 = 462 then DRG_CD_2019_462=1;
	if DRG_2019 = 470 then DRG_CD_2019_470=1;
	if DRG_2019 = 472 then DRG_CD_2019_472=1;
	if DRG_2019 = 473 then DRG_CD_2019_473=1;
	if DRG_2019 = 481 then DRG_CD_2019_481=1;
	if DRG_2019 = 482 then DRG_CD_2019_482=1;
	if DRG_2019 = 493 then DRG_CD_2019_493=1;
	if DRG_2019 = 494 then DRG_CD_2019_494=1;
	if DRG_2019 = 519 then DRG_CD_2019_519=1;
	if DRG_2019 = 520 then DRG_CD_2019_520=1;
	if DRG_2019 = 534 then DRG_CD_2019_534=1;
	if DRG_2019 = 535 then DRG_CD_2019_535=1;
	if DRG_2019 = 536 then DRG_CD_2019_536=1;
	if DRG_2019 = 603 then DRG_CD_2019_603=1;
	if DRG_2019 = 683 then DRG_CD_2019_683=1;
	if DRG_2019 = 684 then DRG_CD_2019_684=1;
	if DRG_2019 = 690 then DRG_CD_2019_690=1;
	if DRG_2019 = 871 then DRG_CD_2019_871=1;
	if DRG_2019 = 872 then DRG_CD_2019_872=1;
	if PERF_APC = 5193 then APC_2019_5193=1;
	if PERF_APC = 5194 then APC_2019_5194=1;
	if PERF_APC = 5232 then APC_2019_5232=1;
	if PERF_APC = 5432 then APC_2019_5432=1;

	HCC_CNT = sum(of HCC1 -- HCC189);
	HCC_CNT_1_3=0;
	HCC_CNT_4_6=0;
	HCC_CNT_7_PLUS=0;
	if HCC_CNT > 0 then do;
		if HCC_CNT <= 3 then HCC_CNT_1_3=1;
		else if HCC_CNT <= 6 then HCC_CNT_4_6=1;
		else if HCC_CNT >= 7 then HCC_CNT_7_PLUS=1;
	end; 

	Age_50 = BENE_AGE-50;
	Age_50_SQ = Age_50 * Age_50;

	rename 
		AGE_50 = AGE_50_&label2.
		AGE_50_SQ = AGE_50_SQ_&label2.
		ANY_DUAL = ANY_DUAL_&label2.
		APC_2019_5193 = APC_2019_5193_&label2.
		APC_2019_5194 = APC_2019_5194_&label2.
		APC_2019_5232 = APC_2019_5232_&label2.
		APC_2019_5432 = APC_2019_5432_&label2.
		CANCER_IMMUNE = CANCER_IMMUNE_&label2.
		CHF_COPD = CHF_COPD_&label2.
		CHF_RENAL = CHF_RENAL_&label2.
		COPD_CARD_RESP_FAIL = COPD_CARD_RESP_FAIL_&label2.
		DIABETES_CHF = DIABETES_CHF_&label2.
		DISABLED_HCC110 = DISABLED_HCC110_&label2.
		DISABLED_HCC176 = DISABLED_HCC176_&label2.
		DISABLED_HCC34 = DISABLED_HCC34_&label2.
		DISABLED_HCC46 = DISABLED_HCC46_&label2.
		DISABLED_HCC54 = DISABLED_HCC54_&label2.
		DISABLED_HCC55 = DISABLED_HCC55_&label2.
		DISABLED_HCC6 = DISABLED_HCC6_&label2.
		DRG_CD_2019_062 = DRG_CD_2019_062_&label2.
		DRG_CD_2019_063 = DRG_CD_2019_063_&label2.
		DRG_CD_2019_064 = DRG_CD_2019_064_&label2.
		DRG_CD_2019_065 = DRG_CD_2019_065_&label2.
		DRG_CD_2019_066 = DRG_CD_2019_066_&label2.
		DRG_CD_2019_178 = DRG_CD_2019_178_&label2.
		DRG_CD_2019_179 = DRG_CD_2019_179_&label2.
		DRG_CD_2019_191 = DRG_CD_2019_191_&label2.
		DRG_CD_2019_192 = DRG_CD_2019_192_&label2.
		DRG_CD_2019_193 = DRG_CD_2019_193_&label2.
		DRG_CD_2019_194 = DRG_CD_2019_194_&label2.
		DRG_CD_2019_195 = DRG_CD_2019_195_&label2.
		DRG_CD_2019_202 = DRG_CD_2019_202_&label2.
		DRG_CD_2019_203 = DRG_CD_2019_203_&label2.
		DRG_CD_2019_217 = DRG_CD_2019_217_&label2.
		DRG_CD_2019_218 = DRG_CD_2019_218_&label2.
		DRG_CD_2019_219 = DRG_CD_2019_219_&label2.
		DRG_CD_2019_220 = DRG_CD_2019_220_&label2.
		DRG_CD_2019_221 = DRG_CD_2019_221_&label2.
		DRG_CD_2019_223 = DRG_CD_2019_223_&label2.
		DRG_CD_2019_224 = DRG_CD_2019_224_&label2.
		DRG_CD_2019_225 = DRG_CD_2019_225_&label2.
		DRG_CD_2019_226 = DRG_CD_2019_226_&label2.
		DRG_CD_2019_227 = DRG_CD_2019_227_&label2.
		DRG_CD_2019_232 = DRG_CD_2019_232_&label2.
		DRG_CD_2019_233 = DRG_CD_2019_233_&label2.
		DRG_CD_2019_234 = DRG_CD_2019_234_&label2.
		DRG_CD_2019_235 = DRG_CD_2019_235_&label2.
		DRG_CD_2019_236 = DRG_CD_2019_236_&label2.
		DRG_CD_2019_243 = DRG_CD_2019_243_&label2.
		DRG_CD_2019_244 = DRG_CD_2019_244_&label2.
		DRG_CD_2019_247 = DRG_CD_2019_247_&label2.
		DRG_CD_2019_248 = DRG_CD_2019_248_&label2.
		DRG_CD_2019_249 = DRG_CD_2019_249_&label2.
		DRG_CD_2019_250 = DRG_CD_2019_250_&label2.
		DRG_CD_2019_251 = DRG_CD_2019_251_&label2.
		DRG_CD_2019_266 = DRG_CD_2019_266_&label2.
		DRG_CD_2019_267 = DRG_CD_2019_267_&label2.
		DRG_CD_2019_273 = DRG_CD_2019_273_&label2.
		DRG_CD_2019_274 = DRG_CD_2019_274_&label2.
		DRG_CD_2019_281 = DRG_CD_2019_281_&label2.
		DRG_CD_2019_282 = DRG_CD_2019_282_&label2.
		DRG_CD_2019_292 = DRG_CD_2019_292_&label2.
		DRG_CD_2019_293 = DRG_CD_2019_293_&label2.
		DRG_CD_2019_309 = DRG_CD_2019_309_&label2.
		DRG_CD_2019_310 = DRG_CD_2019_310_&label2.
		DRG_CD_2019_330 = DRG_CD_2019_330_&label2.
		DRG_CD_2019_331 = DRG_CD_2019_331_&label2.
		DRG_CD_2019_378 = DRG_CD_2019_378_&label2.
		DRG_CD_2019_379 = DRG_CD_2019_379_&label2.
		DRG_CD_2019_389 = DRG_CD_2019_389_&label2.
		DRG_CD_2019_390 = DRG_CD_2019_390_&label2.
		DRG_CD_2019_442 = DRG_CD_2019_442_&label2.
		DRG_CD_2019_443 = DRG_CD_2019_443_&label2.
		DRG_CD_2019_454 = DRG_CD_2019_454_&label2.
		DRG_CD_2019_455 = DRG_CD_2019_455_&label2.
		DRG_CD_2019_460 = DRG_CD_2019_460_&label2.
		DRG_CD_2019_462 = DRG_CD_2019_462_&label2.
		DRG_CD_2019_470 = DRG_CD_2019_470_&label2.
		DRG_CD_2019_472 = DRG_CD_2019_472_&label2.
		DRG_CD_2019_473 = DRG_CD_2019_473_&label2.
		DRG_CD_2019_481 = DRG_CD_2019_481_&label2.
		DRG_CD_2019_482 = DRG_CD_2019_482_&label2.
		DRG_CD_2019_493 = DRG_CD_2019_493_&label2.
		DRG_CD_2019_494 = DRG_CD_2019_494_&label2.
		DRG_CD_2019_519 = DRG_CD_2019_519_&label2.
		DRG_CD_2019_520 = DRG_CD_2019_520_&label2.
		DRG_CD_2019_534 = DRG_CD_2019_534_&label2.
		DRG_CD_2019_535 = DRG_CD_2019_535_&label2.
		DRG_CD_2019_536 = DRG_CD_2019_536_&label2.
		DRG_CD_2019_603 = DRG_CD_2019_603_&label2.
		DRG_CD_2019_683 = DRG_CD_2019_683_&label2.
		DRG_CD_2019_684 = DRG_CD_2019_684_&label2.
		DRG_CD_2019_690 = DRG_CD_2019_690_&label2.
		DRG_CD_2019_871 = DRG_CD_2019_871_&label2.
		DRG_CD_2019_872 = DRG_CD_2019_872_&label2.
		FRACTURE_FLAG = FRACTURE_FLAG_&label2.
		HCC_CNT_1_3 = HCC_CNT_1_3_&label2.
		HCC_CNT_4_6 = HCC_CNT_4_6_&label2.
		HCC_CNT_7_PLUS = HCC_CNT_7_PLUS_&label2.
		HCC1 = HCC1_&label2.
		HCC10 = HCC10_&label2.
		HCC100 = HCC100_&label2.
		HCC103 = HCC103_&label2.
		HCC104 = HCC104_&label2.
		HCC106 = HCC106_&label2.
		HCC107 = HCC107_&label2.
		HCC108 = HCC108_&label2.
		HCC11 = HCC11_&label2.
		HCC110 = HCC110_&label2.
		HCC111 = HCC111_&label2.
		HCC112 = HCC112_&label2.
		HCC114 = HCC114_&label2.
		HCC115 = HCC115_&label2.
		HCC12 = HCC12_&label2.
		HCC122 = HCC122_&label2.
		HCC124 = HCC124_&label2.
		HCC134 = HCC134_&label2.
		HCC135 = HCC135_&label2.
		HCC136 = HCC136_&label2.
		HCC137 = HCC137_&label2.
		HCC157 = HCC157_&label2.
		HCC158 = HCC158_&label2.
		HCC161 = HCC161_&label2.
		HCC162 = HCC162_&label2.
		HCC166 = HCC166_&label2.
		HCC167 = HCC167_&label2.
		HCC169 = HCC169_&label2.
		HCC17 = HCC17_&label2.
		HCC170 = HCC170_&label2.
		HCC173 = HCC173_&label2.
		HCC176 = HCC176_&label2.
		HCC18 = HCC18_&label2.
		HCC186 = HCC186_&label2.
		HCC188 = HCC188_&label2.
		HCC189 = HCC189_&label2.
		HCC19 = HCC19_&label2.
		HCC2 = HCC2_&label2.
		HCC21 = HCC21_&label2.
		HCC22 = HCC22_&label2.
		HCC23 = HCC23_&label2.
		HCC27 = HCC27_&label2.
		HCC28 = HCC28_&label2.
		HCC29 = HCC29_&label2.
		HCC33 = HCC33_&label2.
		HCC34 = HCC34_&label2.
		HCC35 = HCC35_&label2.
		HCC39 = HCC39_&label2.
		HCC40 = HCC40_&label2.
		HCC46 = HCC46_&label2.
		HCC47 = HCC47_&label2.
		HCC48 = HCC48_&label2.
		HCC54 = HCC54_&label2.
		HCC55 = HCC55_&label2.
		HCC57 = HCC57_&label2.
		HCC58 = HCC58_&label2.
		HCC6 = HCC6_&label2.
		HCC70 = HCC70_&label2.
		HCC71 = HCC71_&label2.
		HCC72 = HCC72_&label2.
		HCC73 = HCC73_&label2.
		HCC74 = HCC74_&label2.
		HCC75 = HCC75_&label2.
		HCC76 = HCC76_&label2.
		HCC77 = HCC77_&label2.
		HCC78 = HCC78_&label2.
		HCC79 = HCC79_&label2.
		HCC8 = HCC8_&label2.
		HCC80 = HCC80_&label2.
		HCC82 = HCC82_&label2.
		HCC83 = HCC83_&label2.
		HCC84 = HCC84_&label2.
		HCC85 = HCC85_&label2.
		HCC86 = HCC86_&label2.
		HCC87 = HCC87_&label2.
		HCC88 = HCC88_&label2.
		HCC9 = HCC9_&label2.
		HCC96 = HCC96_&label2.
		HCC99 = HCC99_&label2.
		LTI = LTI_&label2.
		ORIGDS = ORIGDS_&label2.
		PRIOR_HOSP_W_ANY_IP_FLAG_90 = PRIOR_HOSP_W_ANY_IP_FLAG_90_&label2.
		SEPSIS_CARD_RESP_FAIL = SEPSIS_CARD_RESP_FAIL_&label2.
		TKA_FLAG = TKA_FLAG_&label2.
		TKA_FRACTURE_FLAG = TKA_FRACTURE_FLAG_&label2.
	;
run;

proc sql;
	create table t2 as 
	select a.*, b.ep_num as ep_num_&label2.
	from t2_pre as a left join t0 as b
	on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
		and a.LABEL_&label2.=b.LABEL;
quit;

proc sql;
	create table t3 as
	select a.*, b.*
	from t1 as a inner join t2 as b
	on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN;
quit;

data t4;
	set t3;
	AGE_50 = 0;
	AGE_50_SQ = 0;
	ANY_DUAL = 0;
	APC_2019_5193 = 0;
	APC_2019_5194 = 0;
	APC_2019_5232 = 0;
	APC_2019_5432 = 0;
	CANCER_IMMUNE = 0;
	CHF_COPD = 0;
	CHF_RENAL = 0;
	COPD_CARD_RESP_FAIL = 0;
	DIABETES_CHF = 0;
	DISABLED_HCC110 = 0;
	DISABLED_HCC176 = 0;
	DISABLED_HCC34 = 0;
	DISABLED_HCC46 = 0;
	DISABLED_HCC54 = 0;
	DISABLED_HCC55 = 0;
	DISABLED_HCC6 = 0;
	DRG_CD_2019_062 = 0;
	DRG_CD_2019_063 = 0;
	DRG_CD_2019_064 = 0;
	DRG_CD_2019_065 = 0;
	DRG_CD_2019_066 = 0;
	DRG_CD_2019_178 = 0;
	DRG_CD_2019_179 = 0;
	DRG_CD_2019_191 = 0;
	DRG_CD_2019_192 = 0;
	DRG_CD_2019_193 = 0;
	DRG_CD_2019_194 = 0;
	DRG_CD_2019_195 = 0;
	DRG_CD_2019_202 = 0;
	DRG_CD_2019_203 = 0;
	DRG_CD_2019_217 = 0;
	DRG_CD_2019_218 = 0;
	DRG_CD_2019_219 = 0;
	DRG_CD_2019_220 = 0;
	DRG_CD_2019_221 = 0;
	DRG_CD_2019_223 = 0;
	DRG_CD_2019_224 = 0;
	DRG_CD_2019_225 = 0;
	DRG_CD_2019_226 = 0;
	DRG_CD_2019_227 = 0;
	DRG_CD_2019_232 = 0;
	DRG_CD_2019_233 = 0;
	DRG_CD_2019_234 = 0;
	DRG_CD_2019_235 = 0;
	DRG_CD_2019_236 = 0;
	DRG_CD_2019_243 = 0;
	DRG_CD_2019_244 = 0;
	DRG_CD_2019_247 = 0;
	DRG_CD_2019_248 = 0;
	DRG_CD_2019_249 = 0;
	DRG_CD_2019_250 = 0;
	DRG_CD_2019_251 = 0;
	DRG_CD_2019_266 = 0;
	DRG_CD_2019_267 = 0;
	DRG_CD_2019_273 = 0;
	DRG_CD_2019_274 = 0;
	DRG_CD_2019_281 = 0;
	DRG_CD_2019_282 = 0;
	DRG_CD_2019_292 = 0;
	DRG_CD_2019_293 = 0;
	DRG_CD_2019_309 = 0;
	DRG_CD_2019_310 = 0;
	DRG_CD_2019_330 = 0;
	DRG_CD_2019_331 = 0;
	DRG_CD_2019_378 = 0;
	DRG_CD_2019_379 = 0;
	DRG_CD_2019_389 = 0;
	DRG_CD_2019_390 = 0;
	DRG_CD_2019_442 = 0;
	DRG_CD_2019_443 = 0;
	DRG_CD_2019_454 = 0;
	DRG_CD_2019_455 = 0;
	DRG_CD_2019_460 = 0;
	DRG_CD_2019_462 = 0;
	DRG_CD_2019_470 = 0;
	DRG_CD_2019_472 = 0;
	DRG_CD_2019_473 = 0;
	DRG_CD_2019_481 = 0;
	DRG_CD_2019_482 = 0;
	DRG_CD_2019_493 = 0;
	DRG_CD_2019_494 = 0;
	DRG_CD_2019_519 = 0;
	DRG_CD_2019_520 = 0;
	DRG_CD_2019_534 = 0;
	DRG_CD_2019_535 = 0;
	DRG_CD_2019_536 = 0;
	DRG_CD_2019_603 = 0;
	DRG_CD_2019_683 = 0;
	DRG_CD_2019_684 = 0;
	DRG_CD_2019_690 = 0;
	DRG_CD_2019_871 = 0;
	DRG_CD_2019_872 = 0;
	FRACTURE_FLAG = 0;
	HCC_CNT_1_3 = 0;
	HCC_CNT_4_6 = 0;
	HCC_CNT_7_PLUS = 0;
	HCC1 = 0;
	HCC10 = 0;
	HCC100 = 0;
	HCC103 = 0;
	HCC104 = 0;
	HCC106 = 0;
	HCC107 = 0;
	HCC108 = 0;
	HCC11 = 0;
	HCC110 = 0;
	HCC111 = 0;
	HCC112 = 0;
	HCC114 = 0;
	HCC115 = 0;
	HCC12 = 0;
	HCC122 = 0;
	HCC124 = 0;
	HCC134 = 0;
	HCC135 = 0;
	HCC136 = 0;
	HCC137 = 0;
	HCC157 = 0;
	HCC158 = 0;
	HCC161 = 0;
	HCC162 = 0;
	HCC166 = 0;
	HCC167 = 0;
	HCC169 = 0;
	HCC17 = 0;
	HCC170 = 0;
	HCC173 = 0;
	HCC176 = 0;
	HCC18 = 0;
	HCC186 = 0;
	HCC188 = 0;
	HCC189 = 0;
	HCC19 = 0;
	HCC2 = 0;
	HCC21 = 0;
	HCC22 = 0;
	HCC23 = 0;
	HCC27 = 0;
	HCC28 = 0;
	HCC29 = 0;
	HCC33 = 0;
	HCC34 = 0;
	HCC35 = 0;
	HCC39 = 0;
	HCC40 = 0;
	HCC46 = 0;
	HCC47 = 0;
	HCC48 = 0;
	HCC54 = 0;
	HCC55 = 0;
	HCC57 = 0;
	HCC58 = 0;
	HCC6 = 0;
	HCC70 = 0;
	HCC71 = 0;
	HCC72 = 0;
	HCC73 = 0;
	HCC74 = 0;
	HCC75 = 0;
	HCC76 = 0;
	HCC77 = 0;
	HCC78 = 0;
	HCC79 = 0;
	HCC8 = 0;
	HCC80 = 0;
	HCC82 = 0;
	HCC83 = 0;
	HCC84 = 0;
	HCC85 = 0;
	HCC86 = 0;
	HCC87 = 0;
	HCC88 = 0;
	HCC9 = 0;
	HCC96 = 0;
	HCC99 = 0;
	LTI = 0;
	ORIGDS = 0;
	PRIOR_HOSP_W_ANY_IP_FLAG_90 = 0;
	SEPSIS_CARD_RESP_FAIL = 0;
	TKA_FLAG = 0;
	TKA_FRACTURE_FLAG = 0;

	if AGE_50_&label1. ^= AGE_50_&label2. then AGE_50 = 1;
	if AGE_50_SQ_&label1. ^= AGE_50_SQ_&label2. then AGE_50_SQ = 1;
	if ANY_DUAL_&label1. ^= ANY_DUAL_&label2. then ANY_DUAL = 1;
	if APC_2019_5193_&label1. ^= APC_2019_5193_&label2. then APC_2019_5193 = 1;
	if APC_2019_5194_&label1. ^= APC_2019_5194_&label2. then APC_2019_5194 = 1;
	if APC_2019_5232_&label1. ^= APC_2019_5232_&label2. then APC_2019_5232 = 1;
	if APC_2019_5432_&label1. ^= APC_2019_5432_&label2. then APC_2019_5432 = 1;
	if CANCER_IMMUNE_&label1. ^= CANCER_IMMUNE_&label2. then CANCER_IMMUNE = 1;
	if CHF_COPD_&label1. ^= CHF_COPD_&label2. then CHF_COPD = 1;
	if CHF_RENAL_&label1. ^= CHF_RENAL_&label2. then CHF_RENAL = 1;
	if COPD_CARD_RESP_FAIL_&label1. ^= COPD_CARD_RESP_FAIL_&label2. then COPD_CARD_RESP_FAIL = 1;
	if DIABETES_CHF_&label1. ^= DIABETES_CHF_&label2. then DIABETES_CHF = 1;
	if DISABLED_HCC110_&label1. ^= DISABLED_HCC110_&label2. then DISABLED_HCC110 = 1;
	if DISABLED_HCC176_&label1. ^= DISABLED_HCC176_&label2. then DISABLED_HCC176 = 1;
	if DISABLED_HCC34_&label1. ^= DISABLED_HCC34_&label2. then DISABLED_HCC34 = 1;
	if DISABLED_HCC46_&label1. ^= DISABLED_HCC46_&label2. then DISABLED_HCC46 = 1;
	if DISABLED_HCC54_&label1. ^= DISABLED_HCC54_&label2. then DISABLED_HCC54 = 1;
	if DISABLED_HCC55_&label1. ^= DISABLED_HCC55_&label2. then DISABLED_HCC55 = 1;
	if DISABLED_HCC6_&label1. ^= DISABLED_HCC6_&label2. then DISABLED_HCC6 = 1;
	if DRG_CD_2019_062_&label1. ^= DRG_CD_2019_062_&label2. then DRG_CD_2019_062 = 1;
	if DRG_CD_2019_063_&label1. ^= DRG_CD_2019_063_&label2. then DRG_CD_2019_063 = 1;
	if DRG_CD_2019_064_&label1. ^= DRG_CD_2019_064_&label2. then DRG_CD_2019_064 = 1;
	if DRG_CD_2019_065_&label1. ^= DRG_CD_2019_065_&label2. then DRG_CD_2019_065 = 1;
	if DRG_CD_2019_066_&label1. ^= DRG_CD_2019_066_&label2. then DRG_CD_2019_066 = 1;
	if DRG_CD_2019_178_&label1. ^= DRG_CD_2019_178_&label2. then DRG_CD_2019_178 = 1;
	if DRG_CD_2019_179_&label1. ^= DRG_CD_2019_179_&label2. then DRG_CD_2019_179 = 1;
	if DRG_CD_2019_191_&label1. ^= DRG_CD_2019_191_&label2. then DRG_CD_2019_191 = 1;
	if DRG_CD_2019_192_&label1. ^= DRG_CD_2019_192_&label2. then DRG_CD_2019_192 = 1;
	if DRG_CD_2019_193_&label1. ^= DRG_CD_2019_193_&label2. then DRG_CD_2019_193 = 1;
	if DRG_CD_2019_194_&label1. ^= DRG_CD_2019_194_&label2. then DRG_CD_2019_194 = 1;
	if DRG_CD_2019_195_&label1. ^= DRG_CD_2019_195_&label2. then DRG_CD_2019_195 = 1;
	if DRG_CD_2019_202_&label1. ^= DRG_CD_2019_202_&label2. then DRG_CD_2019_202 = 1;
	if DRG_CD_2019_203_&label1. ^= DRG_CD_2019_203_&label2. then DRG_CD_2019_203 = 1;
	if DRG_CD_2019_217_&label1. ^= DRG_CD_2019_217_&label2. then DRG_CD_2019_217 = 1;
	if DRG_CD_2019_218_&label1. ^= DRG_CD_2019_218_&label2. then DRG_CD_2019_218 = 1;
	if DRG_CD_2019_219_&label1. ^= DRG_CD_2019_219_&label2. then DRG_CD_2019_219 = 1;
	if DRG_CD_2019_220_&label1. ^= DRG_CD_2019_220_&label2. then DRG_CD_2019_220 = 1;
	if DRG_CD_2019_221_&label1. ^= DRG_CD_2019_221_&label2. then DRG_CD_2019_221 = 1;
	if DRG_CD_2019_223_&label1. ^= DRG_CD_2019_223_&label2. then DRG_CD_2019_223 = 1;
	if DRG_CD_2019_224_&label1. ^= DRG_CD_2019_224_&label2. then DRG_CD_2019_224 = 1;
	if DRG_CD_2019_225_&label1. ^= DRG_CD_2019_225_&label2. then DRG_CD_2019_225 = 1;
	if DRG_CD_2019_226_&label1. ^= DRG_CD_2019_226_&label2. then DRG_CD_2019_226 = 1;
	if DRG_CD_2019_227_&label1. ^= DRG_CD_2019_227_&label2. then DRG_CD_2019_227 = 1;
	if DRG_CD_2019_232_&label1. ^= DRG_CD_2019_232_&label2. then DRG_CD_2019_232 = 1;
	if DRG_CD_2019_233_&label1. ^= DRG_CD_2019_233_&label2. then DRG_CD_2019_233 = 1;
	if DRG_CD_2019_234_&label1. ^= DRG_CD_2019_234_&label2. then DRG_CD_2019_234 = 1;
	if DRG_CD_2019_235_&label1. ^= DRG_CD_2019_235_&label2. then DRG_CD_2019_235 = 1;
	if DRG_CD_2019_236_&label1. ^= DRG_CD_2019_236_&label2. then DRG_CD_2019_236 = 1;
	if DRG_CD_2019_243_&label1. ^= DRG_CD_2019_243_&label2. then DRG_CD_2019_243 = 1;
	if DRG_CD_2019_244_&label1. ^= DRG_CD_2019_244_&label2. then DRG_CD_2019_244 = 1;
	if DRG_CD_2019_247_&label1. ^= DRG_CD_2019_247_&label2. then DRG_CD_2019_247 = 1;
	if DRG_CD_2019_248_&label1. ^= DRG_CD_2019_248_&label2. then DRG_CD_2019_248 = 1;
	if DRG_CD_2019_249_&label1. ^= DRG_CD_2019_249_&label2. then DRG_CD_2019_249 = 1;
	if DRG_CD_2019_250_&label1. ^= DRG_CD_2019_250_&label2. then DRG_CD_2019_250 = 1;
	if DRG_CD_2019_251_&label1. ^= DRG_CD_2019_251_&label2. then DRG_CD_2019_251 = 1;
	if DRG_CD_2019_266_&label1. ^= DRG_CD_2019_266_&label2. then DRG_CD_2019_266 = 1;
	if DRG_CD_2019_267_&label1. ^= DRG_CD_2019_267_&label2. then DRG_CD_2019_267 = 1;
	if DRG_CD_2019_273_&label1. ^= DRG_CD_2019_273_&label2. then DRG_CD_2019_273 = 1;
	if DRG_CD_2019_274_&label1. ^= DRG_CD_2019_274_&label2. then DRG_CD_2019_274 = 1;
	if DRG_CD_2019_281_&label1. ^= DRG_CD_2019_281_&label2. then DRG_CD_2019_281 = 1;
	if DRG_CD_2019_282_&label1. ^= DRG_CD_2019_282_&label2. then DRG_CD_2019_282 = 1;
	if DRG_CD_2019_292_&label1. ^= DRG_CD_2019_292_&label2. then DRG_CD_2019_292 = 1;
	if DRG_CD_2019_293_&label1. ^= DRG_CD_2019_293_&label2. then DRG_CD_2019_293 = 1;
	if DRG_CD_2019_309_&label1. ^= DRG_CD_2019_309_&label2. then DRG_CD_2019_309 = 1;
	if DRG_CD_2019_310_&label1. ^= DRG_CD_2019_310_&label2. then DRG_CD_2019_310 = 1;
	if DRG_CD_2019_330_&label1. ^= DRG_CD_2019_330_&label2. then DRG_CD_2019_330 = 1;
	if DRG_CD_2019_331_&label1. ^= DRG_CD_2019_331_&label2. then DRG_CD_2019_331 = 1;
	if DRG_CD_2019_378_&label1. ^= DRG_CD_2019_378_&label2. then DRG_CD_2019_378 = 1;
	if DRG_CD_2019_379_&label1. ^= DRG_CD_2019_379_&label2. then DRG_CD_2019_379 = 1;
	if DRG_CD_2019_389_&label1. ^= DRG_CD_2019_389_&label2. then DRG_CD_2019_389 = 1;
	if DRG_CD_2019_390_&label1. ^= DRG_CD_2019_390_&label2. then DRG_CD_2019_390 = 1;
	if DRG_CD_2019_442_&label1. ^= DRG_CD_2019_442_&label2. then DRG_CD_2019_442 = 1;
	if DRG_CD_2019_443_&label1. ^= DRG_CD_2019_443_&label2. then DRG_CD_2019_443 = 1;
	if DRG_CD_2019_454_&label1. ^= DRG_CD_2019_454_&label2. then DRG_CD_2019_454 = 1;
	if DRG_CD_2019_455_&label1. ^= DRG_CD_2019_455_&label2. then DRG_CD_2019_455 = 1;
	if DRG_CD_2019_460_&label1. ^= DRG_CD_2019_460_&label2. then DRG_CD_2019_460 = 1;
	if DRG_CD_2019_462_&label1. ^= DRG_CD_2019_462_&label2. then DRG_CD_2019_462 = 1;
	if DRG_CD_2019_470_&label1. ^= DRG_CD_2019_470_&label2. then DRG_CD_2019_470 = 1;
	if DRG_CD_2019_472_&label1. ^= DRG_CD_2019_472_&label2. then DRG_CD_2019_472 = 1;
	if DRG_CD_2019_473_&label1. ^= DRG_CD_2019_473_&label2. then DRG_CD_2019_473 = 1;
	if DRG_CD_2019_481_&label1. ^= DRG_CD_2019_481_&label2. then DRG_CD_2019_481 = 1;
	if DRG_CD_2019_482_&label1. ^= DRG_CD_2019_482_&label2. then DRG_CD_2019_482 = 1;
	if DRG_CD_2019_493_&label1. ^= DRG_CD_2019_493_&label2. then DRG_CD_2019_493 = 1;
	if DRG_CD_2019_494_&label1. ^= DRG_CD_2019_494_&label2. then DRG_CD_2019_494 = 1;
	if DRG_CD_2019_519_&label1. ^= DRG_CD_2019_519_&label2. then DRG_CD_2019_519 = 1;
	if DRG_CD_2019_520_&label1. ^= DRG_CD_2019_520_&label2. then DRG_CD_2019_520 = 1;
	if DRG_CD_2019_534_&label1. ^= DRG_CD_2019_534_&label2. then DRG_CD_2019_534 = 1;
	if DRG_CD_2019_535_&label1. ^= DRG_CD_2019_535_&label2. then DRG_CD_2019_535 = 1;
	if DRG_CD_2019_536_&label1. ^= DRG_CD_2019_536_&label2. then DRG_CD_2019_536 = 1;
	if DRG_CD_2019_603_&label1. ^= DRG_CD_2019_603_&label2. then DRG_CD_2019_603 = 1;
	if DRG_CD_2019_683_&label1. ^= DRG_CD_2019_683_&label2. then DRG_CD_2019_683 = 1;
	if DRG_CD_2019_684_&label1. ^= DRG_CD_2019_684_&label2. then DRG_CD_2019_684 = 1;
	if DRG_CD_2019_690_&label1. ^= DRG_CD_2019_690_&label2. then DRG_CD_2019_690 = 1;
	if DRG_CD_2019_871_&label1. ^= DRG_CD_2019_871_&label2. then DRG_CD_2019_871 = 1;
	if DRG_CD_2019_872_&label1. ^= DRG_CD_2019_872_&label2. then DRG_CD_2019_872 = 1;
	if FRACTURE_FLAG_&label1. ^= FRACTURE_FLAG_&label2. then FRACTURE_FLAG = 1;
	if HCC_CNT_1_3_&label1. ^= HCC_CNT_1_3_&label2. then HCC_CNT_1_3 = 1;
	if HCC_CNT_4_6_&label1. ^= HCC_CNT_4_6_&label2. then HCC_CNT_4_6 = 1;
	if HCC_CNT_7_PLUS_&label1. ^= HCC_CNT_7_PLUS_&label2. then HCC_CNT_7_PLUS = 1;
	if HCC1_&label1. ^= HCC1_&label2. then HCC1 = 1;
	if HCC10_&label1. ^= HCC10_&label2. then HCC10 = 1;
	if HCC100_&label1. ^= HCC100_&label2. then HCC100 = 1;
	if HCC103_&label1. ^= HCC103_&label2. then HCC103 = 1;
	if HCC104_&label1. ^= HCC104_&label2. then HCC104 = 1;
	if HCC106_&label1. ^= HCC106_&label2. then HCC106 = 1;
	if HCC107_&label1. ^= HCC107_&label2. then HCC107 = 1;
	if HCC108_&label1. ^= HCC108_&label2. then HCC108 = 1;
	if HCC11_&label1. ^= HCC11_&label2. then HCC11 = 1;
	if HCC110_&label1. ^= HCC110_&label2. then HCC110 = 1;
	if HCC111_&label1. ^= HCC111_&label2. then HCC111 = 1;
	if HCC112_&label1. ^= HCC112_&label2. then HCC112 = 1;
	if HCC114_&label1. ^= HCC114_&label2. then HCC114 = 1;
	if HCC115_&label1. ^= HCC115_&label2. then HCC115 = 1;
	if HCC12_&label1. ^= HCC12_&label2. then HCC12 = 1;
	if HCC122_&label1. ^= HCC122_&label2. then HCC122 = 1;
	if HCC124_&label1. ^= HCC124_&label2. then HCC124 = 1;
	if HCC134_&label1. ^= HCC134_&label2. then HCC134 = 1;
	if HCC135_&label1. ^= HCC135_&label2. then HCC135 = 1;
	if HCC136_&label1. ^= HCC136_&label2. then HCC136 = 1;
	if HCC137_&label1. ^= HCC137_&label2. then HCC137 = 1;
	if HCC157_&label1. ^= HCC157_&label2. then HCC157 = 1;
	if HCC158_&label1. ^= HCC158_&label2. then HCC158 = 1;
	if HCC161_&label1. ^= HCC161_&label2. then HCC161 = 1;
	if HCC162_&label1. ^= HCC162_&label2. then HCC162 = 1;
	if HCC166_&label1. ^= HCC166_&label2. then HCC166 = 1;
	if HCC167_&label1. ^= HCC167_&label2. then HCC167 = 1;
	if HCC169_&label1. ^= HCC169_&label2. then HCC169 = 1;
	if HCC17_&label1. ^= HCC17_&label2. then HCC17 = 1;
	if HCC170_&label1. ^= HCC170_&label2. then HCC170 = 1;
	if HCC173_&label1. ^= HCC173_&label2. then HCC173 = 1;
	if HCC176_&label1. ^= HCC176_&label2. then HCC176 = 1;
	if HCC18_&label1. ^= HCC18_&label2. then HCC18 = 1;
	if HCC186_&label1. ^= HCC186_&label2. then HCC186 = 1;
	if HCC188_&label1. ^= HCC188_&label2. then HCC188 = 1;
	if HCC189_&label1. ^= HCC189_&label2. then HCC189 = 1;
	if HCC19_&label1. ^= HCC19_&label2. then HCC19 = 1;
	if HCC2_&label1. ^= HCC2_&label2. then HCC2 = 1;
	if HCC21_&label1. ^= HCC21_&label2. then HCC21 = 1;
	if HCC22_&label1. ^= HCC22_&label2. then HCC22 = 1;
	if HCC23_&label1. ^= HCC23_&label2. then HCC23 = 1;
	if HCC27_&label1. ^= HCC27_&label2. then HCC27 = 1;
	if HCC28_&label1. ^= HCC28_&label2. then HCC28 = 1;
	if HCC29_&label1. ^= HCC29_&label2. then HCC29 = 1;
	if HCC33_&label1. ^= HCC33_&label2. then HCC33 = 1;
	if HCC34_&label1. ^= HCC34_&label2. then HCC34 = 1;
	if HCC35_&label1. ^= HCC35_&label2. then HCC35 = 1;
	if HCC39_&label1. ^= HCC39_&label2. then HCC39 = 1;
	if HCC40_&label1. ^= HCC40_&label2. then HCC40 = 1;
	if HCC46_&label1. ^= HCC46_&label2. then HCC46 = 1;
	if HCC47_&label1. ^= HCC47_&label2. then HCC47 = 1;
	if HCC48_&label1. ^= HCC48_&label2. then HCC48 = 1;
	if HCC54_&label1. ^= HCC54_&label2. then HCC54 = 1;
	if HCC55_&label1. ^= HCC55_&label2. then HCC55 = 1;
	if HCC57_&label1. ^= HCC57_&label2. then HCC57 = 1;
	if HCC58_&label1. ^= HCC58_&label2. then HCC58 = 1;
	if HCC6_&label1. ^= HCC6_&label2. then HCC6 = 1;
	if HCC70_&label1. ^= HCC70_&label2. then HCC70 = 1;
	if HCC71_&label1. ^= HCC71_&label2. then HCC71 = 1;
	if HCC72_&label1. ^= HCC72_&label2. then HCC72 = 1;
	if HCC73_&label1. ^= HCC73_&label2. then HCC73 = 1;
	if HCC74_&label1. ^= HCC74_&label2. then HCC74 = 1;
	if HCC75_&label1. ^= HCC75_&label2. then HCC75 = 1;
	if HCC76_&label1. ^= HCC76_&label2. then HCC76 = 1;
	if HCC77_&label1. ^= HCC77_&label2. then HCC77 = 1;
	if HCC78_&label1. ^= HCC78_&label2. then HCC78 = 1;
	if HCC79_&label1. ^= HCC79_&label2. then HCC79 = 1;
	if HCC8_&label1. ^= HCC8_&label2. then HCC8 = 1;
	if HCC80_&label1. ^= HCC80_&label2. then HCC80 = 1;
	if HCC82_&label1. ^= HCC82_&label2. then HCC82 = 1;
	if HCC83_&label1. ^= HCC83_&label2. then HCC83 = 1;
	if HCC84_&label1. ^= HCC84_&label2. then HCC84 = 1;
	if HCC85_&label1. ^= HCC85_&label2. then HCC85 = 1;
	if HCC86_&label1. ^= HCC86_&label2. then HCC86 = 1;
	if HCC87_&label1. ^= HCC87_&label2. then HCC87 = 1;
	if HCC88_&label1. ^= HCC88_&label2. then HCC88 = 1;
	if HCC9_&label1. ^= HCC9_&label2. then HCC9 = 1;
	if HCC96_&label1. ^= HCC96_&label2. then HCC96 = 1;
	if HCC99_&label1. ^= HCC99_&label2. then HCC99 = 1;
	if LTI_&label1. ^= LTI_&label2. then LTI = 1;
	if ORIGDS_&label1. ^= ORIGDS_&label2. then ORIGDS = 1;
	if PRIOR_HOSP_W_ANY_IP_FLAG_90_&label1. ^= PRIOR_HOSP_W_ANY_IP_FLAG_90_&label2. then PRIOR_HOSP_W_ANY_IP_FLAG_90 = 1;
	if SEPSIS_CARD_RESP_FAIL_&label1. ^= SEPSIS_CARD_RESP_FAIL_&label2. then SEPSIS_CARD_RESP_FAIL = 1;
	if TKA_FLAG_&label1. ^= TKA_FLAG_&label2. then TKA_FLAG = 1;
	if TKA_FRACTURE_FLAG_&label1. ^= TKA_FRACTURE_FLAG_&label2. then TKA_FRACTURE_FLAG = 1;

	Change_Flag = 0;
	Change_Flag = max(of AGE_50 -- TKA_FRACTURE_FLAG);

	Label = strip(ep_num_&label1.) || "_" || strip(ep_num_&label2.) ;

run;

proc sql;
	create table t5_&bpid1._&bpid2._&timeper. as 
	select "&timeper." as Time_Period, Label, BPID, ANCHOR_TYPE, EPISODE_GROUP_NAME,
		count(*) as Episodes,
		sum(Change_Flag) as Change_Flag,
		sum(AGE_50) as AGE_50,
		sum(AGE_50_SQ) as AGE_50_SQ,
		sum(ANY_DUAL) as ANY_DUAL,
		sum(APC_2019_5193) as APC_2019_5193,
		sum(APC_2019_5194) as APC_2019_5194,
		sum(APC_2019_5232) as APC_2019_5232,
		sum(APC_2019_5432) as APC_2019_5432,
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
		sum(DRG_CD_2019_062) as DRG_CD_2019_062,
		sum(DRG_CD_2019_063) as DRG_CD_2019_063,
		sum(DRG_CD_2019_064) as DRG_CD_2019_064,
		sum(DRG_CD_2019_065) as DRG_CD_2019_065,
		sum(DRG_CD_2019_066) as DRG_CD_2019_066,
		sum(DRG_CD_2019_178) as DRG_CD_2019_178,
		sum(DRG_CD_2019_179) as DRG_CD_2019_179,
		sum(DRG_CD_2019_191) as DRG_CD_2019_191,
		sum(DRG_CD_2019_192) as DRG_CD_2019_192,
		sum(DRG_CD_2019_193) as DRG_CD_2019_193,
		sum(DRG_CD_2019_194) as DRG_CD_2019_194,
		sum(DRG_CD_2019_195) as DRG_CD_2019_195,
		sum(DRG_CD_2019_202) as DRG_CD_2019_202,
		sum(DRG_CD_2019_203) as DRG_CD_2019_203,
		sum(DRG_CD_2019_217) as DRG_CD_2019_217,
		sum(DRG_CD_2019_218) as DRG_CD_2019_218,
		sum(DRG_CD_2019_219) as DRG_CD_2019_219,
		sum(DRG_CD_2019_220) as DRG_CD_2019_220,
		sum(DRG_CD_2019_221) as DRG_CD_2019_221,
		sum(DRG_CD_2019_223) as DRG_CD_2019_223,
		sum(DRG_CD_2019_224) as DRG_CD_2019_224,
		sum(DRG_CD_2019_225) as DRG_CD_2019_225,
		sum(DRG_CD_2019_226) as DRG_CD_2019_226,
		sum(DRG_CD_2019_227) as DRG_CD_2019_227,
		sum(DRG_CD_2019_232) as DRG_CD_2019_232,
		sum(DRG_CD_2019_233) as DRG_CD_2019_233,
		sum(DRG_CD_2019_234) as DRG_CD_2019_234,
		sum(DRG_CD_2019_235) as DRG_CD_2019_235,
		sum(DRG_CD_2019_236) as DRG_CD_2019_236,
		sum(DRG_CD_2019_243) as DRG_CD_2019_243,
		sum(DRG_CD_2019_244) as DRG_CD_2019_244,
		sum(DRG_CD_2019_247) as DRG_CD_2019_247,
		sum(DRG_CD_2019_248) as DRG_CD_2019_248,
		sum(DRG_CD_2019_249) as DRG_CD_2019_249,
		sum(DRG_CD_2019_250) as DRG_CD_2019_250,
		sum(DRG_CD_2019_251) as DRG_CD_2019_251,
		sum(DRG_CD_2019_266) as DRG_CD_2019_266,
		sum(DRG_CD_2019_267) as DRG_CD_2019_267,
		sum(DRG_CD_2019_273) as DRG_CD_2019_273,
		sum(DRG_CD_2019_274) as DRG_CD_2019_274,
		sum(DRG_CD_2019_281) as DRG_CD_2019_281,
		sum(DRG_CD_2019_282) as DRG_CD_2019_282,
		sum(DRG_CD_2019_292) as DRG_CD_2019_292,
		sum(DRG_CD_2019_293) as DRG_CD_2019_293,
		sum(DRG_CD_2019_309) as DRG_CD_2019_309,
		sum(DRG_CD_2019_310) as DRG_CD_2019_310,
		sum(DRG_CD_2019_330) as DRG_CD_2019_330,
		sum(DRG_CD_2019_331) as DRG_CD_2019_331,
		sum(DRG_CD_2019_378) as DRG_CD_2019_378,
		sum(DRG_CD_2019_379) as DRG_CD_2019_379,
		sum(DRG_CD_2019_389) as DRG_CD_2019_389,
		sum(DRG_CD_2019_390) as DRG_CD_2019_390,
		sum(DRG_CD_2019_442) as DRG_CD_2019_442,
		sum(DRG_CD_2019_443) as DRG_CD_2019_443,
		sum(DRG_CD_2019_454) as DRG_CD_2019_454,
		sum(DRG_CD_2019_455) as DRG_CD_2019_455,
		sum(DRG_CD_2019_460) as DRG_CD_2019_460,
		sum(DRG_CD_2019_462) as DRG_CD_2019_462,
		sum(DRG_CD_2019_470) as DRG_CD_2019_470,
		sum(DRG_CD_2019_472) as DRG_CD_2019_472,
		sum(DRG_CD_2019_473) as DRG_CD_2019_473,
		sum(DRG_CD_2019_481) as DRG_CD_2019_481,
		sum(DRG_CD_2019_482) as DRG_CD_2019_482,
		sum(DRG_CD_2019_493) as DRG_CD_2019_493,
		sum(DRG_CD_2019_494) as DRG_CD_2019_494,
		sum(DRG_CD_2019_519) as DRG_CD_2019_519,
		sum(DRG_CD_2019_520) as DRG_CD_2019_520,
		sum(DRG_CD_2019_534) as DRG_CD_2019_534,
		sum(DRG_CD_2019_535) as DRG_CD_2019_535,
		sum(DRG_CD_2019_536) as DRG_CD_2019_536,
		sum(DRG_CD_2019_603) as DRG_CD_2019_603,
		sum(DRG_CD_2019_683) as DRG_CD_2019_683,
		sum(DRG_CD_2019_684) as DRG_CD_2019_684,
		sum(DRG_CD_2019_690) as DRG_CD_2019_690,
		sum(DRG_CD_2019_871) as DRG_CD_2019_871,
		sum(DRG_CD_2019_872) as DRG_CD_2019_872,
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
	from t4
	group by "&timeper.", Label, BPID, ANCHOR_TYPE, EPISODE_GROUP_NAME;
quit;

%mend;

%runhosp(1125,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(1148,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(1167,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(1209,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(1343,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(1368,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(1374,0004,y201810,y201811,1810,1811,201810_201811);
%runhosp(1374,0008,y201810,y201811,1810,1811,201810_201811);
%runhosp(1374,0009,y201810,y201811,1810,1811,201810_201811);
%runhosp(1686,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(1688,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(1696,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(1710,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(1958,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2070,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2374,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2376,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2378,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2379,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0003,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0004,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0005,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0006,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0007,y201810,y201811,1810,1811,201810_201811);
%runhosp(1075,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0009,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0010,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0011,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0012,y201810,y201811,1810,1811,201810_201811);
*%runhosp(5746,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0013,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0014,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0015,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0016,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0017,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0020,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0021,y201810,y201811,1810,1811,201810_201811);
%runhosp(2586,0023,y201810,y201811,1810,1811,201810_201811);
%runhosp(2594,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2048,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2049,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2607,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5038,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5050,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2587,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2589,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5154,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5282,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(2631,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5037,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5478,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(5043,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5479,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(5480,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(5215,0003,y201810,y201811,1810,1811,201810_201811);
%runhosp(5215,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(5229,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5263,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5264,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5481,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(5394,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5395,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5397,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(5397,0005,y201810,y201811,1810,1811,201810_201811);
%runhosp(5397,0004,y201810,y201811,1810,1811,201810_201811);
%runhosp(5397,0008,y201810,y201811,1810,1811,201810_201811);
%runhosp(5397,0003,y201810,y201811,1810,1811,201810_201811);
%runhosp(5397,0006,y201810,y201811,1810,1811,201810_201811);
%runhosp(5397,0009,y201810,y201811,1810,1811,201810_201811);
%runhosp(5397,0010,y201810,y201811,1810,1811,201810_201811);
%runhosp(5916,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(6049,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(6050,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(6051,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(6052,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(6053,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(5397,0007,y201810,y201811,1810,1811,201810_201811);
%runhosp(1102,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(1105,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(1106,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(1103,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(1104,0000,y201810,y201811,1810,1811,201810_201811);
%runhosp(5392,0004,y201810,y201811,1810,1811,201810_201811);
%runhosp(6054,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(6055,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(6056,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(6057,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(6058,0002,y201810,y201811,1810,1811,201810_201811);
%runhosp(6059,0002,y201810,y201811,1810,1811,201810_201811);
*%runhosp(1191,0002,y201810,y201811,1810,1811,201810_201811);

%runhosp(1125,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(1148,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(1167,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(1209,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(1343,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(1368,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(1374,0004,y201811,y201812,1811,1812,201811_201812);
%runhosp(1374,0008,y201811,y201812,1811,1812,201811_201812);
%runhosp(1374,0009,y201811,y201812,1811,1812,201811_201812);
%runhosp(1686,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(1688,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(1696,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(1710,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(1958,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2070,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2374,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2376,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2378,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2379,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0003,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0004,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0005,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0006,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0007,y201811,y201812,1811,1812,201811_201812);
%runhosp(1075,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0009,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0010,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0011,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0012,y201811,y201812,1811,1812,201811_201812);
*%runhosp(5746,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0013,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0014,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0015,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0016,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0017,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0020,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0021,y201811,y201812,1811,1812,201811_201812);
%runhosp(2586,0023,y201811,y201812,1811,1812,201811_201812);
%runhosp(2594,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2048,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2049,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2607,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5038,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5050,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2587,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2589,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5154,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5282,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(2631,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5037,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5478,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(5043,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5479,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(5480,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(5215,0003,y201811,y201812,1811,1812,201811_201812);
%runhosp(5215,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(5229,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5263,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5264,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5481,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(5394,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5395,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5397,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(5397,0005,y201811,y201812,1811,1812,201811_201812);
%runhosp(5397,0004,y201811,y201812,1811,1812,201811_201812);
%runhosp(5397,0008,y201811,y201812,1811,1812,201811_201812);
%runhosp(5397,0003,y201811,y201812,1811,1812,201811_201812);
%runhosp(5397,0006,y201811,y201812,1811,1812,201811_201812);
%runhosp(5397,0009,y201811,y201812,1811,1812,201811_201812);
%runhosp(5397,0010,y201811,y201812,1811,1812,201811_201812);
%runhosp(5916,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(6049,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(6050,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(6051,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(6052,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(6053,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(5397,0007,y201811,y201812,1811,1812,201811_201812);
%runhosp(1102,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(1105,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(1106,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(1103,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(1104,0000,y201811,y201812,1811,1812,201811_201812);
%runhosp(5392,0004,y201811,y201812,1811,1812,201811_201812);
%runhosp(6054,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(6055,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(6056,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(6057,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(6058,0002,y201811,y201812,1811,1812,201811_201812);
%runhosp(6059,0002,y201811,y201812,1811,1812,201811_201812);
*%runhosp(1191,0002,y201811,y201812,1811,1812,201811_201812);

%runhosp(1125,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(1148,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(1167,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(1209,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(1343,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(1368,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(1374,0004,y201812,y201901,1812,1901,201812_201901);
%runhosp(1374,0008,y201812,y201901,1812,1901,201812_201901);
%runhosp(1374,0009,y201812,y201901,1812,1901,201812_201901);
%runhosp(1686,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(1688,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(1696,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(1710,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(1958,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2070,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2374,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2376,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2378,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2379,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0003,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0004,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0005,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0006,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0007,y201812,y201901,1812,1901,201812_201901);
%runhosp(1075,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0009,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0010,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0011,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0012,y201812,y201901,1812,1901,201812_201901);
%runhosp(5746,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0013,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0014,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0015,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0016,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0017,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0020,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0021,y201812,y201901,1812,1901,201812_201901);
%runhosp(2586,0023,y201812,y201901,1812,1901,201812_201901);
%runhosp(2594,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2048,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2049,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2607,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5038,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5050,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2587,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2589,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5154,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5282,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(2631,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5037,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5478,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(5043,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5479,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(5480,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(5215,0003,y201812,y201901,1812,1901,201812_201901);
%runhosp(5215,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(5229,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5263,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5264,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5481,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(5394,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5395,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5397,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(5397,0005,y201812,y201901,1812,1901,201812_201901);
%runhosp(5397,0004,y201812,y201901,1812,1901,201812_201901);
%runhosp(5397,0008,y201812,y201901,1812,1901,201812_201901);
%runhosp(5397,0003,y201812,y201901,1812,1901,201812_201901);
%runhosp(5397,0006,y201812,y201901,1812,1901,201812_201901);
%runhosp(5397,0009,y201812,y201901,1812,1901,201812_201901);
%runhosp(5397,0010,y201812,y201901,1812,1901,201812_201901);
%runhosp(5916,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(6049,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(6050,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(6051,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(6052,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(6053,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(5397,0007,y201812,y201901,1812,1901,201812_201901);
%runhosp(1102,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(1105,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(1106,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(1103,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(1104,0000,y201812,y201901,1812,1901,201812_201901);
%runhosp(5392,0004,y201812,y201901,1812,1901,201812_201901);
%runhosp(6054,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(6055,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(6056,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(6057,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(6058,0002,y201812,y201901,1812,1901,201812_201901);
%runhosp(6059,0002,y201812,y201901,1812,1901,201812_201901);
*%runhosp(1191,0002,y201812,y201901,1812,1901,201812_201901);

%runhosp(1125,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(1148,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(1167,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(1209,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(1343,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(1368,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(1374,0004,y201901,y201902,1901,1902,201901_201902);
%runhosp(1374,0008,y201901,y201902,1901,1902,201901_201902);
%runhosp(1374,0009,y201901,y201902,1901,1902,201901_201902);
%runhosp(1686,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(1688,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(1696,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(1710,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(1958,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2070,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2374,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2376,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2378,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2379,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0003,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0004,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0005,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0006,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0007,y201901,y201902,1901,1902,201901_201902);
%runhosp(1075,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0009,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0010,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0011,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0012,y201901,y201902,1901,1902,201901_201902);
%runhosp(5746,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0013,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0014,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0015,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0016,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0017,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0020,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0021,y201901,y201902,1901,1902,201901_201902);
%runhosp(2586,0023,y201901,y201902,1901,1902,201901_201902);
%runhosp(2594,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2048,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2049,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2607,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5038,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5050,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2587,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2589,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5154,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5282,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(2631,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5037,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5478,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(5043,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5479,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(5480,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(5215,0003,y201901,y201902,1901,1902,201901_201902);
%runhosp(5215,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(5229,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5263,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5264,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5481,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(5394,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5395,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5397,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(5397,0005,y201901,y201902,1901,1902,201901_201902);
%runhosp(5397,0004,y201901,y201902,1901,1902,201901_201902);
%runhosp(5397,0008,y201901,y201902,1901,1902,201901_201902);
%runhosp(5397,0003,y201901,y201902,1901,1902,201901_201902);
%runhosp(5397,0006,y201901,y201902,1901,1902,201901_201902);
%runhosp(5397,0009,y201901,y201902,1901,1902,201901_201902);
%runhosp(5397,0010,y201901,y201902,1901,1902,201901_201902);
%runhosp(5916,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(6049,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(6050,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(6051,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(6052,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(6053,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(5397,0007,y201901,y201902,1901,1902,201901_201902);
%runhosp(1102,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(1105,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(1106,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(1103,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(1104,0000,y201901,y201902,1901,1902,201901_201902);
%runhosp(5392,0004,y201901,y201902,1901,1902,201901_201902);
%runhosp(6054,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(6055,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(6056,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(6057,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(6058,0002,y201901,y201902,1901,1902,201901_201902);
%runhosp(6059,0002,y201901,y201902,1901,1902,201901_201902);
*%runhosp(1191,0002,y201901,y201902,1901,1902,201901_201902);

%runhosp(1125,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(1148,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(1167,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(1209,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(1343,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(1368,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(1374,0004,y201902,y201903,1902,1903,201902_201903);
%runhosp(1374,0008,y201902,y201903,1902,1903,201902_201903);
%runhosp(1374,0009,y201902,y201903,1902,1903,201902_201903);
%runhosp(1686,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(1688,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(1696,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(1710,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(1958,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2070,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2374,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2376,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2378,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2379,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0003,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0004,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0005,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0006,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0007,y201902,y201903,1902,1903,201902_201903);
%runhosp(1075,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0009,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0010,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0011,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0012,y201902,y201903,1902,1903,201902_201903);
%runhosp(5746,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0013,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0014,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0015,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0016,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0017,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0020,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0021,y201902,y201903,1902,1903,201902_201903);
%runhosp(2586,0023,y201902,y201903,1902,1903,201902_201903);
%runhosp(2594,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2048,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2049,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2607,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5038,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5050,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2587,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2589,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5154,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5282,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(2631,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5037,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5478,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(5043,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5479,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(5480,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(5215,0003,y201902,y201903,1902,1903,201902_201903);
%runhosp(5215,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(5229,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5263,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5264,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5481,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(5394,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5395,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5397,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(5397,0005,y201902,y201903,1902,1903,201902_201903);
%runhosp(5397,0004,y201902,y201903,1902,1903,201902_201903);
%runhosp(5397,0008,y201902,y201903,1902,1903,201902_201903);
%runhosp(5397,0003,y201902,y201903,1902,1903,201902_201903);
%runhosp(5397,0006,y201902,y201903,1902,1903,201902_201903);
%runhosp(5397,0009,y201902,y201903,1902,1903,201902_201903);
%runhosp(5397,0010,y201902,y201903,1902,1903,201902_201903);
%runhosp(5916,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(6049,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(6050,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(6051,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(6052,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(6053,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(5397,0007,y201902,y201903,1902,1903,201902_201903);
%runhosp(1102,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(1105,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(1106,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(1103,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(1104,0000,y201902,y201903,1902,1903,201902_201903);
%runhosp(5392,0004,y201902,y201903,1902,1903,201902_201903);
%runhosp(6054,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(6055,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(6056,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(6057,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(6058,0002,y201902,y201903,1902,1903,201902_201903);
%runhosp(6059,0002,y201902,y201903,1902,1903,201902_201903);
*%runhosp(1191,0002,y201902,y201903,1902,1903,201902_201903);

%runhosp(1125,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(1148,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(1167,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(1209,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(1343,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(1368,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(1374,0004,y201903,y201904,1903,1904,201903_201904);
%runhosp(1374,0008,y201903,y201904,1903,1904,201903_201904);
%runhosp(1374,0009,y201903,y201904,1903,1904,201903_201904);
%runhosp(1686,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(1688,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(1696,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(1710,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(1958,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2070,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2374,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2376,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2378,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2379,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0003,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0004,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0005,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0006,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0007,y201903,y201904,1903,1904,201903_201904);
%runhosp(1075,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0009,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0010,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0011,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0012,y201903,y201904,1903,1904,201903_201904);
%runhosp(5746,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0013,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0014,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0015,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0016,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0017,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0020,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0021,y201903,y201904,1903,1904,201903_201904);
%runhosp(2586,0023,y201903,y201904,1903,1904,201903_201904);
%runhosp(2594,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2048,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2049,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2607,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5038,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5050,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2587,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2589,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5154,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5282,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(2631,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5037,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5478,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(5043,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5479,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(5480,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(5215,0003,y201903,y201904,1903,1904,201903_201904);
%runhosp(5215,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(5229,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5263,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5264,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5481,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(5394,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5395,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5397,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(5397,0005,y201903,y201904,1903,1904,201903_201904);
%runhosp(5397,0004,y201903,y201904,1903,1904,201903_201904);
%runhosp(5397,0008,y201903,y201904,1903,1904,201903_201904);
%runhosp(5397,0003,y201903,y201904,1903,1904,201903_201904);
%runhosp(5397,0006,y201903,y201904,1903,1904,201903_201904);
%runhosp(5397,0009,y201903,y201904,1903,1904,201903_201904);
%runhosp(5397,0010,y201903,y201904,1903,1904,201903_201904);
%runhosp(5916,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(6049,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(6050,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(6051,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(6052,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(6053,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(5397,0007,y201903,y201904,1903,1904,201903_201904);
%runhosp(1102,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(1105,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(1106,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(1103,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(1104,0000,y201903,y201904,1903,1904,201903_201904);
%runhosp(5392,0004,y201903,y201904,1903,1904,201903_201904);
%runhosp(6054,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(6055,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(6056,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(6057,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(6058,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(6059,0002,y201903,y201904,1903,1904,201903_201904);
%runhosp(1191,0002,y201903,y201904,1903,1904,201903_201904);


data TP_Var_Compare;
	set t5:;
run;

%MACRO EXPORT;
%if &mode.=main %then %do;
	proc export data= TP_Var_Compare
	    outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\88 - Documentation\50 - BPCI Advanced 2019\Checking Documentation\_Data Summary\sasout_Compare TP Variables_&sysdate..csv"
	    dbms=csv replace; 
	run;
%end;
%else %if &mode.=base %then %do;
	proc export data= TP_Var_Compare
	    outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\88 - Documentation\50 - BPCI Advanced 2019\Checking Documentation\_Data Summary\sasout_Baseline Compare TP Variables_&sysdate..csv"
	    dbms=csv replace; 
	run;
%end;
%mend EXPORT;

%EXPORT;


proc printto;run;
%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;


