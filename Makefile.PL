use 5.006;

use ExtUtils::MakeMaker;

#
# The following is needed, because User::Identity does gracefully handle
# a missing Geography::Countries, but is incompatible with older releases.
#

my %prereq;
my ($gc, $gc_version) = (Geography::Countries => 1.4);

eval "require $gc";

if($@ =~ m/^Can't locate/)
{   # Not installed, but it is optional...
}
elsif($@)
{   # Other error message
    warn "Found problems compiling $gc:\n$@";
    $prereq{$gc} = $gc_version;
}
elsif($gc->VERSION < $gc_version)
{   warn "$gc is too old (",$gc->VERSION,"), and needs to be reinstalled\n";
    $prereq{$gc} = $gc_version;
}

WriteMakefile
  ( NAME          => 'User::Identity'
  , VERSION_FROM  => 'lib/User/Identity.pm'
  , PREREQ_PM     => \%prereq
  , ABSTRACT      => 'Define a user'
  , AUTHOR        => 'Mark Overmeer <markov@cpan.org>'
);
