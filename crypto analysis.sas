
****************************************************************************************************************************
* Program:  crypto analysis.sas
* Author:	Kaitlin Benedict
* Purpose:	Analyze Premier Healthcare Data patients hospitalized with crypto meningitis (identified by ICD-10 code)
****************************************************************************************************************************;

libname cr '\\cdc.gov\project\CCID_NCZVED_DFBMD_MDB\Mycotics-Epi\Premier\Crypto\analysis'; run;
libname LU '\\cdc.gov\project\NCEZID_ERIB_CERNER2\PREMIER\LookupArchive202210209'; run;

*Import data. Pulled from Databricks on 10/22/2024*;
PROC IMPORT OUT=cr.patdemo 
DATAFILE= "\\cdc.gov\project\CCID_NCZVED_DFBMD_MDB\Mycotics-Epi\Premier\Crypto\analysis\patdemo.csv" 
DBMS=CSV REPLACE; GETNAMES=YES; DATAROW=2; guessingrows=32767; 
RUN; 
PROC IMPORT OUT=cr.paticd_diag 
DATAFILE= "\\cdc.gov\project\CCID_NCZVED_DFBMD_MDB\Mycotics-Epi\Premier\Crypto\analysis\paticd_diag.csv" 
DBMS=CSV REPLACE; GETNAMES=YES; DATAROW=2; guessingrows=32767; 
RUN; 
PROC IMPORT OUT=cr.lab_res 
DATAFILE= "\\cdc.gov\project\CCID_NCZVED_DFBMD_MDB\Mycotics-Epi\Premier\Crypto\analysis\lab_res.csv" 
DBMS=CSV REPLACE; GETNAMES=YES; DATAROW=2; guessingrows=32767; 
RUN; 
PROC IMPORT OUT=cr.genlab 
DATAFILE= "\\cdc.gov\project\CCID_NCZVED_DFBMD_MDB\Mycotics-Epi\Premier\Crypto\analysis\genlab.csv" 
DBMS=CSV REPLACE; GETNAMES=YES; DATAROW=2; guessingrows=32767; 
RUN; 
PROC IMPORT OUT=cr.genlab_flag
DATAFILE= "\\cdc.gov\project\CCID_NCZVED_DFBMD_MDB\Mycotics-Epi\Premier\Crypto\analysis\genlab_flag.csv" 
DBMS=CSV REPLACE; GETNAMES=YES; DATAROW=2; guessingrows=32767; 
RUN; 
PROC IMPORT OUT=cr.patbill 
DATAFILE= "\\cdc.gov\project\CCID_NCZVED_DFBMD_MDB\Mycotics-Epi\Premier\Crypto\analysis\patbill.csv" 
DBMS=CSV REPLACE; GETNAMES=YES; DATAROW=2; guessingrows=32767; 
RUN;
PROC IMPORT OUT=cr.paticd_proc 
DATAFILE= "\\cdc.gov\project\CCID_NCZVED_DFBMD_MDB\Mycotics-Epi\Premier\Crypto\analysis\paticd_proc.csv" 
DBMS=CSV REPLACE; GETNAMES=YES; DATAROW=2; guessingrows=32767; 
RUN;
PROC IMPORT OUT=cr.cpt 
DATAFILE= "\\cdc.gov\project\CCID_NCZVED_DFBMD_MDB\Mycotics-Epi\Premier\Crypto\analysis\cpt.csv" 
DBMS=CSV REPLACE; GETNAMES=YES; DATAROW=2; guessingrows=32767; 
RUN;

*Explore datasets*;
proc contents data=cr.patdemo; run; *demographics, n=3193*;
proc contents data=cr.paticd_diag; run; *ICD diagnosis codes, n=77313*;
proc contents data=cr.lab_res; run; *microbiology lab data, n=18280*;
proc contents data=cr.genlab; run; *general lab data, n=372087*;
proc contents data=cr.patbill; run; *billing data, n=1542722*;
proc contents data=cr.paticd_proc; run; *ICD procedure codes, n=15274*;
proc contents data=cr.cpt; run; *cpt codes, n=311899*;

****************************
****************************
ICD DIAGNOSIS CODES
****************************
****************************

*Get the most common (non-admitting) ICD-10 diagnosis codes to make sure we're not missing
anything important when we create our flags. Note, we did try pulling GCS this way, 
but the numbers were so small that they'd have to be suppressed.*;
proc freq data=cr.paticd_diag order=freq; tables icd_code; where ICD_PRI_SEC ne 'A'; run;

*Flag underlying conditions of interest, remove admitting diagnoses*;
data cr.paticd_diag2; set cr.paticd_diag; where icd_pri_sec ne 'A'; 
if icd_code in: ('N17') then icd_acutekidney=1; else icd_acutekidney=0;
if icd_code in: ('D50' 'D51' 'D52' 'D53' 'D55' 'D56' 'D57' 'D58' 'D59'
	'D60' 'D61' 'D62' 'D63' 'D64') then icd_anemia=1; else icd_anemia=0;
if icd_code in: ('G35' 'G70' 'K50' 'K51' 'L40' 'L93' 'M02.3' 'M05' 'M06' 'M08' 'M33' 'M35.2' 'M45') 
	then icd_autoimmune=1; else icd_autoimmune=0;
if icd_code in: ('U07.1' 'B97.29') then icd_covid=1; else icd_covid=0;
if icd_code in: ('E08' 'E09' 'E10' 'E11' 'E12' 'E13') then icd_diabetes=1; else icd_diabetes=0;
if icd_code in: ('C81' 'C82' 'C83' 'C84' 'C85' 'C86' 'C88' 'C90' 'C91' 'C92' 'C93' 'C94' 
	'C95' 'C96') then icd_hememalig=1; else icd_hememalig=0;
