package Enigo::Common::Filter::test::test;

sub filter {
  my $self = shift;
  my $code = shift;

  if ($code =~ /initialize\s*(.*?)\s*;/) {
    my $assignee = $1;
    $assignee =~ s/^\s*\(//;
    $assignee =~ s/\)\s*$//;
    my $expansion = <<ECODE;
my \$self = shift;
my ($assignee) = \@_;
ECODE
    $code =~ s/initialize\s*.*?\s*;/$expansion/g;
  }

  return $code;
}

1;
