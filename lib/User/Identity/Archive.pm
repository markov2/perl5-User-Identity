# This code is part of distribution User-Identity.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package User::Identity::Archive;
use base 'User::Identity::Item';

use strict;
use warnings;

=chapter NAME

User::Identity::Archive - base class for archiving user information

=chapter SYNOPSIS

 use User::Identity::Archive::Plain;
 my $friends = M<User::Identity::Archive::Plain>->new('friends');
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

=option  from FILEHANDLE|FILENAME
=default from C<undef>

=cut

sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args) or return;

    if(my $from = delete $args->{from})
    {   $self->from($from) or return;
    }

    $self;
}

#-----------------------------------------

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