if icd_code in: ('B20' 'Z21') then icd_HIV=1; else icd_HIV=0;
if icd_code in: ('E87.6') then icd_hypokalemia=1; else icd_hypokalemia=0;
if icd_code in: ('E87.1') then icd_hyponatremia=1; else icd_hyponatremia=0;
if icd_code in: ('D80' 'D81' 'D82' 'D83' 'D84' 'D85' 'D86' 'D87' 'D88' 'D89') 
	then icd_immunedz=1; else icd_immunedz=0;
if icd_code in: ('K70' 'K71' 'K72' 'K73' 'K74' 'K75' 'K76' 'K77') then icd_liverdz=1; else icd_liverdz=0;
if icd_code in: ('D70') then icd_neutropenia=1; else icd_neutropenia=0;
if icd_code in: ('E66') then icd_overweight=1; else icd_overweight=0;
if icd_code in: ('Z98.2') then icd_CSFdrain=1; else icd_CSFdrain=0;
if icd_code in: ('E40' 'E41' 'E42' 'E43' 'E44' 'E45' 'E46') then icd_malnut=1; else icd_malnut=0;
if icd_code in: ('D86') then icd_sarcoid=1; else icd_sarcoid=0;
if icd_code in: ('G40' 'R56') then icd_seizure=1; else icd_seizure=0;
if icd_code in: ('A40' 'A41') then icd_sepsis=1; else icd_sepsis=0;
if icd_code in: ('F17' 'Z72.0' 'Z87.891') then icd_smoking=1; else icd_smoking=0;
if icd_code in: ('C00' 'C01' 'C02' 'C03' 'C04' 'C05' 'C06' 'C07' 'C08' 'C09' 'C10' 'C11'
	'C12' 'C13' 'C14' 'C15' 'C16' 'C17' 'C18' 'C19' 'C20' 'C21' 'C22'
	'C23' 'C24' 'C25' 'C26' 'C27' 'C28' 'C29' 'C30' 'C31' 'C32' 'C33'
	'C34' 'C35' 'C36' 'C37' 'C38' 'C39' 'C40' 'C41' 'C42' 'C43' 'C45'
	'C46' 'C47' 'C48' 'C49' 'C50' 'C51' 'C52' 'C53' 'C54' 'C55' 'C56'
	'C57' 'C58' 'C59' 'C60' 'C61' 'C62' 'C63' 'C64' 'C65' 'C66' 'C67'
	'C68' 'C69' 'C70' 'C71' 'C72' 'C73' 'C74' 'C75' 'C76' 'C77' 'C78'
	'C79' 'C80' ) then icd_solidcancer=1; else icd_solidcancer=0;
if icd_code in: ('T86' 'Z94' 'Z95.2' 'Z95.3') then icd_transplant=1; else icd_transplant=0;
run;

*Summarize ICD flags to the hospitalization level*;
proc sql;
	create table cr.paticd_diag3 as
	select pat_key,
	max(icd_acutekidney) as icd_acutekidney,
	max(icd_anemia) as icd_autoimmune,
	max(icd_autoimmune) as icd_anemia,
	max(icd_covid) as icd_covid,
	max(icd_diabetes) as icd_diabetes,
	max(icd_hememalig) as icd_hememalig,
	max(icd_HIV) as icd_HIV,
	max(icd_hypokalemia) as icd_hypokalemia,
	max(icd_hyponatremia) as icd_hyponatremia,
	max(icd_immunedz) as icd_immunedz,
	max(icd_liverdz) as icd_liverdz,
	max(icd_neutropenia) as icd_neutropenia,
	max(icd_overweight) as icd_overweight,
	max(icd_CSFdrain) as icd_CSFdrain,
	max(icd_malnut) as icd_malnut,
	max(icd_sarcoid) as icd_sarcoid,
	max(icd_seizure) as icd_seizure,
	max(icd_sepsis) as icd_sepsis,
	max(icd_smoking) as icd_smoking,
	max(icd_solidcancer) as icd_solidcancer,
	max(icd_transplant) as icd_transplant
from cr.paticd_diag2
group by pat_key;
quit;

proc freq data=cr.paticd_diag3; tables
icd_acutekidney
icd_anemia
icd_autoimmune
icd_covid
icd_diabetes
icd_hememalig
icd_HIV
icd_hypokalemia
icd_hyponatremia
icd_immunedz
icd_liverdz
icd_neutropenia
icd_overweight
icd_CSFdrain
icd_malnut
icd_sarcoid
icd_seizure
icd_sepsis
icd_smoking
icd_solidcancer
icd_transplant;
run;

*Merge the diagnosis flags to the main dataset*;
proc sql;
create table cr.crypto as
select *
from cr.patdemo as a left join cr.paticd_diag3 as b
on a.pat_key=b.pat_key;
quit;


****************************
****************************
PATBILL 
****************************
****************************

////////*Searching for an easy way to identify ART by group, not by individual drug name*;
*not enough detail*;
proc freq data=cr.patbill; tables prod_cat_desc/out=prod_cat_desc; run; 
*this has something called "ANTIVIRALS, HIV" which could be good*;
proc freq data=cr.patbill; tables prod_class_desc/out=prod_class_desc; run; 
*this has slightly more detail than prod_class_desc but not much more detail on the HIV meds*;
proc freq data=cr.patbill; tables clin_sum_desc/out=clin_sum_desc; run; 
*this has individual medication names*;
proc freq data=cr.patbill; tables prod_name_meth_desc/out=prod_name_meth_desc; run; 
*med names within prod_class_desc="ANTIVIRALS, HIV"*;
proc freq data=cr.patbill; tables std_chg_desc; where prod_class_desc="ANTIVIRALS, HIV"; run; 
*/////////*;

*Output frequency dataset to identify items of interest. This variable has the most detail*;
proc freq data=cr.patbill; tables std_chg_desc/out=std_chg_desc; run;

