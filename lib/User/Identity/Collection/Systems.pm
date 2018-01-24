# This code is part of distribution User-Identity.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package User::Identity::Collection::Systems;
use base 'User::Identity::Collection';

use strict;
use warnings;

use User::Identity::System;

=chapter NAME

User::Identity::Collection::Systems - a collection of system descriptions

=chapter SYNOPSIS

=chapter DESCRIPTION

The M<User::Identity::Collection::Systems> object maintains a set
M<User::Identity::System> objects, each describing a login for the
user on some system.

=chapter METHODS

=c_method new [$name], %options

=default name      C<'systems'>
=default item_type M<User::Identity::System>

=cut

sub new(@)
{   my $class = shift;
    $class->SUPER::new(systems => @_);
}

sub init($)
{   my ($self, $args) = @_;
    $args->{item_type} ||= 'User::Identity::System';

    $self->SUPER::init($args);

    $self;
}

sub type() { 'network' }

1;

