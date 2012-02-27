Servermonitoringhq::Application.config.middleware.use ExceptionNotifier,   
  :email_prefix => "[ERROR] ",   
  :sender_address => '"Notifier" <notifier@servermonitoringhq.com>',   
  :exception_recipients => ['ian.purton@gmail.com']