*Flag items of interest*;
data cr.patbill2; set cr.patbill; 
bill_ICU=0; 
bill_vent=0;
bill_LP=0;
bill_lumbardrain=0;
bill_EVD_VP=0;
med_AMB_any=0;
med_ABLC=0;
med_LAMB=0;
med_AMB_unk=0;
med_fluc=0;
med_5FC=0;
med_ART=0;
if clin_sum_code in ("110108","110102") then bill_ICU=1; *Codes are from COVID/IFI analysis*;
if STD_CHG_DESC in (
'VENTILAT ASST & MANAGEMENT INIT SHIFT(8HRS) 94002'
'VENTILATION ASST & MANAGEMENT FIRST DAY 94002'
'VENTILATION ASST & MANAGEMENT SUBSEQUENT DAY 94003'
'VENTILATION MANUAL 15 MIN'
'VENTILATOR ASSESSMENT'
'VENTILATOR EQUIPMENT PER DAY'
'VENTILATOR MAINTENANCE'
'VENTILATOR PER SHIFT (8HRS) 94003'
'VENTILATOR SETUP'
'VENTILATOR STANDBY'
'VENTILATOR TRANSPORT'
'VENTILATOR WEANING PARAMETERS'
) then bill_vent=1; 
if STD_CHG_DESC in (
'CL PUNCTURE SPINAL LUMBAR DIAGNOSTIC'
'ER PUNCTURE SPINAL LUMBAR DIAGNOSTIC'
'PF PUNCT SPINAL LUMBAR DIAGNOSTIC W/FLUORO/CT GUID'
'PF PUNCTURE SPINAL LUMBAR DIAGNOSTIC'
'PUNCTURE SPINAL LUMBAR DIAGNOSTIC'
'PUNCTURE SPINAL LUMBAR DIAGNOSTIC W/FLUORO/CT GUID'
'TR PUNCT SPINAL LUMBAR DIAGNOSTIC W/FLUORO/CT GUID'
'TR PUNCTURE SPINAL LUMBAR DIAGNOSTIC'
'ER PUNCTURE SPINAL THERAPEUTIC'
'PF ANES DIAG/THERAPEUTIC LUMBAR PUNCTURE'
'PF PUNCTURE SPINAL THERAPEUTIC'
'PUNCTURE SPINAL THERAPEUTIC'
'PUNCTURE SPINAL THERAPEUTIC W/FLUORO/CT GUIDANCE'
'TR PUNCTURE SPINAL THERAPEUTIC W/FLUORO/CT GUIDANC'
'TRAY LUMBAR PUNCTURE'
'TRAY LUMBAR PUNCTURE PEDS'
) then bill_LP=1;
if STD_CHG_DESC in ('DRAIN LUMBAR') then bill_lumbardrain=1;
if STD_CHG_DESC in (
'DRAIN EXTERNAL VENTRICULAR (EVD)'
'DRAIN VENTRICULAR'
'SET DRAINAGE VENTRICULAR'
'CATHETER PERITONEAL VP SHUNT'
'CREATE SHUNT VENTRICULO-PERITON/PLEURAL/OTHER'
'REMOVE CSF SHUNT SYSTEM W/REPLACE'
'REPLACE/REVISE CSF SHUNT/VALVE/DISTAL CATH'
'SHUNT CSF FLOW CONTROL'
'SHUNT VENTRICULAR'
'SHUNT VP'
) then bill_EVD_VP=1;
if STD_CHG_DESC in (
'AMPHOTERICIN B MISC'
'AMPHOTERICIN B PARENTERAL MISC'
'AMPHOTERICIN B(LIPID), ABELCET VL 100MG'
'AMPHOTERICIN B(LIPID), ABELCET VL 10MG'
'AMPHOTERICIN B(LIPID), ABELCET VL 50MG'
'AMPHOTERICIN B(LIPO), AMBISOME INJ 10MG'
'AMPHOTERICIN B(LIPO), AMBISOME VL 50MG'
'AMPHOTERICIN B, FUNGIZONE VL 50MG'
) then med_AMB_any=1;
if STD_CHG_DESC in (
'AMPHOTERICIN B(LIPID), ABELCET VL 100MG'
'AMPHOTERICIN B(LIPID), ABELCET VL 10MG'
'AMPHOTERICIN B(LIPID), ABELCET VL 50MG'
) then med_ABLC=1;
if STD_CHG_DESC in (
'AMPHOTERICIN B(LIPO), AMBISOME INJ 10MG'
'AMPHOTERICIN B(LIPO), AMBISOME VL 50MG'
) then med_LAMB=1;
if STD_CHG_DESC in (
'AMPHOTERICIN B MISC'
'AMPHOTERICIN B PARENTERAL MISC'
) then med_AMB_unk=1;
if STD_CHG_DESC in (
'FLUCONAZOLE MISC'
'FLUCONAZOLE ORAL MISC'
'FLUCONAZOLE PARENTERAL MISC'
'FLUCONAZOLE, DIFLUCAN IV PREMIX 100MG'
'FLUCONAZOLE, DIFLUCAN IV PREMIX 200MG'
'FLUCONAZOLE, DIFLUCAN IV PREMIX 400MG'
'FLUCONAZOLE, DIFLUCAN SUSP 10MG/ML 35ML'
'FLUCONAZOLE, DIFLUCAN SUSP 40MG/ML 35ML'
'FLUCONAZOLE, DIFLUCAN SUSP 40MG/ML 5ML'
'FLUCONAZOLE, DIFLUCAN TAB 100MG'
'FLUCONAZOLE, DIFLUCAN TAB 150MG'
'FLUCONAZOLE, DIFLUCAN TAB 200MG'
'FLUCONAZOLE, DIFLUCAN TAB 50MG'
'FLUCONAZOLE, DIFLUCAN VL 100MG 50ML'
'FLUCONAZOLE, DIFLUCAN VL 200MG 100ML'
'FLUCONAZOLE, DIFLUCAN VL 400MG 200ML'
) then med_fluc=1;
if STD_CHG_DESC in (
'FLUCYTOSINE'
'FLUCYTOSINE MISC'
'FLUCYTOSINE ORAL MISC'
'FLUCYTOSINE, ANCOBON CAP 250MG'
'FLUCYTOSINE, ANCOBON CAP 500MG'
) then med_5FC=1;
if prod_class_desc="ANTIVIRALS, HIV" then med_ART=1;
run;

