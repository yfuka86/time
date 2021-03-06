load './twitter_client.rb'

require 'clockwork'
require 'time'
require 'pry'
require 'timeout'
include Clockwork

class Timer
  STATUSES = [:working, :not_working]
  REGEXP = {working: /\As\w*\z/, not_working: /\A[ef]\w*\z/}
  INITIAL_STATUS_IDX = 1

  def initialize
    @status = STATUSES[INITIAL_STATUS_IDX]
    @from = Time.now
    @sum = {}
    @new_sum = {}
    STATUSES.each do |sym|
      if f = File.open(sym.to_s, "a+")
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
    time = (Time.parse("1/1") + (sec - day * 86400)).strftime("#{day}D,%-Hh%-Mm%-Ss")
  end

  def puts_time
    now = Time.now
    sec = now - @from
    time = time_range_presenter(sec)
    @new_sum[@status] = @sum[@status] + sec
    total = time_range_presenter(@new_sum[@status])

    puts "you continue #{@status} for #{time}"
    puts "totally you have been #{@status} for #{total}"

    File.open(@status.to_s, "w") do |file|
      file.write((@new_sum[@status]).to_s)
    end

    if now.sec == 0 && now.min == 0
      puts `afplay sound.mp3`
      if now.hour % 6 == 0
        str = "total:\n"
        STATUSES.each do |status|
          str += "#{status.to_s}:#{time_range_presenter(@new_sum[status])}\n"
        end
        puts TwitterClient.new.post(str)
      end
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
                @sum[@status] = @new_sum[@status]
                @status = sym
                @from = Time.now
              end
            end
          end
        end
        puts_time
      rescue Timeout::Error
        puts_time
      end
    end
  end
end

Timer.new.start
