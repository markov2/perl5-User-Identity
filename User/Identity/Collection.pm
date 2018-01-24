package User::Identity::Collection;
use base 'User::Identity::Item';

use strict;
use warnings;

use User::Identity;
use Carp;
use Scalar::Util qw/weaken/;
use List::Util   qw/first/;

=head1 NAME

User::Identity::Collection - base class for collecting roles of a user

=head1 SYNOPSIS

 use User::Identity;
 use User::Identity::Collection;
 my $me    = User::Indentity->new(...);
 my $set   = User::Identity::Collection::Email->new(...);
 $me->addCollection($set);

 # Simpler
 use User::Identity;
 my $me    = User::Indentity->new(...);
 my $set   = $me->addCollection(type => 'email', ...)

 my @roles = $me->collection('email');  # list of collected items

 my $coll  = $me->collection('email');  # a User::Identity::Collection
 my @roles = $coll->roles;
 my @roles = @$coll;                    # same, by overloading

 my $role  = $me->collection('email')->find($coderef);
 my $role  = $me->collection('location')->find('work');
 my $role  = $me->find(location => 'work');
 
=head1 DESCRIPTION

The User::Identity::Collection object maintains a set user related objects.
It helps selecting these objects, which is partially common to all collections
(for instance, each object has a name so you can search on names), and sometimes
specific to the extension of this collection.

Currently imlemented extensions are

=over 4

=item * User::Identity::Collection::Locations

=item * User::Identity::Collection::Emails

=item * User::Identity::Collection::Systems

=back

=head1 METHODS

=head2 Initiation

=cut

#-----------------------------------------

=c_method new [NAME], OPTIONS

=option  user OBJECT
=default user undef

The user which has this collection of roles.

=option  item_type CLASS
=default item_type <required>

The CLASS which is used to store the information for each of the maintained
objects within this collection.

=option   roles    ROLE|ARRAY
=default  roles    undef

Immediately add some roles to this collection.  In case of an ARRAY, each
element of the array is passed separately to addRole(). So, you may end-up
with an ARRAY of arrays each grouping a set of options to create a role.

=cut

sub init($)
{   my ($self, $args) = @_;

    defined $args->{$_} && ($self->{'UIC_'.$_} = delete $args->{$_})
        foreach qw/
item_type
/;

   $self->SUPER::init($args);
   
   if(my $user = delete $args->{user})
   {   $self->user($user);
   }

   $self->{UIC_roles} = { };
   my $roles = $args->{roles};

   my @roles
    = ! defined $roles      ? ()
    : ref $roles eq 'ARRAY' ? @$roles
    :                         $roles;

   $self->addRole($_) foreach @roles;

   $self;
}

#-----------------------------------------

=head2 Overloading

=cut

#-----------------------------------------

=method stringification

Returns the name of the collection and a sorted list of defined items.

=examples

 print "$collection\n";  #   location: home, work

=cut

use overload '""' => sub {
   my $self = shift;
   $self->name . ": " . join(", ", sort map {$_->name} $self->roles);
};

#-----------------------------------------

=method @{}

When the reference to a collection object is used as array-reference, it
will be shown as list of roles.

=examples

 my $locations = $ui->collection('location');
 foreach my $loc (@$location) ...
 print $location->[0];

=cut

use overload '@{}' => sub { [ shift->roles ] };

#-----------------------------------------

=head2 Attributes

=cut

#-----------------------------------------

=method roles

Returns all defined roles within this collection.

=cut

sub roles() { values %{shift->{UIC_roles}} }

#-----------------------------------------

=method addRole ROLE| ( [NAME],OPTIONS ) | ARRAY-OF-OPTIONS

Adds a new role to this collection.  ROLE is an object of the right type
(depends on the extension of this module which type that is) or a list
of OPTIONS which are used to create such role.  The options can also be
passed as reference to an array.  The added role is returned.

=examples

 my $uicl = User::Identity::Collection::Locations->new;

 my $uil  = User::Identity::Location->new(home => ...);
 $uicl->addRole($uil);

 $uicl->addRole( home => address => 'street 32' );
 $uicl->addRole( [home => address => 'street 32'] );

Easier

 $ui      = User::Identity;
 $ui->add(location => 'home', address => 'street 32' );
 $ui->add(location => [ 'home', address => 'street 32' ] );

=error Wrong type of role for $collection: requires a $expect but got a $type

Each $collection groups sets of roles of one specific type ($expect).  You
cannot add objects of a different $type.

=error Cannot create a $type to add this to my collection.

Some options are specified to create a $type object, which is native to
this collection.  However, for some reason this failed.

=cut

sub addRole(@)
{   my $self = shift;

    my $role;
    my $maintains = $self->{UIC_item_type};
    if(ref $_[0] && ref $_[0] ne 'ARRAY')
    {   $role = shift;
        croak "ERROR: Wrong type of role for ".ref($self)
            . ": requires a $maintains but got a ". ref($role)
           unless $role->isa($maintains);
    }
    else
    {   $role = $maintains->new(ref $_[0] ? @{$_[0]} :  @_);
        croak "ERROR: Cannot create a $maintains to add this to my collection."
            unless defined $role;
    }

    $role->user($self->user);
    $self->{UIC_roles}{$role->name} = $role;
    $role;
}

#-----------------------------------------

=method user [USER]

The user whose address this is.  This is a weak link, which means that
the location object will be removed when the user object is deleted and
no other references to this location object exist.

=cut

sub user(;$)
{   my $self = shift;

    if(@_)
    {   my $user = shift;
        $self->{UIC_user} = $user;

        weaken($self->{UIC_user}) if defined $user;
        $_->user($user) foreach $self->roles;
    }

    $self->{UIC_user};
}

#-----------------------------------------

=head2 Searching

=cut

#-----------------------------------------

=method find NAME|CODE|undef

Find the object with the specified NAME in this collection.  With C<undef>,
a randomly selected role is returned.

When a code reference is specified, all collected roles are scanned one
after the other (in unknown order).  For each role,

 CODE->($object, $collection)

is called.  When the CODE returns true, the role is selected.  In list context,
all selected roles are returned.  In scalar context, the first match is
returned and the scan is aborted immediately.

=examples

 my $emails = $ui->collection('emails');
 $emails->find('work');

 sub find_work($$) {
    my ($mail, $emails) = @_;
    $mail->location->name eq 'work';
 }
 my @at_work = $emails->find(\&find_work);
 my @at_work = $ui->find(location => \&find_work);
 my $any     = $ui->find(location => undef );

=cut

sub find($)
{   my ($self, $select) = @_;

      !defined $select ? ($self->roles)[0]
    : !ref $select     ? $self->{UIC_roles}{$select}
    : wantarray        ? grep ({ $select->($_, $self) } $self->roles)
    :                    first { $select->($_, $self) } $self->roles;
}

#-----------------------------------------

1;

