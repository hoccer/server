# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_server2_session',
  :secret      => 'fbd9bb0f75317353a1cd814b6b6766996a3309ba33f25c5bdc684b0c9e1bcdc3726608670b7558efbc6fffaaa84aeed35c54134494c707c52840a41be502ddc4'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
