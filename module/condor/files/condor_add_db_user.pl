#!/usr/bin/perl

use Expect;

my $username = $ARGV[0];
my $passwd = $ARGV[1];

my $adduser = Expect->spawn("createuser $username --no-createdb --no-adduser --pwprompt") || die "Unable run createuser to add $username\n";
unless($adduser->expect(10,"Enter password for new role: "))
{
   die "Password prompt for $username wasn't found\n";
}
print $adduser "$passwd\n";

unless($adduser->expect(10,"Enter it again: "))
{
   die "Password confirmation prompt for $username wasn't found\n";
}
print $adduser "$passwd\n";

unless($adduser->expect(10,"Shall the new role be allowed to create more new roles? (y/n) "))
{
   die "Final question not found for $username\n";
}
print $adduser "n\n";
$adduser->soft_close();

exit 0;
