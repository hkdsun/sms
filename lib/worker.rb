require_relative 'lftp'

class Worker
  def initialize(event)
    @event = event
    @job_params = event.job_params
  end

  def do_work
    lftp = LFTPSync.new(
      source: @job_params['path'],
      destination: "#{DOWNLOAD_DIR}/#{@job_params['label']}/",
      host: "TODO get this from event/config",
    )
    lftp.run_command
  end

  def work
    @event.start
    do_work
  ensure
    @event.finish
  end
end
