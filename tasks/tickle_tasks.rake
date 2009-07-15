require File.join(File.dirname(__FILE__), "../lib/tickle")

# Yanked from Rails
desc 'Run all unit, functional and integration tests'
task :tickle, :count do |t, args|
  errors = %w(tickle:units tickle:functionals tickle:integration).collect do |task|
    begin
      Rake::Task[task].invoke(args[:count])
      nil
    rescue => e
      task
    end
  end.compact
  abort "Errors running #{errors.to_sentence}!" if errors.any?
end

namespace :tickle do
  [:units, :functionals, :integration].each do |t|
    type = t.to_s.sub(/s$/, '')

    desc "Run #{type} tests"
    task t, :count do |t, args|
      Tickle.load_environment

      size = args[:count] ? args[:count].to_i : 2
      puts "Running #{type} tests using #{size} processes"
      Tickle.run_tests type, size
    end
  end
end
