require_relative 'utils.rb'

class BaseWorkflow
  attr_accessor :name

  def initialize(task_list)

    puts 'BaseWorkflow::initialize called with task_list: '+task_list
    # the domain to look for decision tasks in.
    @domain = init_domain

    # the task list is used to poll for decision tasks.
    @task_list = task_list

    # The list of activities to run, in order. These name/version hashes can be
    # passed directly to AWS::SimpleWorkflow::DecisionTask#schedule_activity_task.
    @activity_list = [
        { :name => 'task_one',    :version => 'v1' },
        { :name => 'task_two',    :version => 'v1' },
        { :name => 'task_three',  :version => 'v1' },
        { :name => 'task_four',   :version => 'v1' },
    ]

    register_workflow
  end

  def register_workflow
    puts 'BaseWorkflow::register_workflow called'

    workflow_name = self.class
    @workflow_type = nil

    # a default value...
    workflow_version = '1'

    # Check to see if this workflow type already exists. If so, use it.
    @domain.workflow_types.each do | a |
      if (a.name == workflow_name) && (a.version == workflow_version)
        @workflow_type = a
      end
    end

    if @workflow_type.nil?
      options =  {
          :default_child_policy => :terminate,
          :default_task_start_to_close_timeout => 3600,
          :default_execution_start_to_close_timeout => 24 * 3600 }

      puts "registering workflow: #{workflow_name}, #{workflow_version}, #{options.inspect}"
      @workflow_type = @domain.workflow_types.register(workflow_name, workflow_version, options)
    end

    puts "** registered workflow: #{workflow_name}"
  end

  def poll_for_decisions
    puts 'BaseWorkflow::poll_for_decisions called'

    # first, poll for decision tasks...
    @domain.decision_tasks.poll(@task_list) do | task |

      puts 'BaseWorkflow::poll_for_decisions :: task: '+task

      task.new_events.each do | event |
        case event.event_type
          when 'WorkflowExecutionStarted'
            puts "** scheduling activity task: #{@activity_list.first[:name]}"

            task.schedule_activity_task( @activity_list.first,
                                         { :task_list => "#{@task_list}-activities" } )

          when 'ActivityTaskCompleted'
            # we are running the activities in strict sequential order, and
            # using the results of the previous activity as input for the next
            # activity.
            last_activity = @activity_list.pop

            if(@activity_list.empty?)
              puts "!! All activities complete! Sending complete_workflow_execution..."
              task.complete_workflow_execution
              return true;
            else
              # schedule the next activity, passing any results from the
              # previous activity. Results will be received in the activity
              # task.
              puts "** scheduling activity task: #{@activity_list.first[:name]}"
              if event.attributes.has_key?('result')
                task.schedule_activity_task(
                    @activity_list.first,
                    { :input => event.attributes[:result],
                      :task_list => "#{@task_list}-activities" } )
              else
                task.schedule_activity_task(
                    @activity_list.first, { :task_list => "#{@task_list}-activities" } )
              end
            end
          when 'ActivityTaskTimedOut'
            puts "!! Failing workflow execution! (timed out activity)"
            task.fail_workflow_execution
            return false

          when 'ActivityTaskFailed'
            puts "!! Failing workflow execution! (failed activity)"
            task.fail_workflow_execution
            return false

          when 'WorkflowExecutionCompleted'
            puts "## Yesss, workflow execution completed!"
            task.workflow_execution.terminate
            return false
        end
      end
    end
  end

  def start_execution
    workflow_execution = @workflow_type.start_execution( { :task_list => @task_list } )
    poll_for_decisions
  end

end


if __FILE__ == $0
  require 'securerandom'

  # Use a different task list name every time we start a new workflow execution.
  #
  # This avoids issues if our pollers re-start before SWF considers them closed,
  # causing the pollers to get events from previously-run executions.
  task_list = SecureRandom.uuid

  # Let the user start the activity worker first...
  puts "Start the activity worker, preferably in a separate command-line window, with"
  puts "the following command:"
  puts ""
  puts "> ruby activity_worker.rb #{task_list}-activities"
  puts ""
  puts "Press return when you're ready..."

  i = gets

  puts "Starting workflow execution..."
  baseworkflow = BaseWorkflow.new(task_list)
  baseworkflow.start_execution
end

