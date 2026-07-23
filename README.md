I'm sick of being asked for feedback.

This is a [Sieve](https://proton.me/support/sieve-advanced-custom-filters)
filter which can be used to filter out of emails that ask for it. It uses
a scoring method, where certain words, phrases, and other details increase
the score, and where an email is filtered out if the score is above a certain
threshold. Details which suggest that the email is _not_ asking for feedback
increase the threshold.

The filter is imperfect and incomplete. Desperate attempts to _know what you
think_ will still get through, and there may be some false positives. However,
the filter will also be improved over time.

You may need to create an email folder named _Filtered out by AI_ before this
filter will work.

## Authorship

Unlike my other project,
[sieve-filter-feedback-requests](https://github.com/openjck/sieve-filter-feedback-requests),
this Sieve filter is not written by me. Rather, I asked an AI to write and
maintain it, and I make only minor tweaks. So far, the only AI I've used is
[Claude](https://claude.ai/).
