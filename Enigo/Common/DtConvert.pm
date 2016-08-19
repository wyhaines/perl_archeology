#!/usr/local/bin/perl -w 

package Enigo::Common::DtConvert;

use strict;

my %months = (
  JAN => "01",
  FEB => "02",
  MAR => "03",
  APR => "04",
  MAY => "05",
  JUN => "06",
  JUL => "07",
  AUG => "08",
  SEP => "09",
  OCT => "10",
  NOV => "11",
  DEC => "12"
);
#############################################################################
sub yyyymmdd
{
  my ($date) = $_[0];
  my ($day, $mon, $mm, $year);
  my $result = "";
  $date =~ s/^\s*//;
  $date =~ s/\s*$//;
  
  if( 
     (  ($day, $mon, $year) = $date =~ /^(\d\d)(\w\w\w)(\d{4})$/ )
     &&
     (  $mm = $months{uc($mon)} )
    ){   $result = $year . $mm . $day }
  unless( $result =~ /\d{8}/ ) { $result = "nonCon" }

  return $result;
}
#############################################################################
sub ddMonyyyy
{
  my ($date) = $_[0];
  my ($day, $mon, $mm, $year);
  my $result = "";
  $date =~ s/^\s*//;
  $date =~ s/\s*$//;
  my %mms = (
    "01" => "Jan",
    "02" => "Feb",
    "03" => "Mar",
    "04" => "Apr",
    "05" => "May",
    "06" => "Jun",
    "07" => "Jul",
    "08" => "Aug",
    "09" => "Sep",
    "10" => "Oct",
    "11" => "Nov",
    "12" => "Dec",
  );
  
  if( 
     (  ($year, $mm, $day) = $date =~ /^(\d{4})(\d\d)(\d\d)$/ )
     &&
     (  $mon = $mms{$mm} )
    ){   $result = $day . $mon . $year }
  unless( $result =~ /^(\d\d)(\w\w\w)(\d{4})$/ ) { $result = $date }

  return $result;

}
#############################################################################
return 1;
