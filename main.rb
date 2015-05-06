load './twitter_client.rb'

require 'clockwork'
require 'time'
require 'pry'
require 'timeout'
include Clockwork

class Timer
  STATUSES = [:work, :not_work]
  REGEXP = {work: /\As\w*\z/, not_work: /\A[ef]\w*\z/}
  INITIAL_STATUS_IDX = 1

  def initialize
    @status = STATUSES[INITIAL_STATUS_IDX]
    @from = Time.now
    @sum = {}
    @new_sum = {}
    STATUSES.each do |sym|
      if f = File.open(sym.to_s)
        if f.eof?
          @sum[sym] = 0
        else
          f.each do |line|
            @sum[sym] = line.to_i
          end
        end
      end
    end
    @new_sum = @sum.clone
  end

  def time_range_presenter(sec)
    day = sec.to_i / 86400
    time = (Time.parse("1/1") + (sec - day * 86400)).strftime("#{day}日%-H時間%-M分%-S秒")
  end

  def puts_time
    sec = Time.now - @from
    time = time_range_presenter(sec)
    @new_sum[@status] = @sum[@status] + sec
    total = time_range_presenter(@new_sum[@status])

    puts "you continue #{@status}ing for #{time}"
    puts "totally you #{@status}ed for #{total}"

    File.open(@status.to_s, "w") do |file|
      file.write((@new_sum[@status]).to_s)
    end
  end

  def start
    every(1.seconds, 'ticktack') do
      line = ''
      begin
        Timeout::timeout(0.01) do
          if line = gets
            line.chomp!
            STATUSES.each do |sym|
              if line =~ REGEXP[sym] && @status != sym
                @status = sym
                @from = Time.now
              end
              @sum[sym] = @new_sum[sym]
            end
          end
        end
        puts_time
      rescue Timeout::Error
        puts_time
      end
    end

    every(1.hours, 'twitter') do
      puts TwitterClient.new.post("#{@status.to_s}:#{@sum[@status]}")
    end
  end
end

Timer.new.start
