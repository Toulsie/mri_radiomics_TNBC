/* Adapted from "Sas macro/precision recall analysis.sas" (Toulsie/mri_radiomics_TNBC).
   The %existchk macro definition below is byte-identical to the repo's macro
   (it's a small validation helper the file's main %PRcurve macro calls
   internally before doing any precision-recall computation, to confirm a
   data set and its required variables exist). The repo ships this macro
   with no caller; the calls at the bottom are a small caller we wrote to
   exercise all three of its documented outcomes (data+vars found; a
   requested variable missing; the data set itself missing) against a
   synthetic dataset, not derived from any real patient data. */

%macro existchk(data=, var=, dmsg=e, vmsg=e);
   %global status; %let status=ok;
   %if &dmsg=e %then %let dmsg=ERROR;
   %else %if &dmsg=w %then %let dmsg=WARNING;
   %else %let dmsg=NOTE;
   %if &vmsg=e %then %let vmsg=ERROR;
   %else %if &vmsg=w %then %let vmsg=WARNING;
   %else %let vmsg=NOTE;
   %if %quote(&data) ne %then %do;
     %if %sysfunc(exist(&data)) ne 1 %then %do;
       %put &dmsg: Data set %upcase(&data) not found.;
       %let status=nodata;
     %end;
     %else %if &var ne %then %do;
       %let dsid=%sysfunc(open(&data));
       %if &dsid %then %do;
         %let i=1;
         %do %while (%scan(&var,&i) ne %str() );
            %let var&i=%scan(&var,&i);
            %if %sysfunc(varnum(&dsid,&&var&i))=0 %then %do;
              %put &vmsg: Variable %upcase(&&var&i) not found in data %upcase(&data).;
              %let status=novar;
            %end;
            %let i=%eval(&i+1);
         %end;
         %let rc=%sysfunc(close(&dsid));
       %end;
       %else %put ERROR: Could not open data set &data.;
     %end;
   %end;
   %else %do;
     %put &dmsg: Data set not specified.;
     %let status=nodata;
   %end;
%mend;

/* Synthetic mock data: a small binary classification problem (predicted
   score vs. binary outcome), shaped like the ROC/precision-recall inputs
   %PRcurve (the file's main macro, which calls %existchk internally)
   expects. Not derived from any real patient data. */
data mock_class;
  input score outcome;
  datalines;
0.12 0
0.85 1
0.34 0
0.67 1
0.22 0
0.91 1
0.45 0
0.78 1
;
run;

/* Case 1: data set and both variables exist -> status=ok */
%existchk(data=mock_class, var=score outcome)
%put NOTE: Case 1 status=&status;

/* Case 2: data set exists but the requested variable does not -> status=novar */
%existchk(data=mock_class, var=nonexistent_var, vmsg=w)
%put NOTE: Case 2 status=&status;

/* Case 3: data set itself does not exist -> status=nodata */
%existchk(data=doesnotexist)
%put NOTE: Case 3 status=&status;
