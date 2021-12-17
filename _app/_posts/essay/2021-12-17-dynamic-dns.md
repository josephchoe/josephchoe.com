---
title: Dynamic DNS
date: 2021-12-17 08:00:00 -0600
author: joseph
---

I've been self-hosting some services on my [homelab]({% post_url essay/2021-09-03-infrastructure %}). However, since I don't have a static IP through my Internet service provider, I need some sort of dynamic DNS script that will update the requisite A record on my name server.

Here's how I do it.

## Server Configuration

Provision a [new virtual machine]({% post_url essay/2021-10-29-openbsd-proxmox %}) with OpenBSD 7.0 installed, [setup NTP]({% post_url essay/2021-11-05-openntpd %}), all of that stuff.

Ruby is a great scripting language, with a clean, easy to understand syntax. Therefore, I need to install Ruby onto the machine, which I've [gone over before]({% post_url video/2021-11-26-compiling-ruby-from-source %}).

I also installed [`chruby`](https://github.com/postmodern/chruby), a pair of shell scripts that set environment variables like `PATH` and `RUBIES` so that the system knows where to find the installed Ruby. However, it has a dependency on `bash`, so be aware of that.

I'd like to port `chruby` to `ksh`, or KornShell, but I haven't had the time yet. Maybe one of these days!

## Script

I use AWS Route 53 at the moment, mostly because it has an API I'm familiar with, but also because I haven't found anything better that suits my needs.

The below script queries an IP lookup URL and compares that value with the A record in Route 53. If they match, then the script exits early. Otherwise, it sends an upsert changeset to AWS.

```ruby
require 'net/http'

require 'oga'
require 'aws-sdk-route53'

hosted_zone_id = ENV["ZONE_ID"]
dns_name = ENV["DNS_NAME"]
ip_lookup_uri = ENV["IP_LOOKUP_URI"]

uri = URI(ip_lookup_uri)
current_ip = Net::HTTP.get(uri)

client = Aws::Route53::Client.new

response = client.list_resource_record_sets({
  :hosted_zone_id => hosted_zone_id,
  :start_record_name => dns_name,
  :start_record_type => "A",
  :max_items => 1
})

record_set = response.resource_record_sets.first
resource_record = record_set.resource_records.first
previous_ip = resource_record.value

if current_ip == previous_ip
  exit 0
end

client.change_resource_record_sets({
  :change_batch => {
    :changes => [
      {
        :action => "UPSERT",
        :resource_record_set => {
          :name => dns_name,
          :resource_records => [
            {
              :value => current_ip
            },
          ],
          :ttl => 900,
          :type => "A"
        },
      },
    ],
  },
  :hosted_zone_id => hosted_zone_id
})

exit 0
```

The only third party dependencies I'm using are to the AWS Ruby Route 53 SDK and `oga`, which is itself a dependency of the SDK. Other than that, I'm using `net/http` which is part of the Ruby Standard Library, rather than use one of the many HTTP gems out there.

You should always keep dependencies down to the bare minimum. I could have used one of the many, *many* HTTP Ruby libraries, but I'm often more focused on future stability than using the hottest new thing. I can rely on the `net/http` library to be stable far more than I can one of HTTP Ruby libraries, if I'm honest.

Because I'm using environment variables, I need to export those in a separate shell script:

```sh
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=...
export ZONE_ID=...
export DNS_NAME=example.com
export IP_LOOKUP_URI=https://api.example.org
```

Use whatever IP lookup service makes sense for you, though I use my own self-hosted one.

I wrote a script to source things like `chruby` and the requisite environment variables and then run the Ruby script itself.

```sh
#!/usr/bin/env bash

set -e

HOME=/home/joseph

source $HOME/.bashrc

source $HOME/dynamic-dns/env.sh

ruby $HOME/dynamic-dns/dynamic_dns.rb
```

Finally, I setup a cronjob to execute the script every fifteen minutes.

```sh
*/15 * * * * /home/joseph/dynamic_dns.sh
```

I can also call the script manually through `./dynamic_dns.sh` if I want.

## Conclusion

This setup is a bit more finicky than I would like. I'd like to move away from `bash` at some point, for example, and adding one more dependency to it means one more thing to change when I eventually do.

Still, it works, and while that's not the greatest factor in determining whether to deploy something, it is *a* factor.
