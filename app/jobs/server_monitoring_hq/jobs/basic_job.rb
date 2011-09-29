module ServerMonitoringHQ

  module Jobs

    class BasicJob

      def self.check_job_age(timestamp)
        age = Time.now.gmtime - Time.parse(timestamp)
        if age > 60
          Logger.info "Job too old, moving on."
          # Process.exit
          return false
        end
      end

    end

  end

end