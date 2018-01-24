# This code is part of distribution User-Identity.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package User::Identity::Collection::Users;
use base 'User::Identity::Collection';

use strict;
use warnings;

use User::Identity;

=chapter NAME

User::Identity::Collection::Users - a collection of users

=chapter SYNOPSIS

=chapter DESCRIPTION

The M<User::Identity::Collection::Users> object maintains a set
M<User::Identity> objects, each describing a user.

=chapter METHODS

=c_method new [$name], %options

=default name      C<'people'>
=default item_type M<User::Identity>

=cut

sub new(@)
{   my $class = shift;
    $class->SUPER::new(systems => @_);
}

sub init($)
{   my ($self, $args) = @_;
    $args->{item_type} ||= 'User::Identity';

    $self->SUPER::init($args);

    $self;
}

sub type() { 'people' }

1;

