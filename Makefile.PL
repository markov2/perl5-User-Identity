use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME          => 'User::Identity'
  , VERSION_FROM  => 'lib/User/Identity.pm'
  , PREREQ_PM     =>
      { Geography::Countries => 1.4
      }
  , ABSTRACT      => 'Define a user'
  , AUTHOR        => 'Mark Overmeer <markov@cpan.org>'
);
