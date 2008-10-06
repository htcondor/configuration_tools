# condor_collector_check.rb

Facter.add("condor_collector_check") do
	setcode do
		%x{/usr/bin/condor_config_val DAEMON_LIST | /bin/grep -ci COLLECTOR}.chomp
	end
end
