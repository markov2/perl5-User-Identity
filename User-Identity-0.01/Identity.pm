package User::Identity;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

User::Identity - info about a physical person

=head1 SYNOPSIS

 use User::Identity;
 my $me = User::Indentity->new
  ( firstname => 'John'
  , surname   => 'Doe'
  );
 print $me;           # prints "John Doe"
 print $me->fullName  # same

=head1 DESCRIPTION

The User::Identity object is created to maintain a set of information
which is related to one user.  The identity can be created by any
simple or complex Perl program, and is therefore more flexible than
an XML file.  If you need more kinds of user information, then please
contact the author.

=head1 METHODS

=over 4

=cut

#-----------------------------------------

=item new [NICKNAME], OPTIONS

Create a new user identity, which will contain all data related 
to a single physical human being.  Most user data can only be
specified at object construction, because they should never
change.  A NICKNAME may be specified as first argument, but also
as option.

Available OPTIONS:

=over 4

=item * charset => STRING

=item * courtesy => STRING

=item * date_of_birth => DATE

=item * firstname => STRING

=item * full_name => STRING
 
=item * formal_name => STRING

=item * initials => STRING

=item * nickname => STRING

=item * gender => STRING

=item * language => STRING

=item * prefix => STRING

=item * surname => STRING

=item * titles => STRING

=cut

sub new(@)
{   my $class = shift;
    return undef unless @_;           # no empty users.

    unshift @_, 'nickname' if @_ %2;  # odd-length list: starts with nick

    (bless {}, $class)->init( {@_} );
}

sub init($)
{   my ($self, $args) = @_;

    defined $args->{$_} && ($self->{'UI_'.$_} = delete $args->{$_})
        foreach qw/
charset
courtesy
date_of_birth
full_name
formal_name
firstname
gender
initials
language
nickname
prefix
surname
titles
/;

   if(keys %$args)
   {   require Carp;
       local $" = ', ';
       Carp::croak("Unknown options: @{ [keys %$args ] }");
   }

   $self;
}

#-----------------------------------------

=item charset

The user's prefered character set.

=cut

sub charset() { shift->{UI_charset} || $ENV{LC_CTYPE} || $ENV{LC_ALL} }

#-----------------------------------------

=item nickname

Returns the user's nickname, which could be used as username, e-mail
alias, or such.  When no nick is specified, firstname() is called,
and all characters converted to lower case.

=cut

sub nickname()
{   my $self = shift;
    return $self->{UI_nickname} if exists $self->{UI_nickname};

    if(my $firstname = $self->firstname)
    {   return lc $firstname;
    }

    # TBI: If OS-specific info exists, then username

    undef;
}

#-----------------------------------------

=item firstname

=cut

sub firstname()
{   my $self = shift;

    return $self->{UI_firstname}
       if defined $self->{UI_firstname};

    # TBI: parse fullname if no first name is known.

    undef;
}

#-----------------------------------------

=item initials

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

=item prefix

The words which are between the firstname (or initials) and the surname.

=cut

sub prefix() { shift->{UI_prefix} }

#-----------------------------------------

=item surname

Returns the surname of person, or C<undef> if that is not known.

=cut

sub surname() {shift->{UI_surname}}

#-----------------------------------------

=item fullName

If this is not specified as value during object construction, it is
guessed based on other known values like "firstname prefix surname". 

=cut

sub fullName()
{   my $self = shift;

    return $self->{UI_full_name}
       if defined $self->{UI_full_name};

    my $full = join ' ', grep {defined $_}
                   @$self{ qw/UI_firstname UI_prefix UI_surname/ };

    $full = ucfirst(lc $self->{UI_nickname})
       if !length $full && defined $self->{UI_nickname};

    # TBI: if OS-specific knowledge, then unix GCOS?

    $full;
}

#-----------------------------------------

=item formalName

Returns a formal name for the user.  If not defined as instantiation
parameter, it is constructed from other available information, which
may result in an incorrect or an incomplete name.  The result is built
from "courtesy initials prefix surname title".

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

=item courtesy

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

    my $lang = lc($self->language || 'en');

    return $table->{$lang} if exists $table->{$lang};

    $lang =~ s/\..*//;     # "en_GB.utf8" --> "en-GB"  and retry
    return $table->{$lang} if exists $table->{$lang};

    $lang =~ s/[-_].*//;   # "en_GB.utf8" --> "en"  and retry
    $table->{$lang};
}

#-----------------------------------------

=item language

Can contain a list or a single language name, as defined by the RFC
Examples are 'en', 'en-GB', 'nl-BE'.

in scalar context only one value
is returned (the first in case of a list) as preferred language of the
person.  In list context, all (or the only one) value is returned.

=cut

sub language()
{   my $self = shift;

    return $self->{UI_language}
       if defined $self->{UI_language};

    # TBI: if we have a courtesy, we may detect the language.

    # TBI: when we have a postal address, we may derive the language from
    # the country.

    # TBI: if we have an e-mail addres, we may derive the language from
    # that.

    $ENV{LANG} || $ENV{LC_NAME} || $ENV{LC_TYPE} || $ENV{LC_ALL};
}

#-----------------------------------------

=item gender

Returns the specified gender of the person, as specified during
instantiation, which could be like 'Male', 'm', 'homme', 'man'.
There is no smart behavior on this: the exact specified value is
returned. Methods isMale(), isFemale(), and courtesy() are smart.

=cut

sub gender() { shift->{UI_gender} }

#-----------------------------------------

=item isMale

Returns true if we are sure that the user is male.  This is specified as
gender at instantiation, or derived from the courtesy value.  Method
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

=item isFemale

See isMale(): return true if we are sure it is a woman.

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

=item dateOfBirth

Returns the date of birth, as specified during instantiation.

=cut

sub dateOfBirth() {shift->{UI_date_of_birth}}

#-----------------------------------------

=item birth

Returns the date in standardized format: YYYYMMDD, easy to sort and
select.  This may return undef, even if the dateOfBirth() contains
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

=item age

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

=item titles

The titles, degrees in education or of other kind.  If these are complex, you
may need to specify a formal name as well because formatting sometimes
failes.

=cut

sub titles() { shift->{UI_titles} }

#-----------------------------------------

=back

=head1 SEE ALSO

User::Identity can be used in combination with Mail::Identity.

=head1 AUTHOR

Mark Overmeer, E<lt>mark@overmeer.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mark Overmeer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;

