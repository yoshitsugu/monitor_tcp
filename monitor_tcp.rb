require 'socket'
require 'mail'
require 'logger'
require 'timeout'
require File.expand_path("config.rb", File.dirname(__FILE__))

class TcpTester
  def initialize(host, port, timeout=5)
    @host = host
    @port = port
    @timeout = timeout
  end

  def main
    fork_timeout(@timeout) do 
      TCPSocket.open(@host, @port)
    end
  end

  class ForkTimeoutError < RuntimeError; end

  # http://docs.ruby-lang.org/ja/2.1.0/class/Timeout.html
  # 普通のtimeoutだとRubyレベルの処理でtimeoutは可能だが、Cライブラリ内でブロックされるとtimeoutが検知できない。
  def fork_timeout(secs, step=0.1, &block)
    pid = Process.fork(&block)
    unless _wait_until(pid, secs, step) then
      Process.kill(:KILL, pid)
      raise ForkTimeoutError
    end
  end
  
  def _wait_until(pid, secs, step)
    (0.0).step(secs, step) do
      sleep(0.1)
      fin = Process.waitpid(pid, Process::WNOHANG)
      return fin unless fin.nil?
    end
    nil
  end
end


begin
  logger = Logger.new(File.expand_path("log.log", File.dirname(__FILE__)))
  if CONFIG.nil?
    raise "CONFIGを設定してね" 
  end
  TcpTester.new(CONFIG[:host], CONFIG[:port], CONFIG[:timeout]).main
  logger.info "TEST OK"
rescue => e
  logger.error e.message
  logger.error e.backtrace.join("\n")
  mail = Mail.new do
    from CONFIG[:mail_from]
    to CONFIG[:mail_to]
    subject "TCP WATCH ERROR on #{CONFIG[:host]}:#{CONFIG[:port]}"
    body "#{e.message}\n#{e.backtrace.join("\n")}"
  end
  mail.delivery_method :smtp, address: CONFIG[:smtp_host], port: CONFIG[:smtp_port], openssl_verify_mode: "none" ,enable_starttls_auto: false
  mail.deliver
end

