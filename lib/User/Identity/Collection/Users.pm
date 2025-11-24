#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package User::Identity::Collection::Users;
use parent 'User::Identity::Collection';

use strict;
use warnings;

use Log::Report     'user-identity';

use User::Identity  ();

#--------------------
=chapter NAME

User::Identity::Collection::Users - a collection of users

=chapter SYNOPSIS

=chapter DESCRIPTION

The User::Identity::Collection::Users object maintains a set
User::Identity objects, each describing a user.

=chapter METHODS

=c_method new [$name], %options
=default name      C<'people'>
=default item_type User::Identity
=cut

sub new(@)
{	my $class = shift;
	$class->SUPER::new(systems => @_);
}

sub init($)
{	my ($self, $args) = @_;
	$args->{item_type} ||= 'User::Identity';
	$self->SUPER::init($args);
}

sub type() { 'people' }

1;
