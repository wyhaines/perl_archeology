package Enigo::Common::Filter::Config::ostype;

sub filter {
  my $self = shift;
  my $code = shift;

  if ($code =~ m{\[!--ostype--\]}i) {
    my $value = $ENV{OSTYPE};
    my $expansion = "q($value)";
    $code =~ s{\[!--ostype--\]}{$expansion}ig;
  }

  return $code;
}

1;
