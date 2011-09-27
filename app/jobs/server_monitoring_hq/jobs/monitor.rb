module ServerMonitoringHQ
  
  module Jobs
    
    class Monitor < BasicJob

      @queue = :servermonitoringhq
      
      def self.perform(server, return_url, timestamp, env=production)
        check_job_age(timestamp)

        Logger.info "Return URL (#{return_url})"

        if !server[:url].blank?
          Logger.info "Monitor via Agent: #{server[:url]} #{server[:id]} #{server[:env]}"
          SysStats::Stats.monitor_url(server[:url], server[:id], return_url)
        else
          Logger.info "Monitor: #{server[:hostname]} #{server[:id]} #{server[:password]} #{server[:username]} #{env}"

          time = Benchmark.measure do
            SysStats::Stats.monitor(server[:hostname], server[:username], server[:password], server[:port], server[:id], server[:private_key], return_url)
          end
          
          Logger.info "Monitor Finished: " + time.to_s
        end
      end
      
    end
    
  end
  
end