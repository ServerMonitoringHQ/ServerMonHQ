module ServersHelper

  def public_code(servers)

    url = 'http://servermonitoringhq.com'
    access_key = servers[0].access_key

code = <<EOF
#{url}/statistics/external/#{access_key}
EOF

    return code

  end

end
