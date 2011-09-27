module ServerMonitoringHQ

  module Jobs

    class Ports < BasicJob

      @queue = :default

      def self.perform(server, ports, return_url, timestamp, env=production)
        check_job_age(timestamp)

        Logger.info "Return URL (#{return_url})"
        Logger.info "Ports: #{server[:hostname]} #{server[:username]} #{server[:password]}"

        time = Benchmark.measure do
          SysStats::Stats.ports(server[:hostname], server[:username], server[:password], server[:port], server[:id], ports, server[:private_key], return_url)
        end
        
        Logger.info "Ports Finished: " + time.to_s
      end

    end

  end

end