*Collapse patbill flags to the hospitalization level and create variables for start day and total # days*;
proc sql; 
  create table cr.patbill3 as
  select pat_key, 
  	max(bill_ICU) as bill_ICU,
	max(bill_vent) as bill_vent,
	max(bill_LP) as bill_LP,
	max(bill_lumbardrain) as bill_lumbardrain,
	max(bill_EVD_VP) as bill_EVD_VP,
	max(med_AMB_any) as med_AMB_any,
	max(med_ABLC) as med_ABLC,
	max(med_LAMB) as med_LAMB,
	max(med_AMB_unk) as med_AMB_unk,
	max(med_fluc) as med_fluc,
	max(med_5FC) as med_5FC,
	max(med_ART) as med_ART,
	min(case when (bill_ICU=1) then serv_date end) as startday_bill_ICU,
	min(case when (bill_vent=1) then serv_date end) as startday_bill_vent,
	min(case when (bill_LP=1) then serv_date end) as startday_bill_LP,
	min(case when (bill_lumbardrain=1) then serv_date end) as startday_bill_lumbardrain,
	min(case when (bill_EVD_VP=1) then serv_date end) as startday_bill_EVD_VP,
	min(case when (med_AMB_any=1) then serv_date end) as startday_med_AMB_any,
	min(case when (med_ABLC=1) then serv_date end) as startday_med_ABLC,
	min(case when (med_LAMB=1) then serv_date end) as startday_med_LAMB,
	min(case when (med_AMB_unk=1) then serv_date end) as startday_med_AMB_unk,
	min(case when (med_fluc=1) then serv_date end) as startday_med_fluc,
	min(case when (med_5FC=1) then serv_date end) as startday_med_5FC,
	min(case when (med_ART=1) then serv_date end) as startday_med_ART,
	count(distinct case when (bill_ICU=1) then serv_date end) as days_bill_ICU,
	count(distinct case when (bill_vent=1) then serv_date end) as days_bill_vent,
	count(distinct case when (bill_LP=1) then serv_date end) as days_bill_LP,
	count(distinct case when (bill_lumbardrain=1) then serv_date end) as days_bill_lumbardrain,
	count(distinct case when (bill_EVD_VP=1) then serv_date end) as days_bill_EVD_VP,
	count(distinct case when (med_AMB_any=1) then serv_date end) as days_med_AMB_any,
	count(distinct case when (med_ABLC=1) then serv_date end) as days_med_ABLC,
	count(distinct case when (med_LAMB=1) then serv_date end) as days_med_LAMB,
	count(distinct case when (med_AMB_unk=1) then serv_date end) as days_med_AMB_unk,
	count(distinct case when (med_fluc=1) then serv_date end) as days_med_fluc,
	count(distinct case when (med_5FC=1) then serv_date end) as days_med_5FC,
	count(distinct case when (med_ART=1) then serv_date end) as days_med_ART
  from cr.patbill2
  group by pat_key
  order by pat_key;
  quit;
  run;

data cr.patbill3; set cr.patbill3;
if bill_ICU=0 then days_bill_ICU=.;
if bill_vent=0 then days_bill_vent=.;
if bill_LP=0 then days_bill_LP=.;
if bill_lumbardrain=0 then days_bill_lumbardrain=.;
if bill_EVD_VP=0 then days_bill_EVD_VP=.;
if med_AMB_any=0 then days_med_AMB_any=.;
if med_ABLC=0 then days_med_ABLC=.;
if med_LAMB=0 then days_med_LAMB=.;
if med_AMB_unk=0 then days_med_AMB_unk=.;
if med_fluc=0 then days_med_fluc=.;
if med_5FC=0 then days_med_5FC=.;
if days_med_ART=0 then days_med_ART=.;
run;

*Check the new variables*;
proc freq data=cr.patbill3; tables
bill_ICU
bill_vent
bill_LP
bill_lumbardrain
bill_EVD_VP
med_AMB_any
med_ABLC
med_LAMB
med_AMB_unk
med_fluc
med_5FC
med_ART;
run;

proc means data=cr.patbill3 n mean median; var
days_bill_ICU
days_bill_vent
days_bill_LP
days_bill_lumbardrain
days_bill_EVD_VP
days_med_AMB_any
days_med_ABLC
days_med_LAMB
days_med_AMB_unk
days_med_fluc
days_med_5FC
days_med_ART;
run;

*Merge the billing flags to the main dataset*;
proc sql;
create table cr.crypto2 as
select *
from cr.crypto as a left join cr.patbill3 as b
on a.pat_key=b.pat_key;
quit;


****************************
****************************
PATICD_PROC
****************************
****************************

*Bring in the lookup table for code descriptions*;
proc sql;
create table cr.paticd_proc2 as
select a.*, b.icd_desc
from cr.paticd_proc as a left join LU.phd_lu_icdcode as b
on a.icd_code=b.icd_code;
quit;

*Check total number of hospitalizations - 2817, so not everyone had PCS recorded*;
proc sql; select count (distinct pat_key) as pat_key from cr.paticd_proc2; run; 

*Output frequency dataset to identify items of interest*;
proc freq data=cr.paticd_proc2; tables icd_desc icd_code/out=paticd_proc2;
where ICD_PRI_SEC ne 'A'; run;

*Flag LP, EVD/VP, and lumbar drains*;
data cr.paticd_proc3; set cr.paticd_proc2; 
proc_LP=0;
proc_EVD_VP=0;
proc_lumbardrain=0;
if icd_code in ('009Y3ZZ' '009Y40Z' '009U3ZX' '009U0ZX') then proc_LP=1;
if icd_code in ('009600Z' '00960ZX' '00960ZZ' '009630Z' '00963ZX' '00963ZZ' 
'009640Z' '00964ZX' '00964ZZ') then proc_EVD_VP=1;
if icd_code in ('009Y00Z' '009Y30Z' '009Y40Z' '0016076' '00160J6' '00160K6'
'0016376' '00163J6' '00163K6' '0016476' '00164J6' '00164K6') then proc_lumbardrain=1;
run;

