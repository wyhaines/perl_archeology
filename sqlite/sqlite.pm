#!/usr/bin/perl -wc
#
######################################################################
##### Header
######################################################################

=pod

=head1 NAME

sqlite.pm - low level interface to sqlite API

=head1

I<REVISION: $Revision: 1.1.1.1 $>

I<AUTHOR: Kirk Haines>

I<DATE_MODIFIED: $Date: 2001/12/17 02:28:37 $>

=head1 SYNOPSIS

This package provides an interface into the sqlite API.  It
currently only supports a bare minimum of functionality.

Namely, the sqlite_open(), sqlite_close(), and sqlite_exec()
functions.  The others will be added over time.

Note that though this module can be used as is for dealing
with sqlite, the intent is that this module will serve to
power a DBD::Sqlite driver.  Note, also, that this software
is ALPHA.  It is developing, and it will change.  Guaranteed.

=head1 DESCRIPTION

=head1 EXAMPLES

=head1 TODO

Z<>

Z<>

Z<>

=cut

######################################################################
######################################################################

package sqlite;

($sqlite::VERSION) = ('$Revision: 1.1.1.1 $' =~ m{:\s+([\d\.]+)});

use Inline C =>
             Config =>
               LIBS => '-lsqlite -lgdbm',
           VERSION => '0.02',
           NAME => 'sqlite';

use Inline C => <<'EOC';

#include <sqlite.h>
#include <stdio.h>
#include <stdarg.h>

SV* the_exec_callback;
SV* the_busy_callback;

typedef struct {
  sqlite* sqlthing_ptr;
} SQLobj;

static int exec_callback(SV* info,int argc, char **argv, char **columnNames) {
  /* Much fun.  We need to construct on the Perl stack an argument list to
     pass back into the perl callback.  This argument list should contain:

     -- the info SV*
     -- an SV* containing the number of columns
     -- an AV* containing a list of SV*s with the column values
     -- an AV* containing a list of SV*s with the column names
  */
  AV* column_values;
  AV* column_names;
  int rv; 
  int count;
  dSP;

  ENTER;
  SAVETMPS;

  column_values = newAV();
  column_names = newAV();
  for(count = 0;count < argc;count++) {
    av_push(column_values, newSVpv(argv[count],0));
    av_push(column_names, newSVpv(columnNames[count],0));
  }

  PUSHMARK(SP);
  XPUSHs(info);
  XPUSHs(sv_2mortal(newSViv(argc)));
  XPUSHs(sv_2mortal(newRV_noinc((SV*) column_values))); 
  XPUSHs(sv_2mortal(newRV_noinc((SV*) column_names))); 

  PUTBACK;
  rv = perl_call_sv(the_exec_callback,G_SCALAR); 
  SPAGAIN;
  if (rv > 0) {
    rv = POPi;
  }
  PUTBACK;
  FREETMPS;
  LEAVE;

  return rv;
}


SV* open_db(SV* dbname,SV* mode) {
  sqlite* sqlthing;
  char* errmsg = 0;
  SV* sv_errmsg;
  SV* sqlobj_ref_sv;
  SV* sqlobj_blessed_sv;
  SQLobj* sqlobj = malloc(sizeof(SQLobj));

  sqlobj_ref_sv = newSViv(0);
  sqlobj_blessed_sv = newSVrv(sqlobj_ref_sv,"sqlite"); 
  sqlobj->sqlthing_ptr = sqlite_open(SvPV(dbname,PL_na),SvIV(mode),&errmsg);
  sv_setiv(sqlobj_blessed_sv,(IV)sqlobj);

  if (errmsg != 0) {
    sv_errmsg = newSVpv(errmsg,0);
    free(errmsg);
    return sv_errmsg;
  }

  return sqlobj_ref_sv;
}


void DESTROY (SV* obj) {
  SQLobj* sqlobj = (SQLobj*)SvIV(SvRV(obj));
  free(sqlobj->sqlthing_ptr);
  free(sqlobj);
}


void close_db(SV* sqlite_ptr) {
  sqlite* sqlthing;
  Inline_Stack_Vars;

  sqlthing = ((SQLobj*)SvIV(SvRV(sqlite_ptr)))->sqlthing_ptr;
  sqlite_close(sqlthing);
  Inline_Stack_Void;
}


