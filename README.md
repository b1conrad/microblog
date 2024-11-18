# microblog

An experiment in using [PicoStack](https://PicoStack.org/) to access an API, in this case from Bluesky. This [GitHub repository](https://github.com/b1conrad/microblog) is 100% KRL.

Of note is that modification of the pico engine (i.e. its TypeScript code) is not required.


## Separation of concerns

There are two things going on, as is typical of a web application which uses an API to access an external service.


### Vendor SDK

Bluesky provides an API for creating a new post. We use a separate ruleset to implement/wrap their API. Since, conceptually, it “belongs” to them, we use their domain name as part of the ruleset ID. In this case, [the SDK ruleset](https://github.com/b1conrad/microblog/blob/main/krl/app.bsky.sdk.krl) is named `app.bsky.sdk` and, really, it should actually belong to them, and/or should be contributed to them.

This ruleset uses a `defaction` cascade to handle not only the “happy path” but also the case where an access token needs to be refreshed. See [history](https://github.com/b1conrad/microblog/commits/main/krl/app.bsky.sdk.krl) and commit comments for more discussion.


### Client web application

A bare-bones web application is provided, PicoStack style, as a single ruleset whose ruleset ID is `microblog_poster`, and is 72 lines of KRL code, consisting of:



* 21 lines for [the HTML code](https://github.com/b1conrad/microblog/blob/main/krl/microblog_poster.krl#L10-L30) with which the user interacts
* 7 lines for [a rule to refresh the page](https://github.com/b1conrad/microblog/blob/main/krl/microblog_poster.krl#L65-L71) after a user action
* 18 lines for [a rule to create a channel](https://github.com/b1conrad/microblog/blob/main/krl/microblog_poster.krl#L40-L57) to be used for the web application
* 7 lines for [a rule to actually create a new Bluesky post](https://github.com/b1conrad/microblog/blob/main/krl/microblog_poster.krl#L58-L64) for the user
* 6 lines for [keeping track of API responses](https://github.com/b1conrad/microblog/blob/main/krl/microblog_poster.krl#L33-L38)
* 13 lines of overhead for the ruleset and its meta and global blocks
