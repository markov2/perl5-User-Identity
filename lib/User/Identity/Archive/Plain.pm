
package User::Identity::Archive::Plain;
use base 'User::Identity::Archive';

use strict;
use warnings;
use Carp;

=chapter NAME

User::Identity::Archive::Plain - simple, plain text archiver

=chapter SYNOPSIS

 use User::Identity::Archive::Plain;
 my $friends = M<User::Identity::Archive::Plain>->new('friends');
 $friends->from(\*FH);
 $friends->from('.friends');

=chapter DESCRIPTION

This archiver, which extends M<User::Identity::Archive>, uses a very
simple plain text file to store the information of users.  The syntax
is described in the DETAILS section, below.

=chapter OVERLOADED

=chapter METHODS

=c_method new [NAME], OPTIONS

=option  abbreviations HASH|ARRAY
=default abbreviations []
Adds a set of abbreviations for collections to the syntax of the
plain text archiver.  See section L</Simplified class names> for
a list of predefined names.

=option  only ARRAY|ABBREV
=default only []
Lists the only information (as (list of) abbreviations) which should be
read.  Other information is removed before even checking whether it is
a valid abbreviation or not.

=option  tabstop INTEGER
=default tabstop 8
Sets the default tab-stop width.

=cut

my %abbreviations =
 ( user     => 'User::Identity'
 , email    => 'Mail::Identity'
 , location => 'User::Identity::Location'
 , system   => 'User::Identity::System'
 , list     => 'User::Identity::Collection::Emails'
 );

sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args) or return;

    # Define the keywords.

    my %only;
    if(my $only = delete $args->{only})
    {   my @only = ref $only ? @$only : $only;
        $only{$_}++ for @only;
    }

    while( my($k,$v) = each %abbreviations)
    {   $self->abbreviation($k, $v) unless keys %only && !$only{$k};
    }
    
    if(my $abbrevs = delete $args->{abbreviations})
    {   $abbrevs = { @$abbrevs } if ref $abbrevs eq 'ARRAY';
        while( my($k,$v) = each %$abbrevs)
        {   $self->abbreviation($k, $v) unless keys %only && !$only{$k};   
        }
    }

    foreach (keys %only)
    {   warn "Option 'only' specifies undefined abbreviation '$_'\n"
            unless defined $self->abbreviation($_);
    }

    $self->{UIAP_items}   = {};
    $self->{UIAP_tabstop} = delete $args->{tabstop} || 8;
    $self;
}

=method from FILEHANDLE|FILENAME|ARRAY, OPTIONS
Read the plain text information from the specified FILEHANDLE, FILENAME,
STRING, or ARRAY of lines.

=option  tabstop INTEGER
=default tabstop <default from object>

=option  verbose INTEGER
=default verbose 0

=warning Cannot read archive from $source

=cut

sub from($@)
{   my ($self, $in, %args) = @_;

    my $verbose = $args{verbose} || 0;
    my ($source, @lines);

    if(ref $in)
    {   ($source, @lines)
         = ref $in eq 'ARRAY'     ? ('array', @$in)
         : ref $in eq 'GLOB'      ? ('GLOB', <$in>)
         : $in->isa('IO::Handle') ? (ref $in, $in->getlines)
         : confess "Cannot read from a ", ref $in, "\n";
    }
    elsif(open IN, "<", $in)
    {   $source = "file $in";
        @lines  = <IN>;
    }
    else
    {   warn "Cannot read archive from file $in: $!\n";
        return $self;
    }

    print "reading data from $source\n" if $verbose;

    return $self unless @lines;
    my $tabstop = $args{tabstop} || $self->defaultTabStop;

    $self->_set_lines($source, \@lines, $tabstop);

    while(my $starter = $self->_get_line)
    {   $self->_accept_line;
        my $indent = $self->_indentation($starter);

        print "  adding $starter" if $verbose > 1;

        my $item   = $self->_collectItem($starter, $indent);
        $self->add($item->type => $item) if defined $item;
    }
    $self;
}

