require_relative 'utils.rb'

class BasicActivity

  attr_accessor :activity_type
  attr_accessor :name
  attr_accessor :results

  def initialize(name, version = 'v1', options = nil)

    @activity_type = nil
    @name = name
    @results = nil

    # get the domain to use for activity tasks.
    @domain = init_domain

    # Check to see if this activity type already exists.
    @domain.activity_types.each do | a |
      if (a.name == @name) && (a.version == version)
        @activity_type = a
      end
    end

    if @activity_type.nil?
      # If no options were specified, use some reasonable defaults.
      if options.nil?
        options = {
            # All timeouts are in seconds.
            :default_task_heartbeat_timeout => 900,
            :default_task_schedule_to_start_timeout => 120,
            :default_task_schedule_to_close_timeout => 3800,
            :default_task_start_to_close_timeout => 3600 }
      end
      @activity_type = @domain.activity_types.register(@name, version, options)
    end
  end


  def do_activity(task)
    @results = task.input # may be nil
    return true
  end

end