package User::Identity::Collection::Item;
use base 'User::Identity::Item';

use strict;
use warnings;

use User::Identity;
use Scalar::Util qw/weaken/;
use Carp         qw/carp croak/;

=chapter NAME

User::Identity::Collection::Item - base class for any collectable item

=chapter SYNOPSIS

=chapter DESCRIPTION

The C<User::Identity::Collection::Item> object is extended into objects which
contain data to be collected.

=chapter METHODS

=section Initiation

=c_method new [NAME], OPTIONS

=option  user OBJECT
=default user undef

Refers to the user (a User::Identity object) who has this item in one of
his/het collections.  The item may be unrelated to any user.

=error Each collectable item requires a name

You have to specify a name for each collected item.  These names need to be
unique within one collection.

=cut

sub init($)
{  my ($self, $args) = @_;

   if(my $user = delete $args->{user})
   {   $self->user($user);
   }

   $self->SUPER::init($args);
}

#-----------------------------------------

=section Attributes

=method user [USER]

The user whose address this is.  This is a weak link, which means that
the location object will be removed when the user object is deleted and
no other references to this location object exist.

=cut

sub user(;$)
{   my $self = shift;
    if(@_)
    {   my $user = $self->{UICI_user} = shift;
        weaken($self->{UICI_user}) if defined $user;
    }

    $self->{UICI_user};
}

#-----------------------------------------

1;

