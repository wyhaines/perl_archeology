package Enigo::Common::Filter::Config::env;

sub filter {
  my $self = shift;
  my $code = shift;

  if (my (@matches) = $code =~ m{\[!--env\s+(.*?)--\]}gi) {
    foreach my $match (@matches) {
      my $value = $ENV{$match};
      my $expansion = "q($value)";
      $code =~ s{\[!--env\s+$match--\]}{$expansion}i;
    }
  }

  return $code;
}

1;
