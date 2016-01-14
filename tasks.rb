
require_relative 'basic_activity'
require 'pp'

class TaskOne < BasicActivity
  def initialize
    super('task_one')
  end

  def do_activity(task)
    pp task
    return true
  end
end


class TaskTwo < BasicActivity
  def initialize
    super('task_two')
  end

  def do_activity(task)
    pp task
    return true
  end
end

class TaskThree < BasicActivity
  def initialize
    super('task_three')
  end

  def do_activity(task)
    pp task
    return true
  end
end

class TaskFour < BasicActivity
  def initialize
    super('task_four')
  end

  def do_activity(task)
    pp task
    return true
  end
end


