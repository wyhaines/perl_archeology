package Enigo::Common::Filter::Config::hostname;

sub filter {
  my $self = shift;
  my $code = shift;

  if ($code =~ m{\[!--hostname--\]}i) {
    open(HOSTNAME,"/bin/hostname|");
    my $hostname = <HOSTNAME>;
    chomp($hostname);
    close(HOSTNAME);
    my $expansion = "q($hostname)";
    $code =~ s{\[!--hostname--\]}{$expansion}ig;
  }

  return $code;
}

1;
