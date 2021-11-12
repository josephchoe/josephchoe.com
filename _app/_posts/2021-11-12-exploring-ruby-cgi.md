---
title: Exploring Ruby CGI
date: 2021-11-12 08:00:00 -0600
author: joseph
---

Lately, I've been thinking about how Ruby web applications are deployed.

In most applications, you have a web server like `nginx` serving static pages. These web servers can also route traffic to application servers like `puma`, which then allows for the use of the [Rack interface]({% post_url video/2021-07-16-rack-the-best-ruby-web-framework %}).

However, this means you have both the web server and the application server running constantly. Which might be what you want, depending on your use case, but also maybe not.

Perhaps I'm showing my age, but when I was a young kid I would write the odd Perl script for small bits of functionality like web counters or guestbooks. This was done through the **common gateway interface** or CGI.

We can also serve Ruby scripts through this interface, like so:

```ruby
# hello.cgi

#!/usr/bin/ruby

puts "Status: 200"
puts "Content-Type: text/plain"
puts
puts "Hello, world!"
```

Via CGI, we're printing output to the user on the browser by printing messages to `$stdout`. You can see familiar elements like the HTTP status code, a header, and the body of the response separated from the headers by a newline.

If you run this script, it will simply print to `$stdout`:

```sh
$ ./hello.cgi
Status: 200
Content-Type: text/plain

Hello, world!
```

And when we serve this script from our web server:

```sh
$ curl -i http://localhost:9292/hello.cgi
HTTP/1.1 200 OK
Content-Type: text/plain
Server: WEBrick/1.7.0 (Ruby/3.0.2/2021-07-07)
Date: Sun, 07 Nov 2021 08:44:22 GMT
Content-Length: 12
Connection: Keep-Alive

Hello, world!
```

Fairly straightforward!

We can also use Rack's CGI handler if we want to abstract away some of the request handling:

```ruby
# hello-rack.cgi

#!/usr/bin/ruby

require 'rack'

class Application
  def call(env)
    [200, {"Content-Type"=>"text/plain"}, ["Hello, Rack!"]]
  end
end

app = Application.new

Rack::Handler::CGI.run(app)
```

I kind of like this, because I'm using a simple and familiar interface for my web requests. Still, it's probably overkill unless I need routing or request handling, like the form parameters from an HTTP `POST`.

Of course, even if we're not running an application server like `puma`, we're still creating a new Ruby process for each request that comes in, so there's some overhead to think about. You wouldn't necessarily want to use this for applications that need to serve hundreds of thousands of requests per minute. But most applications don't really have those requirements, if we're being honest.

Anywho, I do like the idea of segregating functionality into different, tiny scripts that each do one thing well. This is still something I'm starting to explore, though I do think it's a bit funny how I'm circling back to pretty old web technology.
