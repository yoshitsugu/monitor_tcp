require 'socket'
require 'mail'
require 'logger'
require File.expand_path("config.rb", File.dirname(__FILE__))

class TcpTester
  def initialize(host, port, timeout=5)
    @host = host
    @port = port
    @timeout = timeout
  end

  def main
    timeout(@timeout) do
      TCPSocket.open(@host, @port)
    end
  end
end

logger = Logger.new(File.expand_path("log.log", File.dirname(__FILE__)))
begin
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

