module ServerMonitoringHQ

  module Jobs

    class Page < BasicJob

      @queue = :default

      def self.perform(url, search, page_id, return_url, timestamp, env=production)
        check_job_age(timestamp)

        Logger.info "Return URL (#{return_url})"
        Logger.info "Page: #{url} #{search}"

        time = Benchmark.measure do
          SysStats::Stats.page(url, search, page_id, return_url)
        end
        
        Logger.info "Page Finished: " + time.to_s
      end

    end

  end

end