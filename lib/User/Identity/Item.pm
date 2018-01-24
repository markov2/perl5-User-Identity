# This code is part of distribution User-Identity.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package User::Identity::Item;

use strict;
use warnings;

use Scalar::Util qw/weaken/;
use Carp;

=chapter NAME

User::Identity::Item - general base class for User::Identity

=chapter SYNOPSIS

=chapter DESCRIPTION

The C<User::Identity::Item> base class is extended into useful modules: it
has no use by its own.

=chapter METHODS

=section Constructors

=c_method new [$name], %options

=requires name STRING
A simple name for this item.  Try to give a useful name in the context of
the item time.  Each time when you lookup items, you need to specify
this name, so it should be unique and not to hard to handle in your program.
For instance, when a person is addressed, you usually will give him/her
this a nickname.

=option  description STRING
=default description undef
Free format description on the collected item.

=option  parent OBJECT
=default parent C<undef>
The encapsulating object: the object which collects this one.

=warning Unknown option $name for a $class

One used option is not defined.  Check the manual page of the class to
see which options are accepted.

=warning Unknown options @names for a $class

More than one option is not defined.

=error Each item requires a name
You have to specify a name for each item.  These names need to be
unique within one collection, but feel free to give the same name
to an e-mail address and a location.

=cut

sub new(@)
{   my $class = shift;
    return undef unless @_;       # no empty users.

    unshift @_, 'name' if @_ %2;  # odd-length list: starts with nick

    my %args = @_;
    my $self = (bless {}, $class)->init(\%args);

    if(my @missing = keys %args)
    {   local $" = '", "';
        warn "WARNING: Unknown ".(@missing==1? 'option' : 'options' )
           . " \"@missing\" for a $class\n";
    }

    $self;
}

sub init($)
{   my ($self, $args) = @_;

    unless(defined($self->{UII_name} = delete $args->{name}))
    {   croak "ERROR: Each item requires a name";
    }

    $self->{UII_description} = delete $args->{description};
    $self;
}

#-----------------------------------------

=section Attributes

=method name [$newname]

The name of this item.  Names are unique within a collection... a second
object with the same name within any collection will destroy the already
existing object with that name.

Changing the name of an item is quite dangerous.  You probably want to
call M<User::Identity::Collection::renameRole()> instead.
=cut

sub name(;$)
{   my $self = shift;
    @_ ? ($self->{UII_name} = shift) : $self->{UII_name};
}

#-----------------------------------------

=method description 

Free format description on this item.  Please do not add
any significance to the content of this field: if you are in need
for an extra attribute, please contact the author of the module to
implement it, or extend the object to suit your needs.

=cut

sub description() {shift->{UII_description}}

#-----------------------------------------

=section Collections

=method addCollection $object | <[$type], %options>

Add a new collection of roles to an item.  This can be achieved in two ways:
either create an M<User::Identity::Collection> $object yourself and then
pass that to this method, or supply all the %options needed to create such
an object and it will be created for you.  The object which is added is
returned, and can be used for many methods directly.

For %options, see the specific type of collection.  Additional options are
listed below.

=requires type STRING|CLASS

The nickname of a collection class or the CLASS name itself of the
object to be created.  Required if an object has to be created.
Predefined type nicknames are C<email>, C<system>, and C<location>.

=examples

 my $me   = User::Identity->new(...);
 my $locs = User::Identity::Collection::Locations->new();
 $me->addCollection($locs);

 my $email = $me->addCollection(type => 'email');
 my $email = $me->addCollection('email');

=error $object is not a collection.

The first argument is an object, but not of a class which extends
M<User::Identity::Collection>.

=error Don't know what type of collection you want to add.

If you add a collection, it must either by a collection object or a
list of options which can be used to create a collection object.  In
the latter case, the type of collection must be specified.

=error Cannot load collection module for $type ($class).

Either the specified $type does not exist, or that module named $class returns
compilation errors.  If the type as specified in the warning is not
the name of a package, you specified a nickname which was not defined.
Maybe you forgot the 'require' the package which defines the nickname.

=error Creation of a collection via $class failed.

The $class did compile, but it was not possible to create an object
of that class using the options you specified.

=cut

our %collectors =
 ( emails      => 'User::Identity::Collection::Emails'
 , locations   => 'User::Identity::Collection::Locations'
 , systems     => 'User::Identity::Collection::Systems'
 , users       => 'User::Identity::Collection::Users'
 );  # *s is tried as well, so email, system, and location will work

