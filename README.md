Formstack APIs
=============

Repository Containing Multiple Formstack API Wrappers

Requirements to Use Any Formstack APIs in this Repository
=========================================================
* A valid [Formstack.com](http://www.formstack.com) account
* A valid Formstack API V2 Application. [You can create one here.](https://www.formstack.com/admin/applications/add)
* Willingness to hack and test on your own. Formstack will try to maintain its libraries as best as it can but ultimately the responsibility of your code is on you, the developer.

API Wrappers
============
- PHP (Laravel) Wrapper - [https://github.com/SeunMatt/fstackapi_php](https://github.com/SeunMatt/fstackapi_php)

FAQs
====
* **Where's the wrapper for \<INSERT LANGUAGE HERE\>?** - Currently our goal is
 to make new wrappers for all of the wrappers that currently exist for the V1 API.
 Have a pet language you'd love to see a wrapper for? We're willing to take pull
 requests for changes to existing wrappers and/or additional wrappers.
* **Is there a rate limit?** - Yes. Formstack currently applies a rate limit of
 14,400 requests per Access Token per day.
