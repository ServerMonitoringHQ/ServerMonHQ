module ServerMonitoringHQ

  module Jobs

    class Top < BasicJob

      @queue = :default

      def self.perform(server, return_url, timestamp, env=production)
        check_job_age(timestamp)

        Logger.info "Return URL (#{return_url})"
        Logger.info "Top: #{server[:hostname]} #{server[:username]} #{server[:password]}"

        time = Benchmark.measure do
          SysStats::Stats.top(server[:hostname], server[:username], server[:password], server[:port], server[:id], server[:private_key], return_url)
        end
        
        Logger.info "Top Finished: " + time.to_s
      end

    end

  end

end