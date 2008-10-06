# condor_startd_check.rb

Facter.add("condor_startd_check") do
	setcode do
		%x{/usr/bin/condor_config_val DAEMON_LIST | /bin/grep -ci STARTD}.chomp
	end
end
