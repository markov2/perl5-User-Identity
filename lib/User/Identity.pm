package User::Identity;
use base 'User::Identity::Item';

use strict;
use warnings;
use Carp;

=chapter NAME

User::Identity - maintains info about a physical person

=chapter SYNOPSIS

 use User::Identity;
 my $me = User::Identity->new
  ( 'john'
  , firstname => 'John'
  , surname   => 'Doe'
  );
 print $me->fullName  # prints "John Doe"
 print $me;           # same

=chapter DESCRIPTION

The C<User::Identity> object is created to maintain a set of informational
objects which are related to one user.  The C<User::Identity> module tries to
be smart providing defaults, conversions and often required combinations.

The identities are not implementing any kind of storage, and can therefore
be created by any simple or complex Perl program.  This way, it is more
flexible than an XML file to store the data.  For instance, you can decide
to store the data with M<Data::Dumper>, M<Storable>, DBI, M<AddressBook>
or whatever.  Extension to simplify this task are still to be developed.

If you need more kinds of user information, then please contact the
module author.

=chapter OVERLOADED

=method stringification

When an C<User::Identity> is used as string, it is automatically
translated into the fullName() of the user involved.

=examples

 my $me = User::Identity->new(...)
 print $me;          # same as  print $me->fullName
 print "I am $me\n"; # also stringification

=cut

use overload '""' => 'fullName';

#-----------------------------------------

=chapter METHODS

=c_method new [NAME], OPTIONS

Create a new user identity, which will contain all data related 
to a single physical human being.  Most user data can only be
specified at object construction, because they should never
change.  A NAME may be specified as first argument, but also
as option, one way or the other is required.

=option  charset STRING
=default charset $ENV{LC_CTYPE}

=option  courtesy STRING
=default courtesy undef

=option  birth DATE
=default birth undef

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

my @attributes = qw/charset courtesy birth full_name formal_name
firstname gender initials language nickname prefix surname titles /;

sub init($)
{   my ($self, $args) = @_;

    exists $args->{$_} && ($self->{'UI_'.$_} = delete $args->{$_})
        foreach @attributes;

    $self->SUPER::init($args);
}

sub type() { 'user' }

sub user() { shift }

=section Attributes

=method charset
The user's prefered character set, which defaults to the value of
LC_CTYPE environment variable.

=cut

sub charset() { shift->{UI_charset} || $ENV{LC_CTYPE} }

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

=method firstname
Returns the first name of the user.  If it is not defined explicitly, it
is derived from the nickname, and than capitalized if needed.

=cut

sub firstname()
{   my $self = shift;
    $self->{UI_firstname} || ucfirst $self->nickname;
}

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

=method prefix
The words which are between the firstname (or initials) and the surname.

=cut

sub prefix() { shift->{UI_prefix} }

=method surname
Returns the surname of person, or C<undef> if that is not known.

=cut

sub surname() { shift->{UI_surname} }

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

=method gender
Returns the specified gender of the person, as specified during
instantiation, which could be like 'Male', 'm', 'homme', 'man'.
There is no smart behavior on this: the exact specified value is
returned. Methods isMale(), isFemale(), and courtesy() are smart.

=cut

sub gender() { shift->{UI_gender} }

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

=method dateOfBirth
Returns the date of birth, as specified during instantiation.

=cut

sub dateOfBirth() { shift->{UI_birth} }

=method birth
Returns the date in standardized format: YYYYMMDD, easy to sort and
select.  This may return C<undef>, even if the M<dateOfBirth()> contains
a value, simply because the format is not understood. Month or day may
contain C<'00'> to indicate that those values are not known.

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

=method titles
The titles, degrees in education or of other kind.  If these are complex,
you may need to specify the formal name of the users as well, because
smart formatting probably failes.

=cut

sub titles() { shift->{UI_titles} }

1;

