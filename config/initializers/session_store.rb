# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_throw_data_server_2_0_session',
  :secret      => '986da66a8b07ac6ab80e92b76300fce90922de80c2a34adc7fad11c087b3272596dbfa0427dce5104ba6f3bafaf4eb50a46893bc1f63bd418f80a0d847b8befd'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