proc sql; 
  create table cr.paticd_proc4 as
  select pat_key, 
  	max(proc_LP) as proc_LP,
	max(proc_EVD_VP) as proc_EVD_VP,
	max(proc_lumbardrain) as proc_lumbardrain,
	count(distinct case when (proc_LP=1) then proc_date end) as days_proc_LP,
	count(distinct case when (proc_EVD_VP=1) then proc_date end) as days_proc_EVD_VP,
	count(distinct case when (proc_lumbardrain=1) then proc_date end) as days_proc_lumbardrain
  from cr.paticd_proc3
  group by pat_key
  order by pat_key;
  quit;
  run;

proc freq data=cr.paticd_proc4; 
tables proc_LP proc_EVD_VP proc_lumbardrain days_proc_LP days_proc_EVD_VP days_proc_lumbardrain; run; 

*Merge the PCS code data to the main dataset*;
proc sql;
create table cr.crypto3 as
select *
from cr.crypto2 as a left join cr.paticd_proc4 as b
on a.pat_key=b.pat_key;
quit;


****************************
****************************
GEN_LAB
****************************
****************************

*Output frequency dataset to identify items of interest*;
proc freq data=cr.genlab; tables LAB_TEST_DESC/out=LAB_TEST_DESC; run;

*Limit the genlab data to CD4 tests*;
data cr.genlab2; set cr.genlab; 
where LAB_TEST_DESC in: 
('Cells.CD3+CD4+/100 cells:NFr:Pt:Bld:Qn'
'Cells.CD3+CD4+/100 cells:NFr:Pt:Body fld:Qn'
'Cells.CD3+CD4+/100 cells:NFr:Pt:Tiss:Qn'
'Cells.CD3+CD4+/100 cells:NFr:Pt:XXX:Qn'
'Cells.CD3+CD4+/Cells.CD3+CD8+:NRto:Pt:Bld:Qn'
'Cells.CD3+CD4+/Cells.CD3+CD8+:NRto:Pt:Body fld:Qn'
'Cells.CD3+CD4+/Cells.CD3+CD8+:NRto:Pt:Bronchial:Qn'
'Cells.CD3+CD4+/Cells.CD3+CD8+:NRto:Pt:XXX:Qn'
'Cells.CD3+CD4+:NCnc:Pt:Bld:Qn'
'Cells.CD4+CD8+/100 cells:NFr:Pt:Bld:Qn'
'Cells.CD4/100 cells:NFr:Pt:Bld:Qn'
'Cells.CD4/100 cells:NFr:Pt:XXX:Qn'
'Cells.CD4/100 lymphocytes:NFr:Pt:XXX:Qn'
'Cells.CD4/Cells.CD8:NRto:Pt:Bld:Qn'
'Cells.CD4:NCnc:Pt:Bld:Qn'
'Cells.CD4:NCnc:Pt:XXX:Qn'
'T-cell subsets CD4 & CD8 panel:-:Pt:Bld:-');
genlab_CD4test=1;
run; *574 tests*

*Print to figure out how to categorize*;
proc sql; create table test as
select PAT_KEY, ORDER_KEY, LAB_TEST_CODE, LAB_TEST_DESC, LAB_TEST_RESULT,
LAB_TEST_RESULT_UNIT, REFERENCE_INTERVAL, ABNORMAL_FLAG
from cr.genlab2; run;

*Basically we want any result where the result_unit isn't "null" or %
because we're looking for things like mm^3*;
proc freq data=cr.genlab2; tables LAB_TEST_RESULT_UNIT; run;
data cr.genlab3; set cr.genlab2;
where LAB_TEST_RESULT_UNIT not in ('%' '******' '******' 'Ratio' 'ZZ' 'null' 'ratio' 'x10E9/L' '% of Lymph');
run;

*Total number of hospitalizations with CD4 tests - 133*;
proc sql; select count (distinct pat_key) as pat_key from cr.genlab3; run;

*Turn results to numeric*;
data cr.genlab3; set cr.genlab3; CD4 = input(LAB_TEST_RESULT, 8.); run;

*129 of the 133 hospitalizations with CD4 tests had results available*;
proc sql; select count (distinct pat_key) as pat_key from cr.genlab3
where CD4 ne .; run; 

*Sort by pat_key and day to keep the first CD4 result per hospitalization*;
proc sort data=cr.genlab3; by PAT_KEY LAB_TEST_RESULT_DATETIME; run;
data cr.genlab4; set cr.genlab3; by PAT_KEY; if first.PAT_KEY; run;

*Merge CD4 flag to main dataset*;
proc sql;
create table cr.crypto4 as
select a.*, b.CD4
from cr.crypto3 as a left join cr.genlab4 as b
on a.pat_key=b.pat_key;
quit;

*Identify CSF profile tests*;
proc freq data=cr.genlab; tables LAB_TEST_DESC;
where SPECIMEN_SOURCE_DESC in ('Cerebrospinal fluid sample' 'Cerebrospinal fluid specimen');
run;

*Flag CSF profile tests*;
data cr.genlab5; set cr.genlab; 
where SPECIMEN_SOURCE_DESC in ('Cerebrospinal fluid sample' 'Cerebrospinal fluid specimen')
and LAB_TEST_DESC in: 
('Leukocytes:NCnc:Pt:CSF:Qn'
'Leukocytes:NCnc:Pt:CSF:Qn:Manual count'
'Glucose:MCnc:Pt:CSF:Qn'
'Protein:MCnc:Pt:CSF:Qn'
'Protein:PrThr:Pt:CSF:Ord');
CSF_test=1;
if LAB_TEST_DESC in: 
('Leukocytes:NCnc:Pt:CSF:Qn'
'Leukocytes:NCnc:Pt:CSF:Qn:Manual count') then CSF_test_WBC=1;
if LAB_TEST_DESC in: ('Glucose:MCnc:Pt:CSF:Qn') then CSF_test_glucose=1;
if LAB_TEST_DESC in: 
('Protein:MCnc:Pt:CSF:Qn'
'Protein:PrThr:Pt:CSF:Ord') then CSF_test_protein=1;
run; *1957 tests*