SV* exec_sql(SV* sqlite_ptr,SV* sql,SV* code,SV* info) {
  sqlite* sqlthing;
  char* errmsg = 0;
  SV* sv_errmsg;
  AV* retval_array;
  int rv;

  the_exec_callback = code;
  sqlthing = ((SQLobj*)SvIV(SvRV(sqlite_ptr)))->sqlthing_ptr;
  rv = sqlite_exec(sqlthing,SvPV(sql,PL_na),exec_callback,info,&errmsg);

  retval_array = newAV();
  av_push(retval_array,newSViv(rv));

  if (errmsg != 0) {
    sv_errmsg = newSVpv(errmsg,0);
    free(errmsg);
  } else {
    sv_errmsg = newSVpv("",0); 
  }

  av_push(retval_array,sv_errmsg);
  return newRV_noinc((SV*) retval_array);
}


SV* get_table(SV* sqlite_ptr,SV* sql) {
  sqlite* sqlthing;
  AV* av_result;
  SV* sv_nrow;
  SV* sv_ncolumn;
  int nrow;
  int ncolumn;
  char** result;
  char* errmsg = 0;
  SV* sv_errmsg;
  AV* retval_array;
  int rv;
  int t;
  
  sqlthing = ((SQLobj*)SvIV(SvRV(sqlite_ptr)))->sqlthing_ptr; 
  rv = sqlite_get_table(sqlthing,SvPV(sql,PL_na),&result,&nrow,&ncolumn,&errmsg);

  retval_array = newAV();
  av_result = newAV();
  av_push(retval_array,newSViv(rv));

  for (t = 0;t < ((1 + nrow) * ncolumn);t++) {
    av_push(av_result,newSVpv(result[t],0));
  }
  sqlite_free_table(result);

  av_push(retval_array,newSViv(nrow));
  av_push(retval_array,newSViv(ncolumn));
  av_push(retval_array,newRV_noinc((SV*) av_result));
  if (errmsg != 0) {
    sv_errmsg = newSVpv(errmsg,0);
    free(errmsg);
  } else {
    sv_errmsg = newSVpv("",0); 
  }

  av_push(retval_array,sv_errmsg);

  return newRV_noinc((SV*) retval_array);
}


void interrupt(SV* sqlite_ptr) {
  sqlite* sqlthing;

  sqlthing = ((SQLobj*)SvIV(SvRV(sqlite_ptr)))->sqlthing_ptr;
  sqlite_interrupt(sqlthing);
}


int complete(SV* sql) {
  return sqlite_complete(SvPV(sql,PL_na));
}


SV* version() {
  return newSVpv(sqlite_version,0);
}


SV* encoding() {
  return newSVpv(sqlite_encoding,0);
}


void busy_timeout(SV* sqlite_ptr,int ma) {
  sqlite* sqlthing;

  sqlthing = ((SQLobj*)SvIV(SvRV(sqlite_ptr)))->sqlthing_ptr;
  sqlite_busy_timeout(sqlthing,ma);
}


static int busy_callback(SV* info,char* article,int count) {
  int rv;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(info); 
  XPUSHs(sv_2mortal(newSVpv(article,0))); 
  XPUSHs(sv_2mortal(newSViv(count)));

  PUTBACK;
  rv = perl_call_sv(the_busy_callback,G_SCALAR); 
  SPAGAIN;
  if (rv > 0) {
    rv = POPi;
  }
  PUTBACK;
  FREETMPS;
  LEAVE;

  return rv;
}


void busy_handler(SV* sqlite_ptr, SV* code, SV* info) {
  sqlite* sqlthing;

  sqlthing = ((SQLobj*)SvIV(SvRV(sqlite_ptr)))->sqlthing_ptr;
  the_busy_callback = code;
  sqlite_busy_handler(sqlthing,busy_callback,info);
}


EOC

=pod

=head1 NOTES

=head2 Changes

$Log: sqlite.pm,v $
Revision 1.1.1.1  2001/12/17 02:28:37  khaines
Hierarchy of custom Perl modules

Revision 1.4  2001/08/15 03:32:55  khaines
Added a list of changes, in POD form, at the end of the file.


=cut

1;

