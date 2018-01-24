package User::Identity;
use base 'User::Identity::Item';

use strict;
use warnings;
use Carp;

=head1 NAME

User::Identity - maintains info about a physical person

=head1 SYNOPSIS

 use User::Identity;
 my $me = User::Indentity->new
  ( 'john'
  , firstname => 'John'
  , surname   => 'Doe'
  );
 print $me->fullName  # prints "John Doe"
 print $me;           # same

=head1 DESCRIPTION

The User::Identity object is created to maintain a set of informational
objects which are related to one user.  The User::Identity module try to
be smart providing defaults, conversions and often required combinations.

The identities are not implementing any kind of storage, and can therefore
be created by any simple or complex Perl program.  This way, it is more
flexible than an XML file to store the data.  For instance, you can decide
to store the data with Data::Dumper, Storable, DBI, Mail::AddressBook
or whatever.  Extension to simplify this task are still to be developed.

If you need more kinds of user information, then please contact the
module author.

=head1 METHODS

=cut

#-----------------------------------------

=head2 Initiation

=cut

#-----------------------------------------

=c_method new [NAME], OPTIONS

Create a new user identity, which will contain all data related 
to a single physical human being.  Most user data can only be
specified at object construction, because they should never
change.  A NAME may be specified as first argument, but also
as option, one way or the other is required..

=option  charset STRING
=default charset $ENV{LC_CTYPE}

=option  courtesy STRING
=default courtesy undef

=option  date_of_birth DATE
=default date_of_birth undef

=option  firstname STRING
=default firstname undef

=option  full_name STRING
=default full_name undef
 
=option  formal_name STRING
=default formal_name undef

=option  initials STRING
=default initials undef

=option  nickname STRING
=default nickname undef

=option  gender STRING
=default gender undef

=option  language STRING
=default language 'en'

=option  prefix STRING
=default prefix undef

=option  surname STRING
=default surname undef

=option  titles STRING
=default titles undef

=cut

my @attributes = qw/charset courtesy date_of_birth full_name formal_name
firstname gender initials language nickname prefix surname titles /;

sub init($)
{   my ($self, $args) = @_;

    defined $args->{$_} && ($self->{'UI_'.$_} = delete $args->{$_})
        foreach @attributes;

   $self->SUPER::init($args);
}

#-----------------------------------------

=head2 Overloading

=cut

#-----------------------------------------

=method stringification

When an User::Identity is used as string, it is automatically
translated into the fullName() of the user involved.

=examples

 my $me = User::Identity->new(...)
 print $me;          # same as  print $me->fullName
 print "I am $me\n"; # also stringification

=cut

use overload '""' => 'fullName';

#-----------------------------------------

=head2 Attributes

=cut

#-----------------------------------------

=method charset

The user's prefered character set, which defaults to the value of
LC_CTYPE environment variable.

=cut

sub charset() { shift->{UI_charset} || $ENV{LC_CTYPE} }

#-----------------------------------------

=method nickname

Returns the user's nickname, which could be used as username, e-mail
alias, or such.  When no nickname was explicitly specified, the name is
used.

=cut

sub nickname()
{   my $self = shift;
    $self->{UI_nickname} || $self->name;
    # TBI: If OS-specific info exists, then username
}

#-----------------------------------------

=method firstname

Returns the first name of the user.  If it is not defined explicitly, it
is derived from the nickname, and than capitalized if needed.

=cut

sub firstname()
{   my $self = shift;
    $self->{UI_firstname} || ucfirst $self->nickname;
}

#-----------------------------------------

=method initials

The initials, which may be derived from the first letters of the
firstname.

=cut

sub initials()
{   my $self = shift;
    return $self->{UI_initials}
        if defined $self->{UI_initials};

    if(my $firstname = $self->firstname)
    {   my $i = '';
        while( $firstname =~ m/(\w+)(\-)?/g )
        {   my ($part, $connect) = ($1,$2);
            $connect ||= '.';
            $part =~ m/^(chr|th|\w)/i;
            $i .= ucfirst(lc $1).$connect;
        }
        return $i;
    }
}

#-----------------------------------------

=method prefix

The words which are between the firstname (or initials) and the surname.

=cut

sub prefix() { shift->{UI_prefix} }

#-----------------------------------------

=method surname

Returns the surname of person, or C<undef> if that is not known.

=cut

sub surname() { shift->{UI_surname} }

#-----------------------------------------

=method fullName

If this is not specified as value during object construction, it is
guessed based on other known values like "firstname prefix surname". 
If a surname is provided without firstname, the nickname is taken
as firstname.  When a firstname is provided without surname, the
nickname is taken as surname.  If both are not provided, then
the nickname is used as fullname.

=cut

