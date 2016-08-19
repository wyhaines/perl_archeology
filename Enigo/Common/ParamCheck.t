#!/usr/bin/perl
#Version: $Revision: 1.1.1.1 $
#Date Modified: $Date: 2001/12/17 02:28:37 $

use strict;

use Enigo::TestTools qw(perl);

print "Testing Enigo::Common::ParamCheck\n\n";

runTests(<<'ETESTS');
use Enigo::Common::ParamCheck qw(paramCheck);
use Error qw(:try);

my $error_text;
try
  {
    my ($param) = paramCheck(123);
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() throws an exception if invoked without an expected params list.',
      !$error_text);
;;;;;
my $error_text;
try
  {
    my ($param) = paramCheck([A => 'quadracep'],123);
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() throws an exception if expected params list has incorrect syntax.',
      !$error_text);
;;;;;
my $param;
eval {
  ($param) = paramCheck([A => 'A'],'this is a test');
};

check('paramCheck() with a valid type A param returns as expected.',
      $param->{A} ne 'this is a test',
      $@);
;;;;;
my $error_text;
try
  {
    my ($param) = paramCheck([A => 'A'],123);
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() with an invalid type A param throws an exception.',
      !$error_text);
;;;;;
my $param;
eval {
  ($param) = paramCheck([AN => 'AN'],"this is test number\n2");
};

check('paramCheck() with a valid type AN param returns as expected.',
      $param->{AN} ne "this is test number\n2",
      $@);
;;;;;
my $error_text;
try
  {
    my ($param) = paramCheck([AN => 'AN'],'#123');
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() with an invalid type AN param throws an exception.',
      !$error_text);
;;;;;
my $param;
eval {
  ($param) = paramCheck([I => 'I'],123);
};

check('paramCheck() with a valid type I param returns as expected.',
      $param->{I} != 123,
      $@);
;;;;;
my $error_text;
try
  {
    my ($param) = paramCheck([I => 'I'],11.37);
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() with an invalid type I param throws an exception.',
      !$error_text);
;;;;;
my $param;
eval {
  ($param) = paramCheck([N => 'N'],11.37);
};

check('paramCheck() with a valid type N param returns as expected.',
      $param->{N} != 11.37,
      $@);
;;;;;
my $error_text;
try
  {
    my ($param) = paramCheck([N => 'N'],'abc');
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() with an invalid type N param throws an exception.',
      !$error_text);
;;;;;
my $var = 123;
my $ref_var = \$var;
my $param;
eval {
  ($param) = paramCheck([RR => 'RR'],\$ref_var);
};

check('paramCheck() with a valid type RR param returns as expected.',
      $param->{RR} ne \$ref_var,
      $@);
;;;;;
my $error_text;
try
  {
    my $var = 123;
    my $ref_var = \$var;
    my ($param) = paramCheck([RR => 'RR'],$ref_var);
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() with an invalid type RR param throws an exception.',
      !$error_text);
;;;;;
my $var = 123;
my $param;
eval {
  ($param) = paramCheck([SR => 'SR'],\$var);
};

check('paramCheck() with a valid type SR param returns as expected.',
      $param->{SR} ne \$var,
      $@);
;;;;;
my $error_text;
try
  {
    my $var = 123;
    my ($param) = paramCheck([SR => 'SR'],$var);
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() with an invalid type SR param throws an exception.',
      !$error_text);
;;;;;
my $var = [1,2,3];
my $param;
eval {
  ($param) = paramCheck([AR => 'AR'],$var);
};

check('paramCheck() with a valid type AR param returns as expected.',
      $param->{AR} ne $var,
      $@);
;;;;;
my $error_text;
try
  {
    my $var = {var => 123};
    my ($param) = paramCheck([AR => 'AR'],$var);
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() with an invalid type AR param throws an exception.',
      !$error_text);
;;;;;
my $var = {var => 123};
my $param;
eval {
  ($param) = paramCheck([HR => 'HR'],$var);
};

check('paramCheck() with a valid type HR param returns as expected.',
      $param->{HR} ne $var,
      $@);
;;;;;
my $error_text;
try
  {
    my $var = \*STDERR;
    my ($param) = paramCheck([HR => 'HR'],$var);
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() with an invalid type HR param throws an exception.',
      !$error_text);
;;;;;
my $var = \*STDERR;
my $param;
eval {
  ($param) = paramCheck([GR => 'GR'],$var);
};

check('paramCheck() with a valid type GR param returns as expected.',
      $param->{GR} ne $var,
      $@);
;;;;;
my $error_text;
try
  {
    my $var = sub {print "testing\n"};
    my ($param) = paramCheck([GR => 'GR'],$var);
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() with an invalid type GR param throws an exception.',
      !$error_text);
;;;;;
my $var = sub {print "testing\n"};
my $param;
eval {
  ($param) = paramCheck([CR => 'CR'],$var);
};

check('paramCheck() with a valid type CR param returns as expected.',
      $param->{CR} ne $var,
      $@);
;;;;;
my $error_text;
try
  {
    my ($param) = paramCheck([CR => 'CR'],123);
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() with an invalid type CR param throws an exception.',
      !$error_text);
;;;;;
my $var = sub {return 1};
my $param;
eval {
  ($param) = paramCheck([ECR => 'ECR'],$var);
};

check('paramCheck() with a valid type ECR param returns as expected.',
      $param->{ECR} ne &{$var},
      $@);
;;;;;
my $error_text;
try
  {
    my $var = sub {die};
    my ($param) = paramCheck([ECR => 'ECR'],$var);
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() with an invalid type ECR param throws an exception.',
      !$error_text);
