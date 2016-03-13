require_relative 'event'
require_relative 'worker'
require 'eventmachine'

class Supervisor
  def initialize
    @queue = []
  end

  def push(params)
    event = Event.new(params)

    callback = Proc.new do |exception|
      if exception
        puts "Acting on a failure resulted from:\nMessage: #{exception}"
        puts "Backtrace: #{exception.backtrace.join("\n")}" if DEBUG
      end

      puts "Popping #{event} off the queue"
      @queue.delete(event)
    end

    @queue.push(event)

    EM.defer do
      with_fallback(callback, process(event))
    end
  end

  def process(event)
    return Proc.new do
      worker = Worker.new(event)
      worker.work
    end
  end

  def with_fallback(callback, work_proc)
    begin
      work_proc.call
      callback.call(nil)
    rescue StandardError => e
      callback.call(e)
    end
  end
end