sub fullName()
{   my $self = shift;

    return $self->{UI_full_name}
       if defined $self->{UI_full_name};

    my ($first, $prefix, $surname)
       = @$self{ qw/UI_firstname UI_prefix UI_surname/};

    $surname = ucfirst $self->nickname if  defined $first && ! defined $surname;
    $first   = $self->firstname        if !defined $first &&   defined $surname;
    
    my $full = join ' ', grep {defined $_} ($first,$prefix,$surname);

    $full = $self->firstname unless length $full;

    # TBI: if OS-specific knowledge, then unix GCOS?

    $full;
}

#-----------------------------------------

=method formalName

Returns a formal name for the user.  If not defined as instantiation
parameter (see new()), it is constructed from other available information,
which may result in an incorrect or an incomplete name.  The result is
built from "courtesy initials prefix surname title".

=cut

sub formalName()
{   my $self = shift;
    return $self->{UI_formal_name}
       if defined $self->{UI_formal_name};

    my $initials = $self->initials;

    my $firstname = $self->{UI_firstname};
    $firstname = "($firstname)" if defined $firstname;

    my $full = join ' ', grep {defined $_}
       $self->courtesy, $initials
       , @$self{ qw/UI_prefix UI_surname UI_titles/ };
}

#-----------------------------------------

=method courtesy

The courtesy is used to address people in a very formal way.  Values
are like "Mr.", "Mrs.", "Sir", "Frau", "Heer", "de heer", "mevrouw".
This often provides a way to find the gender of someone addressed.

=cut

my %male_courtesy
 = ( mister    => 'en'
   , mr        => 'en'
   , sir       => 'en'
   , 'de heer' => 'nl'
   , mijnheer  => 'nl'
   , dhr       => 'nl'
   , herr      => 'de'
   );

my %male_courtesy_default
 = ( en        => 'Mr.'
   , nl        => 'De heer'
   , de        => 'Herr'
   );

my %female_courtesy
 = ( miss      => 'en'
   , ms        => 'en'
   , mrs       => 'en'
   , madam     => 'en'
   , mevr      => 'nl'
   , mevrouw   => 'nl'
   , frau      => 'de'
   );

my %female_courtesy_default
 = ( en        => 'Madam'
   , nl        => 'Mevrouw'
   , de        => 'Frau'
   );

sub courtesy()
{   my $self = shift;

    return $self->{UI_courtesy}
       if defined $self->{UI_courtesy};

    my $table
      = $self->isMale   ? \%male_courtesy_default
      : $self->isFemale ? \%female_courtesy_default
      : return undef;

    my $lang = lc $self->language;
    return $table->{$lang} if exists $table->{$lang};

    $lang =~ s/\..*//;     # "en_GB.utf8" --> "en-GB"  and retry
    return $table->{$lang} if exists $table->{$lang};

    $lang =~ s/[-_].*//;   # "en_GB.utf8" --> "en"  and retry
    $table->{$lang};
}

#-----------------------------------------

=method language

Can contain a list or a single language name, as defined by the RFC
Examples are 'en', 'en-GB', 'nl-BE'.  The default language  is 'en'
(English).

=cut

# TBI: if we have a courtesy, we may detect the language.
# TBI: when we have a postal address, we may derive the language from
#      the country.
# TBI: if we have an e-mail addres, we may derive the language from
#      that.

sub language() { shift->{UI_language} || 'en' }

#-----------------------------------------

=method gender

Returns the specified gender of the person, as specified during
instantiation, which could be like 'Male', 'm', 'homme', 'man'.
There is no smart behavior on this: the exact specified value is
returned. Methods isMale(), isFemale(), and courtesy() are smart.

=cut

sub gender() { shift->{UI_gender} }

#-----------------------------------------

=method isMale

Returns true if we are sure that the user is male.  This is specified as
gender at instantiation, or derived from the courtesy value.  Methods
isMale and isFemale are not complementatory: they can both return false
for the same user, in which case the gender is undertermined.

=cut

sub isMale()
{   my $self = shift;

    if(my $gender = $self->{UI_gender})
    {   return $gender =~ m/^[mh]/i;
    }

    if(my $courtesy = $self->{UI_courtesy})
    {   $courtesy = lc $courtesy;
        $courtesy =~ s/[^\s\w]//g;
        return 1 if exists $male_courtesy{$courtesy};
    }

    undef;
}

#-----------------------------------------

=method isFemale

See isMale(): return true if we are sure the user is a woman.

=cut

sub isFemale()
{   my $self = shift;

    if(my $gender = $self->{UI_gender})
    {   return $gender =~ m/^[vf]/i;
    }

    if(my $courtesy = $self->{UI_courtesy})
    {   $courtesy = lc $courtesy;
        $courtesy =~ s/[^\s\w]//g;
        return 1 if exists $female_courtesy{$courtesy};
    }

    undef;
}

#-----------------------------------------

