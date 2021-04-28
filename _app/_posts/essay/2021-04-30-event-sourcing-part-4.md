---
title: "Event Sourcing, Part 4: View Data"
date: 2021-04-30 08:00:00 -0600
author: joseph
---

It took a while, but we're finally here.

We've built a component that accepted [user registrations]({% post_url /essay/2021-01-29-event-sourcing-part-1 %}) and one that handled [email uniqueness]({% post_url /essay/2021-02-26-event-sourcing-part-2 %}). We designed them to communicate with each other through the [publish and subscribe]({% post_url /essay/2021-03-26-event-sourcing-part-3 %}) messaging pattern. But this is all pointless if our applications can't use the events in some way to show data to users.

Part of what makes event sourced architecture so difficult to understand, as opposed to ORM or object-relational mapping so easy, is that there's a lot of moving parts. With an ORM, you can often write a single line of code to write to the database and retrieve a tuple. With an event sourced architecture, it takes a lot of work to get to this point.

But we can finally reach that last hurdle.

## Disclaimer

This essay is a tool for learning. I stress this every time, but code found on the Internet should be evaluated and understood on its merits and adapted for a specific use case, not copied and pasted wholesale.

## View Data

It would be very difficult for our applications to interact directly with our entity streams. Remember that it's an append-only log of all the transactions or changes to state within our application. We cannot just query each stream to ask for all changes and process them with each query.

Instead, we need to project our final state or view data to a database, whether that be PostgreSQL, Redis, or some other data store, and our application can query that instead.

Let's look at a simple registrations table in PostgreSQL:

```sql
CREATE TABLE "registrations" (
  "registration_id" UUID PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "email_address" varchar NOT NULL,
  "is_email_accepted" BOOLEAN NOT NULL,
  "is_registered" BOOLEAN NOT NULL
);
```

If the above registrations table looks like our Registration entity from previous essays, that is by design:

```ruby
class Registration
  include Schema::DataStructure

  attribute :id, String
  attribute :user_id, String
  attribute :email_address, String

  attribute :initiated_time, Time
  attribute :email_accepted_time, Time
  attribute :email_rejected_time, Time
  attribute :registered_time, Time
  attribute :cancelled_time, Time

  ## ...
end
```

Yet how do populate the registrations table?

## Populating View Data

It should come as no surprise that we use the same mechanism we used to process commands and events: components. Because we have access to the Registration component's events, we can use those same events to trigger changes in our view database.

I'm not going to go into the specific entities, commands, events, projections, et cetera for our new Registration view data component, because that would just be retreading old ground. But let's look at the handler and see how it differs from other components:

```ruby
module Handlers
  module Registration
    class Events
      ## ..

      category :registration_view_data

      handle ::Registration::Client::Messages::Events::EmailRejected do |registration_email_rejected|
        registration_id = registration_email_rejected.registration_id

        registration, version = store.fetch(registration_id, include: :version)

        if registration.email_rejected?
          logger.info(tag: :ignored) { "Event ignored (Event: #{registration_email_rejected.class.name}, Registration ID: #{registration_id}, User ID: #{registration_email_rejected.user_id})" }
          return
        end

        # Insert tuple into registrations table or other side effects.
        ## ..

        time = clock.iso8601

        email_rejected = EmailRejected.follow(registration_email_rejected, exclude: [:claim_id])
        email_rejected.processed_time = time

        stream_name = stream_name(registration_id)

        write.(email_rejected, stream_name, expected_version: version)
      end

      handle ::Registration::Client::Messages::Events::Registered do |registration_registered|
        registration_id = registration_registered.registration_id

        registration, version = store.fetch(registration_id, include: :version)

        if registration.registered?
          logger.info(tag: :ignored) { "Event ignored (Event: #{registration_registered.class.name}, Registration ID: #{registration_id}, User ID: #{registration_registered.user_id})" }
          return
        end

        # Insert tuple into registrations table or other side effects.  
        ## ..

        time = clock.iso8601

        registered = Registered.follow(registration_registered)
        registered.processed_time = time

        stream_name = stream_name(registration_id)

        write.(registered, stream_name, expected_version: version)
      end
    end
  end
end
```

After we've retrieved the entity from the store, but before we write a new event to the Registration view data stream, we insert a tuple into our registrations table (or execute any other side effect). This ensures that any side effects are protected by the optimistic locking we have in place, and therefore executed only once.

We can use any database tool, including `ActiveRecord` or `Sequel`, to insert the actual tuples:

```ruby

Registration.create(
  :registration_id => registration_id,
  :user_id => user_id,
  :email_address => email_address,
  :is_email_rejected => false,
  :is_registered => true
)
```

Once that's done, our view database is populated.

## Requesting Data

In a normal Rails application, the inserting of the tuple and querying of the database happens within a single request-response cycle. But within an event sourced architecture, it's a little more complicated.

The sequence within the application itself would look something like this:

```bash
# Send a command to the registration service.
curl -d '{"registration_id": "abc", "user_id": "123", "email_address": "john@example.com" }' -H "Content-Type: application/json" -X POST http://localhost:3000/registrations

# Query the registration for data.
curl -H "Content-Type: application/json" http://localhost:3000/registrations/abc
```

The first `curl` command sends a request to the registration service, which writes a command to our registration command stream:

```ruby
register = Register.new

register.registration_id = registration_id
register.user_id = user_id
register.email_address = email_address

stream_name = "registration:command-#{registration_id}"

write.(claim, stream_name)
```

This would kick off the registration and email uniqueness components, which are waiting for new commands and events to process. But this is happening autonomously outside of the knowledge of the resource. The resource would simply respond with the following HTTP response:

```http
HTTP/1.1 202 Accepted
Content-Type: application/json
Location: http://localhost:3000/registrations/abc
```

An HTTP 202 Accepted response is generally expected when the request is being processed asynchronously. In addition, we're returning a `Location` header so the application knows which resource to query for data.

The second `curl` command queries the database:

```sql
SELECT
  "is_email_rejected",
  "is_registered"
FROM "registrations"
WHERE "registration_id" = :registration_id;
```

Because the view database is populated asynchronously, the first few queries to the resource may result in an HTTP 404 error. The application will need to continue querying the resource until it receives an HTTP 200 response, though perhaps with some sort of exponential backoff or rate limiting at play.

Once the request is successful, the application knows whether the registration was successful or whether the email in question is already in use by someone else and can show the appropriate views to the user.

Now we're done.

## Conclusion

Over the last few months, we've built an event sourced system that handles the single use case of user registrations, taking email uniqueness into account. We've protected against concurrency and made our components idempotent. We've seen the interaction between two components, and we've populated a view database, so that our application can query view data.

I can't answer the question of whether you should build something like this in your own application. That's really dependent on your own use case and requirements. But the Ruby ecosystem is really hyper-focused on a single type of architecture called the monolith. I think it's useful to know and understand different types of architectures, but resources on this subject, especially in Ruby, are few and far between.

Still, I hope you've found some value in this sequence of essays.
