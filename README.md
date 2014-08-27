= Mailphax - Send faxes with Phaxio using 3rd party email services

Mailphax is a simple sinatra app.  You can run it on any host or with any service that supports ruby and sinatra.

== Installation on Heroku

(This assumes you have the Heroku toolbelt installed and have a Heroku account.)

1. git clone this repo && cd mailphax
1. heroku create
1. heroku config:set PHAXIO_KEY=yourPhaxioApiKey
1. heroku config:set PHAXIO_SECRET=yourPhaxioApiSecret
1. git push heroku master

Now set up your hosted email service to invoke callbacks to this service when mail is received.  (See below.)

== Configuring Mandrill
1. Sign up for a mandrill account
2. In the Mandrill console, click "Inbound" in the left sidebar.
3. Add a new inbound domain that you have DNS control over.
4. Modify the DNS on your inbound domain to point to Mandrill using MX records. (Click the "DNS Settings" button for more info.)
5. Click "Routes" in the Mandrill console under your new inbound domain.
6. Add a wildcard route "*" and point it to http://yourMailPhaxInstallation/mandrill (e.g. http://example.com/mandrill)
7. Profit.

== Configuring SendGrid
TODO

== Configuring Mailgun
1. Sign up for a mailgun account
2. In the Mailgun console, click "Domains" in the navbar.
3. Add a new inbound domain that you have DNS control over.  (Or use something.mailgun.org and you can use a mailgun subdomain!)
4. Modify the DNS on your inbound domain to point to Mailgun using MX records.
5. Click "Routes" in the main Mailgun Navbar.
6. Click "Create new route"
7. Leave the priority field alone.
8. For "filter expression", specify "match_recipient("[0-9]+@YOURDOMAIN")" where YOURDOMAIN is the domain you added in step 3.
9. For "Actions" specify "forward("http://yourMailPhaxInstallation/mailgun")" where yourMailPhaxInstallation should be the location where you've installed the sinatra app.
10. Click "Save".
11. Profit.