sub addCollection(@)
{   my $self = shift;
    return unless @_;

    my $object;
    if(ref $_[0])
    {   $object = shift;
        croak "ERROR: $object is not a collection"
           unless $object->isa('User::Identity::Collection');
    }
    else
    {   unshift @_, 'type' if @_ % 2;
        my %args  = @_;
        my $type  = delete $args{type};

        croak "ERROR: Don't know what type of collection you want to add"
           unless $type;

        my $class = $collectors{$type} || $collectors{$type.'s'} || $type;
        eval "require $class";
        croak "ERROR: Cannot load collection module $type ($class); $@\n"
           if $@;

        $object = $class->new(%args);
        croak "ERROR: Creation of a collection via $class failed\n"
           unless defined $object;
    }

    $object->parent($self);
    $self->{UI_col}{$object->name} = $object;
}


=method removeCollection $object|$name
=cut

sub removeCollection($)
{   my $self = shift;
    my $name = ref $_[0] ? $_[0]->name : $_[0];

       delete $self->{UI_col}{$name}
    || delete $self->{UI_col}{$name.'s'};
}


=method collection $name

In scalar context the collection object with the $name is returned.
In list context, all the roles within the collection are returned.

=examples

 my @roles = $me->collection('email');        # list of collected items
 my @roles = $me->collection('email')->roles; # same of collected items
 my $coll  = $me->collection('email');        # a User::Identity::Collection

=cut

sub collection($;$)
{   my $self       = shift;
    my $collname   = shift;
    my $collection
      = $self->{UI_col}{$collname} || $self->{UI_col}{$collname.'s'} || return;

    wantarray ? $collection->roles : $collection;
}


=method add $collection, $role

The $role is added to the $collection.  The $collection is the name of a
collection, which will be created automatically with M<addCollection()> if
needed.  The $collection can also be specified as existing collection object.

The $role is anything what is acceptable to
M<User::Identity::Collection::addRole()> of the
collection at hand, and is returned.  $role typically is a list of
parameters for one role, or a reference to an array containing these
values.

=examples

 my $ui   = User::Identity->new(...);
 my $home = $ui->add(location => [home => street => '27 Roadstreet', ...] );
 my $work = $ui->add(location => work, tel => '+31-2231-342-13', ... );

 my $travel = User::Identity::Location->new(travel => ...);
 $ui->add(location => $travel);

 my $system = User::Identity::Collection::System->new(...);
 $ui->add($system => 'localhost');

=warning No collection $name
The collection with $name does not exist and can not be created.

=cut

sub add($$)
{   my ($self, $collname) = (shift, shift);
    my $collection
     = ref $collname && $collname->isa('User::Identity::Collection')
     ? $collname
     : ($self->collection($collname) || $self->addCollection($collname));

    unless($collection)
    {   carp "No collection $collname";
        return;
    }

    $collection->addRole(@_);
}

=ci_method type 
Returns a nice symbolic name for the type.

=cut

sub type { "item" }

=method parent [$parent]
Returns the parent of an Item (the enclosing item).  This may return C<undef>
if the object is stand-alone.

=cut

sub parent(;$)
{   my $self = shift;
    return $self->{UII_parent} unless @_;

    $self->{UII_parent} = shift;
    weaken($self->{UII_parent});
    $self->{UII_parent};
}

=method user 
Go from this object to its parent, to its parent, and so on, until a
M<User::Identity> is found or the top of the object tree has been
reached.

=example
 print $email->user->fullName;

=cut

sub user()
{   my $self   = shift;
    my $parent = $self->parent;
    defined $parent ? $parent->user : undef;
}

#-----------------------------------------

=section Searching

=method find $collection, $role

Returns the object with the specified $role within the named collection.
The collection can be specified as name or object.

=examples

 my $role  = $me->find(location => 'work');       # one location
 my $role  = $me->collection('location')->find('work'); # same

 my $email = $me->addCollection('email');
 $me->find($email => 'work');
 $email->find('work');   # same

=cut

sub find($$)
{   my $all        = shift->{UI_col};
    my $collname   = shift;
    my $collection
     = ref $collname && $collname->isa('User::Identity::Collection') ? $collname
     : ($all->{$collname} || $all->{$collname.'s'});

    defined $collection ? $collection->find(shift) : ();
}

1;

