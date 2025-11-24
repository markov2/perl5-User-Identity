#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package User::Identity::Archive;
use parent 'User::Identity::Item';

use strict;
use warnings;

use Log::Report     'user-identity';

#--------------------
=chapter NAME

User::Identity::Archive - base class for archiving user information

=chapter SYNOPSIS

  use User::Identity::Archive::Plain;
  my $friends = User::Identity::Archive::Plain->new('friends');
  $friends->from(\*FH);
  $friends->from('.friends');

=chapter DESCRIPTION

An archive stores collections. It depends on the type of archive how and
where that is done.  Some archivers may limit the kinds of selections
which can be stored.

=chapter OVERLOADED

=chapter METHODS
=cut

sub type { "archive" }

=c_method new [$name], %options
=option  from $filehandle|$file
=default from undef
=cut

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	if(my $from = delete $args->{from})
	{	$self->from($from) or return;
	}

	$self;
}

#--------------------
=section Access to the archive

=method from $source, %options
Read definitions from the specified $source, which usually can be a
filehandle or filename.  The syntax used in the information $source
is archiver dependent.

Not all archivers implement C<from()>, so you may want to check with
C<UNIVERSAL::can()> beforehand.

=example

  use User::Identity::Archive::Some;
  my $a = User::Identity::Archive::Some->new('xyz');
  $a->from(\*STDIN) if $a->can('from');

=cut

1;