*Print to figure out how to categorize*;
proc sql; create table test as
select PAT_KEY, ORDER_KEY, LAB_TEST_CODE, LAB_TEST_DESC, LAB_TEST_RESULT,
LAB_TEST_RESULT_UNIT, REFERENCE_INTERVAL, ABNORMAL_FLAG
from cr.genlab5; run;

proc freq data=cr.genlab5; tables LAB_TEST_RESULT_UNIT; where CSF_test_WBC=1; run; 
proc freq data=cr.genlab5; tables LAB_TEST_RESULT_UNIT; where CSF_test_glucose=1; run;
proc freq data=cr.genlab5; tables LAB_TEST_RESULT_UNIT; where CSF_test_protein=1; run;

*For WBC, drop n=22 tests if the result unit is "null"
For glucose, all the units are mg/dl, so that's good
Jeremy said the units for protein are ok - the ones recorded as g/dL are probably errors and should be mg/dL*;
data cr.genlab6; set cr.genlab5;
if CSF_test_WBC=1 and LAB_TEST_RESULT_UNIT in ("null") then delete; 
run;

*Total number of hospitalizations with CSF tests - 357*;
proc sql; select count (distinct pat_key) as pat_key from cr.genlab6; run;

*Turn results to numeric*;
data cr.genlab6; set cr.genlab6;
LAB_TEST_RESULT2=input(LAB_TEST_RESULT, 8.);
if LAB_TEST_RESULT2=. then LAB_TEST_RESULT2=0;
if CSF_test_WBC=1 then CSF_test_WBC_value = LAB_TEST_RESULT2; 
if CSF_test_glucose=1 then CSF_test_glucose_value = LAB_TEST_RESULT2; 
if CSF_test_protein=1 then CSF_test_protein_value = LAB_TEST_RESULT2; 
run;

proc print data=cr.genlab6; var CSF_test_WBC CSF_test_glucose CSF_test_protein
LAB_TEST_RESULT CSF_test_WBC_value CSF_test_glucose_value CSF_test_protein_value;
run;

*Sort by pat_key and day to keep the first CSF test result of each type per hospitalization*;
data x; set cr.genlab6; where CSF_test_WBC=1; run;
proc sort data=x; by PAT_KEY LAB_TEST_RESULT_DATETIME; run;
data x2; set x; by PAT_KEY; if first.PAT_KEY; run;
data y; set cr.genlab6; where CSF_test_glucose=1; run;
proc sort data=y; by PAT_KEY LAB_TEST_RESULT_DATETIME; run;
data y2; set y; by PAT_KEY; if first.PAT_KEY; run;
data z; set cr.genlab6; where CSF_test_protein=1; run;
proc sort data=z; by PAT_KEY LAB_TEST_RESULT_DATETIME; run;
data z2; set z; by PAT_KEY; if first.PAT_KEY; run;

*Merge CSF test flags to main dataset*;
proc sql;
create table cr.crypto5 as
select a.*, b.CSF_test_WBC_value
from cr.crypto4 as a left join x2 as b
on a.pat_key=b.pat_key;
quit;
proc sql;
create table cr.crypto6 as
select a.*, b.CSF_test_glucose_value
from cr.crypto5 as a left join y2 as b
on a.pat_key=b.pat_key;
quit;
proc sql;
create table cr.crypto7 as
select a.*, b.CSF_test_protein_value
from cr.crypto6 as a left join z2 as b
on a.pat_key=b.pat_key;
quit;

****************************
****************************
CPT - NOT USING!! these codes are mostly for outpatient
****************************
****************************

*Bring in the lookup table for code descriptions*;
proc sql;
create table cr.cpt2 as
select a.*, b.cpt_desc
from cr.cpt as a left join LU.phd_lu_cptcode as b
on a.cpt_code=b.cpt_code;
quit;

*Check total number of hospitalizations - 985, so not everyone had CPT codes recorded*;
proc sql; select count (distinct pat_key) as pat_key from cr.cpt2; run; 

*Output frequency dataset to identify items of interest*;
proc freq data=cr.cpt2; tables cpt_desc /out=cpt2; run;

*Look for LP codes*;
data cr.cpt3; set cr.cpt2; 
CPT_LP=0;
if cpt_code in ('00635' '62270' '62328' '62329') then CPT_LP=1;
run;

proc sql; 
  create table cr.cpt4 as
  select pat_key, 
  	max(CPT_LP) as CPT_LP
  from cr.cpt3
  group by pat_key
  order by pat_key;
  quit;
  run;

 proc freq data=cr.cpt4; tables CPT_LP; run; *531 had any LP*;

/* Merge the CPT code data to the main dataset
proc sql;
create table cr.crypto4 as
select *
from cr.crypto3 as a left join cr.cpt4 as b
on a.pat_key=b.pat_key;
quit; */

*Thinking of not using CPT data because the billing and ICD procedure data are better. 
Only about 1/3 of the crypto meningitis patients have CPT data, which makes sense because
CPT are mostly outpatient anyway.;


****************************
****************************
CLEAN FINAL DATASET
****************************
****************************;
*Merge in the physician specialty lookup dataset to the main dataset*;
proc sql;
create table cr.crypto8 as
select *
from cr.crypto7 as a left join lu.phd_lu_physpec as b
on a.attphy_spec=b.phy_spec;
quit;

*Merge in genlab_flag*;
proc sql;
create table cr.crypto9 as
select *
from cr.crypto8 as a left join cr.genlab_flag as b
on a.pat_key=b.pat_key;
quit;

