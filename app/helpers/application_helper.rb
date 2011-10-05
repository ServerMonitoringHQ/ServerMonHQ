# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def next_steps

    if current_user.account.servers.count == 0
      return '<div id="next-steps">To get started go to the Servers tab and click "Add Server"</div>'
    end

    pages = current_user.account.servers.inject(0) do 
      |sum, val| sum + val.pages.count 
    end
    
    if pages == 0
      return '<div id="next-steps">Why not try our web page monitoring ?' +
        ' Select a server then click the pages tab.</div>'
    end

    ports = current_user.account.servers.inject(0) do 
      |sum, val| sum + val.ports.count 
    end
    
    if ports == 0
      return '<div id="next-steps">Why not try our port monitoring ?' +
        ' Select a server then click the ports tab.</div>'
    end
  end

  def paypal_cancel_path
    custom = current_user.account.id

    if Rails.env == 'development'
      return "https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_subscr-find&alias=buss_1287675769_biz%40gmail%2ecom"
    else
      return "https://www.paypal.com/cgi-bin/webscr?cmd=_subscr-find&alias=ian%2epurton%40rbs%2ecom"
    end
  end

  def paypal_path(item_no)
    custom = current_user.account.id

    if Rails.env == 'development'

      paypal_url = "https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id="
      notify_url = "http://serverpulse.ianpurton.com/paypal_ipn"
      return_url = "http://serverpulse.ianpurton.com/account"

      if item_no == 0
        return paypal_url + "PKRDEBWL2CVPJ&custom=#{custom}&notify_url=#{notify_url}" +
          "&return=#{return_url}&rm=1"
      elsif item_no == 1
        return paypal_url + "PKRDEBWL2CVPJ&custom=#{custom}&notify_url=#{notify_url}" +
          "&return=#{return_url}&rm=1"
      elsif item_no == 2
        return paypal_url + "QF4KRDXNURVJW&custom=#{custom}&notify_url=#{notify_url}" +
          "&return=#{return_url}&rm=1"
      elsif item_no == 3
        return paypal_url + "URGNZ5ZU39D7A&custom=#{custom}&notify_url=#{notify_url}" +
          "&return=#{return_url}&rm=1"
      end
    else

      paypal_url = "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id="
      notify_url = "http://servermonitoringhq.com/paypal_ipn"
      return_url = "http://servermonitoringhq.com/account"

      if item_no == 0
        return paypal_url + "B7XTN2TB4N6AG&custom=#{custom}&notify_url=#{notify_url}" +
          "&return=#{return_url}&rm=1"
      elsif item_no == 1
        return paypal_url + "YFAC78P5YVMVW&custom=#{custom}&notify_url=#{notify_url}" +
          "&return=#{return_url}&rm=1"
      elsif item_no == 2
        return paypal_url + "BEZ4KZT2YE5YW&custom=#{custom}&notify_url=#{notify_url}" +
          "&return=#{return_url}&rm=1"
      elsif item_no == 3
        return paypal_url + "WZV4VR94PQZJJ&custom=#{custom}&notify_url=#{notify_url}" +
          "&return=#{return_url}&rm=1"
      end
    end
  end

  def select_tab(lookup)
    if request.fullpath =~ lookup
      return "active"
    end
    return "normal"
  end
  
  def select_home
    if request.fullpath == '/'
      return "selected"
    end
    return "normal"
  end

  def distro_image(distro)
    
    if distro =~ /centos/i 
      return image_tag('/images/distros/centos.gif', :alt => 'centOS')  
    end        

    if distro =~ /debian/i   
      return image_tag('/images/distros/debian.gif', :alt => 'Debian')   
    end                            

    if distro =~ /fedora/i  
      return image_tag('/images/distros/fedora.gif', :alt => 'Fedora')    
    end            

    if distro =~ /freebsd/i 
      return image_tag('/images/distros/freebsd.gif', :alt => 'FreeBSD')    
    end             

    if distro =~ /gentoo/i    
      return image_tag('/images/distros/gentoo.gif', :alt => 'Gentoo')    
    end          

    if distro =~ /mandrake/i   
      return image_tag('/images/distros/mandrake.gif', :alt => 'Mandrake')    
    end        

    if distro =~ /redhat/i 
      return image_tag('/images/distros/redhat.gif', :alt => 'RedHat')     
    end        

    if distro =~ /slackware/i   
      return image_tag('/images/distros/slackware.gif', :alt => 'Slackware')   
    end        

    if distro =~ /suse/i
      return image_tag('/images/distros/suse.gif', :alt => 'Suse')   
    end        
  
    return image_tag('/images/distros/linux.gif', :alt => 'Linux')                              
  end
  
end
