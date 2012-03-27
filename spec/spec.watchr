# Started with: https://gist.github.com/298168
#
if __FILE__ == $0
  puts "Run with: watchr #{__FILE__}. \n\nRequired gems: watchr rev"
  exit 1
end

# --------------------------------------------------
# Convenience Methods
# --------------------------------------------------
def run(cmd)
  puts(cmd)
  system(cmd)
end

def run_all_specs
  run 'rspec'
end

def run_single_spec *spec
  spec = spec.map {|s| %Q{-P "#{s}"}}.join(' ')
  run "rspec #{spec}"
end

# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------
watch('^spec/spec_helper\.rb') {run_all_specs}
# watch('^spec/.*_spec\.rb'    ) {|m| run_single_spec(m[0])}
# watch('^lib/(.*)\.rb'        ) {|m| run_single_spec('spec/**/%s_spec.rb' % File.basename(m[1]))}
watch('^spec/.*_spec\.rb'    ) {run_all_specs}
watch('^lib/(.*)\.rb'        ) {run_all_specs}

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
# Ctrl-\
Signal.trap('QUIT') do
  puts " --- Running all tests ---\n\n"
  run_all_specs
end

# Ctrl-C
Signal.trap('INT') { abort("\n") }

puts "Watching.."
