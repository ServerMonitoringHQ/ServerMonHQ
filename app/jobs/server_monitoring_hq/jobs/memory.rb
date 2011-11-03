module ServerMonitoringHQ

  module Jobs

    class Memory < BasicJob

      @queue = :servermonitoringhq

      def self.perform(server, return_url, timestamp, env="production")
        return if check_job_age(timestamp)

        Logger.info "Return URL (#{return_url})"
        Logger.info "Memory: #{server[:hostname]} #{server[:username]} #{server[:password]}"
        
        time = Benchmark.measure do
          SysStats::Stats.memory(server[:hostname], server[:username], server[:password], server[:port], server[:id], server[:private_key], return_url)
        end

        Logger.info "Memory Finished: " + time.to_s
      end

    end

  end

end