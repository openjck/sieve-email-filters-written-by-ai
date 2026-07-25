This project contains Sieve-based email filters which filter out useless and
annoying emails that are not technically spam. All filters in this project are
written by AI.

## Installation

Your email client must support
[Sieve](https://proton.me/support/sieve-advanced-custom-filters) filters.
Consult your email client's documentation for instructions on installing them.

Because these filters move emails into an email folder named _Filtered out by
AI_, you may need to create an email folder named _Filtered out by AI_ before
the filters will work. I don't know whether email programs typically create the
folder automatically.

## Filters

The following Sieve email filters are provided by this project:

| Filter                                                        | Description                                                                                 |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| [Feedback requests](./filters/feedback-requests/filter.sieve) | Filters out emails which request feedback: "rate your trip," "tell us what you think," etc. |

## False positives and false negatives

No email filter is perfect. False positives (filtering out emails you _want_ to
see) and false negatives (_not_ filtering out emails you _don't_ want to see)
will occur. Desperate attempts to _know what you think_ will still get through
from time to time. Even still, the filters will be improved over time. Just keep
an eye on the _Filtered out by AI_ email folder, especially if you're waiting
for an important email or having trouble finding an email that you think you
should have received.

## Authorship

Unlike my other project,
[sieve-email-filters](https://github.com/openjck/sieve-email-filters), these
Sieve filters are not written by me. Rather, I use an AI to write and maintain
them, and I make only minor tweaks. So far, the only AI I've used is
[Claude](https://claude.ai/).
