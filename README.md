# Gittip Service Access Dashboard

[![Build Status](https://travis-ci.org/gittip/access-dashboard.svg?branch=master)](https://travis-ci.org/gittip/access-dashboard)

A tiny app aspiring to be a dynamic means of communicating who has
access to what in an Open Company. (Origin story:
gittip/www.gittip.com#2220)

## Usage

    export GITHUB_TOKEN=xxxxxxxxx
    export HEROKU_API_KEY=xxxxxxxxx
    export BALANCED_COOKIE_SESSION_ID=xxxxxxxxxxxx
    export BALANCED_MARKETPLACE_ID=xxxxxxxxxxxx
    bundle install --path vendor/bundle
    bundle exec camping app.rb
    curl http://127.0.0.1:3301

## Notes

* Github personal access token must have the permissions `public_repo` &
  `read:org`
* `BALANCED_COOKIE_SESSION_ID` was retrieved from the browser inspector
  tool.
