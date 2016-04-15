Mailphax
========

Send faxes with Phaxio using 3rd party email services.  Mailphax is a simple sinatra app.  You can run it on any host or with any service that supports ruby and sinatra.

Configuring Mailgun
-------
1. Sign up for a mailgun account
1. In the Mailgun console, click "Domains" in the navbar.
1. Add a new inbound domain that you have DNS control over.  (Or use something.mailgun.org and you can use a mailgun subdomain!  If you use a mailgun subdomain, you can skip the next step as DNS is set up by mailgun already.)
1. Modify the DNS on your inbound domain to point to Mailgun using MX records.
1. Click "Routes" in the main Mailgun Navbar.
1. Click "Create new route"
1. Leave the priority field alone.
1. For "filter expression", specify "match_recipient("[0-9]+@YOURDOMAIN")" where YOURDOMAIN is the domain you added in step 3.
1. For "Actions" specify "forward("http://yourMailPhaxInstallation/mailgun")" where yourMailPhaxInstallation should be the location where you've installed the sinatra app.
1. Click "Save".
1. Profit.
