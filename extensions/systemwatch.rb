require 'sinatra/base'

module SystemWatch
  OS = RUBY_PLATFORM

  def self.registered(app)
    if OS.include? "darwin"
      puts "SystemWatch: Running on macOS"
      @system = 'MacOS'
    elsif OS.include? "linux"
      puts "SystemWatch: Running on Linux"
      @system = 'Linux'
    else
      puts "SystemWatch: Running on an unsupported OS"
      @system = 'unsupported'
    end
  end

  def self.cpu_usage
    if @system == 'Linux'
      @proc0 = File.readlines('/proc/stat').grep(/^cpu /).first.split(" ")
      sleep 1
      @proc1 = File.readlines('/proc/stat').grep(/^cpu /).first.split(" ")

      @proc0usagesum = @proc0[1].to_i + @proc0[2].to_i + @proc0[3].to_i
      @proc1usagesum = @proc1[1].to_i + @proc1[2].to_i + @proc1[3].to_i
      @procusage = @proc1usagesum - @proc0usagesum

      @proc0total = 0
      for i in (1..4) do
        @proc0total += @proc0[i].to_i
      end
      @proc1total = 0
      for i in (1..4) do
        @proc1total += @proc1[i].to_i
      end
      @proctotal = (@proc1total - @proc0total)

      @cpuusage = (@procusage.to_f / @proctotal.to_f)
      @cpuusagepercentage = (100 * @cpuusage).to_f.round(2)
    elsif @system == 'MacOS'
      top = `top -l1 | awk '/CPU usage/'`
      top = top.gsub(/[\,a-zA-Z:]/, "").split(" ")
      top[0].to_f
    end
  end

  def self.ram_usage
    if @system == 'Linux'
      if File.exist?("/proc/meminfo")
        File.open("/proc/meminfo", "r") do |file|
          @result = file.read
        end
      end

      @memstat = @result.split("\n").collect{|x| x.strip}
      @memtotal = @memstat[0].gsub(/[^0-9]/, "")
      @memactive = @memstat[5].gsub(/[^0-9]/, "")
      @memactivecalc = (@memactive.to_f * 100) / @memtotal.to_f
      @memusagepercentage = @memactivecalc.round
    elsif @system == 'MacOS'
      top = `top -l1 | awk '/PhysMem/'`
      used = top.match(/(\d+)M used/)[1].to_f
      free = top.match(/(\d+)M unused/)[1].to_f
      total = used + free
      (used / total * 100).round(2)
    end
  end

  Sinatra.register SystemWatch
end