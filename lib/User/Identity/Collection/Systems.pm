#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package User::Identity::Collection::Systems;
use parent 'User::Identity::Collection';

use strict;
use warnings;

use Log::Report     'user-identity';

use User::Identity::System ();

#--------------------
=chapter NAME

User::Identity::Collection::Systems - a collection of system descriptions

=chapter SYNOPSIS

=chapter DESCRIPTION

This C<User::Identity::Collection::Systems> object maintains a set
User::Identity::System objects, each describing a login for the
user on some system.

=chapter METHODS

=c_method new [$name], %options
=default name      C<'systems'>
=default item_type User::Identity::System
=cut

sub new(@)
{	my $class = shift;
	$class->SUPER::new(systems => @_);
}

sub init($)
{	my ($self, $args) = @_;
	$args->{item_type} ||= 'User::Identity::System';
	$self->SUPER::init($args);
}

sub type() { 'network' }

1;
