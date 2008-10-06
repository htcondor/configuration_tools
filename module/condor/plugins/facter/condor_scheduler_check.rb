# condor_scheduler_check.rb

Facter.add("condor_scheduler_check") do
	setcode do
		%x{/usr/bin/condor_config_val DAEMON_LIST | /bin/grep -ci SCHEDD}.chomp
	end
end