;;;;;
my $var = [1,2,3];
my $param;
eval {
  ($param) = paramCheck([UR => 'UR'],\$var);
};

check('paramCheck() with a valid type UR param returns as expected.',
      $param->{UR} ne \$var,
      $@);
;;;;;
my $error_text;
try
  {
    my ($param) = paramCheck([UR=> 'UR'],"\nabc123u&me b4i4qru/18");
  }
catch Enigo::Common::Exception::ParamCheck with
  {
    $error_text = $_[0]->stringify();
  };
check('paramCheck() with an invalid type UR param throws an exception.',
      !$error_text);
;;;;;
my $param;
eval {
  ($param) = paramCheck([U => 'U'],{U => "\nabc123u&me b4i4qru/18"});
};

check('paramCheck() with a valid type U param returns as expected.',
      $param->{U} ne "\nabc123u&me b4i4qru/18",
      $@);
;;;;;
my $param;
eval {
  ($param) = paramCheck([CD => 'CD=/(?:car|truck)/i'],'truck');
};
check('paramCheck() with a valid CD validated param returns as expected.',
      $param->{CD} ne 'truck',
      $@);
;;;;;
my $param;
eval {
  ($param) = paramCheck([A => 'A',
                         I => 'I'],{A => 'abc',
                                    I => 123});
};

check('paramCheck() with valid params in a hashref works as expected.',
      (($param->{A} ne 'abc') or ($param->{I} != 123)),
      $@);
;;;;;
my $param;
eval {
  ($param) = paramCheck([A => 'A',
                            I => 'I'],'abc',
                                      123);
};

check('paramCheck() with valid params in a list works as expected.',
      (($param->{A} ne 'abc') or ($param->{I} != 123)),
      $@);
;;;;;
my $param;
eval {
  ($param) = paramCheck([A => 'A',
                         I => 'I',
                         I2 => 'IO'],{A => 'abc',
                                      I => 123,
                                      I2 => 456});
};

check('paramCheck() with an optional, present, param in a hashref works.',
      (($param->{A} ne 'abc') or
       ($param->{I} != 123) or
       ($param->{I2} != 456)),
      $@);
;;;;;
my $param;
eval {
  ($param) = paramCheck([A => 'A',
                         I => 'I',
                         I2 => 'IO'],'abc',
                                     123,
                                     456);
};

check('paramCheck() with an optional, present, param in a list works.',
      (($param->{A} ne 'abc') or
       ($param->{I} != 123) or
       ($param->{I2} != 456)),
      $@);
;;;;;
my $param;
eval {
  ($param) = paramCheck([A => 'A',
                         I => 'I',
                         I2 => 'IO'],{A => 'abc',
                                      I => 123});
};

check('paramCheck() with an optional, missing, param in a hashref works.',
      (($param->{A} ne 'abc') or
       ($param->{I} != 123) or
       defined $param->{I2}),
      $@);
;;;;;
my $param;
eval {
  ($param) = paramCheck([A => 'A',
                         I => 'I',
                         I2 => 'IO'],'abc',
                                     123);
};

check('paramCheck() with an optional, missing, param in a list works.',
      (($param->{A} ne 'abc') or
       ($param->{I} != 123) or
       defined $param->{I2}),
      $@);
;;;;;
my $param;
eval {
  ($param) = paramCheck([A => 'A',
                         I => 'IO',
                         A2 => 'A'],'abc',
                                    'def');
};
check('paramCheck() with an optional, missing, param between two required params in a list works as expected.',
      (($param->{A} ne 'abc') or
       ($param->{A2} ne 'def') or
       exists $param->{I}),
      $@);
;;;;;
my $param;
my @remainder;
eval {
  ($param,@remainder) = paramCheck([A => 'A',
                                    I => 'IO'],'abc',
                                               123,
                                               456,
                                               'def');
};

check('paramCheck() with left over list arguments is processed correctly.',
      (($param->{A} ne 'abc') or
       ($param->{I} != 123) or
       ($remainder[0] != 456) or
       ($remainder[1] ne 'def')),
       join("\n",$param->{A},
                 $param->{I},
                 @remainder));
;;;;;
my $param;
eval {
  ($param) = paramCheck([A => 'A',
                         B => 'A',
                         C => 'A',
                         D => 'A',
                         E => 'A',
                         F => 'A'],'a',
                                   {B => 'b',
                                    E => 'e'},
                                    'c',
                                    'd',
                                    'f');
};

check('paramCheck() deals with arguments passed via intermingled list arguments and hash refs (though only the sick and demented would pass parms this way).',
      (($param->{A} ne 'a') or
       ($param->{B} ne 'b') or
       ($param->{C} ne 'c') or
       ($param->{D} ne 'd') or
       ($param->{E} ne 'e') or
       ($param->{F} ne 'f')),
      join("\n","A $param->{A}",
                "B $param->{B}",
                "C $param->{C}",
                "D $param->{D}",
                "E $param->{E}",
                "F $param->{F}"));
;;;;;
my $param;
eval {
  ($param) = paramCheck([A => ['A','xyz'],
                         I => 'I',
                         AN => ['AN','4score']],{I => 123});
};

check('paramCheck() deals with ommitted params passed via a hash reference by utizing defined defaults for those params.',
      (($param->{A} ne 'xyz') or
       ($param->{I} != 123) or
       ($param->{AN} ne '4score')),
       join("\n",$param->{A},$param->{I},$param->{AN}));

ETESTS