*Re-categorize and make new variables*;
data cr.crypto10; set cr.crypto9; 
length attphy_spec_c $25. race_eth $20. race_dich $20. disc_status_c $30. point_of_origin_c $30. category $15.;

year = year(admit_date); 

if disc_status in (20, 40, 41, 42) then died=1; else died=0;
if disc_status in (20, 40, 41, 42, 50, 51) then died2=1; else died2=0;

if disc_status in (20, 40, 41, 42)  then disc_status_c="Died";
else if disc_status in (1, 6, 21) then disc_status_c="Discharged home";
else if disc_status in (7) then disc_status_c="Left AMA";
else if disc_status in (50,51) then disc_status_c="Hospice";
else disc_status_c="Transferred to another HCF";

if disc_status_c in ("Died" "Hospice") then disc_status_c2="Died or hospice";
else disc_status_c2=disc_status_c;

if age in (0:17) then age_group=1;
if age in (18:34) then age_group=2;
if age in (35:44) then age_group=3;
if age in (45:54) then age_group=4;
if age in (55:64) then age_group=5;
if age ge 65 then age_group=6;

if gender='U' then gender='';
if race='U' then race='';
if race in ('A' 'B' 'O') then race_c='Non-white';
else if race = 'W' then race_c='White'; 
else race_c='';
if hispanic_ind='U' then hispanic_ind='';

if hispanic_ind = 'Y' then race_eth="Hispanic";
else if hispanic_ind = '' then race_eth="";
else if hispanic_ind = 'N' and race = "A" then race_eth ="Non-Hispanic Asian";
else if hispanic_ind = 'N' and race = "W" then race_eth ="Non-Hispanic White";
else if hispanic_ind = 'N' and race = "B" then race_eth ="Non-Hispanic Black";
else if hispanic_ind = 'N' and race = "O" then race_eth ="Non-Hispanic Other";
else race_eth = '';

if race_eth ="Non-Hispanic Asian" then race_eth2="Non-Hispanic Other";
else race_eth2=race_eth;

if race_eth = '' then race_dich='';
else if race_eth="Non-Hispanic Black" then race_dich="Non-Hispanic Black";
else race_dich = "Not Black";

if std_payor in (300, 310, 320) then std_payor_c='Medicare';
else if std_payor in (330, 340, 350) then std_payor_c='Medicaid';
else if std_payor in (360, 370, 380) then std_payor_c='Private';
else std_payor_c='Other';

if beds_grp in ('000-099' '100-199') then beds_grp_c='000-199';
if beds_grp in ('200-299' '300-399') then beds_grp_c='200-399';
if beds_grp in ('400-499' '500+') then beds_grp_c='400+';

if point_of_origin='1' then point_of_origin_c='Non-healthcare';
else if point_of_origin in ('8' '9') then point_of_origin_c='';
else point_of_origin_c='Healthcare';

LOS=discharge_date - admit_date;
days_to_ART=startday_med_ART-admit_date;
if days_to_ART=. then ART_at_admit=.;
else if days_to_ART le 1 then ART_at_admit=1; else ART_at_admit=0;

if bill_LP=1 or proc_LP=1 then any_LP=1; else any_LP=0;
if bill_EVD_VP=1 or proc_EVD_VP=1 or bill_lumbardrain=1 or proc_lumbardrain=1 or icd_CSFdrain=1
then any_CSFdrain=1; else any_CSFdrain=0;

if days_bill_LP=. then days_any_LP=days_proc_LP;
else days_any_LP=days_bill_LP; 
if days_any_LP=1 then only1LP=1; else only1LP=0;

if icd_HIV=1 then category='HIV';
else if icd_transplant=1 then category='Transplant';
else category='NHNT';

if days_med_AMB_any=. then days_med_AMB_any_cat='';
else if days_med_AMB_any in (0:7) then days_med_AMB_any_cat='7 days or less';
else if days_med_AMB_any in (8:13) then days_med_AMB_any_cat='8-13 days';
else if days_med_AMB_any in (14:27) then days_med_AMB_any_cat='14-27 days';
else if days_med_AMB_any in (28:41) then days_med_AMB_any_cat='28-41 days';
else if days_med_AMB_any ge 42 then days_med_AMB_any_cat='42+ days';

run;



****************************
****************************
LP ANALYSIS
****************************
****************************;

*INFORMATION FOR MANUSCRIPT TEXT/FOOTNOTES*;
*Print admission and discharge dates to identify study window*;
proc freq data=cr.crypto10; tables admit_date discharge_date; run;

*Cut to hospitalizations with at least 1 LP. Dataset gets cut from n=3193 to n=2263*;
data cr.lp; set cr.crypto10; where any_LP=1; run;
 
*Cut to patients' first hospitalization*;
proc sql; select count (distinct medrec_key) as medrec_key from cr.lp; run; *n=1850 patients*;
proc sort data=cr.lp; by medrec_key admit_date; run;
data cr.lp2; set cr.lp; by medrec_key admit_date; if first.medrec_key; run;

*Identify re-admissions within 30 days*;
*count hospitalizations per person*;
data x; set cr.lp;
by medrec_key admit_date;
if first.medrec_key then hosp_count=1;
else hosp_count+1;
run;
*get days between discharge date and subsequent admission date*;
data y; set x;
by medrec_key admit_date;
days_between_hosp = abs(intck('days',admit_date,lag(discharge_date)));
if first.medrec_key then call missing(days_between_hosp);
if days_between_hosp=. then days_between_hosp30=.;
else if days_between_hosp le 30 then days_between_hosp30=1; else days_between_hosp30=0;
run;
*check*;
proc print data=y; var medrec_key hosp_count admit_date 
discharge_date days_between_hosp days_between_hosp30; run;
*focus on the 2nd hospitalization per person*;
data z; set y; where hosp_count=2; 
keep medrec_key days_between_hosp days_between_hosp30;
run; 
*merge the re-admission info back to the dataset that contains patients' first hospitalization*;
proc sql;
create table cr.lp2 as
select *
from cr.lp2 as a left join z as b
on a.medrec_key=b.medrec_key;
quit;