sub _set_lines($$$)
{   my ($self, $source, $lines, $tab) = @_;
    $self->{UIAP_lines}  = $lines;
    $self->{UIAP_source} = $source;
    $self->{UIAP_curtab} = $tab;
    $self->{UIAP_linenr} = 0;
    $self;
}

sub _get_line()
{   my $self = shift;
    my ($lines, $linenr, $line) = @$self{ qw/UIAP_lines UIAP_linenr UIAP_line/};

    # Accept old read line, if it was not accepted.
    return $line if defined $line;

    # Need to read a new line;
    $line = '';
    while($linenr < @$lines)
    {   my $reading = $lines->[$linenr];

        $linenr++, next if $reading =~ m/^\s*\#/;    # skip comments
        $linenr++, next unless $reading =~ m/\S/;    # skip blanks
        $line .= $reading;

        if($line =~ s/\\\s*$//)
        {   $linenr++;
            next;
        }

        if($line =~ m/^\s*tabstop\s*\=\s*(\d+)/ )
        {   $self->{UIAP_curtab} = $1;
            $line = '';
            next;
        }

        last;
    }
    return () unless length $line || $linenr < @$lines;
    
    $self->{UIAP_linenr} = $linenr;
    $self->{UIAP_line}   = $line;
    $line;
}

sub _accept_line()
{   my $self = shift;
    delete $self->{UIAP_line};
    $self->{UIAP_linenr}++;
}

sub _location()     { @{ (shift) }{ qw/UIAP_source UIAP_linenr/ } }

sub _indentation($)
{   my ($self, $line) = @_;
    return -1 unless defined $line;

    my ($indent) = $line =~ m/^(\s*)/;
    return length($indent) unless index($indent, "\t") >= 0;

    my $column = 0;
    my $tab    = $self->{UIAP_curtab};
    my @chars  = split //, $indent;
    while(my $char = shift @chars)
    {   $column++, next if $char eq ' ';
        $column = (int($column/$tab+0.0001)+1)*$tab;
    }
    $column;
}

sub _collectItem($$)
{   my ($self, $starter, $indent) = @_;
    my ($type, $name) = $starter =~ m/(\w+)\s*(.*?)\s*$/;
    my $class = $abbreviations{$type};
    my $skip  = ! defined $class;
#warn "Skipping type $type\n" if $skip;

    my (@fields, @items);

    while(1)
    {   my $line        = $self->_get_line;
        my $this_indent = $self->_indentation($line);
        last if $this_indent <= $indent;

        $self->_accept_line;
        $line           =~ s/[\r\n]+$//;
#warn "Skipping line $line\n" if $skip;
        next if $skip;

        my $next_line   = $self->_get_line;
        my $next_indent = $self->_indentation($next_line);

        if($this_indent < $next_indent)
        {   # start a collectable item
#warn "Accepting item $line, $this_indent\n";
            my $item = $self->_collectItem($line, $this_indent);
            push @items, $item if defined $item;
#warn "Item ready $line\n";
        }
        elsif(   $this_indent==$next_indent
              && $line =~ m/^\s*(\w*)\s*(\w+)\s*\=\s*(.*)/ )
        {   # Lookup!
            my ($group, $name, $lookup) = ($1,$2,$3);
#warn "Lookup ($group, $name, $lookup)";
            my $item;   # not implemented yet
            push @items, $item if defined $item;
        }
        else
        {   # defined a field
#warn "Accepting field $line\n";
            my ($group, $name) = $line =~ m/(\w+)\s*(.*)/;
            $name =~ s/\s*$//;
            push @fields, $group => $name;
            next;
        }
    }

    return () unless @fields || @items;

#warn "$class NAME=$name";
    my $warn     = 0;
    my $warn_sub = $SIG{__WARN__};
    $SIG{__WARN__} = sub {$warn++; $warn_sub ? $warn_sub->(@_) : print STDERR @_};

    my $item = $class->new(name => $name, @fields);
    $SIG{__WARN__} = $warn_sub;

    if($warn)
    {   my ($source, $linenr) = $self->_location;
        $linenr -= 1;
        warn "  found in $source around line $linenr\n";
    }

    $item->add($_->type => $_) foreach @items;
    $item;
}

=section Attributes

=method defaultTabStop [INTEGER]
Returns the width of a tab, optionally after setting it.  This must be
the same as set in your editor.
=cut

sub defaultTabStop(;$)
{   my $self = shift;
    @_ ? ($self->{UIAP_tabstop} = shift) : $self->{UIAP_tabstop};
}

=method abbreviation NAME, [CLASS]
Returns the class which is capable of storing information which is
grouped as NAME.  With CLASS argument, you add (or overrule) the
definitions of an abbreviation.  The CLASS is automatically loaded.

If CLASS is C<undef>, then the abbreviation is deleted.  The class
name which is deleted is returned.

=cut

sub abbreviation($;$)
{   my ($self, $name) = (shift, shift);
    return $self->{UIAP_abbrev}{$name} unless @_;

    my $class = shift;
    return delete $self->{UIAP_abbrev}{$name} unless defined $class;

    eval "require $class";
    die "Class $class is not usable, because of errors:\n$@" if $@;

    $self->{UIAP_abbrev}{$name} = $class;
}

=method abbreviations
Returns a sorted list of all names which are known as abbreviations.

=cut

sub abbreviations() { sort keys %{shift->{UIAP_abbrev}} }

=chapter DETAILS

=section The Plain Archiver Format

=subsection Simplified class names

It is too much work to specify full class named on each spot where you
want to create a new object with data.  Therefore, abbreviations are
introduced.  Use M<new(abbreviations)> or M<abbreviations()> to add extra
abbreviations or to overrule some predefined.

Predefined names:
  user         M<User::Identity>
  email        M<Mail::Identity>
  location     M<User::Identity::Location>
  system       M<User::Identity::System>
  list         M<User::Identity::Collection::Emails>

It would have been nicer to refer to a I<person> in stead of a I<user>,
however that would add to the confusion with the name-space.

=subsection Indentation says all

The syntax is as simple as possible. An extra indentation on a line
means that the variable or class is a collection within the class on
the line before.

 user markov
   location home
      country NL
   email home
      address  mark@overmeer.net
      location home
   email work
      address  solutions@overmeer.bet

 email tux
    address tux@fish.net

The above defines two items: one M<User::Identity> named C<markov>, and
an e-mail address C<tux>.  The user has two collections: one contains
a single location, and one stores two e-mail addresses.

To add to the confusion: the C<location> is defined as field in C<email>
and as collection.  The difference is easily detected: if there are
indented fields following the line it is a collection.  Mistakes will
in most cases result in an error message.

=subsection Long lines

If you want to continue on the next line, because your content is too
large, then add a backslash to the end, like this:

 email home
    description This is my home address,     \
                But I sometimes use this for \
                work as well
    address tux@fish.aq

Continuations do not play the game of indentation, so what you also
can do is:

 email home
    description               \
 This is my home address,     \
 But I sometimes use this for \
 work as well
    address tux@fish.aq

The fields C<comment> and C<address> must be correctly indented.
The line terminations are lost, which is useful for most fields.  However,
if you need them, you have to check the description of the applicable field.

=subsection Comments

You may add comments and white spaces.  Comments start with a C<'#'> as
first non-blank character on the line.  Comments are B<not allowed> on
the same line as real data, as some languages (like Perl) permit.

You can insert comments and blank lines on all places where you need
them:

 user markov

    # my home address
    email home

       # useless comment statement
       address tux@fish.aq
       location #mind_the_hash

is equivalent to:

 user markov
    email home
       address tux@fish.aq
       location #mind_the_hash

=subsection References

Often you will have the need to add the same information to two items,
for instance, multiple people share the same address.  In this case,
you can create a reference.  However, this is only permitted for
whole items: you can refer to someone's location, but not to the person's
street.

To create a reference to an item of someone else, use

 user markov
    location home = user(cleo).location(home)
    location work
       organization   MARKOV Solutions

=subsection Configuration parameters

You can add some configuration lines as well.  On the moment, the only
one defined is

 tabstop = 4

which can be used to change the meaning of tabs in the file.  The default
setting is 8, but some people prefer 4 (or other values).

=cut

1;

