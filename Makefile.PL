use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME          => 'User::Identity'
  , VERSION_FROM  => 'User/Identity.pm'
  , DIR           => [ 'User', 'Mail' ]
  , PREREQ_PM     =>
      { Geography::Countries => 1.4
      }
  , ABSTRACT      => 'Define a user'
  , AUTHOR        => 'Mark Overmeer <markov@cpan.org>'
);