=method dateOfBirth

Returns the date of birth, as specified during instantiation.

=cut

sub dateOfBirth() { shift->{UI_date_of_birth} }

#-----------------------------------------

=method birth

Returns the date in standardized format: YYYYMMDD, easy to sort and
select.  This may return C<undef>, even if the dateOfBirth() contains
a value, simply because the format is not understood. Month or day may
contain '00' to indicate that those values are not known.

=cut

sub birth()
{   my $birth = shift->dateOfBirth;
    my $time;

    if($birth =~ m/^\s*(\d{4})[-\s]*(\d{2})[-\s]*(\d{2})\s*$/)
    {   # Pre-formatted.
        return sprintf "%04d%02d%02d", $1, $2, $3;
    }

    eval "require Date::Parse";
    unless($@)
    {   my ($day,$month,$year) = (Date::Parse::strptime($birth))[3,4,5];
        if(defined $year)
        {   return sprintf "%04d%02d%02d"
              , ($year + 1900)
              , (defined $month ? $month+1 : 0)
              , ($day || 0);
        }
    }

    # TBI: Other date parsers

    undef;
}

#-----------------------------------------

=method age

Calcuted from the datge of birth to the current moment, as integer.  On the
birthday, the number is incremented already.

=cut

sub age()
{   my $birth = shift->birth or return;

    my ($year, $month, $day) = $birth =~ m/^(\d{4})(\d\d)(\d\d)$/;
    my ($today, $tomonth, $toyear) = (localtime)[3,4,5];
    $tomonth++;

    my $age = $toyear+1900 - $year;
    $age-- if $month > $tomonth || ($month == $tomonth && $day >= $today);
    $age;
}

#-----------------------------------------

=method titles

The titles, degrees in education or of other kind.  If these are complex,
you may need to specify the formal name of the users as well, because
smart formatting probably failes.

=cut

sub titles() { shift->{UI_titles} }

#-----------------------------------------

=head2 Collections

=cut

#-----------------------------------------

=method addCollection OBJECT | ([TYPE], OPTIONS)

Add a new collection of roles to the user.  This can be achieved in two ways:
either create an User::Identity::Collection OBJECT yourself and then
pass that to this method, or supply all the OPTIONS needed to create such
an object and it will be created for you.  The object which is added is
returned, and can be used for many methods directly.

For OPTIONS, see the specific type of collection.  Additional options are
listed below.

=option  type STRING|CLASS
=default type <required>

The nickname of a collection class or the CLASS name itself of the
object to be created.  Required if an object has to be created.
Predefined type nicknames are C<email> and C<location>.

=examples

 my $me   = User::Identity->new(...);
 my $locs = User::Identity::Collection::Locations->new();
 $me->addCollection($locs);

 my $email = $me->addCollection(type => 'email');
 my $email = $me->addCollection('email');

=error $object is not a collection.

The first argument is an object, but not of a class which extends
User::Identity::Collection.

=error Don't know what type of collection you want to add.

If you add a collection, it must either by a collection object or a
list of options which can be used to create a collection object.  In
the latter case, the type of collection must be specified.

=error Cannot load collection module $type ($class).

Either the specified $type does not exist, or that module named $class returns
compilation errors.  If the type as specified in the warning is not
the name of a package, you specified a nickname which was not defined.
Maybe you forgot the 'require' the package which defines the nickname.

=error Creation of a collection via $class failed.

The $class did compile, but it was not possible to create an object
of that class using the options you specified.

=cut

our %collectors =
 ( emails    => 'User::Identity::Collection::Emails'
 , locations => 'User::Identity::Collection::Locations'
 , systems   => 'User::Identity::Collection::Systems'
 );  # *s is tried as well, so email and location work too.

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
        croak "ERROR: Cannot load collection module $type ($class)"
           if $@;

        $object = $class->new(%args);
        croak "ERROR: Creation of a collection via $class failed"
           unless defined $object;
    }

    $object->user($self);
    $self->{UI_col}{$object->name} = $object;
}

#-----------------------------------------

=method collection NAME

In scalar context the collection object with the NAME is returned.
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

#-----------------------------------------

=method add COLLECTION, ROLE

The ROLE is added to the COLLECTION.  The COLLECTION is the name of a
collection, which will be created automatically with addCollection() if
needed.  The COLLECTION can also be specified as existing collection object.

The ROLE is anything what is acceptable to addRole() of the
collection at hand, and is returned.  ROLE typically is a list of
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

#-----------------------------------------

=method find COLLECTION, ROLE

Returns the object with the specified ROLE within the named collection.
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
     = ref $collname && $collname->isa('User::Identity::Collect') ? $collname
     : ($all->{$collname} || $all->{$collname.'s'});

    return unless defined $collection;
    $collection->find(shift);
}

#-----------------------------------------

1;

