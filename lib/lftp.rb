require 'pty'

class LFTPSync
  class SyncError < StandardError; end
  PARALLELIZATION_FACTOR = 5
  LOG_DIR = ENV['SYNCMYSHIT_LOGDIR'] || '.'

  def initialize(
    source: nil,
    destination: nil,
    host: nil,
    port: nil,
    clear_src_dir: false,
    log: true
  )

    @host = host
    @source = source
    @destination = destination
    @port = port
    @remove_src = clear_src_dir
    @logging = log
    @debug = DEBUG
    @command = build_lftp_command

    raise ArgumentError, "Insufficient arguments to build an lftp command" unless @host && @source && @destination
  end

  def logging?
    @logging
  end

  def build_lftp_command
    stdin = <<-EOF
      set cmd:interactive false
      set ftp:ssl-protect-data true
      set ftps:initial-prot
      set ftp:ssl-force true
      set ftp:ssl-protect-data true
      set ssl:verify-certificate off
      set mirror:use-pget-n #{PARALLELIZATION_FACTOR}
      mirror #{"--Remove-source-files" if @remove_src} -c -P#{PARALLELIZATION_FACTOR} #{"--log=#{LOG_DIR}/syncmyshit_lftp.log" if logging?} #{@source.shellescape} #{@destination.shellescape}
      quit
    EOF
    cmd = "lftp sftp://#{@host.shellescape} #{"-p #{@port}" if @port}"
    [cmd, stdin]
  end

  def parse_line(line)
    # format reference:
    # `Adventure Time - 203b - Slow Love {C_P} (720p).mkv', got 147624467 of 173127299 (85%) 3.93M/s eta:22s
    re = /`(.*)',\sgot\s(.*)\sof\s(.*)\s\((.*)\)\s([0-9M\/s\.]*)\seta:(.*)/
    match = line.match(re)
    if match
      {
        filename: match[1],
        downloaded: match[2],
        total: match[3],
        progress: match[4],
        speed: match[5],
        eta: match[6],
      }
    end
  end

  def spawn_command
    cmd, doc = build_lftp_command
    PTY.spawn(cmd) do |reader, writer, pid|
      begin
        writer.puts doc
        reader.sync = true
        reader.each do |line|
          progress = parse_line(line)
          if progress
            puts "[LFTP-SYNC] #{progress[:filename]} | #{progress[:speed]} | #{progress[:progress]} | ETA: #{progress[:eta]}"
          else
            puts "[LFTP-SYNC] #{line}"
          end
        end
      rescue Errno::EIO
        puts "[LFTP-SYNC] no more output?"
      ensure
        Process.kill('KILL', pid)
      end
    end
  end

  def run_command
    begin
      spawn_command
    rescue PTY::ChildExited => e
      raise LFTPSync::SyncError, "lftp process exited unexpectedly"
    end
  end
end
