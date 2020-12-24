---
title: A PayPal Ruby primer
date: 2021-01-08 08:00:00 -0600
author: joseph
---

One of the most common use cases in software development is consuming third party APIs. The details may differ, but overall you'll always need some way to interface with an external dependency, no matter your business. And if you're in the e-commerce space, you'll always need to collect money from your customers.

One way to collect payments is to use PayPal. It's fairly ubiquitous; customers are used to using PayPal, which means adding it to your own application will incur less friction, allowing your potential customers to become paying customers.

## Disclaimer

This essay is a tool for learning. The code herein should not be used in a production environment, especially where actual money and customer data is involved. I strongly advise against copy and pasting the code into your own project, without fully understanding all of its implications. Be sure to read through to the end, and see how you can adapt it to your use case.

## Why Not Use the PayPal Ruby SDK?

There are several reasons we might not wish to use [PayPal's official SDK](https://github.com/paypal/Checkout-Ruby-SDK). The most important reason is that we want to learn how to use our programming language of choice, in this case Ruby, to do it ourselves. We may not be able to code a better solution than someone else already has, but we can at least learn a thing or two along the way.

Using someone else's code and their DSL, or domain-specific language, does not translate that learning to other parts of your system. Instead, you need to learn each new SDK separately, rather than knowing how HTTP requests work generally and applying that knowledge to solve whatever specific problem you have.

Consider also that adding another dependency to your project may not be the best idea. Some third party projects may do things that you may not want to do. Perhaps they have a retry strategy that you don't necessarily want in your own project. Perhaps they make calls asynchronously, and you want them to be single-threaded. When you use someone else's code, you relinquish **control** over that part of your own system.

## Dependencies

I think it's important to know what dependencies are being pulled into the code so that those reading later on down the line can make adjustments of their own. The Rails ecosystem makes it incredibly easy for this sort of information be opaque to the reader. For example, many developers think that the syntax for `1.second.ago` is pure Ruby, even though it's really a monkey-patch from `ActiveSupport`. Therefore, I'll be listing out dependencies for all these kinds of essays when its source is not incredibly obvious.

For this essay, I'm using [HTTPClient](https://github.com/nahi/httpclient) for HTTP requests mostly because it's what I know. It's written in pure Ruby and is pretty lightweight, with no external dependencies.

The `Base64` and `JSON` modules are both part of the Ruby Standard Library.

## Create a Developer Account

To begin, we need to create a developer account on PayPal. I'm not really going to go into much detail on how to do that, as it's far out of scope for this essay. Find out how to do that [here](https://developer.paypal.com/docs/checkout/integrate/#1-set-up-your-development-environment).

However, once you have your developer account and created an application, or using the default application, we will need the application's client ID and secret. Make sure you keep that in a safe place, as we'll be using that very soon.

## Retrieve an Access Token

Our first step is to retrieve an **access token** by exchanging one for our client ID and secret. The PayPal REST API uses OAuth 2.0 for its integrations. Again, OAuth is outside the scope of this essay, but just know that in order to consume the necessary HTTP endpoints, we'll need to exchange our client ID and secret for a temporary access token.

Let's first look at how PayPal [demonstrates](https://developer.paypal.com/docs/api/get-an-access-token-curl/) this through the `cURL` command.

```bash
curl h(ttps://api-m.sandbox.paypal.com/v1/oauth2/token \
  -H "Accept: application/json" \
  -H "Accept-Language: en_US" \
  -u "<client_id>:<secret>" \
  -d "grant_type=client_credentials"
```

The first part of the command begins with `http://api-m.sandbox.paypal.com`, which is the endpoint or location the resource can be found.

Following that are a collection of arguments or parameters. The `-H` option stands for custom headers passed to the server. The `-u` option is another header passed to the server, but containing **basic access authentication**. In essence, it's a simple username and password encoded in Base64.

Finally, the `-d` option is the HTTP POST data payload, or the body of the request, passed to the server. In this case, it's an attribute of `grant_type` with the value of `client_credentials`, letting the server know we are passing in a client ID and secret in exchange for an access token.

Let's take a look at the response from the server:

```json
{
  "scope": "...",
  "access_token": "...",
  "token_type": "Bearer",
  "app_id": "...",
  "expires_in": 32389,
  "nonce": "..."
}
```

There's quite a bit of information in this response, but what we really care about is the `access_token`. Remember the form this data takes, as we'll be parsing this data in our code next.

Here's how we can translate the above `cURL` command into Ruby code.

```ruby
require 'base64'
require 'httpclient'
require 'json'

def retrieve_access_token(host, client_id, client_secret)
  client = HTTPClient.new

  authorization = Base64.strict_encode64("#{client_id}:#{client_secret}")

  headers = {
    "Accept" => "application/json",
    "Accept-Language" => "en_US",
    "Authorization" => "Basic #{authorization}"
  }
  body = {
    "grant_type" => "client_credentials"
  }
  uri = "#{host}/v1/oauth2/token"

  response = client.post(uri, :header => headers, :body => body)

  body = JSON.parse(response.body)
  access_token = body["access_token"]
  access_token
end
```

First, we declare our dependencies. Then, we have a function called `retrieve_access_token`, which accepts three parameters: a `host`, `client_id`, and `client_secret`.

After instantiating the `HTTPClient` class, we encode in Base64 the `client_id` and `client_secret`. Then, we declare our request headers and body, which we then pass to the serve via POST. Note the similarities between this code and the above `cURL` command.

Finally, upon receipt of the response, we parse for the `access_token`.

## Create an Order

Now that we have the access token, we can create an order.

```ruby
require 'httpclient'
require 'json'

def create_order(host, access_token, currency_code, amount)
  client = HTTPClient.new

  headers = {
    "Content-Type" => "application/json",
    "Authorization" => "Bearer #{access_token}"
  }
  body = {
    "intent" => "CAPTURE",
    "purchase_units" => [
      {
        "amount" => {
          "currency_code" => currency_code,
          "value" => amount,
          "breakdown" => {
            "item_total" => {
              "currency_code" => currency_code,
              "value" => amount,
            }
          }
        },
        "descripton": "This is a test description.",
        "items" => [
          {
            "name" => "Test item",
            "unit_amount" => {
              "currency_code" => currency_code,
              "value" => amount
            },
            "quantity" => "1",
            "description" => "This is a test description.",
            "category" => "DIGITAL_GOODS"
          }
        ]
      }
    ],
    "application_context" => {
      "shipping_preference" => "NO_SHIPPING",
      "user_action" => "PAY_NOW",
      "return_url" => "https://www.example.com/return",
      "cancel_url" => "https://www.example.com/cancel"
    }
  }.to_json
  uri = "#{host}/v2/checkout/orders"

  response = client.post(uri, :header => headers, :body => body)

  body = JSON.parse(response.body)

  order_id = body["id"]
  approve_url = body["links"].find { |link| link["rel"] == "approve" }["href"]

  [order_id, approve_url]
end
```

This is pretty straightforward. The only thing I'll note here is the `application_context` being passed to the endpoint. This allows us to define the payment experience.

For example, the `user_action` being defined as `PAY_NOW` sets the button to "Pay Now", and the `return_url` and `cancel_url` allows us to set the specific URLs that PayPal will use in the event of a successful authorization and a canceled checkout, respectively.

Let's look at the response.

```json
{
  "id": "07N75338Y32250734",
  "status": "CREATED",
  "links": [
    {
      "href": "https://api.sandbox.paypal.com/v2/checkout/orders/07N75338Y32250734",
      "rel": "self",
      "method": "GET"
    },
    {
      "href": "https://www.sandbox.paypal.com/checkoutnow?token=07N75338Y32250734",
      "rel": "approve",
      "method": "GET"
    },
    {
      "href": "https://api.sandbox.paypal.com/v2/checkout/orders/07N75338Y32250734",
      "rel": "update",
      "method": "PATCH"
    },
    {
      "href": "https://api.sandbox.paypal.com/v2/checkout/orders/07N75338Y32250734/capture",
      "rel": "capture",
      "method": "POST"
    }
  ]
}
```

We'll need the `approve_url` to redirect the customer to that specific endpoint, so the customer can approve the transaction on PayPal. That's why we've parsed and retrieved it within the function above.

## Get Customer Approval

So this is the part where the customer interacts with PayPal, logs into their account, or enters their credit card information. Which is the entire point, as we don't want to store any of that information on our own systems.

The only thing you need to do here is to redirect the customer to the `approve_url`. After the customer is done here, they will be redirected to the `return_url` that was denoted in the `application_context` block in the previous invocation and in the following format:

`https://www.example.com/return?token={order_id}&PayerID={payer_id}`

This will be a signal to your systems to capture the order, and since the `token` is the same as the `order_id`, you will know which order to begin capturing.

## Capture an Order

Capturing the order is simply you telling PayPal to begin the transaction to capture the funds with whatever financial instrument the customer defined previously during the customer approval phase.

```ruby
require 'httpclient'
require 'json'

def capture_order(access_token, order_id)
  client = HTTPClient.new

  headers = {
    "Content-Type" => "application/json",
    "Authorization" => "Bearer #{access_token}"
  }
  uri = "#{host}/v2/checkout/orders/#{order_id}/capture"

  client.post(uri, :header => headers)
end
```

You shouldn't really need to do anything with the response, though you may find there's a need for it. If that's the case, here is an example response.

```json
{
  "id": "5MN996644D7434415",
  "status": "COMPLETED",
  "purchase_units": [{
    "reference_id": "default",
    "payments": {
      "captures": [{
        "id": "67P82586VY465894K",
        "status": "COMPLETED",
        "amount": {
          "currency_code": "USD",
          "value": "100.00"
        },
        "final_capture": true,
        "seller_protection": {
          "status": "ELIGIBLE",
          "dispute_categories": ["ITEM_NOT_RECEIVED", "UNAUTHORIZED_TRANSACTION"]
        },
        "seller_receivable_breakdown": {
          "gross_amount": {
            "currency_code": "USD",
            "value": "100.00"
          },
          "paypal_fee": {
            "currency_code": "USD",
            "value": "3.20"
          },
          "net_amount": {
            "currency_code": "USD",
            "value": "96.80"
          }
        },
        "links": [{
          "href": "https://api.sandbox.paypal.com/v2/payments/captures/67P82586VY465894K",
          "rel": "self",
          "method": "GET"
        }, {
          "href": "https://api.sandbox.paypal.com/v2/payments/captures/67P82586VY465894K/refund",
          "rel": "refund",
          "method": "POST"
        }, {
          "href": "https://api.sandbox.paypal.com/v2/checkout/orders/5MN996644D7434415",
          "rel": "up",
          "method": "GET"
        }],
        "create_time": "2020-12-11T20:59:05Z",
        "update_time": "2020-12-11T20:59:05Z"
      }]
    }
  }],
  "payer": {
    "name": {
      "given_name": "John",
      "surname": "Doe"
    },
    "email_address": "sb-qw5wy3825636@personal.example.com",
    "payer_id": "LFZYNHJ33WQNL",
    "address": {
      "country_code": "US"
    }
  },
  "links": [{
    "href": "https://api.sandbox.paypal.com/v2/checkout/orders/5MN996644D7434415",
    "rel": "self",
    "method": "GET"
  }]
}
```

And with that, you're done!

## Conclusion

As you can see, consuming PayPal endpoints is not very difficult at all, and in fact, you could say that this was not just a PayPal Ruby primer but a lesson in how to consume HTTP endpoints in general. With this knowledge in hand, you will be able to consume other third party HTTP endpoints with relative ease.
