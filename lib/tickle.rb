module Tickle
  extend self

  def load_environment
    return if @loaded
    puts "Loading Rails.."
    ENV["RAILS_ENV"] = "test"
    Object.const_set :RAILS_ENV, "test"

    require(File.join(RAILS_ROOT, 'config', 'environment'))
    $: << "#{Rails.root}/test"
    require "#{Rails.root}/test/test_helper"

    @loaded = true
  end

  def run_tests(dir, n = 2)
    dir = "#{Rails.root}/test/#{dir}/**/*_test.rb" unless dir.index(Rails.root)
    groups = Dir[dir].sort.in_groups(n, false)

    pids = []
    n.times do |i|
      pids << Process.fork do
        prepare_databse(:"test_#{i+1}")
        groups[i].each {|f| load(f) unless f =~ /^-/  }
      end
    end

    Signal.trap 'SIGINT', lambda { pids.each {|p| Process.kill("KILL", p)}; exit 1 }

    # Wait...
    Process.waitall
  end

  def prepare_databse(db)
    ActiveRecord::Base.establish_connection(db)
    conf = ActiveRecord::Base.configurations
    ActiveRecord::Base.connection.recreate_database(conf[db.to_s]["database"], conf[db.to_s])
    ActiveRecord::Base.establish_connection(conf[db.to_s])
    ActiveRecord::Schema.verbose = false
    file = ENV['SCHEMA'] || "#{RAILS_ROOT}/db/schema.rb"
    load(file)
  end
end