#!/usr/bin/perl

use Expect;

my $passwd = $ARGV[0];
my $ip = `/sbin/ifconfig eth0 | grep "inet addr:" | cut -d ':' -f 2 | cut -d ' ' -f 1`;

chomp $ip;
my $addschema = Expect->spawn("psql -h $ip quill quillwriter < /var/lib/pgsql/common_createddl.sql") || die "Unable to add common_createddl.sql schema\n";
unless($addschema->expect(10,"Password for user quillwriter: "))
{
   die "Password prompt wasn't found when inserting common_createddl.sql schema\n";
}
print $addschema "$passwd\n";
$addschema->soft_close();

$addschema = Expect->spawn("psql -h $ip quill quillwriter < /var/lib/pgsql/pgsql_createddl.sql") || die "Unable to add pgsql_createddl.sql schema\n";
unless($addschema->expect(10,"Password for user quillwriter: "))
{
   die "Password prompt wasn't found when inserting pgsql_createddl.sql schema\n";
}
print $addschema "$passwd\n";
$addschema->soft_close();

`touch /var/lock/subsys/condor_quill_schema`;

exit 0;
