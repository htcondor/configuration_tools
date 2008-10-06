# condor_negotiator_check.rb

Facter.add("condor_negotiator_check") do
	setcode do
		%x{/usr/bin/condor_config_val DAEMON_LIST | /bin/grep -ci NEGOTIATOR}.chomp
	end
end
