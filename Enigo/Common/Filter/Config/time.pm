package Enigo::Common::Filter::Config::time;

sub filter {
  my $self = shift;
  my $code = shift;

  if ($code =~ m{\[!--date}) {
    $code = "use Date::Manip;\n$code";
  }

  if ($code =~ m{\[!--date\s+(.*?)--\]\s*(\S+)\s*\[!--date\s+(.*?)--\]}) {
    my $date1 = $1;
    my $op = $2;
    my $date2 = $3;
    my $expansion = <<ECODE;
&{sub{my \$d=ParseDate(q($date1));\$d=~s/://g;\$d}} $op
&{sub{my \$d=ParseDate(q($date2));\$d=~s/://g;\$d}}
ECODE
    $code =~ s{\[!--date.*?--\]\s*\S+\s*\[!--date.*?--\]}{$expansion}g;
  }

  return $code;
}

1;
