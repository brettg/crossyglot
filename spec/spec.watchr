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
#
Signal.trap 'INT' do
  if @sent_an_int
    puts '  Shutting down now.'
    exit
  else
    puts '  One INT runs the tests again. Two shuts down.'
    @sent_an_int = true
    Kernel.sleep 1.5
    run_all_specs
    @sent_an_int = false
  end
end

run_all_specs
