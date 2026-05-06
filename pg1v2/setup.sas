/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 WARNING: STUDENTS, DO NOT EXECUTE THIS PROGRAM! INSTEAD,
          EXIT AND EXECUTE THE CRE8DATA.SAS PROGRAM TO SETUP 
          YOUR COURSE DATA ENVIRONMENT.
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 WARNING: DO NOT ALTER CODE BELOW THIS LINE 
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

%macro UnPack(path,ZIPfile);
%local filecount;

filename zipfile zip "%superq(path)/%superq(ZIPfile)";
/* Read the "members" (files) from the ZIP file */
data contents(keep=memname isFolder);
   length memname $200 isFolder 8;
   fid=dopen("zipfile");
   if fid=0 then stop;
   memcount=dnum(fid);
   call symputx('filecount',memcount,'L');
   do i=1 to memcount;
      memname=dread(fid,i);
      call symputx(cats('file',i),memname,'L');
   end;
   rc=dclose(fid);
run;
/*%put _local_;*/
/*%return;*/

%do i=1 %to &filecount;
%if %qupcase(%qscan(%superq(file&i),-1)) = XLSX %then 
   %do; 
      filename xlout "%superq(path)/%superq(file&i)";
      data _null_;
         infile zipfile(%superq(file&i)) lrecl=256 recfm=F length=length eof=eof unbuf;
         file xlout lrecl=256 recfm=N;
         input;
         put _infile_ $varying256. length;
         return;
       eof:
         stop;
      run;

      filename xlout;
   %end;
   %else %do; 
      filename out "%superq(path)/%superq(file&i)";
      data _null_;
         infile zipfile(%superq(file&i));
         file out;
         input;
         put _infile_;
      run;
      filename out;
   %end;
%end;

filename zipfile;
%mend;

%macro setup(course,pgmname,zipfile,path);
%local fileref rc did didc;
%global rawdata;

%if %index(*OS*VM*,*%substr(&sysscp,1,2)*) %then
   %do;
      %put;
      %put ERROR: *********************************************************;
      %put ERROR- Only Windows, Linux and UNIX operating systems supported.;
      %put ERROR- *********************************************************;
      %put;
      %return;
   %end;

%let path=%superq(path);
/* Does the PATH location exist? */
%let rc=%sysfunc(filename(fileref,%superq(path)));
%let did=%sysfunc(dopen(&fileref));
%if &did=0 %then 
   %do;
      %put ERROR:  The specified location (%superq(path)) does not exist.;
      %put ERROR-  The location must be created and the contents of the course data;
      %put ERROR-  package made available there before you can run this program.;
      %return;
   %end;

%let path=%superq(path)/data;

%UnPack(&path,&zipfile)
%let rawdata=%superq(path)/data; 
/* Assign the libname */
libname &course "%superq(path)" 
%if &sysscp=WIN %then 
   %do;
      filelockwait=10
   %end;
   ;

/* Test the libref is properly assigned */
%let rc = %sysfunc(libref(&course));
%if &rc ne 0 %then 
   %do;
      %put ERROR:  The location you specified for PATH= is %superq(path).;
      %put ERROR-  Unable to assign a LIBREF to that location.;
      %put ERROR-  Terminating without creating your SAS data sets.;
      libname &course clear;
      %return;
   %end;

%include "&path/&pgmname" / encoding=wlatin1;

/*title "List of Tables for the %qupcase(%superq(course)) Course";*/
/*proc sql;*/
/*select memname 'Table', nlobs 'Number of Rows'*/
/*   from dictionary.tables*/
/*   where libname="%qupcase(%superq(course))"*/
/*;*/
/*quit;*/
proc contents data=%superq(course)._all_ nods;
run;
/*title "The SAS System";*/
%mend setup;

%setup(pg1,pg1v2.sas,pg1v2.zip,&path)

