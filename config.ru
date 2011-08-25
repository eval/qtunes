# Use this config to develop the webinterface with shotgun (which gives you reload-per-request):
# $> bundle exec shotgun config.ru
require './lib/qtunes'
run Qtunes::Server
