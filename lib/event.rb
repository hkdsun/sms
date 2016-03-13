class Event
  attr_accessor :params, :job_params

  def initialize(params = {})
    @job_params = params.dup
    @params = params.merge({
      queued_at: Time.now.utc,
    })
  end

  def start(time = Time.now.utc)
    puts "Started processing event at #{time}" if DEBUG
    @params = params.merge({
      started_at: time
    })
  end

  def finish(time = Time.now.utc)
    puts "Finished processing event at #{time}" if DEBUG
    @params = params.merge({
      finished_at: time
    })
  end

  def to_s
    "Event <#{self.hash}>: [#{@params.to_s}]"
  end
end
