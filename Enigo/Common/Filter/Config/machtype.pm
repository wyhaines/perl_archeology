package Enigo::Common::Filter::Config::machtype;

sub filter {
  my $self = shift;
  my $code = shift;

  if ($code =~ m{\[!--machtype--\]}i) {
    my $value = $ENV{MACHTYPE};
    my $expansion = "q($value)";
    $code =~ s{\[!--machtype--\]}{$expansion}ig;
  }

  return $code;
}

1;
