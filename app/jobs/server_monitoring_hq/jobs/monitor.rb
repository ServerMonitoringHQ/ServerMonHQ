module ServerMonitoringHQ
  
  module Jobs
    
    class Monitor < BasicJob

      @queue = :servermonitoringhq
      
      def self.perform(server, return_url, timestamp, env="production")
        return if check_job_age(timestamp)

        puts "Return URL (#{return_url})"

        if !server['url'].blank?
          SysStats::Stats.monitor_url(server['url'], server['id'], return_url)
        else
          time = Benchmark.measure do
            SysStats::Stats.monitor(server['hostname'], server['username'], server['password'], server['port'], server['id'], server['private_key'], return_url)
          end
          
          puts "Monitor Finished: " + time.to_s
        end
      end
      
    end
    
  end
  
end