*Total hospitals: 492*;
proc sql; select count (distinct prov_id) as prov_id from cr.lp2; run;

*Total hospitals with lab data available: 127*;
proc sql; select count (distinct prov_id) as prov_id from cr.lp2 where genlab_flag=1;  run;

*Identify n patients with both HIV and transplant (n=5), and remove them for Table 1*;
proc freq data=cr.lp2; tables icd_HIV*icd_transplant; run;
data cr.lp3; set cr.lp2; if icd_HIV=1 and icd_transplant=1 then delete; run; 




*********
*TABLE 1*
*********;
proc freq data=cr.lp3; tables
(age_group gender race_eth2 std_payor_c point_of_origin_c prov_region 
urban_rural beds_grp_c teaching 
icd_acutekidney icd_anemia icd_autoimmune icd_diabetes icd_hememalig 
icd_HIV icd_hypokalemia icd_hyponatremia icd_immunedz icd_liverdz icd_malnut
icd_neutropenia icd_overweight icd_seizure icd_sepsis icd_smoking icd_solidcancer icd_transplant 
only1LP any_CSFdrain genlab_flag
med_AMB_any med_ABLC med_LAMB med_AMB_unk med_fluc med_5FC
bill_ICU disc_status_c disc_status_c2 days_between_hosp30)*category/chisq;
run;
*Limit covid to after 10/1/2020*;
proc freq data=cr.lp3; tables icd_covid*category/chisq; where (year=2020 and quarter=4) or year in (2021,2022,2023); run; 

*continuous variables*;
proc means data=cr.lp3 n min median mean max p25 p75; 
var age los CSF_test_WBC_value CSF_test_glucose_value CSF_test_protein_value; run;
proc means data=cr.lp3 n min median mean max p25 p75; 
var age los CSF_test_WBC_value CSF_test_glucose_value CSF_test_protein_value; 
class category; run;

*CD4 count, among HIV*;
proc means data=cr.lp3 n min median mean max p25 p75;
var CD4; where icd_HIV=1 and genlab_flag=1; run;
*On ART at admission, among HIV*;
proc freq data=cr.lp3; tables ART_at_admit; where icd_HIV=1; run;

*Among those with no amphotericin B, what happened?*;
proc freq data=cr.lp3; tables disc_status_c med_fluc med_5FC; where med_AMB_any=0; run;
proc print data=cr.lp3; var disc_status_c med_fluc med_5FC; where med_AMB_any=0; run;
proc print data=cr.lp3; var disc_status_c med_fluc med_5FC; 
where med_AMB_any=0 and disc_status_c="Discharged home" and med_fluc=0 and med_5FC=0; run;


*********
*TABLE 2. use dataset lp2 to include the n=5 with both HIV and transplant*
********;
proc freq data=cr.lp2; tables
(age_group gender race_eth2 std_payor_c point_of_origin_c prov_region 
urban_rural beds_grp_c teaching 
icd_acutekidney icd_anemia icd_autoimmune icd_diabetes icd_hememalig 
icd_HIV icd_hypokalemia icd_hyponatremia icd_immunedz icd_liverdz icd_malnut
icd_neutropenia icd_overweight icd_seizure icd_sepsis icd_smoking icd_solidcancer icd_transplant 
any_CSFdrain genlab_flag
med_AMB_any med_ABLC med_LAMB med_AMB_unk med_fluc med_5FC
bill_ICU disc_status_c disc_status_c2)*only1LP/chisq;
run;
data cr.lp2; set cr.lp2; if days_between_hosp30=. then days_between_hosp30=0; run;
proc freq data=cr.lp2; tables (days_between_hosp30)*only1LP/chisq; run;

*Limit covid to after 10/1/2020*;
proc freq data=cr.lp2; tables icd_covid*only1LP/chisq; where (year=2020 and quarter=4) or year in (2021,2022,2023); run; 

*continuous variables*;
proc means data=cr.lp2 n min median mean max p25 p75; 
var age los CSF_test_WBC_value CSF_test_glucose_value CSF_test_protein_value; run;
proc means data=cr.lp2 n min median mean max p25 p75; 
var age los CSF_test_WBC_value CSF_test_glucose_value CSF_test_protein_value; 
class only1LP; run;
proc npar1way data=cr.lp2; 
var age los CSF_test_WBC_value CSF_test_glucose_value CSF_test_protein_value; 
class only1LP; run;
*CD4 count, among HIV*;
proc means data=cr.lp2 n min median mean max p25 p75;
var CD4; where icd_HIV=1 and genlab_flag=1; class only1LP; run;
proc npar1way data=cr.lp2;
var CD4; where icd_HIV=1 and genlab_flag=1; class only1LP; run;



*********
*Draft figure. KM curve comparing survival between patients who received 1 LP vs. >1 LP
********;
data cr.lp2; set cr.lp2; if disc_status_c2 = "Died or hospice" then died2=1; else died2=0;
run;

proc lifetest data=cr.lp2;
time los * died2(0);
strata only1LP;
run;
*But need to account for confounding...*;



******
For Jason. Dataset and variable names for adjusted survival analysis

dataset: cr.lp2
time variable: LOS (continuous length of hospital stay in days)
exposure: only1LP (dichotomous. 0=received more than 1 LP, 1=received only 1 LP)
outcome: died2 (dichotomous. 0=alive at hospital discharge, 1=died)
potential confounders (age is continuous, the rest are categorical):
	age
	race_eth2 
	std_payor_c 
	prov_region 
	urban_rural 
	beds_grp_c 
	icd_acutekidney 
	icd_anemia 
	icd_HIV
	icd_hypokalemia 
	icd_hyponatremia 
	icd_neutropenia 
	icd_overweight 
	icd_transplant
	any_CSFdrain 
	med_AMB_any 
	med_fluc 
	med_5FC
	 
note, instead of the separate variables icd_HIV and icd_transplant, could
consider the composite variable called "Category" instead




