---
title: Personal Tech Stack
date: 2021-06-18 08:00:00 -0600
author: joseph
---

Most of the time when I work on a project, someone has already decided what technologies to use. They made choices I would not have necessarily made. I wouldn't say they were wrong choices, only that my preferences lie elsewhere.

If I were to start a project from scratch, here's what I'd use and why.

## Frontend

Most of the time, I write in HTML and JavaScript without working with a JavaScript framework. I used Ember and Knockout in the past for work, but I quickly disliked using those libraries rather than just plain vanilla JavaScript.

Still, I've grown to like Vue.js. I enjoy using Vue with JSX and `vue-router-dom` as it hits all of my sensibilities. However, I won't always try to develop a single page application right out of the gate.

What I've found though is that I don't really use many of the tools most JavaScript developers use. Instead, I opt for `bash` scripts to help with things like building and deploying the application.

For example:

```bash
# Instead of running this:
yarn test

# I'll run this:
./test.sh
```

When working with multiple projects going up and down the stack, having a consistent API between these projects can be very helpful. Every project will have similar scripts: `start.sh`, `test.sh`, et cetera. Because of this, I don't need to context switch and remember that I'm in a Vue.js application, so I need to run `yarn test` here instead. Each script will contain the necessary commands, and I can execute them without giving it much thought.

### Mobile Development

I don't really know much about mobile development, which is a failing I plan to rectify some time in the future. However, I would probably use Swift and Kotlin, rather than something like React Native, mostly because I think working with the native languages is far more useful in the long run.

## Backend

My language of choice is Ruby, mostly because I enjoy the clean syntax. The creator of the language, Yukihiro Matsumoto, said that when he created the language he wanted to "maximize developer happiness", which I think he was pretty successful at. I rarely have to think about whether this or that syntax is correct.

When you talk about Ruby, you inevitably talk about Rails, but believe it or not, I don't use Rails. It's a fine framework for what it does, but it's also kind of inflexible. Instead, if I'm writing web applications, I'll use Rack, which almost every Ruby web framework is based on already. This has the added benefit that most middleware written for Rails will work for Rack anyway with little to no effort. This also works in reverse: middleware written for Rack will be usable in Rails.

I also have a Rack router I built that is based somewhat on the API used in Roda. I just really like the syntax, I suppose. The only difference is that instead of Strings, I return Rack responses.

```ruby
route do |r|
  r.is "foo" do
    r.get do
      [200, { "Content-Type" => "text/html" }, ["Hello, world!"]]
    end

    r.post do
      # ...
    end
  end
end
```

### Database

Speaking of databases, for the most part I use PostgreSQL, but I never use any ORM like ActiveRecord or Sequel. Instead, I write queries in pure SQL that are then  executed using the `pg` gem.

I haven't really found a need for other stores like Redis or `memcached` or message brokers like RabbitMQ. And like [I've mentioned before]({% post_url /essay/2021-04-23-plug-and-chug %}), I don't like to add technologies to my stack without good reason.

But it depends on the needs of the application, I suppose. For example, I'm sure I would use a graph database like `neo4j` if I was building a social networking application, because querying those kinds of relationships in SQL is much too painful. The needs of the application dictate the technology used.

## Deployment

I feel like deployment is one of those things that isn't talked about a lot, though I'm not sure why. I kind of wish there was a standardized way to deploy applications, because I had to muddle through it for so long.

For frontend applications, I don't do anything more complicated than deploy my code to a static bucket somewhere. My only concerns here are whether the hosting platform can handle the traffic I plan to aim at it.

For server side applications and services, I'll use Packer to create golden images and deploy those images with Terraform. I utilize auto-scaling groups for any of my scaling needs, rather than rely on something like Kubernetes.

## Conclusion

Put all together, my ideal tech stack is:

* Vanilla HTML and JavaScript, or Vue.js
* Ruby
* Rack
* PostgreSQL
* Packer
* Terraform

I'm aware that it's fairly unorthodox.
